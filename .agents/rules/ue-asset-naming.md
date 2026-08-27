# UE4 资产命名规则

## 连字符限制
虚幻引擎不支持文件名中包含 `-`（连字符）。创建蓝图时必须将模板名称中的连字符替换为 `_`（下划线）。

示例：
- `AC-VAL` → `BP_Weapon_Rifle_AC_VAL`
- `SCAR-L` → `BP_Weapon_Rifle_SCAR_L`
- `AKS-74U` → `BP_Weapon_Rifle_AKS_74U`

## 物品编辑器必须打开
创建物品蓝图时，物品编辑器 UI 必须处于打开状态。否则编辑器会使用 Default 规则分配错误的9位数 ItemID（如 831101001），而非正确的递增7位数 ID（如 8310050）。

检查方法（MCP可用时）：
```python
ctx = ue_read(queries=["ctx:"])
# 检查 opened_objed_tabs 是否包含 editor_type="Item"
```

打开方法：
```python
ue.objed_open_editor('Item')
```
