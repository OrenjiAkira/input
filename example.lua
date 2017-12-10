
-- usage example --


-- first we require the module
local INPUT = require 'input'
local CONFIGURE = require 'input.configure'
local USE_JSON, JSON = pcall(require, 'dkjson')
local USE_TOML, TOML = pcall(require, 'toml')

-- it also needs to be set up with a virtual mapping;
-- that's specific to your game
local DIGITAL = {
  QUIT      = {"f8"},
  D_UP      = {"up"},
  D_LEFT    = {"left"},
  D_DOWN    = {"down"},
  D_RIGHT   = {"right"},
  BUTTON_01 = {1},
  BUTTON_02 = {2},
  BUTTON_03 = {3},
  BUTTON_04 = {4},
  BUTTON_05 = {5},
  BUTTON_06 = {6},
  BUTTON_07 = {7},
  BUTTON_08 = {8},
  BUTTON_09 = {9},
  BUTTON_10 = {10},
  BUTTON_11 = {11},
  BUTTON_12 = {12},
}

local ANALOG = {
  X_AXIS  = 2,
  Y_AXIS  = 4,
}

local HAT = {
  HAT_DIR = 1
}

-- we call the setup method and pass the virtual mapping as argument
function love.load()
  -- you can load it from your save data with 'load'
  -- > returns false if there's no controls save or if it's corrupted,
  -- > returns true if the controls were successfully loaded
  love.filesystem.setIdentity("joystick")
  local decoder = (USE_JSON and JSON.decode) or (USE_TOML and TOML.parse)
  local loaded = INPUT.load(decoder)
  if not loaded then
    -- or you can manually load it from memory with 'setup'
    -- > returns true always
    INPUT.setup(DIGITAL, ANALOG, HAT)
  end
end


function love.quit()
  -- you can save your mappings with 'save'
  -- returns true on success, throws an error if it fails
  local encoder
  if USE_JSON then
    function encoder(data)
      return JSON.encode(data, { indent = true })
    end
  elseif USE_TOML then
    function encoder(data)
      return TOML.encode(data)
    end
  end
  INPUT.save(encoder)
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

  local dir = INPUT.getHat('HAT_DIR')
  if dir ~= 'c' then
    if dir:match('l') then x = -1 end
    if dir:match('r') then x =  1 end
    if dir:match('u') then y = -1 end
    if dir:match('d') then y =  1 end
  end

  if x == 0 and y == 0 then
    x = x + (INPUT.isActionDown('D_LEFT')  and -1 or 0)
    x = x + (INPUT.isActionDown('D_RIGHT') and  1 or 0)
    y = y + (INPUT.isActionDown('D_UP')    and -1 or 0)
    y = y + (INPUT.isActionDown('D_DOWN')  and  1 or 0)
  end

  INPUT.flush()

  if love.keyboard.isDown('f1') then
    local digital, analog, hat = INPUT.getMaps()
    CONFIGURE(INPUT, {digital = digital, analog = analog, hat = hat})
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

