local Services = setmetatable({}, {
    __index = function(self, key)
        return game:GetService(key)
    end
})

local Players = Services.Players
local Workspace = Services.Workspace
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // CONFIGURATION //
-- Default settings (All OFF for safety)
local Itoshi = {
    KeySystem = {
        Key = "FFDGDLFYUFOHDWHHFXX",
        DiscordLink = "https://discord.gg/AUxUj6T2yE"
    },
    Settings = {
        Combat = {
            Enabled = false,
            AutoBlock = false,
            Prediction = false,
            Range = 25,
            CounterAttack = false
        },
        Generator = {
            Enabled = false,
            Mode = "Hybrid", -- Hybrid, Instant, Legit
            Speed = 0.03,
            AutoLeave = false
        },
        Player = {
            Speed = false,
            SpeedAmount = 0.8,
            InfiniteStamina = false,
            NoSlow = false
        },
        Visuals = {
            Enabled = false,
            Boxes = false,
            Names = false,
            Fullbright = false,
            BigHitbox = false
        }
    },
    Data = {
        ESP_Cache = {},
        Sound_Cache = {},
        LastBlock = 0
    }
}

-- // DATABASE //
local AttackSounds = {
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

local AttackAnims = {
    "126830014841198", "126355327951215", "121086746534252", "18885909645", 
    "98456918873918", "105458270463374", "83829782357897", "125403313786645", 
    "118298475669935", "82113744478546", "70371667919898", "99135633258223", 
    "97167027849946", "109230267448394", "139835501033932", "126896426760253", 
    "109667959938617", "126681776859538", "129976080405072", "121293883585738", 
    "81639435858902", "137314737492715", "92173139187970", "122709416391", 
    "879895330952"
}

local KillerDelays = {
    ["c00lkidd"] = 0, ["jason"] = 0.013, ["slasher"] = 0.01,
    ["1x1x1x1"] = 0.15, ["johndoe"] = 0.33, ["noli"] = 0.15,
    ["nosferatu"] = 0.02, ["guest 666"] = 0.15, ["default"] = 0.1
}

-- // KEY SYSTEM //
local function StartKeySystem()
    if getgenv().ItoshiKeyPassed then return end
    
    local GUI = Instance.new("ScreenGui")
    GUI.Name = "ItoshiKeySystem"
    GUI.Parent = CoreGui
    GUI.IgnoreGuiInset = true

    local Blur = Instance.new("BlurEffect", Lighting)
    Blur.Size = 0
    Services.TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 15}):Play()

    local Frame = Instance.new("Frame", GUI)
    Frame.Size = UDim2.new(0, 350, 0, 200)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1
    Title.Text = "Itoshi Hub | Key System"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 20

    local Input = Instance.new("TextBox", Frame)
    Input.Size = UDim2.new(0.8, 0, 0, 35)
    Input.Position = UDim2.new(0.1, 0, 0.35, 0)
    Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.PlaceholderText = "Paste Key Here..."
    Input.Text = ""
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 6)

    local Submit = Instance.new("TextButton", Frame)
    Submit.Size = UDim2.new(0.8, 0, 0, 35)
    Submit.Position = UDim2.new(0.1, 0, 0.6, 0)
    Submit.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    Submit.Text = "Check Key"
    Submit.TextColor3 = Color3.fromRGB(255, 255, 255)
    Submit.Font = Enum.Font.SourceSansBold
    Submit.TextSize = 16
    Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 6)

    local Discord = Instance.new("TextButton", Frame)
    Discord.Size = UDim2.new(1, 0, 0, 20)
    Discord.Position = UDim2.new(0, 0, 0.85, 0)
    Discord.BackgroundTransparency = 1
    Discord.Text = "Get Key (Copy Discord Link)"
    Discord.TextColor3 = Color3.fromRGB(100, 100, 255)
    Discord.TextSize = 14

    Discord.MouseButton1Click:Connect(function()
        setclipboard(Itoshi.KeySystem.DiscordLink)
        Discord.Text = "Link Copied!"
        task.wait(1)
        Discord.Text = "Get Key (Copy Discord Link)"
    end)

    Submit.MouseButton1Click:Connect(function()
        if Input.Text == Itoshi.KeySystem.Key then
            Submit.Text = "Success!"
            Submit.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            task.wait(0.5)
            GUI:Destroy()
            Blur:Destroy()
            getgenv().ItoshiKeyPassed = true
        else
            Submit.Text = "Wrong Key"
            Submit.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            task.wait(1)
            Submit.Text = "Check Key"
            Submit.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        end
    end)

    repeat task.wait(0.2) until getgenv().ItoshiKeyPassed
