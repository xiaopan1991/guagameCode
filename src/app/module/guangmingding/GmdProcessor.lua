--
-- Author: Your Name
-- Date: 2015-03-03 11:03:40
--
local GmdProcessor = class("GmdProcessor", BaseProcessor)
function GmdProcessor:ctor()
	self.hard = 1
	self.index = 1
	self.hardstr = {"初级","中级","高级",}
end
function GmdProcessor:ListNotification()
	return {
		GmdModule.SHOW_GMD,
	}
end
function GmdProcessor:handleNotification(notify, data)
	if notify == GmdModule.SHOW_GMD then
		self:onSetView()
	end
end
function GmdProcessor:updateLimit()

end
function GmdProcessor:updateBoss()
	self.bossdata = DataConfig:getGMDBossByHardAndIndex(self.hard,self.index)	
	self.bossnametxt:setString(self.bossdata.name)
	self.tezhengtxt:setString("")
	self.skilltxt:setString("")
	self.rewardtxt:setString("")
	self.firstpasstxt:setString("")
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30084"],self.hardstr[self.hard],self.index)
	self.titletxt:setString(str)
	self.headpng:loadTexture()
end
function GmdProcessor:updateCoolDown()

end
function GmdProcessor:onSetView()
	if(not self.view) then
		local gmd = ResourceManager:widgetFromJsonFile("ui/guangmingding.json")
		local helpBtn = gmd:getChildByName("helpBtn")
		self.hardbtn1 = gmd:getChildByName("hardbtn1")
		self.hardbtn2 = gmd:getChildByName("hardbtn2")
		self.hardbtn3 = gmd:getChildByName("hardbtn3")
		self.startbtn = gmd:getChildByName("startbtn")
		self.saodangbtn = gmd:getChildByName("saodangbtn")
		self.rightbtn = gmd:getChildByName("rightbtn")
		self.leftbtn = gmd:getChildByName("leftbtn")

		self.headpng = gmd:getChildByName("headpng")
		local cfg = DataConfig:getAllConfigMsg()
		local str = addArgsToMsg(cfg["30085"],self.index)
		self.text1 = gmd:getChildByName("text1")
		self.text1:setString(str)
		str = cfg["30086"]
		self.text2 = gmd:getChildByName("text2")
		self.text2:setString(str)
		str = cfg["30087"]
		self.text3 = gmd:getChildByName("text3")
		self.text3:setString(str)
		str = cfg["30088"]
		self.text4 = gmd:getChildByName("text4")
		self.text4:setString(str)
		str = cfg["30089"]
		self.text5 = gmd:getChildByName("text5")
		self.text5:setString(str)
		self.bossnametxt = gmd:getChildByName("bossnametxt")
		self.tezhengtxt = gmd:getChildByName("tezhengtxt")
		self.skilltxt = gmd:getChildByName("skilltxt")
		self.rewardtxt = gmd:getChildByName("rewardtxt")
		self.firstpasstxt = gmd:getChildByName("firstpasstxt")
		self.titletxt = gmd:getChildByName("titletxt")

		helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.hardbtn1:addTouchEventListener(handler(self,self.onBtnClick))
		self.hardbtn2:addTouchEventListener(handler(self,self.onBtnClick))
		self.hardbtn3:addTouchEventListener(handler(self,self.onBtnClick))
		self.startbtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.saodangbtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.rightbtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.leftbtn:addTouchEventListener(handler(self,self.onBtnClick))
		self:setView(gmd)
		self:addMidView(gmd,true)

		self.hard = 1
		self.index = 1
		self:updateBoss()
		self:updateLimit()
		self:updateCoolDown()
	end
end
function GmdProcessor:onRonglianClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "helpBtn" then
	elseif btnName == "hardbtn1" then
	elseif btnName == "hardbtn2" then
	elseif btnName == "hardbtn3" then
	elseif btnName == "startbtn" then
	elseif btnName == "saodangbtn" then
	elseif btnName == "rightbtn" then
	elseif btnName == "leftbtn" then
	end
end
return GmdProcessor