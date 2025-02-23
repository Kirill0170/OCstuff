--[[
Monitors HBM power usage
Requires:
- Power Gauge connected
- /usr/lib/graph.lua software
]]
local power=require("component").ntm_power_gauge
local graph=require("graph")
local g=graph.new("Power Monitor","HE/t")
while true do g:addValue(power.getInfo()) os.sleep(0.5) end