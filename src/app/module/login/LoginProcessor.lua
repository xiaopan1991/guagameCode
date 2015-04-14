--登录处理器
local LoginProcessor = class("LoginProcessor", BaseProcessor)
local ItemFace = require("app.components.ItemFace")
local ServerItem = import(".ui.ServerItem")
local UIEditBox = import("app.components.UIEditBox")

function LoginProcessor:ctor()
	self.loginView = nil
	self.serverView = nil
end

--消息列表
function LoginProcessor:ListNotification()
	return {
		LoginModule.SHOW_LOGINVIEW,
		LoginModule.SHOW_SERVERLISTVIEW,
		LoginModule.USER_LOGIN,
		LoginModule.USER_REGISTER,
		LoginModule.JSON_LOAD_COMPLETED
	}
end

--消息处理
function LoginProcessor:handleNotification(notify, data)
	if notify == LoginModule.SHOW_LOGINVIEW then 
		if self.view ~= nil and self.loginView ~= nil and self.view:getName() == self.loginView:getName() then
			return
		end
		self:onSetView()
	elseif notify == LoginModule.USER_LOGIN  then
		--登录
		self:handleLoginData(data.data)
	elseif notify == LoginModule.USER_REGISTER  then
		--用户注册返回
		self:handleRegisterData(data.data)
	elseif notify == LoginModule.JSON_LOAD_COMPLETED then
		scheduler.performWithDelayGlobal(function() self:afterDo() end, 0.1)
	end
end

--初始化登录界面
function LoginProcessor:onSetView(view)
	local view = nil
 --    print(tolua.isnull(self.loginView))
 --    local isnew = true
	if self.loginView == nil or tolua.isnull(self.loginView) then
		view = ResourceManager:widgetFromJsonFile("ui/login.json")
	    self.loginView = view
        --isnew = false
	end
	view = self.loginView
	self.cfg = DataConfig:getAllConfigMsg()
	--登录界面
	local btnLogin = view:getChildByName("btnLogin")
	local btnRegister = view:getChildByName("btnRegister")
	btnLogin:addTouchEventListener(handler(self,self.onLoginViewBtnClick))
	btnRegister:addTouchEventListener(handler(self,self.onLoginViewBtnClick))

	local scrollViewId = view:getChildByName("scrollViewId")
	local scrollViewPwd = view:getChildByName("scrollViewPwd")

	self.lbZone = view:getChildByName("lbfenqu")    --分区label
	self.btnZone = view:getChildByName("btnZone")  --分区按钮
	self.btnZone:addTouchEventListener(handler(self,self.showZone))
	
	--显示分区
	local js = cc.UserDefault:getInstance():getStringForKey("zoneid")
	if js and js ~= "" then
		self.zoneData = json.decode(js)
	else
		-- [{"tw":"均衡教統 2","cn":"均衡教统 2"},{"$datetime":"2015-07-02 14:00:00.000000"},1,"2013-11-08"]
		local zoneDatas = DataConfig:getZones()
		self.zoneData = nil
		for k,v in pairs(zoneDatas) do
			if(not self.zoneData) then
				v[5] = k
				self.zoneData = v				
			else
				if(self.zoneData[2]["$datetime"] > v[2]["$datetime"]) then
					v[5] = k
					self.zoneData = v					
				end
			end
		end
		js = json.encode(self.zoneData)
		cc.UserDefault:getInstance():setStringForKey("zoneid",js)
	end
	if self.zoneData then
		self.lbZone:setString(self.zoneData[1].cn)
	else
		self.lbZone:setString("请选择分区！")
	end

    --if not isnew then
	    --账号和密码输入框
		local txtAccount = ccui.EditBox:create(cc.size(280,46), "ui/blank.png")
        txtAccount:setContentSize(cc.size(280,46))
	    txtAccount:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	    txtAccount:setFontSize(18)
	    txtAccount:setFontColor(cc.c3b(255,240,1))
	    txtAccount:setFontName(DEFAULT_FONT)
	    --txtAccount:setPosition(307,200)
	    txtAccount:setPosition(0,0)
		txtAccount:setAnchorPoint(0,0)
	    txtAccount:setPlaceHolder("请输入账号")
	    txtAccount:setPlaceholderFont(DEFAULT_FONT,18)
	    txtAccount:setMaxLength(20)
	    scrollViewId:addChild(txtAccount)
	    self.txtAccount = txtAccount

	    local txtPwd = ccui.EditBox:create(cc.size(280,46), "ui/blank.png")
	    txtPwd:setContentSize(cc.size(280,46))
	    txtPwd:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	    txtPwd:setFontSize(18)
	    txtPwd:setFontColor(cc.c3b(255,240,1))
	    txtPwd:setFontName(DEFAULT_FONT)
	    --txtPwd:setPosition(307,136)
	    txtPwd:setPosition(0,0)
		txtPwd:setAnchorPoint(0,0)
	    txtPwd:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
	    txtPwd:setPlaceHolder("输入密码")
	    txtPwd:setPlaceholderFont(DEFAULT_FONT,18)
	    txtPwd:setMaxLength(16)
	    scrollViewPwd:addChild(txtPwd)
	    self.txtPwd = txtPwd
	    

	    -- 默认用户密码 方便调试
		local account_encoding = cc.UserDefault:getInstance():getStringForKey("account")
		local account = json.decode(account_encoding)
		if account_encoding ~= "" and account ~= nil then
			self.txtAccount:setText(account.username)
			self.txtPwd:setText(account.password)
		end
    --end

	local size = view:getContentSize()

	GameInstance.loginScene:addMidView(view)
	view:setPosition(display.cx - size.width/2,display.cy-size.height/2 - 30)
	self.view = self.loginView
	self.view.processor = self
