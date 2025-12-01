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
                Mode = "Aggressive",
                Range = 25, 
                Reaction = 0, 
                Duration = 0.8, 
                AutoFace = true,
                CheckFacing = false 
            },
            Hitbox = {
                Enabled = true, 
                Size = 25, 
                Transparency = 0.6, 
                Reach = true, 
                Backtrack = true
            },
            Resolver = {Enabled = true}
        },
        Killer = {
            Enabled = false,
            Magnet = {Enabled = false, Speed = 0.8},
            Reach = {Enabled = false, Multiplier = 2}
        },
        Movement = {
            Fly = {Enabled = false, Speed = 1, Vertical = 1, Mode = "CFrame"}, 
            Speed = {Enabled = false, Val = 0.5, Mode = "CFrame"},
            NoClip = {Enabled = false},
            AntiAim = {Enabled = false}
        },
        Utility = {
            AutoGenerator = {
                Enabled = false, 
                Method = "Pathfinding",
                AutoSkill = true,
                Dist = 2000
            },
            AutoHeal = {Enabled = false, Threshold = 35},
            AntiStun = {Enabled = true}
        },
        Visuals = {
            ESP = {Enabled = false, Box = true, Tracer = false, Name = true},
            Chams = {Enabled = false, Fill = Color3.fromRGB(255, 0, 0), Outline = Color3.fromRGB(255, 255, 255)},
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
        IsMovingToGen = false
    },
    Cache = {
        Targets = {},
        Generators = {},
        ESP = {},
        Animations = {},
        Connections = {}
    },
    Constants = {
        SafeAnims = {
            ["idle"] = true, ["walk"] = true, ["run"] = true, ["jump"] = true, ["fall"] = true, ["climb"] = true, ["equip"] = true
        }
    }
}

local Signal = {}
Signal.__index = Signal
function Signal.new()
    local self = setmetatable({}, Signal)
    self._bindable = Instance.new("BindableEvent")
    return self
end
function Signal:Connect(callback)
    return self._bindable.Event:Connect(callback)
end
function Signal:Fire(...)
    self._bindable:Fire(...)
end

local Janitor = {}
Janitor.__index = Janitor
function Janitor.new()
    return setmetatable({_objects = {}}, Janitor)
end
function Janitor:Add(object)
    table.insert(self._objects, object)
end
function Janitor:Clean()
    for _, obj in pairs(self._objects) do
        if typeof(obj) == "RBXScriptConnection" then
            obj:Disconnect()
        elseif type(obj) == "function" then
            obj()
        elseif typeof(obj) == "Instance" then
            obj:Destroy()
        end
    end
    self._objects = {}
end

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

local KeySystem = {}
function KeySystem.Run()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "ItoshiAuth"
    S.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 320, 0, 160)
    F.Position = UDim2.new(0.5, -160, 0.5, -80)
    F.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    F.BorderSizePixel = 0
    F.Parent = S
    
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    }
    UIGradient.Rotation = 45
    UIGradient.Parent = F
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = F
    
    local Title = Instance.new("TextLabel")
    Title.Text = "ITOSHI HUB | SUPREME"
    Title.Size = UDim2.new(1, 0, 0.25, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 50, 50)
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 20
    Title.Parent = F
    
    local KeyBox = Instance.new("TextBox")
    KeyBox.Size = UDim2.new(0.8, 0, 0.25, 0)
    KeyBox.Position = UDim2.new(0.1, 0, 0.35, 0)
    KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.PlaceholderText = "Enter Key..."
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.Text = ""
    KeyBox.Parent = F
    local KeyCorner = Instance.new("UICorner")
    KeyCorner.CornerRadius = UDim.new(0, 6)
    KeyCorner.Parent = KeyBox
    
    local AuthBtn = Instance.new("TextButton")
    AuthBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
    AuthBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
    AuthBtn.Text = "AUTHENTICATE"
    AuthBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    AuthBtn.TextColor3 = Color3.new(1,1,1)
    AuthBtn.Font = Enum.Font.GothamBold
    AuthBtn.Parent = F
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = AuthBtn
    
    local Validated = false
    AuthBtn.MouseButton1Click:Connect(function()
        if KeyBox.Text == "FFDGDLFYUFOHDWHHFXX" then
            Validated = true
            getgenv().ItoshiAuth = true
            S:Destroy()
        else
            KeyBox.Text = "INVALID KEY"
            task.wait(1)
            KeyBox.Text = ""
        end
    end)
    repeat task.wait(0.1) until Validated
