--聊天模块
local ChatModule = class("ChatModule", BaseModule)
local ChatProcessor = import(".ChatProcessor")
local ChatPlayerProcessor = import(".ChatPlayerProcessor")
ChatModule.SHOW_CHAT = "SHOW_CHAT"
ChatModule.ADD_CHAT_MESSAGE = "ADD_CHAT_MESSAGE"
ChatModule.USER_CHAT_ZONE = "user.chat_zone"
ChatModule.USER_CHAT_USER_INFO = "user.chat_user_info"
ChatModule.USER_CHAT_RECORD = "user.chat_record"
ChatModule.CONNECT_CHAT = "CONNECT_CHAT"
ChatModule.CHAT_CONNECTED = "CHAT_CONNECTED"
ChatModule.CHAT_CLOSED = "CHAT_CLOSED"
ChatModule.CHAT_RECONNECT = "CHAT_RECONNECT"
ChatModule.CHAT_UPDATE_STATE = "CHAT_UPDATE_STATE"
ChatModule.CHAT_HAS_SEND_LOGIN = "CHAT_HAS_SEND_LOGIN"
function ChatModule:ctor()
	ChatModule.super.ctor(self)
end

function ChatModule:ProcessorList()
	return {
		ChatProcessor,
		ChatPlayerProcessor
	}
end
return ChatModule