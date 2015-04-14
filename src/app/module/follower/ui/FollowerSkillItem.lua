--
-- Author: wanghe
-- Date: 2014-11-14 14:19:05
-- followerskillitem
local FollowerSkillItem = class("FollowerSkillItem", function ()
	local node = ccui.Layout:create()
	node:setContentSize(cc.size(550,128))
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
	return node
end)

FollowerSkillItem.skin = nil

FollowerSkillItem.ITEM_SELECT = "ITEM_CLICK"

--弟子技能条
function FollowerSkillItem:ctor()
	self:init()
end

--初始化UI
function FollowerSkillItem:init()
	if FollowerSkillItem.skin == nil then
		FollowerSkillItem.skin = ResourceManager:widgetFromJsonFile("ui/followerskillitem.json")
		FollowerSkillItem.skin:retain()
	end

	local view = FollowerSkillItem.skin:clone()
	self:addChild(view)
	self.view = view

	-- 技能图标
	-- local skilliconblank: 
	self.skillnametxt 	= view:getChildByName("skillnametxt")
	self.skillcosttxt 	= view:getChildByName("skillcosttxt")
	self.skilldsctxt 	= view:getChildByName("skilldsctxt")
	self.selectBtn 		= view:getChildByName("selectBtn")
	self.skillicon 		= view:getChildByName("skillicon")
	self.skilllvtxt		= view:getChildByName("skilllvtxt")
	--check box
	self.selectBtn:addEventListener(handler(self,self.handleCheckItem))
end

--checkBOX点击
function FollowerSkillItem:handleCheckItem(sender,eventType)
	if  eventType == ccui.CheckBoxEventType.selected then 
		self.data.select = true
		self:dispatchEvent({name =  FollowerSkillItem.ITEM_SELECT, data = self.data})
	elseif eventType == ccui.CheckBoxEventType.unselected then
		self.data.select = false
		self:dispatchEvent({name =  FollowerSkillItem.ITEM_SELECT, data = self.data})
	end
end

--设置数据
function FollowerSkillItem:setData(data)
	self.data = data
	-- self.skillnametxt
	if self.data.sid == "None" or self.data.sid == ""  then
		--给空值
		return
	end

	if data.select == true then
		self.selectBtn:setSelected(true)
	end

	--技能名字
	local skill = DataConfig:getSkillById(self.data.sid)
	self.skillnametxt:setString(skill.name)

	self.skillcosttxt:setString("消耗内力："..skill.mp[2])
	self.skilldsctxt:setString(skill.info)
	self.skilllvtxt:setString(""..skill.unlock_lv)
	self.skillicon:loadTexture("skillicon/"..self.data.sid..".png")
end

return FollowerSkillItem