local component = require("component")
local gpu = component.gpu
local term=require("term")
local graph={}
graph.ver="1.0"
graph.defaultResolution={80,25}
graph.defaultColorTable={
  0x00FF00, --top values
  0xFFFF00, --middle values
  0xFFCC33, --lower values
  0xFF0000  --lowest values
}
Graph={}
Graph.__index=Graph
function Graph:new(name,unit,colors)
  local obj=setmetatable({},Graph)
  obj.name=name or "Unnamed Graph"
  obj.unit=unit or ""
  obj.symbol="█"
  obj.colors=colors or graph.defaultColorTable
  obj.res=graph.defaultResolution
  obj.data={}
  obj.maxY=0
  obj.minY=math.huge
  obj.settings={
    showDate=true,
    adjustRange=true,
  }
  return obj
end
function Graph:drawMisc()
  gpu.setForeground(0xFFFFFF)
  local pixelValue=(self.maxY-self.minY)/20 -- Calculate the value for each pixel
  for i=0,20 do
    local value = math.floor(self.minY+pixelValue*i)
    gpu.set(1,25-i,tostring(value)) -- Display the value on the left
  end
  -- Display the latest value at the top
  local latest=self.data[#self.data] or 0
  gpu.set(1, 1, tostring(latest)) -- Display the latest value
  gpu.set(1, 2, self.unit)
  gpu.set(30, 1, self.name)
  if self.settings.showDate==true then gpu.set(67,1, os.date()) end
end
function Graph:plotColumn(x,_y)
  local scaledY = math.floor((_y-self.minY)/(self.maxY-self.minY)*20) -- Scale Y to fit the screen height
  local color = self:getColor(scaledY) -- Get color based on height
  gpu.setForeground(color) -- Set color for the column
  for y = -1, scaledY-1 do
    gpu.set(x,25-y-1,self.symbol) -- Invert Y-axis for screen coordinates
  end
end
-- Function to determine color based on height
function Graph:getColor(y)
  if y > 11 then return self.colors[1]
  elseif y > 6 then return self.colors[2]
  elseif y > 2 then return self.colors[3] end
  return self.colors[4]
end
function Graph:draw()
  term.clear()
  self.maxY=-1
  self.minY=math.huge
  for _, value in ipairs(self.data) do
    if value > self.maxY then self.maxY = value end
    if value < self.minY then self.minY = value end
  end
  -- Adjust min and max for better aesthetics
  if self.settings.adjustRange==true then
    local range = self.maxY-self.minY
    if range > 0 then
      self.minY = self.minY-(0.1 * range) -- 10% below the minimum
      self.maxY = self.maxY+(0.1 * range) -- 10% above the maximum
    else
        -- If all values are equal, set min and max accordingly
      self.minY = 0
      self.maxY = self.maxY * 2
    end
  end
  -- Ensure no negative values when scaling
  if self.minY < 0 then self.minY = 0 end

  self:drawMisc() -- Draw the scale legend
  for i, value in ipairs(self.data) do
    self:plotColumn(i+string.len(tostring(self.maxY)),value) -- Plot each column, offset for the legend
  end
end
function Graph:addValue(value)
  if #self.data >= 78 then
    table.remove(self.data, 1) -- Remove the oldest value
  end
  table.insert(self.data, value) -- Add the new value
  self:draw() -- Redraw the graph
end
function graph.new(name,unit,colors)
  return Graph:new(name,unit,colors)
end
return graph