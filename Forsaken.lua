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

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIG
local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = false, Range = 25, Rotate = true},
            AutoBlock = {
                Enabled = false, 
                Range = 20, 
                BlockTime = 0.6, 
                DetectSound = true, 
                DetectAnim = true
            },
            Hitbox = {Enabled = false, Size = 5, Transparency = 0.5} -- Small size to be safe/legit
        },
        Killer = {
            Enabled = false,
            Magnet = {Enabled = false, Force = 0.5},
        },
        Visuals = {
            ESP = {Enabled = false},
            Fullbright = false
        },
        Utility = {
            AutoHeal = {Enabled = false}
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        Target = nil
    },
    Cache = {
        ESP = {},
        Sounds = {}
    }
}

-- AUTH
local KeySystem = {}
function KeySystem.Run()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "ItoshiAuth"
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 300, 0, 150)
    F.Position = UDim2.new(0.5, -150, 0.5, -75)
    F.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.3, 0)
    B.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    B.TextColor3 = Color3.new(1,1,1)
    B.PlaceholderText = "Key..."
    B.Text = ""
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "INJECT"
    Btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
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

-- TARGET SYSTEM
local Combat = {}
function Combat.GetTargets()
    local T = {}
    -- Players
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then table.insert(T, p.Character) end
    end
    -- NPCs (Killers/Monsters)
    if tick() % 0.5 < 0.1 then -- Optimization
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(v) then
                table.insert(T, v)
            end
        end
    end
    return T
end

function Combat.Block()
    if Itoshi.State.Blocking or (tick() - Itoshi.State.LastBlock < 0.2) then return end
    Itoshi.State.Blocking = true
    Itoshi.State.LastBlock = tick()
    
    -- Press F
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    
    -- Hold
    task.delay(Itoshi.Settings.Combat.AutoBlock.BlockTime, function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        Itoshi.State.Blocking = false
    end)
end

function Combat.CheckThreats()
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end

    for _, Enemy in pairs(Combat.GetTargets()) do
        local ERoot = Enemy:FindFirstChild("HumanoidRootPart")
        local EHum = Enemy:FindFirstChild("Humanoid")
        
        if ERoot and EHum and EHum.Health > 0 then
            local Dist = (MyRoot.Position - ERoot.Position).Magnitude
            
            if Dist <= Itoshi.Settings.Combat.AutoBlock.Range then
                -- 1. ANIMATION DETECTION (Universal)
                if Itoshi.Settings.Combat.AutoBlock.DetectAnim then
                    local Anim = EHum:FindFirstChild("Animator")
                    if Anim then
                        for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
                            -- Detect ANY Action/Attack Priority
                            if Track.Priority == Enum.AnimationPriority.Action or 
                               Track.Priority == Enum.AnimationPriority.Action2 or 
                               Track.Priority == Enum.AnimationPriority.Action3 then
                                Combat.Block()
                                return -- Block once is enough
                            end
                        end
                    end
                end
                
                -- 2. AUDIO DETECTION (Experimental)
                if Itoshi.Settings.Combat.AutoBlock.DetectSound then
                    -- Listen to sounds played in RootPart or Head
                    for _, Part in pairs({ERoot, Enemy:FindFirstChild("Head")}) do
                        if Part then
                            for _, S in pairs(Part:GetChildren()) do
                                if S:IsA("Sound") and S.Playing and S.Volume > 0.5 then
                                    -- Check if sound just started playing
                                    if not Itoshi.Cache.Sounds[S] or (tick() - Itoshi.Cache.Sounds[S] > 1) then
                                        Itoshi.Cache.Sounds[S] = tick()
                                        Combat.Block()
                                        return
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

function Combat.RunKillAura()
    if not Itoshi.Settings.Combat.KillAura.Enabled then return end
    
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    
    for _, Enemy in pairs(Combat.GetTargets()) do
        local ERoot = Enemy:FindFirstChild("HumanoidRootPart")
        if ERoot then
            local Dist = (MyRoot.Position - ERoot.Position).Magnitude
            if Dist <= Itoshi.Settings.Combat.KillAura.Range then
                -- Auto Rotate (Face Enemy)
                if Itoshi.Settings.Combat.KillAura.Rotate then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(ERoot.Position.X, MyRoot.Position.Y, ERoot.Position.Z))
                end
                
                -- Attack
                local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if Tool then Tool:Activate() end
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                break -- Focus one target
            end
        end
    end
end

function Combat.KillerLogic()
    if not Itoshi.Settings.Killer.Enabled then return end
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    
    -- Find closest survivor
    local Target = nil
    local MinDist = 100
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local Dist = (MyRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if Dist < MinDist then
                MinDist = Dist
                Target = p.Character.HumanoidRootPart
            end
        end
    end
    
    if Target then
        -- MAGNET (Safe CFrame Lerp)
        if Itoshi.Settings.Killer.Magnet.Enabled then
            local Dir = (Target.Position - MyRoot.Position).Unit
            MyRoot.CFrame = MyRoot.CFrame + (Dir * Itoshi.Settings.Killer.Magnet.Force)
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Loading Warlord...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabK = Window:CreateTab("Killer", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)
local TabU = Window:CreateTab("Utility", 4483362458)

TabC:CreateToggle({Name = "Kill Aura (OP)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block (Ultimate)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateToggle({Name = "Use Audio Detection", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.DetectSound = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 40}, Increment = 1, CurrentValue = 20, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Legit Hitbox (5 studs)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})

TabK:CreateToggle({Name = "Killer Mode", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Enabled = v end})
TabK:CreateToggle({Name = "Magnet (Chase Assist)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Killer.Magnet.Enabled = v end})
TabK:CreateSlider({Name = "Magnet Force", Range = {0.1, 1}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Itoshi.Settings.Killer.Magnet.Force = v end})

TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Visuals.Fullbright = v
    if v then Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.GlobalShadows=false Lighting.Ambient=Color3.new(1,1,1) end
end})

TabU:CreateToggle({Name = "Auto Heal", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoHeal.Enabled = v end})

-- LOOPS
RunService.RenderStepped:Connect(function()
    SecureCall(Combat.CheckThreats) -- Auto Block (Needs speed)
    SecureCall(Combat.RunKillAura)
    SecureCall(Combat.KillerLogic)
    
    -- Hitbox Logic
    if Itoshi.Settings.Combat.Hitbox.Enabled then
        for _, t in pairs(Combat.GetTargets()) do
            local r = t:FindFirstChild("HumanoidRootPart")
            if r then r.Size = Vector3.new(5,5,5) r.Transparency = 0.7 r.CanCollide = false end
        end
    end
end)

-- ESP LOOP
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
