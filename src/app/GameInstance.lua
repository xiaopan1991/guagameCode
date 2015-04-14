--全局引用
local GameInstance = {}

GameInstance.modules = {}
--场景
GameInstance.mainScene = nil 	--主场景
GameInstance.loginScene = nil   --登录场景

GameInstance.uiLayer = nil

--自动售出
GameInstance.autosellcolor = {}
--非本职业 true 自动卖出非本职业的装备  false 不卖
GameInstance.autoselljob = false
--是否关闭聊天  false 开启  true 关闭
GameInstance.closechat = nil

GameInstance.relogin = false

--UI

--数据
--静态配置数据
GameInstance.config = {}	

GameInstance.RANDOM_NUM_1 = 239641
GameInstance.RANDOM_NUM_2 = 6700417
GameInstance.RANDOM_NUM_3 = 9991
GameInstance.RANDOM_NUM_SEED = GameInstance.RANDOM_NUM_SEED or nil--挂机掉落装备生成的随机种子
GameInstance.RANDOM_BOSS_BATTLE_SEED = GameInstance.RANDOM_BOSS_BATTLE_SEED or 10000--Boss战+PVP的战斗过程的随机种子
--按照目前的随机种子，生成0到mod-1的随机整数
require("framework.cc.utils.bit")
function GameInstance.getServerRandom(mod)
	if(not mod) then
		mod = 1000
	end
	if(GameInstance.RANDOM_NUM_SEED) then
		GameInstance.RANDOM_NUM_SEED = (bit.blshift(GameInstance.RANDOM_NUM_SEED + GameInstance.RANDOM_NUM_3,3) + GameInstance.RANDOM_NUM_2) % GameInstance.RANDOM_NUM_1
		return GameInstance.RANDOM_NUM_SEED % mod
	end
end
function GameInstance.getSeedFromServer(serverSeed)
	GameInstance.RANDOM_NUM_SEED = serverSeed
end
function GameInstance.setHangEquipNum(num)
	GameInstance.HANG_EQUIP_NUM = num
end
function GameInstance.getNextHangEquipNum()
	GameInstance.HANG_EQUIP_NUM = GameInstance.HANG_EQUIP_NUM + 1
	return GameInstance.HANG_EQUIP_NUM
end
function GameInstance.getBossBattleSeedFromServer(serverSeed)
	GameInstance.RANDOM_BOSS_BATTLE_SEED = serverSeed
end
function GameInstance.getBossBattleServerRandom(mod)
	if(not mod) then
		mod = 1000
	end
	if(GameInstance.RANDOM_BOSS_BATTLE_SEED) then
		GameInstance.RANDOM_BOSS_BATTLE_SEED = (bit.blshift(GameInstance.RANDOM_BOSS_BATTLE_SEED + GameInstance.RANDOM_NUM_3,3) + GameInstance.RANDOM_NUM_2) % GameInstance.RANDOM_NUM_1
		return GameInstance.RANDOM_BOSS_BATTLE_SEED % mod
	end
end
function GameInstance.setGameSetting(arr)
	local temp = GameInstance.closechat
	GameInstance.closechat = (arr[6] == 1)
	if(GameInstance.closechat == true and temp == false) then
		Observer.sendNotification(NetCoreModule.CLOSE_SOCKET )
	elseif(GameInstance.closechat == false and temp == true) then
		Observer.sendNotification(ChatModule.CONNECT_CHAT)
	end
	Observer.sendNotification(ChatModule.CHAT_UPDATE_STATE)
	GameInstance.autoselljob = (arr[5] == 1)
	GameInstance.autosellcolor = {}
	for i=1,4 do
		GameInstance.autosellcolor[i] = arr[i]
	end
end
return GameInstance