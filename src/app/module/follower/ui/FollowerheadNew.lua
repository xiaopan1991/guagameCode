--
-- Author: Your Name
-- Date: 2015-01-14 18:11:17
--
local FollowerheadNew = class("FollowerheadNew", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(178,101))
		return layout
	end)
function FollowerheadNew:ctor()
	self.state = 1--1,锁,2,解锁
	self.png = ccui.ImageView:create()
	self.png:setAnchorPoint(cc.p(0,0))
	self.blockTxt = display.newTTFLabel({
		text = "",
		font = DEFAULT_FONT,
		size = 12,
		align = cc.TEXT_ALIGNMENT_CENTER,
    	valign = cc.TEXT_ALIGNMENT_CENTER,
		dimensions = cc.size(79,20)
	})
	self:addChild(self.png)
	self.blockTxt:setPosition(89,38)
	self:addChild(self.blockTxt)
end
function FollowerheadNew:setData(data)
	self.data = data
	local maskSpr
	if(data.lock == true) then
		self.blockTxt:setString(data.lv.."级开放")
		self.blockTxt:setColor(cc.c3b(68,220,33))
		self.blockTxt:setSystemFontSize(16)
		self.png:loadTexture("ui/followerlock"..data.job..".png")		
		-- maskSpr = display.newMaskedSprite("ui/followerheadmask.png","ui/head/follower"..data.job..".png")
	else
		self.blockTxt:setString("")
		self.png:loadTexture("ui/followerunselect"..data.job..".png")
	end
	
end
function FollowerheadNew:setSelected(selected)
	if not self.data or self.data.lock then
		return
	end
	if(selected == self.selected) then
		return
	end
	self.selected = selected
	if(selected) then
		self.png:loadTexture("ui/followerselected"..self.data.job..".png")
	else
		self.png:loadTexture("ui/followerunselect"..self.data.job..".png")
	end
end
function FollowerheadNew:onDeleteMe()	
end
return FollowerheadNew