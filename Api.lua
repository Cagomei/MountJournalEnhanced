local _, ADDON = ...

ADDON.Api = {}

--region mountIdToOriginalIndex
local mountIdToOriginalIndex

local function collectMountIds()
    ADDON:ResetIngameFilter()

    local list = {}
    local count = C_MountJournal.GetNumDisplayedMounts()
    for i = 1, count do
        local mountId = select(12, C_MountJournal.GetDisplayedMountInfo(i))
        list[mountId] = i
    end

    return list
end

local function MountIdToOriginalIndex(mountId, recursionCounter)
    if nil == mountIdToOriginalIndex then
        mountIdToOriginalIndex = collectMountIds()
    end

    local index = mountIdToOriginalIndex[mountId] or nil

    if index then
        local displayedMountId = select(12, C_MountJournal.GetDisplayedMountInfo(index))
        if displayedMountId ~= mountId then
            mountIdToOriginalIndex = nil
            recursionCounter = recursionCounter or 1
            if recursionCounter < 4 then
                return MountIdToOriginalIndex(mountId, recursionCounter + 1)
            end
        end
    end

    return index
end
--endregion

function ADDON.Api:GetMountInfoByID(mountId)
    local creatureName, spellId, icon, active, isUsable, sourceType, isFavorite, isFaction, faction, hideOnChar, isCollected, mountID, a, b, c, d, e, f, g, h = C_MountJournal.GetMountInfoByID(mountId)
    isUsable = isUsable and IsUsableSpell(spellId)

    return creatureName, spellId, icon, active, isUsable, sourceType, isFavorite, isFaction, faction, hideOnChar, isCollected, mountID, a, b, c, d, e, f, g, h
end
function ADDON.Api:PickupByID(mountId, ...)
    local index = MountIdToOriginalIndex(mountId)
    if index then
        return C_MountJournal.Pickup(index, ...)
    end
end
function ADDON.Api:GetIsFavoriteByID(mountId, ...)
    local index = MountIdToOriginalIndex(mountId)
    if index then
        return C_MountJournal.GetIsFavorite(index, ...)
    end
end
function ADDON.Api:SetIsFavoriteByID(mountId, ...)
    local index = MountIdToOriginalIndex(mountId)
    if index then
        C_MountJournal.SetIsFavorite(index, ...)
        mountIdToOriginalIndex = nil
    end
end

local selectedMount, selectedCreature
function ADDON.Api:SetSelected(selectedMountID, selectedVariation)
    if selectedMount ~= selectedMountID then
        selectedMount = selectedMountID
        selectedCreature = selectedVariation or nil
        MountJournal_SelectByMountID(selectedMountID)
        --MountJournal_HideMountDropdown();
        --ADDON.UI:UpdateMountList()
        ADDON.UI:UpdateMountDisplay()
    elseif selectedCreature ~= selectedVariation then
        selectedCreature = selectedVariation or nil
        ADDON.UI:UpdateMountDisplay(true)
    end
end
function ADDON.Api:GetSelected()
    return selectedMount, selectedCreature
end

-- from https://www.townlong-yak.com/framexml/live/Blizzard_Collections/Blizzard_MountCollection.lua#668
function ADDON.Api:UseMount(mountID)
    if mountID then
        local creatureName, spellID, icon, active = C_MountJournal.GetMountInfoByID(mountID);
        if (active) then
            C_MountJournal.Dismiss();
        elseif (C_MountJournal.NeedsFanfare(mountID)) then
            local function OnFinishedCallback()
                C_MountJournal.ClearFanfare(mountID);
                --MountJournal_HideMountDropdown();
                ADDON.UI:UpdateMountList()
                ADDON.UI:UpdateMountDisplay()
            end
            MountJournal.MountDisplay.ModelScene:StartUnwrapAnimation(OnFinishedCallback);
        else
            C_MountJournal.SummonByID(mountID);
        end
    end
end

ADDON.Events:RegisterCallback("OnJournalLoaded", function()
    -- setup hooks
    hooksecurefunc("MountJournal_SelectByMountID", function(mountId)
        ADDON.Api:SetSelected(mountId)
    end)
end, "api hooks")