local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

-- SERVICES
local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local VirtualInputManager = Services.VirtualInputManager
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIG (RAGE DEFAULTS APPLIED)
local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = true, Range = 25, Speed = 0.01}, -- Fastest
            AutoBlock = {
                Enabled = true, 
                Mode = "Hybrid", 
                Range = 25, 
                Reaction = 0, 
                Duration = 0.8, 
                AutoFace = true, 
                CheckFacing = true -- Fix: Don't block if killer looks away
            },
            Hitbox = {Enabled = true, Size = 20, Transparency = 0.5}
        },
        Visuals = {
            ESP = {Enabled = false},
            Fullbright = false
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
        LastAttack = 0
    },
    Cache = {
        Targets = {},
        ESP = {}
    },
    Keywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action", "heavy", "light"}
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
    F.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.25, 0)
    B.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    B.TextColor3 = Color3.new(1,1,1)
    B.PlaceholderText = "Key..."
    B.Text = ""
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.65, 0)
    Btn.Text = "INJECT"
    Btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
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

-- UTILS
local function SecureCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local function GetRoot(Char)
    return Char:FindFirstChild("HumanoidRootPart")
end

-- COMBAT LOGIC
local Combat = {}

function Combat.RefreshCache()
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

function Combat.IsFacing(MyRoot, TargetRoot)
    local Vec = (MyRoot.Position - TargetRoot.Position).Unit
    local Dot = TargetRoot.CFrame.LookVector:Dot(Vec)
    return Dot > 0.5 -- Killer is looking roughly at me
end

function Combat.IsAttacking(Char)
    if not Char then return false end
    local Hum = Char:FindFirstChild("Humanoid")
    if not Hum then return false end
    local Anim = Hum:FindFirstChild("Animator")
    if not Anim then return false end
    
    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
        if Track.Priority == Enum.AnimationPriority.Action or Track.Priority == Enum.AnimationPriority.Action2 then
            return true
        end
        local N = Track.Name:lower()
        for _, K in pairs(Itoshi.Keywords) do
            if string.find(N, K) then return true end
        end
    end
    return false
end

function Combat.Logic()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    -- KILL AURA (RAGE)
    if Itoshi.Settings.Combat.KillAura.Enabled then
        if tick() - Itoshi.State.LastAttack > Itoshi.Settings.Combat.KillAura.Speed then
            for _, Target in pairs(Itoshi.Cache.Targets) do
                local TRoot = GetRoot(Target)
                if TRoot then
                    local Dist = (MyRoot.Position - TRoot.Position).Magnitude
                    if Dist <= Itoshi.Settings.Combat.KillAura.Range then
                        -- Face
                        MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                        -- Attack
                        VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                        VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                        Itoshi.State.LastAttack = tick()
                        break
                    end
                end
            end
        end
    end

    -- AUTO BLOCK (HYBRID + FACE CHECK)
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        if not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
            for _, Target in pairs(Itoshi.Cache.Targets) do
                local TRoot = GetRoot(Target)
                if TRoot then
                    local Dist = (MyRoot.Position - TRoot.Position).Magnitude
                    if Dist <= Itoshi.Settings.Combat.AutoBlock.Range then
                        local ShouldBlock = false
                        
                        -- Check Facing (Is killer looking at me?)
                        if Itoshi.Settings.Combat.AutoBlock.CheckFacing then
                            if not Combat.IsFacing(MyRoot, TRoot) then
                                continue -- Skip if not looking at me
                            end
                        end

                        -- Hybrid Logic
                        if Itoshi.Settings.Combat.AutoBlock.Mode == "Hybrid" then
                            if Combat.IsAttacking(Target) or Dist < 6 then ShouldBlock = true end
                        elseif Itoshi.Settings.Combat.AutoBlock.Mode == "Animation" then
                             if Combat.IsAttacking(Target) then ShouldBlock = true end
                        elseif Itoshi.Settings.Combat.AutoBlock.Mode == "Distance" then
                             ShouldBlock = true
                        end

                        if ShouldBlock then
                            -- Auto Face
                            if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                                MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                            end
                            
                            -- Reaction
                            if Itoshi.Settings.Combat.AutoBlock.Reaction > 0 then
                                task.wait(Itoshi.Settings.Combat.AutoBlock.Reaction)
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
    end
end

-- HITBOX EXPANDER
function Combat.UpdateHitbox()
    if not Itoshi.Settings.Combat.Hitbox.Enabled then return end
    local S = Itoshi.Settings.Combat.Hitbox.Size
    local T = Itoshi.Settings.Combat.Hitbox.Transparency
    
    for _, Target in pairs(Itoshi.Cache.Targets) do
        local Root = GetRoot(Target)
        if Root then
            Root.Size = Vector3.new(S, S, S)
            Root.Transparency = T
            Root.CanCollide = false
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "itoshi hub Loaded",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "RageCfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = Itoshi.Settings.Combat.KillAura.Enabled, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateSlider({Name = "Aura Range", Range = {5, 30}, Increment = 1, CurrentValue = Itoshi.Settings.Combat.KillAura.Range, Callback = function(v) Itoshi.Settings.Combat.KillAura.Range = v end})

TabC:CreateToggle({Name = "Auto Block", CurrentValue = Itoshi.Settings.Combat.AutoBlock.Enabled, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateToggle({Name = "Smart Face Check", CurrentValue = Itoshi.Settings.Combat.AutoBlock.CheckFacing, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.CheckFacing = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 50}, Increment = 1, CurrentValue = Itoshi.Settings.Combat.AutoBlock.Range, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateSlider({Name = "Block Duration", Range = {0.1, 2}, Increment = 0.1, CurrentValue = Itoshi.Settings.Combat.AutoBlock.Duration, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Duration = v end})

TabC:CreateToggle({Name = "Hitbox Expander", CurrentValue = Itoshi.Settings.Combat.Hitbox.Enabled, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Hitbox Size", Range = {2, 50}, Increment = 1, CurrentValue = Itoshi.Settings.Combat.Hitbox.Size, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})
TabC:CreateSlider({Name = "Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = Itoshi.Settings.Combat.Hitbox.Transparency, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Transparency = v end})

TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- LOOPS
RunService.RenderStepped:Connect(function()
    SecureCall(Combat.Logic)
    SecureCall(Combat.UpdateHitbox)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        SecureCall(Combat.RefreshCache)
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
