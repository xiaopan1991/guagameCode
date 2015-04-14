local ChatProcessor = class("ChatProcessor", BaseProcessor)
local XRichText = import("app.components.XRichText")
local DirtyWordsTools = import("app.utils.DirtyWordsTools")
local UIEditBox = import("app.components.UIEditBox")
local NameItem = require("app.module.gamesys.ui.NameItem")
function ChatProcessor:ctor()
	self.keepChatNum = 100--只保留这些数目的记录，其他删除
	self.bCanSend = false
	self.uivisible = false
	self.lastSendTime = nil
end
function ChatProcessor:ListNotification()
	return {
		ChatModule.SHOW_CHAT,
		ChatModule.ADD_CHAT_MESSAGE,
		ChatModule.CHAT_CONNECTED,
		ChatModule.CHAT_HAS_SEND_LOGIN,
		ChatModule.CHAT_CLOSED,
		ChatModule.CHAT_RECONNECT,
		ChatModule.CHAT_UPDATE_STATE,
		ChatModule.USER_CHAT_RECORD,
		}
end
function ChatProcessor:handleNotification(notify, data)
	if notify == ChatModule.SHOW_CHAT then
		if(not self.uivisible) then
			self:initUI()
		end
	elseif notify == ChatModule.USER_CHAT_RECORD then
		local record = data.data.data.record.chat_zone
		local bSelf
		for i,v in ipairs(record) do
			local temp = changeSecToTimeStr(v.t)
			temp = string.split(temp, ".")
			temp = string.split(temp[1], " ")
			bSelf = (v.uid == PlayerData:getUid())
			self:updateChatInfo(v.s,v.name,v.title,bSelf,temp[2])
		end
		if(self.uivisible == false) then
			Observer.sendNotification(IndexModule.CHAT_NOTICE)
		end
	elseif notify == ChatModule.ADD_CHAT_MESSAGE then
		if(data.data.info.method == "login") then
			self:updateChatInfo("服务器已连接...")
			self.bCanSend = true
			self:updateCanSend()
			Observer.sendNotification(ChatModule.CHAT_HAS_SEND_LOGIN)
			local net = {}
			net.method = ChatModule.USER_CHAT_RECORD
			net.params = {}
			Net.sendhttp(net)
		elseif(data.data.info.method == "chat_zone") then
			local temp = changeSecToTimeStr(data.data.info.t)
			temp = string.split(temp, ".")
			temp = string.split(temp[1], " ")
			local bSelf = (data.data.info.uid == PlayerData:getUid())
			self:updateChatInfo(data.data.info.s,data.data.info.name,data.data.info.title,bSelf,temp[2])
			if(self.uivisible == false and (not bSelf)) then
				Observer.sendNotification(IndexModule.CHAT_NOTICE)
			end
		end
	elseif notify == ChatModule.CHAT_CLOSED then
		self:updateChatInfo("服务器已断开")
		self.bCanSend = false
		self:updateCanSend()
	elseif notify == ChatModule.CHAT_RECONNECT then
		self:updateChatInfo("正在重连...")
	elseif notify == ChatModule.CHAT_UPDATE_STATE then
		if(self.uivisible) then
			self:updateTipTxt()
		end
	end
