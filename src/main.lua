function __G__TRACKBACK__(errorMessage)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback("", 2))
    print("----------------------------------------")
    --[[local btns = {{text = "确定",skin = 3,}}
	local alert = GameAlert.new()
	alert:pop("----------------------------------------\n".."LUA ERROR: " .. tostring(errorMessage),"程序错误",btns)]]
end
package.path = package.path .. ";src/"
cc.FileUtils:getInstance():setPopupNotify(false)
App = require("app.MyApp").new()
--GameAlert = require("app.components.GameAlert")
App:run()
--[[
package.loaded["hotfix.hotfix"] = nil
require("hotfix.hotfix")
]]