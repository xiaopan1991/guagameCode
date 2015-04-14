--
-- Author: Your Name
-- Date: 2015-01-22 17:49:46
--
local MultiBattleProcessor = class("MultiBattleProcessor", BaseProcessor)
function MultiBattleProcessor:ctor()
	-- self.state = 0--0,未开启1，报名已结束，正在战斗中2，报名中，未报名，3，报名中，已报名，非队长
	--4，报名中，已报名，队长
	-- self.combat_begin_time = 0
	-- self.sign_up_time = 0
	-- self.begin_fight_time = 0
	self.timeDiff = 0 -- 服务器和本地时间的时差
end
function MultiBattleProcessor:ListNotification()
	return {
		-- MultiBattleModule.SHOW_MULTI_BATTLE,
		MultiBattleModule.USER_GET_MULTIPLAYER_PVP_INFO,
		MultiBattleModule.USER_SIGN_UP_MULTIPLAYER_PVP,
		MultiBattleModule.USER_CANCEL_SIGN_UP,
    }
end
function MultiBattleProcessor:handleNotification(notify, data)
	if notify == MultiBattleModule.USER_GET_MULTIPLAYER_PVP_INFO then
		-- dump(data.data)
		if data.data.data.sign == 0 then
			local btns = {{text = "确定",skin = 3,}}
			local alert = GameAlert.new()
			local richStr = {{text = "多人团战",color = COLOR_RED},
							{text = " 功能尚未开启，敬请期待",color = COLOR_GREEN},}
			alert:pop(richStr,"ui/titlenotice.png",btns)
			return
		end

		-- 计算服务器和本地的时间差
		self.timeDiff = os.time() - changeTimeStrToSec(data.data.server_now['$datetime'])

		self:initUI()
		self:setData(data.data.data)
		self:updateUI()
	elseif notify == MultiBattleModule.USER_SIGN_UP_MULTIPLAYER_PVP then
		if data.data.params.is_leader then
			self.data.stage.is_sign_up = 1
			self.data.stage.is_leader = 1

			local payCoin = DataConfig.data.cfg.system_simple.multiplayer_pvp.sign_up_coin
			PlayerData:setCoin(math.floor(data.data.data.coin))
			popNotices({{"创建队伍成功",COLOR_GREEN},{"元宝: -"..payCoin,COLOR_RED},})
		else
			self.data.stage.is_sign_up = 1
			self.data.stage.is_leader = 0

			local cfg = DataConfig:getAllConfigMsg()
			toastNotice(cfg['20031'], COLOR_GREEN)
		end
		self:updateUI()
	elseif notify == MultiBattleModule.USER_CANCEL_SIGN_UP then
		-- self.state = 2
		self.data.stage.is_sign_up = 0
		self:updateUI()
	end

