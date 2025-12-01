local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local hookmeta = hookmetamethod or function(...) end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local CoreGui = Services.CoreGui
local VirtualInputManager = Services.VirtualInputManager
local Lighting = Services.Lighting

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Itoshi = {
    Settings = {
        Killer = {
            Enabled = false,
            Absorption = {Enabled = false, Size = 25, Transparency = 0.7, Extend = true},
            Aimbot = {Enabled = false, Smoothness = 1, Magnet = false, MagnetSpeed = 0.5}
        },
        Combat = {
            SilentAim = {Enabled = false, FOV = 150, ShowFOV = false, Part = "HumanoidRootPart"},
            AutoBlock = {Enabled = false, Mode = "Animation", Range = 15, Reaction = 0, Duration = 0.5, AutoFace = true}
        },
        Movement = {
            Fly = {Enabled = false, Speed = 80, Vertical = 50},
            Speed = {Enabled = false, Val = 16},
            Jump = {Enabled = false, Val = 50},
            NoClip = {Enabled = false}
        },
        Visuals = {
            ESP = {Enabled = false},
            Fullbright = false
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        FlyKeys = {W=false, A=false, S=false, D=false, Up=false, Down=false},
        Target = nil
    },
    Cache = {
        ESP = {},
        FOV = nil
    },
    Keywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action"}
}

local function SecureCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local KeySystem = {}
function KeySystem.Run()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "ItoshiAuth"
    
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 300, 0, 150)
    F.Position = UDim2.new(0.5, -150, 0.5, -75)
    F.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    F.BorderSizePixel = 0
    F.Parent = S
    
    local Title = Instance.new("TextLabel")
    Title.Text = "ITOSHI HUB | KILLER"
    Title.Size = UDim2.new(1, 0, 0.2, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(200, 0, 0)
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 20
    Title.Parent = F
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.25, 0)
    B.Position = UDim2.new(0.1, 0, 0.3, 0)
    B.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    B.TextColor3 = Color3.fromRGB(255, 255, 255)
    B.Text = ""
    B.PlaceholderText = "Enter Key..."
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.2, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "ACCESS"
    Btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.GothamBold
    Btn.Parent = F
    
    local Valid = false
    Btn.MouseButton1Click:Connect(function()
        if B.Text == "FFDGDLFYUFOHDWHHFXX" then
            Valid = true
            getgenv().ItoshiAuth = true
            S:Destroy()
        else
            B.Text = "INVALID"
            task.wait(1)
            B.Text = ""
        end
    end)
    repeat task.wait(0.1) until Valid
end

KeySystem.Run()

local Logic = {}

function Logic.GetTargets()
    local T = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then table.insert(T, p.Character) end
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(v) then
            table.insert(T, v)
        end
    end
    return T
end

function Logic.GetClosestSurvivor()
    local C = nil
    local M = math.huge
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil end
    
    for _, Char in pairs(Logic.GetTargets()) do
        local Root = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChild("Humanoid")
        if Root and Hum and Hum.Health > 0 then
            local Dist = (MyRoot.Position - Root.Position).Magnitude
            if Dist < M then
                M = Dist
                C = Char
            end
        end
    end
    return C
end

