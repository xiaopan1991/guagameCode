--网络层处理器  长连接

cc.utils 				= require("framework.cc.utils.init")
cc.net 					= require("framework.cc.net.init")
local PacketBuffer = import(".PacketBuffer") 


local SocketProcessor = class("SocketProcessor", BaseProcessor)

--
function SocketProcessor:ctor()
 	--socket数据队列
 	self.datapool = {}
 	self.connectHeartID = nil
 	self.reConnectID = nil
 	self.hasSendLogin = false
end
--消息列表
function SocketProcessor:ListNotification()
	return {
		NetCoreModule.SEND_SOCKET,
		NetCoreModule.RECEIVE_SOCKET,
		ChatModule.CONNECT_CHAT,
		NetCoreModule.CLOSE_SOCKET,
		ChatModule.CHAT_HAS_SEND_LOGIN,
	}
end

--处理消息
function SocketProcessor:handleNotification(notify,data)
	if notify == NetCoreModule.SEND_SOCKET then
		-- 缓存掉
		self.datapool[#self.datapool+1] = data.data
		-- data.data = nil
		if self._socket == nil or self._socket.isConnected == false then 
			self:connect()
			return
		end
		self:send()
	elseif notify == NetCoreModule.RECEIVE_SOCKET then
	elseif notify == NetCoreModule.CLOSE_SOCKET then
		self:closeTcp()
	elseif notify == ChatModule.CONNECT_CHAT then
		if( not self.hasSendLogin) then
			self:connectTcp()
		end
		self.hasSendLogin = true
	elseif notify == ChatModule.CHAT_HAS_SEND_LOGIN then
		self.hasSendLogin = true
	end 
end

--连接网络
function SocketProcessor:connect()
	-- body
	if not self._socket then
		self._socket  = cc.net.SocketTCP.new(SERVER_IP, SERVER_PORT)
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CONNECTED, handler(self, self.onStatus))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CLOSE, handler(self,self.onStatus))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CLOSED, handler(self,self.onStatus))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CONNECT_FAILURE, handler(self,self.onStatus))

		self._socket:addEventListener(cc.net.SocketTCP.EVENT_DATA, handler(self,self.onData))
		self._buf = PacketBuffer.new()
	end

	self._socket:connect()
end

--socket 状态
function SocketProcessor:onStatus(event)
	print("SocketProcessor:onStatus"..event.name)
	if event.name == cc.net.SocketTCP.EVENT_CONNECTED then
		self:send()
		if(self.connectHeartID) then
			scheduler.unscheduleGlobal(self.connectHeartID)
			self.connectHeartID = nil
		end
		local function sendHeartBeat()
			local data = {}
			data.method = "heartbeat"
			Net.sendsocket(data)
		end
		self.connectHeartID = scheduler.scheduleGlobal(sendHeartBeat,5)
		if(self.reConnectID) then
			scheduler.unscheduleGlobal(self.reConnectID)
			self.reConnectID = nil
		end
		Observer.sendNotification(ChatModule.CHAT_CONNECTED )
		--连接上了
	elseif event.name == cc.net.SocketTCP.EVENT_CLOSE then
		--关闭
		self.hasSendLogin = false
		self.datapool = {}
		if(self._socket) then
			self._socket.isConnected = false
			self._socket = nil
		end
		if(self.connectHeartID) then
			scheduler.unscheduleGlobal(self.connectHeartID)
			self.connectHeartID = nil
		end
		if(self.reConnectID) then
			scheduler.unscheduleGlobal(self.reConnectID)
			self.reConnectID = nil
		end
		Observer.sendNotification( ChatModule.CHAT_CLOSED )
		if(GameInstance.closechat == false) then
			self.reConnectID = scheduler.scheduleGlobal(handler(self,self.connectTcp),10)
			Observer.sendNotification( ChatModule.CHAT_RECONNECT )
		end		
	--elseif event.name == cc.net.SocketTCP.EVENT_CLOSED then
		--已关闭
	--elseif event.name == cc.net.SocketTCP.EVENT_CONNECT_FAILURE then
		--失败
	end
end
function SocketProcessor:closeTcp()
	if(self.connectHeartID) then
		scheduler.unscheduleGlobal(self.connectHeartID)
		self.connectHeartID = nil
	end
	if(self.reConnectID) then
		scheduler.unscheduleGlobal(self.reConnectID)
		self.reConnectID = nil
	end
	self.datapool = {}
	self.hasSendLogin = false
	if(self._socket) then
		self._socket.isConnected = false
		self._socket:close()
		self._socket = nil
	end	
	--Observer.sendNotification( ChatModule.CHAT_CLOSED )
end
function SocketProcessor:connectTcp()
	local data = {}
	data.method = "login"
	data.uid = PlayerData:getUid()
	data.key = PlayerData:getSessionId()
	Net.sendsocket(data)
end
function SocketProcessor:unregister()
	self:closeTcp()
	SocketProcessor.super.unregister(self)
end
--socket 数据
function SocketProcessor:onData(event)
	-- body
	print("SocketProcessor:onData=",event.data)
	local msgs = event.data
	if(type(msgs) == "string") then
		msgs = string.split(msgs,'\r\n')
		local info
		local tempNode
		local data
		for i,v in ipairs(msgs) do
			if(v ~= "") then
				info = json.decode(v)
				tempNode = display.newNode()
				data = {}
				tempNode.data = data
				data.info = info
				if(info.method == "err" and info.code == 100000) then
					local btns = {{text = "确定",skin = 3,callback = handler(self,self.gotoLogin)}}
		            local alert = GameAlert.new()
		            local richStr = {{text = "聊天数据异常！！！",color = display.COLOR_WHITE},
		            }
		            alert:pop(richStr,"ui/titlenotice.png",btns)
		            self:closeTcp()
					return
				end 
				Observer.sendNotification(ChatModule.ADD_CHAT_MESSAGE ,tempNode)
			end
		end
	end	
	--[[
	local __msgs = self._buf:parsePackets(event.data)
	local __msg = nil
	local msgData
	for i=1,#__msgs do
		__msg = __msgs[i]
		-- TODO转成json 然后广播出去
		-- dump(__msg)
		msgData = json.decode(__msg)
		print("888888888888888888888888888888888888888888")
		dump(msgData)
	end
	]]
end
function SocketProcessor:gotoLogin()
    TimeManager:stop()
    GameInstance.relogin = true
    LoadingBall.hide()
    local scene = require("app.scenes.LoginScene").new()
    display.replaceScene(scene)
end
--从队列里取，然后依次发送
function SocketProcessor:send()
	while #self.datapool > 0 do
		local data = self.datapool[1]
		table.remove(self.datapool,1)
		print("begin send"..json.encode(data))
		local __buf = PacketBuffer.parseData(data)
		self._socket:send(__buf:getPack()..'\r\n')
	end
end


return SocketProcessor