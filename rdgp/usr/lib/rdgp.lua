local mnp=require("cmnp")
local graph=require("graph")
local event=require("event")
local thread=require("thread")
local rdgp={}
rdgp.version="0.5"
function rdgp.graphHandler(name,unit,colors,dataEvent)
  local g=graph.new(name,unit,colors)
  while true do
    local id,data=event.pullMultiple(dataEvent,"interrupted")
    if id=="interrupted" then break end
    data=require("serialization").unserialize(data)
    if data[1]=="data" then
      if tonumber(data[2]) then
        g:addValue(data[2],true)
      end
    end
  end
end
function rdgp.connectGraph(dest)
  if not mnp.isConnected(true) then return false end
  local success,ip=mnp.checkAvailability(dest)
  if not success then return false end
  mnp.send(ip,"rdgp",{"connect"})
  local rdata=mnp.receive(ip,"rdgp",10)
  if not rdata then return false end
  if rdata[1]=="ok" then
    local dataEvent="rdgpData"
    local stopEvent="interrupted"
    thread.create(mnp.listen,ip,"rdgp",dataEvent,stopEvent):detach()
    rdgp.graphHandler(rdata[2],rdata[3],rdata[4],dataEvent)
  end
  return false
end
rdgp.clients={}
function rdgp.dataHandler(fun)
  while os.sleep(1) do
    local success,data=pcall(fun)
    if not success then
      mnp.log("RDGP","Couldn't get data: "..data,2)
    elseif not tonumber(data) then
      mnp.log("RDGP","Function gave not number: "..tostring(data))
    else
      for _,ip in pairs(rdgp.clients) do
        mnp.send(ip,"rdgp",{"data",tonumber(data)})
      end
    end
  end
end
function rdgp.server(fun,name,unit)
  if not mnp.isConnected(true) then error("Couldn't connect to network") end
  if not name then name=os.getenv("this_ip").." graph" end
  if not unit then unit="x" end
  thread.create(rdgp.dataHandler,fun)
  while true do
    local rdata,np=mnp.receive("broadcast","rdgp",60)
    if rdata[1]=="connect" then
      mnp.send(np["route"][0],"rdgp",{"ok",name,unit})
      table.insert(rdgp.clients,np["route"][0])
    end
  end
end
return rdgp