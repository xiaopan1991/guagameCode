--
-- Author: Your Name
-- Date: 2015-03-03 11:06:13
--
local GmdModule = class("GmdModule",BaseModule)
local GmdProcessor = import(".GmdProcessor")
GmdModule.SHOW_GMD    = "SHOW_GMD"  	 --显示光明顶界面
function GmdModule:ctor()
	-- body
	GmdModule.super.ctor(self)
end

function GmdModule:ProcessorList()
	return {
		GmdProcessor,
	}
end

return GmdModule