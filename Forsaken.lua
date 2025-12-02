-- // ITOSHI HUB V14: ULTIMATE ARCHITECTURE //
-- SYSTEM: ROBLOX LUA OPTIMIZED
-- BUILD: RELEASE CANDIDATE

local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    Lighting = game:GetService("Lighting"),
    Stats = game:GetService("Stats"),
    TweenService = game:GetService("TweenService"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // CONFIGURATION //
local Itoshi = {
    Auth = {
        Key = "FFDGDLFYUFOHDWHHFXX",
        Discord = "https://discord.gg/AUxUj6T2yE",
        Passed = false
    },
    Settings = {
        Combat = {
            Enabled = false,
            AutoBlock_Audio = false,
            AutoBlock_Anim = false,
            Prediction = false,
            PredictionAmount = 0.15,
            Range = 25,
            DoubleTap = false,
            TeleportBehind = false, -- New: Teleport behind killer when they attack
            FaceEnemy = false
        },
        Generator = {
            Enabled = false,
            Mode = "Hybrid", -- Hybrid, Instant, Legit
            FixSpeed = 0.03,
            AutoLeave = false,
            TeleportToGen = false -- New: TP to nearest gen
        },
        Movement = {
            SpeedEnabled = false,
            SpeedFactor = 0.8,
            PulseMove = false,
            AntiStun = false,
            InfiniteStamina = false,
            AutoWiggle = false, -- New: Auto spam A/D when grabbed
            BunnyHop = false
        },
        Visuals = {
            Enabled = false,
            Box = false,
            Name = false,
            Distance = false,
            Health = false,
            Tracers = false,
            Fullbright = false,
            HitboxExpand = false,
            HitboxSize = 22,
            HitboxColor = Color3.fromRGB(255, 0, 0),
            Chams = false
        }
    },
    Cache = {
        Drawings = {},
        Sounds = {},
        Connections = {},
        LastBlock = 0,
        CurrentTarget = nil
    }
}

-- // DATABASE: KILLER SOUNDS (COMPLETE) //
local SoundDatabase = {
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

-- // DATABASE: KILLER ANIMATIONS (COMPLETE) //
local AnimDatabase = {
    "126830014841198", "126355327951215", "121086746534252", "18885909645", 
    "98456918873918", "105458270463374", "83829782357897", "125403313786645", 
    "118298475669935", "82113744478546", "70371667919898", "99135633258223", 
    "97167027849946", "109230267448394", "139835501033932", "126896426760253", 
    "109667959938617", "126681776859538", "129976080405072", "121293883585738", 
    "81639435858902", "137314737492715", "92173139187970", "122709416391", 
    "879895330952"
}

-- // DATABASE: KILLER DELAYS //
local DelayDatabase = {
    ["c00lkidd"] = 0, ["jason"] = 0.013, ["slasher"] = 0.01,
    ["1x1x1x1"] = 0.15, ["johndoe"] = 0.33, ["noli"] = 0.15,
    ["nosferatu"] = 0.02, ["guest 666"] = 0.15, ["default"] = 0.1
}

-- // UTILITY SYSTEM //
local Utils = {}

function Utils.GetRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function Utils.GetHum(char)
    if not char then return nil end
    return char:FindFirstChild("Humanoid")
end

function Utils.GetPing()
    local PingVal = Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    return PingVal / 1000
end

function Utils.IsVisible(part)
    if not part then return false end
    local Origin = Camera.CFrame.Position
    local Direction = (part.Position - Origin).Unit * (part.Position - Origin).Magnitude
    local Raycast = Services.Workspace:Raycast(Origin, Direction)
    if Raycast and Raycast.Instance:IsDescendantOf(part.Parent) then
        return true
    end
    return false
end

function Utils.Notify(title, text, duration)
    Services.CoreGui:FindFirstChild("RobloxGui"):FindFirstChild("NotificationFrame"):Fire({
        Title = title,
        Text = text,
        Duration = duration
    })
end

-- // AUTHENTICATION SYSTEM (UI) //
local function InitializeAuth()
    if getgenv().ItoshiV14Auth then return end
    
    local GUI = Instance.new("ScreenGui")
    GUI.Name = "ItoshiSecurityV14"
    GUI.Parent = Services.CoreGui
    GUI.IgnoreGuiInset = true
    
    local Blur = Instance.new("BlurEffect", Services.Lighting)
    Blur.Size = 0
    Services.TweenService:Create(Blur, TweenInfo.new(1), {Size = 20}):Play()
    
    local Frame = Instance.new("Frame", GUI)
    Frame.Size = UDim2.new(0, 400, 0, 250)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    
    local Stroke = Instance.new("UIStroke", Frame)
    Stroke.Color = Color3.fromRGB(200, 0, 0)
    Stroke.Thickness = 2
    
    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.BackgroundTransparency = 1
    Title.Text = "ITOSHI HUB V14"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 24
    
    local Input = Instance.new("TextBox", Frame)
    Input.Size = UDim2.new(0.8, 0, 0, 40)
    Input.Position = UDim2.new(0.1, 0, 0.35, 0)
    Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.PlaceholderText = "Paste Key..."
    Input.Text = ""
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 6)
    
    local DiscordBtn = Instance.new("TextButton", Frame)
    DiscordBtn.Size = UDim2.new(0.8, 0, 0, 30)
    DiscordBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    DiscordBtn.Text = "COPY DISCORD LINK"
    DiscordBtn.TextColor3 = Color3.fromRGB(100, 100, 255)
    Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 6)
    
    local LoginBtn = Instance.new("TextButton", Frame)
    LoginBtn.Size = UDim2.new(0.8, 0, 0, 40)
    LoginBtn.Position = UDim2.new(0.1, 0, 0.75, 0)
    LoginBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    LoginBtn.Text = "LOGIN"
    LoginBtn.Font = Enum.Font.GothamBold
    LoginBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", LoginBtn).CornerRadius = UDim.new(0, 6)
    
    DiscordBtn.MouseButton1Click:Connect(function()
        setclipboard(Itoshi.Auth.Discord)
        DiscordBtn.Text = "LINK COPIED!"
        task.wait(1)
        DiscordBtn.Text = "COPY DISCORD LINK"
    end)
    
    LoginBtn.MouseButton1Click:Connect(function()
        if Input.Text == Itoshi.Auth.Key then
            LoginBtn.Text = "SUCCESS"
            LoginBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            task.wait(0.5)
            GUI:Destroy()
            Blur:Destroy()
            getgenv().ItoshiV14Auth = true
        else
            LoginBtn.Text = "INVALID KEY"
            LoginBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            task.wait(1)
            LoginBtn.Text = "LOGIN"
            LoginBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        end
    end)
    
    repeat task.wait(0.1) until getgenv().ItoshiV14Auth
