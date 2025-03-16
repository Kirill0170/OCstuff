--Tui Graphics Library
local gpu=require("component").gpu
local thread=require("thread")
local event=require("event")
local tgl={}
tgl.util={}
tgl.defaults={}
tgl.defaults.foregroundColor=0xFFFFFF
tgl.defaults.backgroundColor=0x000000
tgl.ver="0.1"
tgl.debug=true

Color2={}
Color2.__index=Color2
function Color2:new(col1,col2)
  if not col1 then col1=tgl.defaults.foregroundColor end
  if not col2 then col2=tgl.defaults.backgroundColor end
  col1=tonumber(col1)
  col2=tonumber(col2)
  if col1 and col2 then
    if col1>0 and col1<16777216 and col2>0 and col2<16777216 then
      return setmetatable({col1,col2},Color2)
    end
  end
  return nil
end

Pos2={}
Pos2.__index=Pos2
function Pos2:new(x,y)
  if not x then x=1 end
  if not y then y=1 end
  x=tonumber(x)
  y=tonumber(y)
  if x and y then
    if x>0 and y>0 and x<161 and y<100 then
      local obj=setmetatable({},Pos2)
      obj[1]=x
      obj[2]=y
      obj.x=x
      obj.y=y
      return obj
    end
  end
  return nil
end

Button={}
Button.__index=Button
function Button:new(text,callback,pos2,color2)
  local obj=setmetatable({},Button)
  obj.text=text or "[Button]"
  if type(callback)~="function" then
  	callback=function() if tgl.debug then print("[DEBUG]Empty button!") end end
  end
  obj.callback=callback
  obj.pos2=pos2 or Pos2:new()
  obj.color2=color2 or Color2:new()
  obj.handler=function (a,b,x,y)
    if x>=obj.pos2.x
    and x<obj.pos2.x+string.len(obj.text)
    and y==obj.pos2.y then
      pcall(obj.callback)
    end
  end
  return obj
end
function Button:enable()
  event.listen("touch",self.handler)
end
function Button:disable()
  event.ignore("touch",self.handler)
end
function Button:render()
  gpu.set(self.pos2.x,self.pos2.y,self.text)
end

return tgl
