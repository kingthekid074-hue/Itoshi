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

local Titanium = {
    Settings = {
        Combat = {
            SilentAim = {Enabled = false, FOV = 150, ShowFOV = false, Part = "HumanoidRootPart"},
            AutoBlock = {Enabled = false, Mode = "Animation", Range = 15, Reaction = 0, Duration = 0.5, AutoFace = true},
            Hitbox = {Enabled = false, Size = 15, Transparency = 0.5, Part = "HumanoidRootPart"}
        },
        Movement = {
            Fly = {Enabled = false, Speed = 80, Vertical = 50},
            Speed = {Enabled = false, Val = 16},
            Jump = {Enabled = false, Val = 50},
            NoClip = {Enabled = false}
        },
        Visuals = {
            ESP = {Enabled = false, Dist = 3000},
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
    if getgenv().TitaniumAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "TitaniumAuth"
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 300, 0, 150)
    F.Position = UDim2.new(0.5, -150, 0.5, -75)
    F.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.3, 0)
    B.Text = ""
    B.PlaceholderText = "Key: FFDGDLFYUFOHDWHHFXX"
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.2, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "INJECT CORE"
    Btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Parent = F
    
    local Valid = false
    Btn.MouseButton1Click:Connect(function()
        if B.Text == "FFDGDLFYUFOHDWHHFXX" then
            Valid = true
            getgenv().TitaniumAuth = true
            S:Destroy()
        end
    end)
    repeat task.wait(0.1) until Valid
end

KeySystem.Run()

local Combat = {}
function Combat.GetTargets()
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

function Combat.GetClosestToMouse()
    local C = nil
    local M = math.huge
    local Mouse = UserInputService:GetMouseLocation()
    for _, Char in pairs(Combat.GetTargets()) do
        local Part = Char:FindFirstChild(Titanium.Settings.Combat.SilentAim.Part)
        if Part then
            local Pos, Vis = Camera:WorldToViewportPoint(Part.Position)
            if Vis then
                local D = (Vector2.new(Pos.X, Pos.Y) - Mouse).Magnitude
                if D < M and D <= Titanium.Settings.Combat.SilentAim.FOV then
                    M = D
                    C = Part
                end
            end
        end
    end
    return C
end

function Combat.IsAttacking(Model)
    if not Model then return false end
    local Anim = Model:FindFirstChild("Humanoid") and Model.Humanoid:FindFirstChild("Animator")
    if not Anim then return false end
    for _, T in pairs(Anim:GetPlayingAnimationTracks()) do
        local N = T.Name:lower()
        if T.Priority == Enum.AnimationPriority.Action or T.Priority == Enum.AnimationPriority.Action2 or T.Priority == Enum.AnimationPriority.Movement then
            for _, K in pairs(Titanium.Keywords) do
                if string.find(N, K) then return true end
            end
        end
    end
    return false
end

function Combat.Update()
    if Titanium.Settings.Combat.SilentAim.Enabled then
        Titanium.State.Target = Combat.GetClosestToMouse()
        if Titanium.Settings.Combat.SilentAim.ShowFOV then
            if not Titanium.Cache.FOV then
                Titanium.Cache.FOV = Drawing.new("Circle")
                Titanium.Cache.FOV.Color = Color3.fromRGB(255, 0, 0)
                Titanium.Cache.FOV.Thickness = 1
                Titanium.Cache.FOV.NumSides = 60
                Titanium.Cache.FOV.Filled = false
            end
            Titanium.Cache.FOV.Visible = true
            Titanium.Cache.FOV.Radius = Titanium.Settings.Combat.SilentAim.FOV
            Titanium.Cache.FOV.Position = UserInputService:GetMouseLocation()
        elseif Titanium.Cache.FOV then
            Titanium.Cache.FOV.Visible = false
        end
    end

    if Titanium.Settings.Combat.Hitbox.Enabled then
        local S = Titanium.Settings.Combat.Hitbox.Size
        local V = Vector3.new(S, S, S)
        for _, Char in pairs(Combat.GetTargets()) do
            local P = Char:FindFirstChild(Titanium.Settings.Combat.Hitbox.Part)
            if P then
                P.Size = V
                P.Transparency = Titanium.Settings.Combat.Hitbox.Transparency
                P.CanCollide = false
            end
        end
    end

    if Titanium.Settings.Combat.AutoBlock.Enabled then
        local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if MyRoot then
            for _, Char in pairs(Combat.GetTargets()) do
                local KRoot = Char:FindFirstChild("HumanoidRootPart")
                if KRoot then
                    local D = (MyRoot.Position - KRoot.Position).Magnitude
                    local Block = false
                    if Titanium.Settings.Combat.AutoBlock.Mode == "Animation" then
                        if D <= Titanium.Settings.Combat.AutoBlock.Range and Combat.IsAttacking(Char) then Block = true end
                    else
                        if D <= Titanium.Settings.Combat.AutoBlock.Range then Block = true end
                    end
                    
                    if Block and not Titanium.State.Blocking and (tick() - Titanium.State.LastBlock > 0.2) then
                        if Titanium.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(KRoot.Position.X, MyRoot.Position.Y, KRoot.Position.Z))
                        end
                        task.wait(Titanium.Settings.Combat.AutoBlock.Reaction)
                        Titanium.State.Blocking = true
                        Titanium.State.LastBlock = tick()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        task.delay(Titanium.Settings.Combat.AutoBlock.Duration, function()
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                            Titanium.State.Blocking = false
                        end)
                        break
                    end
                end
            end
        end
    end
