--Tui Graphics Library
local gpu=require("component").gpu
local thread=require("thread")
local event=require("event")
local term=require("term")
local tgl={}
tgl.ver="0.5.3"
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
function tgl.util.printColors16(noNextLine)
  for name,col in pairs(tgl.defaults.colors16) do
    Text:new(name,Color2:new(col)):render(noNextLine)
    if noNextLine then term.write(" ") end
  end
  if noNextLine then term.write("\n") end
end

tgl.util.log("TGL version "..tgl.ver.." loaded")

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

tgl.defaults.colors2={}
tgl.defaults.colors2.openos=Color2:new(0xFFFFFF,0)
tgl.defaults.colors2.white=Color2:new(0,0xFFFFFF)
tgl.defaults.colors2.close=Color2:new(0xFFFFFF,0xFF0000)

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

function tgl.changeToPos2(pos2,ignore,offsetX)
  if not pos2 then return false end
  if not offsetX then offsetX=0 end
  if not ignore then
    local old=Pos2:new(term.getCursor())
    term.setCursor(pos2.x+offsetX,pos2.y)
    return old
  end
  term.setCursor(pos2.x+offsetX,pos2.y)
end

Size2={}
Size2.__index=Size2
function Size2:newFromPoint(x1,y1,x2,y2)
  if not x1 then x1=1 end
  if not y1 then y1=1 end
  if not x2 then x2=10 end
  if not y2 then y2=10 end
  local pos1=Pos2:new(x1,y1)
  local pos2=Pos2:new(x2,y2)
  if pos1 and pos2 then
    local obj=setmetatable({},Size2)
    obj.x1=x1
    obj.y1=y1
    obj.x2=x2
    obj.y2=y2
    obj.pos1=pos1
    obj.pos2=pos2
    obj.sizeX=math.abs(x2-x1+1)
    obj.sizeY=math.abs(y2-y1+1)
    return obj
  end
  return nil
end
function Size2:newFromPos2(pos1,pos2)
  if pos1 and pos2 then
    local obj=setmetatable({},Size2)
    obj.x1=pos1.x
    obj.y1=pos1.y
    obj.x2=pos2.x
    obj.y2=pos2.y
    obj.pos1=pos1
    obj.pos2=pos2
    obj.sizeX=math.abs(obj.x2-obj.x1+1)
    obj.sizeY=math.abs(obj.y2-obj.y1+1)
    return obj
  end
  return nil
end
function Size2:newFromSize(x,y,sizeX,sizeY)
  local pos1=Pos2:new(x,y)
  if pos1 and tonumber(sizeX) and tonumber(sizeY) then
    local obj=setmetatable({},Size2)
    obj.x1=x
    obj.y1=y
    obj.x2=x+sizeX
    obj.y2=y+sizeY
    obj.sizeX=sizeX
    obj.sizeY=sizeY
    obj.pos1=pos1
    obj.pos2=Pos2:new(obj.x2,obj.y2)
    return obj
  end
end
function Size2:moveToPos2(pos2)
  if not pos2 then return false end
  self.x1=pos2.x
  self.y1=pos2.y
  self.x2=self.x1+self.sizeX
  self.y2=self.y1+self.sizeY
  self.pos1=pos2
  self.pos2=Pos2:new(self.x2,self.y2)
  return true
end

function tgl.fillSize2(size2,col2,char)
  if not char then char=" " end
  local prev=tgl.changeToColor2(col2)
  gpu.fill(size2.x1,size2.y1,size2.sizeX,size2.sizeY,char)
  tgl.changeToColor2(prev,true)
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
  	callback=function() tgl.util.log("Empty Button!!") end
  end
  obj.callback=callback
  obj.pos2=pos2 or Pos2:new()
  obj.col2=color2 or Color2:new()
  obj.handler=function (_,_,x,y)
    if x>=obj.pos2.x
    and x<obj.pos2.x+string.len(obj.text)
    and y==obj.pos2.y then
      thread.create(obj.onClick):detach()
      local success,err=pcall(obj.callback)
      if not success then
        tgl.util.log("Button handler error: "..err)
      end
    end
  end
  obj.onClick=function()
    obj:disable()
    local invert=Color2:new(obj.col2[2],obj.col2[1])
    local prev=obj.col2
    obj.col2=invert
    obj:render()
    obj.col2=prev
    os.sleep(0.5)
    obj:render()
    obj:enable()
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
  local prev=tgl.changeToColor2(self.col2)
  gpu.set(self.pos2.x,self.pos2.y,self.text)
  tgl.changeToColor2(prev,true)
end

InputField={}
InputField.__index=InputField
function InputField:new(text,pos2,col2)
  local obj=setmetatable({},InputField)
  obj.type="InputField"
  obj.text=text or "[______]"
  obj.pos2=pos2 or Pos2:new()
  obj.col2=col2 or Color2:new()
  obj.value=""
  obj.eventName="defaultInputEvent"
  obj.handler=function (_,_,x,y)
    if x>=obj.pos2.x
    and x<obj.pos2.x+string.len(obj.text)
    and y==obj.pos2.y then
      obj:disable()
      local prev=tgl.changeToPos2(obj.pos2,false,1)
      local prevCol=tgl.changeToColor2(self.col2)
      obj.value=io.read()
      event.push(obj.eventName,obj.value)
      obj:enable()
      tgl.changeToPos2(prev,true)
      tgl.changeToColor2(prevCol,true)
    end
  end
  return obj
