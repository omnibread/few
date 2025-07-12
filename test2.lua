-- Define the target RemoteEvent path
local REMOTE_PATH = "ReplicatedStorage.Remotes.BuyStallItem"

-- Find the remote
local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
if remote then
    remote = remote:FindFirstChild("BuyStallItem")
end

if not remote or not remote:IsA("RemoteEvent") then
    warn("Could not find the RemoteEvent at:", REMOTE_PATH)
    return
end

print("Found RemoteEvent:", REMOTE_PATH)

-- Store the original FireServer method
-- We need to capture this *before* we override it.
local originalFireServer = remote.FireServer

-- Override the FireServer method for this specific RemoteEvent instance
remote.FireServer = function(self, ...)
    -- 'self' will be the RemoteEvent itself (in this case, 'remote')
    -- '...' captures all the arguments passed to FireServer

    print("\n--- RemoteEvent Fired! ---")
    print("Remote:", REMOTE_PATH)

    -- Print arguments passed
    local args = {...}
    if #args > 0 then
        print("Arguments Passed:")
        for i, v in ipairs(args) do
            -- Attempt to get a more descriptive representation of the value
            local argString = tostring(v)
            if typeof(v) == "Instance" and v.Name then
                argString = v.Name .. " (Instance)"
            elseif typeof(v) == "table" then
                argString = "Table (count: " .. #v .. ")" -- Simplified for tables
            end
            print(string.format("  [%d]: %s (Type: %s)", i, argString, typeof(v)))
        end
    else
        print("No arguments passed.")
    end

    -- Print the call stack to identify the caller script and line number
    -- debug.traceback() gives you the current execution stack.
    -- The most relevant information will be the lines immediately above this function call.
    print("\n--- Call Stack (Caller Information) ---")
    print(debug.traceback()) -- This will show you where remote:FireServer() was called from.
    print("---------------------------------------\n")

    -- Call the original FireServer method to ensure the game's functionality is not broken.
    -- It's crucial to pass 'self' (the remote object itself) as the first argument
    -- when calling a method that was originally called with colon syntax (e.g., remote:FireServer(...)).
    -- If the original method was called with dot syntax (e.g., remote.FireServer(remote, ...)),
    -- then you'd call originalFireServer(self, ...). Since it's nearly always colon for remotes,
    -- passing 'self' explicitly is correct.
    return originalFireServer(self, ...)
end

print("Successfully hooked 'BuyStallItem:FireServer()'. Waiting for calls...")
