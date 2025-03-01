local dest="" --setup this!
if dest=="" then return end
local shell=require("shell")
shell.execute("cm c")
require("rdgp").connectGraph(dest)