local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local hookmetamethod = hookmetamethod or function(...) end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

-- // CORE SERVICES //
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
local CollectionService = Services.CollectionService
local ReplicatedStorage = Services.ReplicatedStorage

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // ITOSHI KERNEL CONFIG //
local Itoshi = {
    Signature = "ITOSHI_BYPASS_VMAX",
    Settings = {
        Combat = {
            KillAura = {Enabled = true, Range = 25, Speed = "Hyper", Rotate = true},
            AutoBlock = {Enabled = true, Mode = "Universal", Range = 20, Reaction = 0, Duration = 0.6, AutoFace = true},
            Hitbox = {Enabled = true, Size = 25, Transparency = 0.6, Reach = true}
        },
        Utility = {
            AutoGenerator = {
                Enabled = false, 
                Method = "Pathfinding",
                AutoSkill = true,
                Speed = 22
            },
            AutoHeal = {Enabled = true, Threshold = 40},
            AntiStun = {Enabled = true}
        },
        Visuals = {
            ESP = {Enabled = true, Box = true, Tracer = true},
            GenESP = {Enabled = true, Color = Color3.fromRGB(0, 255, 100)}, -- FIXED
            Fullbright = true,
            MobileUI = true
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        LastAttack = 0,
        Input = {W=false, A=false, S=false, D=false, Up=false, Down=false, MobileUp=false, MobileDown=false},
        Target = nil,
        Waypoints = {},
        IsMovingToGen = false
    },
    Cache = {
        Targets = {},
        Generators = {}, -- Deep Cache
        ESP = {},
        GenESP_Cache = {}
    },
    Keywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action", "heavy"}
}

-- // UTILS & SECURITY //
local function SecureCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local function GetRoot(Char)
    return Char:FindFirstChild("HumanoidRootPart") or Char:FindFirstChild("Torso")
end

local function GetHum(Char)
    return Char:FindFirstChild("Humanoid")
end

-- // KEY SYSTEM //
local function LoadKeySystem()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "ItoshiAuth"
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 320, 0, 150)
    F.Position = UDim2.new(0.5, -160, 0.5, -75)
    F.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    F.BorderSizePixel = 0
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.25, 0)
    B.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    B.TextColor3 = Color3.new(1,1,1)
    B.Text = ""
    B.PlaceholderText = "Enter Key..."
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.65, 0)
    Btn.Text = "INJECT BYPASS"
    Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
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
LoadKeySystem()

-- // DEEP SCAN ENGINE (GENERATOR FIX) //
local Scanner = {}

function Scanner.FindGenerators()
    table.clear(Itoshi.Cache.Generators)
    
    -- Deep Scan Workspace for ANY ProximityPrompt
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            -- Check parent name or Prompt text
            local Name = (v.Parent and v.Parent.Name:lower()) or ""
            local Action = v.ActionText:lower()
            local Object = v.ObjectText:lower()
            
            if Name:find("generator") or Name:find("gen") or 
               Action:find("repair") or Action:find("fix") or 
               Object:find("generator") then
                
                if v.Parent and v.Parent:IsA("BasePart") or v.Parent:IsA("Model") then
                     table.insert(Itoshi.Cache.Generators, v)
                end
            end
        end
    end
end

-- // GENERATOR ESP (VISUAL FIX) //
local Visuals = {}

function Visuals.UpdateGenESP()
    if not Itoshi.Settings.Visuals.GenESP.Enabled then
        for i, v in pairs(Itoshi.Cache.GenESP_Cache) do v:Destroy() end
        Itoshi.Cache.GenESP_Cache = {}
        return
    end

    for _, Prompt in pairs(Itoshi.Cache.Generators) do
        if Prompt.Parent then
            -- Determine the main part to adorn to
            local Adornee = Prompt.Parent
            if Adornee:IsA("Model") then
                Adornee = Adornee.PrimaryPart or Adornee:FindFirstChild("HumanoidRootPart") or Adornee:FindFirstChildWhichIsA("BasePart")
            end
            
            if Adornee and not Itoshi.Cache.GenESP_Cache[Adornee] then
                -- Create ESP
                local B = Instance.new("BillboardGui")
                B.Name = "ItoshiGenESP"
                B.Adornee = Adornee
                B.Size = UDim2.new(0, 100, 0, 50)
                B.StudsOffset = Vector3.new(0, 2, 0)
                B.AlwaysOnTop = true
                B.Parent = CoreGui
                
                local T = Instance.new("TextLabel")
                T.Size = UDim2.new(1, 0, 1, 0)
                T.BackgroundTransparency = 1
                T.Text = "⚡ GEN ⚡"
                T.TextColor3 = Itoshi.Settings.Visuals.GenESP.Color
                T.TextStrokeTransparency = 0
                T.Font = Enum.Font.GothamBlack
                T.TextSize = 14
                T.Parent = B
                
                local H = Instance.new("Highlight")
                H.Adornee = Adornee.Parent -- Highlight the whole model
                H.FillColor = Itoshi.Settings.Visuals.GenESP.Color
                H.OutlineColor = Color3.new(1,1,1)
                H.FillTransparency = 0.7
                H.Parent = CoreGui
                
                Itoshi.Cache.GenESP_Cache[Adornee] = {Gui = B, High = H}
            end
        end
    end
