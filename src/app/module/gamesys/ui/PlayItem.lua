local PlayItem = class("PlayItem", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(105,105))
		return layout
	end)
function PlayItem:ctor()
	local size = self:getContentSize()
	self.w = size.width/2
	self.h = size.height/2

	self.kuang = ccui.ImageView:create("ui/90002.png")
	self.kuang:setPosition(self.w,self.h)
	self:addChild(self.kuang,3)

	self.bg = ccui.ImageView:create("ui/comblack84.png")
	self.bg:setPosition(self.w,self.h)
	self:addChild(self.bg,1)
	
end
function PlayItem:setData(data)
	self.head = ccui.ImageView:create("ui/head/"..data..".png")
	self.head:setPosition(self.w,self.h)
	self:addChild(self.head,2)
end
return PlayItem