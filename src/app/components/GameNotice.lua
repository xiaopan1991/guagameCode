--警告文字层
local GameNotice = class("GameNotice", function ()
	local ly = display.newLayer()
	ly:retain()   --永不被释放
	return ly
end)

--构造
function GameNotice:ctor()
	--保存当前显示的所有的notice
	self.notices = {}
	self.toast = {}
end
--显示下一个notice
function GameNotice:onNextNotice()
	table.remove(self.notices,1)
	if(#self.notices > 0) then
		self:popNotice(self.notices[1][1],self.notices[1][2])
	end
end
function GameNotice:popNotices(notices)
	self:clear()
	local nums = #notices
	local delay = 2--运动完后的集体静止时间
	local oneSpace = 50
	local oneSpaceTime = 0.1
	local startY = math.max(display.cy - oneSpace*nums/2,20)
	local label
	local bg
	for i,v in ipairs(notices) do
		label = display.newTTFLabel({
		    text = v[1],
		    font = DEFAULT_FONT,
		    size = 30,
		    color = v[2] or COLOR_RED, -- 使用纯红色
		})
		label:enableOutline(cc.c4b(0, 0, 0, 255),2)
		bg = display.newSprite("ui/noticebg.png")
		self:addChild(bg, 1)
		self:addChild(label, 2)
		bg:setPosition(display.cx,startY)
		bg:setVisible(false)
		label:setPosition(display.cx,startY)
		label:setVisible(false)
		
		local arr = {label,bg}
		local action1
		local action2
		local action3
		local action4
		local action5
		local action6
		for ii,vv in ipairs(arr) do
			action1 = cc.DelayTime:create((i-1)*oneSpaceTime)
			action2 = cc.CallFunc:create(handler(vv, self.onNoticeShow))
			action3 = cc.MoveTo:create((nums-i)*oneSpaceTime*2/3, cc.p(display.cx,startY+(nums-i)*oneSpace))
			action4 = cc.DelayTime:create(2)
			action5 = cc.FadeOut:create(0.5)
			action6 = cc.CallFunc:create(handler(vv, self.onNoticeHide))
			vv:runAction(transition.sequence({action1,action2,action3,action4,action5,action6}))
		end		
	end
end
function GameNotice:onNoticeShow()
	self:setVisible(true)
end
function GameNotice:popNotice(content,color)
	local label = display.newTTFLabel({
	    text = content,
	    font = DEFAULT_FONT,
	    size = 30,
	    color = color or COLOR_RED, -- 使用纯红色
	    -- align = cc.TEXT_ALIGN_CENTER,
	    -- valign = cc.TEXT_VALIGN_CENTER,
	    -- dimensions = cc.size(640, 200)
	})
	label:setPosition(display.cx,display.cy*3/4)
	label:setScale(2)
	local sequence = transition.sequence({
		cc.ScaleTo:create(0.3, 1),
	    cc.FadeOut:create(1.2),
	    cc.CallFunc:create(handler(label, self.onNoticeHide)),
	})
	local action1 = cc.Spawn:create({
		cc.MoveTo:create(1.5, cc.p(display.cx,display.height)),
	    sequence}
	)
	local action2 = transition.sequence({
		cc.DelayTime:create(0.10),
	    cc.CallFunc:create(handler(self, self.onNextNotice)),
	})
	local action3 = cc.Spawn:create({
		action1,
	    action2}
	)
	self:addChild(label)
	label:runAction(action3)
end
--显示一个notice
function GameNotice:showNotice(content,color)
	--把新的notice 文本放到屏幕的中间  
	--然后把新的notice存入数组
	table.insert(self.notices,{content,color})
	if(#self.notices == 1) then
		self:popNotice(self.notices[1][1],self.notices[1][2])
	end
end

--Text 消失的时候回调
--这个self 就是label
function GameNotice:onNoticeHide()
	-- body
	self:removeFromParent(true)
	-- print(self)
end
--屏幕中间出现notice，2秒后渐隐消失
function GameNotice:toastNotice(content,color)
	for i,v in ipairs(self.toast) do
		v:setPositionY((#self.toast + 1 - i)*50 + display.cy)
	end
	local label = display.newTTFLabel({
	    text = content,
	    font = DEFAULT_FONT,
	    size = 30,
	    color = color or COLOR_RED, -- 使用纯红色
	    -- align = cc.TEXT_ALIGN_CENTER,
	    -- valign = cc.TEXT_VALIGN_CENTER,
	    -- dimensions = cc.size(640, 200)
	})
	label:setPosition(display.cx,display.cy)
	local action = transition.sequence({
		cc.DelayTime:create(2),
		cc.FadeOut:create(0.5),
	    cc.CallFunc:create(handler(self, self.onToastNoticeHide)),
	})
	self:addChild(label)
	label:runAction(action)
	table.insert(self.toast, label)
end
function GameNotice:onToastNoticeHide()
	-- body	
	self.toast[1]:removeFromParent(true)
	table.remove(self.toast,1)
	-- print(self)
end
function GameNotice:clear()
	print("clear notice")
	self.notices = {}
	self.toast = {}
	self:removeAllChildren()
end

return GameNotice