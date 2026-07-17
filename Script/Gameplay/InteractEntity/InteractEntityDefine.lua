

EInteractEntityErrCode = {
    None                = 0,   -- 成功
    FailInvalid        = 1,   -- 实体无效(不存在或已销毁)
    FailOutOfRange     = 2,   -- 玩家不在交互范围内
    FailNoConfig       = 3,   -- 配置不存在
    FailPlayerInvalid  = 4,   -- 玩家状态无效
    FailUnavailable    = 5,   -- 实体当前不可用
    FailInCooldown     = 6,   -- 冷却中
    FailExhausted      = 7,   -- 使用次数耗尽(全局)
    FailNoBehaviourHandler      = 8,   -- 无对应类型的 Handler
    FailServerError    = 9,   -- 服务端执行异常
    FailNotEnoughScore = 10,  -- 积分不足
    FailAlreadyUsed    = 11,  -- 已使用过(per-player 限制)
    FailBehaviourComponentUnavailable    = 13,   -- 行为组件当前不可用
    FailNotOverlapped = 13, --未发生碰撞
    FailAmmoAlreadyFully = 14,--已是满弹药状态
    FailAlreadyDrawing = 15,--
}