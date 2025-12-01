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
        Combat = {
            SilentAim = {Enabled = false, FOV = 180, ShowFOV = false, Part = "HumanoidRootPart"},
            AutoBlock = {Enabled = false, Mode = "Hybrid", Range = 18, Reaction = 0, Duration = 0.5, AutoFace = true},
            Hitbox = {Enabled = false, Size = 20, Transparency = 0.6, Part = "HumanoidRootPart"},
            KillAura = {Enabled = false, Range = 25, Speed = 0.1},
            Backtrack = {Enabled = false, Time = 0.5}
        },
        Killer = {
            Enabled = false,
            Magnet = {Enabled = false, Speed = 0.8},
            Reach = {Enabled = false, Multiplier = 2}
        },
        Movement = {
            Fly = {Enabled = false, Speed = 90, Vertical = 60},
            Speed = {Enabled = false, Val = 20},
            Jump = {Enabled = false, Val = 50},
            NoClip = {Enabled = false},
            Desync = {Enabled = false}
        },
        Visuals = {
            ESP = {Enabled = false},
            Chams = {Enabled = false, Fill = Color3.fromRGB(255,0,0)},
            Fullbright = false,
            MobileUI = false
        },
        Utility = {
            AutoHeal = {Enabled = false, Threshold = 30},
            AntiStun = {Enabled = false}
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        LastAttack = 0,
        Input = {W=false, A=false, S=false, D=false, Up=false, Down=false, MobileUp=false, MobileDown=false},
        Target = nil,
        BacktrackRecords = {}
    },
    Cache = {
        ESP = {},
        FOV = nil,
        Chams = {},
        MobileGui = nil
    },
    Keywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action", "comb"}
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
    F.Size = UDim2.new(0, 350, 0, 180)
    F.Position = UDim2.new(0.5, -175, 0.5, -90)
    F.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    F.BorderSizePixel = 0
    F.Parent = S
    
    local G = Instance.new("UIGradient")
    G.Color = ColorSequence.new(Color3.fromRGB(15,15,20), Color3.fromRGB(5,5,8))
    G.Rotation = 45
    G.Parent = F
    
    local T = Instance.new("TextLabel")
    T.Text = "ITOSHI HUB | HYBRID"
    T.Size = UDim2.new(1, 0, 0.2, 0)
    T.BackgroundTransparency = 1
    T.TextColor3 = Color3.fromRGB(255, 0, 0)
    T.Font = Enum.Font.GothamBlack
    T.TextSize = 18
    T.Parent = F
    
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
    Btn.Text = "LOGIN"
    Btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.GothamBold
    Btn.Parent = F
    
    local V = false
    Btn.MouseButton1Click:Connect(function()
        if B.Text == "FFDGDLFYUFOHDWHHFXX" then
            V = true
            getgenv().ItoshiAuth = true
            S:Destroy()
        else
            B.Text = "INVALID"
            task.wait(1)
            B.Text = ""
        end
    end)
    repeat task.wait(0.1) until V
end

KeySystem.Run()

local MobileManager = {}
function MobileManager.Toggle()
    if Itoshi.Cache.MobileGui then Itoshi.Cache.MobileGui:Destroy() Itoshi.Cache.MobileGui = nil end
    if not Itoshi.Settings.Visuals.MobileUI then return end
    
    local S = Instance.new("ScreenGui")
    S.Name = "ItoshiMobileControls"
    S.Parent = CoreGui
    Itoshi.Cache.MobileGui = S
    
    local function CreateBtn(Text, Pos, DownFunc, UpFunc)
        local B = Instance.new("TextButton")
        B.Size = UDim2.new(0, 60, 0, 60)
        B.Position = Pos
        B.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        B.BackgroundTransparency = 0.6
        B.Text = Text
        B.TextColor3 = Color3.new(1,1,1)
        B.TextSize = 24
        B.Font = Enum.Font.GothamBold
        B.Parent = S
        Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
        Instance.new("UIStroke", B).Color = Color3.fromRGB(255, 0, 0)
        
        B.MouseButton1Down:Connect(DownFunc)
        B.MouseButton1Up:Connect(UpFunc)
        B.MouseLeave:Connect(UpFunc)
    end
    
    CreateBtn("▲", UDim2.new(0.85, 0, 0.55, 0), 
        function() Itoshi.State.Input.MobileUp = true end, 
        function() Itoshi.State.Input.MobileUp = false end
    )
    
    CreateBtn("▼", UDim2.new(0.85, 0, 0.7, 0), 
        function() Itoshi.State.Input.MobileDown = true end, 
        function() Itoshi.State.Input.MobileDown = false end
    )
    
    CreateBtn("FLY", UDim2.new(0.72, 0, 0.62, 0), 
        function() 
            Itoshi.Settings.Movement.Fly.Enabled = not Itoshi.Settings.Movement.Fly.Enabled 
        end, function() end
    )
