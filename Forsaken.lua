local Services = setmetatable({}, {
    __index = function(self, key)
        return game:GetService(key)
    end
})

-- // SERVICES //
local Players = Services.Players
local Workspace = Services.Workspace
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local VirtualInputManager = Services.VirtualInputManager
local UserInputService = Services.UserInputService
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting
local Stats = Services.Stats
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // CONFIGURATION & STATE //
local Itoshi = {
    Config = {
        Combat = {
            Enabled = true,
            AudioBlock = true,
            AnimBlock = true,
            Prediction = true,
            Range = 25,
            DoubleTap = true,
            Delays = {
                ["c00lkidd"] = 0,
                ["jason"] = 0.013,
                ["slasher"] = 0.01,
                ["1x1x1x1"] = 0.15,
                ["johndoe"] = 0.33,
                ["noli"] = 0.15,
                ["nosferatu"] = 0.02,
                ["guest 666"] = 0.15,
                ["default"] = 0.1
            }
        },
        Generator = {
            Enabled = true,
            Mode = "Hybrid", -- Hybrid, Instant, Legit
            FixSpeed = 0.03,
            AutoLeave = true
        },
        Movement = {
            SpeedEnabled = false,
            SpeedFactor = 0.8,
            PulseMove = true,
            AntiStun = true,
            InfiniteStamina = true
        },
        Visuals = {
            Enabled = true,
            Boxes = true,
            Names = true,
            Fullbright = true,
            HitboxExpand = true,
            HitboxSize = 22,
            HitboxColor = Color3.fromRGB(255, 0, 0)
        }
    },
    Cache = {
        EspObjects = {},
        CachedSounds = {},
        LastBlock = 0
    }
}

-- // FULL DATABASE (NO ABBREVIATIONS) //
local TargetSounds = {
    ["102228729296384"] = true,
    ["140242176732868"] = true,
    ["112809109188560"] = true,
    ["136323728355613"] = true,
    ["115026634746636"] = true,
    ["84116622032112"] = true,
    ["108907358619313"] = true,
    ["127793641088496"] = true,
    ["86174610237192"] = true,
    ["95079963655241"] = true,
    ["101199185291628"] = true,
    ["119942598489800"] = true,
    ["84307400688050"] = true,
    ["113037804008732"] = true,
    ["105200830849301"] = true,
    ["75330693422988"] = true,
    ["82221759983649"] = true,
    ["81702359653578"] = true,
    ["108610718831698"] = true,
    ["112395455254818"] = true,
    ["109431876587852"] = true,
    ["109348678063422"] = true,
    ["85853080745515"] = true,
    ["12222216"] = true,
    ["105840448036441"] = true,
    ["114742322778642"] = true,
    ["119583605486352"] = true,
    ["79980897195554"] = true,
    ["71805956520207"] = true,
    ["79391273191671"] = true,
    ["89004992452376"] = true,
    ["101553872555606"] = true,
    ["101698569375359"] = true,
    ["106300477136129"] = true,
    ["116581754553533"] = true,
    ["117231507259853"] = true,
    ["119089145505438"] = true,
    ["121954639447247"] = true,
    ["125213046326879"] = true,
    ["131406927389838"] = true,
    ["71834552297085"] = true,
    ["805165833096"] = true,
    ["125403313786645"] = true,
    ["83829782357897"] = true
}

local TargetAnims = {
    "126830014841198", "126355327951215", "121086746534252", "18885909645", 
    "98456918873918", "105458270463374", "83829782357897", "125403313786645", 
    "118298475669935", "82113744478546", "70371667919898", "99135633258223", 
    "97167027849946", "109230267448394", "139835501033932", "126896426760253", 
    "109667959938617", "126681776859538", "129976080405072", "121293883585738", 
    "81639435858902", "137314737492715", "92173139187970", "122709416391", 
    "879895330952"
}

-- // UTILITY FUNCTIONS //
local function GetRoot(char) 
    return char and char:FindFirstChild("HumanoidRootPart") 
end

local function GetHum(char) 
    return char and char:FindFirstChild("Humanoid") 
