
-- constants
local DIV = "-------------------------------"
local LINE = "--"
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
local _start
local _toggleEvents

-- loads or unloads inputs
function _toggleEvents()
  for _,event in pairs(CALLBACKS) do
    Configure[event], love[event] = love[event], Configure[event]
  end
end

function Configure.quit()
  print(LINE, "All set, carry on")
  print(DIV)
  _toggleEvents()
end

-- mappings.digital is a digital mapping table (handle -> key/button)
-- mappings.analog is an analog mapping table (handle -> axis_id)
return function (input, mappings)
  _toggleEvents()
  Configure.load(input, mappings)
end

