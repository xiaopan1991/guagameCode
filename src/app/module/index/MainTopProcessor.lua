--主界面顶部的面板处理器
--显示玩家昵称 等级 经验 银两 元宝
local MainTopProcessor = class("MainTopProcessor", BaseProcessor)

function MainTopProcessor:ctor()
	self.name = "MainTopProcessor"
end
--关心的消息列表
function MainTopProcessor:ListNotification()
	return {
	    IndexModule.SHOW_MAIN_TOP,
      IndexModule.MONEY_UPDATE,
      IndexModule.EXP_UPDATE,
      IndexModule.LEVEL_UPDATE,
      IndexModule.NAME_UPDATE
    }
end

--消息处理
--notify 	消息名
--data 		数据
function MainTopProcessor:handleNotification(notify, data)
  if notify == IndexModule.SHOW_MAIN_TOP then
    self:initUI(data)
    self:setData()
  elseif notify == IndexModule.MONEY_UPDATE then
    self:updateMoney()
  elseif notify == IndexModule.EXP_UPDATE then
    self:updateExp()
  elseif notify == IndexModule.LEVEL_UPDATE then
    self:updateLv()
  elseif notify == IndexModule.NAME_UPDATE then
    self:updateName()
	end
end

--初始化UI
function MainTopProcessor:initUI()
  if self.view ~= nil and (not tolua.isnull(self.view)) then 
    return 
  end

  local mainTop = ResourceManager:widgetFromJsonFile("ui/maintop.json")
  self.txtPlayerName = mainTop:getChildByName("txtPlayerName")
  self.txtCoins = mainTop:getChildByName("txtCoins")
  self.txtDiamond = mainTop:getChildByName("txtDiamond")
  self.progressBarMain = mainTop:getChildByName("progressBarMain")
  self.txtLevel = mainTop:getChildByName("txtLevel")
  self.txtLevel:enableOutline(cc.c4b(0, 0, 0, 255),2)
  local btnJob = mainTop:getChildByName("btnJob")
  local btnPlus = mainTop:getChildByName("btnPlus")


  btnJob:addTouchEventListener(handler(self, self.onPersonBtnClick))
  btnPlus:addTouchEventListener(handler(self, self.onPersonBtnClick))

  self.btnJob = btnJob 

  self:setView(mainTop)
  self:addTopView(mainTop)
end
function MainTopProcessor:onPersonBtnClick(sender,eventType)
  if  eventType ~= TouchEventType.ended then 
    return
  end
  local btn = tolua.cast(sender,"ccui.Button")
  local btnName = btn:getName()
  if btnName == "btnJob" then 
    Observer.sendNotification(GamesysModule.SHOW_PERSON_INFO)
  elseif btnName == "btnPlus" then
    Observer.sendNotification(ChargeModule.SHOW_CHARGE_VIEW)
  end
end

--设置view
function MainTopProcessor:setData()
  local tp = PlayerData:getHeroType()
  self.btnJob:loadTextureNormal("ui/type/"..tp..".png")
  self:updateMoney()
  self:updateExp()
  self:updateLv()
  self:updateName()
end
--更新昵称
function MainTopProcessor:updateName()
  if self.view == nil then 
    return
  end
 self.txtPlayerName:setString(PlayerData:getPlayerName())
end
--更新货币
function MainTopProcessor:updateMoney()
  if self.view == nil then 
    return
  end

  self.txtCoins:setString(PlayerData:getGold())
  self.txtDiamond:setString(PlayerData:getCoin())
end
--更新经验
function MainTopProcessor:updateExp()
  if self.view == nil then 
    return
  end
  local lvexp = DataConfig:getUpdateExpByLvl(PlayerData:getLv())
  local exp = PlayerData:getExp()
  local percent = 0
  if lvexp~= 0 then
    percent = math.floor(exp/lvexp*100)
  end
  --[[if percent < 3 then
    percent = 3 --3才能保证显示不畸形
  end]]
  self.progressBarMain:setPercent(percent)
end
--更新等级
function MainTopProcessor:updateLv()
  if self.view == nil then 
    return
  end
  self.txtLevel:setString("等级:"..PlayerData:getLv())
end

return MainTopProcessor