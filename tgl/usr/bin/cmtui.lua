local tgl=require("tgl")
local term=require("term")
local gpu=require("component").gpu

local blue=Color2:new(0,tgl.defaults.colors16.blue)

local main_frame=Frame:new({},Size2:newFromSize(1,1,tgl.defaults.screenSizeX,tgl.defaults.screenSizeY),blue)


