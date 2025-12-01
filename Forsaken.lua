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
local PathfindingService = Services.PathfindingService
local TweenService = Services.TweenService
local ProximityPromptService = Services.ProximityPromptService
local ReplicatedStorage = Services.ReplicatedStorage
local Stats = Services.Stats

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = true, Range = 25, Rate = "Hyper", Rotate = true},
            AutoBlock = {
                Enabled = true, 
                Mode = "Neural", -- Combined Logic
                Range = 25, 
                Reaction = 0, 
                Duration = 0.8, 
                AutoFace = true,
                CheckFacing = false
            },
            Hitbox = {Enabled = true, Size = 20, Transparency = 0.7, Reach = true},
            SilentAim = {Enabled = false, FOV = 300, ShowFOV = false}
        },
        Killer = {
            Enabled = false,
            Magnet = {Enabled = false, Speed = 0.8},
            Reach = {Enabled = false, Multiplier = 2}
        },
        Movement = {
            Fly = {Enabled = false, Speed = 1, Vertical = 1, Mode = "Physics"}, 
            Speed = {Enabled = false, Val = 0.5, Mode = "CFrame"},
            NoClip = {Enabled = false},
            AntiAim = {Enabled = false}
        },
        Utility = {
            AutoGenerator = {
                Enabled = false, 
                Method = "AI-Walk",
                AutoSkill = true,
                Speed = 22
            },
            AutoHeal = {Enabled = false, Threshold = 40},
            AntiStun = {Enabled = true}
        },
        Visuals = {
            ESP = {Enabled = false, Box = true, Tracer = false, Name = true},
            Chams = {Enabled = false, Fill = Color3.fromRGB(255, 0, 0)},
            Fullbright = false,
            MobileUI = false
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        LastAttack = 0,
        Target = nil,
        Input = {W=false, A=false, S=false, D=false, Up=false, Down=false, MobileUp=false, MobileDown=false},
        Path = nil,
        Waypoints = {},
        CurrentWaypoint = 0,
        IsMoving = false,
        Connections = {}
    },
    Cache = {
        Targets = {},
        Generators = {},
        ESP = {},
        Animations = {},
        Sounds = {}
    },
    Constants = {
        SafeAnims = {
            ["idle"] = true, ["walk"] = true, ["run"] = true, ["jump"] = true, ["fall"] = true, ["climb"] = true, ["equip"] = true, ["emote"] = true
        },
        AttackKeywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action", "heavy", "light", "charge", "hit", "dmg"}
    }
}

local Math = {}
function Math.GetDistance(P1, P2) return (P1 - P2).Magnitude end
function Math.GetDirection(Origin, Target) return (Target - Origin).Unit end
function Math.IsFacing(OriginCF, TargetPos)
    local Vec = (TargetPos - OriginCF.Position).Unit
    return OriginCF.LookVector:Dot(Vec) > 0.5
end

local Security = {}
function Security.Init()
    local OldNC
    OldNC = hookmeta(game, "__namecall", newcclosure(function(self, ...)
        local Method = getnamecallmethod()
        if Method == "Kick" or Method == "kick" then return end
        if Method == "FireServer" and tostring(self):lower():find("ban") then return end
        return OldNC(self, ...)
    end))
end
Security.Init()

