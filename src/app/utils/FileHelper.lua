local FileHelper = {}


--写文件
--path 文件路径  全路径 绝对
--文件内容
--模式
function FileHelper.writefile(path,content,mode)
	local md = mode or "w+b"
    local file = io.open(path, md)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

--读取文件
function FileHelper.readfile(filepath)
	local fileData = nil
	if cc.FileUtils:getInstance():isFileExist(filepath) then
		fileData = CZHelperFunc:getFileData(filepath)
	end
	return fileData
end