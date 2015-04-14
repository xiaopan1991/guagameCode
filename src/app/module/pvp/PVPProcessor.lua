--PVP 处理器
local PVPProcessor = class("PVPProcessor", BaseProcessor)

function PVPProcessor:ctor()
	-- body
	self.jjcview = nil
	self.rankview = nil
	self.shopview = nil
	self.curView = nil

	self.viewlist = {}	 --view数组
	self.btnlist  = {}   --按钮
end

function PVPProcessor:ListNotification()
	return {
		PVPModule.SHOW_PVP_PANEL,
		PVPModule.UPDATE_PVP_PANEL,
	}
end

function PVPProcessor:handleNotification(notify, data)
	if notify == PVPModule.SHOW_PVP_PANEL then
		self:initUI()
		self:setData()
	elseif notify == PVPModule.UPDATE_PVP_PANEL then
		self:sendRequest()
	end
end

--初始化UI显示
-- arg  预留 没用
function PVPProcessor:initUI(arg)
	if self.view ~= nil then
		return
	end

	local view = ResourceManager:widgetFromJsonFile("ui/pvppanel.json")
	self.btnJJC = view:getChildByName("btnJJC")
	self.btnRank = view:getChildByName("btnRank")
	self.btnShop = view:getChildByName("btnShop")
	self.btnJJC:addTouchEventListener(handler(self,self.onTabClick))
	self.btnRank:addTouchEventListener(handler(self,self.onTabClick))
	self.btnShop:addTouchEventListener(handler(self,self.onTabClick))

	enableBtnOutLine(self.btnJJC,COMMON_BUTTONS.TAB_BUTTON)
	enableBtnOutLine(self.btnRank,COMMON_BUTTONS.TAB_BUTTON)
	enableBtnOutLine(self.btnShop,COMMON_BUTTONS.TAB_BUTTON)

	self.btnlist["0"] = self.btnJJC
	self.btnlist["1"] = self.btnRank
	self.btnlist["2"] = self.btnShop

	self.det = display.height - 960
	local theight = 766
	if display.height > 960 then
		theight = 766 + self.det
	end
	local size = view:getLayoutSize()
	view:setContentSize(cc.size(size.width,theight))
	local bg = view:getChildByName("imgbg")
	local bgsize = bg:getLayoutSize()
	bg:setContentSize(cc.size(bgsize.width,bgsize.height + self.det))

	self:addMidView(view,true)
	self:setView(view)
	self:tabIndex(0)
end

function PVPProcessor:onTabClick(sender, eventType)
	if eventType ~= TouchEventType.ended then
		return
	end
	local btnName = sender:getName()
	print("btnName "..btnName)
	if btnName == "btnJJC" then
		self:tabIndex(0)
	elseif btnName == "btnRank" then
		self:tabIndex(1)
	elseif btnName == "btnShop" then
		self:tabIndex(2)
	end
end
function PVPProcessor:sendRequest()
	local net = {}
	net.method = PVPModule.USER_GET_MY_RANK
	net.params = {}
	net.params.refresh = false
	Net.sendhttp(net)
