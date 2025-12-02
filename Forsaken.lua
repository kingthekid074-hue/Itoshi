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
local ProximityPromptService = Services.ProximityPromptService
local ReplicatedStorage = Services.ReplicatedStorage

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = true, Range = 25, Speed = "Hyper", Rotate = true},
            AutoBlock = {Enabled = true, Mode = "Hybrid", Range = 18, Reaction = 0, Duration = 0.5, AutoFace = true},
            Hitbox = {Enabled = true, Size = 20, Transparency = 0.6, Reach = true}
        },
        Utility = {
            AutoGenerator = {
                Enabled = false, 
                Method = "Pathfinding", 
                Speed = 22,
                TeleportPrompt = true
            },
            Puzzles = {
                AutoSkillCheck = true, -- For Spacebar checks
                AutoSolve = true,      -- For Complex Puzzles (Wires/Flow)
                SolveDelay = 1.5       -- Time to wait before solving (Safety)
            },
            AutoHeal = {Enabled = true, Threshold = 40},
            AntiStun = {Enabled = true}
        },
        Visuals = {
            ESP = {Enabled = false},
            MobileUI = false,
            Fullbright = false
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        LastAttack = 0,
        IsMovingToGen = false,
        Solving = false
    },
    Cache = {
        Targets = {},
        Generators = {},
        ESP = {},
        Remotes = {}
    },
    Keywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action"}
}

local function SecureCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local function GetRoot(Char)
    return Char:FindFirstChild("HumanoidRootPart")
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
    F.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.3, 0)
    B.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    B.TextColor3 = Color3.new(1,1,1)
    B.Text = ""
    B.PlaceholderText = "Enter Key..."
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "INJECT SOLVER"
    Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
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

-- MOBILE UI
local MobileManager = {}
function MobileManager.Toggle()
    if Itoshi.Cache.MobileGui then Itoshi.Cache.MobileGui:Destroy() Itoshi.Cache.MobileGui = nil end
    if not Itoshi.Settings.Visuals.MobileUI then return end
    local S = Instance.new("ScreenGui", CoreGui)
    Itoshi.Cache.MobileGui = S
    local function B(T, P, F)
        local Btn = Instance.new("TextButton", S)
        Btn.Size = UDim2.new(0,50,0,50)
        Btn.Position = P
        Btn.BackgroundColor3 = Color3.new(0,0,0)
        Btn.BackgroundTransparency = 0.5
        Btn.TextColor3 = Color3.new(1,1,1)
        Btn.Text = T
        Btn.MouseButton1Click:Connect(F)
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(1,0)
    end
    B("FLY", UDim2.new(0.85, 0, 0.6, 0), function() 
        -- Fly Toggle Logic
    end)
end

-- PUZZLE SOLVER (THE FIX)
local PuzzleSys = {}

function PuzzleSys.FindRemotes()
    -- Scan for puzzle completion remotes
    if not Itoshi.Cache.Remotes.Complete then
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:lower():find("complete") or v.Name:lower():find("finish") or v.Name:lower():find("puzzle")) then
                Itoshi.Cache.Remotes.Complete = v
            end
        end
    end
end

function PuzzleSys.Solve()
    if not Itoshi.Settings.Utility.Puzzles.AutoSolve then return end
    if Itoshi.State.Solving then return end
    
    local Gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not Gui then return end
    
    for _, G in pairs(Gui:GetChildren()) do
        if G:IsA("ScreenGui") and G.Enabled then
            -- Detect Complex Puzzles (Not Skill Checks)
            if G.Name:lower():find("puzzle") or G.Name:lower():find("generator") or G:FindFirstChild("Grid") then
                
                Itoshi.State.Solving = true
                
                -- 1. Wait Safety Delay
                task.wait(Itoshi.Settings.Utility.Puzzles.SolveDelay)
                
                -- 2. Try to find a "Solve" or "Done" remote/function
                PuzzleSys.FindRemotes()
                if Itoshi.Cache.Remotes.Complete then
                    Itoshi.Cache.Remotes.Complete:FireServer(true) -- Try generic boolean
                    Itoshi.Cache.Remotes.Complete:FireServer()     -- Try empty
                else
                    -- 3. Fallback: Click all buttons (Brute Force)
                    for _, B in pairs(G:GetDescendants()) do
                        if (B:IsA("ImageButton") or B:IsA("TextButton")) and B.Visible then
                            local pos = B.AbsolutePosition + (B.AbsoluteSize/2)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                        end
                    end
                end
                
                Itoshi.State.Solving = false
                return
            end
        end
    end
end

function PuzzleSys.SkillCheck()
    if not Itoshi.Settings.Utility.Puzzles.AutoSkillCheck then return end
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

