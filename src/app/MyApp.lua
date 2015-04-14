
require("config")
require("platform")
require("framework.init")
require("app.utils.GlobalArgs")
require("app.utils.common")
require("socket")

display.COLOR_YELLOW = cc.c3b(255, 255, 0)
display.COLOR_VIOLET = cc.c3b(255, 0, 255)
display.COLOR_ORANGE = cc.c3b(255, 165, 0)
display.COLOR_GREY = cc.c3b(128, 128, 128)

DEFAULT_FONT = "yh.ttf"

--可写目录，Windows上就是工程根目录，Android上是SD卡+"guagame"
WRITE_PATH = ""
--全局引用
GameInstance = import(".GameInstance")
require("cocos.ui.GuiConstants")
--全局类
BaseModule = require("core.BaseModule")
BaseProcessor = require("core.BaseProcessor")
Observer = require("core.Observer")
Net = require("app.manager.Net")
-- BasePanel = require("app.components.BasePanel")
--模块
NetCoreModule = require("app.module.netcore.NetCoreModule")		--网络模块
LoginModule = require("app.module.login.LoginModule")			--登录模块
MainSceneModule = require("app.module.mainui.MainSceneModule")	--主场景模块
IndexModule = require("app.module.index.IndexModule")			--主页模块
ShopModule = require("app.module.shop.ShopModule")				--商城模块
BagModule = require("app.module.bag.BagModule")					--背包模块
RonglianModule = require("app.module.ronglian.RonglianModule")  -- 熔炼模块
MapModule = require("app.module.map.MapModule")                 --地图、
GamesysModule = require("app.module.gamesys.GamesysModule")     -- 系统模块
BattleModule = require("app.module.battle.BattleModule")  		-- 战斗模块--数据
PVPModule = require("app.module.pvp.PVPModule")					--PVP 模块
FollowerModule = require("app.module.follower.FollowerModule")		--弟子模块
ChatModule = require("app.module.chat.ChatModule")
skillmodule = require("app.module.skill.skillmodule")
ChargeModule = require("app.module.charge.ChargeModule")        --充值
MultiBattleModule = require("app.module.multibattle.MultiBattleModule")--团战
GmdModule = require("app.module.guangmingding.GmdModule")--光明顶

PlayerData = require("app.manager.PlayerDataManager").new()		--玩家数据集合 
Raid = require("app.manager.RaidManager").new()					--Raid数据集合
Bag = require("app.manager.BagManager").new() 					--背包数据集合
DataConfig = require("app.manager.DataConfigManager").new() 	--配置数据集合

--工具
local GameNotice = require("app.components.GameNotice")			--文字提示组件
LoadingBall = require("app.components.LoadingBall")				--加载小圈圈
XWebView = require("app.components.XWebView")					--浏览器

TimeManager = require("app.manager.TimeManager").new() 							--时间管理
BattleManager = require("app.manager.BattleManager").new()						--挂机戰斗管理
BossPvpBattleManager = require("app.manager.BossPvpBattleManager").new() 		--Boss+Pvp 戰斗管理
Audio = require("app.manager.AudioManager").new()                               --声音管理器
ResourceManager = require("app.manager.ResourceManager").new()                  --json界面文件资源管理

gamenotice = gamenotice or nil
if gamenotice == nil then
	gamenotice = GameNotice.new()
	GameInstance.notice = gamenotice
end
notice = function(content,cpp)
	-- body
	return gamenotice:popNotices({{content,cpp}})
end
toastNotice = function(content,cpp)
	-- body
	return gamenotice:popNotices({{content,cpp}})
end
popNotices = function(notices)
	-- body
	return gamenotice:popNotices(notices)
end
 --notice("提示内容",255,0,0)

GameAlert = require("app.components.GameAlert")
GameInputAlert = require("app.components.GameInputAlert")
PopLayer = require("app.components.PopLayer").new()

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

--模块列表
function MyApp:moduleList()
	return {
		NetCoreModule,
		MainSceneModule,
		IndexModule,
		ShopModule,
		LoginModule,
        
		BagModule,
		RonglianModule,
		MapModule,
		BattleModule,
		PVPModule,
		EquipModule,
		GamesysModule,
		FollowerModule,
		ChatModule,
		skillmodule,
		ChargeModule,
        MultiBattleModule,
        --GmdModule,
	}
end

function MyApp:run()
	--初始化WRITE_PATH
	if device.platform == "android" or device.platform == "ios" then
		WRITE_PATH = cc.FileUtils:getInstance():getWritablePath().."guagame/"
	else
		WRITE_PATH = cc.FileUtils:getInstance():getWritablePath()
	end
	--注册各个Module
	self:registerModule()

    cc.FileUtils:getInstance():addSearchPath("res/")
    cc.Director:getInstance():setProjection(cc.DIRECTOR_PROJECTION2_D)
    self:enterScene("LoginScene")
end

function MyApp:registerModule()
	local modules = self:moduleList()
	self.modules = {}
	--v 是BaseModule的子类
	for k,v in pairs(modules) do
		local mod = v.new()
		mod:registerProcessor()
		table.insert(self.modules,mod)
	end
end

function MyApp:unregisterModule()
	if self.modules ~= nil then
		for k,v in pairs(self.modules) do
			v:unregisterProcessor()
		end
	end
end

--进入后台
function MyApp:onEnterBackground()
	MyApp.super.onEnterBackground(self)
	--
	if(TimeManager.started) then
        TimeManager:setPause(true)
    end
    self.background = true
end

--进入前台
function MyApp:onEnterForeground()
	MyApp.super.onEnterForeground(self)
	--
	-- 控制音乐播放 如果是停止的话 就停止
	local flag = cc.UserDefault:getInstance():getIntegerForKey("soundstatus",0)
	if flag == 1 then
		Audio:pause()
	end
	if(self.background and TimeManager.started) then
		BattleModule:sendHangclear(false)
		self.background = false
	end
end

return MyApp