end

StartKeySystem()

-- // UTILS //
local function GetRoot(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function GetHum(char) return char and char:FindFirstChild("Humanoid") end
local function SafeCall(func, ...) pcall(func, ...) end
local function GetPing() return Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end

-- // ESP (VISUALS) //
local ESP = {}
function ESP.Add(Model)
    if Itoshi.Data.ESP_Cache[Model] then return end
    local Obj = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Model = Model
    }
    Obj.Box.Visible = false
    Obj.Box.Color = Color3.fromRGB(255, 0, 0)
    Obj.Box.Thickness = 1
    Obj.Box.Filled = false
    
    Obj.Name.Visible = false
    Obj.Name.Color = Color3.new(1, 1, 1)
    Obj.Name.Size = 14
    Obj.Name.Center = true
    Obj.Name.Outline = true
    
    Itoshi.Data.ESP_Cache[Model] = Obj
end

function ESP.Clear(Model)
    if Itoshi.Data.ESP_Cache[Model] then
        Itoshi.Data.ESP_Cache[Model].Box:Remove()
        Itoshi.Data.ESP_Cache[Model].Name:Remove()
        Itoshi.Data.ESP_Cache[Model] = nil
    end
end

function ESP.MainLoop()
    if not Itoshi.Settings.Visuals.Enabled then 
        for _, v in pairs(Itoshi.Data.ESP_Cache) do v.Box.Visible = false v.Name.Visible = false end
        return 
    end
    for Model, Obj in pairs(Itoshi.Data.ESP_Cache) do
        if Model.Parent and GetRoot(Model) and GetHum(Model) and GetHum(Model).Health > 0 then
            local Pos, OnScreen = Camera:WorldToViewportPoint(GetRoot(Model).Position)
            if OnScreen then
                local H = 2500 / Pos.Z
                if Itoshi.Settings.Visuals.Boxes then
                    Obj.Box.Size = Vector2.new(H * 0.7, H)
                    Obj.Box.Position = Vector2.new(Pos.X - Obj.Box.Size.X / 2, Pos.Y - Obj.Box.Size.Y / 2)
                    Obj.Box.Visible = true
                else Obj.Box.Visible = false end
                
                if Itoshi.Settings.Visuals.Names then
                    Obj.Name.Text = Model.Name
                    Obj.Name.Position = Vector2.new(Pos.X, Pos.Y - (H / 2) - 15)
                    Obj.Name.Visible = true
                else Obj.Name.Visible = false end
            else
                Obj.Box.Visible = false
                Obj.Name.Visible = false
            end
        else
            ESP.Clear(Model)
        end
    end
end

