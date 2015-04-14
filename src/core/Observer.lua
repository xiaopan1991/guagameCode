--观察者 能收能发
--TODO 废弃 __NotificationCenter
--用纯lua实现观察者模式
local ObserverManager = import(".ObserverManager")

local Observer = class("Observer",function ()
	local node = display.newNode()
	node:retain()
	return node
end)

Observer.manager = nil

function Observer:ctor()
	if Observer.manager == nil then
		Observer.manager = ObserverManager.new()
	end
end

--添加消息监听
--notify 消息名  字符串
--callback 回调函数
function Observer:registerNotification(notify)
	Observer.getManager():registerObserver(self,notify)
end

--移除消息监听
--notify  消息名
function Observer:unregisterNotification(notify)
	Observer.getManager():unregisterObserver(self,notify)
end

--发送消息
--notify  消息名  字符串
--data 	  数据体  table
function Observer:sendNotification(notify,data)
	Observer.getManager():sendNotification(notify,data)
end


--发送消息 全局的
--notify  消息名  字符串
--data 	  数据体  table
function Observer.sendNotification(notify,data)
	Observer.getManager():sendNotification(notify,data)
end

function Observer.getManager()
	if Observer.manager == nil then
		Observer.manager = ObserverManager.new()
	end
	return Observer.manager
end

--处理notify 由子类去处理
function Observer:handleNotification(notify,data)
	-- body
end

return Observer