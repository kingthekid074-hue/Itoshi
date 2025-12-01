local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

-- SERVICES
local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local CoreGui = Services.CoreGui
local VirtualInputManager = Services.VirtualInputManager
local Lighting = Services.Lighting

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIG
local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = false, Range = 22, Speed = 0.1},
            AutoBlock = {Enabled = false, Range = 20, Reaction = 0, Duration = 0.5, AutoFace = true},
            Hitbox = {Enabled = false, Size = 15, Transparency = 0.8}
        },
        Movement = {
            Fly = {Enabled = false, Speed = 1, Vertical = 1}, 
            Speed = {Enabled = false, Val = 0.5},
            NoClip = {Enabled = false},
        },
        Visuals = {
            ESP = {Enabled = false},
            Fullbright = false
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        LastAttack = 0,
        Target = nil
    },
    Cache = {
        ESP = {},
        Targets = {}, -- Stores enemies
        Connections = {} -- Stores event connections
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

-- KEY SYSTEM
local KeySystem = {}
function KeySystem.Run()
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
    B.Position = UDim2.new(0.1, 0, 0.25, 0)
    B.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    B.TextColor3 = Color3.new(1,1,1)
    B.PlaceholderText = "Key..."
    B.Text = ""
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.65, 0)
    Btn.Text = "LOAD (NO LAG)"
    Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
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
KeySystem.Run()

-- OPTIMIZED TARGET SYSTEM (EVENT BASED)
local Combat = {}

function Combat.AddTarget(Char)
    if not Char then return end
    table.insert(Itoshi.Cache.Targets, Char)
    
    -- Event Listener for Attacks (Zero-Lag Block)
    local Hum = Char:WaitForChild("Humanoid", 1)
    if Hum then
        local Anim = Hum:WaitForChild("Animator", 1)
        if Anim then
            local Conn = Anim.AnimationPlayed:Connect(function(Track)
                if Itoshi.Settings.Combat.AutoBlock.Enabled then
                    if Track.Priority == Enum.AnimationPriority.Action or Track.Priority == Enum.AnimationPriority.Action2 then
                        local MyRoot = GetRoot(LocalPlayer.Character)
                        local TRoot = GetRoot(Char)
                        if MyRoot and TRoot then
                            local Dist = (MyRoot.Position - TRoot.Position).Magnitude
                            if Dist <= Itoshi.Settings.Combat.AutoBlock.Range then
                                Combat.Block(TRoot)
                            end
                        end
                    end
                end
            end)
            table.insert(Itoshi.Cache.Connections, Conn)
        end
    end
end

function Combat.RefreshCache()
    -- Clear old connections to free memory
    for _, c in pairs(Itoshi.Cache.Connections) do c:Disconnect() end
    table.clear(Itoshi.Cache.Connections)
    table.clear(Itoshi.Cache.Targets)
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then Combat.AddTarget(p.Character) end
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(v) then
            Combat.AddTarget(v)
        end
    end
end

function Combat.Block(TargetRoot)
    if Itoshi.State.Blocking or (tick() - Itoshi.State.LastBlock < 0.1) then return end
    
    if Itoshi.Settings.Combat.AutoBlock.AutoFace then
        local MyRoot = GetRoot(LocalPlayer.Character)
        if MyRoot then
            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TargetRoot.Position.X, MyRoot.Position.Y, TargetRoot.Position.Z))
        end
    end
    
    Itoshi.State.Blocking = true
    Itoshi.State.LastBlock = tick()
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    task.delay(Itoshi.Settings.Combat.AutoBlock.Duration, function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        Itoshi.State.Blocking = false
    end)
end

function Combat.RunKillAura()
    if not Itoshi.Settings.Combat.KillAura.Enabled then return end
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    if tick() - Itoshi.State.LastAttack > Itoshi.Settings.Combat.KillAura.Speed then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.KillAura.Range then
                MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                Itoshi.State.LastAttack = tick()
                break
            end
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub | Optimized",
    LoadingTitle = "Zero Lag Mode",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura (Event Based)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block (Event Based)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 30}, Increment = 1, CurrentValue = 18, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Hitbox Size", Range = {2, 30}, Increment = 1, CurrentValue = 15, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- OPTIMIZED LOOPS
-- Only Kill Aura runs on RenderStepped (because it needs speed)
RunService.RenderStepped:Connect(function()
    SecureCall(Combat.RunKillAura)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

-- Background Loop (1 Second Interval)
-- Handles Caching, Hitbox, ESP Refresh (Zero CPU usage)
task.spawn(function()
    while true do
        task.wait(1)
        SecureCall(Combat.RefreshCache)
        
        -- Hitbox Logic
        if Itoshi.Settings.Combat.Hitbox.Enabled then
            for _, t in pairs(Itoshi.Cache.Targets) do
                local r = GetRoot(t)
                if r then r.Size = Vector3.new(Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size) r.Transparency = 0.8 r.CanCollide = false end
            end
        end
        
        -- ESP Logic
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