end

local function SafeCall(func, ...) 
    pcall(func, ...) 
end

local function GetPing()
    return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
end

-- // CUSTOM ESP SYSTEM //
local ESP = {}
function ESP.Create(Model)
    if Itoshi.Cache.EspObjects[Model] then return end
    local Obj = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Model = Model
    }
    Obj.Box.Visible = false
    Obj.Box.Color = Color3.fromRGB(255, 50, 50)
    Obj.Box.Thickness = 1.5
    Obj.Box.Filled = false
    Obj.Name.Visible = false
    Obj.Name.Color = Color3.fromRGB(255, 255, 255)
    Obj.Name.Size = 16
    Obj.Name.Center = true
    Obj.Name.Outline = true
    Itoshi.Cache.EspObjects[Model] = Obj
end

function ESP.Remove(Model)
    if Itoshi.Cache.EspObjects[Model] then
        Itoshi.Cache.EspObjects[Model].Box:Remove()
        Itoshi.Cache.EspObjects[Model].Name:Remove()
        Itoshi.Cache.EspObjects[Model] = nil
    end
end

function ESP.Update()
    if not Itoshi.Config.Visuals.Enabled then 
        for _, v in pairs(Itoshi.Cache.EspObjects) do v.Box.Visible = false v.Name.Visible = false end
        return 
    end
    for Model, Obj in pairs(Itoshi.Cache.EspObjects) do
        if Model.Parent and GetRoot(Model) and GetHum(Model) and GetHum(Model).Health > 0 then
            local Vec, OnScreen = Camera:WorldToViewportPoint(GetRoot(Model).Position)
            if OnScreen then
                local Size = 2500 / Vec.Z
                if Itoshi.Config.Visuals.Boxes then
                    Obj.Box.Size = Vector2.new(Size * 0.8, Size)
                    Obj.Box.Position = Vector2.new(Vec.X - Obj.Box.Size.X / 2, Vec.Y - Obj.Box.Size.Y / 2)
                    Obj.Box.Visible = true
                else Obj.Box.Visible = false end
                
                if Itoshi.Config.Visuals.Names then
                    Obj.Name.Text = Model.Name .. " [" .. math.floor((LocalPlayer.Character.HumanoidRootPart.Position - GetRoot(Model).Position).Magnitude) .. "m]"
                    Obj.Name.Position = Vector2.new(Vec.X, Vec.Y - (Obj.Box.Size.Y / 2) - 20)
                    Obj.Name.Visible = true
                else Obj.Name.Visible = false end
            else Obj.Box.Visible = false Obj.Name.Visible = false end
        else ESP.Remove(Model) end
    end
end

-- // GENERATOR AI (HYBRID & INSTANT) //
local function InitGeneratorAI()
    local OldNC
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        if not checkcaller() and getnamecallmethod() == "InvokeServer" and self.Name == "RF" then
            if args[1] == "enter" then
                Itoshi.State.IsInteracting = true
                Itoshi.State.CurrentGen = self.Parent.Parent
                if Itoshi.Config.Generator.Enabled then
                    task.spawn(function()
                        local Gen = Itoshi.State.CurrentGen
                        local RE = Gen and Gen:FindFirstChild("Remotes") and Gen.Remotes:FindFirstChild("RE")
                        local Prog = Gen and Gen:FindFirstChild("Progress")
                        if RE and Prog then
                            while Itoshi.State.IsInteracting and Itoshi.Config.Generator.Enabled do
                                if Prog.Value >= 100 then
                                    if Itoshi.Config.Generator.AutoLeave then self:InvokeServer("leave") end
                                    break
                                end
                                
                                -- SEND FIX SIGNAL
                                RE:FireServer()
                                
                                -- SPEED LOGIC
                                if Itoshi.Config.Generator.Mode == "Hybrid" then
                                    if Prog.Value < 90 then
                                        task.wait(Itoshi.Config.Generator.FixSpeed)
                                    else
                                        task.wait(0.1) -- Slow down at end
                                    end
                                elseif Itoshi.Config.Generator.Mode == "Instant" then
                                    task.wait(0.005) -- Max Speed
                                else
                                    task.wait(0.15) -- Legit
                                end
                            end
                        end
                    end)
                end
            elseif args[1] == "leave" then
                Itoshi.State.IsInteracting = false
            end
        end
        return OldNC(self, ...)
    end)
