local tgl=require("tgl")
local component=require("component")
local zirnox=component.zirnox_reactor
local power_gauge=component.ntm_power_gauge
local black=tgl.defaults.colors2.black
local good=Color2:new(tgl.defaults.colors16.lime,0)
local med=Color2:new(tgl.defaults.colors16.yellow,0)
local bad=Color2:new(tgl.defaults.colors16.red,0)
local water=Color2:new(tgl.defaults.colors16.darkblue,0)
local steam=Color2:new(tgl.defaults.colors16.lightgray,0)

local title_frame=Frame:new({},Size2:newFromSize(1,1,80,3),black)
title_frame.borders=tgl.defaults.boxes.double
title_frame.borderType="inline"
title_frame:add(Text:new("v1.3",black,Pos2:new(2,2)))
title_frame:add(Text:new("ZIRNOX Reactor",black,Pos2:new((80-14)/2,2)))

local zirnox_frame=Frame:new({},Size2:newFromSize(1,4,80,4),black)
zirnox_frame.borders=tgl.defaults.boxes.double
zirnox_frame.borderType="inline"
zirnox_frame:add(Text:new("Temperature:",black,Pos2:new(2,2)))
zirnox_frame:add(Text:new("Pressure:",black,Pos2:new(2,3)))
zirnox_frame:add(Text:new("Steam:",black,Pos2:new(25,3)))
zirnox_frame:add(Text:new("Water:",black,Pos2:new(25,2)))
zirnox_frame:add(Text:new("Power:",black,Pos2:new(45,2)))
zirnox_frame:add(Text:new("Active:",black,Pos2:new(45,3)))

zirnox_frame:add(Text:new("?C",good,Pos2:new(14,2)),"temp")
zirnox_frame:add(Text:new("? Bar",good,Pos2:new(11,3)),"pressure")
zirnox_frame:add(Text:new("?mb",water,Pos2:new(31,2)),"water")
zirnox_frame:add(Text:new("?mb",steam,Pos2:new(31,3)),"steam")
zirnox_frame:add(Text:new("?kHE",med,Pos2:new(51,2)),"power")
zirnox_frame:add(Text:new("?",bad,Pos2:new(52,3)),"active")

local run=true
zirnox_frame:add(Button:new("[Exit program]",function() run=false end,Pos2:new(66,2),black))
zirnox_frame:add(Button:new("[Toggle reactor]", function()
	if zirnox.isActive() then zirnox.setActive(false)
	else zirnox.setActive(true) end end,Pos2:new(64,3),black))

local main_frame=Frame:new({title_frame,zirnox_frame=zirnox_frame},Size2:newFromSize(1,1,80,25),black)

local function convertTemp(temp)
	return math.floor((temp) * 0.00001 * 780 + 20)
end
local function convertPressure(pres)
	return math.floor((pres) * 0.00001 * 30)
end

local function render()
	for i,v in pairs({"temp","pressure","water","steam","power","active"}) do
		main_frame.objects.zirnox_frame.objects[v]:render()
	end
end

local function update()
	local temp,pres,wat,ste,_,active=zirnox.getInfo()
	local power=power_gauge.getInfo()*20/1000
	if temp>85000 or pres>85000 or wat<16000 then
		zirnox.setActive(false)
		require("computer").beep()
	end
	temp=convertTemp(temp)
	pres=convertPressure(pres)
	
	if temp<250 then main_frame.objects.zirnox_frame.objects.temp.col2=good end
	if temp>=250 then main_frame.objects.zirnox_frame.objects.temp.col2=med end
	if temp>500 then main_frame.objects.zirnox_frame.objects.temp.col2=bad end
	main_frame.objects.zirnox_frame.objects.temp.text=temp.."C   "
	
	if pres<12 then main_frame.objects.zirnox_frame.objects.pressure.col2=good end
	if pres>=12 then main_frame.objects.zirnox_frame.objects.pressure.col2=med end
	if pres>=18 then main_frame.objects.zirnox_frame.objects.pressure.col2=bad end
	main_frame.objects.zirnox_frame.objects.pressure.text=pres.." Bar   "
	
	main_frame.objects.zirnox_frame.objects.water.text=wat.."mb    "
	main_frame.objects.zirnox_frame.objects.steam.text=ste.."mb    "
	
	if active==true then main_frame.objects.zirnox_frame.objects.active.col2=good
	else main_frame.objects.zirnox_frame.objects.active.col2=bad end
	main_frame.objects.zirnox_frame.objects.active.text=tostring(active).." "
	
	main_frame.objects.zirnox_frame.objects.power.text=power.."kHE   "
	
	render()
end

main_frame:render()
main_frame:enableAll()
while run do
	os.sleep(1)
	update()
end
main_frame:disableAll()