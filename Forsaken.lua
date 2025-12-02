-- [[ ITOSHI HUB ]] --
-- THE MOST ADVANCED FORSAKEN SCRIPT EVER MADE --

local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local hookmetamethod = hookmetamethod or function(...) end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

-- // 1. CORE SERVICES //
local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local CoreGui = Services.CoreGui
local VirtualInputManager = Services.VirtualInputManager
local Lighting = Services.Lighting
local PathfindingService = Services.PathfindingService
local ProximityPromptService = Services.ProximityPromptService
local TweenService = Services.TweenService
local ReplicatedStorage = Services.ReplicatedStorage
local Stats = Services.Stats
local TeleportService = Services.TeleportService
local HttpService = Services.HttpService

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // 2. CONFIGURATION MATRIX //
local Itoshi = {
    Signature = "ITOSHI HUB",
    Key = "FFDGDLFYUFOHDWHHFXX",
    Settings = {
        Combat = {
            KillAura = {Enabled = true, Range = 25, Speed = "Hyper", Rotate = true, Backstab = true},
            AutoBlock = {
                Enabled = true, 
                Mode = "Neural", -- AI Decision Making
                Range = 25, 
                Reaction = 0, 
                Duration = 0.8, 
                AutoFace = true,
                CheckFacing = false,
                PredictPing = true
            },
            Hitbox = {Enabled = true, Size = 25, Transparency = 0.6, Reach = true, Backtrack = true, Material = "ForceField"},
            SilentAim = {Enabled = true, FOV = 400, ShowFOV = false, Part = "Head"},
            TriggerBot = {Enabled = false, Delay = 0}
        },
        Killer = {
            Enabled = false,
            Magnet = {Enabled = false, Speed = 0.8, Range = 50},
            Reach = {Enabled = false, Multiplier = 3},
            InstaKill = {Enabled = false}, -- Risk
            LoopKill = {Enabled = false}
        },
        Movement = {
            Fly = {Enabled = false, Speed = 1, Vertical = 1, Mode = "CFrame"}, 
            Speed = {Enabled = false, Val = 0.5, Mode = "Velocity"},
            NoClip = {Enabled = false},
            AntiAim = {Enabled = false, Type = "Spin"},
            InfiniteJump = {Enabled = false},
            BunnyHop = {Enabled = false}
        },
        Utility = {
            AutoGenerator = {
                Enabled = false, 
                Method = "Pathfinding", -- Safe
                AutoSkill = true,
                Speed = 22,
                TeleportPrompt = true,
                InstantInteract = false
            },
            AutoHeal = {Enabled = true, Threshold = 45},
            AntiStun = {Enabled = true},
            AntiRagdoll = {Enabled = true},
            ServerHop = {Enabled = false},
            Rejoin = {Enabled = false}
        },
        Visuals = {
            ESP = {Enabled = false, Box = true, Tracer = true, Name = true, Health = true, Dist = 5000, Chams = true},
            GenESP = {Enabled = false, Color = Color3.fromRGB(0, 255, 0)},
            Fullbright = false,
            Crosshair = {Enabled = false},
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
        IsMovingToGen = false,
        ClosestGen = nil
    },
    Cache = {
        Targets = {},
        Generators = {},
        ESP = {},
        Animations = {},
        Sounds = {},
        Connections = {}
    },
    Constants = {
        SafeAnims = {
            ["idle"] = true, ["walk"] = true, ["run"] = true, ["jump"] = true, ["fall"] = true, ["climb"] = true, ["equip"] = true, ["sit"] = true
        },
        AttackKeywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action", "heavy", "light", "charge", "hit"}
    }
}

-- // 3. INTERNAL LIBRARIES //

local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({_b = Instance.new("BindableEvent")}, Signal) end
function Signal:Connect(f) return self._b.Event:Connect(f) end
function Signal:Fire(...) self._b:Fire(...) end

local Math = {}
function Math.GetDist(p1, p2) return (p1 - p2).Magnitude end
function Math.IsFacing(cf, pos) return cf.LookVector:Dot((pos - cf.Position).Unit) > 0 end
function Math.Predict(target, time) 
    local root = target:FindFirstChild("HumanoidRootPart")
    return root and (root.Position + (root.Velocity * time)) or target.Position
end

local function SecureCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local function GetRoot(Char) return Char:FindFirstChild("HumanoidRootPart") end
local function GetHum(Char) return Char:FindFirstChild("Humanoid") end

-- // 4. AUTHENTICATION //
local KeySystem = {}
function KeySystem.Run()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "Itoshi Key system"
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 400, 0, 220)
    F.Position = UDim2.new(0.5, -200, 0.5, -110)
    F.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    F.BorderSizePixel = 0
    F.Parent = S
    
    local G = Instance.new("UIGradient")
    G.Color = ColorSequence.new(Color3.fromRGB(20,20,25), Color3.fromRGB(10,10,12))
    G.Rotation = 45
    G.Parent = F
    
    local T = Instance.new("TextLabel")
    T.Text = "ITOSHI HUB"
    T.Size = UDim2.new(1, 0, 0.25, 0)
    T.BackgroundTransparency = 1
    T.TextColor3 = Color3.fromRGB(255, 0, 0)
    T.Font = Enum.Font.GothamBlack
    T.TextSize = 24
    T.Parent = F
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.2, 0)
    B.Position = UDim2.new(0.1, 0, 0.35, 0)
    B.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    B.TextColor3 = Color3.fromRGB(255, 255, 255)
    B.Text = ""
    B.PlaceholderText = "Authentication Key..."
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.2, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.65, 0)
    Btn.Text = "verify"
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
            B.Text = "INVALID ACCESS"
            task.wait(1)
            B.Text = ""
        end
    end)
    repeat task.wait(0.1) until V
