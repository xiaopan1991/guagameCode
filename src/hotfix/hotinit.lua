package.loaded["hotfix.hotconfig"] = nil
require("hotfix.hotconfig")
require("lfs")

hotfix = {}
hotfix.server = "http://192.168.1.146/gameupdate/platform/official/"
hotfix.fListName = "flist"
hotfix.libDir = "lib/"
hotfix.lcherZipName = "hotfix.zip"
hotfix.updateFilePostfix = ".upd"

--开启windows 热更新
--慎用 会把代码都覆盖干掉
hotfix.windowsUpdate = false
--调试模式 每次运行会重新拷贝资源和代码
hotfix.debugmode = true

local sharedApplication = CCApplication:sharedApplication()
local sharedDirector = CCDirector:sharedDirector()
local target = sharedApplication:getTargetPlatform()
hotfix.platform    = "unknown"
hotfix.model       = "unknown"

local sharedApplication = CCApplication:sharedApplication()
local target = sharedApplication:getTargetPlatform()
if target == kTargetWindows then
    hotfix.platform = "windows"
elseif target == kTargetMacOS then
    hotfix.platform = "mac"
elseif target == kTargetAndroid then
    hotfix.platform = "android"
elseif target == kTargetIphone or target == kTargetIpad then
    hotfix.platform = "ios"
    if target == kTargetIphone then
        hotfix.model = "iphone"
    else
        hotfix.model = "ipad"
    end
end

-- check device screen size
local glview = sharedDirector:getOpenGLView()
local size = glview:getFrameSize()
local w = size.width
local h = size.height

if CONFIG_SCREEN_WIDTH == nil or CONFIG_SCREEN_HEIGHT == nil then
    CONFIG_SCREEN_WIDTH = w
    CONFIG_SCREEN_HEIGHT = h
end

if not CONFIG_SCREEN_AUTOSCALE then
    if w > h then
        CONFIG_SCREEN_AUTOSCALE = "FIXED_HEIGHT"
    else
        CONFIG_SCREEN_AUTOSCALE = "FIXED_WIDTH"
    end
else
    CONFIG_SCREEN_AUTOSCALE = string.upper(CONFIG_SCREEN_AUTOSCALE)
end

local scale, scaleX, scaleY

if CONFIG_SCREEN_AUTOSCALE then
    if type(CONFIG_SCREEN_AUTOSCALE_CALLBACK) == "function" then
        scaleX, scaleY = CONFIG_SCREEN_AUTOSCALE_CALLBACK(w, h, hotfix.model)
    end

    if not scaleX or not scaleY then
        scaleX, scaleY = w / CONFIG_SCREEN_WIDTH, h / CONFIG_SCREEN_HEIGHT
    end

    if CONFIG_SCREEN_AUTOSCALE == "FIXED_WIDTH" then
        scale = scaleX
        CONFIG_SCREEN_HEIGHT = h / scale
    elseif CONFIG_SCREEN_AUTOSCALE == "FIXED_HEIGHT" then
        scale = scaleY
        CONFIG_SCREEN_WIDTH = w / scale
    else
        scale = 1.0
    end
    glview:setDesignResolutionSize(CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, kResolutionNoBorder)
end

local winSize = sharedDirector:getWinSize()
hotfix.size = {width = winSize.width, height = winSize.height}
hotfix.width              = hotfix.size.width
hotfix.height             = hotfix.size.height
hotfix.cx                 = hotfix.width / 2
hotfix.cy                 = hotfix.height / 2

--写入目录
hotfix.writablePath = CCFileUtils:sharedFileUtils():getWritablePath()

---跨平台适配 TODO
if hotfix.platform == "android" then
    hotfix.javaClassName = "com/meng52/game/guagame/GameHelper"
    hotfix.luaj = {}
    function hotfix.luaj.callStaticMethod(className, methodName, args, sig)
        return CCLuaJavaBridge.callStaticMethod(className, methodName, args, sig)
    end

    local para = {}
    local prosign = "()Ljava/lang/String;"
    local isok = false
    isok,hotfix.writablePath = hotfix.luaj.callStaticMethod(hotfix.javaClassName,"getWriteablePath",para,prosign)
    print("hotfix.writablePath"..hotfix.writablePath)

