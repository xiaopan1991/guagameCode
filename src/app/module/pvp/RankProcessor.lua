--排行处理器
local pvprankitem = import(".ui.pvprankitem")
local RankProcessor = class("RankProcessor", BaseProcessor)

function RankProcessor:ctor()
	-- body
end

function RankProcessor:ListNotification()
	return {
		PVPModule.USER_GET_PVP_RANK,
	}
end

function RankProcessor:handleNotification(notify, data)
	if notify == PVPModule.USER_GET_PVP_RANK then
		self:setData(data.data)
	end
end

--初始化UI显示
-- arg  预留 没用
function RankProcessor:initUI(view)
	self:setView(view)
	self.scrollview = view:getChildByName("ranklist")
	self.toplayer = view:getChildByName("toplayer")
	self.txtTitle = view:getChildByName("txtTitle")
end

function RankProcessor:requestRank()
	local net = {}
	net.method = PVPModule.USER_GET_PVP_RANK
	net.params = {}
	Net.sendhttp(net)
end

--设置数据
function RankProcessor:setData(data)
	-- dump(data.data)
	self.data = data.data
	self.scrollview:removeAllChildren()	
	local num = table.nums(self.data)	
    local rowPadding = 6
	local colNum = 1

	self.txtTitle:setString("排名前"..num.."的玩家")

	local w = 545
	local h = 108
	local leftPadding = (self.scrollview:getContentSize().width - w)/2

	--滚动条宽度
	local innerWidth = self.scrollview:getInnerContainerSize().width
	--设置滚动条内容区域大小
	self.scrollview:setInnerContainerSize(cc.size(innerWidth,math.max(math.ceil(num/colNum) * (h + rowPadding) + 20,self.scrollview:getContentSize().height)))

	local render = nil
	local innerHeight = self.scrollview:getInnerContainerSize().height
	--y起始坐标
	local ystart = innerHeight 

	local i = 1
	for k,v in ipairs(self.data) do
		render = pvprankitem.new()
		render:setData(v)
		render:setPosition(leftPadding ,ystart - math.modf(i/colNum)*(h + rowPadding))
		self.scrollview:addChild(render)
		i = i + 1
	end

	-- --显示自己
	-- self.toplayer:removeAllChildren()
	-- render = pvproleitem.new()
	-- render:setData(self.data.data.my_rank)
	-- render:hideBg()
	-- render:setPosition(10,0)
	-- self.toplayer:addChild(render)
end

return RankProcessor