end
function MultiBattleProcessor:initUI()
	if(not self.view) then
		self.panel = ResourceManager:widgetFromJsonFile("ui/MultiBattleUI.json")
		self.bg = self.panel:getChildByName("bg")
		self.helpbtn = self.panel:getChildByName("helpbtn")
		self.top = self.panel:getChildByName("top")
		self.middle = self.panel:getChildByName("middle")
		self.bottom = self.panel:getChildByName("bottom")
		local btnClose = self.panel:getChildByName("btnClose")
		self.tiptxt = self.top:getChildByName("tiptxt")
		self.managerbtn = self.bottom:getChildByName("managerbtn")
		self.cancelsignbtn = self.bottom:getChildByName("cancelsignbtn")
		self.joinbtn = self.bottom:getChildByName("joinbtn")
		self.createbtn = self.bottom:getChildByName("createbtn")
		self.bottomtiptxt = self.bottom:getChildByName("bottomtiptxt")
		self.middletiptxt = self.middle:getChildByName("middletiptxt")
		self.txt_1 = self.middle:getChildByName("txt_1")
		self.txt_2 = self.middle:getChildByName("txt_2")
		self.txt_3 = self.middle:getChildByName("txt_3")
		self.txt_4 = self.middle:getChildByName("txt_4")
		self.txtInfo = self.middle:getChildByName("txtInfo")
		self.txtCountdown = display.newBMFontLabel({
			text = "",
			font = "ui/fnt/mb_num.fnt",
			x = 320,
			y = 245,
		})
		self.middle:addChild(self.txtCountdown, 1)

		local theight = 766
		self.det = display.height - 960
		if display.height > 960 then
			theight = theight + self.det
		end
		local size = self.panel:getLayoutSize()
		self.panel:setContentSize(cc.size(size.width,theight))
		size = self.bg:getContentSize()
		self.bg:setContentSize(cc.size(size.width,size.height + self.det))
		self:setView(self.panel)
		
		enableBtnOutLine(self.managerbtn,COMMON_BUTTONS.BLUE_BUTTON)
		enableBtnOutLine(self.cancelsignbtn,COMMON_BUTTONS.BLUE_BUTTON)
		enableBtnOutLine(self.joinbtn,COMMON_BUTTONS.BLUE_BUTTON)
		enableBtnOutLine(self.createbtn,COMMON_BUTTONS.ORANGE_BUTTON)
		self.managerbtn:addTouchEventListener(handler(self,self.onClick))
		self.cancelsignbtn:addTouchEventListener(handler(self,self.onClick))
		self.joinbtn:addTouchEventListener(handler(self,self.onClick))
		self.createbtn:addTouchEventListener(handler(self,self.onClick))
		self.helpbtn:addTouchEventListener(handler(self,self.onClick))
		btnClose:addTouchEventListener(handler(self,self.onClick))

		-- 根据配置设置提示信息
		local cfg = DataConfig:getAllConfigMsg()
		local pvp = DataConfig.data.cfg.system_simple.multiplayer_pvp
		
		local t1 = addArgsToMsg(cfg['20035'], pvp.fighting_time[1], pvp.fighting_time[2])
		local t2 = addArgsToMsg(cfg['20036'], pvp.lv_limit)
		local t3 = cfg['20037']
		self.tiptxt:setString(string.format('%s\n%s\n%s', t1, t2, t3))

		self.txt_1:setString(cfg['20046'])
		self.txt_3:setString(cfg['20047'])

		local date = os.date('*t')
		local weekday = date['wday'] - 1
		if weekday <= 0 then
			weekday = 7
		end

		local txt_2_eid = string.format('%s%02d', pvp.champion_gift.gem_color[weekday], pvp.champion_gift.leader.gem.lv)
		local txt_2_goods = DataConfig:getGoodByID(txt_2_eid)
		local txt_2_num = pvp.champion_gift.leader.gem.num
		self.txt_2:setString(addArgsToMsg(cfg['30070']..'*@2', txt_2_goods.name, txt_2_num))

		local txt_4_eid = string.format('%s%02d', pvp.champion_gift.gem_color[weekday], pvp.champion_gift.common.gem.lv)
		local txt_4_goods = DataConfig:getGoodByID(txt_4_eid)
		local txt_4_num = pvp.champion_gift.common.gem.num
		self.txt_4:setString(addArgsToMsg(cfg['30071']..'*@2', txt_4_goods.name, txt_4_num))

		self.managerbtn:setEnabled(false)
		self.cancelsignbtn:setEnabled(false)
		self.joinbtn:setEnabled(false)
		self.createbtn:setEnabled(false)
		self.bottomtiptxt:setEnabled(false)
		
		self.managerbtn:setVisible(false)
		self.cancelsignbtn:setVisible(false)
		self.joinbtn:setVisible(false)
		self.createbtn:setVisible(false)
		self.bottomtiptxt:setVisible(false)

		self.timer = scheduler.scheduleGlobal(handler(self,self.timeUpdate), 1)
	end

	self:addMidView(self.panel,true)
end
function MultiBattleProcessor:timeUpdate(dt)
	self:countdown()
end
function MultiBattleProcessor:countdown()
	--print('countdown: ', os.time())
	-- print('xxxxxxxxxxxxxxxxxxxxxxxxxxxxx', self.state)
	-- if not (self.data.is_open == 1 and (self.data.stage.sign == 1 or self.data.stage.sign == 2)) then
	if not (self.data.is_open == 1 and self.data.stage.sign == 1) then
		return
	end

	local countdown = changeTimeStrToSec(self.data.stage.time[2]['$datetime']) - (os.time() - self.timeDiff)

	-- 根据当前时间动态更改界面
	if self.data.is_open == 1 and self.data.stage.sign == 1 and countdown <= 0 then
		self.data.is_open = 1
		self.data.stage.sign = 2
		self:updateUI()
	end

	-- print('xxxxxxxxxx', countdown)
	local hour = math.floor(countdown / 3600)
	local min = math.floor(countdown % 3600 / 60)
	local sec = countdown % 60

	-- 这段备用
	-- if self.txtCountdown and tolua.isnull(self.txtCountdown) then
	-- 	scheduler.unscheduleGlobal(self.timer)
	-- 	self.timer = nil
	-- 	self.txtCountdown = nil
	-- end

	if self.txtCountdown then
		self.txtCountdown:setString(string.format('%02d:%02d:%02d', hour, min, sec))
	end
