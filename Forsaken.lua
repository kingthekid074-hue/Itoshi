local Services = setmetatable({}, {
    __index = function(self, key) return game:GetService(key) end
})

local Players = Services.Players
local Workspace = Services.Workspace
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local VirtualInputManager = Services.VirtualInputManager
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting
local Stats = Services.Stats
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // CONFIGURATION //
local Itoshi = {
    Settings = {
        Combat = {
            Enabled = false,
            AutoBlock = false,
            Prediction = false,
            Range = 25,
            DoubleTap = false
        },
        Generator = {
            Enabled = false,
            Mode = "Blatant", -- Blatant (Fast), Legit (Slow)
            Speed = 0.05,
            AutoLeave = false,
            Distance = 15
        },
        Movement = {
            SpeedEnabled = false,
            SpeedFactor = 22,
            InfiniteStamina = false,
            AntiStun = false
        },
        Visuals = {
            Enabled = false,
            Boxes = false,
            Names = false,
            Fullbright = false
        }
    },
    Cache = {
        SoundDebounce = {},
        EspObjects = {},
        Generators = {}
    }
}

-- // 1. DATABASE (KILLER SOUNDS) //
local KillerSounds = {
    ["102228729296384"] = true, ["140242176732868"] = true, ["112809109188560"] = true,
    ["136323728355613"] = true, ["115026634746636"] = true, ["84116622032112"] = true,
    ["108907358619313"] = true, ["127793641088496"] = true, ["86174610237192"] = true,
    ["95079963655241"] = true, ["101199185291628"] = true, ["119942598489800"] = true,
    ["84307400688050"] = true, ["113037804008732"] = true, ["105200830849301"] = true,
    ["75330693422988"] = true, ["82221759983649"] = true, ["81702359653578"] = true,
    ["108610718831698"] = true, ["112395455254818"] = true, ["109431876587852"] = true,
    ["109348678063422"] = true, ["85853080745515"] = true, ["12222216"] = true,
    ["105840448036441"] = true, ["114742322778642"] = true, ["119583605486352"] = true,
    ["79980897195554"] = true, ["71805956520207"] = true, ["79391273191671"] = true,
    ["89004992452376"] = true, ["101553872555606"] = true, ["101698569375359"] = true,
    ["106300477136129"] = true, ["116581754553533"] = true, ["117231507259853"] = true,
    ["119089145505438"] = true, ["121954639447247"] = true, ["125213046326879"] = true,
    ["131406927389838"] = true, ["71834552297085"] = true, ["805165833096"] = true,
    ["125403313786645"] = true, ["83829782357897"] = true
}

