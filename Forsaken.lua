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

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Runtime = {
    Connections = {},
    Threads = {},
    Instances = {},
    Flags = {},
    Handlers = {}
}

local function Secure(func)
    local s, e = pcall(func)
    if not s then warn(e) end
end

local function DisconnectAll()
    for _, c in pairs(Runtime.Connections) do c:Disconnect() end
    for _, t in pairs(Runtime.Threads) do task.cancel(t) end
    for _, i in pairs(Runtime.Instances) do i:Destroy() end
    Runtime.Connections = {}
    Runtime.Threads = {}
    Runtime.Instances = {}
end

DisconnectAll()

local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({_bindable = Instance.new("BindableEvent")}, Signal) end
function Signal:Connect(cb) return self._bindable.Event:Connect(cb) end
function Signal:Fire(...) self._bindable:Fire(...) end

local UI_KeySystem = {}
function UI_KeySystem.Init()
    local Screen = Instance.new("ScreenGui")
    Screen.Name = "NexusAuth"
    Screen.Parent = CoreGui
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 150)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 0
    Frame.Parent = Screen
    
    local UICorner = Instance.new("UICorner")
    UICorner.Parent = Frame
    
    local Title = Instance.new("TextLabel")
    Title.Text = "NEXUS AUTHENTICATION"
    Title.Size = UDim2.new(1, 0, 0.3, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = Frame
    
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0.8, 0, 0.25, 0)
    Box.Position = UDim2.new(0.1, 0, 0.4, 0)
    Box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.PlaceholderText = "Enter Key..."
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 12
    Box.Parent = Frame
    Instance.new("UICorner", Box)

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.8, 0, 0.2, 0)
    Button.Position = UDim2.new(0.1, 0, 0.7, 0)
    Button.BackgroundColor3 = Color3.fromRGB(60, 100, 255)
    Button.Text = "LOGIN"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Frame
    Instance.new("UICorner", Button)
    
    local valid = false
    
    local function Check()
        if Box.Text == "test" then
            valid = true
            Screen:Destroy()
        else
            Box.Text = "Invalid Key"
            task.wait(1)
            Box.Text = ""
        end
    end
    
    Button.MouseButton1Click:Connect(Check)
    
    repeat task.wait(0.1) until valid
end

UI_KeySystem.Init()

local Handler_Input = {}
Handler_Input.__index = Handler_Input
Handler_Input.State = {W=false, A=false, S=false, D=false, Space=false, Ctrl=false, Shift=false}

function Handler_Input.Init()
    table.insert(Runtime.Connections, UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.W then Handler_Input.State.W = true end
        if i.KeyCode == Enum.KeyCode.A then Handler_Input.State.A = true end
        if i.KeyCode == Enum.KeyCode.S then Handler_Input.State.S = true end
        if i.KeyCode == Enum.KeyCode.D then Handler_Input.State.D = true end
        if i.KeyCode == Enum.KeyCode.Space then Handler_Input.State.Space = true end
        if i.KeyCode == Enum.KeyCode.LeftControl then Handler_Input.State.Ctrl = true end
        if i.KeyCode == Enum.KeyCode.LeftShift then Handler_Input.State.Shift = true end
    end))
    
    table.insert(Runtime.Connections, UserInputService.InputEnded:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.W then Handler_Input.State.W = false end
        if i.KeyCode == Enum.KeyCode.A then Handler_Input.State.A = false end
        if i.KeyCode == Enum.KeyCode.S then Handler_Input.State.S = false end
        if i.KeyCode == Enum.KeyCode.D then Handler_Input.State.D = false end
        if i.KeyCode == Enum.KeyCode.Space then Handler_Input.State.Space = false end
        if i.KeyCode == Enum.KeyCode.LeftControl then Handler_Input.State.Ctrl = false end
        if i.KeyCode == Enum.KeyCode.LeftShift then Handler_Input.State.Shift = false end
    end))
end

local Handler_Physics = {}
Handler_Physics.Options = {
    Fly = {Enabled = false, Speed = 60, Vertical = 40},
    NoClip = {Enabled = false},
    Speed = {Enabled = false, Value = 16},
    Jump = {Enabled = false, Value = 50}
}

