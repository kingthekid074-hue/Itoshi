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

-- CONFIG
local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = false, Range = 20},
            AutoBlock = {Enabled = false, Range = 15, Reaction = 0, Duration = 0.5, AutoFace = true},
            WeaponReach = {Enabled = false, Size = 15, Active = false} -- NEW: Weapon Resize Logic
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
        Input = {W=false, A=false, S=false, D=false, Up=false, Down=false, MobileUp=false, MobileDown=false},
        FlyObjects = {}
    },
    Cache = {
        ESP = {},
        MobileGui = nil
    },
    Keywords = {"attack", "slash", "swing", "punch", "lunge", "throw", "cast", "m1", "action", "heavy"}
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
    Btn.Text = "LOAD REACH"
    Btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
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
    
    Btn("REACH", UDim2.new(0.8,0,0.6,0), function() 
        Itoshi.Settings.Combat.WeaponReach.Enabled = not Itoshi.Settings.Combat.WeaponReach.Enabled
    end)
end

-- COMBAT
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
    if not Char then return false end
    local Anim = Char:FindFirstChild("Humanoid") and Char.Humanoid:FindFirstChild("Animator")
    if not Anim then return false end
    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
        -- Priority Check (Action/Action2/Action3/Action4)
        if Track.Priority.Value >= 2 then
            return true
        end
    end
    return false
end

-- WEAPON REACH LOGIC (THE FIX)
function Combat.UpdateReach()
    if not Itoshi.Settings.Combat.WeaponReach.Enabled then return end
    
    local Char = LocalPlayer.Character
    if not Char then return end
    
    local Tool = Char:FindFirstChildOfClass("Tool")
    if Tool then
        local Handle = Tool:FindFirstChild("Handle") or Tool:FindFirstChild("Hitbox") or Tool:FindFirstChild("Blade")
        if Handle then
            if not Handle:FindFirstChild("OriginalSize") then
                local S = Instance.new("Vector3Value", Handle)
                S.Name = "OriginalSize"
                S.Value = Handle.Size
                
                local C = Instance.new("SelectionBox", Handle)
                C.Name = "ReachVisual"
                C.Adornee = Handle
                C.Color3 = Color3.new(1,0,0)
            end
            
            -- Resize Handle
            Handle.Size = Vector3.new(Itoshi.Settings.Combat.WeaponReach.Size, Itoshi.Settings.Combat.WeaponReach.Size, Itoshi.Settings.Combat.WeaponReach.Size)
            Handle.Massless = true -- Prevent weight issues
            Handle.CanCollide = false
            Handle.Transparency = 0.5 -- Visual Feedback
        end
    end
end

function Combat.Update()
    -- KILL AURA
    if Itoshi.Settings.Combat.KillAura.Enabled then
        local MyRoot = GetRoot(LocalPlayer.Character)
        if MyRoot then
            for _, Target in pairs(Combat.GetTargets()) do
                local TRoot = GetRoot(Target)
                -- Increased Range Check because we have Reach now
                if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.KillAura.Range then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                    
                    local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if Tool then Tool:Activate() end
                    
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                    break 
                end
            end
        end
    end

    -- AUTO BLOCK
    if Itoshi.Settings.Combat.AutoBlock.Enabled then
        local MyRoot = GetRoot(LocalPlayer.Character)
        if MyRoot then
            for _, Target in pairs(Combat.GetTargets()) do
                local TRoot = GetRoot(Target)
                if TRoot and (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.AutoBlock.Range then
                    if Combat.IsAttacking(Target) and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.1) then
                        if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                        end
                        Itoshi.State.Blocking = true
                        Itoshi.State.LastBlock = tick()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        task.delay(Itoshi.Settings.Combat.AutoBlock.Duration, function()
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                            Itoshi.State.Blocking = false
                        end)
                        break
                    end
                end
            end
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub | Reach Fix",
    LoadingTitle = "Core Loaded",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabC = Window:CreateTab("Combat", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Weapon Reach (Effective)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.WeaponReach.Enabled = v end})
TabC:CreateSlider({Name = "Reach Size", Range = {5, 25}, Increment = 1, CurrentValue = 15, Callback = function(v) Itoshi.Settings.Combat.WeaponReach.Size = v end})

TabC:CreateToggle({Name = "Auto Block", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateSlider({Name = "Block Range", Range = {5, 30}, Increment = 1, CurrentValue = 18, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Range = v end})

TabV:CreateToggle({Name = "Mobile Buttons", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.MobileUI = v MobileManager.Toggle() end})
TabV:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- LOOPS
RunService.RenderStepped:Connect(function()
    SecureCall(Combat.Update)
    SecureCall(Combat.UpdateReach) -- Constantly resize handle
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

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
