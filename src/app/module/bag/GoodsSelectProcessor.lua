-- 通用道具选择界面
-- Author: whe
local ItemFace = require("app.components.ItemFace")
local GoodsSelectProcessor = class("GoodsSelectProcessor", BaseProcessor)

function GoodsSelectProcessor:ctor()
	-- body
end

function GoodsSelectProcessor:ListNotification()
	return {
		BagModule.SHOW_GOODS_SELECT
	}
end

function GoodsSelectProcessor:handleNotification(notify, data)
	if notify == BagModule.SHOW_GOODS_SELECT then
		--data.type 区分道具类型 all就是全部 
		-- dump(data.data)
		self.data = data.data 
		self:initUI()
		self:setData()
	end
end

--初始化UI显示
-- arg  预留 没用
function GoodsSelectProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end

	--加载界面
	local view = ResourceManager:widgetFromJsonFile("ui/goodselect.json")
	local txtInfo = view:getChildByName("txtInfo")
	local btnClose = view:getChildByName("btnClose")
	self.goodlist = view:getChildByName("goodlist")

	btnClose:addTouchEventListener(handler(self,self.onBtnClick))
	txtInfo:setString("点击你想要的宝石即可镶嵌到装备")

	self:setView(view)
	self:addPopView(view)
end

--设置数据
function GoodsSelectProcessor:setData()
	local goods = Bag:getGoodsByType(self.data.type)
	-- dump(goods,"筛选出来的宝石",999)
	local leftPadding = 20
	local rowPadding = 24
	local colPadding = 24
	local colNum = 5

	local w = 83
	local h = 83

	local item = nil
	local index = 0

	--数据长度
	local tlen = table.nums(goods)
	print("背包数据长度"..tlen)
	--滚动条宽度
	local innerWidth = self.goodlist:getInnerContainerSize().width
	--设置滚动条内容区域大小
	self.goodlist:setInnerContainerSize(cc.size(innerWidth,math.ceil(tlen/colNum) * (h + rowPadding)))
	--内容高度
	local innerHeight = self.goodlist:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight - h

	--排序
	local color2value = {10, 20, 40, 30}
	table.sort(goods,function(a,b) 
		-- if a.num > b.num then
		--        return true
		--    elseif a.num < b.num then
		--        return false
		--    else
		--        --eid
		--        local ea = string.sub(a.eid,2,5)
		--        local eb = string.sub(b.eid,2,5)
		--        if tonumber(ea) < tonumber(eb) then
		--            return false
		--        else
		--            return true
		--        end
		--    end
		local a_color = tonumber(string.sub(a.eid,3,3))+1
		local b_color = tonumber(string.sub(b.eid,3,3))+1
		if(a_color ~= b_color) then
			return a_color < b_color
		end
		return a.eid < b.eid
 	end)
	
	for k,v in pairs(goods) do
		-- print(k, v.eid, v.edata.name, v.edata.lv)
		item = ItemFace.new()
		item:setTouchEnabled(true)
		item:addTouchEventListener(handler(self,self.onItemClick))
		item.showInfo = false
		item.showname = true
		item:setData(v)
		item:setPosition((index % colNum) * (w + colPadding)+ leftPadding , ystart - math.modf(index/colNum) * (h + rowPadding))
		item:setScale(0.8)
		self.goodlist:addChild(item)
		index = index + 1
	end
end
--item点击
function GoodsSelectProcessor:onItemClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	if self.data.callback~= nil then
		local data = sender.data
		self.data.callback(data)
	end
	self:removePopView(self.view)
end

--关闭按钮点击
function GoodsSelectProcessor:onBtnClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end

	self:removePopView(self.view)
end

return GoodsSelectProcessor