-- ... (After confirming it's a RemoteEvent as per previous step) ...1

local originalFireServer = remote.FireServer -- This will error as before

-- Attempt to get it from the metatable
if not originalFireServer then
    local remoteMeta = debug.getmetatable(remote)
    if remoteMeta and remoteMeta.__index then
        originalFireServer = rawget(remoteMeta.__index, "FireServer") -- Try rawget to bypass proxies
        if not originalFireServer then
            -- Even deeper: sometimes built-in methods are on the metatable of the metatable.
            -- This is getting very specific and executor-dependent.
            -- For most cases, __index of the main metatable is enough.
            local builtInMeta = debug.getmetatable(remoteMeta.__index)
            if builtInMeta and builtInMeta.__index then
                originalFireServer = rawget(builtInMeta.__index, "FireServer")
            end
        end
    end
end

if not originalFireServer then
    warn("Could not find original FireServer method even via metatable for", REMOTE_PATH)
    return
end

print("Successfully found original FireServer method for hooking.")

-- Now proceed with your hook as before:
remote.FireServer = function(self, ...)
    -- ... (your logging code) ...
    return originalFireServer(self, ...)
end

print("Successfully hooked 'BuyStallItem:FireServer()'. Waiting for calls...")
