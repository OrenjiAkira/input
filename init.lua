
local INPUT = {}
local FS = love.filesystem

local _TYPE_ENUM = { string = 0, number = 1, table = 2 }
local _NOTHING = function () end

local _joystick
local _digital
local _analog
local _hat
local _pressed = {}
local _released = {}
local _held = {}

local _loadFileString
local _stringTable
local _isActionActivated
local _keyPressed
local _keyReleased
local _loadJoystick
local _joystickPressed
local _joystickReleased

function INPUT.wasActionPressed(action)
  return _digital[action] and _isActionActivated(_digital[action], _pressed)
end

function INPUT.wasActionReleased(action)
  return _digital[action] and _isActionActivated(_digital[action], _released)
end

function INPUT.wasAnyPressed(deadzone)
  if deadzone and _joystick then
    for axis_name, axis in pairs(_analog) do
      if _joystick:getAxis(axis) >= deadzone then
        return true
      end
    end
    for hat_name, hat in pairs(_hat) do
      if _joystick:getHat(hat) ~= 'c' then
        return true
      end
    end
  end
  for action in pairs(_digital) do
    if _isActionActivated(_digital[action], _pressed) then
      return true
    end
  end
  return false
end

function INPUT.isActionDown(action)
  return _digital[action] and _isActionActivated(_digital[action], _held)
end

function INPUT.getAxis(axis_name)
  if not _joystick then return 0 end
  return _analog[axis_name] and _joystick:getAxis(_analog[axis_name]) or 0
end

function INPUT.getHat(hat_name)
  if not _joystick then return 'c' end
  return _hat[hat_name] and _joystick:getHat(_hat[hat_name]) or 'c'
end

function INPUT.getJoystick()
  return _joystick
end

function INPUT.setup(inputmap)
  _digital = inputmap.digital or {}
  _analog  = inputmap.analog or {}
  _hat     = inputmap.hat or {}

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

function INPUT.save(path, encoder)
  if not _digital or not _analog or not _hat then return end
  local map = {
    digital = _digital,
    analog = _analog,
    hat = _hat,
  }
  local content = encoder and encoder(map) or "return ".._stringTable(map)
  local file = assert(FS.newFile(path, "w"))
  assert(file:write(content))
  return assert(file:close())
end

function INPUT.load(path, decoder)
  local content, err
  if decoder then
    content, err = _loadFileString(path)
    content = content and decoder(content)
  else
    content, err = FS.load(path)
    content = content and content()
  end
  return content and
         INPUT.setup(content), err
end

function INPUT.delete(path)
  return FS.exists(path) and FS.remove(path)
end

function INPUT.getMap()
  return {
    digital = _digital,
    analog = _analog,
    hat = _hat,
  }
end

function _isActionActivated(action_keys, activated_keys, idx)
  local n = idx or 1 -- index of list
  if action_keys[n] == nil then return false end -- end of list
  return activated_keys[action_keys[n]] or
         _isActionActivated(action_keys, activated_keys, n+1)
end

function _keyPressed(key)
  _pressed[key] = true
  _held[key] = true
end

function _keyReleased(key)
  _released[key] = true
  _held[key] = false
end

function _loadJoystick(joystick)
  _joystick = joystick
  local rumble = _joystick:setVibration(1, 1, .5)
  print(("Found %s: rumble %s"):format(_joystick, rumble and "on" or "off"))
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

function _loadFileString(filename)
  local filedata, err = FS.newFileData(filename)
  return filedata and filedata:getString(), err
end

function _stringTable(t)
  local s = "{\n"
  for k,v in pairs(t) do
    local key, value = false, false
    local key_type, value_type = _TYPE_ENUM[type(k)], _TYPE_ENUM[type(v)]

    -- key has to be string or number
    if key_type == 0 then
      key = ("%s = "):format(k)
    elseif key_type == 1 then
      key = ""
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
      s = s .. "  " .. key .. value .. ",\n"
    end
  end
  s = s .. "}"
  return s
end

return INPUT