local KeySystem = {}
function KeySystem.Run()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "ItoshiKernel"
    S.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 360, 0, 180)
    F.Position = UDim2.new(0.5, -180, 0.5, -90)
    F.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    F.BorderSizePixel = 0
    F.Parent = S
    
    local G = Instance.new("UIGradient")
    G.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 8))
    }
    G.Rotation = 45
    G.Parent = F
    
    local T = Instance.new("TextLabel")
    T.Text = "ITOSHI HUB | ARCHITECT"
    T.Size = UDim2.new(1, 0, 0.25, 0)
    T.BackgroundTransparency = 1
    T.TextColor3 = Color3.fromRGB(255, 60, 60)
    T.Font = Enum.Font.GothamBlack
    T.TextSize = 22
    T.Parent = F
    
    local K = Instance.new("TextBox")
    K.Size = UDim2.new(0.8, 0, 0.25, 0)
    K.Position = UDim2.new(0.1, 0, 0.35, 0)
    K.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    K.TextColor3 = Color3.fromRGB(255, 255, 255)
    K.PlaceholderText = "Authentication Key..."
    K.Text = ""
    K.Font = Enum.Font.Gotham
    K.Parent = F
    Instance.new("UICorner", K).CornerRadius = UDim.new(0, 6)
    
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(0.8, 0, 0.25, 0)
    B.Position = UDim2.new(0.1, 0, 0.65, 0)
    B.Text = "INITIALIZE"
    B.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    B.TextColor3 = Color3.new(1,1,1)
    B.Font = Enum.Font.GothamBold
    B.Parent = F
    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)
    
    local V = false
    B.MouseButton1Click:Connect(function()
        if K.Text == "FFDGDLFYUFOHDWHHFXX" then
            V = true
            getgenv().ItoshiAuth = true
            S:Destroy()
        else
            K.Text = "ACCESS DENIED"
            task.wait(1)
            K.Text = ""
        end
    end)
    repeat task.wait(0.1) until V
end
KeySystem.Run()

local MobileManager = {}
function MobileManager.Init()
    if Itoshi.Cache.MobileGui then Itoshi.Cache.MobileGui:Destroy() end
    if not Itoshi.Settings.Visuals.MobileUI then return end
    
    local S = Instance.new("ScreenGui")
    S.Name = "ItoshiMobile"
    S.Parent = CoreGui
    Itoshi.Cache.MobileGui = S
    
    local function Create(Txt, Pos, Down, Up)
        local B = Instance.new("TextButton")
        B.Size = UDim2.new(0, 55, 0, 55)
        B.Position = Pos
        B.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        B.BackgroundTransparency = 0.5
        B.Text = Txt
        B.TextColor3 = Color3.new(1,1,1)
        B.TextSize = 22
        B.Font = Enum.Font.GothamBold
        B.Parent = S
        Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
        B.MouseButton1Down:Connect(Down)
        B.MouseButton1Up:Connect(Up)
        B.MouseLeave:Connect(Up)
    end
    
    Create("▲", UDim2.new(0.85, 0, 0.5, 0), function() Itoshi.State.Input.MobileUp=true end, function() Itoshi.State.Input.MobileUp=false end)
    Create("▼", UDim2.new(0.85, 0, 0.65, 0), function() Itoshi.State.Input.MobileDown=true end, function() Itoshi.State.Input.MobileDown=false end)
    Create("FLY", UDim2.new(0.7, 0, 0.575, 0), function() 
        Itoshi.Settings.Movement.Fly.Enabled = not Itoshi.Settings.Movement.Fly.Enabled
        if not Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
            local H = LocalPlayer.Character:FindFirstChild("Humanoid")
            local R = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if H then H.PlatformStand = false H:ChangeState(Enum.HumanoidStateType.GettingUp) end
            if R then R.AssemblyLinearVelocity = Vector3.new(0,0,0) end
        end
    end, function() end)
end

local TargetManager = {}
function TargetManager.Refresh()
    table.clear(Itoshi.Cache.Targets)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local H = p.Character:FindFirstChild("Humanoid")
            local R = p.Character:FindFirstChild("HumanoidRootPart")
            if H and R and H.Health > 0 then table.insert(Itoshi.Cache.Targets, p.Character) end
        end
    end
    -- Efficient NPC Scan
    if tick() % 1 < 0.1 then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(v) and v ~= LocalPlayer.Character then
                local H = v.Humanoid
                if H.Health > 0 then table.insert(Itoshi.Cache.Targets, v) end
            end
        end
    end
end

local CombatManager = {}

