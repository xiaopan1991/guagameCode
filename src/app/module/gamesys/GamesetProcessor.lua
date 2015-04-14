local GamesetProcessor = class("GamesetProcessor", BaseProcessor)

function GamesetProcessor:ctor()
	-- body
end

function GamesetProcessor:ListNotification()
	return {
		GamesysModule.SHOW_GAME_SET,
		GamesysModule.UPDATE_GAME_SET,
		GamesysModule.USER_GAME_SETTING,
	}
end

function GamesetProcessor:handleNotification(notify, data)
	if notify == GamesysModule.SHOW_GAME_SET then
		--显示游戏设置界面
		self:onSetView()
	elseif notify == GamesysModule.UPDATE_GAME_SET then
		if(self.view) then
			self:updateUI()
		end
	elseif notify == GamesysModule.USER_GAME_SETTING then
		--dump(data.data.data)
		GameInstance.setGameSetting(data.data.data)
		if self.flagsound == 1 then
			Audio:pause()
		else
			Audio:resume()
		end
		cc.UserDefault:getInstance():setIntegerForKey("soundstatus", self.flagsound)
		self:updateUI()
		notice("设置成功",COLOR_GREEN)
		Observer.sendNotification(IndexModule.SHOW_INDEX,nil)
		--self:addMidView(self.mapPanel,true)
		--self:removeMidView(self.view)
		--Observer.sendNotification(IndexModule.SHOW_INDEX,nil)
	end
		--self:onSetData(data.data)
end
function GamesetProcessor:updateUI()
	local checkBoxArr = {self.checkBox_1,self.checkBox_2,self.checkBox_3,self.checkBox_4}
	for i=1,4 do
		if(GameInstance.autosellcolor[i] == 1) then
			checkBoxArr[i]:setSelected(true)
		else
			checkBoxArr[i]:setSelected(false)
		end
	end
	if GameInstance.autoselljob == true then
    	self.checkBox_5:setSelected(true)
    else
    	self.checkBox_5:setSelected(false)
    end
    if GameInstance.closechat == true then
    	self.checkBox_6:setSelected(true)
    else
    	self.checkBox_6:setSelected(false)
    end
end
function GamesetProcessor:onSetView()
	if self.view ~= nil then
		return
	end
 	local gameset = ResourceManager:widgetFromJsonFile("ui/gamesetpanel.json")
 	gameset:setTouchEnabled(false) 	
 	local theight = 766
	self.det = display.height - 960
	if display.height > 960 then
		theight = 766 + self.det
	end
	local size = gameset:getLayoutSize()
	gameset:setContentSize(cc.size(size.width,theight))
	--local setui = gameset:getChildByName("setui")
	local Imabg = gameset:getChildByName("Imabg")
	local Imabgsize = Imabg:getLayoutSize()
	Imabg:setContentSize(cc.size(Imabgsize.width,Imabgsize.height + self.det))
	local bigbg = gameset:getChildByName("bigbg")
	local bigbgsize = bigbg:getLayoutSize()
	bigbg:setContentSize(cc.size(bigbgsize.width,bigbgsize.height + self.det))
	local btnCancelset = gameset:getChildByName("btnCancelset")--取消设置
	local btnKeepset = gameset:getChildByName("btnKeepset")    --保存设置
	local btninfo = gameset:getChildByName("btninfo")          --信息
	local btnhelp = gameset:getChildByName("btnhelp")          --帮助
	local btnadvice = gameset:getChildByName("btnadvice")      --意见
	local btncancel = gameset:getChildByName("btncancel")      --注销
	local btnChangePwd = gameset:getChildByName("btnChangePwd")--修改密码

	
	local title = btnKeepset:getTitleText()
	btnKeepset:setTitleText('')
	btnKeepset:setTitleText(title)


	enableBtnOutLine(btnKeepset,COMMON_BUTTONS.ORANGE_BUTTON)
	enableBtnOutLine(btnCancelset,COMMON_BUTTONS.BLUE_BUTTON)


	--装备勾选
	self.checkBox_1 = gameset:getChildByName("CheckBox_1")
	self.checkBox_2 = gameset:getChildByName("CheckBox_2")
	self.checkBox_3 = gameset:getChildByName("CheckBox_3")
	self.checkBox_4 = gameset:getChildByName("CheckBox_4")
	self.checkBox_5 = gameset:getChildByName("CheckBox_5")
	self.checkBox_6 = gameset:getChildByName("CheckBox_6")
	self.checkBox_7 = gameset:getChildByName("CheckBox_7")
    --按钮点击
	btnCancelset:addTouchEventListener(handler(self,self.ongamesetClick))
	btnKeepset:addTouchEventListener(handler(self,self.ongamesetClick))
	btninfo:addTouchEventListener(handler(self,self.ongamesetClick))
	btnhelp:addTouchEventListener(handler(self,self.ongamesetClick))
	btnadvice:addTouchEventListener(handler(self,self.ongamesetClick))
	btncancel:addTouchEventListener(handler(self,self.ongamesetClick))
	btnChangePwd:addTouchEventListener(handler(self,self.ongamesetClick))
	--复选框事件
	self.checkBox_1:addEventListener(handler(self,self.checkClick))
	self.checkBox_2:addEventListener(handler(self,self.checkClick))
	self.checkBox_3:addEventListener(handler(self,self.checkClick))
	self.checkBox_4:addEventListener(handler(self,self.checkClick))
	self.checkBox_5:addEventListener(handler(self,self.checkClick))
	self.checkBox_6:addEventListener(handler(self,self.checkClick))
	self.checkBox_7:addEventListener(handler(self,self.checkClick))
	self:setView(gameset)

	self:updateUI()
	self:addMidView(self.view,true)
	local flog = cc.UserDefault:getInstance():getIntegerForKey("soundstatus",0)
	self.checkBox_7:setSelected(flog == 1)


	self:updateNotice()
