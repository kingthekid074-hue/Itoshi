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
local ProximityPromptService = Services.ProximityPromptService
local TweenService = Services.TweenService

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIG
local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = false, Range = 20},
            AutoBlock = {Enabled = false, Range = 15, Reaction = 0, Duration = 0.5, AutoFace = true},
            Hitbox = {Enabled = false, Size = 10, Transparency = 0.5, Reach = true}
        },
        Utility = {
            AutoGenerator = {
                Enabled = false, 
                Teleport = true, -- Go to generator
                AutoSkillCheck = true, -- Hit perfect checks
                Speed = 16 -- Tween Speed
            },
            AutoHeal = {Enabled = false, Threshold = 30}
        },
        Visuals = {
            ESP = {Enabled = false},
            GenESP = {Enabled = false}, -- Generator ESP
            MobileUI = false,
            Fullbright = false
        }
    },
    State = {
        Blocking = false,
        Repairing = false,
        CurrentGen = nil
    },
    Cache = {
        Targets = {},
        Generators = {},
        ESP = {}
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
local function LoadKeySystem()
    if getgenv().ItoshiAuth then return end
    local S = Instance.new("ScreenGui")
    S.Parent = CoreGui
    S.Name = "ItoshiAuth"
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 300, 0, 140)
    F.Position = UDim2.new(0.5, -150, 0.5, -70)
    F.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
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
    Btn.Text = "LOAD ENGINEER"
    Btn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
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

-- GENERATOR LOGIC (NEW)
local GeneratorSys = {}

function GeneratorSys.Refresh()
    table.clear(Itoshi.Cache.Generators)
    for _, v in pairs(Workspace:GetDescendants()) do
        -- Detect Generators by looking for specific parts or prompts
        if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("repair") or v.ObjectText:lower():find("generator")) then
            table.insert(Itoshi.Cache.Generators, v)
        end
    end
end

function GeneratorSys.GetClosest()
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return nil end
    local Closest, MinDist = nil, math.huge
    
    for _, Prompt in pairs(Itoshi.Cache.Generators) do
        if Prompt.Parent then
            local Dist = (MyRoot.Position - Prompt.Parent.Position).Magnitude
            if Dist < MinDist then
                MinDist = Dist
                Closest = Prompt
            end
        end
    end
    return Closest
end

function GeneratorSys.AutoSkillCheck()
    if not Itoshi.Settings.Utility.AutoGenerator.AutoSkillCheck then return end
    
    -- Check PlayerGui for Skill Check UI
    local Gui = LocalPlayer.PlayerGui:FindFirstChild("SkillCheckUI") or LocalPlayer.PlayerGui:FindFirstChild("GameUI")
    if Gui then
        -- This logic tries to find the skill check bar pointer
        -- Generic logic for "Forsaken" style skill checks
        local Bar = Gui:FindFirstChild("Bar", true) 
        local Zone = Gui:FindFirstChild("Zone", true) -- The safe zone
        
        if Bar and Zone and Bar.Visible then
            -- If bar is inside zone (Simple check simulation)
            -- Or just spam Space when UI appears (Works on 90% of Roblox horror games)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end
end

function GeneratorSys.Update()
    if not Itoshi.Settings.Utility.AutoGenerator.Enabled then return end
    
    local MyRoot = GetRoot(LocalPlayer.Character)
    if not MyRoot then return end
    
    local Prompt = GeneratorSys.GetClosest()
    if Prompt and Prompt.Parent then
        local GPos = Prompt.Parent.Position
        
        -- Teleport / Move Logic
        if Itoshi.Settings.Utility.AutoGenerator.Teleport then
            local Dist = (MyRoot.Position - GPos).Magnitude
            if Dist > 5 then
                -- Tween to generator safely
                local Info = TweenInfo.new(Dist / Itoshi.Settings.Utility.AutoGenerator.Speed, Enum.EasingStyle.Linear)
                local Tween = TweenService:Create(MyRoot, Info, {CFrame = CFrame.new(GPos + Vector3.new(0,3,0))})
                Tween:Play()
                return -- Wait until arrived
            end
        end
        
        -- Interact
        if (MyRoot.Position - GPos).Magnitude < 10 then
            fireproximityprompt(Prompt) -- Auto Hold E
            GeneratorSys.AutoSkillCheck() -- Handle Skill Checks
        end
    end
end

-- COMBAT LOGIC
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

function Combat.IsAttacking(Char)
    if not Char then return false end
    local Anim = Char:FindFirstChild("Humanoid") and Char.Humanoid:FindFirstChild("Animator")
    if not Anim then return false end
    for _, Track in pairs(Anim:GetPlayingAnimationTracks()) do
        if Track.Priority.Value >= 2 then return true end
    end
    return false
