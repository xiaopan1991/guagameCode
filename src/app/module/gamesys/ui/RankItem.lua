local RankItem = class("RankItem", function()
	local layout = ccui.Layout:create()
	layout:setContentSize(cc.size(610,140))
	return layout
end)
-- 苦逼死了 这些数据要自己配 策划不懂吧 我不说什么
-- 后端你难道也不懂吗 你学过数据库吗? 你知道什么交关系型数据库吗?
-- power_rank_list 这个东西是啥 为什么不用数据库主键
-- 有主键以后 图标名称 rank_icon_主键.png 艺术字名称 title_rank_主键.png
-- 可以想想到 策划在后台界面添加一行数据 配置这些字段 然后上传两张图片
-- 图片名称生成rank_icon_主键.png 然后热更到用户本地
RankItem.typeSort = {"power_rank_list", "gaibang_power_rank_list", "wudang_power_rank_list", "emei_power_rank_list", "lv_rank_list"}
RankItem.typeData = {
	power_rank_list = {
		name = "战力榜", -- 榜单名称
		icon = "ui/rank_icon_power.png", -- 图标
		title = '30096', -- 榜单称号 丐帮首席弟子:@0
		color = cc.c3b(209, 47, 255), -- 榜单称号颜色

		top_img = "ui/titlerankpower.png", -- 列表头部美术字体
		info = "20068", -- 列表介绍文字 全服战力前二十名
	},
	gaibang_power_rank_list = {
		name = "丐帮高手榜",
		icon = "ui/rank_icon_gaibang.png",
		title = '30093',
		color = cc.c3b(255, 53, 53),

		top_img = "ui/titlerankgaibang.png",
		info = "20074",
	},
	emei_power_rank_list = {
		name = "峨眉高手榜",
		icon = "ui/rank_icon_emei.png",
		title = '30095',
		color = cc.c3b(68, 220, 33),

		top_img = "ui/titlerankemei.png",
		info = "20072",
	},
	wudang_power_rank_list = {
		name = "武当高手榜",
		icon = "ui/rank_icon_wudang.png",
		title = '30094',
		color = cc.c3b(1, 144, 254),

		top_img = "ui/titlerankwudang.png",
		info = "20073",
	},

	lv_rank_list = {
		name = "等级榜",
		icon = "ui/rank_icon_lv.png",
		title = '30098',
		color = cc.c3b(209, 47, 255),

		top_img = "ui/titleranklv.png",
		info = "20069",
	},

	pvp_rank_list = {
		name = "比武榜",
		icon = "ui/rank_icon_pvp.png",
		title = '30099',
		color = cc.c3b(255, 240, 1),

		top_img = "ui/titlerankpvp.png",
		info = "20070",
	},

	gang_rank_list = {
		name = "帮派榜",
		icon = "ui/rank_icon_gang.png",
		title = '30097',
		color = cc.c3b(255, 240, 1),

		top_img = "ui/titlerankgang.png",
		info = "20071",
	},
}
function RankItem:ctor()
	if(not RankItem.view) then
		RankItem.view = ResourceManager:widgetFromJsonFile("ui/rankitem.json")
		RankItem.view:retain()		
	end

	self.view = RankItem.view:clone()
	self.imgBg = self.view:getChildByName("imgBg")
	self.imgIcon = self.view:getChildByName("imgIcon")
	self.imgHead = self.view:getChildByName("imgHead")
	self.imgHeadBorder = self.view:getChildByName("imgHeadBorder")
	self.imgNameBg = self.view:getChildByName("imgNameBg")
	self.txtName = self.view:getChildByName("txtName")
	self.imgPowerBg = self.view:getChildByName("imgPowerBg")
	self.txtPower = self.view:getChildByName("txtPower")
	self.btnMore = self.view:getChildByName("btnMore")

	self.imgHeadBorder:setTouchEnabled(true)

	self.imgHeadBorder:addTouchEventListener(handler(self, self.onClick))
	self.btnMore:addTouchEventListener(handler(self, self.onClick))

	self:addChild(self.view)

	enableBtnOutLine(self.btnMore, COMMON_BUTTONS.BLUE_BUTTON)	
end
function RankItem:setData(data)
	self.data = data

	local cfg = DataConfig:getAllConfigMsg()
	local typedata = RankItem.typeData[data.type]

	self.imgIcon:loadTexture(typedata.icon)
	self.imgHead:loadTexture("ui/head/"..data.hero_type..".png")
	self.txtName:setString(addArgsToMsg(cfg[typedata.title], data.name))
	self.txtName:setColor(typedata.color)
	if data.type == "lv_rank_list" then
		self.txtPower:setString("等级："..data.lv)
	else
		self.txtPower:setString("战力："..data.power)
	end
end
function RankItem:onClick(sender,eventType)
	if  eventType ~= TouchEventType.ended then
		return
	end

	local btn = tolua.cast(sender,"ccui.Button")
	local btnName = btn:getName()

	if btnName == "imgHeadBorder" or btnName == "btnMore" then
		local net = {}
		net.method = GamesysModule.USER_GET_RANK_ALL_LIST
		net.params = {}
		net.params._type = self.data.type
		Net.sendhttp(net)
	end
end
return RankItem