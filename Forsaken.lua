local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

-- SERVICES
local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local CoreGui = Services.CoreGui
local VirtualInputManager = Services.VirtualInputManager
local Lighting = Services.Lighting
local PathfindingService = Services.PathfindingService
local ProximityPromptService = Services.ProximityPromptService

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIG
local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = true, Range = 22, Speed = 0.1, Rotate = true},
            AutoBlock = {Enabled = true, Range = 20, Duration = 0.6, AutoFace = true},
            Hitbox = {Enabled = true, Size = 15, Reach = true}
        },
        Movement = {
            Fly = {Enabled = false, Speed = 1, Vertical = 1},
            Speed = {Enabled = false, Val = 25},
            NoClip = {Enabled = false}
        },
        Utility = {
            AutoGenerator = {Enabled = false, AutoSkill = true},
            AutoHeal = {Enabled = true, Threshold = 40},
            AntiStun = {Enabled = true}
        },
        Visuals = {
            ESP = {Enabled = false},
            Fullbright = false,
            MobileUI = false
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        LastAttack = 0,
        FlyKeys = {W=false, A=false, S=false, D=false, Up=false, Down=false},
        Target = nil,
        MovingToGen = false
    },
    Cache = {
        Targets = {},
        Generators = {},
        ESP = {}
    }
}

-- UTILS
local function SecureCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local function GetRoot(Char)
    return Char:FindFirstChild("HumanoidRootPart")
end

local function GetHum(Char)
    return Char:FindFirstChild("Humanoid")
end

-- KEY SYSTEM
local function LoadKeySystem()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "ItoshiAuth"
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 300, 0, 150)
    F.Position = UDim2.new(0.5, -150, 0.5, -75)
    F.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.3, 0)
    B.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    B.TextColor3 = Color3.new(1,1,1)
    B.PlaceholderText = "Key..."
    B.Text = ""
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "LOAD APEX"
    Btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    Btn.Parent = F
    
    local V = false
    Btn.MouseButton1Click:Connect(function()
        if B.Text == "FFDGDLFYUFOHDWHHFXX" then
            V = true
            getgenv().ItoshiAuth = true
            S:Destroy()
        end
    end)
    repeat task.wait(0.1) until V
end
LoadKeySystem()

-- COMBAT LOGIC
local Combat = {}

function Combat.RefreshTargets()
    table.clear(Itoshi.Cache.Targets)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then table.insert(Itoshi.Cache.Targets, p.Character) end
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(v) then
            table.insert(Itoshi.Cache.Targets, v)
        end
    end
end

function Combat.IsAttacking(Char)
    if not Char then return false end
    local Hum = GetHum(Char)
    if not Hum then return false end
    local Anim = Hum:FindFirstChild("Animator")
    if not Anim then return false end
    
    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
        if Track.Priority == Enum.AnimationPriority.Action or Track.Priority == Enum.AnimationPriority.Action2 then
            return true
        end
    end
    return false
end

function Combat.Update()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- KILL AURA
    if Itoshi.Settings.Combat.KillAura.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.KillAura.Range then
                if Itoshi.Settings.Combat.KillAura.Rotate then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                end
                
                if tick() - Itoshi.State.LastAttack > Itoshi.Settings.Combat.KillAura.Speed then
                    local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if Tool then Tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                    Itoshi.State.LastAttack = tick()
                end
                break
            end
        end
    end
    
    -- AUTO BLOCK
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        if not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
            for _, Target in pairs(Itoshi.Cache.Targets) do
                local TRoot = GetRoot(Target)
                if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.AutoBlock.Range then
                    if Combat.IsAttacking(Target) then
                        if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                        end
                        
                        Itoshi.State.Blocking = true
                        Itoshi.State.LastBlock = tick()
                        
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        
                        task.delay(Itoshi.Settings.Combat.AutoBlock.Duration, function()
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                            Itoshi.State.Blocking = false
                        end)
                        break
                    end
                end
            end
        end
    end

     -- WEAPON REACH
    if Itoshi.Settings.Combat.Hitbox.Enabled and Itoshi.Settings.Combat.Hitbox.Reach then
        local Char = LocalPlayer.Character
        if Char then
             local Tool = Char:FindFirstChildOfClass("Tool")
             if Tool then
                 local Handle = Tool:FindFirstChild("Handle")
                 if Handle then
                     Handle.Size = Vector3.new(Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size)
                     Handle.Massless = true
                     Handle.Transparency = 0.5
                     Handle.CanCollide = false
                 end
             end
        end
    end
end

-- MOVEMENT LOGIC (FIXED)
local Physics = {}

function Physics.Update(dt)
    if Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
        local Hum = GetHum(LocalPlayer.Character)
        local Root = GetRoot(LocalPlayer.Character)
        if Hum and Root then
            Hum.PlatformStand = true
            Root.AssemblyLinearVelocity = Vector3.zero
            
            local CF = Camera.CFrame
            local Move = Vector3.zero
            
            if Hum.MoveDirection.Magnitude > 0 then
                Move = Hum.MoveDirection
            else
                if Itoshi.State.FlyKeys.W then Move = Move + CF.LookVector end
                if Itoshi.State.FlyKeys.S then Move = Move - CF.LookVector end
                if Itoshi.State.FlyKeys.A then Move = Move - CF.RightVector end
                if Itoshi.State.FlyKeys.D then Move = Move + CF.RightVector end
            end
            
            if Move.Magnitude > 0 then
                Move = Move.Unit * Itoshi.Settings.Movement.Fly.Speed * 2
            end
            
            local Y = 0
            if Itoshi.State.FlyKeys.Up then Y = Itoshi.Settings.Movement.Fly.Vertical * 2 end
            if Itoshi.State.FlyKeys.Down then Y = -Itoshi.Settings.Movement.Fly.Vertical * 2 end
            
            Root.CFrame = Root.CFrame + (Move * dt * 50) + (Vector3.new(0, Y, 0) * dt * 50)
        end
    end

    if Itoshi.Settings.Movement.Speed.Enabled and not Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
        local Hum = GetHum(LocalPlayer.Character)
        local Root = GetRoot(LocalPlayer.Character)
        if Hum and Root and Hum.MoveDirection.Magnitude > 0 then
            Root.CFrame = Root.CFrame + (Hum.MoveDirection * Itoshi.Settings.Movement.Speed.Val * dt)
        end
    end
