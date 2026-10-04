--[[
    SCUM ItemQuickDrop Mod  v1.2.0
    ----------------------
    双向模式：
      悬停在【自己背包】的物品上：
        F       = 丢出 1 个到地上
        Shift+F = 丢出整组到地上
      悬停在【容器/箱子/尸体】的物品上：
        F       = 拾取 1 个到自己背包
        Shift+F = 拾取整组到自己背包
    
    所有按键均可在配置文件里自定义。
    依赖：UE4SS (RE-UE4SS) Lua 环境
--]]

local M = {}

-- ============================================================
-- 按键名称映射表
-- ============================================================
local KEY_MAP = {
    A = Key.A, B = Key.B, C = Key.C, D = Key.D, E = Key.E,
    F = Key.F, G = Key.G, H = Key.H, I = Key.I, J = Key.J,
    K = Key.K, L = Key.L, M = Key.M, N = Key.N, O = Key.O,
    P = Key.P, Q = Key.Q, R = Key.R, S = Key.S, T = Key.T,
    U = Key.U, V = Key.V, W = Key.W, X = Key.X, Y = Key.Y, Z = Key.Z,
    NUM_0 = Key.NUM_0, NUM_1 = Key.NUM_1, NUM_2 = Key.NUM_2,
    NUM_3 = Key.NUM_3, NUM_4 = Key.NUM_4, NUM_5 = Key.NUM_5,
    NUM_6 = Key.NUM_6, NUM_7 = Key.NUM_7, NUM_8 = Key.NUM_8,
    NUM_9 = Key.NUM_9,
    F1 = Key.F1, F2 = Key.F2, F3 = Key.F3, F4 = Key.F4,
    F5 = Key.F5, F6 = Key.F6, F7 = Key.F7, F8 = Key.F8,
    F9 = Key.F9, F10 = Key.F10, F11 = Key.F11, F12 = Key.F12,
    SHIFT = Key.SHIFT, LEFT_SHIFT = Key.LEFT_SHIFT, RIGHT_SHIFT = Key.RIGHT_SHIFT,
    CTRL = Key.CTRL, LEFT_CTRL = Key.LEFT_CTRL, RIGHT_CTRL = Key.RIGHT_CTRL,
    ALT = Key.ALT, LEFT_ALT = Key.LEFT_ALT, RIGHT_ALT = Key.RIGHT_ALT,
    SPACE = Key.SPACE, ENTER = Key.ENTER, TAB = Key.TAB,
    ESCAPE = Key.ESCAPE, BACKSPACE = Key.BACKSPACE,
    INSERT = Key.INSERT, DELETE = Key.DELETE,
    HOME = Key.HOME, END = Key.END, PAGE_UP = Key.PAGE_UP, PAGE_DOWN = Key.PAGE_DOWN,
    LEFT_BRACKET = Key.LEFT_BRACKET, RIGHT_BRACKET = Key.RIGHT_BRACKET,
    SEMICOLON = Key.SEMICOLON, COMMA = Key.COMMA, PERIOD = Key.PERIOD,
    SLASH = Key.SLASH, BACKSLASH = Key.BACKSLASH,
    MINUS = Key.MINUS, EQUALS = Key.EQUALS,
    UP = Key.UP, DOWN = Key.DOWN, LEFT = Key.LEFT, RIGHT = Key.RIGHT,
    NUM_PAD_0 = Key.NUM_PAD_0, NUM_PAD_1 = Key.NUM_PAD_1,
    NUM_PAD_2 = Key.NUM_PAD_2, NUM_PAD_3 = Key.NUM_PAD_3,
    NUM_PAD_4 = Key.NUM_PAD_4, NUM_PAD_5 = Key.NUM_PAD_5,
    NUM_PAD_6 = Key.NUM_PAD_6, NUM_PAD_7 = Key.NUM_PAD_7,
    NUM_PAD_8 = Key.NUM_PAD_8, NUM_PAD_9 = Key.NUM_PAD_9,
}

