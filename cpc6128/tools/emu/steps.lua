-- Runs a list of test steps in MAME, one a line, from the file named by the
-- CPC_STEPS environment variable (tools/emu/mame.mjs writes it and reads what
-- this prints):
--   wait N                 run N frames
--   type TEXT              type TEXT on the keyboard ("\n" for Return)
--   poke ADDR VALUE        write a byte (decimal) into the base 64K
--   peek LABEL ADDR LEN    print LEN bytes: "OUT peek LABEL b1 b2 ..."
--   snap LABEL             save a screenshot: "OUT snap LABEL"
--   time LABEL             print the emulated time in seconds: "OUT time LABEL secs"
--   key ROW MASK 1|0       press (1) or let go of (0) the key at that keyboard matrix
--                          row (0-9) and bit mask: "OUT key ROW MASK name"
--   bank LABEL CONFIG ADDR LEN COPY
--                          print LEN bytes from ADDR with RAM configuration CONFIG
--                          paged in (an extra bank at #4000), then page back in the
--                          configuration the program has, the byte at COPY (ga_ram)
--   quit                   stop
local steps = {}
for line in io.lines(os.getenv("CPC_STEPS")) do
  if line ~= "" then table.insert(steps, line) end
end
local machine = manager.machine
local mem = machine.devices[":maincpu"].spaces["program"]
local io = machine.devices[":maincpu"].spaces["io"]
local i, waiting = 1, 0

local function step()
  while i <= #steps do
    if waiting > 0 then waiting = waiting - 1; return end
    local line = steps[i]; i = i + 1
    local op, rest = line:match("^(%S+)%s*(.*)$")
    if op == "wait" then
      waiting = tonumber(rest)
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
    elseif op == "snap" then
      machine.video:snapshot()
      print("OUT snap " .. rest)
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
    elseif op == "quit" then
      print("OUT done")
      machine:exit()
      return
    end
  end
end
emu.register_frame_done(step, "steps")