end
function MultiBattleProcessor:updateUI()
	self.managerbtn:setEnabled(false)
	self.cancelsignbtn:setEnabled(false)
	self.joinbtn:setEnabled(false)
	self.createbtn:setEnabled(false)
	-- self.bottomtiptxt:setEnabled(false)
	-- self.txtInfo:setEnabled(false)

	self.managerbtn:setVisible(false)
	self.cancelsignbtn:setVisible(false)
	self.joinbtn:setVisible(false)
	self.createbtn:setVisible(false)
	self.bottomtiptxt:setVisible(false)
	self.txtInfo:setVisible(false)
	self.txtCountdown:setVisible(false)

	local cfg = DataConfig:getAllConfigMsg()

	if self.data.is_open == 0 then -- 0,未开启
		self.txtInfo:setVisible(true)
		self.middletiptxt:setString(cfg['20049'])
		self.txtInfo:setString(addArgsToMsg(cfg['30076'], self.data.open_time['$datetime']))
		self.txtInfo:setFontSize(18)
		self.txtCountdown:setVisible(true)
	elseif self.data.is_open == 1 and self.data.stage.sign == 1 and self.data.stage.is_sign_up == 0 then -- 2，报名中，未报名
		self.joinbtn:setEnabled(true)
		self.createbtn:setEnabled(true)
		self.joinbtn:setVisible(true)
		self.createbtn:setVisible(true)
		self.txtCountdown:setVisible(true)
		self.middletiptxt:setString(cfg['20049'])
	elseif self.data.is_open == 1 and self.data.stage.sign == 1 and self.data.stage.is_sign_up == 1 and self.data.stage.is_leader == 0 then -- 3，报名中，已报名，非队长
		self.cancelsignbtn:setEnabled(true)
		self.bottomtiptxt:setEnabled(true)
		self.cancelsignbtn:setVisible(true)
		self.bottomtiptxt:setVisible(true)
		self.txtCountdown:setVisible(true)
		self.middletiptxt:setString(cfg['20049'])
		self.bottomtiptxt:setString(cfg['20053'])
	elseif self.data.is_open == 1 and self.data.stage.sign == 1 and self.data.stage.is_sign_up == 1 and self.data.stage.is_leader == 1 then -- 4，报名中，已报名，队长
		self.managerbtn:setEnabled(true)
		self.bottomtiptxt:setEnabled(true)
		self.managerbtn:setVisible(true)
		self.bottomtiptxt:setVisible(true)
		self.txtCountdown:setVisible(true)
		self.middletiptxt:setString(cfg['20049'])
		self.bottomtiptxt:setString(cfg['20033'])
	elseif self.data.is_open == 1 and self.data.stage.sign == 2 then -- 1，正在战斗中
		-- toastNotice(cfg['20048'], COLOR_GREEN)
		self.txtInfo:setVisible(true)
		local start_time = changeTimeStrToSec(self.data.stage.time[1]['$datetime'])
		local end_time = changeTimeStrToSec(self.data.stage.time[2]['$datetime'])
		local center_time = start_time + (end_time - start_time) / 2
		if os.time() < center_time then
			self.txtInfo:setString(cfg['20048'])
			self.txtInfo:setFontSize(30)
		else
			self.txtInfo:setString(cfg['20030'])
			self.txtInfo:setFontSize(18)
		end
		self.middletiptxt:setString(cfg['20048'])
		-- print('ddddd', os.time(), self.combat_begin_time)
		-- local n = math.ceil((os.time() - self.combat_begin_time) / 1200)
		-- self.txtInfo:setString(addArgsToMsg(cfg['30067'], n))
	elseif self.data.is_open == 1 and self.data.stage.sign == 3 then -- 1，不能报名时间
		self.txtInfo:setVisible(true)
		self.middletiptxt:setString(cfg['20054'])
		self.txtInfo:setString(cfg['20054'])
		self.txtInfo:setFontSize(18)
	end

	self:countdown()
