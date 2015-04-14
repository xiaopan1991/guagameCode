require("framework.scheduler")
local DazaoProcessor = class("DazaoProcessor", BaseProcessor)
local ItemFace = require("app.components.ItemFace")
local EquipAttrInfo = require("app.components.EquipAttrInfo")

function DazaoProcessor:ctor()
	-- body
	self.lock = false
end

function DazaoProcessor:ListNotification()
	return {
		RonglianModule.SHOW_DA_ZAO,
		RonglianModule.USER_EQUIP_FORGE_INFO,
		RonglianModule.USER_EQUIP_MELTE_EXCHANGE,
		RonglianModule.USER_EQUIP_FORGE_REFRESH
	}
end

function DazaoProcessor:handleNotification(notify, data)
	if notify == RonglianModule.SHOW_DA_ZAO then
		self:onSetView()
	   --发消息给服务器
		local data = {}
		data.method = RonglianModule.USER_EQUIP_FORGE_INFO
		data.params = {}
		data.params.pf = PF_CONFIG
		Net.sendhttp(data)
	elseif notify == RonglianModule.USER_EQUIP_FORGE_INFO  then
		--返回需要打造的装备
		self:handleNeedEquipMelteData(data.data)

	elseif notify == RonglianModule.USER_EQUIP_MELTE_EXCHANGE  then
		--返回打造装备
		self:handleEquipMelteData(data.data)
	elseif notify == RonglianModule.USER_EQUIP_FORGE_REFRESH then
		--刷新返回的数据
		self:handleUpdataMelteData(data.data)
	end
end
--显示需要打造的装备
function DazaoProcessor:handleNeedEquipMelteData(data)
	--dump(data,"可打造数据返回",999)
	PlayerData:setDazaoData(data.data)
	self.dzdata = PlayerData:getDazaoData()
	local info = self.dzdata.info.info
	self.refresh = self.dzdata.equip_forge_refresh
	self:onSetData()
	self.lock = true
end
--设置装备的数据
function DazaoProcessor:onSetData()
	--属性列表
	--dump(self.dzdata,"可以打造的装备",999)
	self.attr:setData(self.dzdata.info.info)
	self.itemface:setData(self.dzdata.info.info)
	local re_fresh = tostring(self.refresh or 0)
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30059"],re_fresh)
	self.txtUpTimes:setString(str)
	local god = false
	if #self.dzdata.info.info.god > 0 then
		god = true
	end
	print(DataConfig:getDazaoCost(self.dzdata.info.info.color[1] + 1 , god))
	print(PlayerData:getMelte())
	local haveMelte = PlayerData:getMelte()
	local dazaocost = DataConfig:getDazaoCost(self.dzdata.info.info.color[1] + 1 , god)
	if dazaocost > haveMelte then
		--熔炼值不够  红色
		self.txtMelte:setColor(COLOR_RED)
	else
		--绿色
		self.txtMelte:setColor(COLOR_GREEN)
	end
	local strMelte = addArgsToMsg(cfg["30058"],dazaocost,haveMelte)
	self.txtMelte:setString(strMelte)
end

function DazaoProcessor:onSetView()

	local dazaoPanel = ResourceManager:widgetFromJsonFile("ui/dazaopanel.json")
	local txtLable = dazaoPanel:getChildByName("txtLable")
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["20028"])
	txtLable:setString(str)
	-- self.txtMelte = dazaoPanel:getChildByName("dazaoPanel")
	self.txtMelte = dazaoPanel:getChildByName("txtMelte")
	--今日免费刷新次数
	self.txtUpTimes = dazaoPanel:getChildByName("txtUpTimes")
	local re_fresh = tostring(self.refresh or 0)
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30059"],re_fresh)
	self.txtUpTimes:setString(str)
	local btnUp = dazaoPanel:getChildByName("btnUp")
	local btnDazao = dazaoPanel:getChildByName("btnDazao")
	
	local titleIma = dazaoPanel:getChildByName("titleIma")
	local txtTitle = dazaoPanel:getChildByName("txtTitle")
	local btnClose = dazaoPanel:getChildByName("btnClose")
	btnUp:addTouchEventListener(handler(self,self.onBtnClick))
	btnDazao:addTouchEventListener(handler(self,self.onBtnClick))
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))

	--属性列表
	local attr = EquipAttrInfo.new()
	-- attr:setData(dzdata.info)
	attr:setPosition(400,625)
	dazaoPanel:addChild(attr)
	self.attr = attr
	--装备格子
	local itemface = ItemFace.new()
	itemface.showInfo = false --禁用鼠标事件
	itemface:setPosition(70,530)
	dazaoPanel:addChild(itemface)
	self.itemface = itemface 

	self:setView(dazaoPanel)      

	self:addPopView(dazaoPanel)