-- ============================================================
-- 面板类型枚举
-- ============================================================
local PANEL_TYPE = {
    NONE = "none",
    PLAYER_INVENTORY = "player",   -- 自己的背包
    CONTAINER = "container",       -- 箱子/容器/尸体
}

-- ============================================================
-- 配置
-- ============================================================
local CONFIG = {
    enabled = true,
    debug = false,
    key_single_str = "F",
    key_stack_str = "F",
    modifier_stack_str = "SHIFT",
}

local key_single = nil
local key_stack = nil
local modifier_stack = {}

-- 背包 / 容器面板类名（按优先级排序，可在游戏里用 Dumper 查真实类名）
local PANEL_CLASS_NAMES = {
    player = {
        "WB_MainInventoryPanel_C",
        "WB_OnBodyInventory_C",
        "WB_PlayerInventory_C",
    },
    container = {
        "WB_ContainerPanel_C",
        "WB_Container_C",
        "WB_LootPanel_C",
        "WB_LootContainer_C",
        "WB_ChestPanel_C",
        "WB_BarrelPanel_C",
        "WB_CorpseLoot_C",
    },
}

-- ============================================================
-- 工具
-- ============================================================
local function log(msg)
    if CONFIG.debug then
        print("[ItemQuickDrop] " .. tostring(msg))
    end
end

local function resolve_key(key_str)
    if not key_str or key_str == "" then return nil end
    local upper = string.upper(key_str)
    local mapped = KEY_MAP[upper]
    if not mapped then
        print(string.format("[ItemQuickDrop] 警告: 未知按键 '%s'", key_str))
        return nil
    end
    return mapped
end

local function load_config()
    local settings = ModSettings
    local function get_setting(key, default)
        if settings and settings.GetValue then
            local ok, val = pcall(settings.GetValue, key)
            if ok and val ~= nil and val ~= "" then
                return val
            end
        end
        return default
    end

    CONFIG.enabled = get_setting("enabled", true)
    CONFIG.debug = get_setting("debug", false)
    CONFIG.key_single_str = get_setting("key_single", "F")
    CONFIG.key_stack_str = get_setting("key_stack", "F")
    CONFIG.modifier_stack_str = get_setting("modifier_stack", "SHIFT")

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
    log("  key_single = " .. CONFIG.key_single_str)
    log("  key_stack = " .. CONFIG.modifier_stack_str .. "+" .. CONFIG.key_stack_str)
end

local function get_player_controller()
    local pc = UEHelpers.GetPlayerController()
    if pc and pc:IsValid() then return pc end
    return nil
end

local function get_local_player()
    local pc = get_player_controller()
    if not pc then return nil end
    local player = pc.Player
    if player and player:IsValid() then return player end
    return nil
end

-- ============================================================
-- UI 遍历工具
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

--- 在控件树里找第一个匹配的面板，并判断类型
--- 返回：panel_widget, panel_type
local function find_open_inventory_panel()
    local pc = get_player_controller()
    if not pc then return nil, PANEL_TYPE.NONE end

    local game_viewport = pc:GetGameViewport()
    if not game_viewport then return nil, PANEL_TYPE.NONE end

    local viewport_widget = game_viewport.ViewportWidget
    if not viewport_widget or not viewport_widget:IsValid() then
        return nil, PANEL_TYPE.NONE
    end

    -- 先找玩家背包面板
    for _, cls in ipairs(PANEL_CLASS_NAMES.player) do
        local widget = find_widget_by_class(viewport_widget, cls)
        if widget then
            log("找到玩家背包面板: " .. cls)
            return widget, PANEL_TYPE.PLAYER_INVENTORY
        end
    end

    -- 再找容器面板
    for _, cls in ipairs(PANEL_CLASS_NAMES.container) do
        local widget = find_widget_by_class(viewport_widget, cls)
        if widget then
            log("找到容器面板: " .. cls)
            return widget, PANEL_TYPE.CONTAINER
        end
    end

    return nil, PANEL_TYPE.NONE
end

