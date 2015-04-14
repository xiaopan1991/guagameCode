--主页
local IndexProcessor = class("IndexProcessor", BaseProcessor)

--构造
function IndexProcessor:ctor()
	self.name = "IndexProcessor"
end

--关心的消息列表
function IndexProcessor:ListNotification()
	return {
		IndexModule.SHOW_INDEX,
	}
end

--消息处理
--notify 	消息名
--data 		数据
function IndexProcessor:handleNotification(notify, data)
	if notify == IndexModule.SHOW_INDEX then
		if self.view~=nil then
			return
		end
		self:onSetView(data)
		Observer.sendNotification(IndexModule.SHOW_MAIN_TOP)
	end
end
--设置显示对象 绑定事件
function IndexProcessor:onSetView(data)
	local lay = ccui.Layout:create()

	local homepage = ResourceManager:widgetFromJsonFile("ui/homepage.json")
	lay:setName("homepage")
	self.det = display.height - 960
	local theight = 766
	if display.height > 960 then
		theight = 766 + self.det
	end
	local size = homepage:getLayoutSize()
	homepage:setContentSize(cc.size(size.width,theight))

	size = homepage:getContentSize()
	local height = display.height - TOP_HEIGHT - BOTTOM_HEIGHT
	lay:setContentSize(cc.size(size.width,height))
	lay:addChild(homepage)
	homepage:setPosition(0,(height - size.height)/2)
	self:setView(lay)
	GameInstance.mainScene:addMidView(lay)

    local midLay = homepage:getChildByName("midLay")
	--竞技场
	local btnJJC = midLay:getChildByName("btnJJC")
	--商城
	local btnShop = midLay:getChildByName("btnShop")
	--熔炼
	local btnRonglian = midLay:getChildByName("btnRonglian")
	--多人团战
	local btnBattle = midLay:getChildByName("btnBattle")
	--公会
	local btnGonghui = midLay:getChildByName("btnGonghui")
	--充值
	local btnCharge =  midLay:getChildByName("btnCharge")

	btnJJC:addTouchEventListener(handler(self, self.onIndexBtnClick))
	btnShop:addTouchEventListener(handler(self, self.onIndexBtnClick))
	btnRonglian:addTouchEventListener(handler(self, self.onIndexBtnClick))
	btnBattle:addTouchEventListener(handler(self, self.onIndexBtnClick))
	btnGonghui:addTouchEventListener(handler(self, self.onIndexBtnClick))
	btnCharge:addTouchEventListener(handler(self, self.onIndexBtnClick))

	if(not TimeManager.started ) then
		BattleManager:noticeOffLineReward()
	end
	self:getMailMsg()
	Observer.sendNotification(GamesysModule.UPDATE_GAME_TASK)
end
function IndexProcessor:getMailMsg()
	local net = {}
	net.method = GamesysModule.USER_GET_MSG
	net.params = {}
	Net.sendhttp(net)
end
--响应按钮点击
function IndexProcessor:onIndexBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	
	print("touch index btn:"..btnName)
	if btnName == "btnJJC" then
		if(PlayerData.data.power >= DataConfig.data.cfg.system_simple.power_limit) then
			local key = PlayerData:getUid()..PlayerData:getZone().."firstOpenJJC"
			if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
				cc.UserDefault:getInstance():setIntegerForKey(key, 1)
				local alert = GameAlert.new()
	   			alert:popHelp("newbie_guide_8","ui/titlenotice.png")
			end
			Observer.sendNotification(PVPModule.SHOW_PVP_PANEL)
		else
			local cfg = DataConfig:getAllConfigMsg()
			local info = addArgsToMsg(cfg["30011"],DataConfig.data.cfg.system_simple.power_limit)
			local btns = {{text = "确定",skin = 3,},}
			local alert = GameAlert.new()
			alert:pop({{text = info}},"ui/titlenotice.png",btns)
		end
	elseif btnName == "btnShop" then
		Observer.sendNotification(ShopModule.SHOW_SHOP)
	elseif btnName == "btnRonglian" then
		Observer.sendNotification(RonglianModule.SHOW_RONG_LIAN)
	elseif btnName == "btnBattle" then
		-- TODO 检查战斗力
		local pvp = DataConfig.data.cfg.system_simple.multiplayer_pvp
		if PlayerData:getLv() < pvp.lv_limit then
			local alert = GameAlert.new()
			local btns = {{text = "确定",skin = 3,},}
			alert:pop(addArgsToMsg('等级达到@0才能进入', pvp.lv_limit),"ui/titlenotice.png", btns)
			return
		end
		local net = {}
		net.method = MultiBattleModule.USER_GET_MULTIPLAYER_PVP_INFO
		net.params = {}
		Net.sendhttp(net)
	elseif btnName == "btnGonghui" then
		local btns = {{text = "确定",skin = 3,}}
		local alert = GameAlert.new()
		local richStr = {{text = "帮派",color = COLOR_RED},
						{text = " 功能尚未开启，敬请期待",color = COLOR_GREEN},}
		alert:pop(richStr,"ui/titlenotice.png",btns)
	elseif btnName == "btnCharge" then
		Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
	end
end
return IndexProcessor
