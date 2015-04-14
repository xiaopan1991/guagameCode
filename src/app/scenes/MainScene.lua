--主场景
scheduler = require("framework.scheduler")
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    --全局引用
    GameInstance.mainScene = self
    --场景中间和上边的显示对象
    self.midview = nil
    --场景下边的显示对象  工具条
    self.bottomview = nil
    --场景上边的banner条
    self.topview = nil

    -- local bg = display.newScale9Sprite("mainback.png", 320, 568, cc.size(2, 2))
    local bg = display.newSprite("mainback.png")
    -- bg:setContentSize(cc.size(display.width,display.height))
    bg:setPosition(display.cx,display.cy)
    bg:addTo(self)
    --UI层
    self.uiLayer = cc.Layer:create()
    GameInstance.uiLayer = self.uiLayer
    self:addChild(self.uiLayer)
    
    if GameInstance.notice then
        if GameInstance.notice:getParent() ~= nil then
            GameInstance.notice:removeFromParent()
        end
        self:addChild(GameInstance.notice)
        GameInstance.notice:clear()
        GameInstance.notice:setLocalZOrder(9999)
    end
end

function MainScene:onEnter()    
    PopLayer:setCurScene(self)    
end
function MainScene:onEnterTransitionFinish()
    Observer.sendNotification(BattleModule.GUAJI_BEGIN_FIGHT)
    --显示底部工具条子
    Observer.sendNotification(MainSceneModule.SHOW_TOOLBAR, nil)
    --显示主页
    Observer.sendNotification(IndexModule.SHOW_INDEX,nil)
    print("delay function")
    --延迟0.5秒弹出离线挂机奖励
    self:popAlert()
end
function MainScene:popAlert()
    scheduler.performWithDelayGlobal(handler(self,self.showAnnouncement),1)
end
function MainScene:onExit()
    PopLayer:clearPopLayer()
end
--显示公告
function MainScene:showAnnouncement()
    print("Observer.sendNotification(GamesysModule.SHOW_GONGGAO)")
    --Observer.sendNotification(GamesysModule.SHOW_GONGGAO)
    local alert = GameAlert.new()
	alert:popNotice()
end
--添加中间显示对象 会把之前的移除掉
--view 显示对象
--isremoveTop 是否移除TOP
function MainScene:addMidView(view,isremoveTop)
    -- body
    if self.midview~= nil then
        print("midview"..self.midview:getName())
        print("view"..view:getName())
    end
    if (self.midview ~= nil) and (self.midview:getName() ~= view:getName()) then
        self.midview.processor:onHideView(self.midview)
    end

    self.midview = view
    local vp = view:getParent()
    if(vp == nil) then
        self.uiLayer:addChild(view)
    end
    view:setVisible(true)

    if isremoveTop == true then
        if self.topview~=nil then
            if self.topview.processor ~= nil then
                self.topview.processor:onHideView(self.topview)
            else
                self.uiLayer:removeWidget(self.topview)
            end
            self.topview = nil
        end
    end
    --动态布局
    self:resetPos()
end

--添加底部UI
function MainScene:addBottomView(view)
    if self.bottomview ~= nil and self.bottomview:getName() ~= view:getName() then
        self.bottomview.processor:onHideView(self.bottomview)
    end
    local size1 = view:getContentSize()
    self.bottomview = view

    local vp = view:getParent()
    if(vp == nil) then
        self.uiLayer:addChild(view)
    end

    view:setPosition((display.width - size1.width)/2,0)
    view:setVisible(true)
    view:setLocalZOrder(128)
    PopLayer:clearPopLayer()
end

--添加顶部UI
function MainScene:addTopView(view)
    if self.topview~=nil and self.topview:getName() ~= view:getName() then
        if self.topview.processor ~= nil then
            self.topview.processor:onHideView(self.topview)
        else
            self.uiLayer:removeWidget(self.topview)
        end
    end
    self.topview = view
    local vp = view:getParent()
    if(vp == nil) then
        self.uiLayer:addChild(view)
    end
    view:setVisible(true)
    PopLayer:clearPopLayer()

    local size = self.topview:getLayoutSize()
    self:resetPos()
end

--重置UI布局
function MainScene:resetPos()
    local size = nil
    if self.topview ~= nil then
        size = self.topview:getLayoutSize()
        self.topview:setPosition((display.width - size.width)/2,display.height - size.height)
    end

    if self.midview ~= nil then 
        local midsize = self.midview:getLayoutSize()
        -- print("1111111111111111111111**"..self.midview:getName().."=",midsize.width,midsize.height)
        local topheight = 0
        if size~= nil then
            topheight = size.height
        end    
        self.midview:setPosition((display.width - midsize.width)/2,display.height - midsize.height - topheight)
    end
end
return MainScene
