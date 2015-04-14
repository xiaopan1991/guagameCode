package.loaded["hotfix.hotinit"] = nil
require("hotfix.hotinit")

--进入游戏
local function enter_game()
	CCLuaLoadChunksFromZIP("res/framework_precompiled.zip")
	App = require("app.MyApp").new()
    App:run()
end

--热更主场景
local HotFixScene = lcher_class("HotFixScene", function()
	local scene = CCScene:create()
	scene.name = "HotFixScene"
    return scene
end)


function HotFixScene:ctor()
    if hotfix.platform == "android" then
        self._path = hotfix.writablePath .. "/guagame/upd/"
        CCFileUtils:sharedFileUtils():addSearchPath(hotfix.writablePath.."/guagame/")
        CCFileUtils:sharedFileUtils():addSearchPath(hotfix.writablePath.."/guagame/res/")
        CCFileUtils:sharedFileUtils():addSearchPath(hotfix.writablePath.."/guagame/scripts/")
    else
        self._path = hotfix.writablePath .. "upd/"
    end
    if (hotfix.platform ~= "android" and hotfix.platform ~= "ios") then
        --移动平台开启热更
        CCFileUtils:sharedFileUtils():addSearchPath(self._path)
        CCFileUtils:sharedFileUtils():addSearchPath("res/")
    end

	self._textLabel = CCLabelTTF:create(STR_LCHER_HAS_UPDATE, "ui/yh.ttf", 20)
	self._textLabel:setColor(ccc3(255, 255, 255))
	self._textLabel:setPosition(hotfix.cx, hotfix.cy - 60)
	self:addChild(self._textLabel)
	
    hotfix.performWithDelayGlobal(function()
    	if (hotfix.platform == "android" or hotfix.platform == "ios") then
			hotfix.initPlatform(lcher_handler(self, self._initPlatformResult))
		elseif hotfix.windowsUpdate then
            hotfix.initPlatform(lcher_handler(self, self._initPlatformResult))
        else
			enter_game()
		end
    end, 0.1)
end


function HotFixScene:_initPlatformResult(message)
    -- print("update ------------------------------------------------- "..message)
	if message == "successed" then
		--启动更新逻辑
        -- print("update -------------------------------------------------")
		self:_initUpdate()
	else
		--TODO::初始化平台失败
	end
end

function HotFixScene:_initUpdate()
    hotfix.performWithDelayGlobal(function()
    	self:_checkUpdate()
    end, 0.1)
end

function HotFixScene:_checkUpdate()

	hotfix.mkDir(self._path)
    print("make dir :"..self._path)

    if hotfix.platform == "android" then
	   self._curListFile =  hotfix.writablePath .."/guagame/" .. hotfix.fListName
    else
        self._curListFile =  hotfix.writablePath .. hotfix.fListName
    end
    print("self._curListFile :"..self._curListFile)

	if hotfix.fileExists(self._curListFile) and not hotfix.debugmode then
        print("flist file exist")
        self._fileList = hotfix.doFile(self._curListFile)
        print("flist do file ok")
    else
        print("flist file not exist")
        if hotfix.platform == "android" then
            --从ASSETS拷贝到可写目录下
            
            hotfix.copyRes()
        end
        print("begin do file :"..self._curListFile)
        self._fileList = hotfix.doFile(self._curListFile)
    end

    if self._fileList ~= nil then
        local appVersionCode = hotfix.getAppVersionCode()
        print("appVersionCode:"..appVersionCode)
        print("fileList.appVersion:"..self._fileList.appVersion)
        if hotfix.checkAppVersion(appVersionCode,self._fileList.appVersion) then
            --新的app已经更新需要删除upd/目录下的所有文件
            print("appversion not fit! clean upd"..self._path)
            hotfix.removePath(self._path)
        end
    else
    	self._fileList = hotfix.doFile(hotfix.fListName)
    end

    if self._fileList == nil then
        print("local flist not found!!")
    end

    --下载flist
    print("begin download flist")
    self:_requestFromServer(hotfix.fListName, hotfix.RequestType.FLIST)
end

--结束更新
function HotFixScene:_endUpdate()
	if self._updateRetType ~= hotfix.UpdateRetType.SUCCESSED then
		print("update errorCode = "..self._updateRetType)
		-- hotfix.removePath(self._curListFile)
		--连接服务器出错
		self._textLabel:setString(STR_LCHER_SERVER_ERROR)
	end

	enter_game()
end

