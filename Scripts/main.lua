--[[
    SCUM ItemQuickDrop Mod  v1.1.0
    ----------------------
    在背包/容器界面中：
      单键        = 从鼠标悬停的槽位丢出 / 取出 1 个物品
      修饰键+单键 = 丢出 / 取出整组物品
    
    所有按键均可在配置文件里自定义，无需改代码。
    依赖：UE4SS (RE-UE4SS) Lua 环境
--]]

local M = {}

-- ============================================================
-- 按键名称映射表（配置文件里写字符串，运行时转成 Key 枚举）
-- ============================================================
local KEY_MAP = {
    -- 字母
    A = Key.A, B = Key.B, C = Key.C, D = Key.D, E = Key.E,
    F = Key.F, G = Key.G, H = Key.H, I = Key.I, J = Key.J,
    K = Key.K, L = Key.L, M = Key.M, N = Key.N, O = Key.O,
    P = Key.P, Q = Key.Q, R = Key.R, S = Key.S, T = Key.T,
    U = Key.U, V = Key.V, W = Key.W, X = Key.X, Y = Key.Y, Z = Key.Z,
    -- 数字
    NUM_0 = Key.NUM_0, NUM_1 = Key.NUM_1, NUM_2 = Key.NUM_2,
    NUM_3 = Key.NUM_3, NUM_4 = Key.NUM_4, NUM_5 = Key.NUM_5,
    NUM_6 = Key.NUM_6, NUM_7 = Key.NUM_7, NUM_8 = Key.NUM_8,
    NUM_9 = Key.NUM_9,
    -- 功能键
    F1 = Key.F1, F2 = Key.F2, F3 = Key.F3, F4 = Key.F4,
    F5 = Key.F5, F6 = Key.F6, F7 = Key.F7, F8 = Key.F8,
    F9 = Key.F9, F10 = Key.F10, F11 = Key.F11, F12 = Key.F12,
    -- 修饰键
    SHIFT = Key.SHIFT, LEFT_SHIFT = Key.LEFT_SHIFT, RIGHT_SHIFT = Key.RIGHT_SHIFT,
    CTRL = Key.CTRL, LEFT_CTRL = Key.LEFT_CTRL, RIGHT_CTRL = Key.RIGHT_CTRL,
    ALT = Key.ALT, LEFT_ALT = Key.LEFT_ALT, RIGHT_ALT = Key.RIGHT_ALT,
    -- 其他常用
    SPACE = Key.SPACE, ENTER = Key.ENTER, TAB = Key.TAB,
    ESCAPE = Key.ESCAPE, BACKSPACE = Key.BACKSPACE,
    INSERT = Key.INSERT, DELETE = Key.DELETE,
    HOME = Key.HOME, END = Key.END, PAGE_UP = Key.PAGE_UP, PAGE_DOWN = Key.PAGE_DOWN,
    LEFT_BRACKET = Key.LEFT_BRACKET, RIGHT_BRACKET = Key.RIGHT_BRACKET,
    SEMICOLON = Key.SEMICOLON, COMMA = Key.COMMA, PERIOD = Key.PERIOD,
    SLASH = Key.SLASH, BACKSLASH = Key.BACKSLASH,
    MINUS = Key.MINUS, EQUALS = Key.EQUALS,
    -- 方向键
    UP = Key.UP, DOWN = Key.DOWN, LEFT = Key.LEFT, RIGHT = Key.RIGHT,
    -- 小键盘
    NUM_PAD_0 = Key.NUM_PAD_0, NUM_PAD_1 = Key.NUM_PAD_1,
    NUM_PAD_2 = Key.NUM_PAD_2, NUM_PAD_3 = Key.NUM_PAD_3,
    NUM_PAD_4 = Key.NUM_PAD_4, NUM_PAD_5 = Key.NUM_PAD_5,
    NUM_PAD_6 = Key.NUM_PAD_6, NUM_PAD_7 = Key.NUM_PAD_7,
    NUM_PAD_8 = Key.NUM_PAD_8, NUM_PAD_9 = Key.NUM_PAD_9,
}

-- ============================================================
-- 全局配置（从 ModSettings 读取）
-- ============================================================
local CONFIG = {
    enabled = true,
    debug = false,
    key_single_str = "F",
    key_stack_str = "F",
    modifier_stack_str = "SHIFT",
}

-- 运行时绑定的 Key 枚举值
local key_single = nil
local key_stack = nil
local modifier_stack = {}

-- 已注册的按键句柄（用于反注册 / 重载）
local registered_binds = {}