function Logic.KillerUpdate()
    if not Itoshi.Settings.Killer.Enabled then return end
    
    local Target = Logic.GetClosestSurvivor()
    if not Target then return end
    
    local MyRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local TargetRoot = Target:FindFirstChild("HumanoidRootPart")
    
    if not MyRoot or not TargetRoot then return end
    
    -- Hitbox Absorption (Reach)
    if Itoshi.Settings.Killer.Absorption.Enabled then
        local Size = Itoshi.Settings.Killer.Absorption.Size
        TargetRoot.Size = Vector3.new(Size, Size, Size)
        TargetRoot.Transparency = Itoshi.Settings.Killer.Absorption.Transparency
        TargetRoot.CanCollide = false
        
        if Itoshi.Settings.Killer.Absorption.Extend then
            TargetRoot.CFrame = TargetRoot.CFrame:Lerp(MyRoot.CFrame, 0.5) 
        end
    end
    
    -- Predator Aimbot & Magnet
    if Itoshi.Settings.Killer.Aimbot.Enabled then
        local LookAt = CFrame.new(MyRoot.Position, Vector3.new(TargetRoot.Position.X, MyRoot.Position.Y, TargetRoot.Position.Z))
        MyRoot.CFrame = MyRoot.CFrame:Lerp(LookAt, Itoshi.Settings.Killer.Aimbot.Smoothness)
        
        if Itoshi.Settings.Killer.Aimbot.Magnet then
            local Dir = (TargetRoot.Position - MyRoot.Position).Unit
            MyRoot.CFrame = MyRoot.CFrame + (Dir * Itoshi.Settings.Killer.Aimbot.MagnetSpeed)
        end
    end
end

function Logic.CombatUpdate()
    -- Auto Block Logic
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if MyRoot then
            for _, Char in pairs(Logic.GetTargets()) do
                local KRoot = Char:FindFirstChild("HumanoidRootPart")
                local Anim = Char:FindFirstChild("Humanoid") and Char.Humanoid:FindFirstChild("Animator")
                
                if KRoot and Anim then
                    local Dist = (MyRoot.Position - KRoot.Position).Magnitude
                    local Attacking = false
                    
                    for _, T in pairs(Anim:GetPlayingAnimationTracks()) do
                        for _, K in pairs(Itoshi.Keywords) do
                            if string.find(T.Name:lower(), K) and (T.Priority == Enum.AnimationPriority.Action or T.Priority == Enum.AnimationPriority.Action2) then
                                Attacking = true
                                break
                            end
                        end
                    end
                    
                    if Attacking and Dist <= Itoshi.Settings.Combat.AutoBlock.Range and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.2) then
                        if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(KRoot.Position.X, MyRoot.Position.Y, KRoot.Position.Z))
                        end
                        task.wait(Itoshi.Settings.Combat.AutoBlock.Reaction)
                        Itoshi.State.Blocking = true
                        Itoshi.State.LastBlock = tick()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        task.delay(Itoshi.Settings.Combat.AutoBlock.Duration, function()
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                            Itoshi.State.Blocking = false
                        end)
                    end
                end
            end
        end
    end
end

function Logic.PhysicsUpdate()
    if Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if Hum and Root then
            Hum.PlatformStand = true
            Hum:ChangeState(Enum.HumanoidStateType.Physics)
            local Cam = Camera.CFrame
            local V = Vector3.zero
            local K = Itoshi.State.FlyKeys
            if K.W then V = V + Cam.LookVector end
            if K.S then V = V - Cam.LookVector end
            if K.A then V = V - Cam.RightVector end
            if K.D then V = V + Cam.RightVector end
            if V.Magnitude > 0 then V = V.Unit * Itoshi.Settings.Movement.Fly.Speed end
            local Y = 0
            if K.Up then Y = Itoshi.Settings.Movement.Fly.Vertical end
            if K.Down then Y = -Itoshi.Settings.Movement.Fly.Vertical end
            Root.AssemblyLinearVelocity = Vector3.new(V.X, Y, V.Z)
            Root.AssemblyAngularVelocity = Vector3.zero
        end
    end
    if Itoshi.Settings.Movement.Speed.Enabled and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then Hum.WalkSpeed = Itoshi.Settings.Movement.Speed.Val end
    end
