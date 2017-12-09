
-- constants
local DIV = "-------------------------------"
local LINE = "-- "
local CALLBACKS = {
  'keypressed',
  'keyreleased',
  'joystickpressed',
  'joystickreleased',
  'mousepressed',
  'mousereleased',
  'update',
  'draw'
}

-- configure state
local Configure = require 'input.configure.state'

-- forward declaration
local _input
local _toggleEvents

-- loads or unloads inputs
function _toggleEvents()
  for _,event in pairs(CALLBACKS) do
    Configure[event], love[event] = love[event], Configure[event]
  end
end

function Configure.quit(mappings)
  print(LINE.."All set, carry on")
  print(DIV)
  _input.setup(mappings.digital, mappings.analog)
  _input = nil
  _toggleEvents()
end

-- mappings.digital is a digital mapping table (handle -> key/button)
-- mappings.analog is an analog mapping table (handle -> axis_id)
return function (input, mappings)
  assert(input, "No input module loaded")
  _toggleEvents()
  _input = input
  Configure.load(mappings, input.getJoystick())
end

