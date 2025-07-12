-- Configuration
local TARGET_PLAYER_NAME = "kytomic" -- <<< CHANGE THIS to the player whose data you want to check
                                       -- Note: Data for other players might not always be fully replicated to your client.
                                       -- If you only get data for LocalPlayer, try changing this to game:GetService("Players").LocalPlayer.Name

-- From the decompiled script, these constants help us understand the data structure.
-- We can now use the actual value of v_u_26 directly from the decompiled code if we knew it.
-- For now, let's assume v_u_26 (MaxSlots) is 12, as it's a common max.
local MAX_POSSIBLE_LISTINGS = 12 -- This should ideally be 'v_u_26' from Constants.TradeRealm.MaxSlots
local DEFAULT_LISTING_SLOTS = 2  -- From 'v25.TradeRealm.DefaultSlots'
local UPGRADE_STEP_SLOTS = 2     -- From 'v25.TradeRealm.UpgradeStep'

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Main Script Execution
print("--- Starting Market Stall Data Inspection (Via PlayerWrapper Instance Access) ---")
print("Target Player: " .. TARGET_PLAYER_NAME)

local targetPlayer = Players:FindFirstChild(TARGET_PLAYER_NAME)

if not targetPlayer then
    print("[ERROR] Player '" .. TARGET_PLAYER_NAME .. "' not found in game. Make sure they are loaded.")
    print("--- Inspection Complete (Failed) ---")
    return
end