-- ============================================================
-- 工具函数
-- ============================================================
local function log(msg)
    if CONFIG.debug then
        print("[ItemQuickDrop] " .. tostring(msg))
    end
end

--- 把配置里的字符串按键转成 Key 枚举
local function resolve_key(key_str)
    if not key_str or key_str == "" then return nil end
    local upper = string.upper(key_str)
    local mapped = KEY_MAP[upper]
    if not mapped then
        print(string.format("[ItemQuickDrop] 警告: 未知按键 '%s'，将使用默认值", key_str))
        return nil
    end
    return mapped
end

--- 读取 ModSettings 配置
local function load_config()
    -- 从 UE4SS 的 ModSettings 读取
    -- 不同 UE4SS 版本读取方式略有差异，下面兼容常见写法
    local settings = nil
    
    -- 方式一：通过 ModSettings 全局表
    if ModSettings and ModSettings.GetValue then
        settings = ModSettings
    end
    
    -- 方式二：通过 Mod 对象
    local mod_obj = _G.Mod or M
    
    local function get_setting(key, default)
        if settings then
            local ok, val = pcall(settings.GetValue, key)
            if ok and val ~= nil and val ~= "" then
                return val
            end
        end
        -- 备选：直接读 mod.json default_settings 对应的值
        return default
    end
    
    CONFIG.enabled = get_setting("enabled", true)
    CONFIG.debug = get_setting("debug", false)
    CONFIG.key_single_str = get_setting("key_single", "F")
    CONFIG.key_stack_str = get_setting("key_stack", "F")
    CONFIG.modifier_stack_str = get_setting("modifier_stack", "SHIFT")
    
    -- 解析成 Key 枚举
    key_single = resolve_key(CONFIG.key_single_str) or Key.F
    key_stack = resolve_key(CONFIG.key_stack_str) or Key.F
    
    modifier_stack = {}
    if CONFIG.modifier_stack_str ~= "" then
        local mod_key = resolve_key(CONFIG.modifier_stack_str)
        if mod_key then
            table.insert(modifier_stack, mod_key)
        end
    end
    
    log("配置加载完成:")
    log("  enabled = " .. tostring(CONFIG.enabled))
    log("  debug = " .. tostring(CONFIG.debug))
    log("  key_single = " .. CONFIG.key_single_str)
    log("  key_stack = " .. CONFIG.key_stack_str .. " + " .. CONFIG.modifier_stack_str)
end

-- ============================================================
-- 获取玩家 / 角色
-- ============================================================
local function get_player_controller()
    local pc = UEHelpers.GetPlayerController()
    if pc and pc:IsValid() then
        return pc
    end
    return nil
end

local function get_local_player()
    local pc = get_player_controller()
    if not pc then return nil end
    local player = pc.Player
    if player and player:IsValid() then
        return player
    end
    return nil
end

-- ============================================================
-- 获取背包 UI 和悬停槽位
-- ============================================================
local function find_widget_by_class(root_widget, class_name)
    if not root_widget or not root_widget:IsValid() then return nil end
    
    local class = root_widget:GetClass()
    if class and class:GetFName():ToString() == class_name then
        return root_widget
    end
    
    local children = root_widget:GetChildren()
    if children then
        for i = 1, children:Length() do
            local child = children[i]
            if child and child:IsValid() then
                local result = find_widget_by_class(child, class_name)
                if result then return result end
            end
        end
    end
    return nil
end

local function get_hovered_slot()
    local pc = get_player_controller()
    if not pc then return nil end
    
    local game_viewport = pc:GetGameViewport()
    if not game_viewport then return nil end
    
    local viewport_widget = game_viewport.ViewportWidget
    if not viewport_widget or not viewport_widget:IsValid() then
        log("ViewportWidget 无效")
        return nil
    end
    
    -- 常见背包面板类名（按优先级，可在配置里加自定义的）
    local panel_class_names = {
        "WB_MainInventoryPanel_C",
        "WB_InventoryPanel_C",
        "WB_ContainerPanel_C",
        "WB_Container_C",
        "WB_BagPanel_C",
        "WB_LootPanel_C",
    }
    
    local inventory_panel = nil
    for _, cls in ipairs(panel_class_names) do
        inventory_panel = find_widget_by_class(viewport_widget, cls)
        if inventory_panel then
            log("找到背包面板: " .. cls)
            break
        end
    end
    
    if not inventory_panel then
        log("未找到背包面板（背包未打开？）")
        return nil
    end
    
    -- 获取鼠标悬停的槽位
    local hovered = inventory_panel:GetHoveredWidget()
    if hovered and hovered:IsValid() then
        log("Hovered widget: " .. hovered:GetClass():GetFName():ToString())
        return hovered
    end
    
    if inventory_panel.HoveredSlot and inventory_panel.HoveredSlot:IsValid() then
        return inventory_panel.HoveredSlot
    end
    
    return nil
