# SCUM - ItemQuickDrop

SCUM（人渣）UE4SS 客户端 Mod。在背包或容器界面里，鼠标指向物品时按快捷键快速丢出 / 取出物品。

## 功能

| 快捷键 | 效果 |
|--------|------|
| `F` | 从鼠标悬停的槽位丢出 **1 个** 物品 |
| `Shift + F` | 从鼠标悬停的槽位丢出 **整组** 物品 |

适用于：
- 玩家背包（WB_MainInventoryPanel）
- 各种容器 / 箱子 / 尸体 loot 界面
- 任何带网格槽位的 UI

## 安装

1. 先安装 [UE4SS (RE-UE4SS)](https://docs.ue4ss.com/) 到你的 SCUM 游戏目录
2. 把本 mod 的文件夹放到 `SCUM/Binaries/Win64/Mods/ItemQuickDrop/`
3. 确保目录结构：
   ```
   Mods/
   └── ItemQuickDrop/
       ├── mod.json
       └── Scripts/
           └── main.lua
   ```
4. 启动游戏，进游戏后按 `F10` 打开 UE4SS 控制台，看到 `[ItemQuickDrop] 加载完成！` 就说明装好了

## 配置

编辑 `mod.json` 里的 `default_settings`：

```json
{
  "key_single": "F",
  "key_stack": "F",
  "modifier_stack": "SHIFT",
  "debug": false
}
```

- `debug: true` 会在控制台输出详细日志，方便调试

## 调试 / 适配说明

SCUM 不同版本的 UI 类名和内部函数名可能有差异。如果装上去按 F 没反应，需要：

1. 打开 UE4SS 的 **Object Dumper**（默认 `Ctrl+J`）或 **UHT Dumper**，dump 出游戏的类名
2. 在 `main.lua` 的 `panel_class_names` 列表里，把你游戏版本真实的背包面板类名加到最前面
3. 在 `drop_item_from_slot()` 函数里，按实际的丢物品函数名打开对应的调用注释

常见需要确认的点：
- 背包面板控件类名（比如 `WB_MainInventoryPanel_C`）
- 槽位控件里的物品引用字段名（`Item` / `ItemRef` / `InventoryItem`）
- 丢物品的 RPC 函数名（`DropItem` / `ServerDropItem` 等）

## 技术栈

- [UE4SS (RE-UE4SS)](https://docs.ue4ss.com/) - Unreal Engine 4/5 Scripting System
- Lua 脚本 API

## 版本

- v1.0.0 - 初始版本