-- 1. Get the Sonar module (assuming it's in ReplicatedStorage)
local SonarModule = ReplicatedStorage:WaitForChild("Sonar", 10) -- Wait up to 10 seconds
if not SonarModule then
    print("[ERROR] 'Sonar' module not found in ReplicatedStorage. Is this game using the Sonar framework?")
    print("--- Inspection Complete (Failed) ---")
    return
end

local Sonar = require(SonarModule)
if not Sonar then
    print("[ERROR] Failed to require 'Sonar' module.")
    print("--- Inspection Complete (Failed) ---")
    return
end

-- 2. Get the PlayerWrapper module via Sonar
local PlayerWrapperModule = Sonar("PlayerWrapper")
if not PlayerWrapperModule or type(PlayerWrapperModule) ~= "table" or not PlayerWrapperModule.getWrapperFromPlayer then
    print("[ERROR] 'PlayerWrapper' module not found via Sonar, or it doesn't expose 'getWrapperFromPlayer()'.")
    print("--- Inspection Complete (Failed) ---")
    return
end

-- 3. Get the target player's PlayerWrapper instance
local targetPlayerWrapper = PlayerWrapperModule.getWrapperFromPlayer(targetPlayer)
if not targetPlayerWrapper then
    print("[ERROR] PlayerWrapper.getWrapperFromPlayer(" .. TARGET_PLAYER_NAME .. ") returned nil.")
    print("This means the player's wrapper data is not yet fully loaded or replicated to your client.")
    print("--- Inspection Complete (Failed) ---")
    return
end

-- 4. Access the PlayerData.MarketStalls Instance
local marketStallsContainer = targetPlayerWrapper.PlayerData and targetPlayerWrapper.PlayerData.MarketStalls

if not marketStallsContainer or not marketStallsContainer:IsA("Folder") then -- Expecting a Folder or Model
    print("[ERROR] PlayerWrapper.PlayerData.MarketStalls not found or is not a Folder/Instance.")
    print("This indicates the player's market stall data is not available on the client's PlayerWrapper in the expected instance structure.")
    print("--- Inspection Complete (Failed) ---")
    return
end

-- At this point, marketStallsContainer is a Roblox Instance (likely a Folder).
print("\n--- Found PlayerWrapper.PlayerData.MarketStalls (Roblox Instance). Inspecting contents ---")

print("\n--- MarketStalls Summary for " .. TARGET_PLAYER_NAME .. " ---")

-- Check for ShoomsRaised value (accessed as ValueBase)
local shoomsRaised = marketStallsContainer:FindFirstChild("ShoomsRaised")
if shoomsRaised and shoomsRaised:IsA("NumberValue") then
    print("Total Shooms Raised: " .. tostring(shoomsRaised.Value))
else
    print("ShoomsRaised (NumberValue) not found under MarketStalls.")
end

-- Check for Upgrades value (accessed as ValueBase)
local upgrades = marketStallsContainer:FindFirstChild("Upgrades")
local playerListingLimit = DEFAULT_LISTING_SLOTS
if upgrades and upgrades:IsA("NumberValue") then
    print("Market Stall Upgrades: " .. tostring(upgrades.Value))
    playerListingLimit = DEFAULT_LISTING_SLOTS + (upgrades.Value * UPGRADE_STEP_SLOTS)
    print("Calculated Active Listing Slots: " .. tostring(playerListingLimit))
else
    print("Market Stall Upgrades (NumberValue) not found. Assuming " .. DEFAULT_LISTING_SLOTS .. " slots.")
end

-- Check for EquippedSkin value (accessed as ValueBase)
local equippedSkin = marketStallsContainer:FindFirstChild("EquippedSkin")
if equippedSkin and equippedSkin:IsA("StringValue") then
    print("Equipped Stall Skin: " .. (equippedSkin.Value == "" and "Default" or equippedSkin.Value))
else
    print("Equipped Stall Skin (StringValue) not found. Assuming 'Default'.")
end

print("\n--- Individual Stall Listings ---")

local foundAnyListing = false
for i = 1, MAX_POSSIBLE_LISTINGS do
    local listingFolder = marketStallsContainer:FindFirstChild("Listing" .. i)

    if listingFolder and listingFolder:IsA("Folder") then
        foundAnyListing = true
        print("\n  --- Listing " .. i .. " ---")

        local itemName = listingFolder:FindFirstChild("ItemName")
        local amount = listingFolder:FindFirstChild("Amount")
        local price = listingFolder:FindFirstChild("Price")

        -- Determine if the slot is "empty" based on game logic (ItemName.Value == "")
        if itemName and itemName:IsA("StringValue") and itemName.Value == "" then
            print("    Status: Empty Slot")
        else
            print("    Status: Active Listing")
            if itemName and itemName:IsA("StringValue") then
                print("    Item Name: " .. itemName.Value)
            else
                print("    Item Name: Not found or not a StringValue")
            end

            if amount and amount:IsA("NumberValue") then
                print("    Amount: " .. tostring(amount.Value))
            else
                print("    Amount: Not found or not a NumberValue")
            end

            if price and price:IsA("NumberValue") then
                print("    Price: " .. tostring(price.Value))
            else
                print("    Price: Not found or not a NumberValue")
            end
        end

        -- Additionally check for any other ValueBases or attributes within the listing folder
        local foundOtherChildren = false
        for _, child in ipairs(listingFolder:GetChildren()) do
            -- Only print if it's not one of the main three we've already covered
            if child ~= itemName and child ~= amount and child ~= price then
                if child:IsA("ValueBase") then
                    print("    Other Value: " .. child.Name .. " (" .. child.ClassName .. "): " .. tostring(child.Value))
                    foundOtherChildren = true
                elseif child.ClassName == "Folder" or child.ClassName == "Model" then
                    print("    Nested Container: " .. child.Name .. " (" .. child.ClassName .. ")")
                    -- Iterate through contents of nested folders/models (basic level)
                    for _, subItem in ipairs(child:GetChildren()) do
                        if subItem:IsA("ValueBase") then
                            print("        - " .. subItem.Name .. " (" .. subItem.ClassName .. "): " .. tostring(subItem.Value))
                            foundOtherChildren = true
                        elseif subItem.ClassName == "Folder" or subItem.ClassName == "Model" then
                             print("        - " .. subItem.Name .. " (" .. subItem.ClassName .. ") - Contains more data (nested)")
                        else
                            print("        - " .. subItem.Name .. " (Type: " .. subItem.ClassName .. ")")
                        end
                    end
                else
                    print("    Other Child: " .. child.Name .. " (Type: " .. child.ClassName .. ")")
                    foundOtherChildren = true
                end
            end
        end
        if not foundOtherChildren then
            -- Only print this if the slot is active and no other children were found
            if not (itemName and itemName:IsA("StringValue") and itemName.Value == "") then
                print("    No other specific children found beyond ItemName, Amount, Price.")
            end
        end

    end
end

if not foundAnyListing then
    print("No 'ListingX' folders found within 'MarketStalls'.")
    print("This might mean the player has no items listed, or the listing names are different.")
end

print("\n--- Market Stall Inspection Complete ---")
