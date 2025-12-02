local Services = setmetatable({}, {
    __index = function(self, key)
        return game:GetService(key)
    end
})

-- // 1. CORE SERVICES //
local Players = Services.Players
local Workspace = Services.Workspace
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local VirtualInputManager = Services.VirtualInputManager
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting
local Stats = Services.Stats
local LocalPlayer = Players.LocalPlayer

-- // 2. SYSTEM CONSTANTS & CONFIG //
local Itoshi = {
    Version = "7.1.0", -- Updated Version
    Auth = {
        Key = "FFDGDLFYUFOHDWHHFXX",
        Passed = false
    },
    State = {
        InteractingWithGen = false,
        CurrentGenTarget = nil,
        CachedSounds = {},
        LastBlock = 0,
        LastPunch = 0
    },
    Config = {
        Combat = {
            Enabled = true,
            AudioBlock = true,
            AnimBlock = true,
            Prediction = true,
            Range = 25,
            DoubleTap = true,
            Delays = {
                -- Classic Killers
                ["c00lkidd"] = 0,       -- Instant
                ["jason"] = 0.013,      -- Very Fast
                ["slasher"] = 0.01,     -- Very Fast
                ["1x1x1x1"] = 0.15,     -- Fast
                ["johndoe"] = 0.33,     -- Slow
                ["noli"] = 0.15,        -- Fast
                
                -- NEW KILLERS (ADDED)
                ["guest 666"] = 0.15,   -- Combo Based (Fast)
                ["nosferatu"] = 0.2,    -- Standard Melee (Medium)
                
                ["default"] = 0.1
            }
        },
        Generator = {
            Enabled = true,
            Mode = "Instant",
            AutoLeave = true
        },
        Movement = {
            SpeedEnabled = false,
            SpeedFactor = 1.0,
            AntiStun = true,
            InfiniteStamina = true
        },
        Visuals = {
            ESP = true,
            Fullbright = true,
            HitboxExpand = true,
            HitboxSize = 22,
            HitboxColor = Color3.fromRGB(255, 0, 0)
        }
    },
    -- [[ FULL DATABASE ]] --
    Database = {
        Sounds = {
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
        },
        Animations = {
            "126830014841198", "126355327951215", "121086746534252", "18885909645", 
            "98456918873918", "105458270463374", "83829782357897", "125403313786645", 
            "118298475669935", "82113744478546", "70371667919898", "99135633258223", 
            "97167027849946", "109230267448394", "139835501033932", "126896426760253", 
            "109667959938617", "126681776859538", "129976080405072", "121293883585738", 
            "81639435858902", "137314737492715", "92173139187970", "122709416391", "879895330952"
        }
    }
}