function CombatManager.IsAttacking(Target)
    if not Target then return false end
    local Hum = Target:FindFirstChild("Humanoid")
    if not Hum then return false end
    local Anim = Hum:FindFirstChild("Animator")
    if not Anim then return false end
    
    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
        local Name = Track.Name:lower()
        local Safe = false
        for S, _ in pairs(Itoshi.Constants.SafeAnims) do
            if string.find(Name, S) then Safe = true break end
        end
        
        if not Safe then
            if Track.Priority == Enum.AnimationPriority.Action or 
               Track.Priority == Enum.AnimationPriority.Action2 or 
               Track.Priority == Enum.AnimationPriority.Action3 or
               Track.Priority == Enum.AnimationPriority.Movement then
               
               for _, K in pairs(Itoshi.Constants.AttackKeywords) do
                   if string.find(Name, K) then return true end
               end
               -- If priority is Action but name is unknown, assume attack if speed > 0
               if Track.Speed > 0 then return true end
            end
        end
    end
    return false
end

function CombatManager.Update()
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    
    -- KILL AURA
    if Itoshi.Settings.Combat.KillAura.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = Target:FindFirstChild("HumanoidRootPart")
            if TRoot then
                local Dist = Math.GetDistance(MyRoot.Position, TRoot.Position)
                if Dist <= Itoshi.Settings.Combat.KillAura.Range then
                    if Itoshi.Settings.Combat.KillAura.Rotate then
                        MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                    end
                    
                    if tick() - Itoshi.State.LastAttack > 0.05 then
                        local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if Tool then Tool:Activate() end
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                        Itoshi.State.LastAttack = tick()
                    end
                    break
                end
            end
        end
    end
    
    -- AUTO BLOCK
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = Target:FindFirstChild("HumanoidRootPart")
            if TRoot then
                local Dist = Math.GetDistance(MyRoot.Position, TRoot.Position)
                if Dist <= Itoshi.Settings.Combat.AutoBlock.Range then
                    local ShouldBlock = false
                    
                    if Itoshi.Settings.Combat.AutoBlock.Mode == "Neural" then
                        if CombatManager.IsAttacking(Target) then ShouldBlock = true end
                        if Dist < 6 then ShouldBlock = true end -- Panic block
                    end
                    
                    if Itoshi.Settings.Combat.AutoBlock.CheckFacing and not Math.IsFacing(MyRoot, TRoot.Position) then
                        ShouldBlock = false
                    end
                    
                    if ShouldBlock and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
                        if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                        end
                        
                        Itoshi.State.Blocking = true
                        Itoshi.State.LastBlock = tick()
                        
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                        task.delay(Itoshi.Settings.Combat.AutoBlock.Duration, function()
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                            Itoshi.State.Blocking = false
                        end)
                        break
                    end
                end
            end
        end
    end
    
    -- HITBOX REACH
    if Itoshi.Settings.Combat.Hitbox.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = Target:FindFirstChild("HumanoidRootPart")
            if TRoot then
                local S = Itoshi.Settings.Combat.Hitbox.Size
                TRoot.Size = Vector3.new(S, S, S)
                TRoot.Transparency = Itoshi.Settings.Combat.Hitbox.Transparency
                TRoot.CanCollide = false
                
                if Itoshi.Settings.Combat.Hitbox.Reach then
                    TRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -3)
                end
            end
        end
    end
end

local GeneratorManager = {}
function GeneratorManager.Refresh()
    table.clear(Itoshi.Cache.Generators)
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt = (v.ActionText .. v.ObjectText):lower()
            if txt:find("repair") or txt:find("generator") then
                table.insert(Itoshi.Cache.Generators, v)
            end
        end
    end
end

function GeneratorManager.PathTo(Dest)
    local Char = LocalPlayer.Character
    local Hum = Char and Char:FindFirstChild("Humanoid")
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Hum or not Root then return end
    
    Hum.PlatformStand = false
    
    local Path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4
    })
    
    local S, E = pcall(function() Path:ComputeAsync(Root.Position, Dest) end)
    
    if S and Path.Status == Enum.PathStatus.Success then
        local WPs = Path:GetWaypoints()
        for i, WP in pairs(WPs) do
            if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
            if WP.Action == Enum.PathWaypointAction.Jump then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            
            Hum:MoveTo(WP.Position)
            -- Speed Boost Check
            if Hum.WalkSpeed < Itoshi.Settings.Utility.AutoGenerator.Speed then 
                Hum.WalkSpeed = Itoshi.Settings.Utility.AutoGenerator.Speed 
            end
            
            local Timeout = 0
            repeat 
                task.wait(0.1)
                Timeout = Timeout + 0.1
                if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
            until (Root.Position - WP.Position).Magnitude < 4 or Timeout > 3
        end
    else
        Hum:MoveTo(Dest)
    end