end

InitializeAuth()

-- // VISUALS ENGINE (DRAWING API) //
local ESP = {}

function ESP.Create(Model)
    if Itoshi.Cache.Drawings[Model] then return end
    
    local Objects = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthOutline = Drawing.new("Square"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    
    Objects.Box.Visible = false
    Objects.Box.Thickness = 1.5
    Objects.Box.Color = Color3.fromRGB(255, 50, 50)
    Objects.Box.Filled = false
    
    Objects.Name.Visible = false
    Objects.Name.Center = true
    Objects.Name.Color = Color3.fromRGB(255, 255, 255)
    Objects.Name.Size = 14
    Objects.Name.Outline = true
    
    Objects.Distance.Visible = false
    Objects.Distance.Center = true
    Objects.Distance.Color = Color3.fromRGB(200, 200, 200)
    Objects.Distance.Size = 12
    Objects.Distance.Outline = true
    
    Objects.Tracer.Visible = false
    Objects.Tracer.Thickness = 1
    Objects.Tracer.Color = Color3.fromRGB(255, 255, 255)
    
    Itoshi.Cache.Drawings[Model] = Objects
end

function ESP.Remove(Model)
    if Itoshi.Cache.Drawings[Model] then
        for _, DrawingObj in pairs(Itoshi.Cache.Drawings[Model]) do
            DrawingObj:Remove()
        end
        Itoshi.Cache.Drawings[Model] = nil
    end
end

function ESP.Update()
    for Model, Objs in pairs(Itoshi.Cache.Drawings) do
        if not Itoshi.Settings.Visuals.Enabled then
            for _, v in pairs(Objs) do v.Visible = false end
            continue
        end
        
        if Model.Parent and Utils.GetRoot(Model) and Utils.GetHum(Model) and Utils.GetHum(Model).Health > 0 then
            local Root = Utils.GetRoot(Model)
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - Root.Position).Magnitude
            
            if OnScreen then
                local Size = 2500 / ScreenPos.Z
                local Width = Size * 0.6
                
                -- Box
                if Itoshi.Settings.Visuals.Box then
                    Objs.Box.Size = Vector2.new(Width, Size)
                    Objs.Box.Position = Vector2.new(ScreenPos.X - Width/2, ScreenPos.Y - Size/2)
                    Objs.Box.Visible = true
                else
                    Objs.Box.Visible = false
                end
                
                -- Name
                if Itoshi.Settings.Visuals.Name then
                    Objs.Name.Text = Model.Name
                    Objs.Name.Position = Vector2.new(ScreenPos.X, ScreenPos.Y - Size/2 - 15)
                    Objs.Name.Visible = true
                else
                    Objs.Name.Visible = false
                end
                
                -- Distance
                if Itoshi.Settings.Visuals.Distance then
                    Objs.Distance.Text = "[" .. math.floor(Distance) .. "m]"
                    Objs.Distance.Position = Vector2.new(ScreenPos.X, ScreenPos.Y + Size/2 + 5)
                    Objs.Distance.Visible = true
                else
                    Objs.Distance.Visible = false
                end
                
                -- Tracer
                if Itoshi.Settings.Visuals.Tracers then
                    Objs.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    Objs.Tracer.To = Vector2.new(ScreenPos.X, ScreenPos.Y + Size/2)
                    Objs.Tracer.Visible = true
                else
                    Objs.Tracer.Visible = false
                end
            else
                for _, v in pairs(Objs) do v.Visible = false end
            end
        else
            ESP.Remove(Model)
        end
    end
