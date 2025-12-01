local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

-- SERVICES
local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local CoreGui = Services.CoreGui
local VirtualInputManager = Services.VirtualInputManager
local ProximityPromptService = Services.ProximityPromptService

local LocalPlayer = Players.LocalPlayer

-- CONFIG
local Itoshi = {
    Settings = {
        Utility = {
            AutoGenerator = {
                Enabled = false, 
                Teleport = true, 
                AutoSkillCheck = true,
                Speed = 1 -- Safe Speed Multiplier
            }
        },
        Visuals = {
            GenESP = {Enabled = false}
        }
    },
    Cache = {
        Generators = {}
    }
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
    F.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    F.Parent = S
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.4, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.3, 0)
    Btn.Text = "LOAD ENGINEER FIX"
    Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Parent = F
    
    Btn.MouseButton1Click:Connect(function()
        getgenv().ItoshiAuth = true
        S:Destroy()
    end)
end
LoadKeySystem()

-- GENERATOR LOGIC
local GeneratorSys = {}

function GeneratorSys.Refresh()
    table.clear(Itoshi.Cache.Generators)
    for _, v in pairs(Workspace:GetDescendants()) do
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
        if Prompt.Parent and Prompt.Enabled then
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
    
    local Gui = LocalPlayer.PlayerGui:FindFirstChild("SkillCheckUI") or LocalPlayer.PlayerGui:FindFirstChild("GameUI")
    if Gui then
        -- Universal check for any visible frame that looks like a skill check bar
        -- We trigger space when it appears
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end
end

function GeneratorSys.Update()
    if not Itoshi.Settings.Utility.AutoGenerator.Enabled then return end
    
    local MyRoot = GetRoot(LocalPlayer.Character)
    local Hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if not MyRoot or not Hum then return end
    
    local Prompt = GeneratorSys.GetClosest()
    
    if Prompt and Prompt.Parent then
        local GPos = Prompt.Parent.Position
        local Dist = (MyRoot.Position - GPos).Magnitude
        
        -- MOVE LOGIC (Safe CFrame Walk)
        if Itoshi.Settings.Utility.AutoGenerator.Teleport and Dist > 5 then
            Hum.PlatformStand = false
            -- Calculate direction
            local Dir = (GPos - MyRoot.Position).Unit
            -- Move root part smoothly without exceeding server velocity limits
            MyRoot.CFrame = MyRoot.CFrame + (Dir * Itoshi.Settings.Utility.AutoGenerator.Speed)
            -- Look at generator
            MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(GPos.X, MyRoot.Position.Y, GPos.Z))
        end
        
        -- INTERACT LOGIC
        if Dist < 12 then
            -- Stop moving to interact
            if Dist < 5 then MyRoot.Velocity = Vector3.zero end
            
            -- Fire Prompt
            fireproximityprompt(Prompt)
            
            -- Skill Check
            GeneratorSys.AutoSkillCheck()
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub | Engineer Fix",
    LoadingTitle = "Loading...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "Cfg"},
    KeySystem = false, 
})

local TabGen = Window:CreateTab("Utility", 4483362458)
local TabVis = Window:CreateTab("Visuals", 4483362458)

TabGen:CreateToggle({Name = "Auto Generator (Safe Walk)", CurrentValue = false, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Enabled = v end})
TabGen:CreateToggle({Name = "Auto Skill Check", CurrentValue = true, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.AutoSkillCheck = v end})
TabGen:CreateSlider({Name = "Walk Speed", Range = {0.5, 3}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Itoshi.Settings.Utility.AutoGenerator.Speed = v end})

TabVis:CreateToggle({Name = "Generator ESP", CurrentValue = false, Callback = function(v) Itoshi.Settings.Visuals.GenESP = v end})

-- LOOPS
RunService.RenderStepped:Connect(function()
    SecureCall(GeneratorSys.Update)
end)

task.spawn(function()
    while true do
        task.wait(1)
        SecureCall(GeneratorSys.Refresh)
        
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
                    T.Text = "GEN"
                    T.TextStrokeTransparency = 0
                end
            end
        end
    end
end)

Rayfield:LoadConfiguration()