end
KeySystem.Run()

-- // 5. MOBILE MANAGER //
local MobileManager = {}
function MobileManager.Init()
    if Itoshi.Cache.MobileGui then Itoshi.Cache.MobileGui:Destroy() end
    if not Itoshi.Settings.Visuals.MobileUI then return end
    
    local S = Instance.new("ScreenGui", CoreGui)
    S.Name = "ItoshiMobile"
    Itoshi.Cache.MobileGui = S
    
    local function Create(Txt, Pos, D, U)
        local B = Instance.new("TextButton")
        B.Size = UDim2.new(0, 60, 0, 60)
        B.Position = Pos
        B.BackgroundColor3 = Color3.new(0,0,0)
        B.BackgroundTransparency = 0.5
        B.TextColor3 = Color3.new(1,1,1)
        B.Text = Txt
        B.TextSize = 24
        B.Font = Enum.Font.GothamBold
        B.Parent = S
        Instance.new("UICorner", B).CornerRadius = UDim.new(1,0)
        B.MouseButton1Down:Connect(D)
        B.MouseButton1Up:Connect(U)
        B.MouseLeave:Connect(U)
    end
    
    Create("▲", UDim2.new(0.85, 0, 0.5, 0), function() Itoshi.State.Input.MobileUp=true end, function() Itoshi.State.Input.MobileUp=false end)
    Create("▼", UDim2.new(0.85, 0, 0.65, 0), function() Itoshi.State.Input.MobileDown=true end, function() Itoshi.State.Input.MobileDown=false end)
    Create("FLY", UDim2.new(0.7, 0, 0.575, 0), function() 
        Itoshi.Settings.Movement.Fly.Enabled = not Itoshi.Settings.Movement.Fly.Enabled
        if not Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
            local H = GetHum(LocalPlayer.Character)
            local R = GetRoot(LocalPlayer.Character)
            if H then H.PlatformStand = false H:ChangeState(Enum.HumanoidStateType.GettingUp) end
            if R then R.AssemblyLinearVelocity = Vector3.new(0,0,0) end
        end
    end, function() end)
end

-- // 6. ENTITY MANAGER //
local EntityManager = {}
function EntityManager.Refresh()
    table.clear(Itoshi.Cache.Targets)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local H = GetHum(p.Character)
            local R = GetRoot(p.Character)
            if H and R and H.Health > 0 then table.insert(Itoshi.Cache.Targets, p.Character) end
        end
    end
    if tick() % 1 < 0.1 then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(v) and v ~= LocalPlayer.Character then
                local H = v.Humanoid
                if H.Health > 0 then table.insert(Itoshi.Cache.Targets, v) end
            end
        end
    end
