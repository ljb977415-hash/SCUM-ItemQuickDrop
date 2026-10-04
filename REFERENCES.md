# 参考案例

本 mod 的实现思路参考了以下开源 UE4SS 项目：

---

## 1. PalItemInspector (Palworld / 帕鲁)

**仓库**: https://github.com/JuniorMiksza8/PalItemInspector

**参考点**:
- 槽位控件类名探测方式（`WBP_PalCommonItemSlotButton_C` 等）
- 多字段备选提取物品引用（`Item` / `ItemRef` / `ItemSlot` / `MyItemSlot` ...）
- 所有 UE 调用都用 `pcall` 包装，防止游戏崩溃
- 按键绑定系统：解析 "SHIFT+F" 字符串为 Key 枚举 + Modifier 数组
- `RegisterHook` 拦截槽位点击事件的思路
- 玩家控制器缓存 + 延迟重试模式

---

## 2. evrima-dev-knowledge (The Isle EVRIMA)

**仓库**: https://github.com/diplomatic-tendencies/evrima-dev-knowledge

**参考点**:
- 客户端 mod 的安全边界（EAC 反作弊检测范围）
- 尽量把逻辑放服务端，客户端只做输入转发
- Lua 安全规则：不要在输入线程直接碰 UObject，用队列调度
- `.pak` 资源 mod vs `.lua` 逻辑 mod 的适用场景

---

## 3. RVThereYet-GearHotkeys

**仓库**: https://github.com/bitterbutt/RVThereYet-GearHotkeys

**参考点**:
- 可配置按键的 mod 结构
- `config.lua` 分离配置和逻辑的写法

---

## 4. UE4SS 官方文档

**文档**: https://docs.ue4ss.com/

**关键 API**:
- `RegisterKeyBind(Key.XXX, callback)` — 绑定单键
- `RegisterKeyBind(Key.XXX, {modifier_keys}, callback)` — 绑定组合键
- `RegisterHook("/Path/To/Class:FunctionName", callback)` — 拦截 UFunction
- `FindFirstOf("ClassName")` / `FindAllOf("ClassName")` — 查找游戏对象
- `UEHelpers.GetPlayerController()` — 获取本地玩家控制器

---

## 适配 SCUM 时需要确认的点

1. **背包面板类名** — 用 UE4SS Object Dumper（默认 `Ctrl+J`）在游戏里查
2. **槽位控件类名** — 查真实的槽位 Button 类
3. **物品引用字段名** — 槽位里存物品的字段叫什么
4. **丢物品 RPC** — 玩家/角色上的丢物品函数叫什么
5. **转移物品 RPC** — 容器到玩家背包的转移函数叫什么
