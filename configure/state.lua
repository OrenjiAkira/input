
local Configure = {}

-- constants
local STATES = {
  "GREETINGS", "DIGITAL", "ANALOG", "CONFIRM",
}
local DIV = "-------------------------------"
local LINE = "--"


-- locals
local _input
local _mappings
local _context

function Configure.load(input, mappings)
  assert(input, "No input module loaded")
  assert(mappings and mappings.digital and mappings.analog,
         "Invalid mappings argument passed.")
  print(DIV)
  _input = input
  _mappings = mappings
  _context = 1
end


--[[ UPDATE ]]--

local DEADZONE = .2

local _pressed = {}
local _last_handle
local _joystick
local _flush
local _wait
local _loadJoystick
local _updateGreetings
local _updateDigital
local _updateAnalog
local _updateConfirm

function Configure.update(dt)

  if not _wait then _waitFor(.2) end

  -- update contexts
  if     _context == 1 then
    _updateGreetings(dt)
  elseif _context == 2 then
    _updateDigital(dt)
  elseif _context == 3 then
    _updateAnalog(dt)
  elseif _context == 4 then
    _updateConfirm(dt)
  elseif _context == 5 then
    if _wait(dt) then
      Configure.quit()
    end
  end

  -- flush input
  _flush()
end

function Configure.keypressed(key)
  _pressed[key] = true
end

function Configure.joystickpressed(joystick, button)
  if not _joystick or joystick ~= _joystick then
    return _loadJoystick(joystick)
  end
  _pressed[button] = true
end

function _flush()
  for key in pairs(_pressed) do _pressed[key] = false end
end

function _waitFor(sec)
  _wait = function(dt)
    sec = math.max(0, sec - dt)
    return sec <= 0
  end
end

function _loadJoystick(joystick)
  _joystick = joystick
  local rumble = _joystick:setVibration(1, 1, .5)
  print(("%s: rumble %s"):format(_joystick, rumble and "on" or "off"))
end

function _updateGreetings(dt)
  if not _wait(dt) then return end
  if _pressed['return'] then
    _context = _context + 1
    _waitFor(.25)
  end
end

function _updateDigital()
  if not _wait(dt) then return end
  local key = next(_pressed)
  local handle = next(_mappings.digital, _last_handle)
  if handle == nil then
    _context = _context + 1
    _last_handle = nil
    _waitFor(.25)
  elseif key then
    _mappings.digital[handle] = key
    _last_handle = handle
    _waitFor(.25)
  end
end

function _updateAnalog()
  if not _wait(dt) then return end
  local handle = next(_mappings.analog, _last_handle)
  if handle == nil then
    _context = _context + 1
    _last_handle = nil
    _waitFor(.25)
  elseif _joystick then
    local axis_id
    local axes = {_joystick:getAxes()}
    for idx, value in ipairs(axes) do
      local absolute = math.abs(value)
      if absolute > DEADZONE then
        axis_id = axis_id or idx
        if absolute > axes[axis_id] then
          axis_id = idx
        end
      end
    end
    if axis_id then
      _mappings.analog[handle] = axis_id
      _last_handle = handle
      _waitFor(.25)
    end
  end
end

function _updateConfirm()
  if not _wait(dt) then return end
  if _pressed['y'] then
    _context = _context + 1
    _waitFor(0.75)
  elseif _pressed['n'] then
    _context = 1
    _waitFor(.25)
  end
end


--[[ /UPDATE ]]--




--[[ RENDERING ]]--


local PD = 8
local LH = 1
local FSZ = 24
local FONT

local _drawWindow
local _drawGreetings
local _drawDigital
local _drawAnalog
local _drawConfirm

function Configure.draw()
  local g = love.graphics
  -- init font
  if not FONT then
    FONT = g.newFont(FSZ)
    FONT:setLineHeight(LH)
  end
  g.setFont(FONT)

  -- draw contexts
  if     _context == 1 then
    _drawGreetings(g)
  elseif _context == 2 then
    _drawDigital(g)
  elseif _context == 3 then
    _drawAnalog(g)
  elseif _context == 4 then
    _drawConfirm(g)
  elseif _context == 5 then
    local width, height = g.getDimensions()
    _drawWindow("All done!", width/2, height/2, 360, "center")
  end
end

function _drawWindow(text, x, y, wlimit, align)
  local g = love.graphics
  local width, wrapped = _font:getWrap(text, wlimit)
  local height = #wrapped * _font:getHeight() * LH
  g.push()
  g.translate(x - width/2, y - height/2)
  g.setColor(0x22, 0x50, 0x72)
  g.rectangle("fill", -PD, -PD, width+PD*2, height+PD*2)
  g.setColor(0xff, 0xff, 0xff)
  g.printf(text, 0, 0, wlimit, align)
  local handle, current = next(_mappings, _last_handle)
  current = current == true and "UNSET"
  _drawWindow(map_the_digital:format(handle, current),
              width/2, height/2, 360, "left")
  g.pop()
end

function _drawMappings(g)
  local height = _font:getHeight()
  g.push()
  g.translate(32, 32)
  for action, key in pairs(_mappings.digital) do
    local unset = (key == true) and "UNSET"
    local button = (type(key) == 'number') and ("BTN %d"):format(key)
    g.print(("%s: [%s]"):format(action, unset or button or key))
    if _context == 2 and _last_handle == action then
      g.setColor(80, 100, 255)
    else
      g.setColor(255, 255, 255)
    end
    g.translate(0, height)
  end
  g.translate(0, height)
  for axis_name, idx in pairs(_mappings.analog) do
    local unset = (idx == true) and "UNSET"
    g.print(("%s: [%s]"):format(action, unset or idx))
    if _context == 3 and _last_handle == action then
      g.setColor(80, 100, 255)
    else
      g.setColor(255, 255, 255)
    end
    g.translate(0, height)
  end
  g.pop()
end

local greetings = [=[
We'll be mapping all actions to keys now.
Press [enter/return] to continue.]=]
function _drawGreetings(g)
  local width, height = g.getDimensions()
  _drawWindow(greetings, width/2, height/2, 360, "left")
end

local map_the_digital = [=[
Press the key you want for [%s]
(current: %s)]=]
function _drawDigital(g)
  local width, height = g.getDimensions()
  local handle, current = next(_mappings.digital, _last_handle)
  current = (current == true) and "UNSET" or current
  current = (type(current) == 'number')
            and ("BTN %d"):format(current) or current
  _drawWindow(map_the_digital:format(handle, current),
              width/2, height/2, 360, "center")
end

local map_the_analog = [=[
Move the analog input you want for [%s]
(current: %s)]=]
function _drawAnalog(g)
  local width, height = g.getDimensions()
  local handle, current = next(_mappings.analog, _last_handle)
  current = (current == true) and "UNSET" or current
  current = (type(current) == 'number')
            and ("AXIS #%s"):format(current) or "UNSET"
  _drawWindow(map_the_analog:format(handle, current),
              width/2, height/2, 360, "center")
end


local are_you_sure = [=[
Are you sure? [y/n]]=]
function _drawConfirm(g)
  local width, height = g.getDimensions()
  _drawWindow(greetings, width/2, height/2, 360, "center")
end


--[[ /RENDERING ]]--




return Configure


