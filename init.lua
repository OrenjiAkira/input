
local INPUT = {}
local FS = love.filesystem

local _TYPE_ENUM = { string = 0, number = 1, table = 2 }
local _CONTROLS_FILENAME = "controls"
local _NOTHING = function () end

local _joystick
local _digital
local _analog
local _pressed = {}
local _released = {}
local _held = {}

local _stringTable
local _keyPressed
local _keyReleased
local _loadJoystick
local _joystickPressed
local _joystickReleased

local function _isActionActivated(action_keys, activated_keys, idx)
  local n = idx or 1 -- index of list
  if action_keys[n] == nil then return false end -- end of list
  return activated_keys[action_keys[n]] or
         _isActionActivated(action_keys, activated_keys, n+1)
end

function INPUT.wasActionPressed(action)
  return _digital[action] and _isActionActivated(_digital[action], _pressed)
end

function INPUT.wasActionReleased(action)
  return _digital[action] and _isActionActivated(_digital[action], _released)
end

function INPUT.isActionDown(action)
  return _digital[action] and _isActionActivated(_digital[action], _held)
end

function INPUT.getAxis(axis_name)
  if not _joystick then return 0 end
  return _joystick:getAxis(_analog[axis_name])
end

function INPUT.getJoystick()
  return _joystick
end

function INPUT.setup(digital, analog)
  _digital = digital or {}
  _analog = analog or {}

  local default_keypress        = love.keypressed       or _NOTHING
  local default_keyrelease      = love.keyreleased      or _NOTHING
  local default_joystickpress   = love.joystickpressed  or _NOTHING
  local default_joystickrelease = love.joystickreleased or _NOTHING
  local default_joystickadded   = love.joystickadded    or _NOTHING

  love.keypressed = function(key)
    default_keypress(key)
    _keyPressed(key)
  end
  love.keyreleased = function(key)
    default_keyrelease(key)
    _keyReleased(key)
  end
  love.joystickpressed = function(joystick, button)
    default_joystickpress(joystick, button)
    _joystickPressed(joystick, button)
  end
  love.joystickreleased = function(joystick, button)
    default_joystickrelease(joystick, button)
    _joystickReleased(joystick, button)
  end
  love.joystickadded = function(joystick)
    default_joystickadded(joystick)
    _loadJoystick(joystick)
  end

  return true
end

function INPUT.flush()
  -- this should be called last thing in the main update function
  -- it resets the states of 'pressed' and 'released' from keys,
  -- making only 'held' keys persist after first frame.
  for k in pairs(_pressed) do _pressed[k] = false end
  for k in pairs(_released) do _released[k] = false end
end

function INPUT.save()
  if not _digital or not _analog then return end
  local content = "return ".._stringTable({ digital = _digital, analog = _analog })
  local file = assert(FS.newFile(_CONTROLS_FILENAME, "w"))
  print(content)
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
  _held[key] = true
  print("down:", key)
end

function _keyReleased(key)
  _released[key] = true
  _held[key] = false
  print("up:  ", key)
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
  _held[button] = true
end

function _joystickReleased(joystick, button)
  if joystick ~= _joystick then return end
  _released[button] = true
  _held[button] = false
end

function _stringTable(t)
  local s = "{\n"
  for k,v in pairs(t) do
    local key, value = false, false
    local key_type, value_type = _TYPE_ENUM[type(k)], _TYPE_ENUM[type(v)]

    -- key has to be string or number
    if key_type == 0 then
      key = k
    elseif key_type == 1 then
      key = ("[%d]"):format(k)
    end

    -- value can be either string or number
    if value_type == 0 then
      value = "'"..v.."'"
    elseif value_type == 1 then
      value = tostring(v)
    elseif value_type == 2 then
      value = _stringTable(v)
    end

    if key and value then
      s = s .. "  " .. key .. " = " .. value .. ",\n"
    end
  end
  s = s .. "}"
  return s
end

return INPUT

