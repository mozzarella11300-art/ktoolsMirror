-- KTools/window.lua
local addonName = ...
local AceGUI    = LibStub("AceGUI-3.0")

local FRAME_NAME = "KToolsMainFrame"

local function RegisterSpecialFrame(frame)
    _G[FRAME_NAME] = frame
    for i = 1, #UISpecialFrames do
        if UISpecialFrames[i] == FRAME_NAME then return end
    end
    tinsert(UISpecialFrames, FRAME_NAME)
end

local function BuildWindow()
    local f = AceGUI:Create("Frame")
    f:SetTitle(GetAddOnMetadata(addonName, "Title"))
    f:SetStatusText(
        "v" .. (GetAddOnMetadata(addonName, "Version") or "?") ..
        "  |  by " .. (GetAddOnMetadata(addonName, "Author") or "?")
    )
    f:SetWidth(800)
    f:SetHeight(600)
    f:SetLayout("Fill")
    f.frame:SetMinResize(800, 600)
    f.frame:SetFrameStrata("HIGH")
    RegisterSpecialFrame(f.frame)

    local tree = AceGUI:Create("TreeGroup")
    tree:SetFullWidth(true)
    tree:SetFullHeight(true)
    tree:SetLayout("Fill")
    tree:SetTree({})
    tree:SetCallback("OnGroupSelected", function(widget, _, key)
        widget:ReleaseChildren()
        KTools:_onModuleSelected(key, widget)
    end)
    f:AddChild(tree)

    f:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        _G[FRAME_NAME] = nil
        KTools.window  = nil
        KTools.navTree = nil
    end)

    KTools.window  = f
    KTools.navTree = tree
end

function KTools:OpenWindow()
    if self.window then
        self.window.frame:Show()
        return
    end
    BuildWindow()
end

function KTools:CloseWindow()
    if self.window then self.window:Hide() end
end

function KTools:ToggleWindow()
    if self.window and self.window.frame:IsShown() then
        self:CloseWindow()
    else
        self:OpenWindow()
    end
end

function KTools:_refreshNav()
    if not self.navTree then return end
    local items = {}
    for key, mod in pairs(self._modules or {}) do
        items[#items+1] = { value = key, text = mod.title or key }
    end
    table.sort(items, function(a, b) return a.text < b.text end)
    self.navTree:SetTree(items)
end
