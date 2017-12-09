
-- input mapping configuring interface

-- love handlers backup
local _backup = {}

-- input module
local _input

-- current joystick
local _joystick

-- mapping tables
local _digital
local _analog

-- current mapping table and handle
local _mapping
local _handle
local _are_you_sure
local _yes_i_am_sure

-- forward declaration
local _quit
local _font

-- texts
local _greetings = [=[
We're going to map the controls for your game.
Press any (digital) key or button to continue.
]=]
local _map_digital = [=[
Press key or button for: [%s]
(current: [%s])
]=]
local _map_analog = [=[
Move the analog switch/stick for: [%s]
(current: [%s])
]=]
local _current_mapping = "%s: [%s]"

local deadzone = 0.200

local STATE = {}

function STATE.joystickadded(joystick)
  _joystick = joystick
  local rumble = _joystick:setVibration(1, 1, .5)
  print(("%s: rumble %s"):format(_joystick, rumble and "on" or "off"))
end

function STATE.joystickpressed(joystick, button)
  -- configure joystick
  if _joystick ~= joystick then return STATE.joystickadded(joystick) end

  -- greeting confirm
  if not _mapping then
    _mapping = _digital
    _handle = next(_digital)
    return
  end

  -- mapping
  if _mapping == _digital then
    _mapping[_handle] = button
    _handle = next(_digital, _handle)
    if _handle == nil then
      _mapping = _analog
      _handle = next(_analog)
    end
    return
  end
end

function STATE.keypressed(key)
  -- greeting confirm
  if not _mapping then
    _mapping = _digital
    _handle = next(_digital)
    return
  end

  -- mapping
  if _mapping == _digital then
    _mapping[_handle] = key
    _handle = next(_digital, _handle)
    if _handle == nil then
      _mapping = _analog
      _handle = next(_analog)
    end
    return
  end

  -- are you sure
  if _are_you_sure then
    if key == 'y' then
      _quit()
    elseif key == 'n' then
      _mapping = nil
      _handle = nil
    end
  end
end

function STATE.update(dt)
  if _mapping == _analog then
    if _joystick then
      local n, axes = select('#', _joystick:getAxes()), {_joystick:getAxes()}
      local min, choice = deadzone, false
      for i = 1, n do
        if axes[i] > min then
          min = axes[i]
          choice = i
        end
      end
      if choice then
        _analog[_handle] = choice
        _handle = next(_analog, _handle)
      end
    else
      _handle = nil
    end
  end

  if _mapping and not _handle then
    _are_you_sure = true
    return
  end
end

function STATE.draw()
  local g = _backup.graphics
  local width, height = g.getDimensions()
  local midx, midy = width/2, height/2
  g.setBackgroundColor(0, 0, 0)
  g.setColor(255, 255, 255)

  _font = _font or g.newFont(24)
  g.setFont(_font)

  -- greetings confirm
  if not _mapping then
    return g.printf(_greetings, midx-256, midy-32, 256, "left")
  end

  -- list mappings
  g.push()
  g.translate(32, 32)
  for action, key in pairs(_digital) do
    local unset = (key == true) and "UNSET" or false
    local button = (type(key) == 'number') and ("BTN %d"):format(key)
    g.print(_current_mapping:format(action, unset or button or key))
    g.translate(0, 24)
  end
  g.translate(0, 24)
  if _joystick then
    for axis_name, axis_id in pairs(_analog) do
      local unset = (axis_id == true) and "UNSET" or false
      local value = ("AXIS #%s"):format(axis_id)
      g.print(_current_mapping:format(axis_name, unset or value))
      g.translate(0, 24)
    end
  end
  g.pop()

  local w = 256
  local pd = 8
  g.setColor(0x1E, 0x5C, 0x8C)
  g.rectangle("fill", midx-w/2-pd, midy-32-pd, w+2*pd, 2*_font:getHeight()+2*pd)
  g.setColor(255, 255, 255)

  if _are_you_sure then
    return g.printf("Are you sure? [y/n]", midx-w/2, midy-16, w, "center")
  end

  if _mapping == _digital then
    -- mapping digital
    local action_name, current = _handle, _digital[_handle]
    return g.printf(_map_digital:format(action_name, current),
             midx-w/2, midy-32, w, "center"
    )
  elseif _mapping == _analog then
    -- mapping analog
    local axis_name, current = _handle, _analog[_handle]
    return g.printf(_map_digital:format(axis_name, current),
             midx-w/2, midy-32, w, "center"
    )
  end

end

-- quit input mapping state
function _quit()
  for k in pairs(STATE) do love[k] = nil end
  for k,v in pairs(_backup) do love[k] = v end

  -- merge
  _input.setup(_digital, _analog)
end

-- loading function
return function (input, digital, analog)
  assert(input, "No input module received!")
  assert(digital, "No digital mapping table received!")
  assert(analog, "No analog mapping table received!")

  --[[--
  --
  -- digital and analog should be "set" tables
  -- meaning their keys should be strings corresponding to
  -- your game's actions' "handle names" (like "UP" or "ACTION_A")
  -- the values should be "not false", it really doesn't matter otherwise
  --
  --]]--

  for k in pairs(_backup) do _backup[k] = nil end
  for k,v in pairs(love) do _backup[k] = v end
  for k in pairs(_backup) do love[k] = nil end
  for k,v in pairs(STATE) do love[k] = v end

  _digital, _analog = {}, {}
  for k,v in pairs(digital) do _digital[k] = v end
  for k,v in pairs(analog) do _analog[k] = v end

  _input = input
  _mapping = nil
  _handle = nil
end

