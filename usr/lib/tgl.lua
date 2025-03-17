--Tui Graphics Library
local gpu=require("component").gpu
local thread=require("thread")
local event=require("event")
local term=require("term")
local tgl={}
tgl.ver="0.2dev"
tgl.debug=true
tgl.util={}
tgl.defaults={}
tgl.defaults.foregroundColor=0xFFFFFF
tgl.defaults.backgroundColor=0x000000
tgl.defaults.screenSizeX,tgl.defaults.screenSizeY=gpu.getResolution()
tgl.defaults.colors16={}
tgl.defaults.colors16["white"]=0xFFFFFF --white
tgl.defaults.colors16["gold"]=0xFFCC33 --gold
tgl.defaults.colors16["magenta"]=0xCC66CC --magenta
tgl.defaults.colors16["lightblue"]=0x6699FF --lightblue
tgl.defaults.colors16["yellow"]=0xFFFF33 --yellow
tgl.defaults.colors16["lime"]=0x33CC33 --lime
tgl.defaults.colors16["pink"]=0xFF6699 --pink
tgl.defaults.colors16["darkgray"]=0x333333 --darkgray
tgl.defaults.colors16["lightgray"]=0xCCCCCC --lightgray
tgl.defaults.colors16["cyan"]=0x336699 --cyan
tgl.defaults.colors16["purple"]=0x9933CC --purple
tgl.defaults.colors16["darkblue"]=0x333399 --darkblue
tgl.defaults.colors16["brown"]=0x663300 --brown
tgl.defaults.colors16["darkgreen"]=0x336600 --darkgreen
tgl.defaults.colors16["red"]=0xFF3333 --red
tgl.defaults.colors16["black"]=0x000000 --black


function tgl.util.log(text)
  if tgl.debug then
    local c=require("component")
    if c.ocelot then
      c.ocelot.log("TGL: "..text)
    end
  end
end

Color2={}
Color2.__index=Color2
function Color2:new(col1,col2)
  if not col1 then col1=tgl.defaults.foregroundColor end
  if not col2 then col2=tgl.defaults.backgroundColor end
  col1=tonumber(col1)
  col2=tonumber(col2)
  if col1 and col2 then
    if col1>=0 and col1<16777216 and col2>=0 and col2<16777216 then
      return setmetatable({col1,col2},Color2)
    end
  end
  return nil
end

function tgl.changeToColor2(col2,ignore)
  if not col2 then return false end
  if not ignore then
    local old=Color2:new(gpu.getForeground(),gpu.getBackground())
    gpu.setForeground(col2[1])
    gpu.setBackground(col2[2])
    return old
  end
  gpu.setForeground(col2[1])
  gpu.setBackground(col2[2])
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

function tgl.changeToPos2(pos2,ignore)
  if not pos2 then return false end
  if not ignore then
    local old=Pos2:new(term.getCursor())
    term.setCursor(pos2.x,pos2.y)
    return old
  end
  term.setCursor(pos2.x,pos2.y)
end

Text={}
Text.__index=Text
function Text:new(text,col2,pos2)
  local obj=setmetatable({},Text)
  obj.type="Text"
  obj.text=text
  obj.col2=col2 or Color2:new()
  obj.pos2=pos2 or nil
  return obj
end
function Text:render(noNextLine)
  local prev=tgl.changeToColor2(self.col2)
  if not self.pos2 then
    term.write(self.text)
    tgl.changeToColor2(prev,true)
    if not noNextLine then term.write("\n") end
    return true
  end
  gpu.set(self.pos2.x,self.pos2.y,self.text)
  tgl.changeToColor2(prev,true)
  return true
end
function Text:newPos2(x,y)
  local newPos2=Pos2:new(x,y)
  if not newPos2 then return false end
  self.pos2=newPos2
  return true
end

Button={}
Button.__index=Button
function Button:new(text,callback,pos2,color2)
  local obj=setmetatable({},Button)
  obj.type="Button"
  obj.text=text or "[New Button]"
  if type(callback)~="function" then
  	callback=function() if tgl.debug then print("[DEBUG]Empty button!") end end
  end
  obj.callback=callback
  obj.pos2=pos2 or Pos2:new()
  obj.color2=color2 or Color2:new()
  obj.handler=function (_,_,x,y)
    if x>=obj.pos2.x
    and x<obj.pos2.x+string.len(obj.text)
    and y==obj.pos2.y then
      pcall(obj.callback)
    end
  end
  return obj
end
function Button:newPos2(x,y)
  local newPos2=Pos2:new(x,y)
  if not newPos2 then return false end
  self.pos2=newPos2
  return true
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

Bar={}
Bar.__index=Bar
function Bar:new(pos2,objects,col2,objDefaultCol2)
  local obj=setmetatable({},Bar)
  obj.type="Bar"
  obj.pos2=pos2 or Pos2:new()
  obj.col2=col2 or Color2:new()
  obj.objectColor2=objDefaultCol2 or nil
  obj.objects=objects or {}
  return obj
end
function Bar:render()
  local startX=self.pos2.x
  tgl.util.log(startX)
  local endX=tgl.defaults.screenSizeX
  local prev=tgl.changeToColor2(self.col2)
  gpu.fill(self.pos2.x,self.pos2.y,tgl.defaults.screenSizeX,1," ")
  for i,object in pairs(self.objects) do
    if object.type then
      if not object.customX then
        object:newPos2(startX,self.pos2.y)
        startX=startX+string.len(object.text)
        tgl.util.log(string.len(object.text))
        tgl.util.log(startX)
      else
        object:newPos2(object.customX,self.pos2.y)
      end
      if not object.customCol2 and self.objectColor2 then
        object.col2=self.objectColor2
      end
      object:render()
    end
  end
end
function Bar:enableAll()
  for _,object in pairs(self.objects) do
    if object.type then
      if object.type=="Button" then object:enable() end
    end
  end
end
function Bar:disableAll()
  for _,object in pairs(self.objects) do
    if object.type then
      if object.type=="Button" then object:disable() end
    end
  end
end
return tgl
--button self