-- // 3. SECURE AUTH SYSTEM //
local function InitializeSecurity()
    if getgenv().ItoshiV7Auth then return end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ItoshiSecurityV7"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true

    local Blur = Instance.new("BlurEffect")
    Blur.Parent = Lighting
    Blur.Size = 0
    TweenService:Create(Blur, TweenInfo.new(0.8), {Size = 24}):Play()

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, 0, 0.6, 0)
    MainFrame.Size = UDim2.new(0, 450, 0, 260)
    MainFrame.BackgroundTransparency = 1

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 14)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Parent = MainFrame
    UIStroke.Color = Color3.fromRGB(255, 60, 60)
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 1

    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 0, 0.15, 0)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBlack
    Title.Text = "ITOSHI HUB V7"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 28
    Title.TextTransparency = 1

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Parent = MainFrame
    SubTitle.BackgroundTransparency = 1
    SubTitle.Position = UDim2.new(0, 0, 0.25, 0)
    SubTitle.Size = UDim2.new(1, 0, 0, 20)
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.Text = "GOD EMPEROR EDITION"
    SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    SubTitle.TextSize = 14
    SubTitle.TextTransparency = 1

    local InputFrame = Instance.new("Frame")
    InputFrame.Parent = MainFrame
    InputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    InputFrame.Position = UDim2.new(0.1, 0, 0.45, 0)
    InputFrame.Size = UDim2.new(0.8, 0, 0, 45)
    InputFrame.BackgroundTransparency = 1
    Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 8)

    local KeyInput = Instance.new("TextBox")
    KeyInput.Parent = InputFrame
    KeyInput.BackgroundTransparency = 1
    KeyInput.Size = UDim2.new(1, 0, 1, 0)
    KeyInput.Font = Enum.Font.GothamBold
    KeyInput.PlaceholderText = "ENTER LICENSE KEY"
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 16
    KeyInput.TextTransparency = 1

    local AuthBtn = Instance.new("TextButton")
    AuthBtn.Parent = MainFrame
    AuthBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    AuthBtn.Position = UDim2.new(0.1, 0, 0.72, 0)
    AuthBtn.Size = UDim2.new(0.8, 0, 0, 45)
    AuthBtn.Font = Enum.Font.GothamBlack
    AuthBtn.Text = "VERIFY ACCESS"
    AuthBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AuthBtn.TextSize = 16
    AuthBtn.BackgroundTransparency = 1
    AuthBtn.TextTransparency = 1
    Instance.new("UICorner", AuthBtn).CornerRadius = UDim.new(0, 8)

    TweenService:Create(MainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0}):Play()
    TweenService:Create(UIStroke, TweenInfo.new(0.7), {Transparency = 0}):Play()
    task.wait(0.2)
    TweenService:Create(Title, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(SubTitle, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(InputFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    TweenService:Create(KeyInput, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(AuthBtn, TweenInfo.new(0.5), {BackgroundTransparency = 0, TextTransparency = 0}):Play()

    AuthBtn.MouseButton1Click:Connect(function()
        if KeyInput.Text == Itoshi.Auth.Key then
            AuthBtn.Text = "KEY ACCEPTED"
            AuthBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            task.wait(0.6)
            
            TweenService:Create(MainFrame, TweenInfo.new(0.4), {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}):Play()
            TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play()
            
            for _, v in pairs(MainFrame:GetDescendants()) do
                if v:IsA("GuiObject") then
                    TweenService:Create(v, TweenInfo.new(0.2), {Transparency = 1}):Play()
                end
            end
            
            task.wait(0.5)
            ScreenGui:Destroy()
            Blur:Destroy()
            getgenv().ItoshiV7Auth = true
        else
            AuthBtn.Text = "INVALID KEY"
            AuthBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            local pos = InputFrame.Position
            for i=1,6 do
                InputFrame.Position = pos + UDim2.new(0, math.random(-4,4), 0, 0)
                task.wait(0.04)
            end
            InputFrame.Position = pos
            task.wait(1)
            AuthBtn.Text = "VERIFY ACCESS"
            AuthBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
        end
    end)
    
    repeat task.wait(0.2) until getgenv().ItoshiV7Auth
end

InitializeSecurity()

-- // 4. UTILITY MODULE //
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

function Utils.SecureCall(func, ...)
    local s, e = pcall(func, ...)
    if not s then warn(tostring(e)) end
end

-- // 5. GENERATOR SYSTEM (HOOK) //
local OldNameCall
OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if not checkcaller() and method == "InvokeServer" and self.Name == "RF" then
        if args[1] == "enter" then
            Itoshi.State.InteractingWithGen = true
            Itoshi.State.CurrentGenTarget = self.Parent.Parent
            
            if Itoshi.Config.Generator.Enabled then
                task.spawn(function()
                    while Itoshi.State.InteractingWithGen and Itoshi.Config.Generator.Enabled do
                        local Gen = Itoshi.State.CurrentGenTarget
                        local Progress = Gen and Gen:FindFirstChild("Progress")
                        
                        if Progress and Progress.Value >= 100 then
                            break
                        end

                        if Itoshi.Config.Generator.Mode == "Instant" then
                            self:InvokeServer(true)
                            self:InvokeServer(100)
                            task.wait(0.005)
                        else
                            local RE = self.Parent:FindFirstChild("RE")
                            if RE then RE:FireServer() end
                            task.wait(0.15)
                        end
                    end
                end)
            end
            
        elseif args[1] == "leave" then
            Itoshi.State.InteractingWithGen = false
            Itoshi.State.CurrentGenTarget = nil
        end
    end
    
    return OldNameCall(self, ...)
end)

-- // 6. HYBRID COMBAT ENGINE (AUDIO + ANIMATION) //
local function GetKillerDelay(model)
    if not model then return Itoshi.Config.Combat.Delays["default"] end
    local name = model.Name:lower()
    for killer, delay in pairs(Itoshi.Config.Combat.Delays) do
        if string.find(name, killer) then return delay end
    end
    return Itoshi.Config.Combat.Delays["default"]
end

local function CalculatePingComp()
    if not Itoshi.Config.Combat.Prediction then return 0 end
    return (Utils.GetPing() / 1000) * 0.5
end

local function TriggerBlock(killerModel)
    if tick() - Itoshi.State.LastBlock < 0.2 then return end
    Itoshi.State.LastBlock = tick()
    
    local BaseDelay = GetKillerDelay(killerModel)
    local PingComp = CalculatePingComp()
    local FinalDelay = math.max(0, BaseDelay - PingComp)
    
    task.delay(FinalDelay, function()
        local Args = {"UseActorAbility", "Block"}
        ReplicatedStorage.Modules.Network.RemoteEvent:FireServer(unpack(Args))
        
        if Itoshi.Config.Combat.DoubleTap then
            task.delay(0.12, function()
                local PunchArgs = {"UseActorAbility", "Punch"}
                ReplicatedStorage.Modules.Network.RemoteEvent:FireServer(unpack(PunchArgs))
            end)
        end
    end)
end

local function ProcessAudio(sound)
    if not Itoshi.Config.Combat.Enabled or not Itoshi.Config.Combat.AudioBlock then return end
    
    local id = string.match(sound.SoundId, "%d+")
    if not id then return end
    
    if Itoshi.Database.Sounds[id] or (sound.Volume > 0.8 and sound.PlaybackSpeed >= 0.9) then
        if Itoshi.State.CachedSounds[sound] and (tick() - Itoshi.State.CachedSounds[sound]) < 1 then return end
        
        local SoundPos = sound.Parent and sound.Parent.Position
        local MyRoot = Utils.GetRoot(LocalPlayer.Character)
        
        if SoundPos and MyRoot then
            local Dist = (SoundPos - MyRoot.Position).Magnitude
            if Dist <= Itoshi.Config.Combat.Range then
                Itoshi.State.CachedSounds[sound] = tick()
                local KillerModel = sound.Parent:FindFirstAncestorOfClass("Model")
                TriggerBlock(KillerModel)
            end
        end
    end
end

local function CheckAnimations()
    if not Itoshi.Config.Combat.Enabled or not Itoshi.Config.Combat.AnimBlock then return end
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Root = Utils.GetRoot(Player.Character)
            local MyRoot = Utils.GetRoot(LocalPlayer.Character)
            
            if Root and MyRoot and (Root.Position - MyRoot.Position).Magnitude <= Itoshi.Config.Combat.Range then
                local Hum = Utils.GetHum(Player.Character)
                local Animator = Hum and Hum:FindFirstChild("Animator")
                
                if Animator then
                    for _, Track in pairs(Animator:GetPlayingAnimationTracks()) do
                        local id = string.match(Track.Animation.AnimationId, "%d+")
                        for _, dbId in pairs(Itoshi.Database.Animations) do
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

-- // 7. MOVEMENT & PHYSICS //
local function UpdatePhysics()
    local Char = LocalPlayer.Character
    if not Char then return end
    
    if Itoshi.Config.Movement.InfiniteStamina then
        local Stamina = LocalPlayer:FindFirstChild("Stamina")
        if Stamina and Stamina:IsA("NumberValue") then Stamina.Value = 100 end
    end
    
    if Itoshi.Config.Movement.AntiStun then
        local Hum = Utils.GetHum(Char)
        if Hum then
            if Hum.WalkSpeed < 12 and Hum.WalkSpeed > 0 then Hum.WalkSpeed = 16 end
            if Hum.PlatformStand then Hum.PlatformStand = false end
        end
        if Char:FindFirstChild("Slowness") then Char.Slowness:Destroy() end
    end
    
    if Itoshi.Config.Movement.SpeedEnabled then
        local Root = Utils.GetRoot(Char)
        local Hum = Utils.GetHum(Char)
        if Root and Hum and Hum.MoveDirection.Magnitude > 0 then
            Root.CFrame = Root.CFrame + (Hum.MoveDirection * Itoshi.Config.Movement.SpeedFactor)
        end
    end
end

local function UpdateHitboxes()
    if not Itoshi.Config.Visuals.HitboxExpand then return end
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Root = Utils.GetRoot(Player.Character)
            if Root then
                Root.Size = Vector3.new(Itoshi.Config.Visuals.HitboxSize, Itoshi.Config.Visuals.HitboxSize, Itoshi.Config.Visuals.HitboxSize)
                Root.Transparency = 0.6
                Root.CanCollide = false
                Root.Material = Enum.Material.ForceField
                Root.Color = Itoshi.Config.Visuals.HitboxColor
            end
        end
    end
end

-- // 8. VISUALS (ESP) //
local ESP_Storage = {}
local function UpdateESP()
    if not Itoshi.Config.Visuals.ESP then 
        for i, v in pairs(ESP_Storage) do v:Destroy() end
        table.clear(ESP_Storage)
        return 
    end

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Utils.GetRoot(Player.Character) then
            if not ESP_Storage[Player] then
                local HL = Instance.new("Highlight")
                HL.Parent = CoreGui
                HL.Adornee = Player.Character
                HL.FillColor = Color3.fromRGB(255, 0, 0)
                HL.FillTransparency = 0.5
                HL.OutlineColor = Color3.fromRGB(255, 255, 255)
                ESP_Storage[Player] = HL
            end
        else
            if ESP_Storage[Player] then 
                ESP_Storage[Player]:Destroy()
                ESP_Storage[Player] = nil
            end
        end
    end
end

-- // 9. RAYFIELD UI //
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub V7 | God Emperor",
    LoadingTitle = "Initializing Database...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiV7", FileName = "Config"},
    KeySystem = false, 
})

