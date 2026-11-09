-- Runs a list of test steps in MAME, one a line, from the file named by the
-- CPC_STEPS environment variable (tools/emu/mame.mjs writes it and reads what
-- this prints):
--   wait N                 run N frames
--   type TEXT              type TEXT on the keyboard ("\n" for Return)
--   poke ADDR VALUE        write a byte (decimal) into the base 64K
--   peek LABEL ADDR LEN    print LEN bytes: "OUT peek LABEL b1 b2 ..."
--   snap LABEL             save a screenshot: "OUT snap LABEL"
--   quit                   stop
local steps = {}
for line in io.lines(os.getenv("CPC_STEPS")) do
  if line ~= "" then table.insert(steps, line) end
end
local machine = manager.machine
local mem = machine.devices[":maincpu"].spaces["program"]
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
    elseif op == "quit" then
      print("OUT done")
      machine:exit()
      return
    end
  end
end
emu.register_frame_done(step, "steps")
