# UE 网络系统讨论汇总

> 基于 OasisEra (UE 4.18 魔改版) 项目的网络相关技术讨论整理
> 整理日期：2026-07-10

---

## 目录

1. [Server Tick 频率调整](#1-server-tick-频率调整)
2. [项目现有 Tick 配置排查](#2-项目现有-tick-配置排查)
3. [官方文档中的 Tick 相关信息](#3-官方文档中的-tick-相关信息)
4. [服务端与客户端对象对应机制](#4-服务端与客户端对象对应机制)
5. [UActorComponent 的网络身份](#5-uactorcomponent-的网络身份)
6. [Multicast RPC 的作用域限制](#6-multicast-rpc-的作用域限制)
7. [从组件向所有客户端广播消息的方案](#7-从组件向所有客户端广播消息的方案)
8. [UE Material Masking 的实现机制](#8-ue-material-masking-的实现机制)

---

## 1. Server Tick 频率调整

### 1.1 核心控制变量

| 变量 | 类型 | 作用 | 设置方式 |
|------|------|------|----------|
| `NetServerMaxTickRate` | int32 | 服务器最大 Tick 频率上限 | Engine.ini / 控制台 |
| `bClampListenServerTickRate` | uint32 | 是否限制 Listen Server Tick | Engine.ini |
| `MaxClientRate` | int32 | 单客户端最大出站字节/秒 | Engine.ini |
| `MaxInternetClientRate` | int32 | 互联网客户端速率上限 | Engine.ini |

### 1.2 配置方式

**Engine.ini 配置：**
```ini
[/Script/Engine.NetDriver]
NetServerMaxTickRate=30
bClampListenServerTickRate=true
MaxClientRate=15000
```

**控制台命令（运行时）：**
```
net.ServerMaxTickRate=60
```

### 1.3 Actor/Component 级别 Tick 控制

```lua
-- 设置 Actor Tick 间隔
actor:SetActorTickInterval(0.033)  -- 约 30 Hz

-- 设置 Component Tick 间隔
component:SetComponentTickInterval(0.05)  -- 约 20 Hz

-- 魔改版专属：DS 专属 Tick 间隔
-- UActorComponent.DSTickInterval > 0 时覆盖 PrimaryComponentTick.TickInterval
-- 仅影响 Dedicated Server，客户端不受影响

-- 启用/禁用 Tick
actor:SetActorTickEnabled(false)
component:SetComponentTickEnabled(false)
```

### 1.4 Listen Server vs Dedicated Server

| 模式 | Tick 频率控制 | 备注 |
|------|--------------|------|
| Dedicated Server | `net.ServerMaxTickRate` 独立控制 | 与客户端完全解耦 |
| Listen Server | 与客户端帧率耦合 | 需配合 `t.MaxFPS` 控制 |

---

## 2. 项目现有 Tick 配置排查

### 2.1 引擎级配置

项目中 **未找到** 任何显式的 Tick 频率配置：
- 无 `ServerMaxTickRate`
- 无 `NetDriver` 配置
- 无 `MaxFPS` / `MaxFrameRate`
- 无 `TickInterval` / `PrimaryActorTick`
- 无 `SetActorTickEnabled` / `SetTickGroup`

**结论：项目完全依赖引擎默认值。**

### 2.2 Lua 层 Tick 分发架构

项目自建 GameplayBooter 框架管理所有 Lua 子系统的 Tick：

```
  UGCGameMode:ReceiveTick(DeltaTime)     ← 服务端 Tick 入口
      └─ GameplayBooter.OnTick(true, DeltaTime)

  UGCPlayerController:ReceiveTick(DeltaTime) ← 客户端 Tick 入口
      └─ GameplayBooter.OnTick(false, DeltaTime)
```

GameplayBooter 内部维护三个列表：

| 列表 | 注册条件 | 触发时机 |
|------|----------|----------|
| `m_tickList` | 系统实现了 `OnTick()` | 每帧（服务端+客户端） |
| `m_serverTickList` | 系统实现了 `OnServerTick()` | 仅服务端 |
| `m_clientTickList` | 系统实现了 `OnClientTick()` | 仅客户端 |

### 2.3 各子系统 Tick 状态

| 子系统 | Tick 方式 | 状态 |
|--------|-----------|------|
| InteractEntitySystem | `OnTick()` | ✅ 活跃 |
| BP_ZombieWaveManager | `ReceiveTick()` | ✅ 活跃 |
| MonsterSpawnerManager | `ReceiveTick()` | ❌ 已注释 |
| UGCPlayerPawn | `ReceiveTick()` | ❌ 已注释 |
| UGCAttributeGroup_Base | `ReceiveTick()` | ❌ 已注释 |
| Action_PlayerLeave (Update) | Action Tick | ❌ 已注释 |

**实际每帧在跑的 Tick 只有 2 个：InteractEntitySystem 和 ZombieWaveManager。**

### 2.4 推荐的 Tick 优化方案

| 方案 | 实现方式 | 适用场景 |
|------|----------|----------|
| 引擎级配置 | Engine.ini `NetServerMaxTickRate` | 需要引擎层权限 |
| Actor/Component 级 | `SetActorTickInterval()` / `DSTickInterval` | 精细控制 |
| Lua 层节流 | GameplayBooter 中加帧率计数器 | 最灵活，无需改引擎 |

---

## 3. 官方文档中的 Tick 相关信息

### 3.1 UNetDriver API（.projdoc/api）

```yaml
UNetDriver:
  NetServerMaxTickRate: int32    # 服务器最大 Tick 频率
  bClampListenServerTickRate: uint32  # 是否限制 Listen Server Tick
  MaxClientRate: int32           # 单客户端最大出站字节/秒
  MaxInternetClientRate: int32   # 互联网客户端速率上限
```

> 文档标注为 "@todo document"，说明官方尚未完善文档，但属性真实可用。

### 3.2 UActorComponent API（魔改新增属性）

```yaml
UActorComponent:
  DSTickInterval: float          # DS 专属 Tick 间隔（魔改新增）
    # "The frequency in seconds at which this tick function will be executed on DS.
    #  If <= 0 then it will tick every frame.
    #  If > 0 will cover PrimaryComponentTick.TickInterval"
    #  标注: "Add by zoranouyang"
  NetUpdateFrequency: float      # 网络复制频率
  bSupportSuspendTick: bool      # 是否支持挂起 Tick
  bEnableTickWhenOutOfRegion: bool  # 区域外是否允许 Tick
```

### 3.3 Wiki 文档建议

- **348_性能优化总览**："避免Tick中的复杂逻辑：使用基于事件的触发机制"
- **20217_法术场**："CheckType 不推荐使用Tick，会有额外的性能消耗"
- **199_UMG Lua的结构**："Tick 会在每一帧调用该事件"

---

## 4. 服务端与客户端对象对应机制

### 4.1 核心概念：NetGUID

UE 用 **NetGUID**（Network Global Unique Identifier）标识每个可复制的 Actor/Component。服务端和客户端通过这个 ID 对应同一个对象。

```
  服务端                          客户端
  ──────                          ──────
  Actor: PlayerController_A       Actor: PlayerController_A
  NetGUID: 100                    NetGUID: 100
       │                               │
       └──── 通过 NetGUID 对应 ────────┘
```

### 4.2 连接建立流程

```
  服务端                                    客户端
  ──────                                    ──────
  1. 客户端连接请求
       ◄──────────────────────────────────  TCP/UDP 连接

  2. 服务端创建 UNetConnection
  3. 服务端为该连接创建 PlayerController
  4. 分配 NetGUID: 100
  5. 发送 "Actor 100 = PlayerController" 映射
       ──────────────────────────────────►  客户端创建本地代理
                                            记录 NetGUID=100

  6. 服务端复制 Pawn 给该连接
  7. 分配 NetGUID: 200
  8. 发送 "Actor 200 = Pawn" 映射
       ──────────────────────────────────►  客户端创建 Pawn 代理
```

### 4.3 NetGUID 映射表结构

```
UNetConnection
├── PackageMap          ← NetGUID ↔ UClass/Actor 映射
│   └── GuidMap         ← TMap<FGuid, FNetGuidMapItem>
│       ├── NetGUID=100 → PlayerController_A
│       ├── NetGUID=200 → Pawn_A
│       └── NetGUID=300 → GameState
└── ActorGuidMap        ← TMap<AActor*, FNetworkObjectInfo>
    ├── PlayerController_A → {NetGUID=100, Location, Frequency}
    └── GameState          → {NetGUID=300, Location, Frequency}
```

### 4.4 Actor Role（角色）

| 位置 | Role | RemoteRole | 说明 |
|------|------|------------|------|
| 服务端 | `ROLE_Authority` | `ROLE_AutonomousProxy` | 拥有控制权 |
| 拥有者客户端 | `ROLE_AutonomousProxy` | `ROLE_Authority` | 本地控制，可发输入/RPC |
| 其他客户端 | `ROLE_SimulatedProxy` | `ROLE_Authority` | 模拟，只接收同步 |

### 4.5 RPC 路由规则

| RPC 类型 | 调用端 | 执行端 | 条件 |
|----------|--------|--------|------|
| `Server` | 客户端 | 服务端 | 调用者必须是 AutonomousProxy |
| `Client` | 服务端 | 拥有者客户端 | 仅该连接的客户端执行 |
| `Multicast` | 服务端 | 所有客户端 + 服务端 | 该 Actor 的所有实例执行 |

---

## 5. UActorComponent 的网络身份

### 5.1 核心结论

**UActorComponent 默认不分配独立的 NetGUID。**

| 特性 | Actor (AActor) | Component (UActorComponent) |
|------|----------------|----------------------------|
| 独立 NetGUID | ✅ 有 | ❌ 没有 |
| 独立 ActorChannel | ✅ 有 | ❌ 共用 Owner 的 |
| 复制标识 | NetGUID | ObjID + RepKey |
| 远程引用 | 通过 NetGUID 定位 | 通过 Owner Actor + 属性路径定位 |
| RPC 支持 | ✅ Server/Client/Multicast | ⚠️ 仅通过 Owner Actor 转发 |
| Relevancy 检查 | ✅ 独立检查 | ❌ 跟随 Owner Actor |

### 5.2 组件的复制方式

**方式 1：属性复制**
```
Actor: PlayerController_A (NetGUID=100)
    │
    ├── Replicated Property: MyComponent (UActorComponent*)
    │   → 服务端写入属性值 → 客户端接收后自动创建/引用对应组件
    │
    └── 客户端通过 Actor 的 RepLayout 定位组件
```

**方式 2：SubObject 复制（ActorChannel 内部管理）**
```
ActorChannel (对应 PlayerController_A)
    │
    ├── ObjID=0 → 主 Actor 属性
    ├── ObjID=1 → Component_A  ← 用 ObjID 标识，不用 NetGUID
    ├── ObjID=2 → Component_B
    └── ...
```

源码注释（ActorChannel.h:196-207）：
```
// Concepts:
//   ObjID  - arbitrary identifier given by game code
//   RepKey - identifier for current replicated state
//
// ObjID should be constant per object or "category".
```

### 5.3 OasisEra 项目的子对象复制

```lua
-- UGCPlayerController.lua
function UGCPlayerController:GetReplicatedProperties()
    return {"bIsTeamLeader", "Lazy"}, {"LobbyTeammatePlayerKeys", "Lazy"}, {"LobbyInfo", "Lazy"}
end

-- UGCPlayerPawn.lua
function UGCPlayerPawn:GetReplicatedProperties()
    return {"__SubObjectRepList", "Lazy"}
end
```

`"__SubObjectRepList"` 告诉引擎该 Actor 的子对象列表需要复制，通过 ActorChannel 内部的 ObjID 机制追踪。

---

## 6. Multicast RPC 的作用域限制

### 6.1 问题现象

从 PlayerController 的组件发出 Multicast RPC，其他客户端的 PlayerController 收不到。

### 6.2 原因分析

```
  客户端 A 的 PlayerController_A
      │
      ├── 组件: BP_PlayerInteractEntityComponent
      │       └── ResponseToAllClients()  ← Multicast RPC
      │
      ▼
  Multicast 调用
      │
      ├── 服务端: PlayerController_A  ✅ 执行
      ├── 客户端 A: PlayerController_A  ✅ 执行
      ├── 客户端 B: PlayerController_A  ✅ 执行（但 B 上没有 A 的 PC）
      └── 客户端 B: PlayerController_B  ❌ 不执行（不是同一个 Actor 实例）
```

**核心问题**：Multicast RPC 只在 **被调用的那个 Actor 实例** 上执行。每个客户端有自己的 PlayerController，客户端 B 上不存在客户端 A 的 PlayerController。

### 6.3 源码证据

```cpp
// UNetDriver::ProcessRemoteFunction
virtual void ProcessRemoteFunction(
    AActor* Actor,           // ← RPC 绑定到这个 Actor
    UFunction* Function,
    void* Parameters,
    FOutParmRec* OutParms,
    UFrame* Stack,
    UObject* SubObject       // ← SubObject 可选，但仍在 Actor 通道内
);

// ActorChannel.h
virtual void ProcessRemoteFunction(
    AActor* Actor,
    UFunction* Function,
    void* Parameters,
    FOutParmRec* OutParms,
    UFrame* Stack,
    class UObject* SubObject = nullptr  // ← 即使指定 SubObject
);                                      //   仍然走 Actor 的 ActorChannel
```

### 6.4 结论

> **UE 的 Multicast RPC = "这个 Actor 的所有实例都执行"，不是"所有同类对象都执行"。Component 没有独立网络身份，它的 RPC 归属到 Owner Actor 上。**

---

## 7. 从组件向所有客户端广播消息的方案

### 7.1 方案对比

| 方案 | 实现方式 | 优点 | 缺点 | 推荐度 |
|------|----------|------|------|--------|
| GameState Multicast | 服务端调用 GameState 的 Multicast RPC | 所有客户端共享 Actor | 需要修改 GameState | ⭐⭐⭐ |
| 服务端遍历 PC | 遍历所有 PlayerController 发 Client RPC | 精确控制每个客户端 | 服务端逻辑复杂 | ⭐⭐ |
| GenericMessageSystem | 使用项目已有的消息系统 | 改动最小，基础设施完善 | 仅本地通知 | ⭐⭐⭐⭐ |

### 7.2 方案 1：GameState Multicast

```lua
-- 服务端：在 GameState 上添加 Multicast RPC
function UGCGameState:Multicast_ResponseToAllClients(MessageData)
    -- 在所有客户端执行
    UGCGenericMessageSystem.BroadcastGlobalMessage("YourEventName", MessageData)
end

-- 客户端：通过 Server RPC 请求广播
function BP_PlayerInteractEntityComponent:ResponseToAllClients(Data)
    local gameState = UGCGameSystem.GetGameState()
    UnrealNetwork.CallUnrealRPC(self, gameState, "Multicast_ResponseToAllClients", Data)
end
```

### 7.3 方案 2：服务端遍历 PlayerController

```lua
function SomeSystem:ResponseToAllClients(Data)
    local allPlayerControllers = UGCGameSystem.GetAllPlayerControllers()
    for _, pc in pairs(allPlayerControllers) do
        UnrealNetwork.CallUnrealRPC(self, pc, "Client_ReceiveResponse", Data)
    end
end
```

### 7.4 方案 3：GenericMessageSystem（推荐）

```lua
-- 服务端发送
UGCGenericMessageSystem.BroadcastGlobalMessage("InteractResponse", data)

-- 各客户端监听
UGCGenericMessageSystem.ListenGlobalMessage(self, "InteractResponse", self, self.OnReceiveResponse)
```

**推荐使用方案 3**，因为项目已有完整的 GenericMessageSystem 基础设施，改动最小。

---

## 8. UE Material Masking 的实现机制

### 8.1 传统路径（UE 4.18 + UE 5.7 非 Nanite）

Material Masking 通过 `clip()`（discard）实现，定义在 `MaterialTemplate.ush` 的 `GetMaterialCoverageAndClipping()` 中。

**变体 A：标准 clip()**
```hlsl
// MaterialTemplate.ush
clip(GetMaterialMask(PixelMaterialInputs));
// Mask <= 0 → 像素被丢弃
```

**变体 B：Dithered Masking（抗锯齿优化）**
```hlsl
// UE 4.18: 使用有序 Dither
float Dither = (Dither5 * 5 + Noise) * (1.0 / 6.0);
clip(GetMaterialMask(PixelMaterialInputs) + Dither - 0.5);

// UE 5.7: 改用 Blue Noise
float Noise2 = ViewScalarBlueNoise(SvPosition.xy, FrameIndex);
float Dither = 0.83f * Noise2;
return GetMaterialMask(PixelMaterialInputs) + Dither - 0.5f;
```

**变体 C：Alpha-to-Coverage（MSAA 路径）**
```hlsl
// 将 Mask 值映射为 MSAA 逐采样覆盖率位掩码
uint GetDerivativeCoverageFromMask(float MaterialMask)
{
    uint Coverage = 0x0;
    if (MaterialMask > 0.010) Coverage = 0x08;
    if (MaterialMask > 0.125) Coverage = 0x18;
    if (MaterialMask > 0.250) Coverage = 0x19;
    if (MaterialMask > 0.375) Coverage = 0x39;
    if (MaterialMask > 0.500) Coverage = 0x3D;
    if (MaterialMask > 0.625) Coverage = 0x7D;
    if (MaterialMask > 0.750) Coverage = 0x7F;
    if (MaterialMask > 0.875) Coverage = 0xFF;
    return Coverage;
}
// 仅当所有位为 0 时才 clip()
```

### 8.2 Nanite 路径（UE 5.7）

Nanite **不使用 clip()**，而是通过 ShadingMask 编码：

```hlsl
// BasePassPixelShader.usf:2658
// Even with masking and/or pixel depth offset, Nanite never uses actual clip() or SV_Depth
#define PIXELSHADER_EARLYDEPTHSTENCIL EARLYDEPTHSTENCIL
```

```
Nanite Rasterizer
  │
  ├── Depth 阶段: 不执行 clip()，所有三角形都写入深度
  │   └── ShadingMask 编码材质属性（包括 Mask 信息）
  │
  └── Shading 阶段: 根据 ShadingMask 决定是否着色
      └── Masked 像素在 Shading 阶段被跳过
```

### 8.3 对比总结

| 路径 | Masking 方式 | 是否 discard | 影响 Early-Z |
|------|-------------|-------------|-------------|
| 传统 Masked | `clip(mask)` | ✅ 是 | ❌ 破坏 |
| Dithered Mask | `clip(mask + dither - 0.5)` | ✅ 是（随机化） | ❌ 破坏 |
| Alpha-to-Coverage | MSAA Coverage bits + clip | ⚠️ 仅全遮挡时 | ⚠️ 部分破坏 |
| **Nanite** | **ShadingMask 编码** | **❌ 否** | **✅ 不破坏** |

### 8.4 对 OasisEra (UE 4.18) 的影响

- 没有 Nanite，Masking 就是通过 `clip()` 实现
- `clip()` 会破坏 Early-Z → 导致 overdraw
- 减少 Masked 材质使用面积、合理设置 `ClipMaskClipValue`（默认 0.333）可降低 clip 触发率

---

## 附录：关键术语对照

| 中文 | 英文 | 说明 |
|------|------|------|
| 服务器 Tick 频率 | Server Tick Rate | 服务端每秒执行逻辑帧的次数 |
| 网络全局唯一标识符 | NetGUID (Network Global Unique Identifier) | UE 用于标识可复制对象的 ID |
| 属性复制 | Property Replication | 服务端属性变化推送到客户端 |
| 远程过程调用 | RPC (Remote Procedure Call) | 跨网络调用函数 |
| 多播 RPC | Multicast RPC | 服务端调用，所有客户端执行 |
| 服务端 RPC | Server RPC | 客户端调用，服务端执行 |
| 客户端 RPC | Client RPC | 服务端调用，拥有者客户端执行 |
| 权威端 | Authority | 拥有对象控制权的一端（通常是服务端） |
| 自主代理 | Autonomous Proxy | 拥有者客户端上的本地控制代理 |
| 模拟代理 | Simulated Proxy | 非拥有者客户端上的模拟代理 |
| 网络裁剪 | Net Culling | 根据距离决定是否复制 Actor |
| 抖动遮罩 | Dithered Masking | 通过 Dither 实现半透明边缘效果 |
| 接近遮罩映射 | Parallax Occlusion Mapping (POM) | 视差映射技术 |
| 放松锥体步进映射 | Relaxed Cone Step Mapping (RCSM) | 改进的视差映射加速技术 |