end
---切换页签
---index  0 竞技场
---		  1  排名
---		  2   威望商店
function PVPProcessor:tabIndex(index)

	if self.curView ~= nil and self.curView == self.viewlist[tostring(index)] then
		return
	end

	if index == 0 then
		if self.jjcview == nil and tolua.isnull(self.jjcview) then
			self.jjcview = ResourceManager:widgetFromJsonFile("ui/jjcview.json")
			--保存指针
			self.viewlist[tostring(index)] = self.jjcview

			local relarg = ccui.RelativeLayoutParameter:create()
			relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
			local margin = {}
			margin.top = 126
			margin.left = 0
			relarg:setMargin(margin)
			self.jjcview:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))

			local size = self.jjcview:getLayoutSize()
			self.jjcview:setContentSize(cc.size(size.width,size.height + self.det))

			local bgin = self.jjcview:getChildByName("bgin")
			local bginsize = bgin:getContentSize()
			bgin:setContentSize(cc.size(bginsize.width,bginsize.height+self.det))

			local listin = self.jjcview:getChildByName("jjclist")
			local listsize = listin:getContentSize()
			listin:setContentSize(cc.size(listsize.width,listsize.height+self.det))

			local pro = self.module:getProcessorByName("JJCProcessor")
			pro:initUI(self.jjcview)
		end
		self.btnJJC:setTitleColor(cc.c3b(255,255,255))
		self.btnRank:setTitleColor(cc.c3b(255,245,135))
		self.btnShop:setTitleColor(cc.c3b(255,245,135))
		self:tabView(index)
		self:sendRequest()
	elseif index == 1 then
		if self.rankview == nil or tolua.isnull(self.rankview) then
			self.rankview = ResourceManager:widgetFromJsonFile("ui/pvprankview.json")
			self.viewlist[tostring(index)] = self.rankview
			local relarg = ccui.RelativeLayoutParameter:create()
			relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
			local margin = {}
			margin.top = 126
			margin.left = 0
			relarg:setMargin(margin)
			self.rankview:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))
			
			local bgin = self.rankview:getChildByName("bgin")
			local bginsize = bgin:getContentSize()
			bgin:setContentSize(cc.size(bginsize.width,bginsize.height+self.det))

			local listin = self.rankview:getChildByName("ranklist")
			local listsize = listin:getContentSize()
			listin:setContentSize(cc.size(listsize.width,listsize.height+self.det))

			local size = self.rankview:getLayoutSize()
			self.rankview:setContentSize(cc.size(size.width,size.height + self.det))

			local pro = self.module:getProcessorByName("RankProcessor")
			pro:initUI(self.rankview)
		end
		self.btnJJC:setTitleColor(cc.c3b(255,245,135))
		self.btnRank:setTitleColor(cc.c3b(255,255,255))
		self.btnShop:setTitleColor(cc.c3b(255,245,135))
		self:tabView(index)
		local net = {}
		net.method = PVPModule.USER_GET_PVP_RANK
		net.params = {}
		Net.sendhttp(net)
	elseif index == 2 then
		-- weiwangshop.json
		if self.shopview == nil or tolua.isnull(self.shopview) then
			self.shopview = ResourceManager:widgetFromJsonFile("ui/weiwangshop.json")
			self.viewlist[tostring(index)] = self.shopview
			local relarg = ccui.RelativeLayoutParameter:create()
			relarg:setAlign(ccui.RelativeAlign.alignParentTopLeft)
			local margin = {}
			margin.top = 126
			margin.left = 0
			relarg:setMargin(margin)
			self.shopview:setLayoutParameter(tolua.cast(relarg,"ccui.LayoutParameter"))
			
			local bgin = self.shopview:getChildByName("bgin")
			local bginsize = bgin:getContentSize()
			bgin:setContentSize(cc.size(bginsize.width,bginsize.height+self.det))

			local listin = self.shopview:getChildByName("goodslist")
			local listsize = listin:getContentSize()
			listin:setContentSize(cc.size(listsize.width,listsize.height+self.det))

			local size = self.shopview:getLayoutSize()
			self.shopview:setContentSize(cc.size(size.width,size.height + self.det))

			local pro = self.module:getProcessorByName("WeiwangProcessor")
			pro:initUI(self.shopview)
		end
		self.btnJJC:setTitleColor(cc.c3b(255,245,135))
		self.btnRank:setTitleColor(cc.c3b(255,245,135))
		self.btnShop:setTitleColor(cc.c3b(255,255,255))
		self:tabView(index)
	end


	for k,v in pairs(self.btnlist) do
		if k == tostring(index) then
			v:setBright(true)
		else
			v:setBright(false)
		end
	end

end

--tabview 切换显示界面
function PVPProcessor:tabView(index)
	local tview = self.viewlist[tostring(index)]
	self.curView = tview

	if self.curView:getParent() ~= self.view then
		self.view:addChild(tview)
	end

	for k,v in pairs(self.viewlist) do
		if k ~= tostring(index) then
			if not tolua.isnull(v) and v:getParent() ~= nil then
				v:retain()
				v:removeFromParent()
			end
		end
	end

	if index ~= 0 then
	 	local pro1 = self.module:getProcessorByName("JJCProcessor")
		pro1:clearAfterRemove()
	end
end

--设置数据
function PVPProcessor:setData(data)
end

--移除绑定的窗口view
function PVPProcessor:onHideView(view)
	self.curView = nil
	if self.rankview ~= nil and not tolua.isnull(self.rankview) then
		self.rankview:removeFromParent()
		self.rankview = nil
	end

	if self.jjcview ~= nil and not tolua.isnull(self.jjcview) then
		self.jjcview:removeFromParent()
		self.jjcview = nil
	end

	if self.view ~= nil then 
		self.view:removeFromParent(true)
		self.view = nil
	end
	self.isshow = false
	local pro1 = self.module:getProcessorByName("JJCProcessor")
	local pro2 = self.module:getProcessorByName("RankProcessor")
	pro1.view = nil
	pro2.view = nil
	pro1:clearAfterRemove()
end

return PVPProcessor