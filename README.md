# SCUM - ItemQuickDrop

SCUM（人渣）UE4SS 客户端 Mod。在背包或容器界面里，鼠标指向物品时按快捷键快速丢出 / 取出物品。

## 功能

| 快捷键 | 效果 |
|--------|------|
| 单键（默认 `F`） | 从鼠标悬停的槽位丢出 **1 个**物品 |
| 修饰键 + 单键（默认 `Shift + F`） | 从鼠标悬停的槽位丢出 **整组**物品 |

所有按键均可在配置文件里自定义，无需改代码。

---

## 安装

1. 先安装 [UE4SS (RE-UE4SS)](https://docs.ue4ss.com/) 到 SCUM 游戏目录
2. 把本 mod 的文件夹放到 `SCUM/Binaries/Win64/Mods/ItemQuickDrop/`
3. 目录结构：
   ```
   Mods/
   └── ItemQuickDrop/
       ├── mod.json
       └── Scripts/
           └── main.lua
   ```
4. 启动游戏，按 `F10` 打开 UE4SS 控制台，看到 `[ItemQuickDrop] 加载完成！` 就 OK

---

## 配置文件自定义按键

### 配置文件位置

第一次启动后，UE4SS 会在 `Mods/Config/` 下生成配置文件（通常是 `ItemQuickDrop.ini`）。

也可以直接编辑 `mod.json` 里的 `default_settings`，首次启动会写入配置文件。

### 可配置项

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
| `enabled` | 总开关，`true` / `false` | `true` |
| `debug` | 调试模式，输出详细日志 | `false` |
| `key_single` | 丢单个物品的按键 | `F` |
| `key_stack` | 丢整组物品的主按键 | `F` |
| `modifier_stack` | 丢整组的修饰键（`SHIFT` / `CTRL` / `ALT`） | `SHIFT` |

### 支持的按键名称

- **字母**：`A` ~ `Z`
- **数字**：`NUM_0` ~ `NUM_9`
- **功能键**：`F1` ~ `F12`
- **修饰键**：`SHIFT` / `CTRL` / `ALT`（也支持 `LEFT_SHIFT` / `RIGHT_SHIFT` 等）
- **常用键**：`SPACE`、`ENTER`、`TAB`、`ESCAPE`、`BACKSPACE`、`INSERT`、`DELETE`、`HOME`、`END`、`PAGE_UP`、`PAGE_DOWN`
- **方向键**：`UP`、`DOWN`、`LEFT`、`RIGHT`
- **小键盘**：`NUM_PAD_0` ~ `NUM_PAD_9`

### 修改后生效

改完配置后，有两种方式生效：

1. **重载 mod**：在 UE4SS 控制台（`F10`）输入：
   ```lua
   ItemQuickDrop_Reload()
   ```
2. **重启游戏**

---

## 调试 / 适配说明

SCUM 不同版本的 UI 类名和内部函数名可能有差异。按 `F` 没反应时：

1. 把配置里的 `debug` 改成 `true`，重载
2. 进游戏打开背包，按 F，看控制台输出的类名
3. 在 `main.lua` 的 `panel_class_names` 列表里，把真实的背包面板类名加到最前面
4. 在 `drop_item_from_slot()` 里，按实际的丢物品函数名打开对应的调用注释

---

## 版本历史

- **v1.1.0** — 配置文件自定义按键、动态重载、按键名称映射表
- **v1.0.0** — 初始版本
