--装备强化处理器
local ItemFace = require("app.components.ItemFace")
local EquipAttrInfo = require("app.components.EquipAttrInfo")

local QiangHuaProcessor = class("QiangHuaProcessor", BaseProcessor)

function QiangHuaProcessor:ctor()
	-- body
end

function QiangHuaProcessor:ListNotification()
	return {
		BagModule.SHOW_EQUIP_QIANGHUA,
		BagModule.USER_EQUIP_STRENGTHEN,
		IndexModule.MONEY_UPDATE
	}
end

--处理消息
function QiangHuaProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_EQUIP_QIANGHUA then 
		self:initUI()
		self:setData(data.data)
	elseif notify == BagModule.USER_EQUIP_STRENGTHEN then
		self:handleQiangHua(data.data)
	elseif notify == IndexModule.MONEY_UPDATE then
		if self.view ~= nil then
			if self.data ~= nil then
				if self.data.star < 15 then
					self.yinliang = DataConfig:getQianghuaCostYinliang(self.data)
				else
					self.yinliang = 0
				end
				local cfg = DataConfig:getAllConfigMsg()
				local str = addArgsToMsg(cfg["30038"],self.yinliang,PlayerData:getGold())
				self.txt3:setString(str)
			end
			
		end
		
	end
end

--初始化UI
function QiangHuaProcessor:initUI()
	if self.view ~= nil then
		return
	end

	--TIP 强化和洗练用同一个json
	local view = ResourceManager:widgetFromJsonFile("ui/equipxilian.json")
	view:setName("equipqianghua")
	local btnClose = view:getChildByName("btnClose")  	--关闭按钮
	local btnOK    = view:getChildByName("btnOK")		--强化按钮
	local txtTitle = view:getChildByName("txtTitle")	--标题
	local lbinfo   = view:getChildByName("lbinfo")		--说明文本
	local helpBtn = view:getChildByName("helpBtn")
	local imgType = view:getChildByName("imgType")
	self.imgType = imgType

	self.txt1 = view:getChildByName("txt1")  --下一级强化 主属性
	self.txt2 = view:getChildByName("txt2")  --需要强化精华
	self.txt3 = view:getChildByName("txt3")  --需要银两

	btnOK:addTouchEventListener(handler(self,self.onBtnClick))
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
	--标题和说明
	--下一级强化说明文本
	-- txtTitle:setString("装备强化")
	txtTitle:loadTexture("ui/titleqianghua.png")
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["20026"])
	lbinfo:setString(str)
	btnOK:setTitleText("强化")

	--装备图标
	local itemface_r = ccui.RelativeLayoutParameter:create()
	itemface_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	itemface_r:setMargin({left=80, top=120})

	self.itemface = ItemFace.new()
	-- self.itemface:setPosition(88,530)
	self.itemface:setLayoutParameter(tolua.cast(itemface_r,"ccui.LayoutParameter"))
	view:addChild(self.itemface,2)
	self.itemface.showInfo = false

	--装备属性
	local attr_r = ccui.RelativeLayoutParameter:create()
	attr_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	attr_r:setMargin({left=440, top=150})

	self.attr = EquipAttrInfo.new()
	-- self.attr:setPosition(455,615)
	self.attr:setLayoutParameter(tolua.cast(attr_r,"ccui.LayoutParameter"))
	view:addChild(self.attr,2)
	self:setView(view)
	self:addPopView(self.view)
end

--设置数据
function QiangHuaProcessor:setData(data)
	self.data = data
	--dump(data)

	local pos = string.sub(self.data.eid,3,3)
	self.imgType:loadTexture("ui/e"..pos..".png")

	--搞一个itemface 再搞一个EquipAttrInfo
	-- print(self.itemface)
	self.itemface:setData(self.data)
	--属性
	self.attr:setData(self.data)

	--文本说明
	if self.data.star < 15 then
		self.arrup = DataConfig:getQianghuaAdd(self.data)
		self.jinghua = DataConfig:getQianghuaCostJinghua(self.data)
		self.yinliang = DataConfig:getQianghuaCostYinliang(self.data)
	else
		self.arrup = 0
		self.jinghua = 0 
		self.yinliang = 0
	end
	local jh = Bag:getGoodsById("I0001")
	local jhnum = 0
	if jh ~= nil then
		jhnum = jh.num
	end
	if jhnum < self.jinghua then
		self.txt2:setColor(COLOR_RED)
	end
	local curgold = PlayerData:getGold()
	if curgold < self.yinliang then
		self.txt3:setColor(COLOR_RED)
	end
	local cfg = DataConfig:getAllConfigMsg()
	local textStr = addArgsToMsg(cfg["30050"],self.arrup)
	self.txt1:setString(textStr.."%")
	self.txt2:setString("需要强化精华："..self.jinghua.."（当前拥有："..jhnum.."）")
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30038"],self.yinliang,curgold)
	self.txt3:setString(str)
end

--按钮点击处理
function QiangHuaProcessor:onBtnClick(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnOK" then
		if self.data.star == 15 then
			toastNotice("装备已经强化顶级,无法继续强化！")
			return 
		end

		local jh = Bag:getGoodsById("I0001")
		if jh == nil or jh.num < self.jinghua then
			
			local cfg = DataConfig:getAllConfigMsg()
			toastNotice(cfg["10175"])
			self.txt2:setColor(COLOR_RED)
			return
		end

		if PlayerData:getGold() < self.yinliang then
			self.txt3:setColor(COLOR_RED)
			toastNotice("银两不足!")
			return
		end

		self:sendQianghua()
	elseif btnName == "btnClose" then
		self:removePopView(self.view)
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("intensify_equipment")
	end
end

--发送强化请求
function QiangHuaProcessor:sendQianghua()
	-- dump(self.data)
	local net = {}
	net.method = BagModule.USER_EQUIP_STRENGTHEN
	net.params = {}
	net.params.eqid = self.data.sid
	Net.sendhttp(net)
end

--处理服务器发来的数据
function QiangHuaProcessor:handleQiangHua(data)
	--dump(data,"强化数据返回",999)
	local bag = data.data.bag --返回物品列表
	--更新道具列表 弹出获得道具提示
	local gold = data.data.gold
	-- local cost = PlayerData:getGold() - gold
	PlayerData:setGold(gold)
	-- local gold = data.data.gold
	local equip = data.data.equip
	local eid = nil
	for k,v in pairs(equip) do
		Bag:updateEquip(k,v)
		eid = k
	end
	local tdata = Bag:getEquipById(eid)
	--dump(tdata)
	local notices = {{"强化成功！",COLOR_GREEN},{"消耗银两:-"..self.yinliang}}
	

	local goods = nil
	for l,m in pairs(data.data.bag) do
		local goods = Bag:getGoodsById(l)
		local cost = goods.num - m
		table.insert(notices,{goods.edata.name.."-"..cost})
		Bag:updateGoodsNum(l, m)
	end
	popNotices(notices)
	self:setData(tdata)
	local node = display.newNode()
	node.eid = {eid}
	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR,node)
end

--移除界面
function QiangHuaProcessor:onClose(view)

end

return QiangHuaProcessor