local ObserverManager = class("ObserverManager")

function ObserverManager:ctor()
	self.observerArr = {}	
end

function ObserverManager:registerObserver(observer,msg)
	local obs = self.observerArr[msg]
	if obs ~= nil then
		obs[#obs+1] = observer
	else
		self.observerArr[msg] = {}
		self.observerArr[msg][1] = observer
	end
end

function ObserverManager:unregisterObserver(observer,msg)
	local obs = self.observerArr[msg]
	if obs ~= nil then
		table.removebyvalue(obs, observer)
	end
end

function ObserverManager:sendNotification(msg,data)
	local obs = self.observerArr[msg]
	local tobs = {}
	if obs ~= nil then
		for k,v in pairs(obs) do
			tobs[#tobs + 1] = v
		end
		for kk,vv in pairs(tobs) do
			vv:handleNotification(msg,data)
		end
	end
end

return ObserverManager
