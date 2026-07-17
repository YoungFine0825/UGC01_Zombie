# UGC 向量运算规则

## FVector 是 userdata，不能直接用 Lua 算术运算符

**现象**：`K2_GetActorLocation()` 等 API 返回的 `FVector` 是 userdata 对象，不支持 Lua 的 `+`、`-`、`*` 等运算符，也不支持 `:Size()` 等方法。直接使用会导致运行时错误。

```lua
-- ❌ 错误
local locA = actorA:K2_GetActorLocation()
local locB = actorB:K2_GetActorLocation()
local dist = (locA - locB):Size()  -- 运算符对 userdata 无效
local mid = locA + locB             -- 同上
```

**正确做法**：所有向量运算必须通过 `UGCMathUtility` 提供的函数完成。

```lua
-- ✅ 正确
local locA = actorA:K2_GetActorLocation()
local locB = actorB:K2_GetActorLocation()
local diff = UGCMathUtility.SubtractVector(locA, locB)  -- 向量减法
local dist = UGCMathUtility.VSize(diff)                   -- 向量长度
local mid  = UGCMathUtility.AddVector(locA, locB)        -- 向量加法
```

## 常用 UGCMathUtility 向量函数

| 函数 | 说明 |
|---|---|
| `UGCMathUtility.AddVector(A, B)` | A + B |
| `UGCMathUtility.SubtractVector(A, B)` | A - B |
| `UGCMathUtility.MultiplyVector(V, Scalar)` | V * 标量 |
| `UGCMathUtility.VSize(V)` | 向量长度（标量） |
| `UGCMathUtility.VSizeSquared(V)` | 向量长度平方（避免开方，比较距离时更高效） |
| `UGCMathUtility.Normalize(V)` | 单位化向量 |
| `UGCMathUtility.DotProduct(A, B)` | 点积 |
| `UGCMathUtility.CrossProduct(A, B)` | 叉积 |