function Handler_Physics.Update(dt)
    if not LocalPlayer.Character then return end
    local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not Root or not Hum then return end

    if Handler_Physics.Options.Fly.Enabled then
        Hum.PlatformStand = true
        Hum:ChangeState(Enum.HumanoidStateType.Physics)
        
        local CamCF = Camera.CFrame
        local Vel = Vector3.zero
        
        if Handler_Input.State.W then Vel = Vel + CamCF.LookVector end
        if Handler_Input.State.S then Vel = Vel - CamCF.LookVector end
        if Handler_Input.State.A then Vel = Vel - CamCF.RightVector end
        if Handler_Input.State.D then Vel = Vel + CamCF.RightVector end
        
        local FinalVel = Vel.Unit * Handler_Physics.Options.Fly.Speed
        if FinalVel.X ~= FinalVel.X then FinalVel = Vector3.zero end
        
        local Y = 0
        if Handler_Input.State.Space then Y = Handler_Physics.Options.Fly.Vertical end
        if Handler_Input.State.Ctrl then Y = -Handler_Physics.Options.Fly.Vertical end
        
        Root.AssemblyLinearVelocity = Vector3.new(FinalVel.X, Y, FinalVel.Z)
        Root.AssemblyAngularVelocity = Vector3.zero
    else
        if Hum.PlatformStand then Hum.PlatformStand = false end
    end
    
    if Handler_Physics.Options.Speed.Enabled then
        Hum.WalkSpeed = Handler_Physics.Options.Speed.Value
    end
    
    if Handler_Physics.Options.Jump.Enabled then
        Hum.UseJumpPower = true
        Hum.JumpPower = Handler_Physics.Options.Jump.Value
    end
    
    if Handler_Physics.Options.NoClip.Enabled then
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end

local Handler_Visuals = {}
Handler_Visuals.Pool = {}
Handler_Visuals.Options = {ESP = false, Distance = 2000, Fullbright = false}

function Handler_Visuals.Refresh()
    if not Handler_Visuals.Options.ESP then
        for _, v in pairs(Handler_Visuals.Pool) do v:Destroy() end
        Handler_Visuals.Pool = {}
        return
    end
    
    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr ~= LocalPlayer and Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
            local Root = Plr.Character.HumanoidRootPart
            local Dist = (Root.Position - Camera.CFrame.Position).Magnitude
            
            if Dist <= Handler_Visuals.Options.Distance then
                if not Handler_Visuals.Pool[Plr] then
                    local HL = Instance.new("Highlight")
                    HL.FillColor = Color3.fromRGB(255, 0, 0)
                    HL.OutlineColor = Color3.fromRGB(255, 255, 255)
                    HL.FillTransparency = 0.5
                    HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    HL.Parent = Plr.Character
                    Handler_Visuals.Pool[Plr] = HL
                elseif Handler_Visuals.Pool[Plr].Parent ~= Plr.Character then
                     Handler_Visuals.Pool[Plr].Parent = Plr.Character
                end
            else
                if Handler_Visuals.Pool[Plr] then
                    Handler_Visuals.Pool[Plr]:Destroy()
                    Handler_Visuals.Pool[Plr] = nil
                end
            end
        else
            if Handler_Visuals.Pool[Plr] then
                Handler_Visuals.Pool[Plr]:Destroy()
                Handler_Visuals.Pool[Plr] = nil
            end
        end
    end
end

function Handler_Visuals.EnvUpdate()
    if Handler_Visuals.Options.Fullbright then
        Lighting.ClockTime = 12
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    end
end

local Handler_Network = {}
function Handler_Network.Bypass()
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self.Name == "Ban" then return end
        return old(self, ...)
    end)
end

Handler_Input.Init()

table.insert(Runtime.Connections, RunService.RenderStepped:Connect(function(dt)
    Secure(function() Handler_Physics.Update(dt) end)
end))

table.insert(Runtime.Connections, RunService.Heartbeat:Connect(function()
    Secure(function()
        if tick() % 0.5 < 0.1 then Handler_Visuals.Refresh() end
        Handler_Visuals.EnvUpdate()
    end)
end))

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Nexus | Handler Architecture",
    LoadingTitle = "Initializing Handlers...",
    LoadingSubtitle = "Authentication Success",
    ConfigurationSaving = {Enabled = true, FolderName = "Nexus", FileName = "Cfg"},
    KeySystem = false,
})

local Tab_Main = Window:CreateTab("Kinematics", 4483362458)
local Tab_Vis = Window:CreateTab("Visuals", 4483362458)

Tab_Main:CreateToggle({
    Name = "Linear Velocity Fly",
    CurrentValue = false,
    Callback = function(v) Handler_Physics.Options.Fly.Enabled = v end
})

Tab_Main:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 1,
    CurrentValue = 60,
    Callback = function(v) Handler_Physics.Options.Fly.Speed = v end
})

Tab_Main:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) Handler_Physics.Options.NoClip.Enabled = v end
})

Tab_Main:CreateToggle({
    Name = "WalkSpeed Override",
    CurrentValue = false,
    Callback = function(v) Handler_Physics.Options.Speed.Enabled = v end
})

Tab_Main:CreateSlider({
    Name = "Speed Value",
    Range = {16, 300},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v) Handler_Physics.Options.Speed.Value = v end
})

Tab_Vis:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(v) Handler_Visuals.Options.ESP = v end
})

Tab_Vis:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v) Handler_Visuals.Options.Fullbright = v end
})

Rayfield:LoadConfiguration()
Secure(Handler_Network.Bypass)
