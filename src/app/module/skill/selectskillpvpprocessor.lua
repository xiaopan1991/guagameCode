local selectskillpvpprocessor = class("selectskillpvpprocessor", BaseProcessor)
local SelectSkillPvpItem = import(".selectskillpvpitem")
function selectskillpvpprocessor:ctor()
	self.curSelectSkills = {}
end
function selectskillpvpprocessor:ListNotification()
	return {
		skillmodule.SHOW_SELECT_SKILL_PVP,
		skillmodule.UPDATE_SELECT_SKILL_PVP,
		skillmodule.UPDATE_SKILL_UNLOCK_PVP,
	}
end
function selectskillpvpprocessor:handleNotification(notify, node)
	if notify == skillmodule.SHOW_SELECT_SKILL_PVP then 
		self:initUI()
	elseif notify == skillmodule.UPDATE_SELECT_SKILL_PVP then
		if(node.data.bAdd) then
			self:addSelectSkill(node.data.skillid)
		else
			self:removeSelectSkill(node.data.skillid)
		end
		self:updateData()
	elseif notify == skillmodule.UPDATE_SKILL_UNLOCK_PVP then
		if(self.view) then
			self:updateData()
		end
	end
end
function selectskillpvpprocessor:initUI()
	if(not self.view) then
		self.mapPanel = ResourceManager:widgetFromJsonFile("ui/skillpvppanel.json")
		self.mapPanel:setName("selectskillpvppanel")--手动改名与skillpvpprocessor的view区分
		self.bg = self.mapPanel:getChildByName("bg")
		local titlebg = self.mapPanel:getChildByName("tittle")
		-- titlebg:loadTexture("ui/comtitle.png")
		--self.scrollviewbg = self.mapPanel:getChildByName("scrollviewbg")
		self.skillscrollview = self.mapPanel:getChildByName("skillscrollview")
		self.defaultbtn = self.mapPanel:getChildByName("defaultbtn")
		self.changebtn = self.mapPanel:getChildByName("changebtn")
		self.infoTxt = self.mapPanel:getChildByName("infoTxt")
		-- local helpBtn = self.mapPanel:getChildByName("helpBtn")
		local closeBtn = self.mapPanel:getChildByName("closeBtn")
		-- helpBtn:removeFromParent(true)
		self.defaultbtn:setTitleText("取消")
		enableBtnOutLine(self.defaultbtn,COMMON_BUTTONS.BLUE_BUTTON)
		enableBtnOutLine(self.changebtn,COMMON_BUTTONS.ORANGE_BUTTON)
		self.changebtn:setTitleText("保存")
		self.changebtn:loadTextures("ui/combtnyellow.png","ui/combtnyellow.png","")

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

		closeBtn:addTouchEventListener(handler(self,self.onBtnClick))

		self.skillPvpItems = {}
	end
	self:setView(self.mapPanel)
	self:addPopView(self.mapPanel,true)
	self:initSelectSkill()
	self:updateData()
end
function selectskillpvpprocessor:initSelectSkill()
	self.curSelectSkills = {}
	local pvpSkills = PlayerData:getPvpSkills()
	for i,v in ipairs(pvpSkills) do
		self.curSelectSkills[i] = v
	end
end
function selectskillpvpprocessor:addSelectSkill(skillid)
	self.curSelectSkills[#self.curSelectSkills + 1] = skillid
end
function selectskillpvpprocessor:removeSelectSkill(skillid)
	table.removebyvalue(self.curSelectSkills, skillid)
end
function selectskillpvpprocessor:updateData()
	local cfgOpenSkillNum = PlayerData:getUnlockBattleSkillsNum()
	local jobSkillDic = DataConfig:getReconfigSkill()
	local job = PlayerData:getHeroType()
	local openskills = PlayerData:getAllOpenSkills()

	local allJobSkills = #jobSkillDic[job]
	local innerHeight = (10+138)*allJobSkills+10
	innerHeight = math.max(innerHeight,self.skillscrollview:getContentSize().height)
	self.skillscrollview:setInnerContainerSize(cc.size(616,innerHeight))
	local skillPvpItem
	for i,v in ipairs(jobSkillDic[job]) do
		skillPvpItem = self.skillPvpItems[i]
		if(not skillPvpItem) then
			 skillPvpItem = SelectSkillPvpItem.new()
			 self.skillscrollview:addChild(skillPvpItem)
		end
		if(openskills[v.id]) then
			if(table.indexof(self.curSelectSkills, v.id)) then
				skillPvpItem:updateData(v.id,i,false,1)--selectstate,1,2,3=选中，未选中，不可选
			else
				if(#self.curSelectSkills >= cfgOpenSkillNum) then------------------
					skillPvpItem:updateData(v.id,i,false,3)--selectstate,1,2,3=选中，未选中，不可选
				else
					skillPvpItem:updateData(v.id,i,false,2)--selectstate,1,2,3=选中，未选中，不可选
				end
			end
		else
			skillPvpItem:updateData(v.id,i,true)--selectstate,1,2,3=选中，未选中，不可选
		end
		skillPvpItem:setPosition(0,innerHeight - (5+138)*i)
		self.skillPvpItems[i] = skillPvpItem
	end
	self.skillscrollview:setInnerContainerSize(cc.size(616,innerHeight))
	local cfg = DataConfig:getAllConfigMsg()
	local info = cfg["20056"]
	self.infoTxt:setString(info)
end
function selectskillpvpprocessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	if btnName == "defaultbtn" then--取消
		-- Observer.sendNotification(skillmodule.SHOW_SKILL_PVP)
		self:removePopView(self.view)
	elseif btnName == "changebtn" then--保存
		print('xxxxxxxxxxxxxxxxxxxxxxxxxxx')
		self:sendSaveSkills()
		-- Observer.sendNotification(skillmodule.SHOW_SKILL_PVP)
		self:removePopView(self.view)
	elseif btnName == "closeBtn" then
		self:removePopView(self.view)
	end
end
function selectskillpvpprocessor:sendSaveSkills()
	local net = {}
	net.method = skillmodule.USER_CHANGE_SKILL_ORDER
	net.params = {}
	net.params.pvp_skills = true
	net.params.sid_list = {}
	for i,v in ipairs(self.skillPvpItems) do
		if(v.selectstate == 1) then
			table.insert(net.params.sid_list,v.skillid)
		end
	end
	Net.sendhttp(net)
end
return selectskillpvpprocessor