end

-- // 7. COMBAT ENGINE //
local CombatManager = {}

function CombatManager.IsAttacking(Target)
    if not Target then return false end
    local Hum = GetHum(Target)
    if not Hum then return false end
    local Anim = Hum:FindFirstChild("Animator")
    if not Anim then return false end
    
    -- Logic: Check Priority AND Name
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
               if Track.Speed > 0 then return true end
            end
        end
    end
    return false
end

function CombatManager.Process()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- 1. KILL AURA
    if Itoshi.Settings.Combat.KillAura.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot then
                local Dist = Math.GetDist(MyRoot.Position, TRoot.Position)
                if Dist <= Itoshi.Settings.Combat.KillAura.Range then
                    -- Auto Rotate
                    if Itoshi.Settings.Combat.KillAura.Rotate then
                        local LookPos = Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z)
                        if Itoshi.Settings.Combat.KillAura.Backstab then
                            -- Try to get behind
                            LookPos = TRoot.Position + (TRoot.CFrame.LookVector * -2)
                        end
                        MyRoot.CFrame = CFrame.new(MyRoot.Position, LookPos)
                    end
                    
                    if tick() - Itoshi.State.LastAttack > 0.05 then
                        local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if Tool then Tool:Activate() end
                        VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                        VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                        -- Backup R Key
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                        Itoshi.State.LastAttack = tick()
                    end
                    break
                end
            end
        end
    end
    
    -- 2. AUTO BLOCK
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot then
                local Dist = Math.GetDist(MyRoot.Position, TRoot.Position)
                if Dist <= Itoshi.Settings.Combat.AutoBlock.Range then
                    local ShouldBlock = false
                    
                    if Itoshi.Settings.Combat.AutoBlock.Mode == "Neural" then
                        if CombatManager.IsAttacking(Target) then ShouldBlock = true end
                        if Dist < 6 then ShouldBlock = true end -- Panic distance
                    end
                    
                    if Itoshi.Settings.Combat.AutoBlock.CheckFacing and not Math.IsFacing(MyRoot.CFrame, TRoot.Position) then
                        ShouldBlock = false
                    end
                    
                    if ShouldBlock and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
                        if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                        end
                        
                        -- Ping Compensation
                        local Ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
                        if Itoshi.Settings.Combat.AutoBlock.PredictPing then
                            task.wait(math.max(0, Itoshi.Settings.Combat.AutoBlock.Reaction - (Ping/2)))
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
    
    -- 3. HITBOX EXPANDER
    if Itoshi.Settings.Combat.Hitbox.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot then
                local S = Itoshi.Settings.Combat.Hitbox.Size
                TRoot.Size = Vector3.new(S, S, S)
                TRoot.Transparency = Itoshi.Settings.Combat.Hitbox.Transparency
                TRoot.CanCollide = false
                TRoot.Material = Enum.Material[Itoshi.Settings.Combat.Hitbox.Material]
                
                if Itoshi.Settings.Combat.Hitbox.Reach then
                    TRoot.CFrame = MyRoot.CFrame * CFrame.new(0,0,-3)
                end
            end
        end
    end
end

-- // 8. GENERATOR SYSTEM //
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

function GeneratorManager.Pathfind(Dest)
    local Char = LocalPlayer.Character
    local Hum = GetHum(Char)
    local Root = GetRoot(Char)
    if not Hum or not Root then return end
    
    Hum.PlatformStand = false
    
    local Path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4
    })
    
    local S, E = pcall(function() Path:ComputeAsync(Root.Position, Dest) end)
    
    if S and Path.Status == Enum.PathStatus.Success then
        for _, WP in pairs(Path:GetWaypoints()) do
            if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
            if WP.Action == Enum.PathWaypointAction.Jump then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            
            Hum:MoveTo(WP.Position)
            -- Speed Boost
            if Hum.WalkSpeed < Itoshi.Settings.Utility.AutoGenerator.Speed then 
                Hum.WalkSpeed = Itoshi.Settings.Utility.AutoGenerator.Speed 
            end
            
            local Time = 0
            repeat 
                task.wait(0.1)
                Time = Time + 0.1
                if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
            until (Root.Position - WP.Position).Magnitude < 4 or Time > 3
        end
    else
        -- Direct Move (Fallback)
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

