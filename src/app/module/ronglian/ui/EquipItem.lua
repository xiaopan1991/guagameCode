--装备的选择
local ItemFace = require("app.components.ItemFace")
local EquipAttrInfo = require("app.components.EquipAttrInfo")
local EquipItem = class(EquipItem, function()
	local node = ccui.Layout:create()
	cc(node):addComponent("components.behavior.EventProtocol"):exportMethods()
    return node
end)
EquipItem.EQUIP_SELECT = "EQUIP_SELECT"

function EquipItem:ctor()
	if EquipItem.item == nil then
		EquipItem.item = ResourceManager:widgetFromJsonFile("ui/itemEquip.json")
		EquipItem.item:retain()
	end

	local itemEquip = EquipItem.item:clone()

	local txtInfo = itemEquip:getChildByName("txtInfo")
	--注意：根据装备是变化的
	txtInfo:setString("副手武器")
	self.chkEquip = itemEquip:getChildByName("chkEquip")
	self.chkEquip:addEventListener(handler(self,self.selectedEvent))
	self.item = ItemFace.new()
	self.item:setPosition(18,87)
	itemEquip:addChild(self.item)

	self.attr = EquipAttrInfo.new()
	self.attr:setPosition(280,180)
	itemEquip:addChild(self.attr)

	self:addChild(itemEquip)
end
--数据的传递
function EquipItem:setData(data)
	self.data = data
	self.attr:setData(data)
	self.item:setData(data)
	--传进来的数据，内部的改变是否勾选
	if data.select == nil then
		-- return
	elseif data.select == true then
		self.chkEquip:setSelected(true)
	end
	if data.visible == false then
		self.chkEquip:setEnabled(false)
	end
end

--勾选装备
function EquipItem:selectedEvent(sender,eventType)
	-- self.count = 0
	if  eventType == ccui.CheckBoxEventType.selected then 
		self.data.select = true
		-- self.count = self.count+1
		self:dispatchEvent({name =  EquipItem.EQUIP_SELECT, data = self.data})
	elseif eventType == ccui.CheckBoxEventType.unselected then
		self.data.select = false
		-- self.count = self.count-1
		self:dispatchEvent({name =  EquipItem.EQUIP_SELECT, data = self.data})
	end
	--派发事件
	
	-- if self.count == 6 then
	-- 	self:dispatchEvent({name =  EquipItem.EQUIP_SELECT, data = self.data})
	-- end
end

--设置复选框是否显示
function EquipItem:setCheckVisible(bool)
	self.chkEquip:setEnabled(bool)
end



return EquipItem