-- 登录进度条模块
-- Author: whe
-- Date: 2014-09-02 14:26:01

--登录处理器
local LoginLoadingProcessor = class("LoginProcessor", BaseProcessor)

function LoginLoadingProcessor:ctor()
	
end

function LoginLoadingProcessor:ListNotification()
	return {
		LoginModule.SHOW_LOGIN_LOADING,
		LoginModule.UPDATE_LOGIN_LOADING
	}
end

--
function LoginLoadingProcessor:handleNotification(notify, data)
	if notify == LoginModule.SHOW_LOGIN_LOADING then
		self:initUI()
		if data ~= nil then
			self:setData(data.data)
		end
	elseif notify == LoginModule.UPDATE_LOGIN_LOADING then
		self:setData(data.data)
	end
end

--初始化UI显示
-- arg  预留 没用
function LoginLoadingProcessor:initUI(arg)
	if self.view ~= nil and not tolua.isnull(self.view) then
		return
	end

	local view = ResourceManager:widgetFromJsonFile("ui/loginloading.json")
	local progressbar = view:getChildByName("progressbar")
	local lbinfo = view:getChildByName("lbinfo")
	self.progressbar = progressbar
	self.lbinfo = lbinfo
	self:setView(view)

	local size = view:getContentSize()
	view:setPosition(display.cx - size.width/2,display.cy-size.height/2 - 200)
	GameInstance.loginScene:addMidView(view)
end

--设置数据
function LoginLoadingProcessor:setData(data)
	if data == nil then
		self.progressbar:setPercent(4)
		--self.lbinfo:setString("加载配置文件 1%")
	end

	local per = data.per
	local tper = data.per
	local info = data.info
	if tper < 4 then
		tper = 4
	end
	if(data.per == 10) then
		math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		local msgindex = 40000 + math.random(1,21)--40001-40021为随机提示
		self.lbinfo:setString(DataConfig:getConfigMsgByID(tostring(msgindex)))
	end
	self.progressbar:setPercent(tper)
	--self.lbinfo:setString(info.." "..per.."%")
end

return LoginLoadingProcessor