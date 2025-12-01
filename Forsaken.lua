local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local VirtualInputManager = Services.VirtualInputManager
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = false, Range = 25, Rotate = true},
            AutoBlock = {
                Enabled = false, 
                Range = 18, 
                Duration = 0.5, 
                Sensitivity = "High", -- High = Block ANYTHING that isn't walking
                Debug = true -- Shows "BLOCKING!" text when triggered
            },
            Hitbox = {Enabled = false, Size = 15, Transparency = 0.7}
        },
        Visuals = {
            ESP = {Enabled = false},
            Fullbright = false
        }
    },
    State = {
        Blocking = false,
        LastBlock = 0,
    },
    Cache = {
        ESP = {},
        SafeAnims = { -- Animations to IGNORE (Walking/Idle)
            ["idle"] = true, ["walk"] = true, ["run"] = true, ["jump"] = true, ["fall"] = true, ["climb"] = true
        }
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
    F.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
    F.Parent = S
    
    local B = Instance.new("TextBox")
    B.Size = UDim2.new(0.8, 0, 0.3, 0)
    B.Position = UDim2.new(0.1, 0, 0.3, 0)
    B.Text = ""
    B.PlaceholderText = "Key..."
    B.Parent = F
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.Text = "FIXED LOAD"
    Btn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
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

-- UTILS
local function SecureCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local function CreateDebugText(Target)
    if not Itoshi.Settings.Combat.AutoBlock.Debug then return end
    local B = Instance.new("BillboardGui")
    B.Adornee = Target
    B.Size = UDim2.new(0, 200, 0, 50)
    B.StudsOffset = Vector3.new(0, 3, 0)
    B.AlwaysOnTop = true
    
    local T = Instance.new("TextLabel")
    T.Size = UDim2.new(1,0,1,0)
    T.BackgroundTransparency = 1
    T.Text = "ATTACK DETECTED!"
    T.TextColor3 = Color3.new(1,0,0)
    T.TextScaled = true
    T.Font = Enum.Font.GothamBlack
    T.Parent = B
    
    B.Parent = CoreGui
    game:GetService("Debris"):AddItem(B, 1)
end

-- COMBAT
local Combat = {}

function Combat.GetTargets()
    local T = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then table.insert(T, p.Character) end
    end
    -- Get NPCs
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(v) then
            table.insert(T, v)
        end
    end
    return T
end

function Combat.IsAttacking(Char)
    if not Char then return false end
    local Anim = Char:FindFirstChild("Humanoid") and Char.Humanoid:FindFirstChild("Animator")
    if not Anim then return false end
    
    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
        local Name = Track.Name:lower()
        local Speed = Track.Speed
        
        -- AGGRESSIVE CHECK:
        -- If animation is NOT in the safe list (walk/run/idle) -> IT IS AN ATTACK
        local IsSafe = false
        for SafeName, _ in pairs(Itoshi.Cache.SafeAnims) do
            if string.find(Name, SafeName) then
                IsSafe = true
                break
            end
        end
        
        -- Extra Check: Attacks usually have speed > 0 or specific priorities
        if not IsSafe and (Track.Priority.Value >= 2 or Speed > 0.5) then
            return true -- Block it!
        end
    end
    return false
end

function Combat.PerformBlock(Target)
    if Itoshi.State.Blocking or (tick() - Itoshi.State.LastBlock < 0.1) then return end
    
    -- Visual Debug
    CreateDebugText(Target)
    
    -- Face Target
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local MyRoot = LocalPlayer.Character.HumanoidRootPart
        local TargetRoot = Target:FindFirstChild("HumanoidRootPart")
        if TargetRoot then
            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TargetRoot.Position.X, MyRoot.Position.Y, TargetRoot.Position.Z))
        end
    end
    
    Itoshi.State.Blocking = true
    Itoshi.State.LastBlock = tick()
    
    -- Spam F key to ensure registration
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) -- Hold again
    
    task.delay(Itoshi.Settings.Combat.AutoBlock.Duration, function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        Itoshi.State.Blocking = false
    end)
end

function Combat.Update()
    -- KILL AURA
    if Itoshi.Settings.Combat.KillAura.Enabled then
        local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if MyRoot then
            for _, Char in pairs(Combat.GetTargets()) do
                local Root = Char:FindFirstChild("HumanoidRootPart")
                if Root and (MyRoot.Position - Root.Position).Magnitude <= Itoshi.Settings.Combat.KillAura.Range then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(Root.Position.X, MyRoot.Position.Y, Root.Position.Z))
                    local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if Tool then Tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                    break 
                end
            end
        end
    end

    -- AUTO BLOCK (Aggressive Mode)
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if MyRoot then
            for _, Char in pairs(Combat.GetTargets()) do
                local Root = Char:FindFirstChild("HumanoidRootPart")
                if Root and (MyRoot.Position - Root.Position).Magnitude <= Itoshi.Settings.Combat.AutoBlock.Range then
                    if Combat.IsAttacking(Char) then
                        Combat.PerformBlock(Char)
                        break -- Block closest threat
                    end
                end
            end
        end
    end
end

-- HITBOX
function Combat.UpdateHitbox()
    if not Itoshi.Settings.Combat.Hitbox.Enabled then return end
    for _, Char in pairs(Combat.GetTargets()) do
        local Root = Char:FindFirstChild("HumanoidRootPart")
        if Root then
            Root.Size = Vector3.new(Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size)
            Root.Transparency = Itoshi.Settings.Combat.Hitbox.Transparency
            Root.CanCollide = false
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub | Fixed",
    LoadingTitle = "Universal Core",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block (Aggressive)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 30}, Increment = 1, CurrentValue = 18, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})
TabC:CreateToggle({Name = "Show 'BLOCKING!' Text", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Debug = v end})
TabC:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})
TabC:CreateSlider({Name = "Hitbox Size", Range = {2, 30}, Increment = 1, CurrentValue = 15, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Size = v end})

TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- LOOPS
RunService.RenderStepped:Connect(function()
    SecureCall(Combat.Update)
    SecureCall(Combat.UpdateHitbox)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

-- ESP
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
