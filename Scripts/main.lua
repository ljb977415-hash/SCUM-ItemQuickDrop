--[[
    SCUM ItemQuickDrop Mod
    ----------------------
    在背包/容器界面中：
      F       = 从鼠标悬停的槽位丢出 / 取出 1 个物品
      Shift+F = 丢出 / 取出整组物品
    
    依赖：UE4SS (RE-UE4SS) Lua 环境
--]]

local M = {}

-- ============================================================
-- 配置区（可按需修改）
-- ============================================================
local CONFIG = {
    debug = false,               -- 调试模式，输出详细日志
    key_single = Key.F,          -- 按 F 丢单个
    key_stack = Key.F,           -- Shift+F 丢整组
    modifier_stack = { Key.SHIFT },
}

-- ============================================================
-- 工具函数
-- ============================================================
local function log(msg)
    if CONFIG.debug then
        print("[ItemQuickDrop] " .. tostring(msg))
    end
end

local function get_player_controller()
    -- 获取本地玩家控制器
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
-- 获取当前打开的背包 / 容器 UI 及鼠标悬停槽位
-- ============================================================
-- SCUM 的背包 UI 大概是 WB_MainInventoryPanel / WB_ContainerPanel 这类 UMG 控件。
-- 下面的函数会遍历 UI 根控件，尝试找到背包面板和当前 hover 的槽位。
-- 如果类名不对，用 UE4SS 的 UHT Dumper / Object Viewer 在游戏里查真实类名。

--- 在控件树中递归查找指定类名的控件
local function find_widget_by_class(root_widget, class_name)
    if not root_widget or not root_widget:IsValid() then return nil end
    
    local class = root_widget:GetClass()
    if class and class:GetFName():ToString() == class_name then
        return root_widget
    end
    
    -- 遍历子控件
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

--- 获取当前鼠标悬停的 Inventory 槽位（SlotWidget）
--- 返回：槽位控件对象（可能包含 ItemRef / Quantity 等字段）
local function get_hovered_slot()
    local pc = get_player_controller()
    if not pc then return nil end
    
    -- 获取游戏 UI 的根画布
    local game_viewport = pc:GetGameViewport()
    if not game_viewport then return nil end
    
    local viewport_widget = game_viewport.ViewportWidget
    if not viewport_widget or not viewport_widget:IsValid() then
        log("ViewportWidget 无效")
        return nil
    end
    
    -- 尝试常见的背包面板类名（按优先级排序）
    local panel_class_names = {
        "WB_MainInventoryPanel_C",
        "WB_InventoryPanel_C",
        "WB_ContainerPanel_C",
        "WB_Container_C",
        "WB_BagPanel_C",
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
    
    -- 获取鼠标当前悬停的槽位控件
    -- UMG 里常见的做法是用 GetHoveredWidget 或者遍历 Grid 里的 Slot
    local hovered = inventory_panel:GetHoveredWidget()
    if hovered and hovered:IsValid() then
        log("Hovered widget: " .. hovered:GetClass():GetFName():ToString())
        return hovered
    end
    
    -- 备选：如果上面的方法拿不到，试 GetSlotUnderMouse / HoveredSlot
    if inventory_panel.HoveredSlot and inventory_panel.HoveredSlot:IsValid() then
        return inventory_panel.HoveredSlot
    end
    
    return nil
end

-- ============================================================
-- 执行丢物品操作
-- ============================================================
--- 从指定槽位丢出物品
--- @param slot_widget 槽位控件
--- @param amount "single" 丢1个 / "stack" 丢整组
local function drop_item_from_slot(slot_widget, amount)
    if not slot_widget or not slot_widget:IsValid() then
        log("槽位无效")
        return
    end
    
    -- 从槽位里拿到物品引用和数量
    -- 常见字段名：Item / ItemRef / InventoryItem / Quantity / Count
    local item_ref = slot_widget.Item or slot_widget.ItemRef or slot_widget.InventoryItem
    local quantity = slot_widget.Quantity or slot_widget.Count or 1
    
    if not item_ref or not item_ref:IsValid() then
        log("槽位里没有物品")
        return
    end
    
    log(string.format("操作物品: %s, 数量: %d, 模式: %s", 
        item_ref:GetClass():GetFName():ToString(), quantity, amount))
    
    -- ==========================================================
    -- 调用游戏的丢物品接口
    -- ==========================================================
    -- SCUM 里丢物品通常走 PlayerController / Character 的 RPC，
    -- 常见函数名（需要按你游戏版本在 Dumper 里确认）：
    --
    --   player:DropItem(item_ref, amount)
    --   player:ServerDropItem(item_ref, amount)
    --   inventory_component:DropItemBySlot(slot_index, amount)
    --   character:DropItem(item_ref, quantity_to_drop)
    --
    -- 下面给出最常见的两种调用方式，按实际情况打开注释。
    
    local player = get_local_player()
    if not player then
        log("本地玩家无效")
        return
    end
    
    local drop_count = 1
    if amount == "stack" then
        drop_count = quantity
    end
    
    -- 方式一：通过 Character 直接调（最常见）
    -- player:DropItem(item_ref, drop_count)
    
    -- 方式二：通过 InventoryComponent
    -- local inv_comp = player.InventoryComponent
    -- if inv_comp and inv_comp:IsValid() then
    --     inv_comp:ServerDropItem(item_ref, drop_count)
    -- end
    
    -- 方式三：通过槽位自身的 Drop 方法
    -- slot_widget:DropItem(drop_count)
    
    log(string.format("执行丢物品: 数量 %d", drop_count))
    print(string.format("[ItemQuickDrop] 丢出 %d 个物品", drop_count))
end

-- ============================================================
-- 按键回调
-- ============================================================
local function on_key_single()
    log("按下 F（丢单个）")
    local slot = get_hovered_slot()
    if slot then
        drop_item_from_slot(slot, "single")
    end
end

local function on_key_stack()
    log("按下 Shift+F（丢整组）")
    local slot = get_hovered_slot()
    if slot then
        drop_item_from_slot(slot, "stack")
    end
end

-- ============================================================
-- 注册按键
-- ============================================================
local function register_keybinds()
    -- F = 丢单个
    RegisterKeyBind(CONFIG.key_single, on_key_single)
    log("已绑定 F = 丢单个")
    
    -- Shift+F = 丢整组
    RegisterKeyBind(CONFIG.key_stack, CONFIG.modifier_stack, on_key_stack)
    log("已绑定 Shift+F = 丢整组")
end

-- ============================================================
-- 入口
-- ============================================================
local function Init()
    print("[ItemQuickDrop] 模组加载中...")
    
    -- 等待游戏对象加载完成后再注册
    -- UE4SS 提供 ExecuteWithDelay / LoopUntil 来等待
    -- 简单起见直接注册，按键回调里再做对象有效性检查
    
    register_keybinds()
    print("[ItemQuickDrop] 加载完成！")
    print("[ItemQuickDrop] F = 丢1个, Shift+F = 丢整组")
end

Init()
