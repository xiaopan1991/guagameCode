local skillpvpprocessor = class("skillpvpprocessor", BaseProcessor)
local SkillPvpItem = import(".skillpvpitem")
function skillpvpprocessor:ctor()
end
function skillpvpprocessor:ListNotification()
	return {
		skillmodule.SHOW_SKILL_PVP,
		skillmodule.UPDATE_SKILL_UNLOCK_PVP,
		skillmodule.USER_CHANGE_SKILL_ORDER,
		skillmodule.UP_SKILL_ORDER_PVP,
		skillmodule.USER_DEFAULT_SKILLS,
	}
end
function skillpvpprocessor:handleNotification(notify, node)
	if notify == skillmodule.SHOW_SKILL_PVP then 
		self:initUI()
	elseif notify == skillmodule.UPDATE_SKILL_UNLOCK_PVP then
		if(self.view) then

			self:updateData()
		end
	elseif notify == skillmodule.UP_SKILL_ORDER_PVP then
		local pvpSkills = PlayerData:getPvpSkills()
		local temp = pvpSkills[node.data.index]
		pvpSkills[node.data.index] = pvpSkills[node.data.index - 1]
		pvpSkills[node.data.index - 1] = temp
		--PlayerData:setPvpSkills(pvpSkills)
		local net = {}
		net.method = skillmodule.USER_CHANGE_SKILL_ORDER
		net.params = {}
		net.params.pvp_skills = true
		net.params.sid_list = {}
		for i,v in ipairs(pvpSkills) do
			table.insert(net.params.sid_list,v)
		end
		Net.sendhttp(net)
	elseif notify == skillmodule.USER_CHANGE_SKILL_ORDER then
		local cfg = DataConfig:getAllConfigMsg()
		toastNotice(cfg['20055'])
		if node.data.params.pvp_skills then
			PlayerData:setPvpSkills(node.data.data)
		end
	elseif notify == skillmodule.USER_DEFAULT_SKILLS then
		if node.data.params.pvp_skills then
			PlayerData:setPvpSkills(node.data.data)
		end
	end
end
function skillpvpprocessor:initUI()
	if(not self.view) then
		self.mapPanel = ResourceManager:widgetFromJsonFile("ui/skillpvppanel.json")
		self.bg = self.mapPanel:getChildByName("bg")
		--self.scrollviewbg = self.mapPanel:getChildByName("scrollviewbg")
		self.skillscrollview = self.mapPanel:getChildByName("skillscrollview")
		self.defaultbtn = self.mapPanel:getChildByName("defaultbtn")
		self.changebtn = self.mapPanel:getChildByName("changebtn")
		self.infoTxt = self.mapPanel:getChildByName("infoTxt")
		-- local helpBtn = self.mapPanel:getChildByName("helpBtn")
		local closeBtn = self.mapPanel:getChildByName("closeBtn")
		self.infoTxt:setString("作战技能")
		local theight = 766
		self.det = display.height - 960
		if display.height > 960 then
			theight = theight + self.det
		end
		local size = self.mapPanel:getLayoutSize()
		self.mapPanel:setContentSize(cc.size(size.width,theight))

		size = self.bg:getContentSize()
		self.bg:setContentSize(cc.size(size.width,size.height + self.det))

		--size = self.scrollviewbg:getContentSize()
		--self.scrollviewbg:setContentSize(cc.size(size.width,size.height + self.det))	

		size = self.skillscrollview:getContentSize()
		self.skillscrollview:setContentSize(cc.size(size.width,size.height + self.det))

		self.defaultbtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.changebtn:addTouchEventListener(handler(self,self.onBtnClick))
		enableBtnOutLine(self.defaultbtn,COMMON_BUTTONS.BLUE_BUTTON)
		enableBtnOutLine(self.changebtn,COMMON_BUTTONS.BLUE_BUTTON)
		-- helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
		closeBtn:addTouchEventListener(handler(self,self.onBtnClick))

		self.skillPvpItems = {}
	end
	self:setView(self.mapPanel)
	self:addPopView(self.mapPanel,true)
	self:updateData()
end
function skillpvpprocessor:updateData()
	local allConfigBattleSkillNum = #(DataConfig:getUnlockBattleSkillCfg())
	local curUnlockNum = PlayerData:getUnlockBattleSkillsNum()
	local innerHeight = (10+138)*allConfigBattleSkillNum+10
	innerHeight = math.max(innerHeight,self.skillscrollview:getContentSize().height)
	self.skillscrollview:setInnerContainerSize(cc.size(616,innerHeight))
	local pvpSkills = PlayerData:getPvpSkills()
	local skillPvpItem
	for i=1,allConfigBattleSkillNum do
		skillPvpItem = self.skillPvpItems[i]
		if(not skillPvpItem) then
			 skillPvpItem = SkillPvpItem.new()
			 self.skillscrollview:addChild(skillPvpItem)
		end
		if(pvpSkills[i]) then
			skillPvpItem:updateData(false,i,pvpSkills[i])
		else
			if(i<=curUnlockNum) then
				skillPvpItem:updateData(false,i)
			else
				skillPvpItem:updateData(true,i)
			end
		end
		skillPvpItem:setPosition(0,innerHeight - (5+138)*i)
		self.skillPvpItems[i] = skillPvpItem
	end
	local cfg = DataConfig:getAllConfigMsg()
	local info = cfg["20056"]
	self.infoTxt:setString(info)
end
function skillpvpprocessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	if btnName == "defaultbtn" then
		local net = {}
		net.method = skillmodule.USER_DEFAULT_SKILLS
		net.params = {}
		net.params.pvp_skills = true
		Net.sendhttp(net)
	elseif btnName == "changebtn" then
		Observer.sendNotification(skillmodule.SHOW_SELECT_SKILL_PVP)
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("figure_follower")
	elseif btnName == "closeBtn" then
		self:removePopView(self.view)
	end
end
return skillpvpprocessor