--- 判断一个槽位属于哪个面板
--- 思路：从槽位往上找父控件，看最终属于玩家背包还是容器面板
local function get_slot_panel_type(slot_widget)
    if not slot_widget or not slot_widget:IsValid() then
        return PANEL_TYPE.NONE
    end

    -- 往上遍历父控件，直到找到面板级别的控件
    local current = slot_widget
    local depth = 0
    while current and current:IsValid() and depth < 20 do
        local class_name = current:GetClass():GetFName():ToString()

        -- 检查是不是玩家背包类
        for _, cls in ipairs(PANEL_CLASS_NAMES.player) do
            if class_name == cls then
                return PANEL_TYPE.PLAYER_INVENTORY
            end
        end

        -- 检查是不是容器类
        for _, cls in ipairs(PANEL_CLASS_NAMES.container) do
            if class_name == cls then
                return PANEL_TYPE.CONTAINER
            end
        end

        -- 往上找父控件
        current = current:GetParent()
        depth = depth + 1
    end

    log("槽位所属面板未识别，深度=" .. depth)
    return PANEL_TYPE.NONE
end

--- 获取当前鼠标悬停的槽位
--- 返回：slot_widget, panel_type
local function get_hovered_slot()
    local pc = get_player_controller()
    if not pc then return nil, PANEL_TYPE.NONE end

    local game_viewport = pc:GetGameViewport()
    if not game_viewport then return nil, PANEL_TYPE.NONE end

    local viewport_widget = game_viewport.ViewportWidget
    if not viewport_widget or not viewport_widget:IsValid() then
        return nil, PANEL_TYPE.NONE
    end

    -- 找到当前打开的面板（玩家背包 / 容器）
    local panel, panel_type = find_open_inventory_panel()
    if not panel then
        log("没有打开任何背包/容器面板")
        return nil, PANEL_TYPE.NONE
    end

    -- 获取鼠标悬停的控件
    local hovered = panel:GetHoveredWidget()
    if not hovered or not hovered:IsValid() then
        -- 备选方案
        if panel.HoveredSlot and panel.HoveredSlot:IsValid() then
            hovered = panel.HoveredSlot
        end
    end

    if not hovered or not hovered:IsValid() then
        log("当前没有悬停的槽位")
        return nil, PANEL_TYPE.NONE
    end

    log("Hovered: " .. hovered:GetClass():GetFName():ToString())

    -- 确认槽位所属面板类型
    local slot_type = get_slot_panel_type(hovered)
    if slot_type == PANEL_TYPE.NONE then
        -- 兜底：用当前打开的面板类型
        slot_type = panel_type
    end

    return hovered, slot_type
end

-- ============================================================
-- 物品操作
-- ============================================================
--- 从槽位丢物品到地上（玩家背包里的物品）
local function drop_item_to_world(slot_widget, amount)
    local item_ref = slot_widget.Item or slot_widget.ItemRef or slot_widget.InventoryItem
    local quantity = slot_widget.Quantity or slot_widget.Count or 1

    if not item_ref or not item_ref:IsValid() then
        log("槽位里没有物品")
        return
    end

    local player = get_local_player()
    if not player then return end

    local drop_count = 1
    if amount == "stack" then
        drop_count = quantity
    end

    log(string.format("[丢弃] %s x%d", item_ref:GetClass():GetFName():ToString(), drop_count))

    -- ==========================================================
    -- 按实际游戏版本打开对应的调用
    -- ==========================================================
    -- player:DropItem(item_ref, drop_count)
    -- player:ServerDropItem(item_ref, drop_count)
    -- slot_widget:DropItem(drop_count)

    print(string.format("[ItemQuickDrop] 丢弃 %d 个物品", drop_count))
end

