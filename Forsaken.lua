--[[
    ITOSHI HUB V30 | THE GODFATHER EDITION
    ARCHITECT: ITOSHI AI & USER (CO-DEV)
    BUILD: 30.0.1 (FINAL RELEASE)
    
    [ CHANGELOG V30 ]
    + ADDED: Direct Hook for 'Util:SetSpeedCap' (Infinite Stamina Fix)
    + ADDED: Smart Proximity Check for Generators
    + ADDED: Anti-Stun V4 (Deletes 'SlownessStatus' objects instantly)
    + OPTIMIZED: Combat Engine with 60hz active scanning
]]

local Services = setmetatable({}, {
    __index = function(self, key) return game:GetService(key) end
})

-- // 1. CORE SERVICES //
local Players = Services.Players
local Workspace = Services.Workspace
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local VirtualInputManager = Services.VirtualInputManager
local UserInputService = Services.UserInputService
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting
local Stats = Services.Stats
local TeleportService = Services.TeleportService
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // 2. GLOBAL CONFIGURATION //
local Itoshi = {
    Auth = {
        Key = "FFDGDLFYUFOHDWHHFXX",
        Version = "V30-GODFATHER"
    },
    Settings = {
        Combat = {
            Enabled = false,
            AutoBlock = false,
            BlockRange = 25,
            Prediction = true,
            PredictionAmount = 0.15,
            DoubleTap = false,
            FaceEnemy = true,
            LegitMode = false
        },
        Generator = {
            Enabled = false,
            AutoFix = false,
            FixSpeed = 0.05, -- Optimized speed
            AutoLeave = true,
            DetectionRadius = 15
        },
        Movement = {
            SpeedEnabled = false,
            SpeedFactor = 22, -- Legit Run Speed
            InfiniteStamina = false,
            AntiStun = true,
            BunnyHop = false
        },
        Visuals = {
            Enabled = false,
            Boxes = false,
            Names = false,
            Distance = false,
            Tracers = false,
            Fullbright = false,
            HitboxExpand = false,
            HitboxSize = 20,
            HitboxColor = Color3.fromRGB(255, 0, 0)
        }
    },
    Cache = {
        EspObjects = {},
        SoundDebounce = {},
        Generators = {},
        LastBlock = 0
    }
}

-- // 3. ULTIMATE DATABASE (KILLER SOUNDS) //
-- Full list extracted from game files
local KillerSounds = {
    -- Generic
    ["102228729296384"] = true, ["140242176732868"] = true, 
    ["112809109188560"] = true, ["136323728355613"] = true,
    
    -- Slasher / Jason
    ["115026634746636"] = true, ["84116622032112"] = true,
    ["108907358619313"] = true, ["127793641088496"] = true,
    
    -- Noli / 1x1x1x1
    ["86174610237192"] = true, ["95079963655241"] = true,
    ["101199185291628"] = true, ["119942598489800"] = true,
    
    -- Guest 666 / Nosferatu (New)
    ["84307400688050"] = true, ["113037804008732"] = true,
    ["105200830849301"] = true, ["75330693422988"] = true,
    ["82221759983649"] = true, ["81702359653578"] = true,
    
    -- Misc / Rare
    ["108610718831698"] = true, ["112395455254818"] = true,
    ["109431876587852"] = true, ["109348678063422"] = true,
    ["85853080745515"] = true, ["12222216"] = true,
    ["105840448036441"] = true, ["114742322778642"] = true,
    ["119583605486352"] = true, ["79980897195554"] = true,
    ["71805956520207"] = true, ["79391273191671"] = true
}

-- // 4. UTILITY FUNCTIONS //
local Utils = {}

function Utils.GetRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Utils.GetHum(char)
    return char and char:FindFirstChild("Humanoid")
end

function Utils.GetPing()
    return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
end

function Utils.SafeCall(func, ...)
    local s, e = pcall(func, ...)
    if not s then warn("[ITOSHI ERROR]: " .. tostring(e)) end
end

-- // 5. SECURITY & BYPASS (THE HOOK) //
-- This hook intercepts the game's attempt to slow you down
local OldNC
OldNC = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if not checkcaller() then
        -- 1. Intercept SetSpeedCap (Stamina Bypass)
        -- Based on the file you provided: Util:SetSpeedCap(Player, "SlownessStatus", value)
        if method == "FireServer" and self.Name == "SetSpeedCap" then
            if Itoshi.Settings.Movement.InfiniteStamina then
                return nil -- Block the signal entirely
            end
        end
        
        -- 2. Intercept WalkSpeed Changes
        if method == "__newindex" and self:IsA("Humanoid") and args[1] == "WalkSpeed" then
            if Itoshi.Settings.Movement.InfiniteStamina and args[2] < 18 then
                return nil -- Reject slow speed
            end
        end
    end
    
    return OldNC(self, ...)
end)

