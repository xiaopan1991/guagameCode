-- 网络接口 
-- Author: whe
-- Date: 2014-07-28 13:46:32
--
local Net = class("Net")

--发送Socket 
function Net.sendsocket(data)
	local node = display.newNode()
	node.data = data
	Observer.sendNotification(NetCoreModule.SEND_SOCKET,node)
end


--发送Http
function Net.sendhttp(data,update)
	local node = display.newNode()
	node.data = data
	node.data.app_version = "1.0.0"
	node.data.cfg_version = GameInstance.config.cfg_version or "0"
	node.up = update
	-- dump(node.data)
	Observer.sendNotification(NetCoreModule.SEND_HTTP,node)
end

return Net