local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabGen = Window:CreateTab("Generator", 4483362458)
local TabMove = Window:CreateTab("Movement", 4483362458)
local TabVis = Window:CreateTab("Visuals", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)

-- Combat
TabCombat:CreateToggle({Name = "Audio Auto Block", CurrentValue = true, Callback = function(v) Itoshi.Config.Combat.AudioBlock = v end})
TabCombat:CreateToggle({Name = "Animation Auto Block", CurrentValue = true, Callback = function(v) Itoshi.Config.Combat.AnimBlock = v end})
TabCombat:CreateToggle({Name = "Ping Prediction", CurrentValue = true, Callback = function(v) Itoshi.Config.Combat.Prediction = v end})
TabCombat:CreateToggle({Name = "Double Tap (Counter)", CurrentValue = true, Callback = function(v) Itoshi.Config.Combat.DoubleTap = v end})
TabCombat:CreateSlider({Name = "Detection Range", Range = {10, 60}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Config.Combat.Range = v end})
TabCombat:CreateToggle({Name = "Hitbox Expander", CurrentValue = true, Callback = function(v) Itoshi.Config.Visuals.HitboxExpand = v end})
TabCombat:CreateSlider({Name = "Hitbox Size", Range = {5, 30}, Increment = 1, CurrentValue = 22, Callback = function(v) Itoshi.Config.Visuals.HitboxSize = v end})