-- // 6. GENERATOR ENGINE (DIRECT ACCESS) //
local function ScanGenerators()
    -- Clear cache and rescan
    table.clear(Itoshi.Cache.Generators)
    
    local Map = Workspace:FindFirstChild("Map")
    local Ingame = Map and Map:FindFirstChild("Ingame")
    local GenFolder = Ingame and Ingame:FindFirstChild("Map") and Ingame.Map:FindFirstChild("Generator")
    
    if GenFolder then
        for _, Gen in pairs(GenFolder:GetChildren()) do
            if Gen:FindFirstChild("Remotes") and Gen:FindFirstChild("Progress") then
                table.insert(Itoshi.Cache.Generators, Gen)
            end
        end
    end
end
ScanGenerators() -- Initial Scan

local function ProcessGenerators()
    if not Itoshi.Settings.Generator.Enabled then return end
    
    local MyRoot = Utils.GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- Auto rescan if empty
    if #Itoshi.Cache.Generators == 0 then ScanGenerators() end

    for _, Gen in pairs(Itoshi.Cache.Generators) do
        -- Check if gen still exists
        if not Gen or not Gen.Parent then 
            ScanGenerators()
            break 
        end
        
        local MainPart = Gen:FindFirstChild("Main") or Gen:FindFirstChild("COLLISION") or Gen.PrimaryPart
        
        if MainPart and (MainPart.Position - MyRoot.Position).Magnitude < Itoshi.Settings.Generator.DetectionRadius then
            
            local Remotes = Gen.Remotes
            local RE = Remotes:FindFirstChild("RE") -- Confirmed RemoteEvent
            local RF = Remotes:FindFirstChild("RF") -- Confirmed RemoteFunction
            local Progress = Gen.Progress
            
            if RE and Progress and Progress.Value < 100 then
                
                -- Step 1: Simulate Enter (Once)
                if not Gen:GetAttribute("ItoshiActive") then
                    pcall(function() RF:InvokeServer("enter") end)
                    Gen:SetAttribute("ItoshiActive", true)
                end
                
                -- Step 2: Fire Fix Logic
                if Itoshi.Settings.Generator.Mode == "Blatant" then
                    -- Multi-Fire for speed
                    for i = 1, 3 do RE:FireServer() end
                else
                    -- Legit Fire
                    RE:FireServer()
                end
                
                -- Step 3: Auto Leave
                if Itoshi.Settings.Generator.AutoLeave and Progress.Value >= 99 then
                    pcall(function() RF:InvokeServer("leave") end)
                    Gen:SetAttribute("ItoshiActive", nil)
                end
            end
        end
    end
end

-- // 7. COMBAT ENGINE (AUDIO SCANNER) //
local function ProcessCombat()
    if not Itoshi.Settings.Combat.Enabled then return end
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Sound") and v.IsPlaying then
            local id = string.match(v.SoundId, "%d+")
            
            -- Check Database or Volume
            if (id and KillerSounds[id]) or (v.Volume > 0.8 and v.PlaybackSpeed > 0.8) then
                
                -- Debounce
                if Itoshi.Cache.SoundDebounce[v] and (tick() - Itoshi.Cache.SoundDebounce[v]) < 0.4 then continue end
                
                local SPos = v.Parent and v.Parent.Position
                local MyRoot = Utils.GetRoot(LocalPlayer.Character)
                
                if SPos and MyRoot then
                    local Dist = (SPos - MyRoot.Position).Magnitude
                    
                    if Dist <= Itoshi.Settings.Combat.BlockRange then
                        Itoshi.Cache.SoundDebounce[v] = tick()
                        
                        -- Ping Prediction
                        local Ping = Utils.GetPing() / 1000
                        local Prediction = Itoshi.Settings.Combat.Prediction and (Ping * 0.5) or 0
                        
                        task.delay(0.1 - Prediction, function()
                            -- Block
                            ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Block")
                            
                            -- Double Tap
                            if Itoshi.Settings.Combat.DoubleTap then
                                task.delay(0.1, function()
                                    ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Punch")
                                end)
                            end
                        end)
                    end
                end
            end
        end
    end
end

-- // 8. MOVEMENT ENGINE (PHYSICS FORCE) //
local function ProcessMovement()
    local Char = LocalPlayer.Character
    if not Char then return end
    
    local Hum = Utils.GetHum(Char)
    local Root = Utils.GetRoot(Char)
    
    if Hum and Root then
        -- Speed Hack (Velocity)
        if Itoshi.Settings.Movement.SpeedEnabled and Hum.MoveDirection.Magnitude > 0 then
            Root.AssemblyLinearVelocity = Vector3.new(
                Hum.MoveDirection.X * Itoshi.Settings.Movement.SpeedFactor * 5,
                Root.AssemblyLinearVelocity.Y,
                Hum.MoveDirection.Z * Itoshi.Settings.Movement.SpeedFactor * 5
            )
        end
        
        -- Anti-Stun (Object Removal based on your files)
        if Itoshi.Settings.Movement.AntiStun then
            for _, child in pairs(Char:GetChildren()) do
                if child.Name == "SlownessStatus" or child.Name == "Stun" or child.Name == "SpeedStatus" then
                    child:Destroy() -- Destroy the debuff object immediately
                end
            end
            Hum.PlatformStand = false
        end
        
        -- Infinite Stamina (Force Speed)
        if Itoshi.Settings.Movement.InfiniteStamina then
            if Hum.WalkSpeed < 20 then Hum.WalkSpeed = 22 end
            Char:SetAttribute("Stamina", 100) -- Visual Fix
        end
    end
