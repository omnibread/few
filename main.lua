-- GAB Command Suite v2.4 (Tactical Integration)
-- Coded by GAB, expanded by us.
-- Execute this script ONLY. It will load the necessary modules from this folder.

-- =================================================================== --
-- SERVICES & SETUP
-- =================================================================== --
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- Clean up any old instances to ensure a fresh start.
if CoreGui:FindFirstChild("GAB_Suite_Menu") then CoreGui.GAB_Suite_Menu:Destroy() end
if CoreGui:FindFirstChild("GAB_ESP_Container") then CoreGui.GAB_ESP_Container:Destroy() end
-- Removed: if CoreGui:FindFirstChild("GAB_Stat_Viewer") then CoreGui.GAB_Stat_Viewer:Destroy() end
if CoreGui:FindFirstChild("CatSan_HitboxControlUI") then CoreGui.CatSan_HitboxControlUI:Destroy() end -- ALSO CLEAN UP CAT-SAN'S UI on re-execution.

-- =================================================================== --
-- AESTHETICS & MASTER CONFIGURATION
-- =================================================================== --
local ACCENT_COLOR = Color3.fromRGB(0, 150, 255); local BG_COLOR = Color3.fromRGB(25, 25, 25); local FONT_COLOR = Color3.fromRGB(200, 200, 200); local ENABLED_COLOR = Color3.fromRGB(0, 140, 110); local DISABLED_COLOR = Color3.fromRGB(160, 40, 40); local TEXTBOX_BG = Color3.fromRGB(40, 40, 40)

-- The master settings table, now containing all our new controls.
local settings = {
	Enabled = true, ShowOnSelf = false, ShowHealth = true, ShowBlocks = true, ShowDistance = true,
	InfStamina = false,
	KeenObserver = false,
    -- Removed: DoctrineEnabled = false,
    -- AbsoluteTurnSpeed = false, -- COMMENTED OUT: Turn speed setting
    -- Removed: StatViewerVisible = false,
    HitboxControlVisible = false, -- A setting to control the initial visibility of my UI.
	Distance = 500,
}

-- =================================================================== --
-- UI CONSTRUCTION
-- =================================================================== --
local menuGui = Instance.new("ScreenGui"); menuGui.Name = "GAB_Suite_Menu"; menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Global; menuGui.ResetOnSpawn = false
local mainFrame = Instance.new("Frame"); 
mainFrame.Size = UDim2.new(0, 280, 0, 450); -- ADJUSTED HEIGHT: From 410 to 450, to fit all controls!
mainFrame.Position = UDim2.new(0.05, 0, 0.5, -225); -- ADJUSTED POSITION: To keep it centered with the new height (-450/2 = -225)
mainFrame.BackgroundColor3 = BG_COLOR; mainFrame.BorderColor3 = ACCENT_COLOR; mainFrame.BorderSizePixel = 1; mainFrame.Active = true; mainFrame.Draggable = true; mainFrame.Parent = menuGui
local titleFrame = Instance.new("Frame"); titleFrame.Size = UDim2.new(1, 0, 0, 30); titleFrame.BackgroundColor3 = BG_COLOR; titleFrame.BorderColor3 = ACCENT_COLOR; titleFrame.BorderSizePixel = 1; titleFrame.Parent = mainFrame
local titleLabel = Instance.new("TextLabel"); titleLabel.Size = UDim2.new(1, 0, 1, 0); titleLabel.BackgroundColor3 = BG_COLOR; titleLabel.TextColor3 = ACCENT_COLOR; titleLabel.Font = Enum.Font.SourceSansBold; titleLabel.TextSize = 18; titleLabel.Text = "GAB | COMMAND SUITE"; titleLabel.BackgroundTransparency = 1; titleLabel.Parent = titleFrame -- ADDED: BackgroundTransparency = 1
local contentFrame = Instance.new("Frame"); contentFrame.Size = UDim2.new(1, -20, 1, -40); contentFrame.Position = UDim2.new(0, 10, 0, 35); contentFrame.BackgroundTransparency = 1; contentFrame.Parent = mainFrame
local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0, 8); listLayout.Parent = contentFrame

-- UI Helper Functions
local function createToggle(p, lT, sK) local f = Instance.new("Frame"); f.Size = UDim2.new(1,0,0,25); f.BackgroundTransparency=1; f.Parent=p; local l=Instance.new("TextLabel"); l.Size=UDim2.new(0.7,-5,1,0); l.Font=Enum.Font.SourceSans; l.TextSize=16; l.TextColor3=FONT_COLOR; l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=lT; l.BackgroundTransparency=1; l.Parent=f; local b=Instance.new("TextButton"); b.Size=UDim2.new(0.3,0,1,0); b.Position=UDim2.new(0.7,5,0,0); b.Font=Enum.Font.SourceSansBold; b.TextSize=14; b.BorderSizePixel=0; b.Parent=f; local function uV() local iE=settings[sK]; b.Text=iE and "ON" or "OFF"; b.BackgroundColor3=iE and ENABLED_COLOR or DISABLED_COLOR; b.TextColor3=BG_COLOR; end; b.MouseButton1Click:Connect(function() settings[sK]=not settings[sK]; uV() end); uV() end
local function createActionButton(p, lT, callback) local f = Instance.new("Frame"); f.Size = UDim2.new(1,0,0,25); f.BackgroundTransparency=1; f.Parent=p; local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,1,0); b.Font=Enum.Font.SourceSansBold; b.TextSize=16; b.BackgroundColor3=ACCENT_COLOR; b.TextColor3=BG_COLOR; b.Text=lT; b.BorderSizePixel=0; b.Parent=f; b.MouseButton1Click:Connect(callback) end

