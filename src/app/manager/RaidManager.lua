--副本管理器
local RaidManager = class("RaidManager")

--副本管理器
function RaidManager:ctor()
	-- 当前挂机的副本
	self.curPlayRaid = {}
	--
	self.raidData = {}
	--当前地图等级
	self.curLvl = 1
	--当前地图ID
	self.curMapID = ""
	--最大地图ID
	self.maxMapID = ""
end

--获取当前地图
function RaidManager:getCurMap()
	-- body
	return self.curMapID
end
function RaidManager:updateNextRaid()
	if(self.nextMapID) then
		self.curMapID = self.nextMapID
		self.nextMapID = nil
		Observer.sendNotification(MapModule.UPDATE_MAP, nil)
	end
end
--
function RaidManager:changePlayRaid(id)
	-- body
	if(self.curMapID == id) then
		return
	end
	self.curMapID = id
end
function RaidManager:changeNextRaid(id)
	-- body
	if(self.nextMapID == id) then
		return
	end
	self.nextMapID = id
end
function RaidManager:changeMaxRaid(id)
	-- body
	if(self.maxMapID == id) then
		return
	end
	self.maxMapID = id
end
function RaidManager:changeSaoDangRaid(id)
	-- body
	if(self.daoDangID == id) then
		return
	end
	self.daoDangID = id
end
--当前最大扫荡地图
function RaidManager:getSaoDangRaid()
	return self.daoDangID
end
--获取当前最大进度的地图ID
function RaidManager:getMaxRaidId()
	return self.maxMapID
end

return RaidManager