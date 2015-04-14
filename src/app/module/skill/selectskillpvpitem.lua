local selectskillitem = class("selectskillitem", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(545,127))
		return layout
	end)
function selectskillitem:ctor()
	if(not selectskillitem.view) then
		selectskillitem.view = ResourceManager:widgetFromJsonFile("ui/skillitem.json")
		selectskillitem.view:retain()
	end	
	self.view = selectskillitem.view:clone()

	self.skillicon = self.view:getChildByName("skillicon")
	self.skilliconblank = self.view:getChildByName("skilliconblank")
	self.skillbg1 = self.view:getChildByName("skillbg1")
	self.skillbg2 = self.view:getChildByName("skillbg2")
	self.selectBtn = self.view:getChildByName("selectBtn")
	self.skillnametxt = self.view:getChildByName("skillnametxt")
	self.skillcosttxt = self.view:getChildByName("skillcosttxt")
	self.skilldsctxt = self.view:getChildByName("skilldsctxt")
	self.lock = self.view:getChildByName("lock")
	local unlocktips = self.view:getChildByName("unlocktips")
	self.selectBtn:addTouchEventListener(handler(self,self.onClick)) 
	local signBtn = self.view:getChildByName("signBtn")
	signBtn:removeFromParent(true)
	unlocktips:removeFromParent(true)
	self:addChild(self.view)
end
function selectskillitem:updateData(skillid,index,locked,selectstate)--selectstate,1,2,3=选中，未选中，不可选
	self.index = index
	self.skillid = skillid
	self.selectstate = selectstate
	self.skillnametxt:setString(DataConfig:getSkillById(skillid).name)
	if(not locked) then
		local skilllv = PlayerData:getAllOpenSkills()[skillid].lv
		self.skillcosttxt:setColor(cc.c3b(0,103,244))
		self.skillcosttxt:setString("消耗内力："..DataConfig:getSkillMpByIdLv(skillid,skilllv))
		self.selectBtn:setVisible(true)
		if(selectstate == 1) then
			self.selectBtn:loadTextureNormal("ui/dui_box.png")
			self.selectBtn:setTouchEnabled(true)
		elseif(selectstate == 2) then
			self.selectBtn:loadTextureNormal("ui/choosebox.png")
			self.selectBtn:setTouchEnabled(true)
		elseif(selectstate == 3) then
			self.selectBtn:loadTextureNormal("ui/skilllock.png")
			self.selectBtn:setTouchEnabled(false)
		end
		self.lock:setVisible(false)
		self.skillicon:setColor(cc.c3b(255,255,255))
	else
		self.skillcosttxt:setColor(cc.c3b(255,0,0))
		local cfg = DataConfig:getAllConfigMsg()
		local str = addArgsToMsg(cfg["30027"],DataConfig:getSkillById(skillid).unlock_lv)
		self.skillcosttxt:setString(str)
		self.selectBtn:setVisible(false)
		self.selectBtn:setTouchEnabled(false)
		self.lock:setVisible(true)
		self.lock:pos(532, 75)
		self.skillicon:setColor(cc.c3b(120,120,120))
	end
	self.skilldsctxt:setString(DataConfig:getSkillById(skillid).info)
	self.skillicon:loadTexture("skillicon/"..skillid..".png")
end
function selectskillitem:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local tempNode = display.newNode()
	local data = {}
	tempNode.data = data
	if(self.selectstate == 1) then
		data.bAdd = false
	elseif(self.selectstate == 2) then
		data.bAdd = true
	end
	data.skillid = self.skillid	
	Observer.sendNotification(skillmodule.UPDATE_SELECT_SKILL_PVP,tempNode)
end
return selectskillitem