function GeneratorManager.Process()
    if not Itoshi.Settings.Utility.AutoGenerator.Enabled then return end
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    local Closest, Min = nil, 9999
    for _, Gen in pairs(Itoshi.Cache.Generators) do
        if Gen.Parent and Gen.Enabled then
            local D = Math.GetDist(MyRoot.Position, Gen.Parent.Position)
            if D < Min then Min = D Closest = Gen end
        end
    end
    
    if Closest and Closest.Parent then
        local Pos = Closest.Parent.Position
        if Min > 8 then
            if not Itoshi.State.IsMovingToGen then
                Itoshi.State.IsMovingToGen = true
                task.spawn(function()
                    GeneratorManager.Pathfind(Pos)
                    Itoshi.State.IsMovingToGen = false
                end)
            end
        else
            if Itoshi.Settings.Utility.AutoGenerator.TeleportPrompt then
                fireproximityprompt(Closest)
            else
                fireproximityprompt(Closest)
            end
            GeneratorManager.AutoSkill()
        end
    end
end

-- // 9. PHYSICS ENGINE //
local PhysicsManager = {}

function PhysicsManager.Process(dt)
    if Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
        local Hum = GetHum(LocalPlayer.Character)
        local Root = GetRoot(LocalPlayer.Character)
        if Hum and Root then
            Hum.PlatformStand = true
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
            
            local CF = Camera.CFrame
            local Move = Vector3.zero
            local In = Itoshi.State.Input
            
            if Hum.MoveDirection.Magnitude > 0 then
                Move = Hum.MoveDirection
            else
                if In.W then Move = Move + CF.LookVector end
                if In.S then Move = Move - CF.LookVector end
                if In.A then Move = Move - CF.RightVector end
                if In.D then Move = Move + CF.RightVector end
            end
            
            if Move.Magnitude > 0 then Move = Move.Unit * Itoshi.Settings.Movement.Fly.Speed * 2 end
            local Y = 0
            if In.Up or In.MobileUp then Y = Itoshi.Settings.Movement.Fly.Vertical * 2 end
            if In.Down or In.MobileDown then Y = -Itoshi.Settings.Movement.Fly.Vertical * 2 end
            
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
    
    if Itoshi.Settings.Movement.NoClip.Enabled and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end

-- // 10. UTILITY //
local UtilityManager = {}
function UtilityManager.Process()
    if Itoshi.Settings.Utility.AutoHeal.Enabled and LocalPlayer.Character then
        local Hum = GetHum(LocalPlayer.Character)
        if Hum and Hum.Health < Itoshi.Settings.Utility.AutoHeal.Threshold then
            local T = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if T and (T.Name:lower():find("heal") or T.Name:lower():find("med")) then
                Hum:EquipTool(T)
                T:Activate()
            end
        end
    end
    
    if Itoshi.Settings.Utility.AntiStun.Enabled and LocalPlayer.Character then
        local Hum = GetHum(LocalPlayer.Character)
        if Hum then
            Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            if not Itoshi.Settings.Movement.Fly.Enabled then Hum.PlatformStand = false end
        end
    end
end