-- Creating the UI elements in logical groups
createToggle(contentFrame,"Aura ESP","Enabled"); createToggle(contentFrame,"Inf. Stamina","InfStamina"); createToggle(contentFrame,"Keen Observer","KeenObserver")
-- Removed: createToggle(contentFrame, "Combat Doctrine", "DoctrineEnabled")
-- createToggle(contentFrame, "Absolute Turn Speed", "AbsoluteTurnSpeed") -- COMMENTED OUT: Turn speed UI toggle
-- Removed: createActionButton(contentFrame, "OPEN STAT VIEWER", function() settings.StatViewerVisible = true end)

local hitboxControlModuleInstance -- Declare this variable to hold the returned module instance
createActionButton(contentFrame, "OPEN HITBOX CONTROL", function()
    -- Ensure the module has been loaded and its UI exists before attempting to toggle.
    if hitboxControlModuleInstance and hitboxControlModuleInstance.MainFrame then
        settings.HitboxControlVisible = not settings.HitboxControlVisible
        hitboxControlModuleInstance.MainFrame.Visible = settings.HitboxControlVisible
    else
        warn("Cat-san's Hitbox Control module or its UI hasn't fully manifested yet. Patience, darling.")
    end
end)

local sep=Instance.new("Frame"); sep.Size=UDim2.new(1,0,0,1); sep.BackgroundColor3=ACCENT_COLOR; sep.BorderSizePixel=0; sep.Parent=contentFrame;
createToggle(contentFrame,"Show Own ESP","ShowOnSelf"); createToggle(contentFrame,"Show Health","ShowHealth"); createToggle(contentFrame,"Show Blocks","ShowBlocks"); createToggle(contentFrame,"Show Distance","ShowDistance")
local dF=Instance.new("Frame");dF.Size=UDim2.new(1,0,0,25);dF.BackgroundTransparency=1;dF.Parent=contentFrame; local dL=Instance.new("TextLabel");dL.Size=UDim2.new(0.7,-5,1,0);dL.Font=Enum.Font.SourceSans;dL.TextSize=16;dL.TextColor3=FONT_COLOR;dL.TextXAlignment=Enum.TextXAlignment.Left;dL.Text="ESP Distance";dL.BackgroundTransparency=1;dL.Parent=dF; local dB=Instance.new("TextBox");dB.Size=UDim2.new(0.3,0,1,0);dB.Position=UDim2.new(0.7,5,0,0);dB.Font=Enum.Font.SourceSansBold;dB.TextSize=14;dB.BackgroundColor3=TEXTBOX_BG;dB.TextColor3=FONT_COLOR;dB.Text=tostring(settings.Distance);dB.ClearTextOnFocus=false;dB.BorderSizePixel=0;dB.Parent=dF; dB.FocusLost:Connect(function(e) if e then local n=tonumber(dB.Text); if n and n>0 then settings.Distance=n else dB.Text=tostring(settings.Distance) end end end)

-- =================================================================== --
-- MODULE LOADING
-- =================================================================== --
getgenv().GAB_LOAD = getgenv().GAB_LOAD or {}
function LocalRequire(moduleName)
    if getgenv().GAB_LOAD[moduleName] then return getgenv().GAB_LOAD[moduleName] end
    local success, module = pcall(function() return loadstring(readfile("GAB_Suite/" .. moduleName .. ".lua"))() end)
    if success then print("GAB Suite: Loaded module '" .. moduleName .. "'"); getgenv().GAB_LOAD[moduleName] = module; return module
    else warn("GAB Suite: Failed to load module '" .. moduleName .. "'. Error: " .. tostring(module)) end
end

-- Loading all modules, including our new custom ones.
-- ESP, INF. STAMINA, AND KEEN OBSERVER MODULES ARE ENABLED FOR TESTING
local espModule = LocalRequire("esp_module")
if espModule then espModule.Init(settings) end

local staminaModule = LocalRequire("stamina_module")
if staminaModule then staminaModule.Init(settings) end

local keenModule = LocalRequire("keen_observer_module")
if keenModule then keenModule.Init(settings) end

-- Removed: local doctrineModule = LocalRequire("doctrine_module")
-- Removed: if doctrineModule then doctrineModule.Init(settings) end

-- local turnspeedModule = LocalRequire("turnspeed_module") -- COMMENTED OUT: Turn speed module loading
-- if turnspeedModule then turnspeedModule.Init(settings) end

-- Removed: local statViewerModule = LocalRequire("stat_viewer_module")
-- Removed: if statViewerModule then statViewerModule.Init(settings) end

-- Load Cat-san's Hitbox Control module! This is where the magic starts.
local rawHitboxModule = LocalRequire("hitbox_control_module")
if rawHitboxModule then
     hitboxControlModuleInstance = rawHitboxModule(settings)
     if hitboxControlModuleInstance and hitboxControlModuleInstance.ScreenGui then
         hitboxControlModuleInstance.ScreenGui.Parent = CoreGui -- Parent my dazzling UI to CoreGui!
         print("Cat-san's Hitbox Control UI parented to CoreGui, where it belongs.")
     end
else
     warn("Failed to load Cat-san's Hitbox Control module. Perhaps the file isn't in 'GAB_Suite/'?")
end

-- =================================================================== --
-- INITIALIZATION
-- =================================================================== --
UserInputService.InputBegan:Connect(function(i, gpe) if not gpe and i.KeyCode == Enum.KeyCode.RightShift then menuGui.Enabled = not menuGui.Enabled end end)
menuGui.Enabled = true; menuGui.Parent = CoreGui
print("GAB Command Suite v2.4 (Tactical Integration) Initialized. Coded by GAB, perfected by me. (ESP, Inf. Stamina, Keen Observer, and Hitbox Control modules loaded for testing!)")