end
KeySystem.Run()

local MobileManager = {}
function MobileManager.Init()
    if Itoshi.Cache.MobileGui then Itoshi.Cache.MobileGui:Destroy() end
    if not Itoshi.Settings.Visuals.MobileUI then return end
    
    local S = Instance.new("ScreenGui")
    S.Name = "ItoshiMobileControls"
    S.Parent = CoreGui
    Itoshi.Cache.MobileGui = S
    
    local function CreateButton(Text, Position, CallbackDown, CallbackUp)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 55, 0, 55)
        Btn.Position = Position
        Btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Btn.BackgroundTransparency = 0.5
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.Text = Text
        Btn.TextSize = 24
        Btn.Font = Enum.Font.GothamBold
        Btn.Parent = S
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = Btn
        
        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(255, 0, 0)
        Stroke.Thickness = 2
        Stroke.Parent = Btn
        
        Btn.MouseButton1Down:Connect(CallbackDown)
        Btn.MouseButton1Up:Connect(CallbackUp)
        Btn.MouseLeave:Connect(CallbackUp)
    end
    
    CreateButton("▲", UDim2.new(0.85, 0, 0.5, 0), 
        function() Itoshi.State.Input.MobileUp = true end, 
        function() Itoshi.State.Input.MobileUp = false end
    )
    
    CreateButton("▼", UDim2.new(0.85, 0, 0.65, 0), 
        function() Itoshi.State.Input.MobileDown = true end, 
        function() Itoshi.State.Input.MobileDown = false end
    )
    
    CreateButton("FLY", UDim2.new(0.7, 0, 0.575, 0), 
        function() 
            Itoshi.Settings.Movement.Fly.Enabled = not Itoshi.Settings.Movement.Fly.Enabled 
            if not Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
                local Hum = GetHum(LocalPlayer.Character)
                local Root = GetRoot(LocalPlayer.Character)
                if Hum then Hum.PlatformStand = false Hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
                if Root then Root.AssemblyLinearVelocity = Vector3.zero end
            end
        end, 
        function() end
    )
end

local TargetManager = {}
function TargetManager.Refresh()
    table.clear(Itoshi.Cache.Targets)
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local Hum = GetHum(v.Character)
            local Root = GetRoot(v.Character)
            if Hum and Root and Hum.Health > 0 then
                table.insert(Itoshi.Cache.Targets, v.Character)
            end
        end
    end
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) and v ~= LocalPlayer.Character then
            local Hum = GetHum(v)
            local Root = GetRoot(v)
            if Hum and Root and Hum.Health > 0 then
                table.insert(Itoshi.Cache.Targets, v)
            end
        end
    end
end

local CombatManager = {}

function CombatManager.GetClosest()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return nil end
    
    local Closest = nil
    local MinDist = math.huge
    
    for _, Target in pairs(Itoshi.Cache.Targets) do
        local TRoot = GetRoot(Target)
        if TRoot then
            local Dist = (MyRoot.Position - TRoot.Position).Magnitude
            if Dist < MinDist then
                MinDist = Dist
                Closest = Target
            end
        end
    end
    return Closest
end

function CombatManager.IsAttacking(Target)
    if not Target then return false end
    local Hum = GetHum(Target)
    if not Hum then return false end
    local Anim = Hum:FindFirstChild("Animator")
    if not Anim then return false end
    
    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
        local Name = Track.Name:lower()
        local IsSafe = false
        
        for SafeAnim, _ in pairs(Itoshi.Constants.SafeAnims) do
            if string.find(Name, SafeAnim) then
                IsSafe = true
                break
            end
        end
        
        if not IsSafe then
            if Track.Priority == Enum.AnimationPriority.Action or 
               Track.Priority == Enum.AnimationPriority.Action2 or 
               Track.Priority == Enum.AnimationPriority.Action3 or
               Track.Priority == Enum.AnimationPriority.Movement then
                return true
            end
        end
    end
    return false
end

