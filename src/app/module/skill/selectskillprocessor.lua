local selectskillprocessor = class("selectskillprocessor", BaseProcessor)
local SelectSkillItem = import(".selectskillitem")
function selectskillprocessor:ctor()
	self.curSelectSkills = {}
end
function selectskillprocessor:ListNotification()
	return {skillmodule.SHOW_SELECT_SKILL,
			skillmodule.UPDATE_SELECT_SKILL,
			skillmodule.UPDATE_SKILL_UNLOCK,}
end
function selectskillprocessor:handleNotification(notify, node)
	if notify == skillmodule.SHOW_SELECT_SKILL then 
		self:initUI()
	elseif notify == skillmodule.UPDATE_SELECT_SKILL then
		if(node.data.bAdd) then
			self:addSelectSkill(node.data.skillid)
		else
			self:removeSelectSkill(node.data.skillid)
		end
		self:updateData()
	elseif notify == skillmodule.UPDATE_SKILL_UNLOCK then
		if(self.view) then
			self:updateData()
		end
	end
end
function selectskillprocessor:initUI()
	if(not self.view) then
		self.mapPanel = ResourceManager:widgetFromJsonFile("ui/skillpanel.json")
		self.mapPanel:setName("selectskillpanel")--手动改名与skillprocessor的view区分
		self.bg = self.mapPanel:getChildByName("bg")
		local titlebg = self.mapPanel:getChildByName("tittle")
		titlebg:loadTexture("ui/comtitle.png")
		--self.scrollviewbg = self.mapPanel:getChildByName("scrollviewbg")
		self.skillscrollview = self.mapPanel:getChildByName("skillscrollview")
		self.specialbtn = self.mapPanel:getChildByName("specialbtn")
		self.pvpbtn = self.mapPanel:getChildByName("pvpbtn")
		self.changebtn = self.mapPanel:getChildByName("changebtn")
		self.infoTxt = self.mapPanel:getChildByName("infoTxt")
		local btnClose = self.mapPanel:getChildByName("btnClose")
		btnClose:setVisible(false)
		local helpBtn = self.mapPanel:getChildByName("helpBtn")
		helpBtn:removeFromParent(true)
		self.specialbtn:setTitleText("取消")
		enableBtnOutLine(self.specialbtn,COMMON_BUTTONS.BLUE_BUTTON)
		enableBtnOutLine(self.changebtn,COMMON_BUTTONS.ORANGE_BUTTON)
		self.changebtn:setTitleText("保存")
		self.changebtn:loadTextures("ui/combtnyellow.png","ui/combtnyellow.png","")

		self.pvpbtn:setEnabled(false)
		self.pvpbtn:setVisible(false)

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
		self.changebtn:addTouchEventListener(handler(self,self.onBtnClick))

		self.skillItems = {}
	end
	self:setView(self.mapPanel)
	self:addMidView(self.mapPanel,true)
	self:initSelectSkill()
	self:updateData()
end
function selectskillprocessor:initSelectSkill()
	self.curSelectSkills = {}
	local battleSkills = PlayerData:getBattleSkills()
	for i,v in ipairs(battleSkills) do
		self.curSelectSkills[i] = v
	end
end
function selectskillprocessor:addSelectSkill(skillid)
	self.curSelectSkills[#self.curSelectSkills + 1] = skillid
end
function selectskillprocessor:removeSelectSkill(skillid)
	table.removebyvalue(self.curSelectSkills, skillid)
end
function selectskillprocessor:updateData()
	local cfgOpenSkillNum = PlayerData:getUnlockBattleSkillsNum()
	local jobSkillDic = DataConfig:getReconfigSkill()
	local job = PlayerData:getHeroType()
	local openskills = PlayerData:getAllOpenSkills()

	local allJobSkills = #jobSkillDic[job]
	local innerHeight = (10+138)*allJobSkills+10
	innerHeight = math.max(innerHeight,self.skillscrollview:getContentSize().height)
	self.skillscrollview:setInnerContainerSize(cc.size(616,innerHeight))
	local skillItem
	for i,v in ipairs(jobSkillDic[job]) do
		skillItem = self.skillItems[i]
		if(not skillItem) then
			 skillItem = SelectSkillItem.new()
			 self.skillscrollview:addChild(skillItem)
		end
		if(openskills[v.id]) then
			if(table.indexof(self.curSelectSkills, v.id)) then
				skillItem:updateData(v.id,i,false,1)--selectstate,1,2,3=选中，未选中，不可选
			else
				if(#self.curSelectSkills >= cfgOpenSkillNum) then------------------
					skillItem:updateData(v.id,i,false,3)--selectstate,1,2,3=选中，未选中，不可选
				else
					skillItem:updateData(v.id,i,false,2)--selectstate,1,2,3=选中，未选中，不可选
				end
			end
		else
			skillItem:updateData(v.id,i,true)--selectstate,1,2,3=选中，未选中，不可选
		end
		skillItem:setPosition(0,innerHeight - (5+138)*i)
		self.skillItems[i] = skillItem
	end
	self.skillscrollview:setInnerContainerSize(cc.size(616,innerHeight))
	local cfg = DataConfig:getAllConfigMsg()
	local info = addArgsToMsg(cfg["20021"],PlayerData:getLv(),cfgOpenSkillNum)
	self.infoTxt:setString(info)
end
function selectskillprocessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btnName = sender:getName()
	if btnName == "specialbtn" then--取消
		Observer.sendNotification(skillmodule.SHOW_SKILL)
	elseif btnName == "changebtn" then--保存
		self:sendSaveSkills()
		Observer.sendNotification(skillmodule.SHOW_SKILL)
	end
end
function selectskillprocessor:sendSaveSkills()
	local net = {}
	net.method = skillmodule.USER_CHANGE_SKILL_ORDER
	net.params = {}
	net.params.pvp_skills = false
	net.params.sid_list = {}
	for i,v in ipairs(self.skillItems) do
		if(v.selectstate == 1) then
			table.insert(net.params.sid_list,v.skillid)
		end
	end
	Net.sendhttp(net)
end
return selectskillprocessor