
-- usage example --


-- first we require the module
local INPUT = require 'input'
local CONFIGURE = require 'input.configure'

-- it also needs to be set up with a virtual mapping;
-- that's specific to your game
local DIGITAL = {
  QUIT    = {"f8"},
  D_UP    = {"up"},
  D_LEFT  = {"left"},
  D_DOWN  = {"down"},
  D_RIGHT = {"right"},
  BUTTON_1 = {1},
  BUTTON_2 = {2},
  BUTTON_3 = {3},
  BUTTON_4 = {4},
  BUTTON_5 = {5},
  BUTTON_6 = {6},
  BUTTON_7 = {7},
  BUTTON_8 = {8},
  BUTTON_9 = {9},
  BUTTON_10 = {10},
  BUTTON_11 = {11},
  BUTTON_12 = {12},
}

local ANALOG = {
  X_AXIS = 2,
  Y_AXIS = 4,
}

-- we call the setup method and pass the virtual mapping as argument
function love.load()
  -- you can load it from your save data with 'load'
  -- > returns false if there's no controls save or if it's corrupted,
  -- > returns true if the controls were successfully loaded
  love.filesystem.setIdentity("joystick")
  local loaded = INPUT.load()
  if not loaded then
    -- or you can manually load it from memory with 'setup'
    -- > returns true always
    INPUT.setup(DIGITAL, ANALOG)
  end
end


function love.quit()
  -- you can save your mappings with 'save'
  -- returns true on success, throws an error if it fails
  INPUT.save()
end


local x, y = 0, 0
local held = {}

function love.update(dt)
  if INPUT.wasActionPressed('QUIT') then return love.event.quit() end

  -- set held buttons
  while #held > 0 do held[#held] = nil end
  for action, key in pairs(DIGITAL) do
    if INPUT.isActionDown(action) then held[#held+1] = action end
  end

  -- set directional input
  x, y = 0
  x = INPUT.getAxis('X_AXIS')
  y = INPUT.getAxis('Y_AXIS')
  if x == 0 and y == 0 then
    x = x + (INPUT.isActionDown('D_LEFT')  and -1 or 0)
    x = x + (INPUT.isActionDown('D_RIGHT') and  1 or 0)
    y = y + (INPUT.isActionDown('D_UP')    and -1 or 0)
    y = y + (INPUT.isActionDown('D_DOWN')  and  1 or 0)
  end

  INPUT.flush()

  if love.keyboard.isDown('f1') then
    CONFIGURE(INPUT, {digital = DIGITAL, analog = ANALOG})
  end
end

function love.draw()
  local g = love.graphics
  local width, height = g.getDimensions()
  local radius = 64
  local dot = 8
  local midx, midy = width/2, height/2

  g.setBackgroundColor(0, 0, 0)

  -- let's draw the directional input on the screen for debug
  g.push()
  g.translate(midx, midy)
  g.setColor(255, 255, 255)
  g.ellipse("line", 0, 0, radius)
  g.line(0, -radius, 0, radius)
  g.line(-radius, 0, radius, 0)
  g.printf(("[%.3f, %.3f]"):format(x, y),
           -radius, -radius-32, radius*2, "center")
  g.setColor(50, 100, 255)
  g.ellipse("fill", radius * x, radius * y, dot)

  g.printf("PRESS F1 TO RECONFIGURE CONTROLS",
           -radius,  radius+64, radius*2, "center")
  g.pop()

  -- now let's draw the currently held buttons on screen too
  g.push()
  g.setNewFont(16)
  g.setColor(255, 255, 255)
  g.translate(64, 64)
  for i,button in ipairs(held) do
    g.print(("[%s]"):format(button), 0, 0)
    g.translate(0, 16)
  end
  g.pop()
end