end

local Vector = {}
function Vector.Mag(v1, v2) return (v1 - v2).Magnitude end

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

function Combat.GetClosest()
    local C, M = nil, math.huge
    local Mouse = UserInputService:GetMouseLocation()
    for _, Char in pairs(Combat.GetTargets()) do
        local Part = Char:FindFirstChild(Itoshi.Settings.Combat.SilentAim.Part)
        if Part then
            local Pos, Vis = Camera:WorldToViewportPoint(Part.Position)
            if Vis then
                local D = Vector.Mag(Vector2.new(Pos.X, Pos.Y), Mouse)
                if D < M and D <= Itoshi.Settings.Combat.SilentAim.FOV then
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
            for _, K in pairs(Itoshi.Keywords) do
                if string.find(N, K) then return true end
            end
        end
    end
    return false
end

function Combat.BacktrackLog()
    if not Itoshi.Settings.Combat.Backtrack.Enabled then 
        Itoshi.State.BacktrackRecords = {}
        return 
    end
    for _, Char in pairs(Combat.GetTargets()) do
        local Root = Char:FindFirstChild("HumanoidRootPart")
        if Root then
            if not Itoshi.State.BacktrackRecords[Char] then Itoshi.State.BacktrackRecords[Char] = {} end
            table.insert(Itoshi.State.BacktrackRecords[Char], 1, {CFrame = Root.CFrame, Time = tick()})
            if #Itoshi.State.BacktrackRecords[Char] > 30 then table.remove(Itoshi.State.BacktrackRecords[Char]) end
        end
    end
end

function Combat.Update()
    if Itoshi.Settings.Combat.SilentAim.Enabled then
        Itoshi.State.Target = Combat.GetClosest()
        if Itoshi.Settings.Combat.SilentAim.ShowFOV then
            if not Itoshi.Cache.FOV then
                Itoshi.Cache.FOV = Drawing.new("Circle")
                Itoshi.Cache.FOV.Color = Color3.fromRGB(255, 0, 0)
                Itoshi.Cache.FOV.Thickness = 1
                Itoshi.Cache.FOV.NumSides = 60
                Itoshi.Cache.FOV.Filled = false
            end
            Itoshi.Cache.FOV.Visible = true
            Itoshi.Cache.FOV.Radius = Itoshi.Settings.Combat.SilentAim.FOV
            Itoshi.Cache.FOV.Position = UserInputService:GetMouseLocation()
        elseif Itoshi.Cache.FOV then
            Itoshi.Cache.FOV.Visible = false
        end
    end

    if Itoshi.Settings.Combat.KillAura.Enabled then
        local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if MyRoot and tick() - Itoshi.State.LastAttack > Itoshi.Settings.Combat.KillAura.Speed then
            for _, Char in pairs(Combat.GetTargets()) do
                local Root = Char:FindFirstChild("HumanoidRootPart")
                if Root and Vector.Mag(MyRoot.Position, Root.Position) <= Itoshi.Settings.Combat.KillAura.Range then
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                    Itoshi.State.LastAttack = tick()
                    break
                end
            end
        end
    end

    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if MyRoot then
            for _, Char in pairs(Combat.GetTargets()) do
                local KRoot = Char:FindFirstChild("HumanoidRootPart")
                if KRoot then
                    local D = Vector.Mag(MyRoot.Position, KRoot.Position)
                    local Block = false
                    if Itoshi.Settings.Combat.AutoBlock.Mode == "Animation" then
                        if D <= Itoshi.Settings.Combat.AutoBlock.Range and Combat.IsAttacking(Char) then Block = true end
                    elseif Itoshi.Settings.Combat.AutoBlock.Mode == "Hybrid" then
                        if D < 5 or (D <= Itoshi.Settings.Combat.AutoBlock.Range and Combat.IsAttacking(Char)) then Block = true end
                    end
                    if Block and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
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
                        break
                    end
                end
            end
        end
    end
