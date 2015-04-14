local ChangePwdProcessor = class("ChangePwdProcessor", BaseProcessor)
local UIEditBox = import("app.components.UIEditBox")

function ChangePwdProcessor:ctor()
end

function ChangePwdProcessor:ListNotification()
	return {
		GamesysModule.SHOW_CHANGE_PWD,
		GamesysModule.USER_CHANGE_PASSWORD
	
	}
end

function ChangePwdProcessor:handleNotification(notify, data)
	if notify == GamesysModule.SHOW_CHANGE_PWD then
		self:onSetView()
		self:onSetData()
	elseif notify == GamesysModule.USER_CHANGE_PASSWORD then
		self:onChangeData(data.data)
	end
end

function ChangePwdProcessor:onSetView()
	if self.view ~= nil then
		return
	end

 	local changepwdpanel = ResourceManager:widgetFromJsonFile("ui/changepwd.json")

 	local txtInfo = changepwdpanel:getChildByName("txtInfo")
 	txtInfo:setString("")
 	self.txtInfo = txtInfo
 	local btnOk = changepwdpanel:getChildByName("btnOk")
	local btnCancle = changepwdpanel:getChildByName("btnCancle")
	btnOk:addTouchEventListener(handler(self,self.onbtnClick))
	btnCancle:addTouchEventListener(handler(self,self.onbtnClick))

	enableBtnOutLine(btnOk,COMMON_BUTTONS.ORANGE_BUTTON)

	local txtcurPwd = ccui.EditBox:create(cc.size(430,46), "ui/blank.png")
    txtcurPwd:setContentSize(cc.size(430,46))
    txtcurPwd:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    txtcurPwd:setFontSize(18)
    txtcurPwd:setFontColor(cc.c3b(255,240,1))
    txtcurPwd:setFontName(DEFAULT_FONT)
    txtcurPwd:setPosition(367,185)
    txtcurPwd:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    txtcurPwd:setPlaceHolder("请输入旧密码")
    txtcurPwd:setPlaceholderFont(DEFAULT_FONT,18)
    txtcurPwd:setMaxLength(16)
    changepwdpanel:addChild(txtcurPwd,5)
    self.txtcurPwd = txtcurPwd



	local txtnewPwd = ccui.EditBox:create(cc.size(430,46), "ui/blank.png")
    txtnewPwd:setContentSize(cc.size(430,46))
    txtnewPwd:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    txtnewPwd:setFontSize(18)
    txtnewPwd:setFontColor(cc.c3b(255,240,1))
    txtnewPwd:setFontName(DEFAULT_FONT)
    txtnewPwd:setPosition(367,134)
    txtnewPwd:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    txtnewPwd:setPlaceHolder("请输入新密码")
    txtnewPwd:setPlaceholderFont(DEFAULT_FONT,18)
    txtnewPwd:setMaxLength(16)
    changepwdpanel:addChild(txtnewPwd,5)
    self.txtnewPwd = txtnewPwd

    self.cfg = DataConfig:getAllConfigMsg()
	
	self:addPopView(changepwdpanel)
	self:setView(changepwdpanel)

end
--数据
function ChangePwdProcessor:onSetData()
	local str = addArgsToMsg(self.cfg["20057"])
	self.txtInfo:setString(str)

	local account_encoding = cc.UserDefault:getInstance():getStringForKey("account")
	local account = json.decode(account_encoding)
	self.pwd = account.password
	self.id =account.username

  
end
--按钮事件的处理
function ChangePwdProcessor:onbtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnOk" then
		local curpwd = self.txtcurPwd:getText()
		local newpwd = self.txtnewPwd:getText()
		local len = string.utf8len(newpwd)
		if curpwd == "" or newpwd == "" then
			local str = addArgsToMsg(self.cfg["10199"])
			toastNotice(str)
			return
		elseif curpwd ~= self.pwd then
			local str = addArgsToMsg(self.cfg["10191"])
			toastNotice(str)
			return
		elseif newpwd:match("^[0-9a-zA-Z]+$") == nil then 
			local str = addArgsToMsg(self.cfg["10192"])
			toastNotice(str)
			return
		elseif len < 6  then
		 	local str = addArgsToMsg(self.cfg["10193"])
			toastNotice(str)
			return
		elseif curpwd == newpwd then 
			local str = addArgsToMsg(self.cfg["10198"])
			toastNotice(str)
			return
		end
		local data = {}
		data.method = GamesysModule.USER_CHANGE_PASSWORD
		data.params = {}
		data.params.session_key = self.id
		data.params.sessionid = self.pwd
		data.params.new_sessionid = newpwd
		data.params.pf = PF_CONFIG 
		Net.sendhttp(data)
		
	elseif btnName == "btnCancle" then
		self:removePopView(self.view)
	end
end
--更改密码数据回来
function ChangePwdProcessor:onChangeData(data)
	if data.data == true then
		toastNotice("修改成功",COLOR_GREEN)
		local id =  data.params.session_key
		local newpwd = data.params.new_sessionid
		local account = {username = id, password = newpwd}
		cc.UserDefault:getInstance():setStringForKey("account", json.encode(account))
	end
	self:removePopView(self.view)
end 
return ChangePwdProcessor

