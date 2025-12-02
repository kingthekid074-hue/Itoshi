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
local ReplicatedStorage = Services.ReplicatedStorage
local Stats = Services.Stats
local Debris = Services.Debris

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // 2. THE DATABASE (SOUNDS & ANIMS) //
-- Extracted from top-tier scripts for maximum detection
local Database = {
    Sounds = {
        ["102228729296384"] = true, ["140242176732868"] = true, ["112809109188560"] = true,
        ["136323728355613"] = true, ["115026634746636"] = true, ["84116622032112"] = true,
        ["108907358619313"] = true, ["127793641088496"] = true, ["86174610237192"] = true,
        ["95079963655241"] = true, ["101199185291628"] = true, ["119942598489800"] = true,
        ["84307400688050"] = true, ["113037804008732"] = true, ["105200830849301"] = true,
        ["75330693422988"] = true, ["82221759983649"] = true, ["81702359653578"] = true,
        ["108610718831698"] = true, ["112395455254818"] = true, ["109431876587852"] = true,
        ["109348678063422"] = true, ["85853080745515"] = true, ["12222216"] = true
    },
    Anims = {
        "126830014841198", "126355327951215", "121086746534252", "18885909645",
        "98456918873918", "105458270463374", "83829782357897", "125403313786645",
        "118298475669935", "82113744478546", "70371667919898", "99135633258223"
    },
    Keywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action"}
}

-- // 3. CONFIGURATION //
local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = true, Range = 25, Speed = "Hyper", Rotate = true},
            AutoBlock = {
                Enabled = true, 
                Mode = "Hybrid", -- Sound + Anim + Distance
                Range = 25, 
                Reaction = 0, 
                Duration = 0.8, 
                AutoFace = true,
                Predict = true
            },
            Hitbox = {Enabled = true, Size = 25, Transparency = 0.6, Reach = true}
        },
        Utility = {
            AutoGenerator = {
                Enabled = false, 
                Method = "Pathfinding", -- Safe Walk
                AutoSkill = true,       -- Spacebar
                AutoWires = true,       -- Connecting dots
                Speed = 22
            },
            AutoHeal = {Enabled = true, Threshold = 40},
            AntiStun = {Enabled = true}
        },
        Movement = { -- Optional/Manual
            Fly = {Enabled = false, Speed = 1},
            Speed = {Enabled = false, Val = 0.5},
            NoClip = {Enabled = false}
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
        IsMovingToGen = false,
        SolvedWires = {}
    },
    Cache = {
        Targets = {},
        Generators = {},
        ESP = {},
        SoundHooks = {}
    }
}

-- // 4. CORE FUNCTIONS //
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

-- // 5. AUTHENTICATION //
local function LoadKeySystem()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "Itoshi key system"
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 320, 0, 160)
    F.Position = UDim2.new(0.5, -160, 0.5, -80)
    F.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.3, 0)
    B.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    B.TextColor3 = Color3.new(1,1,1)
    B.Text = ""
    B.PlaceholderText = "Key..."
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "verify"
    Btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
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

-- // 6. GENERATOR AI (PUZZLE SOLVER) //
local GenSys = {}

function GenSys.SolveWires()
    if not Itoshi.Settings.Utility.AutoGenerator.AutoWires then return end
    local Gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not Gui then return end
    
    -- Intelligent UI Scanner
    for _, G in pairs(Gui:GetChildren()) do
        if G:IsA("ScreenGui") and G.Enabled then
            -- Wires Logic (Color Matching)
            local Colors = {}
            for _, B in pairs(G:GetDescendants()) do
                if (B:IsA("ImageButton") or B:IsA("TextButton")) and B.Visible then
                    local Col = tostring(B.BackgroundColor3)
                    if not Colors[Col] then Colors[Col] = {} end
                    table.insert(Colors[Col], B)
                end
            end
            
            for _, Pair in pairs(Colors) do
                if #Pair == 2 then
                    -- Simulate Drag/Click
                    local P1 = Pair[1].AbsolutePosition + (Pair[1].AbsoluteSize/2)
                    local P2 = Pair[2].AbsolutePosition + (Pair[2].AbsoluteSize/2)
                    
                    VirtualInputManager:SendMouseButtonEvent(P1.X, P1.Y+30, 0, true, game, 1)
                    task.wait()
                    VirtualInputManager:SendMouseButtonEvent(P1.X, P1.Y+30, 0, false, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(P2.X, P2.Y+30, 0, true, game, 1)
                    task.wait()
                    VirtualInputManager:SendMouseButtonEvent(P2.X, P2.Y+30, 0, false, game, 1)
                end
            end
        end
    end
end

function GenSys.SkillCheck()
    if not Itoshi.Settings.Utility.AutoGenerator.AutoSkill then return end
    local Gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not Gui then return end
    
    for _, G in pairs(Gui:GetChildren()) do
        if G:IsA("ScreenGui") and G.Enabled then
            -- Look for Bar/Cursor
            local Bar = G:FindFirstChild("Bar", true) or G:FindFirstChild("Cursor", true) or G:FindFirstChild("Pointer", true)
            if Bar and Bar.Visible then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end
    end
end

function GenSys.MoveTo(TargetPos)
    local Char = LocalPlayer.Character
    local Hum = GetHum(Char)
    local Root = GetRoot(Char)
    if not Hum or not Root then return end
    
    Hum.PlatformStand = false
    
    -- Advanced Pathfinding
    local Path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4
    })
    
    local S, E = pcall(function() Path:ComputeAsync(Root.Position, TargetPos) end)
    
    if S and Path.Status == Enum.PathStatus.Success then
        for _, WP in pairs(Path:GetWaypoints()) do
            if not Itoshi.Settings.Utility.AutoGenerator.Enabled then break end
            
            if WP.Action == Enum.PathWaypointAction.Jump then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            Hum:MoveTo(WP.Position)
            
            -- Speed Limit
            if Hum.WalkSpeed < 22 then Hum.WalkSpeed = 22 end
            
            local T = 0
            repeat task.wait(0.1) T=T+0.1 until (Root.Position - WP.Position).Magnitude < 4 or T > 2
        end
    else
        Hum:MoveTo(TargetPos)
    end
