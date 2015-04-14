--热更新模块的配置
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 1

-- display FPS stats on screen
DEBUG_FPS = true

-- dump memory info every 10 seconds
DEBUG_MEM = false

-- load deprecated API
LOAD_DEPRECATED_API = false

-- load shortcodes API
LOAD_SHORTCODES_API = true

-- screen orientation landscape
CONFIG_SCREEN_ORIENTATION = "portrait"

-- design resolution
CONFIG_SCREEN_WIDTH  = 960
CONFIG_SCREEN_HEIGHT = 640

CONFIG_SCREEN_AUTOSCALE_CALLBACK = function(w, h, deviceModel)
    if (w == 1024 and h == 768)
        or (w == 2048 and h == 1536) then
            -- iPad
            CONFIG_SCREEN_WIDTH = 1024
            CONFIG_SCREEN_HEIGHT = 768
            if (w == 2048 and h == 1536) then
            	return 2.0, 2.0
            else
            	return 1.0, 1.0
            end
    end
end

-- auto scale mode
CONFIG_SCREEN_AUTOSCALE = "FIXED_HEIGHT"


-- LCHER_FONT = "res/fonts/FZPangWa-M18T.ttf"

STR_LCHER_HAS_UPDATE = 		"正在检测更新,请耐心等待..."
STR_LCHER_UPDATING_TEXT = 	"正在更新数据资源,请耐心等待..."
STR_LCHER_SERVER_ERROR = 	"连接服务器失败，请保持网络通畅..."