end

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.W then Itoshi.State.FlyKeys.W = true end
    if i.KeyCode == Enum.KeyCode.A then Itoshi.State.FlyKeys.A = true end
    if i.KeyCode == Enum.KeyCode.S then Itoshi.State.FlyKeys.S = true end
    if i.KeyCode == Enum.KeyCode.D then Itoshi.State.FlyKeys.D = true end
    if i.KeyCode == Enum.KeyCode.Space then Itoshi.State.FlyKeys.Up = true end
    if i.KeyCode == Enum.KeyCode.LeftControl then Itoshi.State.FlyKeys.Down = true end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W then Itoshi.State.FlyKeys.W = false end
    if i.KeyCode == Enum.KeyCode.A then Itoshi.State.FlyKeys.A = false end
    if i.KeyCode == Enum.KeyCode.S then Itoshi.State.FlyKeys.S = false end
    if i.KeyCode == Enum.KeyCode.D then Itoshi.State.FlyKeys.D = false end
    if i.KeyCode == Enum.KeyCode.Space then Itoshi.State.FlyKeys.Up = false end
    if i.KeyCode == Enum.KeyCode.LeftControl then Itoshi.State.FlyKeys.Down = false end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub | Killer Absolute",
    LoadingTitle = "Core Injection...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiKiller", FileName = "Cfg"},
    KeySystem = false, 
})

local TabKiller = Window:CreateTab("Killer Mode", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabMove = Window:CreateTab("Movement", 4483362458)
local TabVis = Window:CreateTab("Visuals", 4483362458)

TabKiller:CreateSection("Killer Core")
TabKiller:CreateToggle({Name = "Enable Killer Mode", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Enabled = v end})

TabKiller:CreateSection("Hitbox Absorption")
TabKiller:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Absorption.Enabled = v end})
TabKiller:CreateToggle({Name = "Extend Reach (Pull Hitbox)", CurrentValue = true, Callback = function(v) Itoshi.Settings.Killer.Absorption.Extend = v end})
TabKiller:CreateSlider({Name = "Absorption Size", Range = {5, 100}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Killer.Absorption.Size = v end})

TabKiller:CreateSection("Predator Tracking")
TabKiller:CreateToggle({Name = "Predator Aimbot", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Aimbot.Enabled = v end})
TabKiller:CreateToggle({Name = "Survivor Magnet (Go to Nearest)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Aimbot.Magnet = v end})
TabKiller:CreateSlider({Name = "Magnet Speed", Range = {0.1, 2}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Itoshi.Settings.Killer.Aimbot.MagnetSpeed = v end})

TabCombat:CreateSection("Defense")
TabCombat:CreateToggle({Name = "Aegis Auto Block", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabCombat:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 15, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})

TabMove:CreateSection("Physics")
TabMove:CreateToggle({Name = "Velocity Fly", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Fly.Enabled = v 
    if not v and LocalPlayer.Character then LocalPlayer.Character.Humanoid.PlatformStand = false LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero end
end})
TabMove:CreateSlider({Name = "Fly Speed", Range = {20, 500}, Increment = 1, CurrentValue = 80, Callback = function(v) Itoshi.Settings.Movement.Fly.Speed = v end})
TabMove:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Speed.Enabled = v end})
TabMove:CreateSlider({Name = "WalkSpeed", Range = {16, 300}, Increment = 1, CurrentValue = 16, Callback = function(v) Itoshi.Settings.Movement.Speed.Val = v end})

TabVis:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabVis:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Visuals.Fullbright = v
    if v then Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.GlobalShadows=false Lighting.Ambient=Color3.new(1,1,1) end
end})

RunService.RenderStepped:Connect(function(dt)
    SecureCall(Logic.PhysicsUpdate, dt)
    SecureCall(Logic.KillerUpdate)
    SecureCall(Logic.CombatUpdate)
    
    if Itoshi.Settings.Visuals.ESP.Enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not Itoshi.Cache.ESP[p] then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Parent = p.Character
                Itoshi.Cache.ESP[p] = hl
            end
        end
    else
        for i, v in pairs(Itoshi.Cache.ESP) do v:Destroy() end
        Itoshi.Cache.ESP = {}
    end
end)

Rayfield:LoadConfiguration()