end

-- // COMBAT ENGINE //
local function GetKillerDelay(model)
    if not model then return 0.1 end
    local name = model.Name:lower()
    for k, v in pairs(Itoshi.Config.Combat.Delays) do
        if name:find(k) then return v end
    end
    return 0.1
end

local function CalculatePingComp()
    if not Itoshi.Config.Combat.Prediction then return 0 end
    return (GetPing() / 1000) * 0.5
end

local function TriggerBlock(killerModel)
    if tick() - Itoshi.Cache.LastBlock < 0.2 then return end
    Itoshi.Cache.LastBlock = tick()
    
    local BaseDelay = GetKillerDelay(killerModel)
    local PingComp = CalculatePingComp()
    local FinalDelay = math.max(0, BaseDelay - PingComp)
    
    task.delay(FinalDelay, function()
        ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Block")
        if Itoshi.Config.Combat.DoubleTap then
            task.delay(0.12, function()
                ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Punch")
            end)
        end
    end)
end

local Combat = {}
function Combat.ProcessAudio(sound)
    if not Itoshi.Config.Combat.Enabled then return end
    local id = string.match(sound.SoundId, "%d+")
    if not id then return end
    
    if TargetSounds[id] or (sound.Volume > 0.8 and sound.PlaybackSpeed >= 0.9) then
        if Itoshi.Cache.CachedSounds[sound] and (tick() - Itoshi.Cache.CachedSounds[sound]) < 1 then return end
        
        local SPos = sound.Parent and sound.Parent.Position
        local MyRoot = GetRoot(LocalPlayer.Character)
        
        if SPos and MyRoot and (SPos - MyRoot.Position).Magnitude <= Itoshi.Config.Combat.Range then
            Itoshi.Cache.CachedSounds[sound] = tick()
            local Killer = sound.Parent:FindFirstAncestorOfClass("Model")
            TriggerBlock(Killer)
        end
    end
end

function Combat.ProcessAnimation()
    if not Itoshi.Config.Combat.AnimBlock then return end
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Root = GetRoot(Player.Character)
            local MyRoot = GetRoot(LocalPlayer.Character)
            if Root and MyRoot and (Root.Position - MyRoot.Position).Magnitude <= Itoshi.Config.Combat.Range then
                local Hum = GetHum(Player.Character)
                local Anim = Hum and Hum:FindFirstChild("Animator")
                if Anim then
                    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
                        local id = string.match(Track.Animation.AnimationId, "%d+")
                        for _, dbId in pairs(TargetAnims) do
                            if id == dbId then
                                TriggerBlock(Player.Character)
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- // INITIALIZATION & LOOPS //
InitGeneratorAI()

Workspace.DescendantAdded:Connect(function(v)
    if v:IsA("Sound") then v.Played:Connect(function() SafeCall(Combat.ProcessAudio, v) end) end
end)
for _, v in pairs(Workspace:GetDescendants()) do
    if v:IsA("Sound") then v.Played:Connect(function() SafeCall(Combat.ProcessAudio, v) end) end
end

