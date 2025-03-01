function dataFunction() --setup this!

end

local shell=require("shell")
shell.execute("cm c --static")
require("rdgp").server(dataFunction,"name here","unit here")