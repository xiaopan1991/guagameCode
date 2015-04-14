local MainSceneProcessor = class("MainSceneProcessor", BaseProcessor)
local MainSceneModule = import(".MainSceneModule")

--构造
function MainSceneProcessor:ctor()
	-- body
end

--关心的消息列表
function MainSceneProcessor:ListNotification()
	-- body
	return {
		MainSceneModule.SHOW_MAINSCENE,
		MainSceneModule.SHOW_VIEW,
		MainSceneModule.SHOW_POP_VIEW,
		MainSceneModule.SHOW_NOTICE
	}
end


--消息处理
--notify 	消息名
--data 		数据
function MainSceneProcessor:handleNotification(notify, data)
	if notify == MainSceneModule.SHOW_VIEW then 

	elseif notify == MainSceneModule.SHOW_VIEW then

	elseif notify == MainSceneModule.SHOW_NOTICE then

	elseif notify == MainSceneModule.SHOW_MAINSCENE then
		
	end
end

--
function MainSceneProcessor:onSetView(view)

end




return MainSceneProcessor
