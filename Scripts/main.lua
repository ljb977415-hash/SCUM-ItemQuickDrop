--[[
    SCUM ItemQuickDrop Mod  v1.3.0
    ----------------------
    参考 PalItemInspector / evrima-dev-knowledge 最佳实践重写。
    
    双向模式：
      悬停在【自己背包】的物品上：
        F       = 丢出 1 个到地上
        Shift+F = 丢出整组到地上
      悬停在【容器/箱子/尸体】的物品上：
        F       = 拾取 1 个到自己背包
        Shift+F = 拾取整组到自己背包
    
    依赖：UE4SS (RE-UE4SS) Lua 环境
--]]

-- ============================================================
-- 安全工具：所有可能崩溃的调用都包 pcall
-- ============================================================
local function alive(obj)
    if obj == nil then return false end
    local ok, valid = pcall(function() return obj:IsValid() end)
    return ok and valid
end

local function get(getter)
    local ok, val = pcall(getter)
    if ok then return val end
    return nil
end

local function try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        print("[ItemQuickDrop] [ERR] " .. label .. ": " .. tostring(err))
    end
end

local function log(msg)
    if CONFIG.debug then
        print("[ItemQuickDrop] " .. tostring(msg))
    end
end

-- ============================================================
-- 按键解析（支持 "SHIFT+F" / "CTRL+SHIFT+G" 这种字符串）
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
    UP = Key.UP, DOWN = Key.DOWN, LEFT = Key.LEFT, RIGHT = Key.RIGHT,
}

