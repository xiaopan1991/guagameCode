--加载的 Loading转圈
--请求网络服务 如果若干秒内结果不回来 则显示小球球

local LoadingBall = class("LoadingBall",function() 
	local layout = ccui.Layout:create()
	layout:setContentSize(cc.size(display.width,display.height))
	layout:setTouchEnabled(true)
	return layout
	end)

LoadingBall.instance = nil

--
function LoadingBall.show()

	local runScene = display.getRunningScene()
	
	if runScene ~= GameInstance.mainScene and runScene ~= GameInstance.loginScene then
		return
	end
	
	if LoadingBall.instance == nil then
		LoadingBall.instance = LoadingBall.new()
		LoadingBall.instance:setName("LoadingBall")
	else
		return
	end
	PopLayer:popView(LoadingBall.instance)
	LoadingBall.instance:showball()
end

function LoadingBall.hide()
    --
	--PopLayer:stopTouch()
	local runScene = display.getRunningScene()
	if runScene~= GameInstance.mainScene and runScene ~= GameInstance.loginScene then
		return
	end
	if LoadingBall.instance == nil or tolua.isnull(LoadingBall.instance) then
		LoadingBall.instance = nil
		return
	end
	LoadingBall.instance:hideball()
	PopLayer:removePopView(LoadingBall.instance)
	LoadingBall.instance = nil
end

function LoadingBall:ctor()
	local sp = display.newSprite("ui/img_160.png")
	local size = self:getContentSize()
	sp:setPosition(size.width/2,size.height/2)
	self.sp = sp
	self:addChild(sp)
end

function LoadingBall:showball()	
	local sq = transition.sequence({
			cc.RotateBy:create(1, 360)
		})
	local re = cc.RepeatForever:create(sq)
	self.sp:runAction(re)
end

function LoadingBall:hideball()
	self.sp:stopAllActions()
end

return LoadingBall