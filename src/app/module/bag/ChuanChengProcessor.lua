--传承处理器
local ChuanChengProcessor = class("ChuanChengProcessor", BaseProcessor)
local ItemFace = require("app.components.ItemFace")

function ChuanChengProcessor:ctor()
	-- body
end

function ChuanChengProcessor:ListNotification()
	return {
		BagModule.SHOW_CHUAN_CHENG,
		BagModule.USER_EQUIP_GOD_INHERIT,
		IndexModule.MONEY_UPDATE
	}
end

function ChuanChengProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_CHUAN_CHENG then 
		self:initUI()
		self:onSetData(data.data)
	elseif notify == BagModule.USER_EQUIP_GOD_INHERIT then
		--传承返回的数据
		self:handleChuanChengData(data.data)
	elseif notify == IndexModule.MONEY_UPDATE then
		self:onStCost(0)
	end
end
--显示传承界面
function ChuanChengProcessor:initUI()
    if self.view ~= nil then
       return
    end
	local chuanchengPanel = ResourceManager:widgetFromJsonFile("ui/chuanchengpanel.json")
	local btnClose = chuanchengPanel:getChildByName("btnClose")
	local btnChuanCheng = chuanchengPanel:getChildByName("btnChuanCheng")
	local helpBtn = chuanchengPanel:getChildByName("helpBtn")
	
	self.txtInfo = chuanchengPanel:getChildByName("txtInfo")
	self.txtCoin = chuanchengPanel:getChildByName("txtCoin")

	--装备格子 左边的
	local itemface_r = ccui.RelativeLayoutParameter:create()
	itemface_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	itemface_r:setMargin({left=120, top=210})

	local itemface = ItemFace.new()
	itemface.showInfo = false --禁用鼠标事件
	-- itemface:setPosition(120,450)
	itemface:setLayoutParameter(tolua.cast(itemface_r,"ccui.LayoutParameter"))
	chuanchengPanel:addChild(itemface)
	self.itemface = itemface
	--右边的
	local itemface2_r = ccui.RelativeLayoutParameter:create()
	itemface2_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	itemface2_r:setMargin({left=420, top=210})

	local itemface2 = ItemFace.new()
	itemface2.defaultimg = "ui/icon_18.png"
	itemface2.showInfo = false --禁用鼠标事件
	-- itemface2:setPosition(420,450)
	itemface2:setLayoutParameter(tolua.cast(itemface2_r,"ccui.LayoutParameter"))
	chuanchengPanel:addChild(itemface2)
	itemface2:setData()
	itemface2:setTouchEnabled(true)
	itemface2:addTouchEventListener(handler(self,self.onItemClick))
	self.itemface2 = itemface2

    --按钮
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	btnChuanCheng:addTouchEventListener(handler(self,self.onBtnClick))
	helpBtn:addTouchEventListener(handler(self,self.onBtnClick))
	self:setView(chuanchengPanel)
	self:addPopView(chuanchengPanel)
end
--数据
function ChuanChengProcessor:onSetData(data)
	-- dump(data)
	self.data = data
	self.itemface:setData(data)

	--获取神属性的配置
	local lv = data.god[1]
	local godname = data.god[3]
		
	local godcfg = DataConfig:getGodCfg(godname)
	--神属性名字  exp 普通攻击吸血
	local name
	if("ignore_armor" == godname or "ignore_deff" == godname or "ignore_adf" == godname) then
		name = godcfg.name .. " +"..(godcfg.lv_base[1]*lv + godcfg.lv_base[2])
	else
		name = godcfg.name .. " +"..((godcfg.lv_base[1]*lv + godcfg.lv_base[2])*100) .."%"
	end
	for i=4,#data.god do
		godname = data.god[i]
		godcfg = DataConfig:getGodCfg(godname)
		if("ignore_armor" == godname or "ignore_deff" == godname or "ignore_adf" == godname) then
			name = name.."\n"..godcfg.name .. " +"..(godcfg.lv_base[1]*lv + godcfg.lv_base[2])
		else
			name = name.."\n"..godcfg.name .. " +"..((godcfg.lv_base[1]*lv + godcfg.lv_base[2])*100) .."%"
		end
	end
	self.txtInfo:setString(name)
	self.cost = 0	
	self:onStCost(0)

	
end
--按钮的点击事件
function ChuanChengProcessor:onBtnClick(sender,eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnClose" then
		self:removePopView(self.view)
    elseif btnName == "btnChuanCheng" then
    	if self.data2 == nil then
    		notice("请选择要传承的装备!")
    		return
    	end

    	if #self.data2.god > 0 then
    		notice("传承失败,已经是神器了!")
    		return
    	end
    	local curgold = PlayerData:getGold()
		if curgold < self.cost then
			self.txtCoin:setColor(COLOR_RED)
			notice("银两不足")
    		return
		end
    	--发送消息
    	local data = {}
	    data.method = BagModule.USER_EQUIP_GOD_INHERIT
	    data.params = {}
	    data.params.from_eqid = self.data.sid
	    data.params.to_eqid = self.data2.sid
	    Net.sendhttp(data)
	elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("Artifact_inherit")
	end
end

--选择装备点击
function ChuanChengProcessor:onItemClick(sender, eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end
	local node = display.newNode()
	node.data = self.data
	node.callback = handler(self,self.onSelectCallBack)
	node.type = "check" --单选类型 条子上显示按钮
	node.user = "ChuanChengProcessor"

	Observer.sendNotification(BagModule.SHOW_COMMON_EQUIP_SELECT, node)
end

--装备选择
function ChuanChengProcessor:onSelectCallBack(data)
	--dump(data,"装备选择返回",999)
	if #data ~= 0 then
		self.data2 = Bag:getEquipById(data[1])
		self.itemface2:setData(self.data2)
        -- local v = self.data
	    local lvdex = self.data.god[1]
		local cost = DataConfig:getGodCost(self.data.eid,self.data2.eid,lvdex)
		self.cost = cost
		--dump(cost)
		self:onStCost(cost)
	end
end
--需要花费银两
function ChuanChengProcessor:onStCost(cost)
	if self.view == nil then 
    	return
  	end
  	cost = self.cost
  	local curgold = PlayerData:getGold()
	if curgold < cost then
		self.txtCoin:setColor(COLOR_RED)
	end
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30038"],cost,curgold)
	self.txtCoin:setString(str)
end

--传承返回的数据
function ChuanChengProcessor:handleChuanChengData(data)
 	--dump(data.data)
 	local toEqid = data.data.to_eqid
 	local fromEqid = data.data.from_eqid
 	local eqTo = data.data.equips[toEqid]
 	local eqFrom = data.data.equips[fromEqid]
 	--更新数据
 	Bag:updateEquip(toEqid,eqTo)
 	Bag:updateEquip(fromEqid,eqFrom)
 	--显示装备
 	self.itemface:setData(eqFrom)
 	self.itemface2:setData(eqTo)
 	popNotices({{"传承成功!",COLOR_GREEN},{"消耗银两:-"..self.cost}})
 	self.itemface2:setTouchEnabled(false)

 	self.cost = 0
 	PlayerData:setGold(data.data.gold)

 	self.data = eqFrom
 	self.data2 = eqTo

 	local node = display.newNode()
 	node.eid = {toEqid,fromEqid}
 	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR,node)
end


return ChuanChengProcessor