end

local Physics = {}
function Physics.Update(dt)
    if Titanium.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if Hum and Root then
            Hum.PlatformStand = true
            Hum:ChangeState(Enum.HumanoidStateType.Physics)
            local Cam = Camera.CFrame
            local V = Vector3.zero
            local K = Titanium.State.FlyKeys
            if K.W then V = V + Cam.LookVector end
            if K.S then V = V - Cam.LookVector end
            if K.A then V = V - Cam.RightVector end
            if K.D then V = V + Cam.RightVector end
            if V.Magnitude > 0 then V = V.Unit * Titanium.Settings.Movement.Fly.Speed end
            local Y = 0
            if K.Up then Y = Titanium.Settings.Movement.Fly.Vertical end
            if K.Down then Y = -Titanium.Settings.Movement.Fly.Vertical end
            Root.AssemblyLinearVelocity = Vector3.new(V.X, Y, V.Z)
            Root.AssemblyAngularVelocity = Vector3.zero
        end
    end
    if Titanium.Settings.Movement.Speed.Enabled and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then Hum.WalkSpeed = Titanium.Settings.Movement.Speed.Val end
    end
    if Titanium.Settings.Movement.NoClip.Enabled and LocalPlayer.Character then
         for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
         end
    end
end

local Hooks = {}
function Hooks.Init()
    local OldNC, OldIdx
    OldNC = hookmeta(game, "__namecall", newcclosure(function(self, ...)
        local A = {...}
        local M = getnamecallmethod()
        if Titanium.Settings.Combat.SilentAim.Enabled and Titanium.State.Target and (M == "FireServer" or M == "InvokeServer") then
            for i, v in pairs(A) do
                if typeof(v) == "Vector3" then A[i] = Titanium.State.Target.Position end
                if typeof(v) == "CFrame" then A[i] = CFrame.new(A[i].Position, Titanium.State.Target.Position) end
            end
            return OldNC(self, unpack(A))
        end
        return OldNC(self, ...)
    end))
    OldIdx = hookmeta(game, "__index", newcclosure(function(self, K)
        if Titanium.Settings.Combat.SilentAim.Enabled and Titanium.State.Target and (K == "Hit" or K == "Target") and self:IsA("Mouse") then
            return (K == "Hit" and Titanium.State.Target.CFrame or Titanium.State.Target)
        end
        return OldIdx(self, K)
    end))
end

