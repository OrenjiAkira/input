
local INPUT = {}
local FS = love.filesystem

local _TYPE_ENUM = { string = 0, number = 1 }
local _CONTROLS_FILENAME = "controls"

local _joystick
local _digital
local _analog
local _pressed = {}
local _released = {}

local _stringTable
local _keyPressed
local _keyReleased
local _loadJoystick
local _joystickPressed
local _joystickReleased

function INPUT.isActionPressed(action)
  return _pressed[_digital[action]]
end

function INPUT.isActionReleased(action)
  return _released[_digital[action]]
end

function INPUT.isActionHeld(action)
  local key = _digital[action]
  local key_type = _TYPE_ENUM[type(key)]
  if key_type == 0 then
    return love.keyboard.isDown(key)
  elseif _joystick and key_type == 1 then
    return _joystick:isDown(key)
  end
end

function INPUT.getAxis(axis_name)
  if not _joystick then return 0 end
  return _joystick:getAxis(_analog[axis_name])
end

function INPUT.setup(digital, analog)
  _digital = digital or {}
  _analog = analog or {}
  love.keypressed = _keyPressed
  love.keyreleased = _keyReleased
  love.joystickpressed  = _joystickPressed
  love.joystickreleased = _joystickReleased
  love.joystickadded = _loadJoystick
  return true
end

function INPUT.flush()
  for k in pairs(_pressed) do _pressed[k] = false end
  for k in pairs(_released) do _released[k] = false end
end

function INPUT.save()
  if not _digital or not _analog then return end
  local dmap = _stringTable(_digital)
  local amap = _stringTable(_analog)
  local content = "return { digital = "..dmap..", analog = "..amap.." }"
  local file = assert(FS.newFile(_CONTROLS_FILENAME, "w"))
  assert(file:write(content))
  return assert(file:close())
end

function INPUT.load()
  local content, err = FS.load(_CONTROLS_FILENAME)
  content = content and content()
  return content and INPUT.setup(content.digital, content.analog), err
end

function _keyPressed(key)
  _pressed[key] = true
end

function _keyReleased(key)
  _released[key] = true
end

function _loadJoystick(joystick)
  _joystick = joystick
  local rumble = _joystick:setVibration(1, 1, .5)
  print(("%s: rumble %s"):format(_joystick, rumble and "on" or "off"))
end

function _joystickPressed(joystick, button)
  if not joystick or joystick ~= _joystick then
    return _loadJoystick(joystick)
  end
  _pressed[button] = true
end

function _joystickReleased(joystick, button)
  if joystick ~= _joystick then return end
  _released[button] = true
end

function _stringTable(t)
  local s = "{"
  for k,v in pairs(t) do
    local key, value = false, false
    local key_type, value_type = _TYPE_ENUM[type(k)], _TYPE_ENUM[type(v)]

    -- key has to be string
    if key_type == 0 then
      key = "['"..k.."']"
    end

    -- value can be either string or number
    if value_type == 0 then
      value = "'"..v.."'"
    elseif value_type == 1 then
      value = tostring(v)
    end

    if key and value then
      s = s .. key .. " = " .. value .. ","
    end
  end
  s = s:gsub("(,)$", "")
  s = s .. "}"
  return s
end

return INPUT