end

-- // PLAYER ESP //
function Visuals.UpdatePlayerESP()
    if not Itoshi.Settings.Visuals.ESP.Enabled then
        for i, v in pairs(Itoshi.Cache.ESP) do v:Destroy() end
        Itoshi.Cache.ESP = {}
        return
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local Char = p.Character
            if not Itoshi.Cache.ESP[p] or Itoshi.Cache.ESP[p].Adornee ~= Char then
                if Itoshi.Cache.ESP[p] then Itoshi.Cache.ESP[p]:Destroy() end
                
                local H = Instance.new("Highlight")
                H.FillColor = Color3.fromRGB(255, 0, 0)
                H.OutlineColor = Color3.fromRGB(255, 255, 255)
                H.FillTransparency = 0.5
                H.Adornee = Char
                H.Parent = CoreGui
                
                Itoshi.Cache.ESP[p] = H
            end
        end
    end
end

function Visuals.Fullbright()
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    end
end

-- // MOBILE MANAGER //
local MobileManager = {}
function MobileManager.Toggle()
    if Itoshi.Cache.MobileGui then Itoshi.Cache.MobileGui:Destroy() Itoshi.Cache.MobileGui = nil end
    if not Itoshi.Settings.Visuals.MobileUI then return end
    
    local S = Instance.new("ScreenGui", CoreGui)
    Itoshi.Cache.MobileGui = S
    
    local function Btn(T, P, F)
        local B = Instance.new("TextButton", S)
        B.Size = UDim2.new(0, 50, 0, 50)
        B.Position = P
        B.BackgroundColor3 = Color3.new(0,0,0)
        B.BackgroundTransparency = 0.5
        B.TextColor3 = Color3.new(1,1,1)
        B.Text = T
        B.MouseButton1Click:Connect(F)
        Instance.new("UICorner", B).CornerRadius = UDim.new(1,0)
    end
    
    Btn("FLY", UDim2.new(0.85, 0, 0.6, 0), function() 
        Itoshi.Settings.Movement.Fly.Enabled = not Itoshi.Settings.Movement.Fly.Enabled
        if not Itoshi.Settings.Movement.Fly.Enabled and LocalPlayer.Character then
            local H = GetHum(LocalPlayer.Character)
            local R = GetRoot(LocalPlayer.Character)
            if H then H.PlatformStand = false H:ChangeState(Enum.HumanoidStateType.GettingUp) end
            if R then R.AssemblyLinearVelocity = Vector3.zero end
        end
    end)
end

-- // COMBAT SYSTEM //
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

function Combat.IsAttacking(Char)
    local Anim = Char:FindFirstChild("Humanoid") and Char.Humanoid:FindFirstChild("Animator")
    if not Anim then return false end
    for _, T in pairs(Anim:GetPlayingAnimationTracks()) do
        if T.Priority.Value >= 2 then return true end -- Action or Higher
        for _, k in pairs(Itoshi.Keywords) do if T.Name:lower():find(k) then return true end end
    end
    return false
end

function Combat.Update()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- KILL AURA
    if Itoshi.Settings.Combat.KillAura.Enabled then
        for _, Target in pairs(Combat.GetTargets()) do
            local TRoot = GetRoot(Target)
            if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.KillAura.Range then
                if Itoshi.Settings.Combat.KillAura.Rotate then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                end
                if tick() - Itoshi.State.LastAttack > 0.05 then
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
        for _, Target in pairs(Combat.GetTargets()) do
            local TRoot = GetRoot(Target)
            if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.AutoBlock.Range then
                if Combat.IsAttacking(Target) and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.2) then
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
    
    -- HITBOX
    if Itoshi.Settings.Combat.Hitbox.Enabled then
        for _, Target in pairs(Combat.GetTargets()) do
            local TRoot = GetRoot(Target)
            if TRoot then
                TRoot.Size = Vector3.new(Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size)
                TRoot.Transparency = Itoshi.Settings.Combat.Hitbox.Transparency
                TRoot.CanCollide = false
                if Itoshi.Settings.Combat.Hitbox.Reach then
                    TRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -3)
                end
            end
        end
    end