function CombatManager.Update()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- KILL AURA (ROTATIONAL & R-KEY)
    if Itoshi.Settings.Combat.KillAura.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot then
                local Dist = (MyRoot.Position - TRoot.Position).Magnitude
                if Dist <= Itoshi.Settings.Combat.KillAura.Range then
                    if Itoshi.Settings.Combat.KillAura.Rotate then
                        MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                    end
                    
                    if tick() - Itoshi.State.LastAttack > 0.05 then -- 20 CPS Cap
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                        Itoshi.State.LastAttack = tick()
                    end
                    break
                end
            end
        end
    end
    
    -- AUTO BLOCK (AGGRESSIVE & Q-KEY)
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot then
                local Dist = (MyRoot.Position - TRoot.Position).Magnitude
                if Dist <= Itoshi.Settings.Combat.AutoBlock.Range then
                    
                    local ShouldBlock = false
                    
                    -- Mode Logic
                    if Itoshi.Settings.Combat.AutoBlock.Mode == "Aggressive" then
                        if CombatManager.IsAttacking(Target) then ShouldBlock = true end
                    elseif Itoshi.Settings.Combat.AutoBlock.Mode == "Hybrid" then
                        if CombatManager.IsAttacking(Target) or Dist < 8 then ShouldBlock = true end
                    end
                    
                    -- Facing Logic
                    if Itoshi.Settings.Combat.AutoBlock.CheckFacing then
                        local Vec = (MyRoot.Position - TRoot.Position).Unit
                        local Dot = TRoot.CFrame.LookVector:Dot(Vec)
                        if Dot < 0.5 then ShouldBlock = false end
                    end
                    
                    if ShouldBlock and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
                        if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                        end
                        
                        task.wait(Itoshi.Settings.Combat.AutoBlock.Reaction)
                        
                        Itoshi.State.Blocking = true
                        Itoshi.State.LastBlock = tick()
                        
                        -- Press Q
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
    
    -- HITBOX (SILENT REACH / EXPANDER)
    if Itoshi.Settings.Combat.Hitbox.Enabled then
        local Size = Itoshi.Settings.Combat.Hitbox.Size
        local Trans = Itoshi.Settings.Combat.Hitbox.Transparency
        
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot then
                TRoot.Size = Vector3.new(Size, Size, Size)
                TRoot.Transparency = Trans
                TRoot.CanCollide = false
                
                if Itoshi.Settings.Combat.Hitbox.Reach then
                    -- Client-Side Reach: Teleport enemy hitbox to player
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
            local Text = (v.ActionText .. v.ObjectText):lower()
            if Text:find("repair") or Text:find("generator") then
                table.insert(Itoshi.Cache.Generators, v)
            end
        end
    end
end

function GeneratorManager.PathfindTo(TargetPos)
    local Char = LocalPlayer.Character
    local Hum = GetHum(Char)
    local Root = GetRoot(Char)
    if not Hum or not Root then return end
    
    Hum.PlatformStand = false
    
    local Path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })
    
    local Success, Error = pcall(function()
        Path:ComputeAsync(Root.Position, TargetPos)
    end)
    
    if Success and Path.Status == Enum.PathStatus.Success then
        local Waypoints = Path:GetWaypoints()
        for _, Point in pairs(Waypoints) do
            if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
            
            if Point.Action == Enum.PathWaypointAction.Jump then
                Hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            Hum:MoveTo(Point.Position)
            local TimeOut = 0
            repeat 
                task.wait(0.1)
                TimeOut = TimeOut + 0.1
                -- Speed Boost during walk
                if Hum.WalkSpeed < 25 then Hum.WalkSpeed = 25 end
            until (Root.Position - Point.Position).Magnitude < 4 or TimeOut > 2
        end
    else
        -- Fallback: Direct Movement
        Hum:MoveTo(TargetPos)
    end
end

function GeneratorManager.HandleSkillCheck()
    if not Itoshi.Settings.Utility.AutoGenerator.AutoSkill then return end
    local Gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not Gui then return end
    
    for _, G in pairs(Gui:GetChildren()) do
        if G:IsA("ScreenGui") and G.Enabled then
            -- Generic Skill Check Finder
            local Bar = G:FindFirstChild("Bar", true) or G:FindFirstChild("Cursor", true) or G:FindFirstChild("Indicator", true)
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
    
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    local Closest, MinDist = nil, math.huge
    for _, Prompt in pairs(Itoshi.Cache.Generators) do
        if Prompt.Parent and Prompt.Enabled then
            local D = (MyRoot.Position - Prompt.Parent.Position).Magnitude
            if D < MinDist then MinDist = D Closest = Prompt end
        end
    end
    
    if Closest and Closest.Parent then
        local GPos = Closest.Parent.Position
        
        if MinDist > 8 then
            if not Itoshi.State.IsMovingToGen then
                Itoshi.State.IsMovingToGen = true
                task.spawn(function()
                    GeneratorManager.PathfindTo(GPos)
                    Itoshi.State.IsMovingToGen = false
                end)
            end
        else
            fireproximityprompt(Closest)
            GeneratorManager.HandleSkillCheck()
        end
    end
