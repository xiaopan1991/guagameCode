--登录模块
local LoginModule = class("LoginModule", BaseModule)

local LoginProcessor        = import(".LoginProcessor")			--登录管理
local LoginConfigProcessor  = import(".LoginConfigProcessor")	--登录配置数据管理
local CreateRoleProcessor   = import(".CreateRoleProcessor")	--创建角色管理器
local LoginLoadingProcessor = import(".LoginLoadingProcessor")	--登录Loading进度管理器

--显示初始登录界面
LoginModule.SHOW_LOGINVIEW = "SHOW_LOGINVIEW"
--显示创建角色的界面
LoginModule.SHOW_CREAT_ROLE_VIEW = "SHOW_CREAT_ROLE_VIEW" 
--显示登录loading界面
LoginModule.SHOW_LOGIN_LOADING = "SHOW_LOGIN_LOADING"
--更新登录loading界面
LoginModule.UPDATE_LOGIN_LOADING = "UPDATE_LOGIN_LOADING"
--界面json文件加载完成
LoginModule.JSON_LOAD_COMPLETED = "JSON_LOAD_COMPLETED"

--从服务器获取配置文件成功
LoginModule.CONFIG_DATA_GET = "sys.get_config"
--用户登录
LoginModule.USER_LOGIN = "user.login"
--用户注册
LoginModule.USER_REGISTER = "user.register"
--创建用户
LoginModule.USERINIT_USER = "user.init_user"


--从本地读取配置文件
LoginModule.GET_LOCAL_CONFIG = "GET_LOCAL_CONFIG"	--开始读

function LoginModule:ProcessorList()
	return {
		LoginProcessor,
		LoginConfigProcessor,
		CreateRoleProcessor,
		LoginLoadingProcessor
	}
end

return LoginModule