end

-- // GENERATOR PATHFINDING //
local GenSys = {}
function GenSys.MoveTo(TargetPos)
    local Char = LocalPlayer.Character
    local Hum = GetHum(Char)
    local Root = GetRoot(Char)
    if not Hum or not Root then return end
    
    Hum.PlatformStand = false
    local Path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    local S, E = pcall(function() Path:ComputeAsync(Root.Position, TargetPos) end)
    
    if S and Path.Status == Enum.PathStatus.Success then
        for _, WP in pairs(Path:GetWaypoints()) do
            if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
            if WP.Action == Enum.PathWaypointAction.Jump then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            Hum:MoveTo(WP.Position)
            if Hum.WalkSpeed < 22 then Hum.WalkSpeed = 22 end
            
            local T = 0
            repeat task.wait(0.1) T=T+0.1 until (Root.Position - WP.Position).Magnitude < 4 or T > 2
        end
    else
        Hum:MoveTo(TargetPos)
    end
end

function GenSys.SkillCheck()
    if not Itoshi.Settings.Utility.AutoGenerator.AutoSkill then return end
    local Gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not Gui then return end
    local function Check(g)
        for _, c in pairs(g:GetDescendants()) do
            if c:IsA("Frame") and c.Visible and (c.Name:lower():find("bar") or c.Name:lower():find("cursor")) then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                return
            end
        end
    end
    for _, g in pairs(Gui:GetChildren()) do if g:IsA("ScreenGui") and g.Enabled then Check(g) end end
end

function GenSys.Update()
    if not Itoshi.Settings.Utility.AutoGenerator.Enabled then 
        Itoshi.State.IsMovingToGen = false
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
            if not Itoshi.State.IsMovingToGen then
                Itoshi.State.IsMovingToGen = true
                task.spawn(function()
                    GenSys.MoveTo(Closest.Parent.Position)
                    Itoshi.State.IsMovingToGen = false
                end)
            end
        else
            LocalPlayer.Character.Humanoid:MoveTo(MyRoot.Position)
            fireproximityprompt(Closest)
            GenSys.SkillCheck()
        end
    end
end

-- // PHYSICS //
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
        local Hum = GetHum(LocalPlayer.Character)
        local Root = GetRoot(LocalPlayer.Character)
        if Hum and Root and Hum.MoveDirection.Magnitude > 0 then
            Root.CFrame = Root.CFrame + (Hum.MoveDirection * Itoshi.Settings.Movement.Speed.Val * dt)
        end
    end
end

-- // INPUT HOOKS //
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

-- // UI //
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Universal Bypass",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabK = Window:CreateTab("Killer", 4483362458)
local TabG = Window:CreateTab("Utility", 4483362458)
local TabM = Window:CreateTab("Movement", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 20, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Hitbox Reach", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Hitbox Size", Range = {5, 50}, Increment = 1, CurrentValue = 20, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

TabK:CreateToggle({Name = "Killer Mode", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Enabled = v end})
TabK:CreateToggle({Name = "Magnet", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Magnet.Enabled = v end})

TabG:CreateToggle({Name = "Auto Generator", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabG:CreateToggle({Name = "Auto Skill Check", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoSkill = v end})

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

TabV:CreateToggle({Name = "Mobile Controls", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.MobileUI = v MobileManager.Toggle() end})
TabV:CreateToggle({Name = "Generator ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.GenESP.Enabled = v end})
TabV:CreateToggle({Name = "Player ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- // MAIN LOOPS //
RunService.RenderStepped:Connect(function(dt)
    SecureCall(Physics.Update, dt)
    SecureCall(Combat.Update)
    SecureCall(GenSys.Update)
    SecureCall(Visuals.Fullbright)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        SecureCall(Combat.RefreshTargets)
        SecureCall(Scanner.FindGenerators)
        SecureCall(Visuals.UpdateGenESP)
        SecureCall(Visuals.UpdatePlayerESP)
    end
end)

Rayfield:LoadConfiguration()
