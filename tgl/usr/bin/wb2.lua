local tgl=require("tgl")
local term=require("term")
local mnp=require("cmnp")
local event=require("event")

local version="2 devbuild:2"
--colors
local barcolor=Color2:new(0xFFFFFF,tgl.defaults.colors16["lightblue"])
local bgdcolor=tgl.defaults.colors2.white
local menucolor=Color2:new(0,tgl.defaults.colors16["lightgray"])
--topbar
local close_button=Button:new(" X ",function() event.push("browser_close") end,Pos2:new(),tgl.defaults.colors2.close)
close_button.customCol2=true
close_button.customX=tgl.defaults.screenSizeX-2
local topbar=Bar:new(Pos2:new(),{label=Text:new("WebBrowser "..version),close_button=close_button},barcolor,barcolor)
--toolbar
local file_frame=Frame:new({},Size2:newFromSize(3,3,8,6),menucolor)
file_frame.borders=tgl.defaults.boxes.signle
file_frame.borderType="inline"
local close_button_ff=Button:new("Close ",function() file_frame:close() end,Pos2:new(2,2),menucolor)
close_button_ff.onClick=nil
file_frame:add(close_button_ff,"close_button")
local file_button=Button:new("File",function() file_frame:open() end,Pos2:new(2,1))
local toolbar=Bar:new(Pos2:new(1,2),{file_button=file_button},menucolor,menucolor)
--Tabbar
local tabbar=Bar:new(Pos2:new(1,3),{},menucolor,menucolor)
tabbar.space=1
--Addressbar
local urltext=tgl.util.strgen(" ",tgl.defaults.screenSizeX-4)
local urlbar=Bar:new(Pos2:new(1,4),{Text:new("URL:"),url=InputField:new(urltext,Pos2:new())},tgl.defaults.colors2.white,tgl.defaults.colors2.white)
urlbar.objects.url.customX=4
urlbar.space=1

--Tabs
local tabsize2=Size2:newFromPoint(1,5,80,24)
local empty=Frame:new({Text:new("Empty Tab",nil,Pos2:new(2,2))},tabsize2,tgl.defaults.colors2.white)

--main compile
local browser_frame=Frame:new({topbar=topbar,toolbar=toolbar,tabbar=tabbar,urlbar=urlbar,empty})
browser_frame:render()
browser_frame:enableAll()
while true do local a=event.pull("browser_close") if a then
  os.sleep(.5)
  tgl.changeToColor2(tgl.defaults.colors2.black)
  term.clear() break end end
browser_frame:disableAll()
browser_frame=nil