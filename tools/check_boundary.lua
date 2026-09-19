-- Fails if the mathematical core touches the application.
--
-- Run it the same way the automated checks do:
--     lua tools/check_boundary.lua

require("tools.rockpath").add()

local boundary = require("tools.boundary")
local findings = boundary.scanDirectory("core")

if #findings == 0 then
  print("core layer is clean: it never reaches into the application")
  os.exit(0)
end

for _, finding in ipairs(findings) do
  io.stderr:write(
    ("%s:%d uses '%s', which belongs to the application, not the core\n"):format(
      finding.file,
      finding.line,
      finding.name
    )
  )
end

io.stderr:write(("\n%d violation(s). Move this code into the adapter layer.\n"):format(#findings))
os.exit(1)
