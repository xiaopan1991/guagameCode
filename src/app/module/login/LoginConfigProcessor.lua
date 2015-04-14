--登录之前同步配置数据
local LoginConfigProcessor = class("LoginConfigProcessor",BaseProcessor)

function LoginConfigProcessor:ctor()
	-- body
end

--消息监听
function LoginConfigProcessor:ListNotification()
	return {
		LoginModule.GET_LOCAL_CONFIG,--开始去读本地的配置
		LoginModule.CONFIG_DATA_GET--获取服务器的配置成功
	}
end

--消息处理
function LoginConfigProcessor:handleNotification(notify, data)
	if notify == LoginModule.GET_LOCAL_CONFIG then
		self:getLocalConfig(data.data)
	elseif notify == LoginModule.CONFIG_DATA_GET then
		self:onGetServerConfig(data.data)
	end
end
function LoginConfigProcessor:getLocalConfig(ldata)
	-- body
	local configPath = WRITE_PATH .. "config.json"
	local fileData = nil
	if cc.FileUtils:getInstance():isFileExist(configPath) then
		fileData = cc.HelperFunc:getFileData(configPath)
	end
	--如果本地有文件则写入全局配置
	if fileData ~= nil then
		GameInstance.config = json.decode(fileData)
	end
	--进度条 调度
	--发送
	local data = {}
	data.method = LoginModule.CONFIG_DATA_GET
	data.params = {}
	Net.sendhttp(data,ldata)
end

--获取网络文件成功
function LoginConfigProcessor:onGetServerConfig(data)
	--body
	print("config data is coming")
	-- dump(data)
	--比对合并table
	GameInstance.config.cfg = GameInstance.config.cfg or {}
	if data.data.cfg ~= nil then
		table.merge(GameInstance.config.cfg,data.data.cfg)
	end
	GameInstance.config.ana_url = data.data.ana_url
	GameInstance.config.cfg_version = data.data.cfg_version	--配置版本号
	DataConfig:setData(GameInstance.config) --设置全局配置数据管理器的数据
	--然后再写入到存储器上
	local mode = "w+b"
	local file = io.open(WRITE_PATH .. "config.json", mode)
	if file then
        if file:write(json.encode(GameInstance.config)) == nil then 
        	print("write config fail")
        end
        io.close(file)
        print("write config ok")
    end
	--显示登录界面
	Observer.sendNotification(LoginModule.SHOW_LOGINVIEW, nil)
end

return LoginConfigProcessor