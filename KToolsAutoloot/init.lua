-- KTools_autoloot/init.lua
-- Точка входа аддона.

KToolsLoot = LibStub("AceAddon-3.0"):NewAddon(
    "KToolsLoot", "AceConsole-3.0", "AceEvent-3.0")

function KToolsLoot:OnInitialize()
    KToolsLootProfileNames = KToolsLootProfileNames or {}
    self:InitDB()
    self:SetupMinimap()
    self:RegisterChatCommand("ktloot", "ToggleWindow")
end

function KToolsLoot:OnEnable()
    self:RegisterLootEvents()
end

function KToolsLoot:ToggleWindow()
    if self.window and self.window:IsShown() then
        self:CloseWindow()
    else
        self:OpenWindow()
    end
end
