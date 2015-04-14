--洗练处理器
local ItemFace = require("app.components.ItemFace")
local EquipAttrInfo = require("app.components.EquipAttrInfo")

local XiLianProcessor = class("XiLianProcessor", BaseProcessor)

function XiLianProcessor:ctor()
end

function XiLianProcessor:ListNotification()
	return {
		BagModule.SHOW_EQUIP_XILIAN,
		BagModule.USER_EQUIP_WASHS, --洗练
		IndexModule.MONEY_UPDATE
	}
end

--处理消息
function XiLianProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_EQUIP_XILIAN then
		self.data = data.data
		self:initUI()
		self:setData()
	elseif notify == BagModule.USER_EQUIP_WASHS then
		--todo  数据更新到存储管理器里 刷新界面
		print("洗练结果返回显示")
		-- dump(data.data,"洗练结果返回显示",999)
		local ret = data.data
		if ret.return_code == 0 then
			local eqid = ret.data.eqid
			local info = nil
			for k,v in pairs(ret.data.equips) do
				info = v
			end
			-- local cost = PlayerData:getGold() - ret.data.gold
			popNotices({{"洗练成功！",COLOR_GREEN},{"消耗银两:-"..self.cost}})
			PlayerData:setGold(ret.data.gold)
			Bag:updateEquip(eqid, info) --更新装备
			self.data = info
			self:setData()

			local node = display.newNode()
			node.eid = {eqid}
			Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR,node)
		end
	elseif notify == IndexModule.MONEY_UPDATE then
		if self.view ~= nil then
			if self.data ~= nil then
				local cost = DataConfig:getWashCost(self.data)
				local cfg = DataConfig:getAllConfigMsg()
				local str = addArgsToMsg(cfg["30038"],cost,PlayerData:getGold())
				self.txt2:setString(str)
			end
			
		end
	end
end

--显示洗练界面
function XiLianProcessor:initUI()
	if self.view ~= nil then
		return
	end
	local view  = ResourceManager:widgetFromJsonFile("ui/equipxilian.json")
	self:setView(view)
	view:setName("equipxilian")
	
	local btnClose = view:getChildByName("btnClose") 
	local btnOK    = view:getChildByName("btnOK")
	local txtTitle = view:getChildByName("txtTitle")
	local lbinfo   = view:getChildByName("lbinfo")
	local helpBtn = view:getChildByName("helpBtn")
	local imgType = view:getChildByName("imgType")
	self.imgType = imgType

	self.txt1 = view:getChildByName("txt1")  --下一级强化 主属性
	self.txt2 = view:getChildByName("txt2")  --需要强化精华
	self.txt3 = view:getChildByName("txt3")  --需要银两

	self.txt1:setString("洗练可以重置副属性")
	self.txt2:setString("需要银两：0")
	self.txt3:setString("")

	helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
	btnOK:addTouchEventListener(handler(self,self.onBtnClick))
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	-- txtTitle:setString("装备洗练")
	txtTitle:loadTexture("ui/titlexilian.png")
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["20027"])
	lbinfo:setString(str)

	local itemface_r = ccui.RelativeLayoutParameter:create()
	itemface_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	itemface_r:setMargin({left=80, top=120})

	self.itemface = ItemFace.new()
	-- self.itemface:setPosition(88,530)
	self.itemface:setLayoutParameter(tolua.cast(itemface_r,"ccui.LayoutParameter"))
	view:addChild(self.itemface,2)

	local attr_r = ccui.RelativeLayoutParameter:create()
	attr_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	attr_r:setMargin({left=440, top=150})

	self.attr = EquipAttrInfo.new()
	-- self.attr:setPosition(455,615)
	self.attr.user = "XiLianProcessor"
	self.attr:setLayoutParameter(tolua.cast(attr_r,"ccui.LayoutParameter"))
	view:addChild(self.attr,2)
	
	self:addPopView(view)
end

--设置数据
function XiLianProcessor:setData()
	local pos = string.sub(self.data.eid,3,3)
	self.imgType:loadTexture("ui/e"..pos..".png")

	--dump(self.data)
	self.itemface.showInfo = false
	self.itemface:setData(self.data)
	--属性
	self.attr:setData(self.data)

	local cost = DataConfig:getWashCost(self.data)
	self.cost = cost
	local curgold = PlayerData:getGold()
	if curgold < cost then
		self.txt2:setColor(COLOR_RED)
	end
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30038"],cost,curgold)
	self.txt2:setString(str)
end


function XiLianProcessor:onBtnClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()
	if btnName == "btnClose" then
		--关闭
		self:removePopView(self.view)
	elseif btnName == "btnOK" then
		--确定洗练
		if self.cost > PlayerData:getGold() then
			self.txt2:setColor(COLOR_RED)
			toastNotice("银两不足！")
			return
		end

		if self.data.color[1] < 2 then
			toastNotice("只有蓝色以上装备才能洗练!")
			return
		end
		self:beginXilian()
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("equipment_baptize")
	end
end

--请求洗练
function XiLianProcessor:beginXilian()
	local net = {}
	net.method = BagModule.USER_EQUIP_WASHS
	net.params = {}
	net.params.eqid = self.data.sid
	print("请求洗练")
	Net.sendhttp(net)
end



return XiLianProcessor