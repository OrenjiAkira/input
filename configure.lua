
--[[ QUIT AND LOAD ]]--

local CALLBACKS = {
  'keypressed',
  'keyreleased',
  'joystickpressed',
  'joystickreleased',
  'joystickhat',
  'mousepressed',
  'mousereleased',
  'update',
  'draw'
}

-- constants
local DIV = "-------------------------------"
local LINE = "-- "
local STATES = {"GREETINGS", "DIGITAL", "ANALOG", "CONFIRM"}
local ANALOG
local DIGITAL
local HAT

-- important locals
local _joystick
local _mappings
local _context

-- forward declaration
local _input
local _toggleEvents

-- configure state
local Configure = {}

function Configure.load(mappings, joystick)
  assert(mappings and mappings.digital and mappings.analog,
         "Invalid mappings argument passed.")
  print(DIV)
  print(LINE.."Start mapping inputs!")

  ANALOG, DIGITAL, HAT = {}, {}, {}
  for handle in pairs(mappings.digital) do
    table.insert(DIGITAL, handle)
  end
  for handle in pairs(mappings.analog) do
    table.insert(ANALOG, handle)
  end
  for handle in pairs(mappings.hat) do
    table.insert(HAT, handle)
  end
  table.sort(DIGITAL)
  table.sort(ANALOG)
  table.sort(HAT)

  _joystick = joystick
  _mappings = mappings
  _context = 1
end


-- loads or unloads inputs
function _toggleEvents()
  for _,event in pairs(CALLBACKS) do
    Configure[event], love[event] = love[event], Configure[event]
  end
end

function Configure.quit(mappings)
  print(LINE.."All set, carry on")
  print(DIV)
  _input.setup(mappings)
  _input = nil
  _toggleEvents()
end


--[[ UPDATE ]]--

local DEADZONE = .5

local _pressed
local _current
local _flush
local _wait
local _loadJoystick
local _cycleActionInput
local _updateGreetings
local _updateDigital
local _updateAnalog
local _updateHat
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
    _updateHat(dt)
  elseif _context == 5 then
    _updateConfirm(dt)
  elseif _context == 6 and _wait(dt) then
    Configure.quit(_mappings)
  end

  -- flush input
  _flush()
end

function Configure.keypressed(key)
  _pressed = key
end

function Configure.joystickpressed(joystick, button)
  if not _joystick or joystick ~= _joystick then
    return _loadJoystick(joystick)
  end
  _pressed = button
end

function Configure.joystickhat(joystick, hat, direction)
  if not _joystick or joystick ~= _joystick then
    return _loadJoystick(joystick)
  end
  _hat = hat
end

function _flush()
  _pressed = nil
  _hat = nil
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
  print(LINE..
        ("Joystick found: %s (rumble %s)"):format(_joystick,
                                                  rumble and "on" or "off"
        )
  )
end

function _cycleActionInput(action_keys, new_key)
  action_keys[1], new_key = new_key, action_keys[1]
  action_keys[2], new_key = new_key, action_keys[2]
end

function _updateGreetings(dt)
  if not _wait(dt) then return end
  if _pressed == 'return' then
    _context = _context + 1
    _waitFor(.25)
  end
end

function _updateDigital(dt)
  if not _wait(dt) then return end
  _current = _current or 1
  local key = _pressed
  local handle = DIGITAL[_current]
  if handle == nil then
    _context = _context + 1
    _current = nil
    _waitFor(.25)
  elseif key then
    print(LINE..handle..":", key)
    _cycleActionInput(_mappings.digital[handle], key)
    _current = _current + 1
    _waitFor(.25)
  end
end

function _updateAnalog(dt)
  if not _wait(dt) then return end
  _current = _current or 1
  local handle = ANALOG[_current]
  if handle == nil then
    _context = _context + 1
    _current = nil
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
      print(LINE..handle..":", axis_id)
      _mappings.analog[handle] = axis_id
      _current = _current + 1
      _waitFor(.25)
    end
  end
end

function _updateHat(dt)
  if not _wait(dt) then return end
  _current = _current or 1
  local handle = HAT[_current]
  local hat_id = _hat
  if handle == nil then
    _context = _context + 1
    _current = nil
    _waitFor(.25)
  elseif _joystick and _hat then
    print(LINE..handle..":", hat_id)
    _mappings.hat[handle] = hat_id
    _current = _current + 1
    _waitFor(.25)
  end
end

function _updateConfirm(dt)
  if not _wait(dt) then return end
  if _pressed == 'y' then
    _context = _context + 1
    _waitFor(0.75)
  elseif _pressed == 'n' then
    _context = 1
    _waitFor(.25)
  end
end


--[[ /UPDATE ]]--




--[[ RENDERING ]]--


local PD = 16
local LH = 1
local FSZ = 16
local NEUTRAL = {0xff, 0xff, 0xff}
local HIGHLIGHT = {244, 199, 0}
local WINDOW = {0x1d, 0x35, 0x47}
local FONT

local _drawWindow
local _drawMappings
local _drawGreetings
local _drawDigital
local _drawAnalog
local _drawHat
local _drawConfirm
local _parseColoredText

function Configure.draw()
  local g = love.graphics
  -- init font
  if not FONT then
    FONT = g.newFont(FSZ)
    FONT:setLineHeight(LH)
  end
  g.setFont(FONT)

  _drawMappings(g)

  -- draw contexts
  if     _context == 1 then
    _drawGreetings(g)
  elseif _context == 2 then
    _drawDigital(g)
  elseif _context == 3 then
    _drawAnalog(g)
  elseif _context == 4 then
    _drawHat(g)
  elseif _context == 5 then
    _drawConfirm(g)
  elseif _context == 6 then
    local width, height = g.getDimensions()
    _drawWindow("All done!", width/2, height/2, 360, "center")
  end
