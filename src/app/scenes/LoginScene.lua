--登录场景
local LoginScene = class("LoginScene", function ()
	return display.newScene("LoginScene")
end)

--构造函数
function LoginScene:ctor()

	GameInstance.loginScene = self
	self.midview = nil
	-- 登录的背景图
	local bg = display.newSprite("bg.png")
    bg:setAnchorPoint(0,1)
    bg:setPosition(0,display.height)
    bg:addTo(self)

    local gua = display.newSprite("logo.png")
    gua:setPosition(display.cx,display.cy+300)
    gua:addTo(self)
    self.gua = gua 

    --UI层
    self.uiLayer = cc.Layer:create()
    self:addChild(self.uiLayer)

    --重新登录的时候 重新注册
    if GameInstance.relogin == true then
        app:unregisterModule()
        app:registerModule()
        GameInstance.relogin = false
        BattleManager:clear()
        BossPvpBattleManager:clear()
        Bag:clear()
        ResourceManager:clear()
    end



end

function LoginScene:onEnter()
	PopLayer:setCurScene(self)

    if GameInstance.notice then
        if GameInstance.notice:getParent() ~= nil then
            GameInstance.notice:removeFromParent()
        end
        self:addChild(GameInstance.notice)
        GameInstance.notice:clear()
        GameInstance.notice:setLocalZOrder(9999)
    end
	Observer.sendNotification(LoginModule.SHOW_LOGIN_LOADING)
    local node = display.newNode()
    node.data = {}
    node.data.update = LoginModule.UPDATE_LOGIN_LOADING
    node.data.info = "加载配置文件"
	Observer.sendNotification(LoginModule.GET_LOCAL_CONFIG,node)
    --显示一个进度条
end

function LoginScene:onExit()
	PopLayer:clearPopLayer()
end

function LoginScene:addMidView(view)
	-- body
    if self.midview ~= nil then
        print("midview "..self.midview:getName())
        print("view "..view:getName())
    end
    if self.midview ~= nil and self.midview:getName() ~= view:getName() then
        self.midview.processor:onHideView()
    end
    self.midview = view
    self.uiLayer:addChild(view)
    --把弹出层所有子界面的全删除
    PopLayer:clearPopLayer()
end

--转为右上角状态组件留的
function LoginScene:addWidget(widget)
     self.uiLayer:addChild(widget)
end
return LoginScene