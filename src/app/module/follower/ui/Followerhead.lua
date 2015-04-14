local Followerhead = class("Followerhead", function()
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(79,79))
		return layout
	end)
function Followerhead:ctor()
	self.headNode = display.newNode()
	self.headNode:setPosition(40,40)
	self:addChild(self.headNode)

	self.bgpng = ccui.ImageView:create()
	self.bgpng:setPosition(40,40)
	self.bgpng:loadTexture("ui/comblack84.png")
	self:addChild(self.bgpng,-1)

	self.blankpng = ccui.ImageView:create()
	self.blankpng:setPosition(40,40)
	self:addChild(self.blankpng)

	self.blockTxt = display.newTTFLabel({
		text = "",
		font = DEFAULT_FONT,
		size = 12,
		align = cc.TEXT_ALIGNMENT_CENTER,
    	valign = cc.TEXT_ALIGNMENT_CENTER,
		dimensions = cc.size(79,20)
	})
	self.blockTxt:setPosition(40,40)
	self:addChild(self.blockTxt)
	self:setSelected(false)

end

function Followerhead:setData(data)
	self.data = data
	local maskSpr
	if(data.lock == true) then
		self.blockTxt:setString(data.lv.."级开放")
		self.blockTxt:setColor(cc.c3b(68,220,33))
		self.blockTxt:setSystemFontSize(16)		
		-- maskSpr = display.newMaskedSprite("ui/followerheadmask.png","ui/head/follower"..data.job..".png")
	else
		self.blockTxt:setString("")		
		maskSpr = display.newSprite("ui/head/follower"..data.job..".png")
		self.headNode:addChild(maskSpr)
	end
	
end
function Followerhead:setSelected(selected)
	if not self.data then
		return
	end
	if self.data.choose then
		if(selected == self.selected) then
			return
		end
		self.selected = selected
		if(selected) then
			self.blankpng:loadTexture("ui/followerselect.png")
		else
			self.blankpng:loadTexture("ui/84001.png")
		end
	else
		self.blankpng:loadTexture("ui/84002.png")
	end
	
end
function Followerhead:onDeleteMe()	
end
return Followerhead