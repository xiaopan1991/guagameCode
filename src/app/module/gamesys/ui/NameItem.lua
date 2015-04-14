local NameItem = class(NameItem, function()
	local layout = ccui.Layout:create()
	layout:setContentSize(cc.size(545,127))
	cc(layout):addComponent("components.behavior.EventProtocol"):exportMethods()
	return layout
end)

NameItem.colors =  {cc.c3b(1, 144, 254), cc.c3b(245, 49, 247), cc.c3b(255, 240, 1)}
NameItem.colors_c4b =  {cc.c4b(1, 144, 254, 255), cc.c4b(245, 49, 247, 255), cc.c4b(255, 240, 1, 255)}
NameItem.info_colors = {cc.c3b(40, 134, 206), cc.c3b(211, 67, 186), cc.c3b(248, 191, 62)}
NameItem.images = {"ui/title_blue.png", "ui/title_violet.png", "ui/title_orange.png"}

function NameItem:ctor()
	self.p = nil
	self.title = nil
	self.usable = false
	self.use = false

	if NameItem.skin == nil then
		NameItem.skin = ResourceManager:widgetFromJsonFile("ui/nameItem.json")
		NameItem.skin:retain()
	end
	local viewItem = NameItem.skin:clone()

	self.getArrow = viewItem:getChildByName("getArrow")
	self.boxSelect = viewItem:getChildByName("boxSelect")
	self.txtInfo = viewItem:getChildByName("txtInfo")
	self.txtName = viewItem:getChildByName("txtName")
	self.txtget = viewItem:getChildByName("txtget")

	self.txtName:enableOutline(cc.c4b(0,0,0,255), 2)

	self:setTouchEnabled(false)
	viewItem:setTouchEnabled(false)

	self.boxSelect:addEventListener(handler(self,self.onClick))

	self:addChild(viewItem)
end
function NameItem:onClick(sender,eventType)
	self.p:onItemsCheckBox(self)
end
function NameItem:setRequestAward()
	-- local net = {}
	-- net.method = GamesysModule.USER_TASK_DONE
	-- net.params = {}
	-- net.params.task_key = self.data.id
	-- Net.sendhttp(net)
end
function NameItem:setData(title, usable, use)
	self.title = title
	self.usable = usable
	self.use = use

	-- self.txtName:enableOutline(NameItem.colors_c4b[title.color], 1)
	
	self.txtName:setColor(NameItem.colors[title.color])
	self.txtName:setString(title.name)
	

	self.getArrow:loadTexture(NameItem.images[title.color])

	self.txtInfo:setString(title.need)
	self.txtInfo:setColor(NameItem.info_colors[title.color])

	self.txtget:setVisible(not usable)
	self.boxSelect:setVisible(usable)
	self.boxSelect:setEnabled(usable)
	self.boxSelect:setSelected(use)
end


return NameItem