--下载文件
function HotFixScene:_requestFromServer(filename, requestType, waittime)
    local url = hotfix.server .. filename
    print("downloading "..url)
    if hotfix.needUpdate then
        print("开始下载:"..url)
        local request = CCHTTPRequest:createWithUrl(
            function(event)
        	   self:onResponse(event, requestType)
            end
        , url, kCCHTTPRequestMethodGET)

        if request then
        	request:setTimeout(waittime or 60)
        	request:start()
    	else
    		--初始化网络错误
    		self._updateRetType = UpdateRetType.NETWORK_ERROR
    		print("···120 error")
        	self:_endUpdate()
    	end
    else
        print("跳过更新逻辑直接进系统")
    	--不更新
    	enter_game()
    end
end

--服务器返回
function HotFixScene:onResponse(event, requestType)
    local request = event.request
    if event.name == "completed" then
        if request:getResponseStatusCode() ~= 200 then
            self._updateRetType = hotfix.UpdateRetType.NETWORK_ERROR
        	self:_endUpdate()
        else
            local dataRecv = request:getResponseData()
            --hotfix.zip
            if requestType == hotfix.RequestType.HOTFIX then
            	self:_onHotfixPacakgeFinished(dataRecv)
            --flist
            elseif requestType == hotfix.RequestType.FLIST then
            	self:_onFileListDownloaded(dataRecv)
            --res
            else
            	self:_onResFileDownloaded(dataRecv)
            end
        end
    elseif event.name == "inprogress" then
    	 if requestType == hotfix.RequestType.RES then
    	 	self:_onResProgress(event.dlnow)
    	 end
    else
        self._updateRetType = hotfix.UpdateRetType.NETWORK_ERROR
        self:_endUpdate()
    end
end

--hotfix 包完成
function HotFixScene:_onHotfixPacakgeFinished(dataRecv)
    --临时lib目录
	hotfix.mkDir(self._path .. hotfix.libDir)
	local localmd5 = nil
    --本地的hotfix.zip路径
	local localPath = self._path .. hotfix.libDir .. hotfix.lcherZipName
    --
	if not hotfix.fileExists(localPath) then
		localPath = hotfix.writablePath..hotfix.libDir .. hotfix.lcherZipName
	end

	localmd5 = hotfix.fileMd5(localPath)

	local downloadMd5 =  hotfix.fileDataMd5(dataRecv)

	if downloadMd5 ~= localmd5 then
		hotfix.writefile(self._path .. hotfix.libDir .. hotfix.lcherZipName, dataRecv)
        require("main")
    else
    	self:_requestFromServer(hotfix.fListName, hotfix.RequestType.FLIST)
    end
end

--flist下载完成
function HotFixScene:_onFileListDownloaded(dataRecv)
	self._newListFile = self._curListFile .. hotfix.updateFilePostfix
	hotfix.writefile(self._newListFile, dataRecv)

	self._fileListNew = hotfix.doFile(self._newListFile)

    --
	if self._fileListNew == nil then
        print("flist parse error！")
        self._updateRetType = hotfix.UpdateRetType.OTHER_ERROR
		self:_endUpdate()
		return
	end

    --版本号一样结束更新
    print("new flist version "..self._fileListNew.version)
    print("local flist version "..self._fileList.version)

	if self._fileList ~= nil and self._fileListNew.version == self._fileList.version then
        print("version fit,end update")
		hotfix.removePath(self._newListFile)
		self._updateRetType = hotfix.UpdateRetType.SUCCESSED
		self:_endUpdate()
		return
	end

	--创建资源目录
	local dirPaths = self._fileListNew.dirPaths
    print("make dir "..self._path)
    hotfix.mkDir(self._path)
    for i=1,#(dirPaths) do
        print("make dir "..self._path..(dirPaths[i].name))
        hotfix.mkDir(self._path..(dirPaths[i].name))
    end
    print("check update files")
  
    self:_updateNeedDownloadFiles()
    self._numFileCheck = 0
    self:_reqNextResFile()
end

function HotFixScene:_onResFileDownloaded(dataRecv)
	local fn = self._curFileInfo.name .. hotfix.updateFilePostfix
	hotfix.writefile(self._path .. fn, dataRecv)
    print("resfile :"..(self._path .. fn))
    print("resfile info md5 :"..self._curFileInfo.code)
    
	if hotfix.checkFileWithMd5(self._path .. fn, self._curFileInfo.code) then
		table.insert(self._downList, fn)
        print("write file to:"..hotfix.writablePath .. self._curFileInfo.name)
        local path = ""
        if hotfix.platform == "android" then
            path = hotfix.writablePath .."/guagame/".. self._curFileInfo.name
        else
            path = hotfix.writablePath .. self._curFileInfo.name
        end
		hotfix.writefile(path, dataRecv)--写入正式的文件夹里边
		self._hasDownloadSize = self._hasDownloadSize + self._curFileInfo.size
		self._hasCurFileDownloadSize = 0
		self:_reqNextResFile()
	else
		--文件验证失败
        self._updateRetType = hotfix.UpdateRetType.MD5_ERROR
    	self:_endUpdate()
	end