-- Generator
TabGen:CreateToggle({Name = "Auto Fix (Hook)", CurrentValue = true, Callback = function(v) Itoshi.Config.Generator.Enabled = v end})
TabGen:CreateDropdown({Name = "Operation Mode", Options = {"Instant", "Legit"}, CurrentOption = "Instant", Callback = function(v) Itoshi.Config.Generator.Mode = v end})

-- Movement
TabMove:CreateToggle({Name = "CFrame Speed", CurrentValue = false, Callback = function(v) Itoshi.Config.Movement.SpeedEnabled = v end})
TabMove:CreateSlider({Name = "Speed Factor", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 1.0, Callback = function(v) Itoshi.Config.Movement.SpeedFactor = v end})
TabMove:CreateToggle({Name = "Anti Stun/Slow", CurrentValue = true, Callback = function(v) Itoshi.Config.Movement.AntiStun = v end})

-- Visuals
TabVis:CreateToggle({Name = "Player ESP", CurrentValue = true, Callback = function(v) Itoshi.Config.Visuals.ESP = v end})
TabVis:CreateToggle({Name = "Fullbright", CurrentValue = true, Callback = function(v) 
    Itoshi.Config.Visuals.Fullbright = v
    if v then Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.GlobalShadows = false end
end})

-- Misc
TabMisc:CreateButton({Name = "Rejoin Server", Callback = function() Services.TeleportService:Teleport(game.PlaceId, LocalPlayer) end})
TabMisc:CreateButton({Name = "Unload Script", Callback = function() Rayfield:Destroy() end})

-- // 10. MAIN LOOPS //
Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Sound") then
        desc.Played:Connect(function() ProcessAudio(desc) end)
    end
end)

for _, v in pairs(Workspace:GetDescendants()) do
    if v:IsA("Sound") then
        v.Played:Connect(function() ProcessAudio(v) end)
    end
end

RunService.RenderStepped:Connect(function()
    Utils.SecureCall(UpdatePhysics)
    if Itoshi.Config.Visuals.Fullbright then Lighting.ClockTime = 14 end
end)

task.spawn(function()
    while true do
        task.wait(1)
        Utils.SecureCall(UpdateHitboxes)
        Utils.SecureCall(UpdateESP)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        Utils.SecureCall(CheckAnimations)
    end
end)

Rayfield:LoadConfiguration()