end

-- // GENERATOR AI (SMART HOOK) //
local function InitializeGeneratorAI()
    local OldNC
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if not checkcaller() and method == "InvokeServer" and self.Name == "RF" then
            if args[1] == "enter" then
                -- Detection
                if Itoshi.Settings.Generator.Enabled then
                    local Gen = self.Parent.Parent
                    local RE = Gen:FindFirstChild("Remotes") and Gen.Remotes:FindFirstChild("RE")
                    local Progress = Gen:FindFirstChild("Progress")
                    
                    if RE and Progress then
                        task.spawn(function()
                            while Itoshi.Settings.Generator.Enabled and Progress.Value < 100 do
                                RE:FireServer()
                                
                                -- Smart Speed
                                local Speed = Itoshi.Settings.Generator.FixSpeed
                                if Itoshi.Settings.Generator.Mode == "Hybrid" and Progress.Value > 85 then
                                    Speed = 0.15 -- Slow down to look legit
                                elseif Itoshi.Settings.Generator.Mode == "Instant" then
                                    Speed = 0.005 -- God mode speed
                                end
                                
                                task.wait(Speed)
                                
                                if Progress.Value >= 100 and Itoshi.Settings.Generator.AutoLeave then
                                    self:InvokeServer("leave")
                                    break
                                end
                            end
                        end)
                    end
                end
            end
        end
        
        return OldNC(self, ...)
    end)
end

-- // COMBAT ENGINE //
local Combat = {}

function Combat.GetKillerDelay(model)
    if not model then return Itoshi.Settings.Combat.Delays["default"] end
    local name = model.Name:lower()
    for k, v in pairs(Itoshi.Settings.Combat.Delays) do
        if name:find(k) then return v end
    end
    return 0.1
end