end

function HotFixScene:_onResProgress(dlnow)
	self._hasCurFileDownloadSize = dlnow
    self:_updateProgressUI()
end

function HotFixScene:_updateNeedDownloadFiles()
	self._needDownloadFiles = {}	--需要下载的文件列表
    self._downList = {}				--下载完成列表
    self._needDownloadSize = 0 		--需要下载的所有文件size
    self._hasDownloadSize = 0       --已经下载的所有文件size
    self._hasCurFileDownloadSize = 0 --当前下载的文件的size

    local newFileInfoList = self._fileListNew.fileInfoList --最新的flist
    local oldFileInfoList = self._fileList.fileInfoList  --如果是nil 所有重新下
    print("newFileInfoList.."..#newFileInfoList)
    print("oldFileInfoList.."..#oldFileInfoList)
    
    for i = 1,#newFileInfoList do
    	--如果跟本地资源不一致 则判断是否需要下载
        local localfile = ""
        if hotfix.platform == "android" then
            localfile = hotfix.writablePath .."/guagame/".. newFileInfoList[i].name
        else
            localfile = hotfix.writablePath .. newFileInfoList[i].name
        end
        if not hotfix.checkFileWithMd5(localfile, newFileInfoList[i].code) then
            hasChanged = true
        	local fn = newFileInfoList[i].name .. hotfix.updateFilePostfix
        	if hotfix.checkFileWithMd5(self._path .. fn, newFileInfoList[i].code) then
                table.insert(self._downList, fn)
            else
                self._needDownloadSize = self._needDownloadSize + newFileInfoList[i].size
                table.insert(self._needDownloadFiles, newFileInfoList[i])
            end
        end
    end

    local progressBarBg = CCSprite:create("hotfix/loadingbg.png")
    self:addChild(progressBarBg)
    local progressBarBgSize = progressBarBg:getContentSize()
    local progressBarPt = ccp(hotfix.cx, hotfix.cy + progressBarBgSize.height * 0.5)
    progressBarBg:setPosition(progressBarPt)
 
    self._progressBar = CCProgressTimer:create(CCSprite:create("hotfix/loading.png"))
    self._progressBar:setType(kCCProgressTimerTypeBar)
    self._progressBar:setMidpoint(ccp(0,1))
    self._progressBar:setBarChangeRate(ccp(1, 0))
    self._progressBar:setPosition(progressBarPt)
    self:addChild(self._progressBar)
    self._textLabel:setString(STR_LCHER_UPDATING_TEXT)


    self._progressLabel = CCLabelTTF:create("0%", "Artial", 20)
    self._progressLabel:setColor(ccc3(255, 255, 255))
    self._progressLabel:setPosition(hotfix.cx, hotfix.cy - 20)

    self:addChild(self._progressLabel)


end

function HotFixScene:_updateProgressUI()
	local downloadPro = (self._hasDownloadSize  / self._needDownloadSize)*100
    downloadPro = math.modf(downloadPro)
    self._progressBar:setPercentage(downloadPro)
    self._progressLabel:setString(string.format("%d%%", downloadPro))
end

function HotFixScene:_reqNextResFile()

	if #self._needDownloadFiles == 0 then
		self:_endAllResFileDownloaded()
		return
	end

    self:_updateProgressUI()
    self._numFileCheck = self._numFileCheck + 1
    self._curFileInfo = self._needDownloadFiles[self._numFileCheck]

    if self._curFileInfo and self._curFileInfo.name then
    	self:_requestFromServer(self._curFileInfo.name, hotfix.RequestType.RES)
    else
    	self:_endAllResFileDownloaded()
    end

end

function HotFixScene:_endAllResFileDownloaded()
	print("self._newListFile.."..self._newListFile)
	print("self._curListFile.."..self._curListFile)
	--写入flist
	local data = hotfix.readFile(self._newListFile)
    hotfix.writefile(self._curListFile, data)

    self._fileList = hotfix.doFile(self._curListFile)
    if self._fileList == nil then
        self._updateRetType = hotfix.UpdateRetType.OTHER_ERROR
    	self:_endUpdate()
        return
    end

    hotfix.removePath(self._newListFile)

    local offset = -1 - string.len(hotfix.updateFilePostfix)
    for i,v in ipairs(self._downList) do
        v = self._path .. v
        local data = hotfix.readFile(v)

        local fn = string.sub(v, 1, offset)
        hotfix.writefile(fn, data)
        hotfix.removePath(v)
    end

    self._updateRetType = hotfix.UpdateRetType.SUCCESSED
    self:_endUpdate()
end

local lchr = HotFixScene.new()
hotfix.runWithScene(lchr)