-- KTools/init.lua
local addonName = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

KTools = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")

KTools._modules = {}

function KTools:RegisterModule(key, descriptor)
    self._modules[key] = descriptor
    self:_refreshNav()
end

function KTools:_onModuleSelected(key, container)
    local mod = self._modules[key]
    if not mod or not mod.buildUI then return end
    local ok, err = xpcall(
        mod.buildUI,
        function(e) return e .. "\n" .. debugstack() end,
        container
    )
    if not ok then
        local AceGUI = LibStub("AceGUI-3.0")
        local lbl = AceGUI:Create("Label")
        lbl:SetText("|cffff0000" .. L["ERR_MODULE"]:format(key) .. "|r\n" .. tostring(err))
        lbl:SetFullWidth(true)
        container:AddChild(lbl)
        if container.DoLayout then container:DoLayout() end
    end
end

function KTools:OnInitialize()
    KToolsMinimapDB = KToolsMinimapDB or { hide = false }
    self:RegisterChatCommand("ktools", "ToggleWindow")
    self:RegisterChatCommand("ktl",    "ToggleWindow")
    self:SetupMinimap()
end