end

function LoginProcessor:onLoginViewBtnClick(sender,eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end
    
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnLogin" then
		print(btnName)
		-- App:enterScene("MainScene")
		-- 
		--local btns = {{text = "取消",skin = 2,callback = function () print("取消按钮") end},{text = "确定",skin = 1,callback = function () print("确定按钮") end},}
		--local alert = GameAlert.new()
		--alert:pop({{text = "获得奖励：精铁指环 *1 平安符 *1 葛布青裤 *眉刺 *1 宽蔽体 *1 镶玉腰牌 *1 手中竹 *1 "},},"ui/titlenotice.png",btns)

		--if true then
		--	return
		--end
		-- self.web = XWebView.new()
		-- self.web:open("http://192.168.1.114:9999/notice/")

		-- LoadingBall.hide()
		-- LoadingBall.show()
		-- if true then
		-- 	return
		-- end
		local id = self.txtAccount:getText()
		local pwd = self.txtPwd:getText()
		local len = string.utf8len(pwd)
		local len1 = string.utf8len(id)
		if id == "" or pwd == ""then
			local str = addArgsToMsg(self.cfg["10200"])
			toastNotice(str)
			return
			--不能删
		-- elseif id:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") == nil and  id:match("^[1]%d%d%d%d%d%d%d%d%d%d$") == nil then
		-- 	--notice("正确格式为邮箱地址或手机号，请重新输入！")
		--  local str = addArgsToMsg(self.cfg["10202"])
		-- 	toastNotice(str)
		-- 	return
		elseif pwd:match("^[0-9a-zA-Z]+$") == nil then
			--notice("密码格式为数字或字母，请重新输入！")
		 	local str = addArgsToMsg(self.cfg["10192"])
			toastNotice(str)
			return
		elseif len < 6 then
			--notice("密码格式为3位~15位非特殊字符，请重新输入！")
		 	local str = addArgsToMsg(self.cfg["10050"])
			toastNotice(str)
			return--本地测试需要
		elseif len1 < 6 then
		 	local str = addArgsToMsg(self.cfg["10050"])
			toastNotice(str)	
			return
		end
		
		local data = {}
		data.method = LoginModule.USER_LOGIN
		data.params = {}
		data.app_version = "5.0.0"
		data.cfg_version = "20148114542"
		data.params.pf = PF_CONFIG
		data.params.session_key = id
		data.params.sessionid = pwd
		if self.zoneData then
			data.params.zone = self.zoneData[5]
		else
			local str = addArgsToMsg(self.cfg["20058"])
			toastNotice(str)
			return
            --data.params.zone ="1-01"
		end
		-- 默认账号密码 方便调试
		local account = {username=id, password=pwd}
		cc.UserDefault:getInstance():setStringForKey("account", json.encode(account))
		
		print("self.zoneData[5]=",self.zoneData[5])
		Net.sendhttp(data)
		
	elseif btnName == "btnRegister" then
		self.loginView:retain()
		local viewReg = ccs.GUIReader:getInstance():widgetFromJsonFile("ui/register.json")
		self.viewReg = viewReg
		local btnSureRegister = viewReg:getChildByName("btnSureRegister")
		local btnRegisterReturn = viewReg:getChildByName("btnRegisterReturn")
		btnSureRegister:addTouchEventListener(handler(self,self.onRegisterBtnClick))
		btnRegisterReturn:addTouchEventListener(handler(self,self.onRegisterBtnClick))

		local reScrollViewId = viewReg:getChildByName("reScrollViewId")
		local reScrollViewPwd = viewReg:getChildByName("reScrollViewPwd")

	-- 	if self.registerView == nil or tolua.isnull(self.registerView) then
	-- 		--todo
	-- 		local regView = ccs.GUIReader:getInstance():widgetFromJsonFile("ui/login.json")
	-- 		regView:setName("registerpanel")
	-- 		local panel = regView:getChildByName("panel")
	-- 		local state = regView:getChildByName("state")
	-- 		local txtTitle = panel:getChildByName("txtLable")

 --            local lbZone = panel:getChildByName("lbfenqu")    --分区label
	--         local btnZone = panel:getChildByName("btnZone")  --分区按钮
 --            local lbfenqutitle = panel:getChildByName("lbfenqutitle")  --
 --            local bgfenqu = panel:getChildByName("bgfenqu")  --
            
 --            lbZone:setEnabled(false)
 --            btnZone:setEnabled(false)
 --            btnZone:setEnabled(false)
 --            lbfenqutitle:setEnabled(false)
 --            bgfenqu:setEnabled(false)
 --            lbZone:setVisible(false)
 --            btnZone:setVisible(false)
 --            btnZone:setVisible(false)
 --            lbfenqutitle:setVisible(false)
 --            bgfenqu:setVisible(false)
	-- 		txtTitle:setString("账号注册")

			--local txtAccount = UIEditBox.new(364,46)
			local txtAccountReg = ccui.EditBox:create(cc.size(280,46), "ui/blank.png")
			txtAccountReg:setContentSize(cc.size(280,46))
			txtAccountReg:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
			txtAccountReg:setFontSize(18)
			txtAccountReg:setFontColor(cc.c3b(255,240,1))
			txtAccountReg:setFontName(DEFAULT_FONT)
			--txtAccountReg:setPosition(307,190)
			txtAccountReg:setPosition(0,0)
			txtAccountReg:setAnchorPoint(0,0)
			txtAccountReg:setPlaceHolder("请输入账号")
			txtAccountReg:setPlaceholderFont(DEFAULT_FONT,18)
			txtAccountReg:setMaxLength(20)
			reScrollViewId:addChild(txtAccountReg,5)
			self.txtAccountReg = txtAccountReg

			-- -- local txtPwd = UIEditBox.new(364,46)
			local txtPwdReg = ccui.EditBox:create(cc.size(280,46), "ui/blank.png")
			txtPwdReg:setContentSize(cc.size(280,46))
			txtPwdReg:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
			txtPwdReg:setFontSize(18)
			txtPwdReg:setFontColor(cc.c3b(255,240,1))
			txtPwdReg:setFontName(DEFAULT_FONT)
			--txtPwdReg:setPosition(307,125)
			txtPwdReg:setPosition(0,0)
			txtPwdReg:setAnchorPoint(0,0)
			txtPwdReg:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
			txtPwdReg:setPlaceHolder("输入密码")
			txtPwdReg:setPlaceholderFont(DEFAULT_FONT,18)
			txtPwdReg:setMaxLength(16)
			reScrollViewPwd:addChild(txtPwdReg,5)
			self.txtPwdReg = txtPwdReg


	-- 	if self.loginView ~= nil then
	-- 		self.loginView:retain()
	-- 	end
		GameInstance.loginScene:addMidView(viewReg)
		self:setView(viewReg)
		local size = viewReg:getContentSize()
		viewReg:setPosition(display.cx - size.width/2,display.cy-size.height/2 + 14)
	end
end

--注册界面按钮处理
function LoginProcessor:onRegisterBtnClick(sender,eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnSureRegister" then
		local id = self.txtAccountReg:getText()
		local pwd = self.txtPwdReg:getText()
		local len = string.utf8len(pwd)
		local len1 = string.utf8len(id)

		if id == "" or pwd == ""then
			local str = addArgsToMsg(self.cfg["10200"])
			toastNotice(str)
			--notice("账号或密码不能为空，请重新输入",COLOR_GREEN)
			return
			--不能删
		-- elseif id:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") == nil and  id:match("^[1]%d%d%d%d%d%d%d%d%d%d$") == nil then
		-- 	--notice("正确格式为邮箱地址或手机号，请重新输入！")
		--  local str = addArgsToMsg(self.cfg["10202"])
		-- 	toastNotice(str)
		-- 	return
		elseif pwd:match("^[0-9a-zA-Z]+$") == nil then
			--notice("密码格式为数字或字母，请重新输入！")
		 	local str = addArgsToMsg(self.cfg["10192"])
			toastNotice(str)
			return
		elseif len < 6 then
			--notice("密码格式为3位~15位非特殊字符，请重新输入！")
		 	local str = addArgsToMsg(self.cfg["10050"])
			toastNotice(str)
			return
		elseif len1 < 6 then
		 	local str = addArgsToMsg(self.cfg["10050"])
			toastNotice(str)	
			return
		end


		local data = {}
		data.method = LoginModule.USER_REGISTER
		data.params = {}
		data.app_version = "5.0.0"
		data.cfg_version = "20148114542"
		data.params.pf = PF_CONFIG
		data.params.session_key = id
		data.params.sessionid = pwd
		Net.sendhttp(data)
	elseif btnName == "btnRegisterReturn" then
		self.viewReg:retain()
		GameInstance.loginScene:addMidView(self.loginView)
		self:setView(self.loginView)
	end
end
--选区按钮点击处理
--弹出分区列表
function LoginProcessor:showZone(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local zonelist = ResourceManager:widgetFromJsonFile("ui/serverlist.json")
	local lbcurserver = zonelist:getChildByName("lbcurserver")
	-- local btnClose = zonelist:getChildByName("btnClose")
	local btnTiao = zonelist:getChildByName("btnTiao")
	btnTiao:addTouchEventListener(handler(self,self.onZonelistBtnClick))
	if self.zoneData then
		lbcurserver:setString(self.zoneData[1].cn)
	else
		lbcurserver:setString("")
	end
	self.zoneview = zonelist
	GameInstance.loginScene:addMidView(self.zoneview)
	self:setView(self.zoneview)
	local size = self.zoneview:getContentSize()
	self.zoneview:setPosition(display.cx - size.width/2,display.cy-size.height/2 - 132)

	local list = zonelist:getChildByName("slist")

	local zoneData = DataConfig:getZones()
	local item = nil
	local index = 0
	local itemheight = 55
	local allheight = 0
	local ystart = 0
	--排序 计算各个item的位置 计算滑动区域
	local tempZoneData = {}
	local now = os.time()
	local index = 0
	for kk,vv in pairs(zoneData) do
		if now > changeTimeStrToSec(vv[2]["$datetime"]) then
			vv[5] = kk
			tempZoneData[#tempZoneData + 1] = vv
			index = index + 1
		end
	end

	local listsize = list:getInnerContainerSize()
	allheight = table.nums(tempZoneData) * itemheight
	local minHeight = list:getContentSize().height
	ystart = math.max(allheight,minHeight)
	list:setInnerContainerSize(cc.size(listsize.width,ystart))
    --排序
	table.sort(tempZoneData,function(a,b)
			if a[3] >= b[3] then
				return false
			else
				return true
			end
		end)
	-- dump(tempZoneData)
	for k,v in pairs(tempZoneData) do
		item = ServerItem.new()
		item:setData(v)
		ystart = ystart - itemheight
		-- allheight = allheight - itemheight
		print("ystart:"..ystart)
		item:setPosition(0,ystart)
		item:addEventListener(ServerItem.ZONE_CLICK, handler(self,self.onServerListClick))
		list:addChild(item)
	end
end

--分区列表 点击处理
function LoginProcessor:onServerListClick(event)
	local js = json.encode(event.data)
	cc.UserDefault:getInstance():setStringForKey("zoneid",js)
	self.zoneData = event.data
	self:onSetView()
end
--分区列表 关闭
function LoginProcessor:onZonelistBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	self:onSetView()
end
function LoginProcessor:handleLoginData(data)
	print("登录返回数据处理")
	--dump(data,"登录返回数据处理",999)
	---1、登录返回return_code==0 的话 登录成功
	--把数据放到本地的存储结构里
	--进入主界面
	---2、name 玩家昵称如果为空的话 则进入创建角色界面
	if data.return_code == 0 then
		local node = display.newNode()
		node.data = {}
		node.data.per = 0
		node.data.info = "初始化数据"
		--
		Observer.sendNotification(LoginModule.SHOW_LOGIN_LOADING,node)

		--处理登录数据 
		PlayerData:setData(data.data) --玩家的基本信息
		--种子
		GameInstance.getSeedFromServer(data.data.attrs.hang.seed)
		--玩家设置
		GameInstance.setGameSetting(data.data.attrs.game_setting)
		--从服务器得到当前地图
		Raid:changePlayRaid(data.data.attrs.hang.mid)
		--从服务器得到下一幅地图
		Raid:changeNextRaid(data.data.attrs.hang.next_mid)
		
		--从服务器得到当前最大开放地图
		Raid:changeMaxRaid(data.data.attrs.hang.max_mid)
		Raid:changeSaoDangRaid(data.data.attrs.hang.beat_mid)
		--从服务器得到当前boss挑战次数
		BossPvpBattleManager:setBossChargeTimes(data.data.records.BOSS_count)
		--从服务器得到当前已购买boss挑战次数
		BossPvpBattleManager:setBossChargeBuyTimes(data.data.records.challenge_BOSS_count)
		--从服务器得到当前pvp挑战次数
		BossPvpBattleManager:setPVPChargeTimes(data.data.records.PVP_count)
		--从服务器得到当前已购买pvp挑战次数
		BossPvpBattleManager:setPVPChargeBuyTimes(data.data.records.challenge_PVP_count)
		--从服务器得到当前挂机掉落装备id号
		GameInstance.setHangEquipNum(data.data.attrs.hang_equip_num)



		--今日已快速战斗次数
		PlayerData:setQuickBattles(tonumber(data.data.records.fighting_count))
		
		Bag:setData(data)

		local node1 = display.newNode()
		node1.data = {}
		node1.data.per = 10
		node1.data.info = "初始化数据"
		Observer.sendNotification(LoginModule.UPDATE_LOGIN_LOADING,node1)

        if self.registerView ~= nil and (not tolua.isnull(self.registerView))then
            self.registerView:release()
        end
        if self.loginView ~= nil and (not tolua.isnull(self.loginView))then
            self.loginView:release()
        end
		--延迟一下执行
		-- self:afterDo(data)
		scheduler.performWithDelayGlobal(function() ResourceManager:preLoadJson() end, 0.3)
		
	else
		print("登录失败")
		-- dump(data)
		notice(data.data.msg)
	end
end

function LoginProcessor:afterDo(data)
	--dump(data,nil,999)
	--ItemFace.initPool()
	ItemFace.initPool(20)
	local node3 = display.newNode()
	node3.data = {}
	node3.data.per = 98
	node3.data.info = "初始化数据"
	Observer.sendNotification(LoginModule.UPDATE_LOGIN_LOADING,node3)
	scheduler.performWithDelayGlobal(function() self:afterDo2() end, 0.3)
end

function LoginProcessor:afterDo2()
	local node4 = display.newNode()
	node4.data = {}
	node4.data.per = 99
	node4.data.info = "初始化数据"
	Observer.sendNotification(LoginModule.UPDATE_LOGIN_LOADING,node4)

	-- PlayerData:calcAttributes()
	if PlayerData:getPlayerName() == nil then
		-- if self.stateview ~= nil then
		-- 	self.stateview:removeFromParent()
		-- end
		--创建角色
		GameInstance.loginScene.gua:setVisible(false)
		Observer.sendNotification(LoginModule.SHOW_CREAT_ROLE_VIEW, nil)
	else
		--进主场景
		--计算玩家属性
		PlayerData:calcAttributes()
		--计算所有佣兵属性
		PlayerData:updateAllSolidersAttrs()
		App:enterScene("MainScene")
		--背景声音
		Audio:stopMusic()
		Audio:playMusic("sound/backSound.mp3",true)
		local flag = cc.UserDefault:getInstance():getIntegerForKey("soundstatus",0)
		if flag == 1 then
			Audio:pause()
		end
		
	end
end

--处理注册返回数据
function LoginProcessor:handleRegisterData(data)
	--注册return_code ==0 的话 注册成功
	notice("注册成功！",COLOR_GREEN)
	local pwd = data.params.sessionid
	local key = data.params.session_key
	local account = {username=key, password=pwd}
	cc.UserDefault:getInstance():setStringForKey("account", json.encode(account))

	self.txtAccount:setText(key)
	self.txtPwd:setText(pwd)

	self.viewReg:retain()
	GameInstance.loginScene:addMidView(self.loginView)
	self:setView(self.loginView)
end

return LoginProcessor