--- 从容器拾取物品到玩家背包
local function pickup_item_to_player(slot_widget, amount)
    local item_ref = slot_widget.Item or slot_widget.ItemRef or slot_widget.InventoryItem
    local quantity = slot_widget.Quantity or slot_widget.Count or 1

    if not item_ref or not item_ref:IsValid() then
        log("槽位里没有物品")
        return
    end

    local player = get_local_player()
    if not player then return end

    local take_count = 1
    if amount == "stack" then
        take_count = quantity
    end

    log(string.format("[拾取] %s x%d", item_ref:GetClass():GetFName():ToString(), take_count))

    -- ==========================================================
    -- 按实际游戏版本打开对应的调用
    -- ==========================================================
    -- 常见做法是调用容器/库存的转移函数：
    -- container_inventory:TransferItemToPlayer(item_ref, take_count)
    -- container_component:ServerGiveItemToPlayer(item_ref, take_count)
    -- slot_widget:TransferToPlayer(take_count)
    -- player.InventoryComponent:AddItem(item_ref, take_count)
    --   （注意：纯客户端加物品不会同步到服务端，必须走 RPC）

    print(string.format("[ItemQuickDrop] 拾取 %d 个物品", take_count))
end

-- ============================================================
-- 统一入口：根据槽位所属面板自动选择 丢弃 / 拾取
-- ============================================================
local function handle_slot_action(slot_widget, panel_type, amount)
    if not slot_widget or not slot_widget:IsValid() then return end

    if panel_type == PANEL_TYPE.PLAYER_INVENTORY then
        -- 自己背包的物品 → 丢到地上
        drop_item_to_world(slot_widget, amount)
    elseif panel_type == PANEL_TYPE.CONTAINER then
        -- 容器里的物品 → 拾取到自己背包
        pickup_item_to_player(slot_widget, amount)
    else
        log("无法识别槽位所属面板，跳过")
    end
end

-- ============================================================
-- 按键回调
-- ============================================================
local function on_key_single()
    if not CONFIG.enabled then return end
    log("按下单键")
    local slot, panel_type = get_hovered_slot()
    if slot then
        handle_slot_action(slot, panel_type, "single")
    end
end

local function on_key_stack()
    if not CONFIG.enabled then return end
    log("按下组合键")
    local slot, panel_type = get_hovered_slot()
    if slot then
        handle_slot_action(slot, panel_type, "stack")
    end
end

-- ============================================================
-- 按键注册
-- ============================================================
local function register_keybinds()
    if key_single then
        RegisterKeyBind(key_single, on_key_single)
        log("已绑定单键: " .. CONFIG.key_single_str)
    end
    if key_stack and #modifier_stack > 0 then
        RegisterKeyBind(key_stack, modifier_stack, on_key_stack)
        log("已绑定组合键: " .. CONFIG.modifier_stack_str .. "+" .. CONFIG.key_stack_str)
    end
end

-- ============================================================
-- 重载
-- ============================================================
local function reload()
    print("[ItemQuickDrop] 正在重载...")
    load_config()
    register_keybinds()
    print("[ItemQuickDrop] 重载完成！")
    print(string.format("[ItemQuickDrop] 鼠标悬停背包物品: %s = 丢1个, %s+%s = 丢整组",
        CONFIG.key_single_str, CONFIG.modifier_stack_str, CONFIG.key_stack_str))
    print(string.format("[ItemQuickDrop] 鼠标悬停容器物品: %s = 拿1个, %s+%s = 拿整组",
        CONFIG.key_single_str, CONFIG.modifier_stack_str, CONFIG.key_stack_str))
end

_G.ItemQuickDrop_Reload = reload

-- ============================================================
-- 入口
-- ============================================================
local function Init()
    print("[ItemQuickDrop] 模组加载中...")
    print("[ItemQuickDrop] v1.2.0 (双向模式)")

    load_config()
    register_keybinds()

    print("[ItemQuickDrop] 加载完成！")
    print(string.format("[ItemQuickDrop] ┌ 悬停【自己背包】: %s 丢1个 | %s+%s 丢整组",
        CONFIG.key_single_str, CONFIG.modifier_stack_str, CONFIG.key_stack_str))
    print(string.format("[ItemQuickDrop] └ 悬停【箱子/容器】: %s 拿1个 | %s+%s 拿整组",
        CONFIG.key_single_str, CONFIG.modifier_stack_str, CONFIG.key_stack_str))
    print("[ItemQuickDrop] 控制台输入 ItemQuickDrop_Reload() 可重载配置")
end

Init()
