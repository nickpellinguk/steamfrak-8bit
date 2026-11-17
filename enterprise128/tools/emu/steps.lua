-- Runs a list of test steps in MAME's Enterprise 128 driver, one a line, from the file named
-- by the EP_STEPS environment variable (tools/emu/mame.mjs writes it and reads what this
-- prints). As the CPC version's steps.lua, with the Z80's 64K as it's paged at the time, and
-- also any segment, read and written through Dave's own address space (segment * #4000 +
-- offset) without paging anything:
--   wait N                 run N frames
--   waitfor ADDR VALUE MAX run until the byte at ADDR is VALUE (at most MAX frames, then
--                          stop: "OUT timeout ADDR")
--   type TEXT              type TEXT on the keyboard ("\n" for Return)
--   poke ADDR VALUE        write a byte (decimal) into the Z80's 64K
--   peek LABEL ADDR LEN    print LEN bytes: "OUT peek LABEL b1 b2 ..."
--   speek LABEL SEG OFF LEN
--                          print LEN bytes from segment SEG: "OUT peek LABEL b1 b2 ..."
--   spoke SEG OFF VALUE    write a byte into segment SEG
--   load ADDR FILE         copy a file into the Z80's 64K at ADDR
--   sload SEG OFF FILE     copy a file into segment SEG (and on into the next segments)
--   dump LABEL ADDR LEN    write LEN bytes from ADDR to LABEL.bin (beside the steps file)
--   sdump LABEL SEG OFF LEN
--                          likewise from segment SEG
--   fill SEG OFF LEN SEED  fill LEN bytes of segment SEG from OFF with pseudo-random ones
--   jump ADDR              set the Z80's PC to ADDR (the program counter; nothing else changes)
--   regs LABEL             print the Z80's PC and SP: "OUT regs LABEL PC=.... SP=...."
--   pages LABEL            print the segments at pages 0-3: "OUT peek LABEL s0 s1 s2 s3"
--   time LABEL             print the emulated time in seconds: "OUT time LABEL secs"
--   key ROW MASK 1|0       press (1) or let go of (0) the key at that keyboard matrix row
--                          (0-9) and bit mask: "OUT key ROW MASK name"
--   snap LABEL             save a screenshot: "OUT snap LABEL"
--   quit                   stop
local steps = {}
local dir = os.getenv("EP_STEPS"):match("^(.*)/[^/]*$")
-- (MAME's Lua has no io.open, and its io.lines only lasts while this first runs: so the
-- files that load steps copy in are read now)
local files = {}
for line in io.lines(os.getenv("EP_STEPS")) do
  if line ~= "" then table.insert(steps, line) end
  local file = line:match("^load%s+%d+%s+(.+)$") or line:match("^sload%s+%d+%s+%d+%s+(.+)$")
  if file and not files[file] then files[file] = io.lines(file, "a")() end
end
local machine = manager.machine
local cpu = machine.devices[":u1"]
local mem = cpu.spaces["program"]
local io = cpu.spaces["io"]
local phys = machine.devices[":u3"].spaces["program"]    -- Dave's: segment * #4000 + offset
local i, waiting = 1, 0
local wait_addr, wait_value, wait_max

local function write_file(label, bytes)
  local f = emu.file(dir, 0x0E)               -- (write, create)
  assert(f:open(label .. ".bin") == nil, "can't write " .. label .. ".bin")
  f:write(table.concat(bytes))
end

local function step()
  while i <= #steps do
    if waiting > 0 then waiting = waiting - 1; return end
    if wait_addr then
      if mem:read_u8(wait_addr) ~= wait_value then
        wait_max = wait_max - 1
        if wait_max > 0 then return end
        local st = cpu.state
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
    elseif op == "speek" then
      local label, s, a, n = rest:match("(%S+)%s+(%d+)%s+(%d+)%s+(%d+)")
      local base = tonumber(s) * 16384 + tonumber(a)
      local out = {}
      for k = 0, tonumber(n) - 1 do out[#out + 1] = phys:read_u8(base + k) end
      print("OUT peek " .. label .. " " .. table.concat(out, " "))
    elseif op == "spoke" then
      local s, a, v = rest:match("(%d+)%s+(%d+)%s+(%d+)")
      phys:write_u8(tonumber(s) * 16384 + tonumber(a), tonumber(v))
    elseif op == "load" then
      local a, file = rest:match("(%d+)%s+(.+)$")
      local data = files[file]
      for k = 1, #data do mem:write_u8(tonumber(a) + k - 1, data:byte(k)) end
    elseif op == "sload" then
      local s, a, file = rest:match("(%d+)%s+(%d+)%s+(.+)$")
      local data, base = files[file], tonumber(s) * 16384 + tonumber(a)
      for k = 1, #data do phys:write_u8(base + k - 1, data:byte(k)) end
    elseif op == "dump" then
      local label, a, n = rest:match("(%S+)%s+(%d+)%s+(%d+)")
      local out = {}
      for k = 0, tonumber(n) - 1 do out[#out + 1] = string.char(mem:read_u8(tonumber(a) + k)) end
      write_file(label, out)
    elseif op == "sdump" then
      local label, s, a, n = rest:match("(%S+)%s+(%d+)%s+(%d+)%s+(%d+)")
      local base = tonumber(s) * 16384 + tonumber(a)
      local out = {}
      for k = 0, tonumber(n) - 1 do out[#out + 1] = string.char(phys:read_u8(base + k)) end
      write_file(label, out)
    elseif op == "fill" then
      local s, a, n, seed = rest:match("(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
      local base, x = tonumber(s) * 16384 + tonumber(a), tonumber(seed)
      for k = 0, tonumber(n) - 1 do
        x = (x * 1103515245 + 12345) % 2147483648
        phys:write_u8(base + k, (x >> 16) & 255)
      end
    elseif op == "jump" then
      cpu.state["PC"].value = tonumber(rest)
    elseif op == "regs" then
      local st = cpu.state
      print(string.format("OUT regs %s PC=%04X SP=%04X", rest, st["PC"].value, st["SP"].value))
    elseif op == "pages" then
      local out = {}
      for p = 0, 3 do out[#out + 1] = io:read_u8(0xB0 + p) end
      print("OUT peek " .. rest .. " " .. table.concat(out, " "))
    elseif op == "time" then
      print("OUT time " .. rest .. " " .. string.format("%.6f", machine.time:as_double()))
    elseif op == "key" then
      local row, mask, v = rest:match("(%d+)%s+(%d+)%s+(%d+)")
      local port = machine.ioport.ports[":Y" .. row]
      local found
      for name, f in pairs(port.fields) do
        if f.mask == tonumber(mask) then found = f end
      end
      if not found then error("no key at row " .. row .. " mask " .. mask) end
      found:set_value(tonumber(v))
      print("OUT key " .. row .. " " .. mask .. " " .. found.name)
    elseif op == "snap" then
      machine.video:snapshot()
      print("OUT snap " .. rest)
    elseif op == "quit" then
      print("OUT done")
      machine:exit()
      return
    end
  end
end
emu.register_frame_done(step, "steps")
