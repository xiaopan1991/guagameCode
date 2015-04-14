local skillprocessor = class("skillprocessor", BaseProcessor)
local SkillItem = import(".skillitem")
function skillprocessor:ctor()
end
function skillprocessor:ListNotification()
	return {skillmodule.SHOW_SKILL,
		skillmodule.UPDATE_SKILL_UNLOCK,
		skillmodule.USER_CHANGE_SKILL_ORDER,
		skillmodule.UP_SKILL_ORDER,}
end
function skillprocessor:handleNotification(notify, node)
	if notify == skillmodule.SHOW_SKILL then 
		self:initUI()
	elseif notify == skillmodule.UPDATE_SKILL_UNLOCK then
		if(self.view) then
			self:updateData()
		end
	elseif notify == skillmodule.UP_SKILL_ORDER then
		local battleSkills = PlayerData:getBattleSkills()
		local temp = battleSkills[node.data.index]
		battleSkills[node.data.index] = battleSkills[node.data.index - 1]
		battleSkills[node.data.index - 1] = temp
		--PlayerData:setBattleSkills(battleSkills)
		local net = {}
		net.method = skillmodule.USER_CHANGE_SKILL_ORDER
		net.params = {}
		net.params.pvp_skills = false
		net.params.sid_list = {}
		for i,v in ipairs(battleSkills) do
			table.insert(net.params.sid_list,v)
		end
		Net.sendhttp(net)
	elseif notify == skillmodule.USER_CHANGE_SKILL_ORDER then
		if not node.data.params.pvp_skills then
			PlayerData:setBattleSkills(node.data.data)
		end
	end
end
function skillprocessor:initUI()
	if(not self.view) then
		self.mapPanel = ResourceManager:widgetFromJsonFile("ui/skillpanel.json")
		self.bg = self.mapPanel:getChildByName("bg")
		--self.scrollviewbg = self.mapPanel:getChildByName("scrollviewbg")
		self.skillscrollview = self.mapPanel:getChildByName("skillscrollview")
		self.specialbtn = self.mapPanel:getChildByName("specialbtn")
		self.pvpbtn = self.mapPanel:getChildByName("pvpbtn")
		self.changebtn = self.mapPanel:getChildByName("changebtn")
		self.infoTxt = self.mapPanel:getChildByName("infoTxt")
		local helpBtn = self.mapPanel:getChildByName("helpBtn")
		self.infoTxt:setString("作战技能")
		local btnClose = self.mapPanel:getChildByName("btnClose") 
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

		self.specialbtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.pvpbtn:addTouchEventListener(handler(self,self.onBtnClick))
		self.changebtn:addTouchEventListener(handler(self,self.onBtnClick))
		enableBtnOutLine(self.specialbtn,COMMON_BUTTONS.BLUE_BUTTON)
		enableBtnOutLine(self.changebtn,COMMON_BUTTONS.BLUE_BUTTON)
		enableBtnOutLine(self.pvpbtn,COMMON_BUTTONS.BLUE_BUTTON)
		helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
		btnClose:addTouchEventListener(handler(self,self.onBtnClick))

		self.skillItems = {}
	end
	self:setView(self.mapPanel)
	self:addMidView(self.mapPanel,true)
	self:updateData()
end
function skillprocessor:updateData()
	local allConfigBattleSkillNum = #(DataConfig:getUnlockBattleSkillCfg())
	local curUnlockNum = PlayerData:getUnlockBattleSkillsNum()
	local innerHeight = (10+138)*allConfigBattleSkillNum+10
	innerHeight = math.max(innerHeight,self.skillscrollview:getContentSize().height)
	self.skillscrollview:setInnerContainerSize(cc.size(616,innerHeight))
	local battleSkills = PlayerData:getBattleSkills()
	local skillItem
	for i=1,allConfigBattleSkillNum do
		skillItem = self.skillItems[i]
		if(not skillItem) then
			 skillItem = SkillItem.new()
			 self.skillscrollview:addChild(skillItem)
		end
		if(battleSkills[i]) then
			skillItem:updateData(false,i,battleSkills[i])
		else
			if(i<=curUnlockNum) then
				skillItem:updateData(false,i)
			else
				skillItem:updateData(true,i)
			end
		end
		skillItem:setPosition(0,innerHeight - (5+138)*i)
		self.skillItems[i] = skillItem
	end
	local cfg = DataConfig:getAllConfigMsg()
	local info = addArgsToMsg(cfg["20021"],PlayerData:getLv(),PlayerData:getUnlockBattleSkillsNum())
	self.infoTxt:setString(info)
end
function skillprocessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	if btnName == "specialbtn" then
		local btns = {{text = "确定",skin = 3,}}
		local alert = GameAlert.new()
		local richStr = {{text = "技能专精",color = COLOR_RED},
						{text = " 功能尚未开启，敬请期待",color = COLOR_GREEN},}
		alert:pop(richStr,"ui/titlenotice.png",btns)
	elseif btnName == "pvpbtn" then
		Observer.sendNotification(skillmodule.SHOW_SKILL_PVP)
	elseif btnName == "changebtn" then
		Observer.sendNotification(skillmodule.SHOW_SELECT_SKILL)
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("figure_follower")
	elseif btnName == "btnClose" then
		Observer.sendNotification(IndexModule.SHOW_INDEX,nil)
	end
end
return skillprocessor