end

function DazaoProcessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnUp" then
		if self.lock == false then
			return
		end
		--判断免费刷新打造的次数
		if self.refresh == 0 then
			-- 今日免费次数已经用完，刷新一次需要花费20元宝，确定继续吗？
			local price = DataConfig:getDazaoRefreshCost()
			if price > PlayerData:getCoin() then
				-- toastNotice("元宝不足，需要"..price.."元宝")
				btns = {{text = "取消",skin = 2},{text = "充值",skin = 3,callback = handler(self,self.sendChargeView)}}
				alert = GameAlert.new()
				richStr = {{text = "您的元宝不足，请您及时充值！",color = display.COLOR_WHITE}}
				alert:pop(richStr,"ui/titlenotice.png",btns)
				return
			end
			local cfg = DataConfig:getAllConfigMsg()
			local strText = addArgsToMsg(cfg["30060"],price)
			local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendRefresh),args = true},}
			local alert = GameAlert.new()
			alert:pop(strText,"ui/titlenotice.png",btns)
			return
		end
		--发消息给服务器
		self:sendRefresh()
		self.lock = false
	elseif btnName == "btnDazao" then
		if self.lock == false then
			return
		end
		--判断熔炼值是否足够
		if self.dzdata == nil then
			toastNotice("没有可打造装备")
			return
		end
		local god = false
		if #self.dzdata.info.info.god > 0 then
			god = true
		end
		local melte = PlayerData:getMelte()
		local cost = DataConfig:getDazaoCost(self.dzdata.info.info.color[1] + 1 , god)
		self.cost = cost
		if melte < cost then
			toastNotice("熔炼值不足！",COLOR_RED)
			return
		end
		--发消息给服务器
		local data = {}
		data.method = RonglianModule.USER_EQUIP_MELTE_EXCHANGE 
		data.params = {}
		data.params.pf = PF_CONFIG
		Net.sendhttp(data)
		self.lock = false
		-- self.lock = true
		-- scheduler.performWithDelayGlobal(handler(self,self.onReleaseLock), 0.8)

	elseif btnName == "btnClose" then
		self:removePopView(self.view)
	end
end
--前去充值
function DazaoProcessor:sendChargeView()
	self:removePopView(self.view)
	Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
end

function DazaoProcessor:onReleaseLock()
	-- self.lock = false
end

--打造装备
function DazaoProcessor:handleEquipMelteData(data)
	--dump(data,"打造装备",99)
	local dzOkdata = data.data
	local id = dzOkdata.eqid
	local info = dzOkdata.info
	local melte = dzOkdata.melte
	Bag:addEquip(id,info)
	local item = Bag:getEquipById(id)

	--打造的装备返回 加进背包里 同时减去相应的熔炼值
	local god = false 
	if #data.data.info.god > 0 then
		god = true
	end
	print("melte"..melte)
	local cost = DataConfig:getDazaoCost(data.data.info.color[1] + 1 , god)
	PlayerData:setMelte(melte)
	local c3 = Bag:getEquipColor(item.color[1])
	popNotices({{"获得装备："..item.edata.name,c3},{"熔炼值：-"..self.cost,COLOR_RED}})
	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR)

	self:onUpDataHadler()
end

--更新
function DazaoProcessor:onUpDataHadler()
	local data = {}
	data.method = RonglianModule.USER_EQUIP_FORGE_INFO 
	data.params = {}
	data.params.pf = PF_CONFIG
	Net.sendhttp(data)
end

--刷新数据返回
function DazaoProcessor:handleUpdataMelteData(data)
	if data.params.is_coin == 1  then
		local price = DataConfig:getDazaoRefreshCost()
		notice("消耗元宝："..price)
		local yuanbao = PlayerData:getCoin()
		yuanbao = yuanbao - price
		if yuanbao < 0 then
			yuanbao = 0
		end
		PlayerData:setCoin(yuanbao)
	else
		self.refresh = self.refresh - 1
	end
	PlayerData:setDazaoData(data.data)
	self.dzdata = PlayerData:getDazaoData()
	self:onSetData()
	self.lock = true
	-- local dzdata = PlayerData:getDazaoData()
	-- local info = dzdata.info.info
end

--发送刷新打造请求
function DazaoProcessor:sendRefresh(coinrefresh)
	--是否元宝刷新
	coinrefresh = coinrefresh or false
	local data = {}
	data.method = RonglianModule.USER_EQUIP_FORGE_REFRESH 
	data.params = {}
	if coinrefresh == true then
		data.params.is_coin = 1
	else
		data.params.is_coin = 0
	end
	Net.sendhttp(data)
end

return DazaoProcessor