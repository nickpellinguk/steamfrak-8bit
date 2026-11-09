-- Runs a list of test steps in MAME, one a line, from the file named by the
-- CPC_STEPS environment variable (tools/emu/mame.mjs writes it and reads what
-- this prints):
--   wait N                 run N frames
--   waitfor ADDR VALUE MAX run until the byte at ADDR is VALUE (at most MAX frames, then
--                          stop: "OUT timeout ADDR")
--   type TEXT              type TEXT on the keyboard ("\n" for Return)
--   poke ADDR VALUE        write a byte (decimal) into the base 64K
--   peek LABEL ADDR LEN    print LEN bytes: "OUT peek LABEL b1 b2 ..."
--   snap LABEL             save a screenshot: "OUT snap LABEL"
--   load ADDR FILE         copy a file into the base 64K at ADDR
--   dump LABEL ADDR LEN    write LEN bytes from ADDR to LABEL.bin (beside the steps file)
--   regs LABEL             print the Z80's PC and SP: "OUT regs LABEL PC=.... SP=...."
--   time LABEL             print the emulated time in seconds: "OUT time LABEL secs"
--   key ROW MASK 1|0       press (1) or let go of (0) the key at that keyboard matrix
--                          row (0-9) and bit mask: "OUT key ROW MASK name"
--   bank LABEL CONFIG ADDR LEN COPY
--                          print LEN bytes from ADDR with RAM configuration CONFIG
--                          paged in (an extra bank at #4000), then page back in the
--                          configuration the program has, the byte at COPY (ga_ram)
--   bankdump LABEL CONFIG ADDR LEN COPY
--                          write LEN bytes from ADDR with RAM configuration CONFIG
--                          paged in to LABEL.bin, likewise
--   bankpoke CONFIG ADDR VALUE COPY
--                          write a byte with RAM configuration CONFIG paged in, likewise
--   quit                   stop
local steps = {}
local dir = os.getenv("CPC_STEPS"):match("^(.*)/[^/]*$")
-- (MAME's Lua has no io.open, and its io.lines only lasts while this first runs: so the
-- files that load steps copy in are read now)
local files = {}
for line in io.lines(os.getenv("CPC_STEPS")) do
  if line ~= "" then table.insert(steps, line) end
  local file = line:match("^load%s+%d+%s+(.+)$")
  if file and not files[file] then files[file] = io.lines(file, "a")() end
end
local machine = manager.machine
local mem = machine.devices[":maincpu"].spaces["program"]
local io = machine.devices[":maincpu"].spaces["io"]
local i, waiting = 1, 0
local wait_addr, wait_value, wait_max

local function step()
  while i <= #steps do
    if waiting > 0 then waiting = waiting - 1; return end
    if wait_addr then
      if mem:read_u8(wait_addr) ~= wait_value then
        wait_max = wait_max - 1
        if wait_max > 0 then return end
        local st = machine.devices[":maincpu"].state
        print(string.format("OUT stuck PC=%04X SP=%04X", st["PC"].value, st["SP"].value))
        print("OUT timeout " .. wait_addr .. " " .. (i - 1))
        machine:exit()
        return
      end
      wait_addr = nil
    end
    local line = steps[i]; i = i + 1
    local op, rest = line:match("^(%S+)%s*(.*)$")
    if op == "wait" then
      waiting = tonumber(rest)
    elseif op == "waitfor" then
      local a, v, n = rest:match("(%d+)%s+(%d+)%s+(%d+)")
      wait_addr, wait_value, wait_max = tonumber(a), tonumber(v), tonumber(n)
    elseif op == "type" then
      machine.natkeyboard:post((rest:gsub("\\n", "\n")))
    elseif op == "poke" then
      local a, v = rest:match("(%d+)%s+(%d+)")
      mem:write_u8(tonumber(a), tonumber(v))
    elseif op == "peek" then
      local label, a, n = rest:match("(%S+)%s+(%d+)%s+(%d+)")
      local out = {}
      for k = 0, tonumber(n) - 1 do out[#out + 1] = mem:read_u8(tonumber(a) + k) end
      print("OUT peek " .. label .. " " .. table.concat(out, " "))
    elseif op == "load" then
      local a, file = rest:match("(%d+)%s+(.+)$")
      local data = files[file]
      for k = 1, #data do mem:write_u8(tonumber(a) + k - 1, data:byte(k)) end
    elseif op == "dump" then
      local label, a, n = rest:match("(%S+)%s+(%d+)%s+(%d+)")
      local out = {}
      for k = 0, tonumber(n) - 1 do out[#out + 1] = string.char(mem:read_u8(tonumber(a) + k)) end
      local f = emu.file(dir, 0x0E)               -- (write, create)
      assert(f:open(label .. ".bin") == nil, "can't write " .. label .. ".bin")
      f:write(table.concat(out))
    elseif op == "snap" then
      machine.video:snapshot()
      print("OUT snap " .. rest)
    elseif op == "regs" then
      local st = machine.devices[":maincpu"].state
      print(string.format("OUT regs %s PC=%04X SP=%04X", rest, st["PC"].value, st["SP"].value))
    elseif op == "time" then
      print("OUT time " .. rest .. " " .. string.format("%.6f", machine.time:as_double()))
    elseif op == "key" then
      local row, mask, v = rest:match("(%d+)%s+(%d+)%s+(%d+)")
      local port = machine.ioport.ports[":kbrow." .. row]
      local found
      for name, f in pairs(port.fields) do
        if f.mask == tonumber(mask) and (not found or found.name == "Keyboard") then found = f end
      end
      if not found then error("no key at row " .. row .. " mask " .. mask) end
      found:set_value(tonumber(v))
      print("OUT key " .. row .. " " .. mask .. " " .. found.name)
    elseif op == "bank" then
      local label, config, a, n, copy = rest:match("(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
      io:write_u8(0x7F00, tonumber(config))
      local out = {}
      for k = 0, tonumber(n) - 1 do out[#out + 1] = mem:read_u8(tonumber(a) + k) end
      io:write_u8(0x7F00, mem:read_u8(tonumber(copy)))
      print("OUT bank " .. label .. " " .. table.concat(out, " "))
    elseif op == "bankdump" then
      local label, config, a, n, copy = rest:match("(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
      io:write_u8(0x7F00, tonumber(config))
      local out = {}
      for k = 0, tonumber(n) - 1 do out[#out + 1] = string.char(mem:read_u8(tonumber(a) + k)) end
      io:write_u8(0x7F00, mem:read_u8(tonumber(copy)))
      local f = emu.file(dir, 0x0E)
      assert(f:open(label .. ".bin") == nil, "can't write " .. label .. ".bin")
      f:write(table.concat(out))
    elseif op == "bankpoke" then
      local config, a, v, copy = rest:match("(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
      io:write_u8(0x7F00, tonumber(config))
      mem:write_u8(tonumber(a), tonumber(v))
      io:write_u8(0x7F00, mem:read_u8(tonumber(copy)))
    elseif op == "quit" then
      print("OUT done")
      machine:exit()
      return
    end
  end
end
emu.register_frame_done(step, "steps")