end

-- GENERATOR LOGIC (PATHFINDING)
local GenSys = {}

function GenSys.Refresh()
    table.clear(Itoshi.Cache.Generators)
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("repair") or v.ObjectText:lower():find("generator")) and v.Enabled then
            table.insert(Itoshi.Cache.Generators, v)
        end
    end
end

function GenSys.MoveTo(TargetPos)
    local Char = LocalPlayer.Character
    local Hum = GetHum(Char)
    local Root = GetRoot(Char)
    if not Hum or not Root then return end
    
    Hum.PlatformStand = false -- Enable movement
    
    local Path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true
    })
    
    local Success, Error = pcall(function()
        Path:ComputeAsync(Root.Position, TargetPos)
    end)
    
    if Success and Path.Status == Enum.PathStatus.Success then
        for _, WP in pairs(Path:GetWaypoints()) do
            if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
            
            if WP.Action == Enum.PathWaypointAction.Jump then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            Hum:MoveTo(WP.Position)
            
            local Timeout = 0
            repeat 
                task.wait(0.1)
                Timeout = Timeout + 0.1
            until (Root.Position - WP.Position).Magnitude < 4 or Timeout > 2
        end
    else
        Hum:MoveTo(TargetPos) -- Direct fallback
    end
end

function GenSys.AutoSkill()
    if not Itoshi.Settings.Utility.AutoGenerator.AutoSkill then return end
    local Gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not Gui then return end
    
    for _, G in pairs(Gui:GetChildren()) do
        if G:IsA("ScreenGui") and G.Enabled then
            local Bar = G:FindFirstChild("Bar", true) or G:FindFirstChild("Cursor", true)
            if Bar and Bar.Visible then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end
    end
end

function GenSys.Update()
    if not Itoshi.Settings.Utility.AutoGenerator.Enabled then 
        Itoshi.State.MovingToGen = false
        return 
    end
    
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    local Closest, Min = nil, 9999
    for _, G in pairs(Itoshi.Cache.Generators) do
        if G.Parent and G.Enabled then
            local D = (MyRoot.Position - G.Parent.Position).Magnitude
            if D < Min then Min = D Closest = G end
        end
    end
    
    if Closest and Closest.Parent then
        if Min > 8 then
            if not Itoshi.State.MovingToGen then
                Itoshi.State.MovingToGen = true
                task.spawn(function()
                    GenSys.MoveTo(Closest.Parent.Position)
                    Itoshi.State.MovingToGen = false
                end)
            end
        else
            fireproximityprompt(Closest)
            GenSys.AutoSkill()
        end
    end
end

-- INPUTS
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

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Apex Predator...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "ApexCfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabG = Window:CreateTab("Utility", 4483362458)
local TabM = Window:CreateTab("Movement", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = Itoshi.Settings.Combat.KillAura.Enabled, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block", CurrentValue = Itoshi.Settings.Combat.AutoBlock.Enabled, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Weapon Reach", CurrentValue = Itoshi.Settings.Combat.Hitbox.Enabled, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Reach Size", Range = {2, 30}, Increment = 1, CurrentValue = 15, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

TabG:CreateToggle({Name = "Auto Generator (Pathfinding)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabG:CreateToggle({Name = "Auto Skill Check", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoSkill = v end})
TabG:CreateToggle({Name = "Anti-Stun", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AntiStun.Enabled = v end})

TabM:CreateToggle({Name = "Fly (CFrame)", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Movement.Fly.Enabled = v
    if not v and LocalPlayer.Character then
        local Hum = GetHum(LocalPlayer.Character)
        local Root = GetRoot(LocalPlayer.Character)
        -- RESET PHYSICS ON DISABLE
        if Hum then Hum.PlatformStand = false Hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        if Root then Root.AssemblyLinearVelocity = Vector3.zero end
    end
end})
TabM:CreateSlider({Name = "Fly Speed", Range = {0.1, 10}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Itoshi.Settings.Movement.Fly.Speed = v end})
TabM:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Speed.Enabled = v end})
TabM:CreateSlider({Name = "Speed Val", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Itoshi.Settings.Movement.Speed.Val = v end})

TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- LOOPS
RunService.RenderStepped:Connect(function(dt)
    SecureCall(Physics.Update, dt)
    SecureCall(Combat.Update)
    SecureCall(GenSys.Update)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        SecureCall(Combat.RefreshTargets)
        SecureCall(GenSys.GetGenerators)
        
        if Itoshi.Settings.Visuals.ESP.Enabled then
            for _, t in pairs(Itoshi.Cache.Targets) do
                if not Itoshi.Cache.ESP[t] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.Adornee = t
                    hl.Parent = CoreGui
                    Itoshi.Cache.ESP[t] = hl
                end
            end
        else
            for i, v in pairs(Itoshi.Cache.ESP) do v:Destroy() end
            Itoshi.Cache.ESP = {}
        end
    end
end)

Rayfield:LoadConfiguration()
