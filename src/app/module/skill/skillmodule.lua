--聊天模块
local skillmodule = class("skillmodule", BaseModule)
local skillprocessor = import(".skillprocessor")
local selectskillprocessor = import(".selectskillprocessor")
local skillpvpprocessor = import(".skillpvpprocessor")
local selectskillpvpprocessor = import(".selectskillpvpprocessor")

skillmodule.SHOW_SKILL = "SHOW_SKILL"
skillmodule.SHOW_SELECT_SKILL = "SHOW_SELECT_SKILL"
skillmodule.UPDATE_SELECT_SKILL = "UPDATE_SELECT_SKILL"
skillmodule.UPDATE_SKILL_UNLOCK = "UPDATE_SKILL_UNLOCK"
skillmodule.UP_SKILL_ORDER = "UP_SKILL_ORDER"
skillmodule.USER_CHANGE_SKILL_ORDER = "user.change_skill_order"

skillmodule.SHOW_SKILL_PVP = "SHOW_SKILL_PVP"
skillmodule.SHOW_SELECT_SKILL_PVP = "SHOW_SELECT_SKILL_PVP"
skillmodule.UPDATE_SELECT_SKILL_PVP = "UPDATE_SELECT_SKILL_PVP"
skillmodule.UPDATE_SKILL_UNLOCK_PVP = "UPDATE_SKILL_UNLOCK_PVP"
skillmodule.UP_SKILL_ORDER_PVP = "UP_SKILL_ORDER_PVP"
skillmodule.USER_DEFAULT_SKILLS = "user.default_skills"

function skillmodule:ctor()
	skillmodule.super.ctor(self)
end

function skillmodule:ProcessorList()
	return {
		skillprocessor,
		selectskillprocessor,
		skillpvpprocessor,
		selectskillpvpprocessor,
	}
end
return skillmodule