-- // 11. UI CONSTRUCTION //
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Initializing Core...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "ColossusCfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabG = Window:CreateTab("Utility", 4483362458)
local TabM = Window:CreateTab("Movement", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

-- Combat Tab
TabC:CreateToggle({Name = "Kill Aura (Rotational)", CurrentValue = Itoshi.Settings.Combat.KillAura.Enabled, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block (Neural)", CurrentValue = Itoshi.Settings.Combat.AutoBlock.Enabled, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateDropdown({Name = "Block Mode", Options = {"Neural", "Aggressive", "Hybrid"}, CurrentOption = "Neural", Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Mode = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Hitbox Reach", CurrentValue = Itoshi.Settings.Combat.Hitbox.Enabled, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Hitbox Size", Range = {5, 50}, Increment = 1, CurrentValue = 20, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

-- Utility Tab
TabG:CreateToggle({Name = "Auto Generator (AI Path)", CurrentValue = Itoshi.Settings.Utility.AutoGenerator.Enabled, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabG:CreateToggle({Name = "Auto Skill Check", CurrentValue = Itoshi.Settings.Utility.AutoGenerator.AutoSkill, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoSkill = v end})
TabG:CreateSlider({Name = "AI Speed", Range = {16, 60}, Increment = 1, CurrentValue = 22, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Speed = v end})
TabG:CreateToggle({Name = "Auto Heal", CurrentValue = Itoshi.Settings.Utility.AutoHeal.Enabled, Callback = function(v) Itoshi.Settings.Utility.AutoHeal.Enabled = v end})
TabG:CreateToggle({Name = "Anti Stun", CurrentValue = Itoshi.Settings.Utility.AntiStun.Enabled, Callback = function(v) Itoshi.Settings.Utility.AntiStun.Enabled = v end})

-- Movement Tab
TabM:CreateToggle({Name = "Fly (CFrame)", CurrentValue = Itoshi.Settings.Movement.Fly.Enabled, Callback = function(v) 
    Itoshi.Settings.Movement.Fly.Enabled = v
    if not v and LocalPlayer.Character then
        local H = GetHum(LocalPlayer.Character)
        local R = GetRoot(LocalPlayer.Character)
        if H then H.PlatformStand = false H:ChangeState(Enum.HumanoidStateType.GettingUp) end
        if R then R.AssemblyLinearVelocity = Vector3.zero end
    end
end})
TabM:CreateSlider({Name = "Fly Speed", Range = {0.1, 10}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Itoshi.Settings.Movement.Fly.Speed = v end})
TabM:CreateToggle({Name = "Speed Hack", CurrentValue = Itoshi.Settings.Movement.Speed.Enabled, Callback = function(v) Itoshi.Settings.Movement.Speed.Enabled = v end})
TabM:CreateSlider({Name = "Speed Val", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Itoshi.Settings.Movement.Speed.Val = v end})
TabM:CreateToggle({Name = "NoClip", CurrentValue = Itoshi.Settings.Movement.NoClip.Enabled, Callback = function(v) Itoshi.Settings.Movement.NoClip.Enabled = v end})

-- Visuals Tab
TabV:CreateToggle({Name = "Show Mobile Buttons", CurrentValue = Itoshi.Settings.Visuals.MobileUI, Callback = function(v) Itoshi.Settings.Visuals.MobileUI = v MobileManager.Init() end})
TabV:CreateToggle({Name = "ESP", CurrentValue = Itoshi.Settings.Visuals.ESP.Enabled, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = Itoshi.Settings.Visuals.Fullbright, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- // 12. LOOPS & BINDINGS //

-- Input
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

-- Render Loop (Fast)
RunService.RenderStepped:Connect(function(dt)
    SecureCall(PhysicsManager.Process, dt)
    SecureCall(CombatManager.Process)
    SecureCall(GeneratorManager.Process)
    SecureCall(UtilityManager.Process)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

-- Cache Loop (Slow)
task.spawn(function()
    while true do
        task.wait(0.5)
        SecureCall(EntityManager.Refresh)
        SecureCall(GeneratorManager.Refresh)
        
        -- ESP Logic
        if Itoshi.Settings.Visuals.ESP.Enabled then
            for _, target in pairs(Itoshi.Cache.Targets) do
                if not Itoshi.Cache.ESP[target] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.Adornee = target
                    hl.Parent = CoreGui
                    Itoshi.Cache.ESP[target] = hl
                end
            end
        else
            for i, v in pairs(Itoshi.Cache.ESP) do v:Destroy() end
            Itoshi.Cache.ESP = {}
        end
    end
end)

Rayfield:LoadConfiguration()
