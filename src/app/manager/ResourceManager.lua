--
-- Author: Your Name
-- Date: 2015-01-28 10:25:02
--
local ItemFace = require("app.components.ItemFace")
local ResourceManager = class("ResourceManager")
function ResourceManager:ctor()
	self.curLoadIndex = 1
	self.cacheDic = {}
	self.beCacheDic = {}
	self.cacheList = 
	{--
		"ui/itemface.json",
		"ui/awardpanel.json",
		"ui/awardtaskview.json",
		"ui/awardview.json",
		"ui/bagpanel.json",
		--"ui/bossheadui.json",
		--"ui/changetitlename.json",
		--"ui/chargepanel.json",
		--"ui/chatplayer.json",
		--"ui/chatplayeritem.json",
		--"ui/chatui.json",
		--"ui/chuanchengpanel.json",
		--"ui/dazaogod.json",
		--"ui/dazaogoditem.json",
		--"ui/dazaopanel.json",
		--"ui/equipinfo.json",
		"ui/equippanel.json",
		--"ui/equipselect.json",
		"ui/equipselectitem.json",
		"ui/equipshai.json",
		"ui/equipui.json",
		--"ui/equipxiangqian.json",
		--"ui/equipxilian.json",
		"ui/follower.json",
		--"ui/followercommonfoster.json",
		--"ui/followerfoster.json",
		--"ui/followerskill.json",
		--"ui/followerskillitem.json",
		--"ui/followerspecialfoster.json",
		--"ui/gamealert.json",
		--"ui/gamesetpanel.json",
		--"ui/GemUp.json",
		--"ui/goodselect.json",
		--"ui/goodsinfo.json",
		"ui/goodsitem.json",
		"ui/guajiui.json",
		"ui/homepage.json",
		"ui/itemaward.json",
		"ui/itemmap.json",
		--"ui/jjcview.json",
		--"ui/login.json",
		--"ui/loginloading.json",
		--"ui/lotsellpanel.json",
		--"ui/mailitem.json",
		"ui/maintop.json",
		"ui/mappanel.json",
		--"ui/maxmaptip.json",
		--"ui/monsterheadui.json",
		--"ui/MultiBattleOneResult.json",
		--"ui/MultiBattleOneResultCell.json",
		--"ui/MultiBattlePlayerCell.json",
		--"ui/MultiBattlePlayerList.json",
		--"ui/MultiBattleResult.json",
		--"ui/MultiBattleResultCell.json",
		--"ui/MultiBattleUI.json",
		--"ui/nameItem.json",
		--"ui/noticepanel.json",
		"ui/payInfo.json",
		"ui/payitem.json",
		--"ui/personinfo.json",
		--"ui/playerheadui.json",
		--"ui/pvppanel.json",
		--"ui/pvprankview.json",
		--"ui/pvproleitem.json",
		--"ui/role.json",--这种不需要缓存
		--"ui/ronglian.json",
		--"ui/serveritem.json",
		--"ui/serverlist.json",
		"ui/shopdijing.json",
		"ui/shopgold.json",
		"ui/shopmain.json",
		--"ui/skillitem.json",
		--"ui/skillpanel.json",
		--"ui/skillpvpitem.json",
		--"ui/skillpvppanel.json",
		--"ui/smallheadui.json",
		--"ui/specialitem.json",
		"ui/toolbar.json",
		--"ui/tuoshipanel.json",
		--"ui/vippanel.json",
		--"ui/weiwangitem.json",
		--"ui/weiwangshop.json",
	}
	--self.cacheList = {}
	for i,v in ipairs(self.cacheList) do
		self.beCacheDic[v] = true
	end
end
function ResourceManager:preLoadJson()
	if(self.curLoadIndex <= #self.cacheList) then
		local jsonpath = self.cacheList[self.curLoadIndex]
		if(not self.cacheDic[jsonpath]) then
			local widget = ccs.GUIReader:getInstance():widgetFromJsonFile(jsonpath)
			widget:retain()
			self.cacheDic[jsonpath] = widget
		end
		if(ItemFace:getPool():getLen() < 200) then
			ItemFace.addToPool(5)--增加5个
		end
		--发消息
		local node3 = display.newNode()
		node3.data = {}

		node3.data.per = math.floor((self.curLoadIndex-0.5+math.random())*87/#self.cacheList+10)
		node3.data.info = "初始化数据"
		Observer.sendNotification(LoginModule.UPDATE_LOGIN_LOADING,node3)


		self.curLoadIndex = self.curLoadIndex + 1
		scheduler.performWithDelayGlobal(handler(self,self.preLoadJson), 0.1)
	else
		Observer.sendNotification(LoginModule.JSON_LOAD_COMPLETED)
	end
end
function ResourceManager:clear()
	self.curLoadIndex = 1
end
function ResourceManager:widgetFromJsonFile(jsonpath)
	local widget
	if(self.beCacheDic[jsonpath]) then
		return (self.cacheDic[jsonpath]:clone())	
	end
	widget = ccs.GUIReader:getInstance():widgetFromJsonFile(jsonpath)
	return widget
end
return ResourceManager