end

function _parseColoredText(text)
  local colored = {NEUTRAL}
  local l = 1
  for r = 1, #text do
    if text:byte(r) == 42 then
      local color = colored[#colored]
      if color == NEUTRAL then
        color = HIGHLIGHT
      elseif color == HIGHLIGHT then
        color = NEUTRAL
      end
      local excerpt = text:sub(l, r-1)
      table.insert(colored, excerpt)
      table.insert(colored, color)
      l = r + 1
    end
  end
  table.insert(colored, text:sub(l,-1))
  return colored
end

function _drawWindow(text, x, y, wlimit, align)
  local g = love.graphics
  local _, wrapped = FONT:getWrap(text, wlimit)
  local height = #wrapped * FONT:getHeight() * LH
  local width = wlimit
  local colored = _parseColoredText(text)
  g.push()
  g.translate(x - width/2, y - height/2)
  g.setColor(WINDOW)
  g.rectangle("fill", -PD, -PD, width+PD*2, height+PD*2)
  g.setColor(NEUTRAL)
  g.printf(colored, 0, 0, width, align)
  g.pop()
end

function _drawMappings(g)
  local height = FONT:getHeight()
  g.push()
  g.translate(32, 32)
  local handle
  if _context == 2 then
    handle = DIGITAL[_current]
  elseif current == 3 then
    handle = ANALOG[_current]
  elseif current == 4 then
    handle = HAT[_current]
  end
  for _,action in ipairs(DIGITAL) do
    local key1, key2 = unpack(_mappings.digital[action])
    local btn1 = (type(key1) == 'number') and ("BTN %d"):format(key1)
    local btn2 = (type(key2) == 'number') and ("BTN %d"):format(key2)
    key1 = (type(key1) == 'string') and key1 or "UNSET"
    key2 = (type(key2) == 'string') and key2 or "UNSET"
    if handle == action then g.setColor(HIGHLIGHT)
    else g.setColor(NEUTRAL) end
    g.print(("%s: [%s] [%s]"):format(action, btn1 or key1, btn2 or key2)
    )
    g.translate(0, height)
  end
  g.translate(0, height)
  for _,axis_name in ipairs(ANALOG) do
    local idx = _mappings.analog[axis_name]
    idx = (type(idx) == 'number') and idx or "UNSET"
    if handle == axis_name then g.setColor(HIGHLIGHT)
    else g.setColor(NEUTRAL) end
    g.print(("%s: [%s]"):format(axis_name, idx))
    g.translate(0, height)
  end
  g.translate(0, height)
  for _,hat_name in ipairs(HAT) do
    local idx = _mappings.hat[hat_name]
    idx = (type(idx) == 'number') and idx or "UNSET"
    if handle == hat_name then g.setColor(HIGHLIGHT)
    else g.setColor(NEUTRAL) end
    g.print(("%s: [%s]"):format(hat_name, idx))
    g.translate(0, height)
  end
  g.pop()
end

local greetings = [=[
We'll be mapping all actions to keys now.
Press *[enter/return]* to continue.]=]
function _drawGreetings(g)
  local width, height = g.getDimensions()
  _drawWindow(greetings, width/2, height/2, 360, "center")
end

local map_the_digital = [=[
Press the key you want for *[%s]*
(current: *[%s] [%s]*)]=]
function _drawDigital(g)
  local width, height = g.getDimensions()
  local handle = DIGITAL[_current]
  if not handle then return end
  local key1, key2 = unpack(_mappings.digital[handle])
  local btn1 = (type(key1) == 'number') and ("BTN %d"):format(key1)
  local btn2 = (type(key2) == 'number') and ("BTN %d"):format(key2)
  key1 = (type(key1) == 'string') and key1 or "UNSET"
  key2 = (type(key2) == 'string') and key2 or "UNSET"

  if handle and key1 then
    _drawWindow(map_the_digital:format(handle, btn1 or key1, btn2 or key2),
                width/2, height/2, 360, "center"
    )
  end
end

local map_the_analog = [=[
Move the analog input you want for *[%s]*
(current: *[%s]*)]=]
function _drawAnalog(g)
  local width, height = g.getDimensions()
  local handle = ANALOG[_current]
  if not handle then return end
  local axis_id = _mappings.analog[handle]
  axis_id = (type(axis_id) == 'number')
            and ("AXIS #%s"):format(axis_id) or "UNSET"
  if handle and axis_id then
    _drawWindow(map_the_analog:format(handle, axis_id),
                width/2, height/2, 360, "center"
    )
  end
end

local map_the_hat = [=[
Move the hat input you want for *[%s]*
(current: *[%s]*)]=]
function _drawHat(g)
  local width, height = g.getDimensions()
  local handle = HAT[_current]
  if not handle then return end
  local hat_id = _mappings.hat[handle]
  hat_id = (type(hat_id) == 'number') and ("HAT #%s"):format(hat_id) or "UNSET"
  if handle and hat_id then
    _drawWindow(map_the_hat:format(handle, hat_id),
                width/2, height/2, 360, "center"
    )
  end
end

local are_you_sure = [=[
Are you sure? *[y/n]*]=]
function _drawConfirm(g)
  local width, height = g.getDimensions()
  _drawWindow(are_you_sure, width/2, height/2, 360, "center")
end


--[[ /RENDERING ]]--




-- mappings.digital is a digital mapping table (handle -> key/button)
-- mappings.analog is an analog mapping table (handle -> axis_id)
return function (input, mappings)
  assert(input, "No input module loaded")
  _toggleEvents()
  _input = input
  Configure.load(mappings, input.getJoystick())
end

