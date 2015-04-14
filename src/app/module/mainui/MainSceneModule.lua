--主场景模块
local MainSceneModule = class("MainSceneModule", BaseModule)
--processor
local ToolbarProcessor = import(".ToolbarProcessor")
--消息
MainSceneModule.SHOW_MAINSCENE = "SHOW_MAINSCENE"  	--主界面
MainSceneModule.SHOW_TOOLBAR = "SHOW_TOOLBAR"  	--显示工具条
MainSceneModule.SHOW_VIEW = "SHOW_VIEW" 		--显示界面 普通显示
MainSceneModule.SHOW_POP_VIEW = "SHOW_POP_VIEW" --显示界面 模态显示
MainSceneModule.SHOW_NOTICE = "SHOW_NOTICE" 	--显示提示文字


function MainSceneModule:ctor()
	-- body
	MainSceneModule.super.ctor(self)
end

--Processor列表
function MainSceneModule:ProcessorList()
	-- body
	return {
		ToolbarProcessor,
		MainTopProcessor
	}
end

return MainSceneModule