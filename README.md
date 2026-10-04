# SCUM - ItemQuickDrop

SCUM（人渣）UE4SS 客户端 Mod。在背包或容器界面里，鼠标指向物品时按快捷键快速操作。

## 功能（双向模式）

| 鼠标悬停位置 | 单键（默认 `F`） | 修饰键+单键（默认 `Shift+F`） |
|-------------|------------------|-------------------------------|
| **自己背包里的物品** | 丢出 1 个到地上 | 丢出整组到地上 |
| **箱子/容器/尸体里的物品** | 拾取 1 个到自己背包 | 拾取整组到自己背包 |

智能判断：你鼠标放在哪边，就执行哪边对应的操作，不用切换模式。

---

## 安装

1. 安装 [UE4SS (RE-UE4SS)](https://docs.ue4ss.com/) 到 SCUM 游戏目录
2. 把 `ItemQuickDrop` 文件夹放到 `SCUM/Binaries/Win64/Mods/`
3. 目录结构：
   ```
   Mods/
   └── ItemQuickDrop/
       ├── mod.json
       └── Scripts/
           └── main.lua
   ```
4. 进游戏按 `F10` 打开控制台，看到 `[ItemQuickDrop] 加载完成！` 即成功

---

## 配置文件自定义按键

编辑 `mod.json` 的 `default_settings`，或改 `Mods/Config/ItemQuickDrop.ini`：

```json
{
  "enabled": true,
  "debug": false,
  "key_single": "F",
  "key_stack": "F",
  "modifier_stack": "SHIFT"
}
```

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `enabled` | 总开关 | `true` |
| `debug` | 调试日志 | `false` |
| `key_single` | 单键（操作1个） | `F` |
| `key_stack` | 组合键的主按键 | `F` |
| `modifier_stack` | 组合键的修饰键 | `SHIFT` |

### 支持的按键

- 字母 `A`~`Z`
- 数字 `NUM_0`~`NUM_9`
- 功能键 `F1`~`F12`
- 修饰键 `SHIFT` / `CTRL` / `ALT`
- 方向键、小键盘、空格、回车等

### 改完生效

控制台（`F10`）输入：
```lua
ItemQuickDrop_Reload()
```

---

## 调试 / 适配

SCUM 不同版本 UI 类名可能不同。按 `F` 没反应时：

1. `debug` 设为 `true`，重载
2. 打开背包按 F，看控制台输出的类名
3. 在 `main.lua` 的 `PANEL_CLASS_NAMES` 里，把真实类名加到对应列表最前面
4. 在 `drop_item_to_world()` 和 `pickup_item_to_player()` 里，按实际 RPC 函数名打开调用注释

---

## 版本历史

- **v1.2.0** — 双向模式：背包物品丢弃、容器物品拾取，自动判断
- **v1.1.0** — 配置文件自定义按键、动态重载
- **v1.0.0** — 初始版本
