local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

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
            KillAura = {Enabled = false, Range = 20},
            AutoBlock = {Enabled = false, Range = 20, BlockTime = 0.6, AutoFace = true},
            Hitbox = {Enabled = false, Size = 10, Transparency = 0.5, Reach = true} -- Reach Mode Added
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
        Target = nil
    },
    Cache = {
        Targets = {},
        ESP = {},
        MobileGui = nil
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
    F.Size = UDim2.new(0, 300, 0, 140)
    F.Position = UDim2.new(0.5, -150, 0.5, -70)
    F.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.3, 0)
    B.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    B.TextColor3 = Color3.new(1,1,1)
    B.Text = ""
    B.PlaceholderText = "Key..."
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "LOAD FIXED"
    Btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
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

-- MOBILE UI
local function ToggleMobileUI()
    if Itoshi.Cache.MobileGui then Itoshi.Cache.MobileGui:Destroy() Itoshi.Cache.MobileGui = nil end
    if not Itoshi.Settings.Visuals.MobileUI then return end
    
    local S = Instance.new("ScreenGui", CoreGui)
    S.Name = "ItoshiMobile"
    Itoshi.Cache.MobileGui = S
    
    local function Btn(T, P, F)
        local B = Instance.new("TextButton", S)
        B.Size = UDim2.new(0,50,0,50)
        B.Position = P
        B.BackgroundColor3 = Color3.new(0,0,0)
        B.BackgroundTransparency = 0.5
        B.TextColor3 = Color3.new(1,1,1)
        B.Text = T
        B.MouseButton1Click:Connect(F)
        Instance.new("UICorner", B).CornerRadius = UDim.new(1,0)
    end
    
    Btn("FLY", UDim2.new(0.8,0,0.6,0), function() 
        local Root = GetRoot(LocalPlayer.Character)
        if Root then Root.CFrame = Root.CFrame + Vector3.new(0,10,0) end
    end)
end

-- COMBAT LOGIC
local Combat = {}

function Combat.RefreshTargets()
    table.clear(Itoshi.Cache.Targets)
    -- Only cache valid enemies
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then 
            local Hum = p.Character:FindFirstChild("Humanoid")
            if Hum and Hum.Health > 0 then table.insert(Itoshi.Cache.Targets, p.Character) end
        end
    end
    -- NPCs
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(v) then
            local Hum = v:FindFirstChild("Humanoid")
            if Hum and Hum.Health > 0 then table.insert(Itoshi.Cache.Targets, v) end
        end
    end
end

function Combat.IsAttacking(Char)
    if not Char then return false end
    local Anim = Char:FindFirstChild("Humanoid") and Char.Humanoid:FindFirstChild("Animator")
    if not Anim then return false end
    for _, T in pairs(Anim:GetPlayingAnimationTracks()) do
        if T.Priority == Enum.AnimationPriority.Action or T.Priority == Enum.AnimationPriority.Action2 then
            return true
        end
    end
    return false
end

function Combat.Logic()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    local Closest = nil
    local MinDist = Itoshi.Settings.Combat.AutoBlock.Range
    
    -- Find Closest Target
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
    
    Itoshi.State.Target = Closest -- Update State
    
    if Closest then
        local TRoot = GetRoot(Closest)
        
        -- KILL AURA (R)
        if Itoshi.Settings.Combat.KillAura.Enabled then
            -- Face Target (Camera Fix: Only change CFrame rotation, not camera)
            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
            
            if tick() - Itoshi.State.LastAttack > 0.1 then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                Itoshi.State.LastAttack = tick()
            end
        end
        
        -- AUTO BLOCK (Q)
        if Itoshi.Settings.Combat.AutoBlock.Enabled then
            if Combat.IsAttacking(Closest) and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.2) then
                if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                end
                
                Itoshi.State.Blocking = true
                Itoshi.State.LastBlock = tick()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                task.delay(Itoshi.Settings.Combat.AutoBlock.BlockTime, function()
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                    Itoshi.State.Blocking = false
                end)
            end
        end
        
        -- SILENT REACH (NEW HITBOX METHOD)
        if Itoshi.Settings.Combat.Hitbox.Enabled then
            -- Instead of resizing enemy, we teleport their hitpart to us LOCALLY
            TRoot.CanCollide = false
            TRoot.Size = Vector3.new(Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size)
            TRoot.Transparency = Itoshi.Settings.Combat.Hitbox.Transparency
            
            if Itoshi.Settings.Combat.Hitbox.Reach then
                -- Client-Side Teleport (Ghost Hit)
                TRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -3) -- Put them in front of you
            end
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Fixed...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateToggle({Name = "Silent Reach (Hitbox Fix)", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Combat.Hitbox.Enabled = v 
    Itoshi.Settings.Combat.Hitbox.Reach = v
end})
TabC:CreateSlider({Name = "Hitbox Size", Range = {2, 20}, Increment = 1, CurrentValue = 10, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

TabV:CreateToggle({Name = "Mobile Buttons", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.MobileUI = v ToggleMobileUI() end})
TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- LOOPS
RunService.RenderStepped:Connect(function()
    SecureCall(Combat.Logic)
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

-- CACHE LOOP (0.5s)
task.spawn(function()
    while true do
        task.wait(0.5)
        SecureCall(Combat.RefreshTargets)
        
        -- ESP
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
