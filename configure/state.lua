
local Configure = {}

-- constants
local STATES = {
  "GREETINGS", "DIGITAL", "ANALOG", "CONFIRM",
}
local DIV = "-------------------------------"
local LINE = "-- "
local ANALOG
local DIGITAL

-- locals
local _joystick
local _mappings
local _context

function Configure.load(mappings, joystick)
  assert(mappings and mappings.digital and mappings.analog,
         "Invalid mappings argument passed.")
  print(DIV)
  print(LINE.."Start mapping inputs!")

  ANALOG, DIGITAL = {}, {}
  for handle in pairs(mappings.digital) do
    table.insert(DIGITAL, handle)
  end
  for handle in pairs(mappings.analog) do
    table.insert(ANALOG, handle)
  end
  table.sort(DIGITAL)
  table.sort(ANALOG)

  _joystick = joystick
  _mappings = mappings
  _context = 1
end


--[[ UPDATE ]]--

local DEADZONE = .2

local _pressed
local _current
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
      Configure.quit(_mappings)
    end
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

function _flush()
  _pressed = nil
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
    _mappings.digital[handle] = key
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
local FONT

local _drawWindow
local _drawMappings
local _drawGreetings
local _drawDigital
local _drawAnalog
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
    _drawConfirm(g)
  elseif _context == 5 then
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
  g.setColor(0x1d, 0x35, 0x47)
  g.rectangle("fill", -PD, -PD, width+PD*2, height+PD*2)
  g.setColor(0xff, 0xff, 0xff)
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
  end
  for _,action in ipairs(DIGITAL) do
    local key = _mappings.digital[action]
    local unset = (key == true) and "UNSET"
    local button = (type(key) == 'number') and ("BTN %d"):format(key)
    if handle == action then
      g.setColor(80, 100, 255)
    else
      g.setColor(255, 255, 255)
    end
    g.print(("%s: [%s]"):format(action, unset or button or key))
    g.translate(0, height)
  end
  g.translate(0, height)
  for _,axis_name in ipairs(ANALOG) do
    local idx = _mappings.analog[axis_name]
    local unset = (idx == true) and "UNSET"
    if handle == axis_name then
      g.setColor(80, 180, 255)
    else
      g.setColor(255, 255, 255)
    end
    g.print(("%s: [%s]"):format(axis_name, unset or idx))
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
(current: *[%s]*)]=]
function _drawDigital(g)
  local width, height = g.getDimensions()
  local handle = DIGITAL[_current]
  local current = _mappings.digital[handle]
  current = (current == true) and "UNSET" or current
  current = (type(current) == 'number')
            and ("BTN %d"):format(current) or current
  if handle and current then
    _drawWindow(map_the_digital:format(handle, current),
                width/2, height/2, 360, "center")
  end
end

local map_the_analog = [=[
Move the analog input you want for *[%s]*
(current: *[%s]*)]=]
function _drawAnalog(g)
  local width, height = g.getDimensions()
  local handle = ANALOG[_current]
  local current = _mappings.analog[handle]
  current = (current == true) and "UNSET" or current
  current = (type(current) == 'number')
            and ("AXIS #%s"):format(current) or "UNSET"
  if handle and current then
    _drawWindow(map_the_analog:format(handle, current),
                width/2, height/2, 360, "center")
  end
end


local are_you_sure = [=[
Are you sure? *[y/n]*]=]
function _drawConfirm(g)
  local width, height = g.getDimensions()
  _drawWindow(are_you_sure, width/2, height/2, 360, "center")
end


--[[ /RENDERING ]]--




return Configure


