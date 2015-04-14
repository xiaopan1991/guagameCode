-- 声音管理器
-- Author: whe
-- Date: 2014-12-03 16:00:53
--

local AudioManager = class("SoundManagerger")

function AudioManager:ctor()

end

--[[音乐]]
--播放音乐
--filename    音乐文件id or 文件名
--loop   是否循环
function AudioManager:playMusic(filename,loop)
	audio.playMusic(filename, loop)
end
--暂停音乐
function AudioManager:pauseMusic()
	audio.pauseMusic()
end
--停止音乐
function AudioManager:stopMusic()
	audio.stopMusic()
end

--[[音效]]
function AudioManager:playSound(filename,loop)
	audio.playSound(filename,loop)
end


--暂停播放
function AudioManager:pause()
	audio.pauseMusic()
	audio.pauseAllSounds()
end

--停止播放音乐
function AudioManager:stop()
	audio.stopMusic()
	audio.stopAllSounds()
end

--恢复播放音乐
function AudioManager:resume()
	audio.resumeAllSounds()
	audio.resumeMusic()
end
--检查当前是否播放音乐
function AudioManager:isMusicPlaying()
	return audio.isMusicPlaying()
end
return AudioManager