local gpu=require("component").gpu
local term=require("term")
local img={}
function img.splitString(inputString, partLength)
  if not inputString then return {} end
  local parts = {}
  for i = 1, #inputString, partLength do
    local part = inputString:sub(i, i + partLength - 1)
    table.insert(parts, part)
  end
  return parts
end

function img.encodeColor(num)
  if num>0xFFFFFF then error("Number exceeds the limit of 0xFFFFFF") end
  local hex = string.format("%06X", num)
  local splitHex = {hex:sub(1, 2), hex:sub(3, 4), hex:sub(5, 6)}
  return string.char(tonumber(splitHex[1], 16), tonumber(splitHex[2], 16), tonumber(splitHex[3], 16))
end
function img.decodeColor(hexStr)
  if #hexStr ~= 3 then error("String length must be 3") end
  local r, g, b = string.byte(hexStr, 1), string.byte(hexStr, 2), string.byte(hexStr, 3)
  return r * 0x10000 + g * 0x100 + b
end
function img.encode(char,fgdcol,bgdcol)
  return char..img.encodeColor(fgdcol)..img.encodeColor(bgdcol)
end
function img.decode(s)
  return {string.sub(s,1,1),img.decodeColor(string.sub(s,2,4)),img.decodeColor(string.sub(s,5,7))}
end
function img.load(filename)
  local f=io.open(filename)
  if not f then return false,"no such file" end
  local header=f:read("l")
  if not header:sub(1,3)=="img" then return false,"not an image file" end
  local parts = {}
  for part in header:gmatch("[^;]+") do table.insert(parts, part) end
  if #parts~=4 then return false,"corrupted header format" end
  local width, height, mode = tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])
  if not width or not height or not mode then return false,"corrupted header values" end
  if mode==1 then --default
    local image_data={}
    image_data.info={width=width,height=height,mode=mode}
    image_data.raw={}
    for i=1,height do
      image_data.raw[i]={}
      for j=1,width do
        local s=f:read(7)
        table.insert(image_data.raw[i],img.decode(s))
      end
    end
    return image_data
  end
  return nil
end
function img.writeChar(p)
  gpu.setForeground(p[2])
  gpu.setBackground(p[3])
  term.write(p[1])
end
function img.print(image,startX,startY)
  if not startX then startX=1 end
  if not startY then startY=1 end
  local prevCursor=term.setCursor(startX,startY)
  if not image["info"] then return false end
  for _,line in pairs(image.raw) do
    for _,pixel in pairs(line) do
      img.writeChar(pixel)
    end
    term.write("\n")
  end
end
return img

-- .img
--[[
img;10;20;1 #1=default 0=4bit color
 F F F F
_D_D_D_D


0xFFFFFF ->    FF FF FF 
string.char -> █  █  █
]]