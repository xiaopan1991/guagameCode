-- 弹出的输入文本框
-- Author: wanghe
-- Date: 2014-11-26 10:59:04

local GameAlert = import(".GameAlert")
local UIEditBox = import(".UIEditBox")
local GameInputAlert = class("GameInputAlert",GameAlert)

function GameInputAlert:ctor()
	self.super.ctor(self)

	--local editbox = UIEditBox.new(self.textView:getContentSize().width,45,"ui/chatinput.png")
	local editbox = ccui.EditBox:create(cc.size(self.textView:getContentSize().width,45), "ui/chatinput.png")
	editbox:setAnchorPoint(0, 0)
	editbox:setPosition(47,20)
	editbox:setFontName(DEFAULT_FONT)
	editbox:setFontSize(18)
	editbox:setPlaceholderFontColor(cc.c3b(0,255,0))
	--editbox:setMaxLength(20)
	--editbox:setMinLength(0)
	self.editbox = editbox
	self.textView:addChild(editbox)

	-- -- 不要删
	-- local editbox = ccui.EditBox:create(cc.size(self.textView:getContentSize().width-80,41), "ui/chatinput.png")
	-- editbox:setAnchorPoint(0, 0)
	-- editbox:setPosition(40,20)
	-- editbox:setFontName(DEFAULT_FONT)
	-- editbox:setFontSize(18)
	-- editbox:setPlaceholderFontColor(cc.c3b(0,255,0))
	-- editbox:setMaxLength(20)
	-- editbox.setString = editbox.setText
	-- editbox.getString = editbox.getText
	-- self.editbox = editbox
	-- self.textView:addChild(editbox)

	-- -- 不要删
	-- self.editboxbg = ccui.ImageView:create("ui/chatinput.png")
	-- self.editboxbg:setContentSize(cc.size(self.textView:getContentSize().width-60, 41))
	-- self.editboxbg:setScale9Enabled(true)
	-- self.editboxbg:setCapInsets(cc.rect(20, 15, 314, 8))
	-- self.editboxbg:setAnchorPoint(0, 0)
	-- self.editboxbg:setPosition(30, 28)
	-- self.textView:addChild(self.editboxbg)
	-- local editbox = ccui.TextField:create("请输入签名", DEFAULT_FONT, 18)
	-- editbox:ignoreContentAdaptWithSize(false)
	-- editbox:setContentSize(cc.size(self.textView:getContentSize().width-80, 41))
	-- editbox:setAnchorPoint(0, 0)
	-- editbox:setPosition(40, 20)
	-- editbox:setPlaceHolderColor(cc.c3b(0,255,0))
	-- editbox:setMaxLengthEnabled(true)
	-- editbox:setMaxLength(20)
	-- self.editbox = editbox
	-- self.textView:addChild(editbox)

	self.midbg:loadTexture("ui/blank.png")
	local txtinfobg = ccui.ImageView:create("ui/changenameBg.png")
	txtinfobg:setPosition(280,96)
	self.textView:addChild(txtinfobg)


end

--显示弹出框
--alertText 	文本内容 是一个table 或者一个string
-- 			table = {text = "" ,color = xx,size = 20,font = "xx",tag=1}
--title 	标题
--btns 		按钮及其回调
-- 			btns = {
-- 				{text = "",  skin = 1 , callback = function ,args = ...}
-- 			}
--			skin 1 2 3 对应GameAlert.btnskin里的123
function GameInputAlert:popInput(content,title,inputText,inputPlaceholder,callback,txtWidth,x)
	if(not txtWidth) then
		txtWidth = 615
	end

	local btns = {
		{text = "取消",skin = 2},
		{text = "确定",skin = 1,callback = handler(self,self.InputComplete)},
	}

	self:pop(content,title,btns,txtWidth)

	self.editbox:setText(inputText)
	self.editbox:setPlaceHolder(inputPlaceholder)

	self:updatePosition(txtWidth, 240)
	self.richtext:setPosition(x, 90)

	self.inputcallback = callback
end
function GameInputAlert:setMaxLength(len)
	self.editbox:setMaxLength(len)
end
function GameInputAlert:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	for k,v in pairs(self.btns) do
		if v.btn == sender then
			if v.callback ~= nil then
				--把文本作为参数回调出去
				local txt = self.editbox:getText()
				v.callback(txt)
			end
			break
		end
	end
	PopLayer:removePopView(self)
end

function GameInputAlert:InputComplete(txt)
    self.inputcallback(txt)
end

return GameInputAlert