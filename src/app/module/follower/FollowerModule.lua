--弟子模块
local FollowerModule = class("FollowerModule",BaseModule)
local FollowerProcessor = import(".FollowerProcessor")
local FollowerFosterProcessor = import(".FollowerFosterProcessor")
local CommonFosterProcessor = import(".CommonFosterProcessor")
local SpecialFosterProcessor = import(".SpecialFosterProcessor")
local FollowerSkill = import(".FollowerSkill")
--显示弟子
FollowerModule.SHOW_FOLLOWER_VIEW = "SHOW_FOLLOWER_VIEW"
--显示培养
FollowerModule.SHOW_FOLLOWER_FOSTER = "SHOW_FOLLOWER_FOSTER"
--显示普通培养
FollowerModule.SHOW_COMMON_FOSTER = "SHOW_COMMON_FOSTER"
--显示专精培养
FollowerModule.SHOW_SPECIAL_FOSTER = "SHOW_SPECIAL_FOSTER"
--显示佣兵技能
FollowerModule.SHOW_FOLLOWER_SKILL = "SHOW_FOLLOWER_SKILL"
--佣兵技能改变
FollowerModule.FOLLOWER_SKILL_CHANGE = "FOLLOWER_SKILL_CHANGE"
--佣兵培养保存
FollowerModule.FOLLOWER_FOSTER_CHANGE = "FOLLOWER_FOSTER_CHANGE"

--四种培养
FollowerModule.USER_FOLLOWER_TRAIN = "user.follower_train"
--
FollowerModule.USER_CHANGE_FO_ACTION = "user.change_fo_action"
--培养后，保存或取消
FollowerModule.USER_CHANGE_TRAIN_STATUS = "user.change_train_status"
--专精培养
FollowerModule.USER_FOLLOWER_SPECIAL_TRAIN = "user.follower_special_train"
--佣兵换装
FollowerModule.USER_FOLLOWER_EQUIP_DRESS = "user.follower_equip_dress"
--刷新技能
FollowerModule.USER_FOLLOWER_SKILL_FLUSH = "user.follower_skill_flush"


function FollowerModule:ProcessorList()
	return {
		FollowerProcessor,
		FollowerFosterProcessor,
		CommonFosterProcessor,
		SpecialFosterProcessor,
		FollowerSkill
	}
end

return FollowerModule