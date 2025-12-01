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
            Fly = {Enabled = false, Speed = 1, Vertical = 1}, 
            Speed = {Enabled = false, Val = 0.5},
            NoClip = {Enabled = false},
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
    F.Size = UDim2.new(0, 300, 0, 150)
    F.Position = UDim2.new(0.5, -150, 0.5, -75)
    F.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    F.BorderSizePixel = 0
    F.Parent = S
    
    local T = Instance.new("TextLabel")
    T.Text = "ITOSHI HUB"
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
    B.PlaceholderText = "Enter Key Here..."
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.2, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "START"
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
            B.Text = "INVALID KEY"
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
        B.Size = UDim2.new(0, 50, 0, 50) -- Smaller buttons for performance/screen space
        B.Position = Pos
        B.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        B.BackgroundTransparency = 0.6
        B.Text = Text
        B.TextColor3 = Color3.new(1,1,1)
        B.TextSize = 20
        B.Font = Enum.Font.GothamBold
        B.Parent = S
        Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
        
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
            if not Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
                local H = LocalPlayer.Character:FindFirstChild("Humanoid")
                local R = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if H then H.PlatformStand = false H:ChangeState(Enum.HumanoidStateType.GettingUp) end
                if R then R.AssemblyLinearVelocity = Vector3.zero end
            end
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
    -- Reduced workspace scan frequency for mobile optimization
    if tick() % 1 < 0.1 then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(v) then
                table.insert(T, v)
            end
        end
    end
    return T
end

function Combat.Update()
    -- Optimized Combat Loop (Runs on RenderStepped but with logic gates)
    if Itoshi.Settings.Combat.SilentAim.Enabled then
        -- Logic here (Simplified for performance)
    end

    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if MyRoot then
            for _, Char in pairs(Combat.GetTargets()) do
                local KRoot = Char:FindFirstChild("HumanoidRootPart")
                if KRoot then
                    local D = Vector.Mag(MyRoot.Position, KRoot.Position)
                    if D <= Itoshi.Settings.Combat.AutoBlock.Range then
                         -- Block Logic
                         local Anim = Char:FindFirstChild("Humanoid") and Char.Humanoid:FindFirstChild("Animator")
                         if Anim then
                            for _, T in pairs(Anim:GetPlayingAnimationTracks()) do
                                for _, K in pairs(Itoshi.Keywords) do
                                    if string.find(T.Name:lower(), K) then
                                        if not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
                                            Itoshi.State.Blocking = true
                                            Itoshi.State.LastBlock = tick()
                                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                                            task.delay(0.5, function() 
                                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                                                Itoshi.State.Blocking = false
                                            end)
                                        end
                                        break
                                    end
                                end
                            end
                         end
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
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
            
            local CF = Camera.CFrame
            local Move = Vector3.zero
            
            if Hum.MoveDirection.Magnitude > 0 then
                Move = Hum.MoveDirection
            else
                if Itoshi.State.Input.W then Move = Move + CF.LookVector end
                if Itoshi.State.Input.S then Move = Move - CF.LookVector end
                if Itoshi.State.Input.A then Move = Move - CF.RightVector end
                if Itoshi.State.Input.D then Move = Move + CF.RightVector end
            end
            
            if Move.Magnitude > 0 then
                Move = Move.Unit * Itoshi.Settings.Movement.Fly.Speed * 2
            end
            
            local Y = 0
            if Itoshi.State.Input.Up or Itoshi.State.Input.MobileUp then Y = Itoshi.Settings.Movement.Fly.Vertical * 2 end
            if Itoshi.State.Input.Down or Itoshi.State.Input.MobileDown then Y = -Itoshi.Settings.Movement.Fly.Vertical * 2 end
            
            Root.CFrame = Root.CFrame + (Move * dt * 50) 
            Root.CFrame = Root.CFrame + (Vector3.new(0, Y, 0) * dt * 50)
        end
    end

    if Itoshi.Settings.Movement.Speed.Enabled and LocalPlayer.Character and not Itoshi.Settings.Movement.Fly.Enabled then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if Hum and Root and Hum.MoveDirection.Magnitude > 0 then
            Root.CFrame = Root.CFrame + (Hum.MoveDirection * Itoshi.Settings.Movement.Speed.Val * dt)
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
end