function Combat.ExecuteBlock(Killer)
    if tick() - Itoshi.Cache.LastBlock < 0.2 then return end
    Itoshi.Cache.LastBlock = tick()
    
    local Delay = Combat.GetKillerDelay(Killer)
    local PingComp = Itoshi.Settings.Combat.Prediction and Utils.GetPing() * 0.5 or 0
    local FinalDelay = math.max(0, Delay - PingComp)
    
    task.delay(FinalDelay, function()
        -- Block
        Services.ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Block")
        
        -- Counter Attack
        if Itoshi.Settings.Combat.DoubleTap then
            task.delay(0.12, function()
                Services.ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Punch")
            end)
        end
        
        -- Teleport Behind (OP Feature)
        if Itoshi.Settings.Combat.TeleportBehind and Killer then
            local KillerRoot = Utils.GetRoot(Killer)
            local MyRoot = Utils.GetRoot(LocalPlayer.Character)
            if KillerRoot and MyRoot then
                local BehindPos = KillerRoot.CFrame * CFrame.new(0, 0, 4)
                MyRoot.CFrame = CFrame.new(BehindPos.Position, KillerRoot.Position)
            end
        end
    end)
end

function Combat.ProcessAudio(sound)
    if not Itoshi.Settings.Combat.Enabled or not Itoshi.Settings.Combat.AutoBlock_Audio then return end
    
    local id = string.match(sound.SoundId, "%d+")
    if not id then return end
    
    if SoundDatabase[id] or (sound.Volume > 0.8 and sound.PlaybackSpeed >= 0.9) then
        if Itoshi.Cache.CachedSounds[sound] and (tick() - Itoshi.Cache.CachedSounds[sound]) < 1 then return end
        
        local SoundPos = sound.Parent and sound.Parent.Position
        local MyRoot = Utils.GetRoot(LocalPlayer.Character)
        
        if SoundPos and MyRoot then
            if (SoundPos - MyRoot.Position).Magnitude <= Itoshi.Settings.Combat.Range then
                Itoshi.Cache.CachedSounds[sound] = tick()
                local Killer = sound.Parent:FindFirstAncestorOfClass("Model")
                Combat.ExecuteBlock(Killer)
            end
        end
    end
end

function Combat.ProcessAnim()
    if not Itoshi.Settings.Combat.Enabled or not Itoshi.Settings.Combat.AutoBlock_Anim then return end
    
    for _, Player in pairs(Services.Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Root = Utils.GetRoot(Player.Character)
            local MyRoot = Utils.GetRoot(LocalPlayer.Character)
            
            if Root and MyRoot and (Root.Position - MyRoot.Position).Magnitude <= Itoshi.Settings.Combat.Range then
                local Hum = Utils.GetHum(Player.Character)
                local Anim = Hum and Hum:FindFirstChild("Animator")
                
                if Anim then
                    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
                        local id = string.match(Track.Animation.AnimationId, "%d+")
                        for _, dbID in pairs(AnimDatabase) do
                            if id == dbID then
                                Combat.ExecuteBlock(Player.Character)
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- // MOVEMENT ENGINE //
local function UpdateMovement()
    local Char = LocalPlayer.Character
    if not Char then return end
    local Root = Utils.GetRoot(Char)
    local Hum = Utils.GetHum(Char)
    
    if not Root or not Hum then return end
    
    -- Speed
    if Itoshi.Settings.Movement.SpeedEnabled and Hum.MoveDirection.Magnitude > 0 then
        if Itoshi.Settings.Movement.PulseMove then
            Root.AssemblyLinearVelocity = Root.AssemblyLinearVelocity + (Hum.MoveDirection * Itoshi.Settings.Movement.SpeedFactor * 5)
        else
            Root.CFrame = Root.CFrame + (Hum.MoveDirection * Itoshi.Settings.Movement.SpeedFactor)
        end
    end
    
    -- Anti Stun
    if Itoshi.Settings.Movement.AntiStun then
        if Hum.WalkSpeed < 10 then Hum.WalkSpeed = 16 end
        if Char:FindFirstChild("Slowness") then Char.Slowness:Destroy() end
        if Hum.PlatformStand then Hum.PlatformStand = false end
    end
    
    -- Infinite Stamina
    if Itoshi.Settings.Movement.InfiniteStamina then
        Char:SetAttribute("Stamina", 100)
    end
    
    -- Auto Wiggle
    if Itoshi.Settings.Movement.AutoWiggle and Char:FindFirstChild("Grabbed") then
        Services.VirtualInputManager:SendKeyEvent(true, "A", false, game)
        Services.VirtualInputManager:SendKeyEvent(true, "D", false, game)
    end
end

-- // MAIN LOOPS //
InitializeGeneratorAI()

Services.Workspace.DescendantAdded:Connect(function(v)
    if v:IsA("Sound") then v.Played:Connect(function() pcall(Combat.ProcessAudio, v) end) end
end)

for _, v in pairs(Services.Workspace:GetDescendants()) do
    if v:IsA("Sound") then v.Played:Connect(function() pcall(Combat.ProcessAudio, v) end) end
end

Services.RunService.RenderStepped:Connect(function()
    pcall(ESP.Update)
    pcall(UpdateMovement)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Services.Lighting.ClockTime = 14
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        -- Update Player List for ESP & Hitboxes
        for _, P in pairs(Services.Players:GetPlayers()) do
            if P ~= LocalPlayer and P.Character then
                ESP.Create(P.Character)
                
                if Itoshi.Settings.Visuals.HitboxExpand and Utils.GetRoot(P.Character) then
                    local R = Utils.GetRoot(P.Character)
                    R.Size = Vector3.new(Itoshi.Settings.Visuals.HitboxSize, Itoshi.Settings.Visuals.HitboxSize, Itoshi.Settings.Visuals.HitboxSize)
                    R.Transparency = 0.7
                    R.CanCollide = false
                    R.Color = Itoshi.Settings.Visuals.HitboxColor
                    R.Material = Enum.Material.ForceField
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(Combat.ProcessAnim)
    end
end)

-- // UI INTERFACE (RAYFIELD) //
local Library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Library:CreateWindow({
    Name = "Itoshi Hub V14 | ULTIMATE",
    LoadingTitle = "Initializing...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiV14", FileName = "Config"},
    KeySystem = false -- Custom one used
})