Hooks.Init()

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.W then Titanium.State.FlyKeys.W = true end
    if i.KeyCode == Enum.KeyCode.A then Titanium.State.FlyKeys.A = true end
    if i.KeyCode == Enum.KeyCode.S then Titanium.State.FlyKeys.S = true end
    if i.KeyCode == Enum.KeyCode.D then Titanium.State.FlyKeys.D = true end
    if i.KeyCode == Enum.KeyCode.Space then Titanium.State.FlyKeys.Up = true end
    if i.KeyCode == Enum.KeyCode.LeftControl then Titanium.State.FlyKeys.Down = true end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W then Titanium.State.FlyKeys.W = false end
    if i.KeyCode == Enum.KeyCode.A then Titanium.State.FlyKeys.A = false end
    if i.KeyCode == Enum.KeyCode.S then Titanium.State.FlyKeys.S = false end
    if i.KeyCode == Enum.KeyCode.D then Titanium.State.FlyKeys.D = false end
    if i.KeyCode == Enum.KeyCode.Space then Titanium.State.FlyKeys.Up = false end
    if i.KeyCode == Enum.KeyCode.LeftControl then Titanium.State.FlyKeys.Down = false end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Titanium | Warlord Absolute",
    LoadingTitle = "Core Loaded",
    ConfigurationSaving = {Enabled = true, FolderName = "TitaniumAbsolute", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabM = Window:CreateTab("Movement", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateSection("Silent Aim")
TabC:CreateToggle({Name = "Enable Silent Aim", CurrentValue = false, Callback = function(v) Titanium.Settings.Combat.SilentAim.Enabled = v end})
TabC:CreateToggle({Name = "Show FOV", CurrentValue = false, Callback = function(v) Titanium.Settings.Combat.SilentAim.ShowFOV = v end})
TabC:CreateSlider({Name = "FOV Radius", Range = {10, 500}, Increment = 1, CurrentValue = 150, Callback = function(v) Titanium.Settings.Combat.SilentAim.FOV = v end})

TabC:CreateSection("Aegis Auto Block")
TabC:CreateToggle({Name = "Enable Auto Block", CurrentValue = false, Callback = function(v) Titanium.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateDropdown({Name = "Mode", Options = {"Animation", "Distance"}, CurrentOption = "Animation", Callback = function(v) Titanium.Settings.Combat.AutoBlock.Mode = v end})
TabC:CreateSlider({Name = "Range", Range = {5, 50}, Increment = 1, CurrentValue = 15, Callback = function(v) Titanium.Settings.Combat.AutoBlock.Range = v end})

TabC:CreateSection("Hitbox Expander")
TabC:CreateToggle({Name = "Enable Hitbox", CurrentValue = false, Callback = function(v) Titanium.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Size", Range = {2, 50}, Increment = 1, CurrentValue = 15, Callback = function(v) Titanium.Settings.Combat.Hitbox.Size = v end})
TabC:CreateSlider({Name = "Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Titanium.Settings.Combat.Hitbox.Transparency = v end})

TabM:CreateToggle({Name = "Velocity Fly", CurrentValue = false, Callback = function(v) 
    Titanium.Settings.Movement.Fly.Enabled = v
    if not v and LocalPlayer.Character then
        LocalPlayer.Character.Humanoid.PlatformStand = false
        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    end
end})
TabM:CreateSlider({Name = "Fly Speed", Range = {20, 500}, Increment = 1, CurrentValue = 80, Callback = function(v) Titanium.Settings.Movement.Fly.Speed = v end})
TabM:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Titanium.Settings.Movement.Speed.Enabled = v end})
TabM:CreateSlider({Name = "WalkSpeed", Range = {16, 300}, Increment = 1, CurrentValue = 16, Callback = function(v) Titanium.Settings.Movement.Speed.Val = v end})
TabM:CreateToggle({Name = "Noclip", CurrentValue = false, Callback = function(v) Titanium.Settings.Movement.NoClip.Enabled = v end})

TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Titanium.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) 
    Titanium.Settings.Visuals.Fullbright = v
    if v then Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.GlobalShadows=false Lighting.Ambient=Color3.new(1,1,1) end
end})

RunService.RenderStepped:Connect(function(dt)
    SecureCall(Physics.Update, dt)
    SecureCall(Combat.Update)
    if Titanium.Settings.Visuals.ESP.Enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not Titanium.Cache.ESP[p] then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Parent = p.Character
                Titanium.Cache.ESP[p] = hl
            end
        end
    else
        for i, v in pairs(Titanium.Cache.ESP) do v:Destroy() end
        Titanium.Cache.ESP = {}
    end
end)

Rayfield:LoadConfiguration()
