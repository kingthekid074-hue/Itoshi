local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting
local HttpService = Services.HttpService
local TweenService = Services.TweenService
local TeleportService = Services.TeleportService
local ReplicatedStorage = Services.ReplicatedStorage

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Runtime = {
    Connections = {},
    Threads = {},
    Instances = {},
    Flags = {},
    Handlers = {},
    Signals = {},
    Cache = {}
}

local function SecureCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local function DisconnectAll()
    for _, conn in pairs(Runtime.Connections) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end end
    for _, thread in pairs(Runtime.Threads) do if type(thread) == "number" then task.cancel(thread) end end
    for _, inst in pairs(Runtime.Instances) do if inst and inst.Destroy then pcall(function() inst:Destroy() end) end end
    Runtime.Connections, Runtime.Threads, Runtime.Instances, Runtime.Signals, Runtime.Cache = {}, {}, {}, {}, {}
end

DisconnectAll()

local Handler_Forsaken = {}
Handler_Forsaken.Options = {
    Fly = {Enabled = false, Speed = 50, Vertical = 25},
    Speed = {Enabled = false, Value = 16},
    Jump = {Enabled = false, Value = 50},
    NoClip = {Enabled = false},
    ESP = {Enabled = false, Distance = 2000},
    Fullbright = {Enabled = false},
    AntiStun = {Enabled = false},
    InfiniteStamina = {Enabled = false},
    AutoFarm = {Enabled = false},
    GodMode = {Enabled = false}
}

Handler_Forsaken.State = {
    W = false, A = false, S = false, D = false, 
    Space = false, Ctrl = false, Shift = false
}

Handler_Forsaken.ESPStorage = {}

function Handler_Forsaken.InitInput()
    table.insert(Runtime.Connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.W then Handler_Forsaken.State.W = true end
        if input.KeyCode == Enum.KeyCode.A then Handler_Forsaken.State.A = true end
        if input.KeyCode == Enum.KeyCode.S then Handler_Forsaken.State.S = true end
        if input.KeyCode == Enum.KeyCode.D then Handler_Forsaken.State.D = true end
        if input.KeyCode == Enum.KeyCode.Space then Handler_Forsaken.State.Space = true end
        if input.KeyCode == Enum.KeyCode.LeftControl then Handler_Forsaken.State.Ctrl = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then Handler_Forsaken.State.Shift = true end
    end))

    table.insert(Runtime.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then Handler_Forsaken.State.W = false end
        if input.KeyCode == Enum.KeyCode.A then Handler_Forsaken.State.A = false end
        if input.KeyCode == Enum.KeyCode.S then Handler_Forsaken.State.S = false end
        if input.KeyCode == Enum.KeyCode.D then Handler_Forsaken.State.D = false end
        if input.KeyCode == Enum.KeyCode.Space then Handler_Forsaken.State.Space = false end
        if input.KeyCode == Enum.KeyCode.LeftControl then Handler_Forsaken.State.Ctrl = false end
        if input.KeyCode == Enum.KeyCode.LeftShift then Handler_Forsaken.State.Shift = false end
    end))
end

function Handler_Forsaken.UpdateFly()
    if not Handler_Forsaken.Options.Fly.Enabled then return end
    if not LocalPlayer.Character then return end
    
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not root or not humanoid then return end

    humanoid.PlatformStand = true
    
    local camCF = Camera.CFrame
    local moveDir = Vector3.zero
    
    if Handler_Forsaken.State.W then moveDir = moveDir + camCF.LookVector end
    if Handler_Forsaken.State.S then moveDir = moveDir - camCF.LookVector end
    if Handler_Forsaken.State.A then moveDir = moveDir - camCF.RightVector end
    if Handler_Forsaken.State.D then moveDir = moveDir + camCF.RightVector end
    
    local finalVel = moveDir.Unit * Handler_Forsaken.Options.Fly.Speed
    if finalVel.X ~= finalVel.X then finalVel = Vector3.zero end
    
    local yVel = 0
    if Handler_Forsaken.State.Space then yVel = Handler_Forsaken.Options.Fly.Vertical end
    if Handler_Forsaken.State.Ctrl then yVel = -Handler_Forsaken.Options.Fly.Vertical end
    
    root.Velocity = Vector3.new(finalVel.X, yVel, finalVel.Z)
    root.AssemblyAngularVelocity = Vector3.zero
