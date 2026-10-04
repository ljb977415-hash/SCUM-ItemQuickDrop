# SCUM UE4SS C++ DLL Mod 新手入门指南

从零开始，一步一步来。每一步都写清楚。

---

## 总览

你要做的事：
1. 装 VS2022 + Git + CMake
2. 下载 UE4SS 源码
3. 写一个最简单的 C++ Mod
4. 编译出 main.dll
5. 放到游戏里跑起来

预计耗时：第一次大概 1~2 小时（主要是下载 VS 和源码）

---

## 第一步：安装 Visual Studio 2022

### 1.1 下载

去微软官网下载 VS2022 Community（免费）：
https://visualstudio.microsoft.com/zh-hans/downloads/

### 1.2 安装时勾选工作负载

安装程序打开后，**必须勾选**这一项：

> ☑ **使用 C++ 的桌面开发** (Desktop development with C++)

右边「安装详细信息」里确认有：
- MSVC v143 - VS 2022 C++ x64/x86 生成工具
- Windows 11 SDK (10.0.22621.0 或更高)
- C++ CMake 工具 for Windows

点「安装」，等它下完（大概 10~20 GB，耐心等）。

### 1.3 验证

装完后打开 VS2022，能看到启动界面就 OK。

---

## 第二步：安装 Git

### 2.1 下载

https://git-scm.com/download/win

下载 64-bit Git for Windows Setup，一路下一步装好。

### 2.2 验证

按 `Win + R`，输入 `cmd` 回车，在黑窗口里输入：

```
git --version
```

能看到版本号（比如 `git version 2.45.1.windows.1`）就说明装好了。

---

## 第三步：安装 CMake

### 3.1 下载

https://cmake.org/download/

下载 Windows 64-bit Installer（.msi），装的时候**勾选**：

> ☑ Add CMake to the system PATH for all users

### 3.2 验证

新开一个 cmd 窗口，输入：

```
cmake --version
```

能看到版本号（≥ 3.22）就 OK。

---

## 第四步：下载 UE4SS 源码

### 4.1 选一个存放位置

建议放在没有中文、没有空格的路径，比如：
```
D:\dev\
```

### 4.2 Clone 源码

打开 cmd，进入你的开发目录：
```
D:
cd D:\dev
```

然后执行：
```
git clone --recursive https://github.com/UE4SS-RE/RE-UE4SS.git
```

> ⚠️ 注意：`--recursive` 必须加！UE4SS 有很多子模块，不加会缺文件。

这个下载比较大（几个 GB），耐心等。

### 4.3 验证目录结构

下载完后，目录应该长这样：
```
D:\dev\RE-UE4SS\
├── include\          ← 头文件在这里
├── dependencies\     ← 依赖库
├── lib\              ← 预编译库（如果有）
├── src\
├── CMakeLists.txt
└── ...
```

如果 `include` 文件夹存在，就 OK。

---

## 第五步：准备你的 Mod 项目

### 5.1 创建项目文件夹

在你喜欢的位置建一个 mod 项目目录，比如：
```
D:\dev\SCUM-ItemQuickDrop\cpp-template\
```

> 本仓库里的 `cpp-template/` 目录已经给你写好了模板，直接用就行。

### 5.2 项目结构

```
cpp-template\
├── CMakeLists.txt      ← 编译配置
└── src\
    └── main.cpp        ← 你的代码
```

### 5.3 修改 UE4SS 路径

打开 `CMakeLists.txt`，找到这一行：

```cmake
set(UE4SS_ROOT "${CMAKE_SOURCE_DIR}/../../../RE-UE4SS" CACHE PATH "UE4SS source root")
```

把路径改成你实际的 UE4SS 源码路径，比如：
```cmake
set(UE4SS_ROOT "D:/dev/RE-UE4SS" CACHE PATH "UE4SS source root")
```

> 注意：用正斜杠 `/`，不要用反斜杠 `\`。

---

## 第六步：编译（CMake 配置 + 构建）

### 6.1 打开开发者命令行

按 `Win` 键，搜：

> **x64 Native Tools Command Prompt for VS 2022**

打开它（这个窗口自带了 MSVC 编译环境）。

### 6.2 进入项目目录

```
cd D:\dev\SCUM-ItemQuickDrop\cpp-template
```

### 6.3 CMake 配置

```
cmake -B build -A x64
```

这一步会生成 build 目录和 VS 工程文件。

如果成功，最后会看到：
```
-- Configuring done
-- Generating done
-- Build files have been written to: ...
```

### 6.4 编译

```
cmake --build build --config Release
```

等它编译完，看到：
```
[100%] Built target main
```

### 6.5 找到编译产物

编译好的 dll 在：
```
build\bin\Release\main.dll
```

---

## 第七步：部署到游戏

### 7.1 装 UE4SS 到游戏目录

如果还没装 UE4SS：
1. 去 https://docs.ue4ss.com/ 下载 SCUM 专用版
2. 解压到 `SCUM/Binaries/Win64/` 下面

### 7.2 创建 Mod 目录

在游戏目录里建：
```
SCUM/Binaries/Win64/Mods/ItemQuickDrop/
├── enabled.txt        ← 空文件就行，有这个文件代表 mod 启用
└── dlls/
    └── main.dll       ← 把你编译的 main.dll 复制到这里
```

> `enabled.txt` 可以是空文件，只是个标记。

### 7.3 准备游戏启动参数

SCUM 必须加 `-noBattlEye` 启动参数，否则 BE 会拦截 UE4SS。

Steam 里设置：
1. 右键 SCUM → 属性
2. 启动选项里填：
```
-noBattlEye
```

---

## 第八步：测试

### 8.1 启动游戏

用 Steam 启动 SCUM，进主菜单。

### 8.2 打开 UE4SS 控制台

按 `F10`（默认）打开 UE4SS 控制台。

### 8.3 看输出

如果一切正常，你会在控制台看到：
```
========================================
[ItemQuickDrop] UE4SS C++ Mod 加载成功！
[ItemQuickDrop] 版本: v0.0.1 (hello world)
========================================
```

进游戏（单人世界）后还会看到 PlayerController 的对象名。

---

## 常见问题

### Q: cmake 配置时报错「UE4SS include 目录不存在」
A: CMakeLists.txt 里的 UE4SS_ROOT 路径写错了，改成你实际的路径。

### Q: 编译时报错「找不到 UE4SS 头文件」
A: 检查 UE4SS 源码有没有完整 clone（特别是子模块）。重新执行：
```
cd D:\dev\RE-UE4SS
git submodule update --init --recursive
```

### Q: dll 放进去了但控制台没输出
A: 
1. 检查 dll 路径对不对：`Mods/你的Mod名/dlls/main.dll`
2. 检查有没有 `enabled.txt` 文件
3. 检查游戏启动参数有没有加 `-noBattlEye`
4. 确认 UE4SS 版本是 SCUM 专用的，不是其他游戏的

### Q: 游戏崩溃了
A: C++ mod 写错了很容易崩。先确认 hello world 版本能跑，再加代码。每加一点东西就编译测试一次。

---

## 下一步

跑通这个 Demo 之后，就可以开始加功能了：
1. 按键绑定（按 F）
2. 获取背包 UI 和槽位
3. 丢物品 / 拾取物品

参考 `main.lua`（Lua 版）的逻辑，用 C++ API 重写一遍。
