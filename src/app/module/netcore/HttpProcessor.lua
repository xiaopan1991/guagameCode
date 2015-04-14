-- http短连接处理器
-- Author: whe
-- Date: 2014-07-28 14:01:03
local HttpProcessor = class("HttpProcessor", BaseProcessor)
NET_WEAK_DEBUG = false
function HttpProcessor:ctor()
	-- body
    self.msglist = {}--因为游戏对客户端和服务端时间要求很苛刻，加了一个消息队列，只有上一个消息返回，才会发出下一个
    self.sending = false
    self.reConTimes = 0 --重连次数
end

function HttpProcessor:ListNotification()
	-- body
	return {
		NetCoreModule.SEND_HTTP,
		NetCoreModule.RECEIVE_HTTP
	}
end

--处理消息
--node CCObject 载体
--node里还有一个data
function HttpProcessor:handleNotification(notify,node)
	if notify == NetCoreModule.SEND_HTTP then
		self:sendhttp(node.data,node.up)
	elseif notify == NetCoreModule.RECEIVE_HTTP then
	end
end

--发送HTTP请求
function HttpProcessor:sendhttp(data,up)
    --dump(data)
    if PlayerData.login == true then
        data.sessionid = PlayerData:getSessionId()
        data.uid = PlayerData:getUid()
        data.params.actionID = os.time()..math.random(10000000)
        if(TimeManager.started) then
            data.client_time = changeSecToTimeStr(TimeManager:getSvererTime())
        end
    end
    table.insert(self.msglist, {data,up})--存到消息队列中
    if(not self.sending) then
        self:sendNextHttp()
    end    
end
--发送下一个HTTP请求
function HttpProcessor:sendNextHttp()
    if(self.sending) then
        return
    end
    if(#self.msglist == 0) then
        return
    end
    self.sending = true
    local data = self.msglist[1][1]
    local url = HTTP_REQUETS_ADD.."?req="..string.urlencode(json.encode(data))
    local request = network.createHTTPRequest(handler(self,self.onHttpData), url, "GET")
    request:setRequestUrl(url)
    request:setTimeout(20)
    request:start()
    -- dump(request,nil,999)
    if(TimeManager.started) then
        TimeManager:setPause(true)
    end  
    LoadingBall.show()
end
function HttpProcessor:onCompletedHttp(request)
    --清理
    table.remove(self.msglist,1)
    self.sending = false
    LoadingBall.hide()
    --重连次数置0
    self.reConTimes = 0

    --处理消息
    local response = request:getResponseString()
    local js = json.decode(response)
    node = display.newNode()
    node.data = js
    if(js == nil) then
        local btns = {{text = "确定",skin = 3,callback = handler(self,self.gotoLogin)}}
        local alert = GameAlert.new()
        local richStr = {{text = "服务器返回异常，请重新登录",color = display.COLOR_WHITE},
        }
        alert:pop(richStr,"ui/titlenotice.png",btns)
        return
    end
    print("server response:"..js.method)
    if js.return_code == 0 then
        Observer.sendNotification(js.method,node)
        if(node.data and node.data.titles) then
            PlayerData:setTitles(node.data.titles)
        end
    else
        --返回登录界面
        if(js.return_code == 100000 or js.return_code == 100001 or js.return_code == 100002) then
            local btns = {{text = "确定",skin = 3,callback = handler(self,self.gotoLogin)}}
            local alert = GameAlert.new()
            local richStr = {{text = js.data.msg,color = display.COLOR_WHITE},
            }
            alert:pop(richStr,"ui/titlenotice.png",btns)
            return
        end
        toastNotice(js.data.msg)
    end
    if(TimeManager.started) then
        TimeManager:setPause(false)
        TimeManager:jumpToSeverTime(changeTimeStrToSec(node.data.server_now["$datetime"]))
    end
    self:errorProcess(js.return_code)

    --发送下一个消息
    self:sendNextHttp()
end
function HttpProcessor:onFailedHttp(request)
    local err = "http error:"..request:getErrorCode().." "..request:getErrorMessage()
        --TODO错误7 不能连上服务器 弹个框框提示
    print("http error"..request:getErrorCode(), request:getErrorMessage())


    self.sending = false
    LoadingBall.hide()
    --重连次数+1
    self.reConTimes = self.reConTimes + 1


    local curScene = display.getRunningScene()
    if(self.reConTimes > 30) then
        if(curScene.name~="LoginScene") then
            local btns = {{text = "确定",skin = 3,callback = handler(self,self.gotoLogin)}}
            local alert = GameAlert.new()
            local richStr = {{text = "您当前网络状况不佳，请返回登陆界面重试",color = display.COLOR_WHITE},
            }
            alert:pop(richStr,"ui/titlenotice.png",btns)
            return
        end
        toastNotice("您当前网络状况不佳,请检查您的网络")
    end
    --toastNotice("第"..self.reConTimes.."次重试")

    self:sendNextHttp()
end
--回来了
function HttpProcessor:onHttpData(event)
	-- if event.name == "inprogress" then
    if event.name == "progress" then
		--正在进行中
        local upcfg = self:getCurHttpUpdata()
        if upcfg ~= nil then
            --[[local dlnow = event.dlnow
            local dltotal = event.dltotal
            local per = 0
            if dltotal ~= 0 then
                per = math.modf((dlnow/dltotal)*100)
            end
            local update = upcfg.update
            local info = upcfg.info
            local node = display.newNode()
            node.data = {}
            node.data.per = per
            node.data.info = info
            Observer.sendNotification(update,node)]]
        end
		return 
	end
    local request = event.request
    if(event.name == "completed") then
        local response = request:getResponseString()
        local js = json.decode(response)
        if(js) then
            if(NET_WEAK_DEBUG and js.method ~= "sys.get_config" and js.method ~=LoginModule.USER_LOGIN and (2<= math.random(1,10))) then
                event.name = "failed"
            end
        else
            event.name = "failed"
        end
    end
    if(event.name == "completed") then
        self:onCompletedHttp(request)
    else
        self:onFailedHttp(request)
    end
end
function HttpProcessor:errorProcess(errCode)
	if(errCode == 10132 or errCode == 10131) then
    	Observer.sendNotification(PVPModule.UPDATE_PVP_PANEL)
    	BossPvpBattleManager:over()
    end
end
function HttpProcessor:gotoLogin()
    self.msglist = {}
    self.sending = false
    self.reConTimes = 0
    TimeManager:stop()
    GameInstance.relogin = true
    GameInstance.closechat = nil
    local scene = require("app.scenes.LoginScene").new()
    display.replaceScene(scene)
end
--获取http的回调
function HttpProcessor:getCurHttpUpdata()
    return self.msglist[1][2] 
end

return HttpProcessor