end

function GeneratorManager.AutoSkill()
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

function GeneratorManager.Update()
    if not Itoshi.Settings.Utility.AutoGenerator.Enabled then return end
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    
    local Closest, Min = nil, math.huge
    for _, Gen in pairs(Itoshi.Cache.Generators) do
        if Gen.Parent and Gen.Enabled then
            local D = Math.GetDistance(MyRoot.Position, Gen.Parent.Position)
            if D < Min then Min = D Closest = Gen end
        end
    end
    
    if Closest and Closest.Parent then
        local Pos = Closest.Parent.Position
        if Min > 8 then
            if not Itoshi.State.IsMoving then
                Itoshi.State.IsMoving = true
                task.spawn(function()
                    GeneratorManager.PathTo(Pos)
                    Itoshi.State.IsMoving = false
                end)
            end
        else
            fireproximityprompt(Closest)
            GeneratorManager.AutoSkill()
        end
    end
end

local PhysicsManager = {}
function PhysicsManager.Update(dt)
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
                local K = Itoshi.State.Input
                if K.W then Move = Move + CF.LookVector end
                if K.S then Move = Move - CF.LookVector end
                if K.A then Move = Move - CF.RightVector end
                if K.D then Move = Move + CF.RightVector end
            end
            
            if Move.Magnitude > 0 then Move = Move.Unit * Itoshi.Settings.Movement.Fly.Speed * 2 end
            
            local Y = 0
            if Itoshi.State.Input.Up or Itoshi.State.Input.MobileUp then Y = Itoshi.Settings.Movement.Fly.Vertical * 2 end
            if Itoshi.State.Input.Down or Itoshi.State.Input.MobileDown then Y = -Itoshi.Settings.Movement.Fly.Vertical * 2 end
            
            Root.CFrame = Root.CFrame + (Move * dt * 50) + (Vector3.new(0, Y, 0) * dt * 50)
        end
    end
    
    if Itoshi.Settings.Movement.Speed.Enabled and not Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if Hum and Root and Hum.MoveDirection.Magnitude > 0 then
            Root.CFrame = Root.CFrame + (Hum.MoveDirection * Itoshi.Settings.Movement.Speed.Val * dt)
        end
    end
    
    if Itoshi.Settings.Movement.NoClip.Enabled and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end

-- Input Hook
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

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Architect Core",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabK = Window:CreateTab("Killer", 4483362458)
local TabM = Window:CreateTab("Movement", 4483362458)
local TabG = Window:CreateTab("Utility", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura (R-Key)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block (Neural)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Hitbox Reach", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Reach Size", Range = {2, 50}, Increment = 1, CurrentValue = 20, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

TabK:CreateToggle({Name = "Killer Mode", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Enabled = v end})
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
TabM:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Speed.Enabled = v end})
TabM:CreateSlider({Name = "Speed Val", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Itoshi.Settings.Movement.Speed.Val = v end})
TabM:CreateToggle({Name = "NoClip", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.NoClip.Enabled = v end})

TabG:CreateToggle({Name = "Auto Generator (AI Walk)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabG:CreateToggle({Name = "Auto Skill Check", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoSkill = v end})
TabG:CreateSlider({Name = "Walk Speed", Range = {16, 50}, Increment = 1, CurrentValue = 22, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Speed = v end})

TabV:CreateToggle({Name = "Show Mobile Buttons", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.MobileUI = v MobileManager.Init() end})
TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

RunService.RenderStepped:Connect(function(dt)
    SecureCall(PhysicsManager.Update, dt)
    SecureCall(CombatManager.Update)
    SecureCall(GeneratorManager.Update)
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        SecureCall(TargetManager.Refresh)
        SecureCall(GeneratorManager.Refresh)
        
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
