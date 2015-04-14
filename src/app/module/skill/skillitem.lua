local skillitem = class("skillitem", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(616,138))
		return layout
	end)
function skillitem:ctor()
	if(not skillitem.view) then
		skillitem.view = ResourceManager:widgetFromJsonFile("ui/skillitem.json")
		skillitem.view:retain()
	end	
	self.view = skillitem.view:clone()
	self.bg = self.view:getChildByName("bg")
	self.skillicon = self.view:getChildByName("skillicon")
	self.skilliconbg = self.view:getChildByName("skilliconbg")
	self.skilliconblank = self.view:getChildByName("skilliconblank")
	
	self.skillbg1 = self.view:getChildByName("skillbg1")
	self.skillbg2 = self.view:getChildByName("skillbg2")
	self.signBtn = self.view:getChildByName("signBtn")
	self.skillnametxt = self.view:getChildByName("skillnametxt")
	self.skillcosttxt = self.view:getChildByName("skillcosttxt")
	self.skilldsctxt = self.view:getChildByName("skilldsctxt")
	self.lock = self.view:getChildByName("lock")
	self.unlocktips = self.view:getChildByName("unlocktips")
	self.signBtn:addTouchEventListener(handler(self,self.onClick))
	self.bg:addTouchEventListener(handler(self,self.onClickSkill))  
	local selectBtn = self.view:getChildByName("selectBtn")
	selectBtn:removeFromParent(true)

	self.lockarray = {self.lock,self.unlocktips}
	self.openarray = {self.skillicon,self.skilliconblank,self.skillbg1,self.skillbg2,self.signBtn,
						self.skillnametxt,self.skillcosttxt,self.skilldsctxt,}
	self:addChild(self.view)
end
function skillitem:updateData(locked,index,skillid)
	self.index = index
	self.skillid = self.skillid
	if(locked) then
		for i,v in ipairs(self.lockarray) do
			v:setVisible(true)
		end
		for i,v in ipairs(self.openarray) do
			v:setVisible(false)
		end
		self.signBtn:setTouchEnabled(false)
		self.bg:setTouchEnabled(false)
		self.unlocktips:setColor(cc.c3b(255,255,0))
		self.unlocktips:setString("人物等级 "..DataConfig:getUnlockBattleSkillCfg()[index].." 开启")--人物等级 25 开启
		self.skilliconbg:setVisible(false)
	elseif(skillid) then
		for i,v in ipairs(self.lockarray) do
			v:setVisible(false)
		end
		for i,v in ipairs(self.openarray) do
			v:setVisible(true)
		end
		self.bg:setTouchEnabled(false)
		if(index == 1) then
			self.signBtn:loadTextureNormal("ui/redflag.png")
			self.signBtn:setTouchEnabled(false)
		else
			self.signBtn:loadTextureNormal("ui/blueflag.png")
			self.signBtn:setTouchEnabled(true)
		end
		self.skillnametxt:setString(DataConfig:getSkillById(skillid).name)
		local skilllv = PlayerData:getAllOpenSkills()[skillid].lv
		self.skillcosttxt:setString("消耗内力："..DataConfig:getSkillMpByIdLv(skillid,skilllv))
		self.skilldsctxt:setString(DataConfig:getSkillById(skillid).info)
		self.skillicon:loadTexture("skillicon/"..skillid..".png")
		self.skilliconbg:setVisible(true)
	else
		self.lock:setVisible(false)
		for i,v in ipairs(self.openarray) do
			v:setVisible(false)
		end
		self.unlocktips:setVisible(true)
		self.unlocktips:setColor(cc.c3b(0,255,0))
		self.unlocktips:setString("已开启，点击更换技能")
		self.bg:setTouchEnabled(true)
		self.signBtn:setTouchEnabled(false)
		self.skilliconbg:setVisible(false)
	end
end
function skillitem:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data			
	data.index = self.index
	Observer.sendNotification(skillmodule.UP_SKILL_ORDER,tempNode)
end
function skillitem:onClickSkill(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	Observer.sendNotification(skillmodule.SHOW_SELECT_SKILL)
end
return skillitem
