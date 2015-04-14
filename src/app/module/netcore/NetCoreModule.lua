--网络通信层
local NetCoreModule = class("NetCoreModule", BaseModule)
local SocketProcessor = import(".SocketProcessor")
local HttpProcessor = import(".HttpProcessor")

--SOCKET长连接
NetCoreModule.SEND_SOCKET = "SEND_SOCKET"
NetCoreModule.RECEIVE_SOCKET = "RECEIVE_SOCKET"
NetCoreModule.CLOSE_SOCKET = "CLOSE_SOCKET"
--HTTP短连接
NetCoreModule.SEND_HTTP = "SEND_HTTP"
NetCoreModule.RECEIVE_HTTP = "RECEIVE_HTTP"
--Processor
function NetCoreModule:ProcessorList()
	-- body
	return {
		SocketProcessor,
		HttpProcessor
	}
end

return NetCoreModule