end

local Physics = {}
function Physics.Update(dt)
    if Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if Hum and Root then
            Hum.PlatformStand = true
            Hum:ChangeState(Enum.HumanoidStateType.Physics)
            
            local V = Vector3.zero
            
            if Hum.MoveDirection.Magnitude > 0 then
                V = Hum.MoveDirection * Itoshi.Settings.Movement.Fly.Speed
            end
            
            local Y = 0
            if Itoshi.State.Input.Up or Itoshi.State.Input.MobileUp then Y = Itoshi.Settings.Movement.Fly.Vertical end
            if Itoshi.State.Input.Down or Itoshi.State.Input.MobileDown then Y = -Itoshi.Settings.Movement.Fly.Vertical end
            
            Root.AssemblyLinearVelocity = Vector3.new(V.X, Y, V.Z)
            Root.AssemblyAngularVelocity = Vector3.zero
        end
    end
    if Itoshi.Settings.Movement.Speed.Enabled and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then Hum.WalkSpeed = Itoshi.Settings.Movement.Speed.Val end
    end
    if Itoshi.Settings.Movement.NoClip.Enabled and LocalPlayer.Character then
         for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
         end
    end
    if Itoshi.Settings.Killer.Enabled and LocalPlayer.Character then
        local Target = nil
        local MyRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local Min = math.huge
        for _, Char in pairs(Combat.GetTargets()) do
            local R = Char:FindFirstChild("HumanoidRootPart")
            if R and MyRoot then
                local D = Vector.Mag(MyRoot.Position, R.Position)
                if D < Min then Min = D Target = R end
            end
        end
        if Target and MyRoot then
            if Itoshi.Settings.Killer.Magnet.Enabled then
               MyRoot.CFrame = MyRoot.CFrame:Lerp(CFrame.new(MyRoot.Position, Target.Position), 0.1)
               MyRoot.Position = MyRoot.Position:Lerp(Target.Position, Itoshi.Settings.Killer.Magnet.Speed * dt)
            end
            if Itoshi.Settings.Killer.Reach.Enabled then
                Target.Size = Vector3.new(20,20,20)
                Target.CanCollide = false
                Target.Transparency = 0.8
            end
        end
    end
end

local Hooks = {}
function Hooks.Init()
    local OldNC, OldIdx
    OldNC = hookmeta(game, "__namecall", newcclosure(function(self, ...)
        local A = {...}
        local M = getnamecallmethod()
        if Itoshi.Settings.Combat.SilentAim.Enabled and Itoshi.State.Target and (M == "FireServer" or M == "InvokeServer") then
            for i, v in pairs(A) do
                if typeof(v) == "Vector3" then A[i] = Itoshi.State.Target.Position end
                if typeof(v) == "CFrame" then A[i] = CFrame.new(A[i].Position, Itoshi.State.Target.Position) end
            end
            return OldNC(self, unpack(A))
        end
        return OldNC(self, ...)
    end))
    OldIdx = hookmeta(game, "__index", newcclosure(function(self, K)
        if Itoshi.Settings.Combat.SilentAim.Enabled and Itoshi.State.Target and (K == "Hit" or K == "Target") and self:IsA("Mouse") then
            return (K == "Hit" and Itoshi.State.Target.CFrame or Itoshi.State.Target)
        end
        return OldIdx(self, K)
    end))