RunService.RenderStepped:Connect(function()
    SafeCall(ESP.Update)
    
    local Char = LocalPlayer.Character
    if Char and GetRoot(Char) and GetHum(Char) then
        if Itoshi.Config.Movement.SpeedEnabled and GetHum(Char).MoveDirection.Magnitude > 0 then
            local Root = GetRoot(Char)
            if Itoshi.Config.Movement.PulseMove then
                Root.AssemblyLinearVelocity = Root.AssemblyLinearVelocity + (GetHum(Char).MoveDirection * Itoshi.Config.Movement.SpeedFactor * 5)
            else
                Root.CFrame = Root.CFrame + (GetHum(Char).MoveDirection * Itoshi.Config.Movement.SpeedFactor)
            end
        end
        if Itoshi.Config.Movement.AntiStun then
            if GetHum(Char).WalkSpeed < 10 then GetHum(Char).WalkSpeed = 16 end
            if Char:FindFirstChild("Slowness") then Char.Slowness:Destroy() end
        end
        if Itoshi.Config.Movement.InfiniteStamina and LocalPlayer:FindFirstChild("Stamina") then
            LocalPlayer.Stamina.Value = 100
        end
    end
    
    if Itoshi.Config.Visuals.Fullbright then Lighting.ClockTime = 14 end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Itoshi.Config.Visuals.HitboxExpand then
            for _, P in pairs(Players:GetPlayers()) do
                if P ~= LocalPlayer and P.Character and GetRoot(P.Character) then
                    local R = GetRoot(P.Character)
                    R.Size = Vector3.new(22, 22, 22)
                    R.Transparency = 0.7
                    R.CanCollide = false
                    R.Color = Color3.fromRGB(255, 0, 0)
                    ESP.Create(P.Character)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        SafeCall(Combat.ProcessAnimation)
    end
end)

-- // UI SETUP //
local Library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Library:CreateWindow({
    Name = "Itoshi Hub V9 ",
    LoadingTitle = "Full Database Loaded",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiV9", FileName = "Cfg"},
    KeySystem = true,
    KeySettings = {
        Title = "Authentication",
        Subtitle = "Enter Key",
        Note = "Key: FFDGDLFYUFOHDWHHFXX",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = "FFDGDLFYUFOHDWHHFXX"
    }
})

local TabGen = Window:CreateTab("Generator", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabMove = Window:CreateTab("Movement", 4483362458)
local TabVis = Window:CreateTab("Visuals", 4483362458)

TabGen:CreateToggle({Name = "Auto Generator", CurrentValue = true, Callback = function(v) Itoshi.Config.Generator.Enabled = v end})
TabGen:CreateDropdown({Name = "Mode", Options = {"Hybrid", "Instant", "Legit"}, CurrentOption = "Hybrid", Callback = function(v) Itoshi.Config.Generator.Mode = v end})
TabGen:CreateSlider({Name = "Speed", Range = {0, 0.2}, Increment = 0.01, CurrentValue = 0.03, Callback = function(v) Itoshi.Config.Generator.FixSpeed = v end})

TabCombat:CreateToggle({Name = "Auto Block (Audio)", CurrentValue = true, Callback = function(v) Itoshi.Config.Combat.AudioBlock = v end})
TabCombat:CreateToggle({Name = "Auto Block (Anim)", CurrentValue = true, Callback = function(v) Itoshi.Config.Combat.AnimBlock = v end})
TabCombat:CreateToggle({Name = "Ping Prediction", CurrentValue = true, Callback = function(v) Itoshi.Config.Combat.Prediction = v end})
TabCombat:CreateToggle({Name = "Double Tap", CurrentValue = true, Callback = function(v) Itoshi.Config.Combat.DoubleTap = v end})
TabCombat:CreateSlider({Name = "Range", Range = {10, 60}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Config.Combat.Range = v end})

TabMove:CreateToggle({Name = "Speed", CurrentValue = false, Callback = function(v) Itoshi.Config.Movement.SpeedEnabled = v end})
TabMove:CreateSlider({Name = "Factor", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.8, Callback = function(v) Itoshi.Config.Movement.SpeedFactor = v end})
TabMove:CreateToggle({Name = "Anti Stun", CurrentValue = true, Callback = function(v) Itoshi.Config.Movement.AntiStun = v end})

TabVis:CreateToggle({Name = "Enable ESP", CurrentValue = true, Callback = function(v) Itoshi.Config.Visuals.Enabled = v end})
TabVis:CreateToggle({Name = "Fullbright", CurrentValue = true, Callback = function(v) Itoshi.Config.Visuals.Fullbright = v end})
TabVis:CreateToggle({Name = "Hitbox Expander", CurrentValue = true, Callback = function(v) Itoshi.Config.Visuals.HitboxExpand = v end})

Rayfield:LoadConfiguration()