elseif hotfix.platform == "ios" then
    hotfix.ocClassName = "LuaObjcFun"
    hotfix.luaoc = {}
    function hotfix.luaoc.callStaticMethod(className, methodName, args)
        local ok, ret = CCLuaObjcBridge.callStaticMethod(className, methodName, args)
        if not ok then
            local msg = string.format("luaoc.callStaticMethod(\"%s\", \"%s\", \"%s\") - error: [%s] ",
                    className, methodName, tostring(args), tostring(ret))
            if ret == -1 then
                printError(msg .. "INVALID PARAMETERS")
            elseif ret == -2 then
                printError(msg .. "CLASS NOT FOUND")
            elseif ret == -3 then
                printError(msg .. "METHOD NOT FOUND")
            elseif ret == -4 then
                printError(msg .. "EXCEPTION OCCURRED")
            elseif ret == -5 then
                printError(msg .. "INVALID METHOD SIGNATURE")
            else
                printError(msg .. "UNKNOWN")
            end
        end
        return ok, ret
    end
end


--是否需要更新
if (hotfix.platform == "android" or hotfix.platform == "ios") then
    hotfix.needUpdate = true    
else
    hotfix.needUpdate = false
end
--请求类型
hotfix.RequestType = { HOTFIX = 0, FLIST = 1, RES = 2 }
--更新结果
hotfix.UpdateRetType = { SUCCESSED = 0, NETWORK_ERROR = 1, MD5_ERROR = 2, OTHER_ERROR = 3 }

function lcher_handler(obj, method)
    return function(...)
        return method(obj, ...)
    end
end

---类包装
function lcher_class(classname, super)
    local superType = type(super)
    local cls
    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end
    return cls
end

---HEX
function hotfix.hex(s)
    local s = string.gsub(s,"(.)",function (x) return string.format("%02X",string.byte(x)) end)
    return s
end


function hotfix.fileExists(path)
    return CCFileUtils:sharedFileUtils():isFileExist(path)
end

function hotfix.readFile(path)
    local file = io.open(path, "rb")
    if file then
        local content = file:read("*all")
        io.close(file)
        return content
    end
    return nil
end

function hotfix.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function hotfix.removePath(path)
    local mode = lfs.attributes(path, "mode")
    if mode == "directory" then
        local dirPath = path.."/"
        for file in lfs.dir(dirPath) do
            if file ~= "." and file ~= ".." then 
                local f = dirPath..file 
                hotfix.removePath(f)
            end 
        end
        os.remove(path)
    else
        os.remove(path)
    end
end

function hotfix.mkDir(path)
    if not hotfix.fileExists(path) then
        return lfs.mkdir(path)
    end
    return true
end

function hotfix.doFile(path)
    local fileData = CZHelperFunc:getFileData(path)
    local fun = loadstring(fileData)
    local ret, flist = pcall(fun)
    if ret then
        return flist
    end
    return flist
end

function hotfix.fileDataMd5(fileData)
    if fileData ~= nil then
        return CCCrypto:MD5(hotfix.hex(fileData), false)
    else
        return nil
    end
end

function hotfix.fileMd5(filePath)
    local data = hotfix.readFile(filePath)
    return hotfix.fileDataMd5(data)
end

function hotfix.checkFileDataWithMd5(data, cryptoCode)
    if cryptoCode == nil then
        return true
    end

    local fMd5 = CCCrypto:MD5(hotfix.hex(data), false)
    print("fMd5 "..fMd5)
    print("fMd5 "..cryptoCode)
    if fMd5 == cryptoCode then
        return true
    end

    return false
end

--检查文件MD5
function hotfix.checkFileWithMd5(filePath, cryptoCode)
    if not hotfix.fileExists(filePath) then
        print("md5 check file not exist:"..filePath)
        return false
    end
    local filemd5 = CCCrypto:MD5File(filePath) 
    print("md5 check :"..filePath)
    print("file md5 :"..filemd5)
    print("md5 :"..cryptoCode)
    return filemd5 == cryptoCode
    -- local data = hotfix.readFile(filePath)
    -- if data == nil then
    --     return false
    -- end

    -- return hotfix.checkFileDataWithMd5(data, cryptoCode)