end
function GamesetProcessor:updateNotice()
	self.notice = nil
	local key = PlayerData:getUid()..PlayerData:getZone().."firstPersonInfo"
    if(cc.UserDefault:getInstance():getIntegerForKey(key,0) == 0) then
    	local spr
		local frames
		local animation
		local tempX
		local tempY
    	display.addSpriteFrames("ui/new.plist","ui/new.png")
		frames = display.newFrames("xin%04d.png", 1,7)
		animation = display.newAnimation(frames, 0.5 / 7) -- 0.5 秒播放 10桢
		spr = display.newSprite()
		spr:playAnimationForever(animation)
		local node = ccui.Layout:create()
		local relarg = ccui.RelativeLayoutParameter:create()

		relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		local margin = {}
		margin.top = 570
		margin.left = 178
		relarg:setMargin(margin)
		node:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))
		node:addChild(spr)
		self.view:addChild(node,3)
		self.notice = node
    end
end
--数据
function GamesetProcessor:onSetData(data)	
end
--按钮事件的处理
function GamesetProcessor:ongamesetClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnCancelset" then
		--self:removeMidView(self.view)
		Observer.sendNotification(IndexModule.SHOW_INDEX,nil)	
	elseif btnName == "btnKeepset" then
		local tempArr = {}
		local checkBoxArr = {self.checkBox_1,self.checkBox_2,self.checkBox_3,self.checkBox_4}
		for i=1,4 do
			if(checkBoxArr[i]:isSelected()) then
				tempArr[i] = 1
			else
				tempArr[i] = 0
			end
		end
		if(self.checkBox_5:isSelected()) then
			tempArr[5] = 1
		else
			tempArr[5] = 0
		end
		if(self.checkBox_6:isSelected()) then
			tempArr[6] = 1
		else
			tempArr[6] = 0
		end
		if(self.checkBox_7:isSelected()) then
			self.flagsound = 1
		else
			self.flagsound = 0
		end
		--发送
		local net = {}
		net.method = GamesysModule.USER_GAME_SETTING
		net.params = {}
		net.params.data = tempArr
		Net.sendhttp(net)
	elseif btnName == "btninfo" then
		-- self:removePopView(self.view)
		Observer.sendNotification(GamesysModule.SHOW_PERSON_INFO)
		if(self.notice) then
			local key = PlayerData:getUid()..PlayerData:getZone().."firstPersonInfo"
			cc.UserDefault:getInstance():setIntegerForKey(key,1)
			self.notice:removeFromParent()
			self.notice = nil
			local alert = GameAlert.new()
			alert:popHelp("personal_prompt","ui/gamehelp.png")
		end
	elseif btnName == "btnhelp" then
		--todo
		local alert = GameAlert.new()
		--alert:popHelp("game_set","游戏帮助")
		alert:popHelp("game_set","ui/gamehelp.png")
	elseif btnName == "btnadvice" then
		local cfg = DataConfig:getAllConfigMsg()
		local str = cfg["20018"]
		local btns = {{text = "确定",skin = 3,}}
		local alert = GameAlert.new()
		alert:pop(str,"ui/titlenotice.png",btns)
	elseif btnName == "btncancel" then
		local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendGotoLogin)},}
		local alert = GameAlert.new()
		alert:pop({{text = "将返回至登录界面"}},"ui/titlenotice.png",btns)
	elseif btnName == "btnChangePwd" then
		Observer.sendNotification(GamesysModule.SHOW_CHANGE_PWD)
	end	

end
--复选框事件
function GamesetProcessor:checkClick(sender,eventType)
end
function GamesetProcessor:sendGotoLogin()
	TimeManager:stop()
    GameInstance.relogin = true
    GameInstance.closechat = nil
    local scene = require("app.scenes.LoginScene").new()
    LoadingBall.hide()
    display.replaceScene(scene)
end
--移除界面
function GamesetProcessor:onHideView(view)
	if self.view ~= nill then
		self.view:removeFromParent(true)
		self.view = nil
	end
end
return GamesetProcessor