end

function GenSys.Update()
    if not Itoshi.Settings.Utility.AutoGenerator.Enabled then return end
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- Refresh Generators
    if tick() % 1 < 0.1 then
        table.clear(Itoshi.Cache.Generators)
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("repair") or v.ObjectText:lower():find("generator")) and v.Enabled then
                table.insert(Itoshi.Cache.Generators, v)
            end
        end
    end
    
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
            if not Itoshi.State.IsMovingToGen then
                Itoshi.State.IsMovingToGen = true
                task.spawn(function()
                    GenSys.MoveTo(Pos)
                    Itoshi.State.IsMovingToGen = false
                end)
            end
        else
            -- Interaction
            LocalPlayer.Character.Humanoid:MoveTo(MyRoot.Position)
            fireproximityprompt(Closest)
            GenSys.SkillCheck()
            GenSys.SolveWires()
        end
    end
end

-- // 7. COMBAT SYSTEM (HYBRID) //
local Combat = {}

function Combat.ExtractSoundID(Sound)
    if not Sound then return nil end
    return Sound.SoundId:match("%d+")
end

function Combat.IsAttacking(Target)
    -- 1. Sound Detection (FAST)
    local Root = GetRoot(Target)
    if Root then
        for _, S in pairs(Root:GetChildren()) do
            if S:IsA("Sound") and S.Playing then
                local ID = Combat.ExtractSoundID(S)
                if Database.Sounds[ID] then
                    if not Itoshi.Cache.SoundHooks[S] or (tick() - Itoshi.Cache.SoundHooks[S] > 0.5) then
                        Itoshi.Cache.SoundHooks[S] = tick()
                        return true
                    end
                end
            end
        end
    end
    
    -- 2. Animation Detection (BACKUP)
    local Hum = GetHum(Target)
    local Anim = Hum and Hum:FindFirstChild("Animator")
    if Anim then
        for _, T in pairs(Anim:GetPlayingAnimationTracks()) do
            local Name = T.Name:lower()
            local ID = T.Animation.AnimationId:match("%d+")
            
            -- Check ID or Keywords or Priority
            if Database.Anims[ID] then return true end
            if T.Priority.Value >= 2 then
                for _, K in pairs(Itoshi.Keywords) do
                    if string.find(Name, K) then return true end
                end
            end
        end
    end
    return false
end

function Combat.Update()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- Refresh Targets (Slowly)
    if tick() % 0.5 < 0.1 then
        table.clear(Itoshi.Cache.Targets)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then table.insert(Itoshi.Cache.Targets, p.Character) end
        end
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) and v ~= LocalPlayer.Character then
                table.insert(Itoshi.Cache.Targets, v)
            end
        end
    end

    -- Logic
    for _, Target in pairs(Itoshi.Cache.Targets) do
        local TRoot = GetRoot(Target)
        if TRoot then
            local Dist = (MyRoot.Position - TRoot.Position).Magnitude
            
            -- KILL AURA
            if Itoshi.Settings.Combat.KillAura.Enabled and Dist <= Itoshi.Settings.Combat.KillAura.Range then
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
            end
            
            -- AUTO BLOCK
            if Itoshi.Settings.Combat.AutoBlock.Enabled and Dist <= Itoshi.Settings.Combat.AutoBlock.Range then
                if Combat.IsAttacking(Target) and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
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
                end
            end
            
            -- HITBOX REACH
            if Itoshi.Settings.Combat.Hitbox.Enabled then
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

-- // 8. UI //
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Masterpiece Loaded",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabGen = Window:CreateTab("Utility", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block (Sound+Anim)", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = 25, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Hitbox Reach", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Hitbox Size", Range = {2, 50}, Increment = 1, CurrentValue = 20, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

TabGen:CreateSection("Engineer AI")
TabGen:CreateToggle({Name = "Auto Generator (Pathfind)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabGen:CreateToggle({Name = "Auto Skill Check", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoSkill = v end})
TabGen:CreateToggle({Name = "Auto Wire Solver", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoWires = v end})
TabGen:CreateToggle({Name = "Auto Heal", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoHeal.Enabled = v end})

TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- // 9. LOOPS //
RunService.RenderStepped:Connect(function()
    SecureCall(Combat.Update)
    SecureCall(GenSys.Update)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

-- ESP Loop
task.spawn(function()
    while true do
        task.wait(0.5)
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