local TabGen = Window:CreateTab("Generator", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabMove = Window:CreateTab("Movement", 4483362458)
local TabVis = Window:CreateTab("Visuals", 4483362458)

-- Generator
TabGen:CreateToggle({Name = "Auto Generator", CurrentValue = false, Callback = function(v) Itoshi.Settings.Generator.Enabled = v end})
TabGen:CreateDropdown({Name = "Mode", Options = {"Hybrid", "Instant", "Legit"}, CurrentOption = "Hybrid", Callback = function(v) Itoshi.Settings.Generator.Mode = v end})
TabGen:CreateSlider({Name = "Speed", Range = {0, 0.2}, Increment = 0.01, CurrentValue = 0.03, Callback = function(v) Itoshi.Settings.Generator.FixSpeed = v end})
TabGen:CreateToggle({Name = "Auto Leave", CurrentValue = false, Callback = function(v) Itoshi.Settings.Generator.AutoLeave = v end})

-- Combat
TabCombat:CreateToggle({Name = "Auto Block (Audio)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock_Audio = v end})
TabCombat:CreateToggle({Name = "Auto Block (Anim)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock_Anim = v end})
TabCombat:CreateToggle({Name = "Ping Prediction", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Prediction = v end})
TabCombat:CreateToggle({Name = "Counter Attack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.DoubleTap = v end})
TabCombat:CreateToggle({Name = "Teleport Behind (OP)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.TeleportBehind = v end})
TabCombat:CreateSlider({Name = "Range", Range = {10, 60}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.Range = v end})

-- Movement
TabMove:CreateToggle({Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.InfiniteStamina = v end})
TabMove:CreateToggle({Name = "Speed Boost", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.SpeedEnabled = v end})
TabMove:CreateSlider({Name = "Speed Factor", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.8, Callback = function(v) Itoshi.Settings.Movement.SpeedFactor = v end})
TabMove:CreateToggle({Name = "Anti Stun/Slow", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.AntiStun = v end})
TabMove:CreateToggle({Name = "Auto Wiggle", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.AutoWiggle = v end})

-- Visuals
TabVis:CreateToggle({Name = "ESP Enabled", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Enabled = v end})
TabVis:CreateToggle({Name = "Boxes", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Box = v end})
TabVis:CreateToggle({Name = "Names", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Name = v end})
TabVis:CreateToggle({Name = "Distance", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Distance = v end})
TabVis:CreateToggle({Name = "Tracers", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Tracers = v end})
TabVis:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})
TabVis:CreateToggle({Name = "Big Hitboxes", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.HitboxExpand = v end})

Rayfield:LoadConfiguration()