-- // GENERATOR AUTO FIX //
local function SetupGeneratorHook()
    local OldNC
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if not checkcaller() and method == "InvokeServer" and self.Name == "RF" then
            if args[1] == "enter" then
                -- Player touched a generator
                if Itoshi.Settings.Generator.Enabled then
                    local Gen = self.Parent.Parent
                    local RE = Gen and Gen:FindFirstChild("Remotes") and Gen.Remotes:FindFirstChild("RE")
                    local Prog = Gen and Gen:FindFirstChild("Progress")
                    
                    if RE and Prog then
                        task.spawn(function()
                            while Itoshi.Settings.Generator.Enabled and Prog.Value < 100 do
                                RE:FireServer()
                                
                                -- Speed Logic
                                local speed = Itoshi.Settings.Generator.Speed
                                if Itoshi.Settings.Generator.Mode == "Hybrid" and Prog.Value > 90 then
                                    speed = 0.15 -- Slow down at end
                                elseif Itoshi.Settings.Generator.Mode == "Instant" then
                                    speed = 0.005 -- Max Speed
                                end
                                task.wait(speed)
                                
                                -- Stop if done
                                if Prog.Value >= 100 and Itoshi.Settings.Generator.AutoLeave then
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

-- // COMBAT SYSTEM //
local function GetDelay(model)
    if not model then return 0.1 end
    local name = model.Name:lower()
    for k, v in pairs(KillerDelays) do
        if name:find(k) then return v end
    end
    return 0.1
end

local function DoBlock(killer)
    if tick() - Itoshi.Data.LastBlock < 0.2 then return end
    Itoshi.Data.LastBlock = tick()
    
    local Base = GetDelay(killer)
    local Ping = Itoshi.Settings.Combat.Prediction and (GetPing() / 1000 * 0.5) or 0
    local WaitTime = math.max(0, Base - Ping)
    
    task.delay(WaitTime, function()
        ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Block")
        if Itoshi.Settings.Combat.CounterAttack then
            task.delay(0.12, function()
                ReplicatedStorage.Modules.Network.RemoteEvent:FireServer("UseActorAbility", "Punch")
            end)
        end
    end)
end

local function OnSound(sound)
    if not Itoshi.Settings.Combat.Enabled or not Itoshi.Settings.Combat.AutoBlock then return end
    
    local id = string.match(sound.SoundId, "%d+")
    if not id then return end
    
    if AttackSounds[id] or (sound.Volume > 0.8 and sound.PlaybackSpeed >= 0.9) then
        -- Debounce
        if Itoshi.Data.Sound_Cache[sound] and (tick() - Itoshi.Data.Sound_Cache[sound]) < 1 then return end
        
        local SPos = sound.Parent and sound.Parent.Position
        local MyPos = GetRoot(LocalPlayer.Character)
        
        if SPos and MyPos then
            if (SPos - MyPos.Position).Magnitude <= Itoshi.Settings.Combat.Range then
                Itoshi.Data.Sound_Cache[sound] = tick()
                local Killer = sound.Parent:FindFirstAncestorOfClass("Model")
                DoBlock(Killer)
            end
        end
    end
end

local function CheckAnims()
    if not Itoshi.Settings.Combat.Enabled or not Itoshi.Settings.Combat.AnimBlock then return end
    
    for _, P in pairs(Players:GetPlayers()) do
        if P ~= LocalPlayer and P.Character then
            local Root = GetRoot(P.Character)
            local MyRoot = GetRoot(LocalPlayer.Character)
            
            if Root and MyRoot and (Root.Position - MyRoot.Position).Magnitude <= Itoshi.Settings.Combat.Range then
                local Hum = GetHum(P.Character)
                local Anim = Hum and Hum:FindFirstChild("Animator")
                if Anim then
                    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
                        local id = string.match(Track.Animation.AnimationId, "%d+")
                        for _, dbId in pairs(AttackAnims) do
                            if id == dbId then
                                DoBlock(P.Character)
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- // LOOPS & HOOKS //
SetupGeneratorHook()

Workspace.DescendantAdded:Connect(function(v)
    if v:IsA("Sound") then v.Played:Connect(function() SafeCall(OnSound, v) end) end
end)

for _, v in pairs(Workspace:GetDescendants()) do
    if v:IsA("Sound") then v.Played:Connect(function() SafeCall(OnSound, v) end) end
end

RunService.RenderStepped:Connect(function()
    SafeCall(ESP.MainLoop)
    
    local Char = LocalPlayer.Character
    if Char and GetRoot(Char) and GetHum(Char) then
        local Hum = GetHum(Char)
        local Root = GetRoot(Char)
        
        -- Speed
        if Itoshi.Settings.Player.Speed and Hum.MoveDirection.Magnitude > 0 then
            if Itoshi.Settings.Movement.PulseMove then
                Root.AssemblyLinearVelocity = Root.AssemblyLinearVelocity + (Hum.MoveDirection * Itoshi.Settings.Player.SpeedAmount * 5)
            else
                Root.CFrame = Root.CFrame + (Hum.MoveDirection * Itoshi.Settings.Player.SpeedAmount)
            end
        end
        
        -- No Slow
        if Itoshi.Settings.Player.NoSlow then
            if Hum.WalkSpeed < 12 then Hum.WalkSpeed = 16 end
            if Char:FindFirstChild("Slowness") then Char.Slowness:Destroy() end
        end
        
        -- Stamina
        if Itoshi.Settings.Player.InfiniteStamina then
            Char:SetAttribute("Stamina", 100)
        end
    end
    
    if Itoshi.Settings.Visuals.Fullbright then Lighting.ClockTime = 14 end
end)

task.spawn(function()
    while true do
        task.wait(1)
        -- Update Hitboxes & ESP List
        if Itoshi.Settings.Visuals.BigHitbox then
            for _, P in pairs(Players:GetPlayers()) do
                if P ~= LocalPlayer and P.Character and GetRoot(P.Character) then
                    local R = GetRoot(P.Character)
                    R.Size = Vector3.new(20, 20, 20)
                    R.Transparency = 0.7
                    R.CanCollide = false
                    R.Color = Color3.fromRGB(255, 0, 0)
                    ESP.Add(P.Character)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        SafeCall(CheckAnims)
    end
end)

-- // RAYFIELD UI //
local Library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Library:CreateWindow({
    Name = "Itoshi Hub V13",
    LoadingTitle = "Loading...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiV13", FileName = "Config"},
    KeySystem = false -- We used our custom one above
})