end

local PhysicsManager = {}
function PhysicsManager.Update(dt)
    -- FLY (CFRAME STEP)
    if Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
        local Hum = GetHum(LocalPlayer.Character)
        local Root = GetRoot(LocalPlayer.Character)
        if Hum and Root then
            Hum.PlatformStand = true
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
            
            local CF = Camera.CFrame
            local Move = Vector3.zero
            
            -- Hybrid Input
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
            
            Root.CFrame = Root.CFrame + (Move * dt * 50) + (Vector3.new(0, Y, 0) * dt * 50)
        end
    end

    -- SPEED (CFRAME PUSH)
    if Itoshi.Settings.Movement.Speed.Enabled and LocalPlayer.Character and not Itoshi.Settings.Movement.Fly.Enabled then
        local Hum = GetHum(LocalPlayer.Character)
        local Root = GetRoot(LocalPlayer.Character)
        if Hum and Root and Hum.MoveDirection.Magnitude > 0 then
            Root.CFrame = Root.CFrame + (Hum.MoveDirection * Itoshi.Settings.Movement.Speed.Val * dt)
        end
    end
    
    -- NOCLIP
    if Itoshi.Settings.Movement.NoClip.Enabled and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end

-- HOOKS & ANTI-STUN
local Hooks = {}
function Hooks.Init()
    local OldIndex, OldNameCall
    
    OldIndex = hookmeta(game, "__index", newcclosure(function(self, k)
        if Itoshi.Settings.Utility.AntiStun.Enabled and k == "PlatformStand" and not Itoshi.Settings.Movement.Fly.Enabled then
            return false -- Prevent getting stunned/ragdolled
        end
        return OldIndex(self, k)
    end))
end
Hooks.Init()

-- INPUT HANDLING
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

-- UI SETUP
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Warlord System",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "UltimateCfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabGen = Window:CreateTab("Utility", 4483362458)
local TabM = Window:CreateTab("Movement", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura (R)", CurrentValue = Itoshi.Settings.Combat.KillAura.Enabled, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block (Q)", CurrentValue = Itoshi.Settings.Combat.AutoBlock.Enabled, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateDropdown({Name = "Block Mode", Options = {"Aggressive", "Hybrid"}, CurrentOption = "Aggressive", Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Mode = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Hitbox Reach", CurrentValue = Itoshi.Settings.Combat.Hitbox.Enabled, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Reach Size", Range = {2, 50}, Increment = 1, CurrentValue = 20, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

TabGen:CreateToggle({Name = "Auto Generator (Walk)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabGen:CreateToggle({Name = "Auto Skill Check", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoSkill = v end})
TabGen:CreateToggle({Name = "Anti-Stun", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AntiStun.Enabled = v end})

TabM:CreateToggle({Name = "Fly (CFrame)", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Movement.Fly.Enabled = v 
    if not v and LocalPlayer.Character then
        local Hum = GetHum(LocalPlayer.Character)
        local Root = GetRoot(LocalPlayer.Character)
        if Hum then Hum.PlatformStand = false Hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        if Root then Root.AssemblyLinearVelocity = Vector3.zero end
    end
end})
TabM:CreateSlider({Name = "Fly Speed", Range = {0.1, 10}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Itoshi.Settings.Movement.Fly.Speed = v end})
TabM:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.Speed.Enabled = v end})
TabM:CreateSlider({Name = "Speed Val", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Itoshi.Settings.Movement.Speed.Val = v end})
TabM:CreateToggle({Name = "NoClip", CurrentValue = false, Callback = function(v) Itoshi.Settings.Movement.NoClip.Enabled = v end})

TabV:CreateToggle({Name = "Show Mobile Buttons", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.MobileUI = v MobileManager.Init() end})
TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- LOOPS
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
        task.wait(1)
        SecureCall(TargetManager.Refresh)
        SecureCall(GeneratorManager.Refresh)
        
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