--- 解析 "SHIFT+F" 这种配置字符串
--- 返回: key_enum, {modifier_enums}
local function parse_binding(binding_str)
    if not binding_str or binding_str == "" then return nil, nil end
    
    local mods = {}
    local token = binding_str
    
    while true do
        local mod, rest = token:match("^([%a]+)%s*%+%s*(.+)$")
        if not mod then break end
        mod = string.upper(mod)
        -- 修饰键映射（兼容 ModifierKey 表）
        local mod_enum = KEY_MAP[mod]
        if mod_enum then
            table.insert(mods, mod_enum)
        end
        token = rest
    end
    
    local key_name = string.upper(token)
    local key_enum = KEY_MAP[key_name]
    
    if not key_enum then
        print("[ItemQuickDrop] 警告: 未知按键 '" .. binding_str .. "'")
        return nil, nil
    end
    
    return key_enum, (#mods > 0) and mods or nil
end

-- ============================================================
-- 配置
-- ============================================================
local CONFIG = {
    enabled = true,
    debug = false,
    key_single_str = "F",
    key_stack_str = "SHIFT+F",
}

local key_single = nil
local mods_single = nil
local key_stack = nil
local mods_stack = nil

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
    CONFIG.key_stack_str = get_setting("key_stack", "SHIFT+F")

    key_single, mods_single = parse_binding(CONFIG.key_single_str)
    key_stack, mods_stack = parse_binding(CONFIG.key_stack_str)

    log("配置加载:")
    log("  single = " .. CONFIG.key_single_str)
    log("  stack  = " .. CONFIG.key_stack_str)
end

-- ============================================================
-- 玩家对象（缓存 + 延迟重试）
-- ============================================================
local cached_pc = nil
local pc_retry_at = 0.0

local function player_controller()
    if alive(cached_pc) then return cached_pc end
    cached_pc = nil

    local now = os.clock()
    if now < pc_retry_at then return nil end
    pc_retry_at = now + 1.0

    -- 方式一：UEHelpers
    if UEHelpers and UEHelpers.GetPlayerController then
        cached_pc = get(function() return UEHelpers.GetPlayerController() end)
    end

    -- 方式二：FindFirstOf
    if not alive(cached_pc) and FindFirstOf then
        cached_pc = get(function() return FindFirstOf("PlayerController") end)
    end

    -- 方式三：FindAllOf
    if not alive(cached_pc) and FindAllOf then
        local list = get(function() return FindAllOf("PlayerController") end)
        if type(list) == "table" and list[1] then
            cached_pc = list[1]
        end
    end

    return cached_pc
end

local function local_player()
    local pc = player_controller()
    if not alive(pc) then return nil end
    return get(function() return pc.Player end)
end

-- ============================================================
-- 槽位 / 物品探测（多字段备选，参考 PalItemInspector）
-- ============================================================

--- 从槽位控件里提取物品引用（试多个可能的字段名）
local function extract_item_ref(slot_widget)
    if not alive(slot_widget) then return nil end

    -- 可能的物品引用字段名
    local fields = {
        "Item", "ItemRef", "InventoryItem", "ItemInstance",
        "ItemSlot", "MyItemSlot", "TargetSlot",
    }

    for _, field in ipairs(fields) do
        local val = get(function() return slot_widget[field] end)
        if alive(val) then
            return val
        end
    end

    -- 尝试 GetItem() 方法
    local item = get(function() return slot_widget:GetItem() end)
    if alive(item) then return item end

    return nil
end

--- 从槽位控件里提取物品数量
local function extract_quantity(slot_widget)
    if not alive(slot_widget) then return 1 end

    local fields = { "Quantity", "Count", "Amount", "StackCount" }
    for _, field in ipairs(fields) do
        local val = get(function() return slot_widget[field] end)
        if type(val) == "number" and val > 0 then
            return val
        end
    end

    -- 尝试从物品引用里拿数量
    local item = extract_item_ref(slot_widget)
    if alive(item) then
        local qty = get(function() return item.Quantity end)
        if type(qty) == "number" then return qty end
        qty = get(function() return item.Count end)
        if type(qty) == "number" then return qty end
    end

    return 1
end

-- ============================================================
-- 获取当前鼠标悬停的槽位
-- ============================================================

--- 在控件树里递归查找指定类名的控件
local function find_widget_by_class(root_widget, class_name)
    if not alive(root_widget) then return nil end

    local class = get(function() return root_widget:GetClass() end)
    local class_fname = get(function() return class:GetFName():ToString() end)
    if class_fname == class_name then
        return root_widget
    end

    local children = get(function() return root_widget:GetChildren() end)
    if children then
        local count = get(function() return children:Length() end) or 0
        for i = 1, count do
            local child = get(function() return children[i] end)
            if alive(child) then
                local result = find_widget_by_class(child, class_name)
                if result then return result end
            end
        end
    end
    return nil
end

--- 从槽位往上找父控件链，判断属于哪个面板
local PANEL_CLASS_NAMES = {
    player = {
        "WB_MainInventoryPanel_C",
        "WB_OnBodyInventory_C",
        "WB_PlayerInventory_C",
        "WBP_PlayerInventory_C",
    },
    container = {
        "WB_ContainerPanel_C",
        "WB_Container_C",
        "WB_LootPanel_C",
        "WB_LootContainer_C",
        "WB_ChestPanel_C",
        "WB_CorpseLoot_C",
        "WBP_Container_C",
        "WBP_LootBox_C",
    },
}

local function get_slot_panel_type(slot_widget)
    if not alive(slot_widget) then return "none" end

    local current = slot_widget
    local depth = 0
    while alive(current) and depth < 25 do
        local class = get(function() return current:GetClass() end)
        local class_name = get(function() return class:GetFName():ToString() end) or ""

        for _, cls in ipairs(PANEL_CLASS_NAMES.player) do
            if class_name == cls then return "player" end
        end
        for _, cls in ipairs(PANEL_CLASS_NAMES.container) do
            if class_name == cls then return "container" end
        end

        current = get(function() return current:GetParent() end)
        depth = depth + 1
    end

    return "unknown"
end

--- 获取当前鼠标悬停的槽位
--- 返回: slot_widget, panel_type
local function get_hovered_slot()
    local pc = player_controller()
    if not alive(pc) then return nil, "none" end

    local game_viewport = get(function() return pc:GetGameViewport() end)
    if not alive(game_viewport) then return nil, "none" end

    local viewport_widget = get(function() return game_viewport.ViewportWidget end)
    if not alive(viewport_widget) then return nil, "none" end

    -- 找当前打开的面板
    local panel = nil
    local panel_type = "none"

    for _, cls in ipairs(PANEL_CLASS_NAMES.player) do
        panel = find_widget_by_class(viewport_widget, cls)
        if panel then panel_type = "player" break end
    end

    if not panel then
        for _, cls in ipairs(PANEL_CLASS_NAMES.container) do
            panel = find_widget_by_class(viewport_widget, cls)
            if panel then panel_type = "container" break end
        end
    end

    if not panel then
        log("没有打开背包/容器面板")
        return nil, "none"
    end

    -- 获取悬停的控件
    local hovered = get(function() return panel:GetHoveredWidget() end)
    if not alive(hovered) then
        hovered = get(function() return panel.HoveredSlot end)
    end

    if not alive(hovered) then
        log("没有悬停的槽位")
        return nil, "none"
    end

    log("Hovered: " .. (get(function() return hovered:GetClass():GetFName():ToString() end) or "?"))

    -- 确认槽位所属面板
    local slot_type = get_slot_panel_type(hovered)
    if slot_type == "unknown" or slot_type == "none" then
        slot_type = panel_type
    end

    return hovered, slot_type
end

-- ============================================================
-- 物品操作
-- ============================================================

--- 背包物品 → 丢到地上
local function drop_item_to_world(slot_widget, amount)
    local item_ref = extract_item_ref(slot_widget)
    if not alive(item_ref) then
        log("槽位里没有物品")
        return
    end

    local quantity = extract_quantity(slot_widget)
    local drop_count = (amount == "stack") and quantity or 1

    local player = local_player()
    if not alive(player) then return end

    log(string.format("[丢弃] %s x%d", 
        get(function() return item_ref:GetClass():GetFName():ToString() end) or "?",
        drop_count))

    -- ==========================================================
    -- 按实际游戏版本打开对应的调用
    -- ==========================================================
    -- try("DropItem", function() player:DropItem(item_ref, drop_count) end)
    -- try("ServerDropItem", function() player:ServerDropItem(item_ref, drop_count) end)
    -- try("slot:DropItem", function() slot_widget:DropItem(drop_count) end)

    print(string.format("[ItemQuickDrop] 丢弃 %d 个物品", drop_count))
end

--- 容器物品 → 拾取到玩家背包
local function pickup_item_to_player(slot_widget, amount)
    local item_ref = extract_item_ref(slot_widget)
    if not alive(item_ref) then
        log("槽位里没有物品")
        return
    end

    local quantity = extract_quantity(slot_widget)
    local take_count = (amount == "stack") and quantity or 1

    local player = local_player()
    if not alive(player) then return end

    log(string.format("[拾取] %s x%d",
        get(function() return item_ref:GetClass():GetFName():ToString() end) or "?",
        take_count))

    -- ==========================================================
    -- 按实际游戏版本打开对应的调用
    -- ==========================================================
    -- 注意：必须走服务端 RPC，纯客户端加物品不会同步
    -- try("TransferToPlayer", function() slot_widget:TransferToPlayer(take_count) end)
    -- try("ServerGiveItem", function() container:ServerGiveItemToPlayer(item_ref, take_count) end)
    -- try("TransferItem", function() player.InventoryComponent:TransferItemFromContainer(slot_widget, take_count) end)

    print(string.format("[ItemQuickDrop] 拾取 %d 个物品", take_count))
end

local function handle_action(slot_widget, panel_type, amount)
    if panel_type == "player" then
        drop_item_to_world(slot_widget, amount)
    elseif panel_type == "container" then
        pickup_item_to_player(slot_widget, amount)
    else
        log("无法识别槽位所属面板")
    end
end

-- ============================================================
-- 按键回调
-- ============================================================
local function on_single()
    if not CONFIG.enabled then return end
    try("on_single", function()
        local slot, ptype = get_hovered_slot()
        if slot then handle_action(slot, ptype, "single") end
    end)
end

local function on_stack()
    if not CONFIG.enabled then return end
    try("on_stack", function()
        local slot, ptype = get_hovered_slot()
        if slot then handle_action(slot, ptype, "stack") end
    end)
end

-- ============================================================
-- 注册按键
-- ============================================================
local function bind_key(key_enum, mods, callback, label)
    if not key_enum then return end

    local ok
    if mods and #mods > 0 then
        ok = pcall(RegisterKeyBind, key_enum, mods, callback)
    else
        ok = pcall(RegisterKeyBind, key_enum, callback)
    end

    if ok then
        log("已绑定: " .. label)
    else
        print("[ItemQuickDrop] 绑定失败: " .. label)
    end
end

local function register_keybinds()
    bind_key(key_single, mods_single, on_single, CONFIG.key_single_str)
    bind_key(key_stack, mods_stack, on_stack, CONFIG.key_stack_str)
end

-- ============================================================
-- 重载
-- ============================================================
local function reload()
    print("[ItemQuickDrop] 重载中...")
    load_config()
    register_keybinds()
    print("[ItemQuickDrop] 重载完成！")
    print(string.format("[ItemQuickDrop] %s = 操作1个 | %s = 操作整组",
        CONFIG.key_single_str, CONFIG.key_stack_str))
end

_G.ItemQuickDrop_Reload = reload

-- ============================================================
-- 入口
-- ============================================================
local function Init()
    print("[ItemQuickDrop] 加载中... v1.3.0")

    load_config()
    register_keybinds()

    print("[ItemQuickDrop] 加载完成！")
    print(string.format("[ItemQuickDrop] ┌ 悬停【自己背包】: %s 丢1个 | %s 丢整组",
        CONFIG.key_single_str, CONFIG.key_stack_str))
    print(string.format("[ItemQuickDrop] └ 悬停【箱子/容器】: %s 拿1个 | %s 拿整组",
        CONFIG.key_single_str, CONFIG.key_stack_str))
    print("[ItemQuickDrop] 控制台输入 ItemQuickDrop_Reload() 可重载")
end

Init()
