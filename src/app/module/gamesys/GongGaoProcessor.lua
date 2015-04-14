--公告处理器
local GongGaoProcessor = class("GongGaoProcessor",BaseProcessor)

GongGaoProcessor.maxSizeHeight = display.height*5/8
--textView距离panel的间隔
GongGaoProcessor.textViewPadX = 45
GongGaoProcessor.textViewPadTopY = 45
GongGaoProcessor.textViewPadBottomY = 120
--文字距离textView的间隔
GongGaoProcessor.textPadX = 20
GongGaoProcessor.textPadY = 20


function GongGaoProcessor:ctor()
	-- change 
	--[[
	self.webview = nil
	]]
end

--self.web = XWebView.new()
--self.web:open("http://192.168.1.114:9999/notice/")
function GongGaoProcessor:ListNotification()
	return {
		GamesysModule.SHOW_GONGGAO
	}
end

function GongGaoProcessor:handleNotification(notify, data)
	if notify == GamesysModule.SHOW_GONGGAO then
		print("GamesysModule.SHOW_GONGGAO")
		self:initUI()
		self:setData()
	end
end

--初始化UI显示
--arg 预留 没用
function GongGaoProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end

	local view = ResourceManager:widgetFromJsonFile("ui/noticepanel.json")
	local btn = view:getChildByName("btnOk")
	local bg = view:getChildByName("smallbg")

	btn:addTouchEventListener(handler(self,self.onBtnClick))
	self:addPopView(view)
	self:setView(view)	
	
	--[[
	local tp = view:convertToWorldSpace(cc.p(320,387))
	local px,py = tp.x,tp.y
	print("px:"..px)
	print("py:"..py)
	--左上角点
	local px1 = px-575/2
	local py1 = py+550/2
	--左下角的点
	local px2 = px+575/2
	local py2 = py-550/2

	-- --转换世界坐标
	local p1 = ccp(px1,py1)
	local p2 = ccp(px2,py2)

	--左上点x比例
	local sx1 = p1.x / display.width
	--左上点y比例
	local sy1 = 1 - p1.y / display.height
	print("p1.y:"..p1.y)
	--右下点x比例
	local sx2 = p2.x / display.width
	--右下点y比例
	local sy2 = 1 - p2.y / display.height

	local wx1 = sx1 * display.widthInPixels
	local wy1 = sy1 * display.heightInPixels
	local wx2 = sx2 * display.widthInPixels
	local wy2 = sy2 * display.heightInPixels
	self.web = XWebView.new()
	
	self.web:open("http://192.168.1.226:9999/notice/",wx1,wy1,wx2-wx1,wy2-wy1)
	-- self.webview:open("http://www.baidu.com",80,600,600,800)
	-- self.webview:open("http://192.168.1.114:9999/notice/",80,600,600,800)
	]]
end

--确定按钮
function GongGaoProcessor:onBtnClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	--[[
	self.web:remove()
	self.web = nil
	]]
	self:removePopView(self.view)
end

--设置数据
function GongGaoProcessor:setData(data)
	
end

return GongGaoProcessor