end
--是否需要跨平台
--TODO 开发java相关
local function needInitPlatform()
    local needInit = false
    if hotfix.platform == "android" then
        local javaMethodName = "needInitPlatform"
        local javaParams = {}
        local javaMethodSig = "()Z"
        local ok, ret = hotfix.luaj.callStaticMethod(hotfix.javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            needInit = ret
        end
    elseif hotfix.platform == "ios" then
        local ok, ret = hotfix.luaoc.callStaticMethod(hotfix.ocClassName, "needInitPlatform")
        if ok then
            needInit = ret
        end
    end

    return needInit
end

--平台登录
function hotfix.initPlatform(callback)
    if needInitPlatform() then
        if hotfix.platform == "android" then
            local javaMethodName = "initPlatform"
            local javaParams = {
                    callback
                }
            local javaMethodSig = "(I)V"
            hotfix.luaj.callStaticMethod(hotfix.javaClassName, javaMethodName, javaParams, javaMethodSig)
        elseif hotfix.platform == "ios" then
            local args = {
                callback
            }
            hotfix.luaoc.callStaticMethod(hotfix.ocClassName, "initPlatform", args)
        else
            callback("successed")
        end
    else

        callback("successed")
    end
end
--获取App版本号
--TODO 开发跨平台的相关东西
function hotfix.getAppVersionCode()
    local appVersion = "1.0"
    if hotfix.platform == "android" then
        local javaMethodName = "getAppVersion"
        local javaParams = {}
        local javaMethodSig = "()Ljava/lang/String;"
        local ok, ret = hotfix.luaj.callStaticMethod(hotfix.javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            appVersion = ret
        end
    elseif hotfix.platform == "ios" then
        local ok, ret = hotfix.luaoc.callStaticMethod(hotfix.ocClassName, "getAppVersion")
        if ok then
            appVersion = ret
        end
    end
    return appVersion
end

--拷贝资源
function hotfix.copyRes()
    -- local filepath = CCFileUtils:sharedFileUtils():fullPathForFilename(hotfix.fListName);
    local ffile = hotfix.doFile(hotfix.fListName)
    local basePath = hotfix.writablePath.."/guagame"
    local dirPaths = ffile.dirPaths
    local filePaths = ffile.fileInfoList
    hotfix.mkDir(basePath)
    basePath = basePath.."/"
    hotfix.mkDir(basePath..".nomedia")
    for i=1,#(dirPaths) do
        hotfix.mkDir(basePath..dirPaths[i].name)
        print("mkdir"..basePath..dirPaths[i].name)
    end
    print("first make dirs ok")
    for k,v in pairs(filePaths) do
        print("begin copy :"..v.name)
        local data = CCFileUtils:sharedFileUtils():getFileData(v.name)
        hotfix.writefile(basePath..v.name,data)
    end
    print("begin copy flist")
    local fdata = CCFileUtils:sharedFileUtils():getFileData(hotfix.fListName)
    hotfix.writefile(basePath..hotfix.fListName,fdata)
    print("end copy flist")
    print("first copy files ok")
end

-- function hotfix.doCopy(path)
--     for file in lfs.dir(path) do
--         if file ~= "." and file ~= ".." then
--             local p = path..file
--             local attr = lfs.attributes(p)
--             if attr.mode == "directory" then
--                 hotfix.doCopy(p.."/")
--             else
--                 print("file :"..p)
--             end
--         end
--     end
-- end



function hotfix.performWithDelayGlobal(listener, time)
    local scheduler = CCDirector:sharedDirector():getScheduler()
    local handle = nil
    handle = scheduler:scheduleScriptFunc(function()
        scheduler:unscheduleScriptEntry(handle)
        listener()
    end, time, false)
end
--启动场景
function hotfix.runWithScene(scene)
    local curScene = sharedDirector:getRunningScene()
    if curScene then
        sharedDirector:replaceScene(scene)
    else
        sharedDirector:runWithScene(scene)
    end
end

--检查版本号
--v1 旧版本
--v2 新版本
--re false 无需更新
--   true  需要更新
function hotfix.checkAppVersion(v1,v2)
    local v1t = string.split(v1,".")
    local v2t = string.split(v2,".")
    local needUpdate = false
    for i = 1, #v1t do
        if v1t[i] < v2t[i] then
            needUpdate = true
            break
        elseif v1t[i] > v2t[i] then
            needUpdate = false
            break
        end
    end
    return needUpdate
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end