end

function Handler_Forsaken.UpdateMovement()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if Handler_Forsaken.Options.Speed.Enabled then
        humanoid.WalkSpeed = Handler_Forsaken.Options.Speed.Value
    end
    
    if Handler_Forsaken.Options.Jump.Enabled then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Handler_Forsaken.Options.Jump.Value
    end
end

function Handler_Forsaken.UpdateNoClip()
    if not LocalPlayer.Character then return end
    if Handler_Forsaken.Options.NoClip.Enabled then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end

function Handler_Forsaken.UpdateESP()
    if not Handler_Forsaken.Options.ESP.Enabled then
        for player, highlight in pairs(Handler_Forsaken.ESPStorage) do
            if highlight then highlight:Destroy() end
        end
        Handler_Forsaken.ESPStorage = {}
        return
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local distance = (root.Position - Camera.CFrame.Position).Magnitude
                if distance <= Handler_Forsaken.Options.ESP.Distance then
                    if not Handler_Forsaken.ESPStorage[player] then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ForsakenESP_" .. player.Name
                        highlight.Adornee = player.Character
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = player.Character
                        Handler_Forsaken.ESPStorage[player] = highlight
                    end
                else
                    if Handler_Forsaken.ESPStorage[player] then
                        Handler_Forsaken.ESPStorage[player]:Destroy()
                        Handler_Forsaken.ESPStorage[player] = nil
                    end
                end
            end
        else
            if Handler_Forsaken.ESPStorage[player] then
                Handler_Forsaken.ESPStorage[player]:Destroy()
                Handler_Forsaken.ESPStorage[player] = nil
            end
        end
    end
end

function Handler_Forsaken.UpdateLighting()
    if Handler_Forsaken.Options.Fullbright.Enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    end
end

function Handler_Forsaken.HandleAntiStun()
    if Handler_Forsaken.Options.AntiStun.Enabled then
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
end

function Handler_Forsaken.HandleInfiniteStamina()
    if Handler_Forsaken.Options.InfiniteStamina.Enabled then
        if LocalPlayer.Character then
            local stamina = LocalPlayer.Character:FindFirstChild("Stamina")
            if stamina then
                stamina.Value = stamina.MaxValue
            end
        end
    end
end

function Handler_Forsaken.HandleGodMode()
    if Handler_Forsaken.Options.GodMode.Enabled then
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
            end
        end
    end
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Forsaken Ultimate",
    LoadingTitle = "Loading Forsaken Hub...",
    LoadingSubtitle = "Powered by Ultimate Script",
    ConfigurationSaving = {Enabled = true, FolderName = "ForsakenHub", FileName = "Config"},
    KeySystem = false,
})

local TabMovement = Window:CreateTab("Movement", 4483362458)
local TabVisuals = Window:CreateTab("Visuals", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabAutoFarm = Window:CreateTab("Auto Farm", 4483362458)

TabMovement:CreateToggle({
    Name = "Flight System",
    CurrentValue = Handler_Forsaken.Options.Fly.Enabled,
    Callback = function(value) 
        Handler_Forsaken.Options.Fly.Enabled = value 
        if not value and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
        end
    end
})

TabMovement:CreateSlider({
    Name = "Flight Speed",
    Range = {10, 200},
    Increment = 1,
    Suffix = " Speed",
    CurrentValue = Handler_Forsaken.Options.Fly.Speed,
    Callback = function(value) Handler_Forsaken.Options.Fly.Speed = value end
})

TabMovement:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = Handler_Forsaken.Options.Speed.Enabled,
    Callback = function(value) Handler_Forsaken.Options.Speed.Enabled = value end
})

