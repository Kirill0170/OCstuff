local tgl=require("tgl")
local component=require("component")
local mbcs={}
mbcs.version="0.1"
--colors
local black=tgl.defaults.colors2.black
local good=Color2:new(tgl.defaults.colors16.lime,0)
local med=Color2:new(tgl.defaults.colors16.yellow,0)
local bad=Color2:new(tgl.defaults.colors16.red,0)
local blue=Color2:new(tgl.defaults.colors16.darkblue,0)
local gray=Color2:new(tgl.defaults.colors16.lightgray,0)
mbcs.util={}
function mbcs.util.convertHE(value)
  if value>1000000 then
    return string.sub(tostring(value/1000000),1,5).."MHE"
  elseif value>1000 then
    return string.sub(tostring(value/1000),1,5).."kHE"
  end
  return value.."HE"
end
function mbcs.text(pos2,text)
  local t
  if type(text)=="string" then
    t=Text:new(text,black,Pos2:new(1,1))
  elseif text.type=="Text" then
    t=text
    t.pos2=Pos2:new(2,2)
  end
  local f=Frame:new({t},Size2:newFromPos2(pos2,Pos2:new(pos2.x+string.len(text)+1,pos2.y+2)))
  f.borders=tgl.defaults.boxes.double
  return f
end
function mbcs.power_gauge(pos2,uuid,label) --rewrite
  local power
  if not label then label="Power usage:" end
  if not uuid then power=component.ntm_power_gauge
  else power=component.proxy(uuid) end
  local f=Frame:new({Text:new(label,black,Pos2:new(2,2)),power=Text:new("?HE/s",Pos2:new(14,2))},Size2:newFromSize(pos2.x,pos2.y,25))
  f.borders=tgl.defaults.boxes.single
  f.label=label
  f.update=function()
    local s
    local value=power.getInfo()*20
    if value==0 then f.objects.power.col2=med s=" "
    elseif value>0 then f.objects.power.col2=good s="+"
    else f.objects.power.col2=bad s="-" end
    s=s..mbcs.util.convertHE(value)
    f.objects.power.text=s.."/s"
    f.objects.power:render()
  end
  return f
end
function mbcs.power_storage(pos2,uuid,label) --rewrite
  local power
  if not label then label="Power usage:" end
  if not uuid then power=component.ntm_power_storage
  else power=component.proxy(uuid) end
  local f=Frame:new({Text:new(label,black,Pos2:new(2,2)),power=Text:new("?HE",Pos2:new(14,2))},Size2:newFromSize(pos2.x,pos2.y,25))
  f.borders=tgl.defaults.boxes.single
  f.label=label
  f.update=function()
    local value=power.getInfo()
    local s=mbcs.util.convertHE(value)
    if value==0 then f.objects.power.col2=med
    elseif value>0 then f.objects.power.col2=good
    else f.objects.power.col2=bad end
    f.objects.power.text=f.lable..s..
    f.objects.power:render()
  end
  return f
end
--[[
########################################
#        Power usage:100.32kHE/s       #
########################################

########################################
#           Power Storage 67%          #
#       Stored: 123.45MHE/200MHE       #
########################################

########################################
#           Fluid Storage 52%          #
#  Fluid:OXYGEN   Stored:32000mB/256B  #
########################################

#########################

]]