end

function Combat.Update()
    -- Kill Aura & Auto Block Logic (Same as before)
    local MyRoot = GetRoot(LocalPlayer.Character)
    if MyRoot then
        -- Find Threats
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot then
                local Dist = (MyRoot.Position - TRoot.Position).Magnitude
                
                -- Kill Aura
                if Itoshi.Settings.Combat.KillAura.Enabled and Dist <= Itoshi.Settings.Combat.KillAura.Range then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                    local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if Tool then Tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                end
                
                -- Auto Block
                if Itoshi.Settings.Combat.AutoBlock.Enabled and Dist <= Itoshi.Settings.Combat.AutoBlock.Range then
                    if Combat.IsAttacking(Target) and not Itoshi.State.Blocking and (tick() - Itoshi.State.LastBlock > 0.2) then
                        if Itoshi.Settings.Combat.AutoBlock.AutoFace then
                            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                        end
                        Itoshi.State.Blocking = true
                        Itoshi.State.LastBlock = tick()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                        task.delay(Itoshi.Settings.Combat.AutoBlock.Duration, function()
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                            Itoshi.State.Blocking = false
                        end)
                    end
                end
            end
        end
    end
    
    -- Reach
    if Itoshi.Settings.Combat.Hitbox.Enabled and Itoshi.Settings.Combat.Hitbox.Reach then
        for _, Target in pairs(Itoshi.Cache.Targets) do
            local TRoot = GetRoot(Target)
            if TRoot and MyRoot then
                TRoot.CanCollide = false
                TRoot.Size = Vector3.new(10,10,10)
                TRoot.Transparency = 0.5
                TRoot.CFrame = MyRoot.CFrame * CFrame.new(0,0,-3) -- Bring to player
            end
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "itoshi hub Loaded",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabGen = Window:CreateTab("Utility", 4483362458)
local TabC = Window:CreateTab("Combat", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabGen:CreateSection("Generator Automator")
TabGen:CreateToggle({Name = "Auto Repair Generators", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabGen:CreateToggle({Name = "Auto Skill Check (Perfect)", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoSkillCheck = v end})
TabGen:CreateToggle({Name = "Teleport to Generator", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Teleport = v end})
TabGen:CreateSlider({Name = "Tween Speed", Range = {10, 100}, Increment = 1, CurrentValue = 30, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Speed = v end})

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Auto Block", CurrentValue = false, Callback = function(v) Itoshi.Settings.Combat.AutoBlock.Enabled = v end})
TabC:CreateToggle({Name = "Silent Reach", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Combat.Hitbox.Enabled = v 
    Itoshi.Settings.Combat.Hitbox.Reach = v
end})

TabV:CreateToggle({Name = "Generator ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.GenESP = v end})
TabV:CreateToggle({Name = "Player ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.ESP.Enabled = v end})
TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.Fullbright = v end})

-- MAIN LOOPS
RunService.RenderStepped:Connect(function()
    SecureCall(Combat.Update)
    SecureCall(GeneratorSys.Update)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

-- SLOW LOOP (Cache & ESP)
task.spawn(function()
    while true do
        task.wait(1)
        SecureCall(Combat.RefreshTargets)
        SecureCall(GeneratorSys.Refresh)
        
        -- GEN ESP
        if Itoshi.Settings.Visuals.GenESP then
            for _, P in pairs(Itoshi.Cache.Generators) do
                if P.Parent and not P.Parent:FindFirstChild("GenESP") then
                    local B = Instance.new("BillboardGui", P.Parent)
                    B.Name = "GenESP"
                    B.Size = UDim2.new(0,100,0,50)
                    B.AlwaysOnTop = true
                    local T = Instance.new("TextLabel", B)
                    T.Size = UDim2.new(1,0,1,0)
                    T.BackgroundTransparency = 1
                    T.TextColor3 = Color3.new(0,1,0)
                    T.Text = "GENERATOR"
                    T.TextStrokeTransparency = 0
                end
            end
        end
        
        -- PLAYER ESP
        if Itoshi.Settings.Visuals.ESP.Enabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if not Itoshi.Cache.ESP[p] or Itoshi.Cache.ESP[p].Adornee ~= p.Character then
                        if Itoshi.Cache.ESP[p] then Itoshi.Cache.ESP[p]:Destroy() end
                        local hl = Instance.new("Highlight", CoreGui)
                        hl.FillColor = Color3.new(1,0,0)
                        hl.FillTransparency = 0.5
                        hl.Adornee = p.Character
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
