--吞噬处理器
local TunShiProcessor = class("TunShiProcessor", BaseProcessor)
local ItemFace = require("app.components.ItemFace")

function TunShiProcessor:ctor()
	-- body
end

function TunShiProcessor:ListNotification()
	return {
		BagModule.SHOW_TUN_SHI,
		BagModule.USER_EQUIP_GOD_DEVOUR,
		IndexModule.MONEY_UPDATE
	}
end

function TunShiProcessor:handleNotification(notify, data)
	print("receive")
	if notify == BagModule.SHOW_TUN_SHI then
		self:onSetView()
		self:onSetData(data.data)
	elseif notify ==  BagModule.USER_EQUIP_GOD_DEVOUR then
		self:handleTunShiData(data.data)
	elseif notify == IndexModule.MONEY_UPDATE then
		if self.view == nil then 
    		return
  		end
		self:calcCost()
	end
end
--显示吞噬界面
function TunShiProcessor:onSetView()
	if self.view ~= nil then
     	return
    end
    --tuoshi就是tunshi
    local tuoshiPanel = ResourceManager:widgetFromJsonFile("ui/tuoshipanel.json")
	local btnClose = tuoshiPanel:getChildByName("btnClose")
	local btnTunShi = tuoshiPanel:getChildByName("btnTunShi")
	local btnAuto = tuoshiPanel:getChildByName("btnAuto")
	local helpBtn = tuoshiPanel:getChildByName("helpBtn")
	local lbCost = tuoshiPanel:getChildByName("lbCost")
	lbCost:setString("")
	self.txtlv = tuoshiPanel:getChildByName("lv")
	self.jingyan = tuoshiPanel:getChildByName("jingyan")
	self.lbCost = lbCost
	self.progressBar = tuoshiPanel:getChildByName("progressBar")
	self.progressBar:setPercent(0)
	local expBg = tuoshiPanel:getChildByName("expBg")
	self.txtPro = tuoshiPanel:getChildByName("txtPro")  --神奇属性
	
	btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	btnTunShi:addTouchEventListener(handler(self,self.onBtnClick))
	btnAuto:addTouchEventListener(handler(self,self.onBtnClick))
	helpBtn:addTouchEventListener(handler(self,self.onBtnClick))

	local leftPadding = 63
	local rowPadding = 35
	local colPadding = 330
	local colNum = 2

	local w = 84
	local h = 84
	self.items = {}

	--y起始坐标
	local ystart = 210
	self.item = nil
	for i = 0, 5 do
		local item_r = ccui.RelativeLayoutParameter:create()
		item_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
		item_r:setMargin({left=(i % colNum) * (w + colPadding)+ leftPadding, top=ystart + math.modf(i/colNum) * (h + rowPadding)})

		-- (i % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(i/colNum) * (h + rowPadding)

		-- self.item:setLayoutParameter(tolua.cast(item_r,"ccui.LayoutParameter"))

   	 	self.item = ItemFace.new()
   	 	self.item.defaultimg = "ui/icon_18.png"
   		self.items[#self.items + 1] = self.item
   	 	self.item.showInfo = false
		self.item:setData()
		-- self.item:setPosition((i % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(i/colNum) * (h + rowPadding))
		self.item:setLayoutParameter(tolua.cast(item_r,"ccui.LayoutParameter"))
		--self.item:setScale(0.6)
		self.item:setTouchEnabled(true)
		self.item:addTouchEventListener(handler(self,self.onItemClick))
		tuoshiPanel:addChild(self.item)
		i = i + 1
	end

	--装备格子
	local itemface_r = ccui.RelativeLayoutParameter:create()
	itemface_r:setAlign(ccui.RelativeAlign.alignParentTopLeft)
	itemface_r:setMargin({left=271, top=332})

	local itemface = ItemFace.new()
	itemface.showInfo = false --禁用鼠标事件
	-- itemface:setPosition(275,330)--265,310
	itemface:setLayoutParameter(tolua.cast(itemface_r,"ccui.LayoutParameter"))
	tuoshiPanel:addChild(itemface)
	self.itemface = itemface

	--清空当前的数据显示
	self.select = {}

	self:setView(tuoshiPanel)
	self:addPopView(tuoshiPanel)
end

--数据
function TunShiProcessor:onSetData(data)
	--dump(data)
	self.data = data
	self.itemface:setData(data)
	
	self.lvv = data.god[1]
	self.currentExp = data.god[2]
	-- local tol = DataConfig:getGodLvExp(lvv)
	-- self.tol = tol--如果为0的话 就是满级了
	self.tol = DataConfig:getGodLvExp(self.lvv)
	self:onTxtExpChange(self.lvv,self.tol,self.currentExp)
	Observer.sendNotification(BagModule.EQUIP_NUM_UPDATE) --数量更新

	self:calcCost()
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
	self.txtPro:setString(name)	
end

--按钮的点击事件
function TunShiProcessor:onBtnClick(sender,eventType)
	-- 触摸完毕再触发事件
	if  eventType ~= TouchEventType.ended then 
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "btnClose" then
		self:removePopView(self.view)
    elseif btnName == "btnTunShi" then
    	if #self.select == 0 then
			toastNotice("请选择吞噬装备！")
			return
		end
		--{'eqids': ['e21','e22'], 'eqid': 'e15'}
    	--请求吞噬
    	if self.tol == 0 then
    		toastNotice("神器已经升到满级！")
    		return
    	end

    	if self.cost > PlayerData:getGold() then
    		toastNotice("银两不足！")
    		return
    	end
    	for k,v in pairs(self.itemEquips) do
    		if #v.god == 4 then
    		--提示框
		    	local btns = {{text = "取消",skin = 2},{text = "确定",skin = 1,callback = handler(self,self.sendTunshiGod)}}
				local alert = GameAlert.new()
				local cfg = DataConfig:getAllConfigMsg()
		    	local str = addArgsToMsg(cfg["20029"])
				alert:pop(str,"ui/titlenotice.png",btns)
				return
			end
    	end
		self:sendTunshiGod()    	
    elseif btnName == "btnAuto" then
    	self:onAutoEquip()
    elseif btnName == "helpBtn" then
		local alert = GameAlert.new()
		alert:popHelp("Artifact_phagocytosis")
	end
end
function TunShiProcessor:sendTunshiGod()
	local data = {}
    data.method = BagModule.USER_EQUIP_GOD_DEVOUR
    data.params = {}
    data.params.eqids = self.select
    data.params.eqid = self.data.sid
    Net.sendhttp(data)
end
--自动筛选
function TunShiProcessor:onAutoEquip()
	--先清除一下
	for k,v in pairs(self.items) do
		v:setData()
	end
	--清空选中的装备数据
	self.select = {}
	self.itemEquips = Bag:getTunShiEquips(self.data.sid,6)
	if table.nums(self.itemEquips) == 0 then
		toastNotice("没有可以吞噬的装备！")
		return
	end
	local index = 1
	for k,v in pairs(self.itemEquips) do
		self.items[index]:setData(v)
		self.select[index] = v.sid
		index = index + 1
	end

	self:calcCost()
end
--吞噬返回的数据
function TunShiProcessor:handleTunShiData(data)
	--dump(data,"吞噬返回的数据",999)
	local eqid = data.data.eqid
	local equips = data.data.equips
	local eqids = data.data.eqids
	local gold = data.data.gold
	local bag = data.data.bag --返还道具
	local addPith = data.data["I0001"]
	--返还的道具
	if bag ~= nil then
		for k,v in pairs(bag) do
			Bag:updateGoodsNum(k,v)
		end
	end
	--移除吞噬掉的装备
	Bag:removeEquips(eqids)
	--清空控件
	for k,v in pairs(self.items) do
		v:setData()
	end
	
	--吞噬后的装备数据
	local edata = equips[eqid]
	Bag:updateEquip(eqid,edata)
    
	local v = Bag:getEquipById(eqid)
	local node = display.newNode()
	node.eid = {eqid}
	Observer.sendNotification(BagModule.UPDATE_EQUIP_ATTR,node) --属性更新
	local notices = {{"消耗银两：-"..self.cost}}
	if addPith ~= 0  then
		table.insert(notices,{"获得强化精华数量："..addPith,COLOR_GREEN})
	end
	popNotices(notices)
	--重新计算银两消耗
    self.select = {}
    PlayerData:setGold(gold)

    self:onSetData(v)
end
--文本和进度条的变化
--lv等级
--tol总经验
--currentExp当前经验
function TunShiProcessor:onTxtExpChange(lv,tol,currentExp)
	self.txtlv:setString("神器等级：Lv "..lv)
	self.percent = 0
	if tol ~= 0 then
		self.percent = currentExp/tol*100
	end
	self.progressBar:setPercent(self.percent)
	self.jingyan:setString("经验："..currentExp.."/"..tol)
end
--选择装备格子
function TunShiProcessor:onItemClick(sender,eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
    print(sender:getName())
    print(sender:getDescription())
	local node = display.newNode()
	node.data = self.data
	node.type = "check"
	node.select = self.select
	node.user = "TunShiProcessor"
	node.callback = handler(self,self.onSelectCallBack)
	Observer.sendNotification(BagModule.SHOW_COMMON_EQUIP_SELECT, node)
end
--选择装备返回
function TunShiProcessor:onSelectCallBack(data)
	--dump(data,"选择数据返回")
	for k,v in pairs(self.items) do
		v:setData()
	end
	--清空选中的装备数据
	self.select = {}
	self.itemEquips = {}
	for kk,vv in pairs(data) do
		self.itemEquips[#self.itemEquips + 1] = Bag:getEquipById(vv)
	end
	local index = 1
	for k,v in pairs(self.itemEquips) do
		self.items[index]:setData(v)
		self.select[index] = v.sid
		index = index + 1
	end

	self:calcCost()
end

--计算银两消耗
function TunShiProcessor:calcCost()
	local eid = self.data.eid
	local lv1 = tonumber(string.sub(eid,4,6))
	local pos1 = tonumber(string.sub(eid,3,3))
	local star1 = self.data.god[1]

	local cost = 0

	local lv2 = nil
	local pos2 = nil
	local star2 = nil
	local temp = nil
	-- local len = table.nums(self.select)
	-- dump("len"..len)
	if table.nums(self.select) ~= 0 then
		for k,v in pairs(self.select) do
			temp = Bag:getEquipById(v)
			lv2 = tonumber(string.sub(temp.eid,4,6))
			pos2 = tonumber(string.sub(temp.eid,3,3))
			star2 = temp.god[1]
			cost = cost + DataConfig:getGodTunshiCost(lv1, star1, pos1, lv2, star2, pos2)
		end
	end
	self.cost = cost
	local currGold = PlayerData:getGold()
	if currGold < self.cost then
		self.lbCost:setColor(COLOR_RED)
	end
	local cfg = DataConfig:getAllConfigMsg()
	local str = addArgsToMsg(cfg["30038"],self.cost,currGold)
	self.lbCost:setString(str)
	--print("吞噬消费银两："..cost)
end

return TunShiProcessor
