local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Sonar = require(ReplicatedStorage:WaitForChild("Sonar"))

local PurchaseMarketStallSkin_RF = Sonar("RemoteUtils").GetRemoteEvent("PurchaseMarketStallSkin")

local MarketStallService = Sonar("MarketStallService")
local DisplayUtils = Sonar("DisplayUtils")

local function purchaseSkinForFree(skinModel)
    if not skinModel or not skinModel:IsA("Model") then
        warn("Invalid skin model provided.")
        return false
    end

    local skinName = skinModel:GetAttribute("Name")
    local skinDisplayName = skinModel:GetAttribute("DisplayName") or skinName

    if not skinName or skinName == "" then
        warn("Skin model has no 'Name' attribute. Skipping.")
        return false
    end

    local playerWrapper = Sonar("PlayerWrapper").GetClient()
    if playerWrapper and MarketStallService.PlayerOwnsSkin(playerWrapper, skinName) then
        print(string.format("Already own skin: %s. Skipping.", skinDisplayName))
        return true
    end

    local originalPrice = skinModel:GetAttribute("Price")
    local originalCurrency = skinModel:GetAttribute("Currency")

    skinModel:SetAttribute("Price", 0)
    skinModel:SetAttribute("Currency", "Shooms")

    print(string.format("Attempting to purchase skin '%s' (originally %s %s) for FREE...",
        skinDisplayName, originalPrice, originalCurrency))

    local success, result = pcall(function()
        return PurchaseMarketStallSkin_RF:InvokeServer(skinName)
    end)

    skinModel:SetAttribute("Price", originalPrice)
    skinModel:SetAttribute("Currency", originalCurrency)

    if success then
        if result == true then
            print(string.format("Successfully (client-side reported) purchased '%s'!", skinDisplayName))
            return true
        else
            warn(string.format("Failed to purchase '%s'. Server response: %s", skinDisplayName, tostring(result)))
            return false
        end
    else
        warn(string.format("Error invoking server for '%s': %s", skinDisplayName, tostring(result)))
        return false
    end
end

local potentialSkinModels = {}
for _, descendant in ipairs(workspace:GetDescendants()) do
    if descendant:IsA("Model") and descendant:GetAttribute("IsMarketStallSkin") then
        if descendant:GetAttribute("Name") and descendant:GetAttribute("DisplayName") and
           descendant:GetAttribute("Price") and descendant:GetAttribute("Currency") then
            table.insert(potentialSkinModels, descendant)
        end
    elseif string.find(descendant.Name, "MarketStallSkinPurchase", 1, true) then
        if descendant:GetAttribute("Name") and descendant:GetAttribute("DisplayName") and
           descendant:GetAttribute("Price") and descendant:GetAttribute("Currency") then
            table.insert(potentialSkinModels, descendant)
        end
    end
end

if #potentialSkinModels > 0 then
    print(string.format("Found %d potential market stall skins to attempt purchasing.", #potentialSkinModels))
    for i, skinModel in ipairs(potentialSkinModels) do
        purchaseSkinForFree(skinModel)
        task.wait(0.1)
    end
    print("Attempted to purchase all identified market stall skins.")
else
    warn("No potential market stall skin models found in workspace. Exploit might need adjustment for current game structure.")
end