end

Hooks.Init()

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.Space then Itoshi.State.Input.Up = true end
    if i.KeyCode == Enum.KeyCode.LeftControl then Itoshi.State.Input.Down = true end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Space then Itoshi.State.Input.Up = false end
    if i.KeyCode == Enum.KeyCode.LeftControl then Itoshi.State.Input.Down = false end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub | Absolute",
    LoadingTitle = "Core Injection...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabK = Window:CreateTab("Killer", 4483362458)
local TabM = Window:CreateTab("Movement", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)
local TabU = Window:CreateTab("Utility", 4483362458)

TabC:CreateSection("Offensive")
TabC:CreateToggle({Name = "Silent Aim", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.SilentAim.Enabled = v end})
TabC:CreateToggle({Name = "Kill Aura", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Backtrack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Backtrack.Enabled = v end})
TabC:CreateSlider({Name = "Backtrack MS", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.2, Callback = function(v) Itoshi.Settings.Combat.Backtrack.Time = v end})

TabC:CreateSection("Defensive")
TabC:CreateToggle({Name = "Auto Block", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateDropdown({Name = "Block Mode", Options = {"Animation", "Hybrid", "Distance"}, CurrentOption = "Hybrid", Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Mode = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 18, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})

TabK:CreateSection("Killer Mode")
TabK:CreateToggle({Name = "Killer Mode", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Enabled = v end})
TabK:CreateToggle({Name = "Reach (Hitbox)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Reach.Enabled = v end})
TabK:CreateToggle({Name = "Magnet", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Magnet.Enabled = v end})
TabK:CreateSlider({Name = "Magnet Speed", Range = {0.1, 3}, Increment = 0.1, CurrentValue = 0.8, Callback = function(v) Itoshi.Settings.Killer.Magnet.Speed = v end})

TabM:CreateToggle({Name = "Fly", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Fly.Enabled = v if not v and LocalPlayer.Character then LocalPlayer.Character.Humanoid.PlatformStand = false LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero end end})
TabM:CreateSlider({Name = "Fly Speed", Range = {20, 500}, Increment = 1, CurrentValue = 90, Callback = function(v) Itoshi.Settings.Movement.Fly.Speed = v end})
TabM:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Speed.Enabled = v end})
TabM:CreateSlider({Name = "WalkSpeed", Range = {16, 300}, Increment = 1, CurrentValue = 20, Callback = function(v) Itoshi.Settings.Movement.Speed.Val = v end})
TabM:CreateToggle({Name = "Anti-Aim", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Desync.Enabled = v end})

TabV:CreateSection("Mobile Support")
TabV:CreateToggle({Name = "Show Mobile Buttons", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Visuals.MobileUI = v
    MobileManager.Toggle()
end})

TabV:CreateSection("Render")
TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Chams", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Chams.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v if v then Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.GlobalShadows=false Lighting.Ambient=Color3.new(1,1,1) end end})

TabU:CreateToggle({Name = "Auto Heal", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoHeal.Enabled = v end})
TabU:CreateToggle({Name = "Anti Stun", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AntiStun.Enabled = v end})

RunService.RenderStepped:Connect(function(dt)
    SecureCall(Physics.Update, dt)
    SecureCall(Combat.Update)
    SecureCall(Combat.BacktrackLog)
    
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
    
    if Itoshi.Settings.Utility.AutoHeal.Enabled and LocalPlayer.Character then
        local H = LocalPlayer.Character:FindFirstChild("Humanoid")
        if H and H.Health < Itoshi.Settings.Utility.AutoHeal.Threshold then
            local Tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if Tool and (Tool.Name:lower():find("heal") or Tool.Name:lower():find("med")) then
                H:EquipTool(Tool)
                Tool:Activate()
            end
        end
    end
end)

Rayfield:LoadConfiguration()