-- // 2. UTILITY FUNCTIONS //
local function GetRoot(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function GetHum(char) return char and char:FindFirstChild("Humanoid") end
local function GetPing() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end

-- // 3. GENERATOR SYSTEM (PROXIMITY FIXER) //
local function UpdateGenerators()
    table.clear(Itoshi.Cache.Generators)
    local Map = Workspace:FindFirstChild("Map")
    local GenFolder = Map and Map:FindFirstChild("Ingame") and Map.Ingame:FindFirstChild("Map") and Map.Ingame.Map:FindFirstChild("Generator")
    
    if GenFolder then
        for _, Gen in pairs(GenFolder:GetChildren()) do
            if Gen:FindFirstChild("Remotes") and Gen:FindFirstChild("Progress") then
                table.insert(Itoshi.Cache.Generators, Gen)
            end
        end
    end
end
UpdateGenerators() -- Initial Scan

local function ProcessGenerators()
    if not Itoshi.Settings.Generator.Enabled then return end
    
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- Periodic Rescan if empty (Anti-Crash)
    if #Itoshi.Cache.Generators == 0 then UpdateGenerators() end

    for _, Gen in pairs(Itoshi.Cache.Generators) do
        if Gen and Gen.Parent then
            local MainPart = Gen:FindFirstChild("Main") or Gen:FindFirstChild("COLLISION")
            
            if MainPart and (MainPart.Position - MyRoot.Position).Magnitude < Itoshi.Settings.Generator.Distance then
                local RE = Gen.Remotes:FindFirstChild("RE")
                local RF = Gen.Remotes:FindFirstChild("RF")
                local Progress = Gen:FindFirstChild("Progress")
                
                if RE and Progress and Progress.Value < 100 then
                    -- 1. Simulate Entry (Once per gen session)
                    if not Gen:GetAttribute("ItoshiEntered") then
                        pcall(function() RF:InvokeServer("enter") end)
                        Gen:SetAttribute("ItoshiEntered", true)
                    end
                    
                    -- 2. Fire Fix
                    -- Sending multiple signals if Blatant
                    local LoopCount = (Itoshi.Settings.Generator.Mode == "Blatant") and 3 or 1
                    for i = 1, LoopCount do
                        RE:FireServer()
                    end
                    
                    -- 3. Auto Leave
                    if Progress.Value >= 99 and Itoshi.Settings.Generator.AutoLeave then
                        pcall(function() RF:InvokeServer("leave") end)
                        Gen:SetAttribute("ItoshiEntered", nil)
                    end
                end
            end
        end
    end
end

-- // 4. COMBAT SYSTEM (AUDIO & PREDICTION) //
local function ProcessCombat()
    if not Itoshi.Settings.Combat.Enabled then return end
    if not Itoshi.Settings.Combat.AutoBlock then return end

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Sound") and v.IsPlaying then
            local id = string.match(v.SoundId, "%d+")
            
            if id and KillerSounds[id] then
                if Itoshi.Cache.SoundDebounce[v] and (tick() - Itoshi.Cache.SoundDebounce[v]) < 0.5 then continue end
                
                local SPos = v.Parent and v.Parent.Position
                local MyRoot = GetRoot(LocalPlayer.Character)
                
                if SPos and MyRoot and (SPos - MyRoot.Position).Magnitude <= Itoshi.Settings.Combat.Range then
                    Itoshi.Cache.SoundDebounce[v] = tick()
                    
                    -- Ping Prediction Calculation
                    local Ping = Itoshi.Settings.Combat.Prediction and (GetPing() / 1000) or 0
                    local Delay = math.max(0, 0.1 - (Ping * 0.5))
                    
                    task.delay(Delay, function()
                        ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Block")
                        
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

-- // 5. MOVEMENT & STAMINA (HOOK BYPASS) //
local OldNC
OldNC = hookmetamethod(game, "__newindex", function(self, key, value)
    if not checkcaller() and self:IsA("Humanoid") and key == "WalkSpeed" then
        if Itoshi.Settings.Movement.InfiniteStamina then
            -- If game tries to slow us down (stamina drain), we reject it
            if value < 16 then return end
        end
    end
    return OldNC(self, key, value)
end)

local function ProcessMovement()
    local Char = LocalPlayer.Character
    if Char and GetRoot(Char) and GetHum(Char) then
        local Hum = GetHum(Char)
        
        -- Speed Hack
        if Itoshi.Settings.Movement.SpeedEnabled then
            Hum.WalkSpeed = Itoshi.Settings.Movement.SpeedFactor
        end
        
        -- Anti-Stun (Remove Debuffs)
        if Itoshi.Settings.Movement.AntiStun then
            if Char:FindFirstChild("Slowness") then Char.Slowness:Destroy() end
            if Char:FindFirstChild("Stun") then Char.Stun:Destroy() end
            Hum.PlatformStand = false
        end
    end
end

-- // 6. VISUALS (ESP) //
local function UpdateESP()
    if not Itoshi.Settings.Visuals.Enabled then 
        for _, v in pairs(Itoshi.Cache.EspObjects) do v:Remove() end
        table.clear(Itoshi.Cache.EspObjects)
        return 
    end
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and GetRoot(Player.Character) then
            if not Itoshi.Cache.EspObjects[Player] then
                local HL = Instance.new("Highlight")
                HL.Name = "ItoshiESP"
                HL.Parent = CoreGui
                HL.Adornee = Player.Character
                HL.FillColor = Color3.fromRGB(255, 0, 0)
                HL.FillTransparency = 0.5
                HL.OutlineColor = Color3.fromRGB(255, 255, 255)
                HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                Itoshi.Cache.EspObjects[Player] = HL
            end
        else
            if Itoshi.Cache.EspObjects[Player] then
                Itoshi.Cache.EspObjects[Player]:Destroy()
                Itoshi.Cache.EspObjects[Player] = nil
            end
        end
    end
end

-- // 7. LOOPS //
RunService.RenderStepped:Connect(function()
    pcall(ProcessMovement)
    pcall(UpdateESP)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.ClockTime = 14
    end
    
    -- Active Combat Scan
    if Itoshi.Settings.Combat.AutoBlock then
        pcall(ProcessCombat)
    end
end)

task.spawn(function()
    while true do
        task.wait(Itoshi.Settings.Generator.Speed)
        pcall(ProcessGenerators)
    end
end)

-- // 8. UI //
local Library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Library:CreateWindow({
    Name = "Itoshi Hub ",
    LoadingTitle = "script loading...",
    ConfigurationSaving = {Enabled = true, FolderName = "Itoshi", FileName = "Config"},
    KeySystem = false
})

local TabGen = Window:CreateTab("Generator", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabMove = Window:CreateTab("Movement", 4483362458)
local TabVis = Window:CreateTab("Visuals", 4483362458)

TabGen:CreateToggle({Name = "Auto Fix (Stand Near)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Generator.Enabled = v end})
TabGen:CreateDropdown({Name = "Mode", Options = {"Blatant", "Legit"}, CurrentOption = "Blatant", Callback = function(v) Itoshi.Settings.Generator.Mode = v end})
TabGen:CreateSlider({Name = "Speed", Range = {0, 0.2}, Increment = 0.01, CurrentValue = 0.05, Callback = function(v) Itoshi.Settings.Generator.Speed = v end})
TabGen:CreateToggle({Name = "Auto Leave", CurrentValue = false, Callback = function(v) Itoshi.Settings.Generator.AutoLeave = v end})

TabCombat:CreateToggle({Name = "Enable Combat", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Enabled = v end})
TabCombat:CreateToggle({Name = "Auto Block (Sound)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock = v end})
TabCombat:CreateToggle({Name = "Ping Prediction", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Prediction = v end})
TabCombat:CreateToggle({Name = "Double Tap", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.DoubleTap = v end})
TabCombat:CreateSlider({Name = "Range", Range = {10, 60}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.Range = v end})

TabMove:CreateToggle({Name = "Infinite Stamina (Hook)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.InfiniteStamina = v end})
TabMove:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.SpeedEnabled = v end})
TabMove:CreateSlider({Name = "Speed Value", Range = {16, 50}, Increment = 1, CurrentValue = 22, Callback = function(v) Itoshi.Settings.Movement.SpeedFactor = v end})
TabMove:CreateToggle({Name = "Anti Stun", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.AntiStun = v end})

TabVis:CreateToggle({Name = "Enable ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Enabled = v end})
TabVis:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

Rayfield:LoadConfiguration()
