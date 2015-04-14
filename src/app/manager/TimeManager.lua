scheduler = require("framework.scheduler")
local TimeManager = class("BattleManager")
function TimeManager:ctor()
	self.timer = nil
	self.objList = {}
	self.startSeverTime = 0
	self.clientLastTime = 0
	self.paused = false
	self.started = false
	self.pass = false--本次时间不根据scheduleUpdateGlobal增加，为了避免jumpToSeverTime后再次update(dt)
	--引起客户端时间超过服务段时间
end
function TimeManager:start()
	if(not self.timer) then
		self.timer = scheduler.scheduleUpdateGlobal(handler(self, self.update))
		self.started = true
	end
end
function TimeManager:setSvererTime(timeNum)
	self.startSeverTime = timeNum
	self.clientLastTime = 0
	self.pass = true
end
function TimeManager:getSvererTime()
	return (self.startSeverTime + self.clientLastTime)
end
function TimeManager:jumpToSeverTime(totime)
	local jump = totime - self:getSvererTime()
	if(jump > 0) then
		self:update(jump)
	end	
	self.pass = true
end
function TimeManager:setPause(paused)
	self.paused = paused
end
function TimeManager:add(obj)
	if(not self:isAdded(obj)) then
		table.insert(self.objList, obj)
	end
end
function TimeManager:remove(obj)
	table.removebyvalue(self.objList, obj)
end
function TimeManager:isAdded(obj)
	local index = table.indexof(self.objList, obj)
	if(index) then
		return true
	else
		return false
	end
end
function TimeManager:update(dt)
	if(self.paused) then
		return
	end
	if(self.pass == false) then
		self.clientLastTime = self.clientLastTime + dt
		for i,v in ipairs(self.objList) do
			v:timeUpdate(dt)
		end
	end
	self.pass = false
end
function TimeManager:stop()
	if self.timer ~= nil then
		scheduler.unscheduleGlobal(self.timer)
		self.timer = nil
	end
	self.objList = {}
	self.startSeverTime = 0
	self.clientLastTime = 0
	self.paused = false
	self.started = false
	self.pass = false
end
return TimeManager