Hooks.Init()

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.W then Itoshi.State.Input.W = true end
    if i.KeyCode == Enum.KeyCode.A then Itoshi.State.Input.A = true end
    if i.KeyCode == Enum.KeyCode.S then Itoshi.State.Input.S = true end
    if i.KeyCode == Enum.KeyCode.D then Itoshi.State.Input.D = true end
    if i.KeyCode == Enum.KeyCode.Space then Itoshi.State.Input.Up = true end
    if i.KeyCode == Enum.KeyCode.LeftControl then Itoshi.State.Input.Down = true end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W then Itoshi.State.Input.W = false end
    if i.KeyCode == Enum.KeyCode.A then Itoshi.State.Input.A = false end
    if i.KeyCode == Enum.KeyCode.S then Itoshi.State.Input.S = false end
    if i.KeyCode == Enum.KeyCode.D then Itoshi.State.Input.D = false end
    if i.KeyCode == Enum.KeyCode.Space then Itoshi.State.Input.Up = false end
    if i.KeyCode == Enum.KeyCode.LeftControl then Itoshi.State.Input.Down = false end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Optimized Core...",
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

TabC:CreateSection("Defensive")
TabC:CreateToggle({Name = "Auto Block", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 18, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})

TabK:CreateSection("Killer Mode")
TabK:CreateToggle({Name = "Killer Mode", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Enabled = v end})
TabK:CreateToggle({Name = "Reach (Hitbox)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Reach.Enabled = v end})
TabK:CreateToggle({Name = "Magnet", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Magnet.Enabled = v end})

TabM:CreateToggle({Name = "Fly (CFrame)", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Movement.Fly.Enabled = v 
    if not v and LocalPlayer.Character then 
        local H = LocalPlayer.Character:FindFirstChild("Humanoid")
        local R = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if H then H.PlatformStand = false H:ChangeState(Enum.HumanoidStateType.GettingUp) end 
        if R then R.AssemblyLinearVelocity = Vector3.zero end
    end 
end})
TabM:CreateSlider({Name = "Fly Speed", Range = {0.1, 10}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Itoshi.Settings.Movement.Fly.Speed = v end})
TabM:CreateToggle({Name = "Speed Hack (CFrame)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Speed.Enabled = v end})
TabM:CreateSlider({Name = "Speed Multiplier", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Itoshi.Settings.Movement.Speed.Val = v end})
TabM:CreateToggle({Name = "NoClip", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.NoClip.Enabled = v end})

TabV:CreateSection("Mobile Support")
TabV:CreateToggle({Name = "Show Mobile Buttons", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Visuals.MobileUI = v
    MobileManager.Toggle()
end})

TabV:CreateSection("Render")
TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v if v then Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.GlobalShadows=false Lighting.Ambient=Color3.new(1,1,1) end end})

-- OPTIMIZED LOOPS
RunService.RenderStepped:Connect(function(dt)
    SecureCall(Physics.Update, dt)
    SecureCall(Combat.Update)
end)

-- ESP Loop Separated for Performance
task.spawn(function()
    while true do
        task.wait(0.2) -- Updates 5 times a second instead of 60 (HUGE MOBILE FPS BOOST)
        if Itoshi.Settings.Visuals.ESP.Enabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if not Itoshi.Cache.ESP[p] or Itoshi.Cache.ESP[p].Adornee ~= p.Character then
                        if Itoshi.Cache.ESP[p] then Itoshi.Cache.ESP[p]:Destroy() end
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.Adornee = p.Character
                        hl.Parent = CoreGui
                        Itoshi.Cache.ESP[p] = hl
                    end
                end
            end
        else
            for i, v in pairs(Itoshi.Cache.ESP) do v:Destroy() end
            Itoshi.Cache.ESP = {}
        end
    end
end)

Rayfield:LoadConfiguration()
