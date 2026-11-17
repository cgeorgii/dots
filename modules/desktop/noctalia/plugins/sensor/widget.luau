-- The temperature of one thermal zone, found by its type since zone numbers
-- can change between boots. Coloured from the warning temperature on.

local thermal = "/sys/class/thermal"
local zone = noctalia.getConfig("zone")
local warn = noctalia.getConfig("warn")
local critical = noctalia.getConfig("critical")

local tempPath = nil

local function findZone()
  local names = noctalia.listDir(thermal)
  if not names then
    return nil
  end
  for _, name in ipairs(names) do
    if string.sub(name, 1, 12) == "thermal_zone" then
      local kind = noctalia.readFile(thermal .. "/" .. name .. "/type")
      if kind and string.gsub(kind, "%s+$", "") == zone then
        return thermal .. "/" .. name .. "/temp"
      end
    end
  end
  return nil
end

local function show(celsius)
  barWidget.setText(string.format("%d°C", celsius))
  barWidget.setTooltip({ zone, string.format("%d°C (warn %d, critical %d)", celsius, warn, critical) })
  if celsius >= critical then
    barWidget.setColor("error")
    barWidget.setGlyphColor("error")
  elseif celsius >= warn then
    barWidget.setColor("primary")
    barWidget.setGlyphColor("primary")
  else
    barWidget.setColor("on_surface")
    barWidget.setGlyphColor("on_surface")
  end
end

barWidget.setGlyph(noctalia.getConfig("glyph"))

function update()
  noctalia.setUpdateInterval(2000)
  tempPath = tempPath or findZone()
  if not tempPath then
    barWidget.setText("--")
    barWidget.setTooltip(zone .. ": no such thermal zone")
    return
  end
  noctalia.readFileAsync(tempPath, function(contents, _err)
    local milli = contents and tonumber((string.gsub(contents, "%s+$", "")))
    if milli then
      show(math.floor(milli / 1000 + 0.5))
    else
      -- The zone went away (a driver reload); look it up again next time
      tempPath = nil
      barWidget.setText("--")
    end
  end)
end