end
function InputField:render()
  local prev=tgl.changeToColor2(self.col2)
  gpu.set(self.pos2.x,self.pos2.y,self.text)
  tgl.changeToColor2(prev,true)
end
function InputField:enable()
  event.listen("touch",self.handler)
end
function InputField:disable()
  event.ignore("touch",self.handler)
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
  obj.space=0
  obj.sizeX=tgl.defaults.screenSizeX
  obj.centerMode=false
  return obj
end
function Bar:render()
  local prev=tgl.changeToColor2(self.col2)
  gpu.fill(self.pos2.x,self.pos2.y,self.sizeX,1," ")
  if self.centerMode then
    local object=self.objects[1]
    if object.type then
      local len=string.len(object.text)
      local startX=self.pos2.x+(self.sizeX-len)/2
      tgl.util.log("Bar start X:"..startX)
      object:newPos2(startX,self.pos2.y)
      if not object.customCol2 and self.objectColor2 then
        object.col2=self.objectColor2
      end
      object:render()
    end
  else
    local startX=self.pos2.x
    tgl.util.log("Bar start X:"..startX)
    for _,object in pairs(self.objects) do
      if startX>self.pos2.x+self.sizeX then
        tgl.util.log("Bar: out of bounds: "..startX)
        break
      end
      if object.type then
        if not object.customX then
          object:newPos2(startX,self.pos2.y)
          startX=startX+string.len(object.text)+self.space
        else
          object:newPos2(self.pos2.x+object.customX-1,self.pos2.y)
        end
        if not object.customCol2 and self.objectColor2 then
          object.col2=self.objectColor2
        end
        object:render()
      end
    end
  end
  tgl.changeToColor2(prev,true)
  return true
end
function Bar:enableAll()
  for _,object in pairs(self.objects) do
    if object.type then
      if object.type=="Button" or object.type=="InputField" then object:enable() end
    end
  end
end
function Bar:disableAll()
  for _,object in pairs(self.objects) do
    if object.type then
      if object.type=="Button" or object.type=="InputField" then object:disable() end
    end
  end
end

Frame={}
Frame.__index=Frame
function Frame:new(objects,size2,col2)
  local obj=setmetatable({},Frame)
  obj.objects=objects or {}
  obj.size2=size2 or Size2:new()
  obj.col2=col2 or Color2:new()
  --translate objects
  obj:translate()
  return obj
end
function Frame:translate()
  for _,object in pairs(self.objects) do
    if object.type then
      if not object.relpos2 then object.relpos2=object.pos2 end
      local t_pos2=object.relpos2
      if not t_pos2 then error("Corrupted object") end
      object.pos2=Pos2:new(t_pos2.x+self.size2.x1-1,t_pos2.y+self.size2.y1-1) --offset
      if object.type=="Bar" then
        if object.pos2.x+object.sizeX>self.size2.sizeX then
          tgl.util.log("Bar Rescale: "..object.sizeX.." -> "..self.size2.sizeX.." - "..object.pos2.x.." + "..self.size2.x1)
          object.sizeX=self.size2.sizeX-object.pos2.x+self.size2.x1
        end
      end
    end
  end
end
function Frame:render()
  --frame
  tgl.fillSize2(self.size2,self.col2)
  --objects
  for _,object in pairs(self.objects) do
    if object.type then
      object:render()
    end
  end
end
function Frame:moveToPos2(pos2)
  if not pos2 then return false end
  self.size2:moveToPos2(pos2)
  self:translate()
end
function Frame:enableAll()
  for _,object in pairs(self.objects) do
    if object.type then
      if object.type=="Button" or object.type=="InputField" then object:enable() end
      if object.type=="Bar" then object:enableAll() end
    end
  end
end
function Frame:disableAll()
  for _,object in pairs(self.objects) do
    if object.type then
      if object.type=="Button" or object.type=="InputField" then object:disable() end
      if object.type=="Bar" then object:disableAll() end
    end
  end
end
function Frame:add(object,name)
  if object.type then
    if not name then
      table.insert(self.objects,object)
    else
      self.objects[name]=object
    end
    self:translate()
    return true
  end
  return false
end

function tgl.window(size2,title,barcol,framecol)
  if not size2 then return nil end
  if not title then title="Untitled" end
  if not barcol then barcol=Color2:new(0xFFFFFF,tgl.defaults.colors16.lightblue) end
  if not framecol then framecol=tgl.defaults.colors2.white end
  local close_button=Button:new("[X]",function() event.push("close"..title) end,Pos2:new(size2.sizeX-3,1),tgl.defaults.colors2.close)
  close_button.customCol2=true
  close_button.customX=size2.sizeX-2
  local title_text=Text:new(title,barcol)
  title_text.customX=(size2.sizeX-string.len(title))/2
  local topbar=Bar:new(Pos2:new(1,1),{title_text=title_text,close_button=close_button},barcol,barcol)
  local frame=Frame:new({topbar=topbar},size2,framecol)
  return frame
end
return tgl
--errors