end
function ChatProcessor:initUI()
	if(not self.view) then
		self.mapPanel = ResourceManager:widgetFromJsonFile("ui/chatui.json")
		self.bg = self.mapPanel:getChildByName("bg")
		self.textViewBg = self.mapPanel:getChildByName("textViewBg")
		self.textView = self.mapPanel:getChildByName("textView")
		self.inputbg = self.mapPanel:getChildByName("inputbg")
		self.sendLayer = self.mapPanel:getChildByName("sendLayer")
		self.inputlayer = self.mapPanel:getChildByName("inputlayer")
		self.tipTxt = self.mapPanel:getChildByName("tipTxt")
		self.wordTip = self.mapPanel:getChildByName("wordTip")
		
		local size = self.inputlayer:getLayoutSize()

		-- self.inputtxt = ui.newEditBox({image = "ui/chatinput.png",size = CCSize(size.width+3, size.height)})
		self.inputtxt = ccui.EditBox:create(cc.size(size.width, size.height), "ui/lucency.png");
		self.inputtxt:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		self.inputtxt:setFontSize(18)
		self.inputtxt:setFontColor(cc.c3b(255,255,255))
		self.inputtxt:setFontName(DEFAULT_FONT)
		self.inputtxt:setPosition(0,0)
		--self.inputtxt:setMaxLength(DataConfig.data.cfg.system_simple.chat.max_word)
		self.inputtxt:setAnchorPoint(0,0)
		self.inputtxt:setPlaceHolder("请输入聊天内容:")
		self.inputtxt:setPlaceholderFont(DEFAULT_FONT,18)
		self.inputtxt:setPlaceholderFontColor(cc.c3b(255,255,255))
		-- self.inputtxt:addEditBoxEventListener(handler(self,self.onEdit))
		self.inputtxt:registerScriptEditBoxHandler(handler(self,self.onEdit))
		self.inputlayer:addChild(self.inputtxt)
		local max = DataConfig.data.cfg.system_simple.chat.max_word
		local cfg = DataConfig:getAllConfigMsg()
		local str = addArgsToMsg(cfg["30057"],max,max)
		self.wordTip:setString(str)

		local btn = ccui.Button:create()
		btn:setTitleText(" ")
		--btn:setTitleFontName(DEFAULT_FONT)
		--btn:setTitleFontSize(17)
		-- btn:setScale9Enabled(true)
		-- btn:setCapInsetsNormalRenderer(cc.rect(20,20,40,40))
		btn:loadTextureNormal("ui/btnsend.png")
		-- btn:setPreferredSize(cc.size(98,44))
		--btn:setContentSize(cc.size(98,44))
		btn:addTouchEventListener(handler(self,self.onSendClick))
		--enableBtnOutLine(btn, COMMON_BUTTONS.BLUE_BUTTON)
		self.sendLayer:addChild(btn,10)

		local theight = 766
		self.det = display.height - 960
		if display.height > 960 then
			theight = theight + self.det
		end

		size = self.mapPanel:getLayoutSize()
		self.mapPanel:setContentSize(cc.size(size.width,theight))

		size = self.bg:getContentSize()
		self.bg:setContentSize(cc.size(size.width,size.height + self.det))
  
		size = self.textViewBg:getContentSize()
		self.textViewBg:setContentSize(cc.size(size.width,size.height + self.det))

		size = self.textView:getContentSize()
		self.textView:setContentSize(cc.size(size.width,size.height + self.det))
		self.textView:setTouchEnabled(true)
		--self:textView:setBounceable(true)

		self.textView:addTouchEventListener(handler(self,self.onChatPlayer))

		self:setView(self.mapPanel)
		-- btn:addHandleOfControlEvent(handler(self,self.onSendClick),CCControlEventTouchUpInside)

		self.sendBtn = btn
		if(GameInstance.closechat == false) then
			self:updateChatInfo("正在连接服务器...")
		end
	end
	self:setUIVisible()
	self:updateCanSend()
	if(GameInstance.closechat == false) then
		self:connectTcp()		
	end
	self:updateTipTxt()
end
function ChatProcessor:onChatPlayer(sender, eventType)
	if eventType == ccui.TouchEventType.ended and self.prevEventType == ccui.TouchEventType.began and self.bCanSend then
		local net = {}
		net.method = ChatModule.USER_CHAT_USER_INFO
		net.params = {}
		Net.sendhttp(net)
	end

	self.prevEventType = eventType
end
function ChatProcessor:onEdit(event, editbox)
    if event == "began" then
        -- 开始输入
    elseif event == "changed" or event == "ended" or event == "return" then
    	local _text = editbox:getText()
    	local len = string.utf8len(_text)
    	local max = DataConfig.data.cfg.system_simple.chat.max_word
    	if(len > max) then
    		self.wordTip:setString("输入聊天字数超过上限".."（最多"..max.."字,已输入"..len.."字）")
    	else
    		local sheng = max - len
    		local cfg = DataConfig:getAllConfigMsg()
			local str = addArgsToMsg(cfg["30057"],sheng,max)
    		self.wordTip:setString(str)
    	end
    end
end
function ChatProcessor:updateTipTxt()
	if(GameInstance.closechat == false) then
		self.tipTxt:setColor(cc.c3b(68,220,33))
		local cfg = DataConfig:getAllConfigMsg()
		local str = addArgsToMsg(cfg["20025"])
		self.tipTxt:setString(str)
	else
		self.tipTxt:setColor(cc.c3b(255,0,0))
		local cfg = DataConfig:getAllConfigMsg()
		local str = addArgsToMsg(cfg["10187"])
		self.tipTxt:setString(str)
	end
end
function ChatProcessor:updateCanSend()
	if(self.uivisible == true) then
		self.sendBtn:setTouchEnabled(self.bCanSend)
	end
