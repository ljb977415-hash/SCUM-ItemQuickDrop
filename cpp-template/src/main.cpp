// ============================================================
//  ItemQuickDrop —— SCUM UE4SS C++ DLL Mod 最小 Demo
// ============================================================
//  这个文件只做一件事：进游戏后在 UE4SS 控制台打印一行字，
//  证明你的编译环境、DLL 加载、UE4SS 调用全部通了。
//
//  跑通之后再往里加背包操作逻辑。
// ============================================================

#include <Mod/CppUserModBase.hpp>
#include <Unreal/UObjectGlobals.hpp>
#include <Unreal/UObject.hpp>
#include <DynamicOutput/Output.hpp>

using namespace RC;
using namespace Unreal;

class ItemQuickDropMod : public CppUserModBase {
public:
    ItemQuickDropMod() : CppUserModBase() {
        // Mod 被加载时立即调用（游戏启动时）
        Output::send<LogLevel::Standard>(STR("[ItemQuickDrop] Mod 构造函数被调用\n"));
    }

    ~ItemQuickDropMod() override {
        // Mod 卸载时调用
        Output::send<LogLevel::Standard>(STR("[ItemQuickDrop] Mod 被卸载\n"));
    }

    // UE 对象系统初始化完成后调用
    // 在这里面才能安全调用 FindObject / FindFirstOf 等
    auto on_unreal_init() -> void override {
        Output::send<LogLevel::Standard>(STR("========================================\n"));
        Output::send<LogLevel::Standard>(STR("[ItemQuickDrop] UE4SS C++ Mod 加载成功！\n"));
        Output::send<LogLevel::Standard>(STR("[ItemQuickDrop] 版本: v0.0.1 (hello world)\n"));
        Output::send<LogLevel::Standard>(STR("========================================\n"));

        // 试一下找游戏对象 —— 找本地 PlayerController
        auto pc = UObjectGlobals::FindFirstOf(STR("PlayerController"));
        if (pc) {
            Output::send<LogLevel::Standard>(
                STR("[ItemQuickDrop] 找到 PlayerController: %s\n"), 
                pc->GetFullName()
            );
        } else {
            Output::send<LogLevel::Standard>(STR("[ItemQuickDrop] 还没找到 PlayerController（可能游戏还没进图）\n"));
        }
    }
};

// ============================================================
//  这行是关键：把你的 Mod 类导出给 UE4SS
//  编译出来的 main.dll 放到 Mods/你的Mod名/dlls/ 下就能被加载
// ============================================================
EXPORT_SIMPLE_MOD(ItemQuickDropMod);