TabMovement:CreateSlider({
    Name = "Speed Value",
    Range = {16, 150},
    Increment = 1,
    Suffix = " Speed",
    CurrentValue = Handler_Forsaken.Options.Speed.Value,
    Callback = function(value) Handler_Forsaken.Options.Speed.Value = value end
})

TabMovement:CreateToggle({
    Name = "Enhanced Jump",
    CurrentValue = Handler_Forsaken.Options.Jump.Enabled,
    Callback = function(value) Handler_Forsaken.Options.Jump.Enabled = value end
})

TabMovement:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 1,
    Suffix = " Power",
    CurrentValue = Handler_Forsaken.Options.Jump.Value,
    Callback = function(value) Handler_Forsaken.Options.Jump.Value = value end
})

TabMovement:CreateToggle({
    Name = "NoClip (Walk Through Walls)",
    CurrentValue = Handler_Forsaken.Options.NoClip.Enabled,
    Callback = function(value) Handler_Forsaken.Options.NoClip.Enabled = value end
})

TabVisuals:CreateToggle({
    Name = "Player ESP",
    CurrentValue = Handler_Forsaken.Options.ESP.Enabled,
    Callback = function(value) Handler_Forsaken.Options.ESP.Enabled = value end
})

TabVisuals:CreateToggle({
    Name = "Fullbright Mode",
    CurrentValue = Handler_Forsaken.Options.Fullbright.Enabled,
    Callback = function(value) Handler_Forsaken.Options.Fullbright.Enabled = value end
})

TabCombat:CreateToggle({
    Name = "Anti-Stun",
    CurrentValue = Handler_Forsaken.Options.AntiStun.Enabled,
    Callback = function(value) Handler_Forsaken.Options.AntiStun.Enabled = value end
})

TabCombat:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = Handler_Forsaken.Options.InfiniteStamina.Enabled,
    Callback = function(value) Handler_Forsaken.Options.InfiniteStamina.Enabled = value end
})

TabCombat:CreateToggle({
    Name = "God Mode",
    CurrentValue = Handler_Forsaken.Options.GodMode.Enabled,
    Callback = function(value) Handler_Forsaken.Options.GodMode.Enabled = value end
})

TabAutoFarm:CreateToggle({
    Name = "Auto Farm Enemies",
    CurrentValue = Handler_Forsaken.Options.AutoFarm.Enabled,
    Callback = function(value) Handler_Forsaken.Options.AutoFarm.Enabled = value end
})

TabAutoFarm:CreateButton({
    Name = "Teleport to Safe Zone",
    Callback = function()
        local safeZones = {"SafeZone", "Spawn", "Town", "Base"}
        for _, zone in ipairs(safeZones) do
            local part = Workspace:FindFirstChild(zone)
            if part then
                if LocalPlayer.Character then
                    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                    end
                end
                break
            end
        end
    end
})

Handler_Forsaken.InitInput()

table.insert(Runtime.Connections, RunService.RenderStepped:Connect(function(dt)
    SecureCall(Handler_Forsaken.UpdateFly)
end))

table.insert(Runtime.Connections, RunService.Stepped:Connect(function()
    SecureCall(Handler_Forsaken.UpdateMovement)
    SecureCall(Handler_Forsaken.UpdateNoClip)
    SecureCall(Handler_Forsaken.HandleAntiStun)
    SecureCall(Handler_Forsaken.HandleInfiniteStamina)
    SecureCall(Handler_Forsaken.HandleGodMode)
end))

table.insert(Runtime.Connections, RunService.Heartbeat:Connect(function()
    if tick() % 0.5 < 0.1 then
        SecureCall(Handler_Forsaken.UpdateESP)
    end
    SecureCall(Handler_Forsaken.UpdateLighting)
end))

Rayfield:LoadConfiguration()

warn("Forsaken Ultimate Loaded Successfully")
warn("Active Features: Flight, Speed, ESP, God Mode & More")