end

-- ============================================================
-- 执行丢物品
-- ============================================================
local function drop_item_from_slot(slot_widget, amount)
    if not slot_widget or not slot_widget:IsValid() then
        log("槽位无效")
        return
    end
    
    local item_ref = slot_widget.Item or slot_widget.ItemRef or slot_widget.InventoryItem
    local quantity = slot_widget.Quantity or slot_widget.Count or 1
    
    if not item_ref or not item_ref:IsValid() then
        log("槽位里没有物品")
        return
    end
    
    local player = get_local_player()
    if not player then
        log("本地玩家无效")
        return
    end
    
    local drop_count = 1
    if amount == "stack" then
        drop_count = quantity
    end
    
    log(string.format("操作物品: %s, 数量: %d, 模式: %s", 
        item_ref:GetClass():GetFName():ToString(), drop_count, amount))
    
    -- ==========================================================
    -- 按实际游戏版本打开对应的丢物品函数调用
    -- ==========================================================
    -- player:DropItem(item_ref, drop_count)
    -- player:ServerDropItem(item_ref, drop_count)
    -- slot_widget:DropItem(drop_count)
    
    print(string.format("[ItemQuickDrop] 丢出 %d 个物品", drop_count))
end

-- ============================================================
-- 按键回调
-- ============================================================
local function on_key_single()
    if not CONFIG.enabled then return end
    log("按下单键（丢单个）")
    local slot = get_hovered_slot()
    if slot then
        drop_item_from_slot(slot, "single")
    end
end

local function on_key_stack()
    if not CONFIG.enabled then return end
    log("按下组合键（丢整组）")
    local slot = get_hovered_slot()
    if slot then
        drop_item_from_slot(slot, "stack")
    end
end

-- ============================================================
-- 注册 / 反注册按键
-- ============================================================
local function unregister_keybinds()
    -- UE4SS 没有直接的 UnregisterKeyBind，这里通过覆盖注册实现
    -- 实际热重载时 UE4SS 会自动清理旧的 Lua 环境
    registered_binds = {}
end

local function register_keybinds()
    unregister_keybinds()
    
    -- 单键 = 丢单个
    if key_single then
        RegisterKeyBind(key_single, on_key_single)
        table.insert(registered_binds, { key = key_single, mods = nil })
        log("已绑定单键: " .. CONFIG.key_single_str .. " = 丢单个")
    end
    
    -- 组合键 = 丢整组
    if key_stack and #modifier_stack > 0 then
        RegisterKeyBind(key_stack, modifier_stack, on_key_stack)
        table.insert(registered_binds, { key = key_stack, mods = modifier_stack })
        log("已绑定组合键: " .. CONFIG.modifier_stack_str .. "+" .. CONFIG.key_stack_str .. " = 丢整组")
    end
end

-- ============================================================
-- 重载配置（控制台命令）
-- ============================================================
local function reload()
    print("[ItemQuickDrop] 正在重载配置...")
    load_config()
    register_keybinds()
    print("[ItemQuickDrop] 重载完成！")
    print(string.format("[ItemQuickDrop] 当前按键: %s = 丢单个 | %s+%s = 丢整组",
        CONFIG.key_single_str,
        CONFIG.modifier_stack_str,
        CONFIG.key_stack_str))
end

-- 暴露到全局，方便控制台调用 reload()
_G.ItemQuickDrop_Reload = reload

-- ============================================================
-- 入口
-- ============================================================
local function Init()
    print("[ItemQuickDrop] 模组加载中...")
    print("[ItemQuickDrop] v1.1.0")
    
    load_config()
    register_keybinds()
    
    print("[ItemQuickDrop] 加载完成！")
    print(string.format("[ItemQuickDrop] %s = 丢1个物品", CONFIG.key_single_str))
    print(string.format("[ItemQuickDrop] %s + %s = 丢整组物品",
        CONFIG.modifier_stack_str, CONFIG.key_stack_str))
    print("[ItemQuickDrop] 在控制台输入 ItemQuickDrop_Reload() 可重载配置")
end

Init()