end
function ChatProcessor:connectTcp()
	Observer.sendNotification(ChatModule.CONNECT_CHAT)
end
function ChatProcessor:onSendClick(sender, eventType)
	if eventType == ccui.TouchEventType.began then
	elseif eventType == ccui.TouchEventType.moved then
	elseif eventType == ccui.TouchEventType.ended then
		local info = self.inputtxt:getText()
		if(info ~= "") then
			if(self.lastSendTime == nil or TimeManager:getSvererTime() - self.lastSendTime >= DataConfig.data.cfg.system_simple.chat.interval) then
				local len = string.utf8len(info)	
				local max = DataConfig.data.cfg.system_simple.chat.max_word
				if(len >max) then
					toastNotice("输入聊天字数超过上限")				
				else
					info = DirtyWordsTools.checkWords(info)
					local net = {}
					net.method = ChatModule.USER_CHAT_ZONE
					net.params = {}
					net.params.chat_string = info
					Net.sendhttp(net)
					self.inputtxt:setText("")
					local max = DataConfig.data.cfg.system_simple.chat.max_word
					self.wordTip:setString("您当前还可以输入"..(max).."字（最多"..max.."字）")
					self.lastSendTime = TimeManager:getSvererTime()
				end
			else
				toastNotice("亲，您发言太快了！")
			end
		end	
	elseif eventType == ccui.TouchEventType.canceled then
	else
	end
	
end
function ChatProcessor:updateChatInfo(info,speaker,title,bSelf,time)
	local strFormat
	local args
	if(not speaker) then
		strFormat ="s19"
		args = {{info,{255,255,255}},}
	else
		strFormat ="s20"
		if(bSelf) then
			args = {{speaker,{68,220,33},},{info,{68,220,33}},{"["..time.."]",{255,240,1},},}
		else
			args = {{speaker,{255,255,255},},{info,{255,255,255}},{"["..time.."]",{255,240,1},},}
		end	
		if(title and title ~= "") then
			local titles = DataConfig:getAllTitles()
			title = titles[title]
			local color = NameItem.colors[title.color]
			table.insert(args,1,{"["..title.name.."]",{color.r,color.g,color.b},})
		else
			table.insert(args,1,"")
		end
	end

	if(self.textView) then
		if(not self.txtTag) then
			self.txtTag = 1
		else
			self.txtTag = self.txtTag + 1
		end
		local eTxt = XRichText.new()
		eTxt:setContentSize(cc.size(self.textView:getContentSize().width - 20,0))
		eTxt:append(strFormat,args)
		eTxt.text:visit()

		local txtHeight = eTxt.text:getTextSize().height
		local allTxtNum = self.textView:getChildrenCount()
		local tempTxt
		--将最近的keepChatNum个位置上移
		for i=self.txtTag-1,self.txtTag-self.keepChatNum,-1 do
			if(i>0) then
				tempTxt = self.textView:getChildByTag(i)
				tempTxt:setPositionY(tempTxt:getPositionY() + txtHeight)
			end
		end
		--将最近的keepChatNum之外的删除
		if(allTxtNum > self.keepChatNum) then
			for i=self.txtTag - allTxtNum ,self.txtTag - self.keepChatNum-1  do
				tempTxt = self.textView:getChildByTag(i)
				self.textView:removeChild(tempTxt)
			end
		end
		eTxt:setAnchorPoint(0.5,1)
		eTxt:setPosition(self.textView:getContentSize().width/2, txtHeight)
		--滚动条宽度
		local innerWidth = self.textView:getInnerContainerSize().width
		--设置滚动条内容区域大小
		self.textView:setInnerContainerSize(cc.size(innerWidth,math.min(2600,allTxtNum*26)))
		self.textView:addChild(eTxt,0,self.txtTag)
		self.textView:jumpToBottom()
	end
end
function ChatProcessor:setBtnTouchAble(able)
	self.inputtxt:setTouchEnabled(able)
	self.sendBtn:setTouchEnabled(able)
end
function ChatProcessor:onHideView(view)
	-- body
	if self.mapPanel == view then
		self.mapPanel:setVisible(false)
		self.mapPanel:setLocalZOrder(-100)
		self.uivisible = false
	end
end
function ChatProcessor:setUIVisible()
	self:addMidView(self.mapPanel,true)
	self.mapPanel:setLocalZOrder(0)
	self.uivisible = true
end
return ChatProcessor