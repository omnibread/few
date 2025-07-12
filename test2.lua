-- Configuration
-- IMPORTANT: For data like MarketStalls (which is player-specific saved data),
-- it's highly probable that ONLY the LocalPlayer's data is fully replicated to your client.
-- Trying to access another player's Data.MarketStalls might result in nil,
-- even if the path is technically correct, because the server simply doesn't send it to you.
local TARGET_PLAYER_NAME = game:GetService("Players").LocalPlayer.GabiePomni -- Strongly recommended to test with LocalPlayer first.
                                                                    -- Change this to another player's name if you specifically need their data
                                                                    -- but be aware it might not be replicated to your client.

-- From previous decompiled scripts, these are constant values that help us interpret the data.
local MAX_POSSIBLE_LISTINGS = 12 -- From 'v25.TradeRealm.MaxSlots' (assuming it's 12)
local DEFAULT_LISTING_SLOTS = 2  -- From 'v25.TradeRealm.DefaultSlots' (assuming 2 base slots)
local UPGRADE_STEP_SLOTS = 2     -- From 'v25.TradeRealm.UpgradeStep' (assuming 2 slots per upgrade)

-- Services
local Players = game:GetService("Players")

-- Main Script Execution
print("--- Starting Market Stall Data Inspection (Direct Instance Access - No Sonar) ---")
print("Target Player: " .. TARGET_PLAYER_NAME)

local targetPlayer = Players:FindFirstChild(TARGET_PLAYER_NAME)

if not targetPlayer then
    print("[ERROR] Player '" .. TARGET_PLAYER_NAME .. "' not found in game. Make sure they are loaded.")
    print("--- Inspection Complete (Failed) ---")
    return
end

-- Attempt to access the 'Data' folder directly under the player.
-- Use WaitForChild to account for potential lazy loading of this folder.
print("Attempting to find 'Data' folder under player...")
local dataFolder = targetPlayer:WaitForChild("Data", 10) -- Wait up to 10 seconds for the 'Data' folder
if not dataFolder then
    print("[ERROR] 'Data' folder not found under player '" .. TARGET_PLAYER_NAME .. "' after 10 seconds.")
    print("This means the game might not directly replicate player data as a 'Data' folder,")
    print("or it's named differently, or it's simply not present on the client.")
    print("--- Inspection Complete (Failed) ---")
    return
end

if not dataFolder:IsA("Folder") then
    print("[ERROR] Found 'Data', but it's not a Folder (Type: " .. dataFolder.ClassName .. "). Expected a Folder.")
    print("--- Inspection Complete (Failed) ---")
    return
end
print("Found 'Data' folder.")


-- Attempt to access the 'MarketStalls' folder within the 'Data' folder.
print("Attempting to find 'MarketStalls' folder under 'Data'...")
local marketStallsContainer = dataFolder:WaitForChild("MarketStalls", 10) -- Wait up to 10 seconds for 'MarketStalls'
if not marketStallsContainer then
    print("[ERROR] 'MarketStalls' folder not found under 'Data' for player '" .. TARGET_PLAYER_NAME .. "' after 10 seconds.")
    print("This indicates the structure is different, or the data is not replicated as Instances.")
    print("--- Inspection Complete (Failed) ---")
    return
end

if not marketStallsContainer:IsA("Folder") then
    print("[ERROR] Found 'MarketStalls', but it's not a Folder (Type: " .. marketStallsContainer.ClassName .. "). Expected a Folder.")
    print("--- Inspection Complete (Failed) ---")
    return
end
print("Found 'MarketStalls' folder.")

-- At this point, marketStallsContainer is a Roblox Instance (Folder).
print("\n--- Found Data.MarketStalls (Roblox Instance). Inspecting contents ---")

print("\n--- MarketStalls Summary for " .. TARGET_PLAYER_NAME .. " ---")

-- Check for ShoomsRaised value
local shoomsRaised = marketStallsContainer:FindFirstChild("ShoomsRaised")
if shoomsRaised and shoomsRaised:IsA("NumberValue") then
    print("Total Shooms Raised: " .. tostring(shoomsRaised.Value))
else
    print("ShoomsRaised (NumberValue) not found under MarketStalls.")
end

-- Check for Upgrades value
local upgrades = marketStallsContainer:FindFirstChild("Upgrades")
local playerListingLimit = DEFAULT_LISTING_SLOTS
if upgrades and upgrades:IsA("NumberValue") then
    print("Market Stall Upgrades: " .. tostring(upgrades.Value))
    playerListingLimit = DEFAULT_LISTING_SLOTS + (upgrades.Value * UPGRADE_STEP_SLOTS)
    print("Calculated Active Listing Slots: " .. tostring(playerListingLimit))
else
    print("Market Stall Upgrades (NumberValue) not found. Assuming " .. DEFAULT_LISTING_SLOTS .. " slots.")
end

-- Check for EquippedSkin value
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
