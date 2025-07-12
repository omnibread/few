-- Configuration
local TARGET_PLAYER_NAME = "E750gamer" -- <<< CHANGE THIS to the player whose data you want to check
local MAX_STALL_LISTINGS = 10 -- A common max number of listings.
                             -- The decompiled code uses 'v_u_26 = v25.TradeRealm.MaxSlots'.
                             -- If this script doesn't find all listings, you might need to adjust this value.

-- Services
local Players = game:GetService("Players")

-- Function to safely get a descendant
local function getDescendant(instance, path)
    local current = instance
    for _, part in ipairs(path) do
        if current then
            current = current:FindFirstChild(part)
        else
            return nil
        end
    end
    return current
end

-- Main Script Execution
print("--- Starting Market Stall Data Inspection ---")
print("Target Player: " .. TARGET_PLAYER_NAME)

local targetPlayer = Players:FindFirstChild(TARGET_PLAYER_NAME)

if not targetPlayer then
    print("[ERROR] Player '" .. TARGET_PLAYER_NAME .. "' not found in game. Make sure they are loaded.")
    print("--- Inspection Complete (Failed) ---")
    return
end

-- Attempt to access the Data folder and MarketStalls within it
local marketStallsContainer = getDescendant(targetPlayer, {"Data", "MarketStalls"})

if not marketStallsContainer then
    print("[ERROR] Path 'Data.MarketStalls' not found under player '" .. TARGET_PLAYER_NAME .. "'.")
    print("This could mean:")
    print("  - The game doesn't place this data directly under 'Player.Data'.")
    print("  - The 'Data' folder or 'MarketStalls' instance are named differently.")
    print("  - The data is still not fully replicated to the client in this exact structure.")
    print("--- Inspection Complete (Failed) ---")
    return
end

print("\n--- Found MarketStalls container. Inspecting contents ---")

print("\n--- MarketStalls Summary for " .. TARGET_PLAYER_NAME .. " ---")

-- Check for ShoomsRaised value
local shoomsRaised = marketStallsContainer:FindFirstChild("ShoomsRaised")
if shoomsRaised and shoomsRaised:IsA("NumberValue") then
    print("Total Shooms Raised: " .. tostring(shoomsRaised.Value))
else
    print("ShoomsRaised value not found or not a NumberValue.")
end

print("\n--- Individual Stall Listings ---")

local foundListings = false
for i = 1, MAX_STALL_LISTINGS do
    local listingFolder = marketStallsContainer:FindFirstChild("Listing" .. i)

    if listingFolder and listingFolder:IsA("Folder") then
        foundListings = true
        print("\n  --- Listing " .. i .. " ---")
        local itemName = listingFolder:FindFirstChild("ItemName")
        local amount = listingFolder:FindFirstChild("Amount")
        local price = listingFolder:FindFirstChild("Price")

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

        -- Additionally check for any other ValueBases or attributes within the listing folder
        local foundOtherChildren = false
        for _, child in ipairs(listingFolder:GetChildren()) do
            if child ~= itemName and child ~= amount and child ~= price then
                if child:IsA("ValueBase") then
                    print("    Other Value: " .. child.Name .. " (" .. child.ClassName .. "): " .. tostring(child.Value))
                    foundOtherChildren = true
                elseif child.ClassName == "Folder" or child.ClassName == "Model" then
                    print("    Nested Container: " .. child.Name .. " (" .. child.ClassName .. ")")
                    -- You could add deeper recursion here if needed
                    for _, subChild in ipairs(child:GetChildren()) do
                        if subChild:IsA("ValueBase") then
                            print("        - " .. subChild.Name .. " (" .. subChild.ClassName .. "): " .. tostring(subChild.Value))
                            foundOtherChildren = true
                        end
                    end
                else
                    print("    Other Child: " .. child.Name .. " (Type: " .. child.ClassName .. ")")
                    foundOtherChildren = true
                end
            end
        end
        if not foundOtherChildren then
            print("    No other specific children found beyond ItemName, Amount, Price.")
        end

    -- else
    --     -- If a listing is not found, it implies we've gone past the last available listing
    --     -- or it's simply not there. Break if we expect sequential listings.
    --     break 
    end
end

if not foundListings then
    print("No 'ListingX' folders found within 'MarketStalls'.")
    print("This might mean the player has no items listed, or the listing names are different.")
end

print("\n--- Market Stall Inspection Complete ---")
