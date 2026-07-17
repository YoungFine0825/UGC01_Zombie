每次切 Mode 都是整个 DS 进程重启

每个会话里都完整出现一遍：
InitGame（构造 GameMode/GameState）→ UGCGameMode:ReceiveBeginPlay（新 ModeID）→ UGCGameStateBase::BeginPlay → ObjectClass[UGCPlayerController_C] 新建 → [UGCPlayerState] BeginPlay。

所以 GameMode / GameState / PlayerController / PlayerState / 所有 Actor / 整个 Lua VM 全部销毁重建。MultiMode 切 Mode 本质 = 重新匹配 → 重新分配一台 DS，旧 DS 直接关停。