end
function MultiBattleProcessor:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "managerbtn" then
		local net = {}
		net.method = MultiBattleModule.USER_LOOK_TEAM_INFO
		net.params = {}
		Net.sendhttp(net)
	elseif btnName == "cancelsignbtn" then
		local net = {}
		net.method = MultiBattleModule.USER_CANCEL_SIGN_UP
		net.params = {}
		Net.sendhttp(net)
	elseif btnName == "joinbtn" then
		local net = {}
		net.method = MultiBattleModule.USER_SIGN_UP_MULTIPLAYER_PVP
		net.params = {}
		net.params.is_leader = false
		Net.sendhttp(net)
	elseif btnName == "createbtn" then
		-- 检查钻石 提示信息
		local cfg = DataConfig:getAllConfigMsg()
		local pvp = DataConfig.data.cfg.system_simple.multiplayer_pvp
		local alert = GameAlert.new()

		if PlayerData:getCoin() < pvp.sign_up_coin then
			local btns = {{text = "取消",skin = 2},{text = "充值",skin = 3,callback = function()
				PopLayer:clearPopLayer()
				Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
			end}}
			richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
			alert:pop(richStr,"ui/titlenotice.png",btns)
			return
		end

		local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = function()
			local net = {}
			net.method = MultiBattleModule.USER_SIGN_UP_MULTIPLAYER_PVP
			net.params = {}
			net.params.is_leader = true
			Net.sendhttp(net)
		end, args = true}}
		alert:pop(addArgsToMsg(cfg["30075"],pvp.sign_up_coin),"ui/titlenotice.png",btns)
	elseif btnName == "helpbtn" then
		local alert = GameAlert.new()
		alert:popHelp('Martial_overlord')
	elseif btnName == "btnClose" then
		Observer.sendNotification(IndexModule.SHOW_INDEX,nil)
	end
end
function MultiBattleProcessor:setCombatBeginTime(time)
	self.combat_begin_time = changeTimeStrToSec(time)
	-- print('combat_begin_time :', self.combat_begin_time)
end
function MultiBattleProcessor:setSignUpTime(time)
	self.sign_up_time = changeTimeStrToSec(time)
	-- print('sign_up_time :', self.sign_up_time)
	self.startTime = self.sign_up_time
end
function MultiBattleProcessor:setBeginFightTime(time)
	self.begin_fight_time = changeTimeStrToSec(time)
	-- print('begin_fight_time :', self.begin_fight_time)
	self.startTime = self.begin_fight_time
end
function MultiBattleProcessor:setData(data)
	self.data = data

	-- sign 1 团战功能未开启 2 正在在战斗,不可报名 3 可以报名
	-- is_sign_up 0 没有报名 1 已经报名
	-- is_loader 0 不是队长 1 队长

	-- self.state 0,未开启1，报名已结束，正在战斗中2，报名中，未报名，3，报名中，已报名，非队长 4，报名中，已报名，队长

	DataConfig.data.mb = data

	-- if data.si_sign_up ~= nil then
	-- 	data.is_sign_up = data.si_sign_up
	-- end

	-- if data.sign == 1 then
	-- 	self.state = 0
	-- elseif data.sign == 2 then
	-- 	self.state = 1
	-- elseif data.sign == 3 and data.is_sign_up == 0 then
	-- 	self.state = 2
	-- elseif data.sign == 3 and data.is_sign_up == 1 and data.is_leader == 0 then
	-- 	self.state = 3
	-- elseif data.sign == 3 and data.is_sign_up == 1 and data.is_leader == 1 then
	-- 	self.state = 4
	-- end

	-- -- 报名开始时间
	-- if data.combat_begin_time then
	-- 	self:setCombatBeginTime(data.combat_begin_time['$datetime'])
	-- end

	-- -- 报名开始时间
	-- if data.sign_up_time then
	-- 	self:setSignUpTime(data.sign_up_time['$datetime'])
	-- end

	-- -- 战斗开始时间
	-- if data.begin_fight_time then
	-- 	self:setBeginFightTime(data.begin_fight_time['$datetime'])
	-- end
end
function MultiBattleProcessor:onHideView()
	self.super.onHideView(self)

	if self.timer ~= nil then
		print('MultiBattleProcessor:onHideView: scheduler.unscheduleGlobal')
		scheduler.unscheduleGlobal(self.timer)
		self.timer = nil
		self.txtCountdown = nil
	end
end
function MultiBattleProcessor:onExit()
	self.super.onExit(self)

	if self.timer ~= nil then
		print('MultiBattleProcessor:onHideView scheduler.unscheduleGlobal')
		scheduler.unscheduleGlobal(self.timer)
		self.timer = nil
		self.txtCountdown = nil
	end
end
return MultiBattleProcessor