local TabGen = Window:CreateTab("Generator", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabPlayer = Window:CreateTab("Player", 4483362458)
local TabVis = Window:CreateTab("Visuals", 4483362458)

-- Generator Tab
TabGen:CreateToggle({Name = "Auto Fix Generator", CurrentValue = false, Callback = function(v) Itoshi.Settings.Generator.Enabled = v end})
TabGen:CreateDropdown({Name = "Fix Mode", Options = {"Hybrid", "Instant", "Legit"}, CurrentOption = "Hybrid", Callback = function(v) Itoshi.Settings.Generator.Mode = v end})
TabGen:CreateToggle({Name = "Auto Leave When Done", CurrentValue = false, Callback = function(v) Itoshi.Settings.Generator.AutoLeave = v end})

-- Combat Tab
TabCombat:CreateToggle({Name = "Enable Combat", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Enabled = v end})
TabCombat:CreateToggle({Name = "Auto Block (Sound)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock = v end})
TabCombat:CreateToggle({Name = "Auto Block (Animation)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AnimBlock = v end})
TabCombat:CreateToggle({Name = "Counter Attack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.CounterAttack = v end})
TabCombat:CreateSlider({Name = "Range", Range = {10, 50}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.Range = v end})

-- Player Tab
TabPlayer:CreateToggle({Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) Itoshi.Settings.Player.InfiniteStamina = v end})
TabPlayer:CreateToggle({Name = "No Slow / Anti-Stun", CurrentValue = false, Callback = function(v) Itoshi.Settings.Player.NoSlow = v end})
TabPlayer:CreateToggle({Name = "Speed Boost", CurrentValue = false, Callback = function(v) Itoshi.Settings.Player.Speed = v end})
TabPlayer:CreateSlider({Name = "Speed Amount", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.8, Callback = function(v) Itoshi.Settings.Player.SpeedAmount = v end})

-- Visuals Tab
TabVis:CreateToggle({Name = "Enable ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Enabled = v end})
TabVis:CreateToggle({Name = "Show Boxes", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Boxes = v end})
TabVis:CreateToggle({Name = "Show Names", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Names = v end})
TabVis:CreateToggle({Name = "Big Hitboxes", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.BigHitbox = v end})
TabVis:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

Rayfield:LoadConfiguration()
