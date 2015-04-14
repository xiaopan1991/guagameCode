local RankListItem = class("RankListItem", function()
	local layout = ccui.Layout:create()
	layout:setContentSize(cc.size(610,125))
	return layout
end)
function RankListItem:ctor()
	if(not RankListItem.view) then
		RankListItem.view = ResourceManager:widgetFromJsonFile("ui/ranklistitem.json")
		RankListItem.view:retain()		
	end

	self.view = RankListItem.view:clone()
	self.imgBg = self.view:getChildByName("imgBg")
	self.imgHead = self.view:getChildByName("imgHead")
	self.imgHeadBorder = self.view:getChildByName("imgHeadBorder")
	self.imgType = self.view:getChildByName("imgType")
	self.txtLv = self.view:getChildByName("txtLv")
	self.imgInfoBg = self.view:getChildByName("imgInfoBg")
	self.imgRankBg = self.view:getChildByName("imgRankBg")
	self.imgRank = self.view:getChildByName("imgRank")

	self.imgHeadBorder:setTouchEnabled(true)
	self.txtLv:enableOutline(cc.c4b(0,0,0,255), 2)

	self.imgHeadBorder:addTouchEventListener(handler(self, self.onClick))

	-- 介绍
	self.text = ccui.RichText:create()
	self.text:setContentSize(cc.size(320, 90))
	self.text:ignoreContentAdaptWithSize(false)
	self.text:setPosition(305, 62)
	self.view:addChild(self.text)

	print(self.text:getAnchorPoint().x, self.text:getAnchorPoint().y)

	self:addChild(self.view)
end
function RankListItem:setDataType(datatype)
	self.datatype = datatype
end
function RankListItem:setData(data)
	self.data = data
	-- dump(data)

	self.imgHead:loadTexture("ui/head/"..data.hero_type..".png")
	self.imgType:loadTexture("ui/type/"..data.hero_type..".png")
	self.txtLv:setString("Lv."..data.lv)

	if data.rank <= 3 then
		self.imgRank:loadTexture("ui/pvp_rank_"..data.rank..".png")
	else
		self.imgRank:setVisible(false)
	end

	self.text:pushBackElement(ccui.RichElementText:create(1, display.COLOR_WHITE, 255, data.name.."\n", DEFAULT_FONT, 18))

	self.text:pushBackElement(ccui.RichElementText:create(2, display.COLOR_WHITE, 255, "排名: ", DEFAULT_FONT, 18))
	self.text:pushBackElement(ccui.RichElementText:create(3, display.COLOR_YELLOW, 255, data.rank.."       ", DEFAULT_FONT, 18))
	-- power_rank_list gaibang_power_rank_list emei_power_rank_list wudang_power_rank_list
	-- lv_rank_list pvp_rank_list gang_rank_list
	if self.datatype == "lv_rank_list" then -- 等级榜
		self.text:pushBackElement(ccui.RichElementText:create(4, display.COLOR_WHITE, 255, "经验: ", DEFAULT_FONT, 18))
		self.text:pushBackElement(ccui.RichElementText:create(5, display.COLOR_YELLOW, 255, data.exp, DEFAULT_FONT, 18))
	else
		self.text:pushBackElement(ccui.RichElementText:create(4, display.COLOR_WHITE, 255, "战力: ", DEFAULT_FONT, 18))
		self.text:pushBackElement(ccui.RichElementText:create(5, display.COLOR_YELLOW, 255, data.power, DEFAULT_FONT, 18))
	end
	self.text:pushBackElement(ccui.RichElementText:create(6, display.COLOR_WHITE, 255, " \n", DEFAULT_FONT, 18))

	self.text:pushBackElement(ccui.RichElementText:create(7, display.COLOR_WHITE, 255, data.signature, DEFAULT_FONT, 18))
end
function RankListItem:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "imgHeadBorder" then
		local net = {}
		net.method = BagModule.USER_GET_USER_INFO
		net.params = {}
		net.params.uid = self.data.uid
		Net.sendhttp(net)
	end
end
return RankListItem