--基础弹出窗口基类 所有弹出窗口均派生于此
local BasePanel = class("BasePanel", function ()
	return ccui.Layout:create()
end)

--构造函数
function BasePanel:ctor()
	self:setTouchEnabled(true)
	-- self:setTouchSwallowEnabled(false)
	-- view:setTouchEnabled(true)
	-- body
	local view = ResourceManager:widgetFromJsonFile("ui/poppanel.json")
	view:setTouchEnabled(true)
	self.view = view:getChildByName("panel")
	local btn = self.view:getChildByName("btnClose")
	btn:addTouchEventListener(handler(self,self.onBtnCloseClick))
	-- self.view:retain()
	local btn = self.view:getChildByName("btnClose")
	self:addChild(view)
end

--设置窗口的大小
function BasePanel:setPanelSize(width,height)
	-- self:setTouchSwallowEnabled(false)
	self:setTouchEnabled(true)
	-- body
	self.view:setContentSize(cc.size(width,height))
end

function BasePanel:setTitle(title)
	-- body
	local txtTitle = self.view:getChildByName("txtTitle")
	txtTitle:setString(title)
end

--设置关闭按钮是否显示
--设置成false 就不能再设置为true了 否则会报错
function BasePanel:setBtnCloseVisible(bool)
	-- body
	if not bool then
		local btn = self.view:getChildByName("btnClose")
		if btn~=nil then
			btn:removeFromParent()
		end
	end
end

function BasePanel:onBtnCloseClick(sender,eventType)
	-- body
	if  eventType ~= TouchEventType.ended then 
		return
	end
	PopLayer:removePopView(self)
	-- local btn = tolua.cast(sender,"ccui.Button")
	-- local btnName = btn:getName()
end

return BasePanel