-- GENERATOR LOGIC
local GenSys = {}
function GenSys.Update()
    if not Itoshi.Settings.Utility.AutoGenerator.Enabled then Itoshi.State.IsMovingToGen = false return end
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- Refresh Cache
    if tick() % 1 < 0.1 then
        table.clear(Itoshi.Cache.Generators)
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("repair") or v.ObjectText:lower():find("generator")) and v.Enabled then
                table.insert(Itoshi.Cache.Generators, v)
            end
        end
    end
    
    -- Find Closest
    local Closest, Min = nil, 9999
    for _, G in pairs(Itoshi.Cache.Generators) do
        if G.Parent then
            local D = (MyRoot.Position - G.Parent.Position).Magnitude
            if D < Min then Min = D Closest = G end
        end
    end
    
    if Closest and Closest.Parent then
        local Pos = Closest.Parent.Position
        if Min > 8 then
            -- Move (Safe Pathfinding)
            if not Itoshi.State.IsMovingToGen then
                Itoshi.State.IsMovingToGen = true
                task.spawn(function()
                    local Path = PathfindingService:CreatePath()
                    Path:ComputeAsync(MyRoot.Position, Pos)
                    if Path.Status == Enum.PathStatus.Success then
                        for _, WP in pairs(Path:GetWaypoints()) do
                            if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
                            if WP.Action == Enum.PathWaypointAction.Jump then LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                            LocalPlayer.Character.Humanoid:MoveTo(WP.Position)
                            LocalPlayer.Character.Humanoid.WalkSpeed = Itoshi.Settings.Utility.AutoGenerator.Speed
                            local T=0 repeat task.wait(0.1) T=T+0.1 until (MyRoot.Position-WP.Position).Magnitude<4 or T>2
                        end
                    end
                    Itoshi.State.IsMovingToGen = false
                end)
            end
        else
            -- Interact & Solve
            LocalPlayer.Character.Humanoid:MoveTo(MyRoot.Position)
            if Itoshi.Settings.Utility.AutoGenerator.TeleportPrompt then
                fireproximityprompt(Closest)
            end
            PuzzleSys.SkillCheck()
            PuzzleSys.Solve()
        end
    end
end

-- COMBAT
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

function Combat.Update()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- Kill Aura
    if Itoshi.Settings.Combat.KillAura.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.KillAura.Range then
                if Itoshi.Settings.Combat.KillAura.Rotate then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                end
                if tick() - Itoshi.State.LastAttack > Itoshi.Settings.Combat.KillAura.Speed then
                    local T = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if T then T:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                    Itoshi.State.LastAttack = tick()
                end
                break
            end
        end
    end
    
    -- Auto Block
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        if not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
            for _, Target in pairs(Itoshi.Cache.Targets) do
                local TRoot = GetRoot(Target)
                if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.AutoBlock.Range then
                    -- Check Anim
                    local IsAttacking = false
                    local Anim = Target:FindFirstChild("Humanoid") and Target.Humanoid:FindFirstChild("Animator")
                    if Anim then
                        for _, T in pairs(Anim:GetPlayingAnimationTracks()) do
                            if T.Priority.Value >= 2 then IsAttacking = true break end
                        end
                    end
                    
                    if IsAttacking then
                        if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                        end
                        Itoshi.State.Blocking = true
                        Itoshi.State.LastBlock = tick()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                        task.delay(Itoshi.Settings.Combat.AutoBlock.Duration, function()
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                            Itoshi.State.Blocking = false
                        end)
                        break
                    end
                end
            end
        end
    end
    
    -- Hitbox
    if Itoshi.Settings.Combat.Hitbox.Enabled then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot then
                TRoot.Size = Vector3.new(Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size)
                TRoot.Transparency = Itoshi.Settings.Combat.Hitbox.Transparency
                TRoot.CanCollide = false
                if Itoshi.Settings.Combat.Hitbox.Reach then
                    TRoot.CFrame = MyRoot.CFrame * CFrame.new(0,0,-3)
                end
            end
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Puzzle Solver...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabGen = Window:CreateTab("Puzzles", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateToggle({Name = "Hitbox Reach", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})

TabGen:CreateSection("Generator")
TabGen:CreateToggle({Name = "Auto Generator (Walk)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabGen:CreateSlider({Name = "Walk Speed", Range = {16, 50}, Increment = 1, CurrentValue = 22, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Speed = v end})

TabGen:CreateSection("Solver")
TabGen:CreateToggle({Name = "Auto Skill Check (Space)", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.Puzzles.AutoSkillCheck = v end})
TabGen:CreateToggle({Name = "Auto Solve Puzzles (Complex)", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.Puzzles.AutoSolve = v end})
TabGen:CreateSlider({Name = "Solve Delay (Safety)", Range = {0, 5}, Increment = 0.5, CurrentValue = 1.5, Callback = function(v) Itoshi.Settings.Utility.Puzzles.SolveDelay = v end})

TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- LOOPS
RunService.RenderStepped:Connect(function()
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
        task.wait(0.5)
        SecureCall(Combat.RefreshTargets)
        
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
