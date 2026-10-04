# SCUM 专用参考资料

## 已确认的类名（来自 SCUM 官方文档）

### 玩家
- **Prisoner** / **BP_Prisoner_C** — 玩家角色类
- 获取方式：`FindAllOf("Prisoner")`

### 背包 UI
- **WB_MainInventoryPanel** — 主背包面板
- **WB_OnBodyInventory** — 身体穿戴/背包区域
- 基础背包格子：24 cells

### 物品类型
- `World.Items.Types.Bag` — 背包类物品

---

## 待 Dumper 确认的类名

用 UE4SS 的 Object Dumper（默认 `Ctrl+J`）在游戏里查：

### 容器/箱子/尸体面板
- WB_ContainerPanel_C?
- WB_LootPanel_C?
- WB_ChestPanel_C?
- WB_CorpsePanel_C?

### 槽位控件
- 物品槽位按钮类名是什么？
- 槽位里物品引用的字段名？（Item / ItemRef / ItemSlot...）
- 数量字段名？（Quantity / Count / StackCount...）

### 丢物品 / 转移物品 RPC
- Prisoner 上的丢物品函数叫什么？
- 容器到玩家背包的转移函数叫什么？

---

## 参考来源

1. **SCUM Server Automation (SSA)** — 官方 UE4SS mod 示例
   https://github.com/Spidees/SCUM-Server-Automation
   - 确认了 `FindAllOf("Prisoner")` 写法
   - 确认了 pcall + IsValid() 安全写法
   - 确认了 config.txt 配置文件写法

2. **SCUM 官方 mod 开发文档**
   - 确认了 `WB_MainInventoryPanel` / `WB_OnBodyInventory` 类名
   - 确认了背包格子结构

3. **UE4SS 官方文档**
   https://docs.ue4ss.com/
   - `RegisterKeyBind` 按键绑定
   - `FindFirstOf` / `FindAllOf` 对象查找
   - `LoopAsync` 定时循环
