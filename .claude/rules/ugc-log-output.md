# AI Rule: UGC 日志输出规范（真机/模拟器日志抓取）

> 状态: v1.0 | 适用: UGC01_Zombie (UE4.18 + 和平精英 UGC 平台)
> 创建: 2026-08-04 | 来源: 真机/模拟器日志抓取实战踩坑

## 核心坑点（一句话）

**`ugcprint`（以及任何仅封装 `ugcprint` 的打印函数）在真机/模拟器上不会写入 `ShadowTrackerExtra.log` 日志文件。**

需要从日志文件分析问题时，**必须使用 Lua 原生 `print`**。

## 详细说明

| 打印方式 | 输出到 ShadowTrackerExtra.log | 输出到 UGC 调试面板/LogMain | 用途 |
|---|---|---|---|
| Lua 原生 `print` | ✅ 是（LogNula: LuaLog） | ❌ | 真机/模拟器日志文件分析 |
| `ugcprint()` | ❌ 否 | ✅ 是 | 游戏内调试面板显示 |
| `GameplayUtils.Print()`（ugcprint 封装） | ❌ 否 | ✅ 是 | 同上 |

**已验证事实**：
- `GameplayUtils.Print` 内部是 `ugcprint` 的封装（`Script/Gameplay/Utils/Utils.lua`）
- 框架文件 `Content/LuaHelper/Source/Lua/common/ugcprint.lua` 中的 `ugcprint` 是 C++ 绑定（仅函数签名存根，实际实现为引擎 UGC 日志系统）
- 真机/模拟器日志文件（`ShadowTrackerExtra.log`，XOR 0x73 混淆）只收录 `LogNula: LuaLog` 前缀的原生 print 输出

## 代码示例

### ❌ 错误做法（抓日志会"消失"）

```lua
-- GameplayBooter.lua 中的日志，真机/模拟器上不会出现在 ShadowTrackerExtra.log
function GameplayBooter.BeginPlayOnClient()
    GameplayUtils.Print("[客户端] 启动Gameplay相关子系统'")  -- ← 搜不到！
end
```

### ✅ 正确做法（日志文件可搜到）

```lua
function GameplayBooter.BeginPlayOnClient()
    print("[客户端] 启动Gameplay相关子系统")   -- ← 会写入 ShadowTrackerExtra.log
end
```

### 调试期临时方案（不改业务代码）

```lua
-- 在需要追踪的函数里临时加一行原生 print
function BP_InteractEntityComponent:OnRep_InstanceID()
    print("OnRep_InstanceID: 获得实例ID", self.InstanceID)  -- 日志文件可追踪
    -- ... 原有逻辑
end
```

## 陷阱列表

1. **搜索关键词陷阱**：用 `grep "启动Gameplay"` 搜不到 = 不代表代码没执行。可能是 `ugcprint` 没写入日志文件。**先确认代码里用的是 `print` 还是 `ugcprint` 再下结论**。
2. **回调名大小写**：Lua 复制回调 `OnRep_InstanceID`（大写 I），不是 `OnRep_m_instanceID`。搜索时注意实际代码中的函数名。
3. **DS/客户端视角混入**：客户端日志中 `UGC_LogMain_Popups_UIBP:OnReceiveLogsFromDS()` 是**客户端 UI 显示 DS 转发的 TagLog**，不是客户端进程自身执行的日志。区分方法：看行是否以 `LogNula: LuaLog:` 直接开头（客户端自身）还是 `UGC_LogMain_Popups_UIBP` 前缀（DS 转发显示）。
4. **Grep 日志前先看源码**：抓日志分析前，先确认目标打印点用的什么函数（`print` / `ugcprint` / `GameplayUtils.Print`），避免"搜不到就以为没执行"的误判。
5. **ugcprint 保留用途**：游戏内调试面板/LogMain 显示仍用 `ugcprint`（它负责 UI 日志列表），两者不冲突——需要文件日志用 print，需要面板显示用 ugcprint。

## 验证方法

- 抓取日志：`python UGCProjects/fetch_mumu_logs.py <adb端口>`（自动 pull + XOR 0x73 解密到 `Saved/Logs/UGC01_Zombie/Clientlog/Decoded/`）
- 验证某打印是否写入：解密的日志中搜索 `LogNula: LuaLog:` + 你的内容前缀
- 若搜不到但代码确实执行了 → 检查是否用了 `ugcprint` 系函数