end

-- // 9. ESP ENGINE (DRAWING API) //
local ESP = {}

function ESP.Create(Model)
    if Itoshi.Cache.EspObjects[Model] then return end
    
    local Obj = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Square")
    }
    
    Obj.Box.Visible = false
    Obj.Box.Thickness = 1.5
    Obj.Box.Color = Color3.fromRGB(255, 0, 0)
    Obj.Box.Filled = false
    
    Obj.Name.Visible = false
    Obj.Name.Center = true
    Obj.Name.Color = Color3.new(1,1,1)
    Obj.Name.Size = 14
    
    Itoshi.Cache.EspObjects[Model] = Obj
end

function ESP.Update()
    if not Itoshi.Settings.Visuals.Enabled then
        for _, v in pairs(Itoshi.Cache.EspObjects) do v.Box.Visible = false v.Name.Visible = false end
        return
    end
    
    for _, P in pairs(Players:GetPlayers()) do
        if P ~= LocalPlayer and P.Character and Utils.GetRoot(P.Character) then
            ESP.Create(P.Character)
            local Obj = Itoshi.Cache.EspObjects[P.Character]
            local Root = Utils.GetRoot(P.Character)
            local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            
            if OnScreen then
                local H = 2500 / Pos.Z
                local W = H * 0.6
                
                if Itoshi.Settings.Visuals.Boxes then
                    Obj.Box.Size = Vector2.new(W, H)
                    Obj.Box.Position = Vector2.new(Pos.X - W/2, Pos.Y - H/2)
                    Obj.Box.Visible = true
                else Obj.Box.Visible = false end
                
                if Itoshi.Settings.Visuals.Names then
                    Obj.Name.Text = P.Name .. " ["..math.floor((Root.Position - Utils.GetRoot(LocalPlayer.Character).Position).Magnitude).."m]"
                    Obj.Name.Position = Vector2.new(Pos.X, Pos.Y - H/2 - 15)
                    Obj.Name.Visible = true
                else Obj.Name.Visible = false end
            else
                Obj.Box.Visible = false
                Obj.Name.Visible = false
            end
        end
    end
end

-- // 10. MAIN LOOPS //
RunService.RenderStepped:Connect(function()
    Utils.SafeCall(ProcessMovement)
    Utils.SafeCall(ProcessCombat)
    Utils.SafeCall(ESP.Update)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.ClockTime = 14
    end
end)

task.spawn(function()
    while true do
        task.wait(Itoshi.Settings.Generator.FixSpeed)
        Utils.SafeCall(ProcessGenerators)
    end
end)

-- // 11. UI SETUP (RAYFIELD) //
local Library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Library:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "loading script...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiV30", FileName = "Cfg"},
    KeySystem = false
})

local TabGen = Window:CreateTab("Generator", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabMove = Window:CreateTab("Movement", 4483362458)
local TabVis = Window:CreateTab("Visuals", 4483362458)

-- Generator
TabGen:CreateToggle({Name = "Auto Fix (Proximity)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Generator.Enabled = v end})
TabGen:CreateDropdown({Name = "Mode", Options = {"Blatant", "Legit"}, CurrentOption = "Blatant", Callback = function(v) Itoshi.Settings.Generator.Mode = v end})
TabGen:CreateSlider({Name = "Fix Speed", Range = {0, 0.2}, Increment = 0.01, CurrentValue = 0.05, Callback = function(v) Itoshi.Settings.Generator.FixSpeed = v end})
TabGen:CreateToggle({Name = "Auto Leave", CurrentValue = false, Callback = function(v) Itoshi.Settings.Generator.AutoLeave = v end})

-- Combat
TabCombat:CreateToggle({Name = "Auto Block", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Enabled = v Itoshi.Settings.Combat.AutoBlock = v end})
TabCombat:CreateToggle({Name = "Double Tap", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.DoubleTap = v end})
TabCombat:CreateToggle({Name = "Ping Prediction", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Prediction = v end})
TabCombat:CreateSlider({Name = "Range", Range = {10, 50}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.BlockRange = v end})

-- Movement
TabMove:CreateToggle({Name = "Infinite Stamina (Bypass)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.InfiniteStamina = v end})
TabMove:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.SpeedEnabled = v end})
TabMove:CreateSlider({Name = "Speed Factor", Range = {16, 50}, Increment = 1, CurrentValue = 22, Callback = function(v) Itoshi.Settings.Movement.SpeedFactor = v end})
TabMove:CreateToggle({Name = "Anti-Stun (Delete Debuffs)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.AntiStun = v end})

-- Visuals
TabVis:CreateToggle({Name = "Player ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Enabled = v end})
TabVis:CreateToggle({Name = "Boxes", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Boxes = v end})
TabVis:CreateToggle({Name = "Names", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Names = v end})
TabVis:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

Rayfield:LoadConfiguration()
