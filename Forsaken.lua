local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local sethidden = sethiddenproperty or function(...) end
local gethidden = gethiddenproperty or function(...) return nil end
local hookmeta = hookmetamethod or function(...) end

local Runtime = {
    Void = nil,
    Graphics = {},
    Network = {},
    Input = {},
    World = {},
    Files = {},
    Security = {},
    State = {
        Authenticated = false,
        Key = "test",
        Version = "9.9.9-APEX"
    }
}

local Services = setmetatable({}, {
    __index = function(self, key)
        local s = game:GetService(key)
        rawset(self, key, cloneref(s))
        return s
    end
})

local Utils = {}
function Utils.randomString(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local ret = ""
    for i = 1, len do
        local r = math.random(1, #chars)
        ret = ret .. string.sub(chars, r, r)
    end
    return ret
end

function Utils.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.deepCopy(orig_key)] = Utils.deepCopy(orig_value)
        end
        setmetatable(copy, Utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local Signal = {}
Signal.__index = Signal
function Signal.new()
    local self = setmetatable({}, Signal)
    self._bindable = Instance.new("BindableEvent")
    self._args = {}
    return self
end
function Signal:Connect(callback)
    return self._bindable.Event:Connect(function(key)
        callback(table.unpack(self._args[key] or {}))
        self._args[key] = nil
    end)
end
function Signal:Fire(...)
    local key = tostring(os.clock()) .. Utils.randomString(10)
    self._args[key] = {...}
    self._bindable:Fire(key)
end
function Signal:Destroy()
    self._bindable:Destroy()
end

local Janitor = {}
Janitor.__index = Janitor
function Janitor.new()
    return setmetatable({_objects = {}}, Janitor)
end
function Janitor:Add(object, method)
    table.insert(self._objects, {obj = object, met = method})
    return object
end
function Janitor:Clean()
    for _, item in ipairs(self._objects) do
        if type(item.obj) == "function" then
            item.obj()
        elseif type(item.obj) == "table" and item.obj.Destroy then
            item.obj:Destroy()
        elseif item.obj and item.met and item.obj[item.met] then
            item.obj[item.met](item.obj)
        elseif item.obj and typeof(item.obj) == "RBXScriptConnection" then
            item.obj:Disconnect()
        end
    end
    self._objects = {}
end

local SecurityHandler = {}
SecurityHandler.Flags = {
    BypassTeleport = true,
    AntiKick = true,
    Spoiler = false
}
function SecurityHandler.Init()
    local Meta = getrawmetatable(game)
    local OldNameCall = Meta.__namecall
    setreadonly(Meta, false)
    Meta.__namecall = newcclosure(function(self, ...)
        local Method = getnamecallmethod()
        local Args = {...}
        if SecurityHandler.Flags.AntiKick and (Method == "Kick" or Method == "kick") then
            return nil
        end
        if SecurityHandler.Flags.BypassTeleport and Method == "Teleport" then
            return nil
        end
        return OldNameCall(self, ...)
    end)
    setreadonly(Meta, true)
end

local AuthHandler = {}
function AuthHandler.Execute()
    if Runtime.State.Authenticated then return true end
    
    local Screen = Instance.new("ScreenGui")
    Screen.Name = Utils.randomString(20)
    Screen.Parent = Services.CoreGui
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Screen.IgnoreGuiInset = true

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    Frame.Parent = Screen

    local Center = Instance.new("Frame")
    Center.Size = UDim2.new(0, 400, 0, 250)
    Center.AnchorPoint = Vector2.new(0.5, 0.5)
    Center.Position = UDim2.new(0.5, 0, 0.5, 0)
    Center.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Center.BorderSizePixel = 0
    Center.Parent = Frame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Center
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(60, 60, 255)
    Stroke.Thickness = 2
    Stroke.Parent = Center

    local Title = Instance.new("TextLabel")
    Title.Text = "SYSTEM ACCESS"
    Title.Size = UDim2.new(1, 0, 0.2, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 24
    Title.Parent = Center

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0.8, 0, 0.2, 0)
    Box.Position = UDim2.new(0.1, 0, 0.4, 0)
    Box.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.PlaceholderText = "Input Security Key"
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 16
    Box.Parent = Center
    
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.Parent = Box
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.8, 0, 0.2, 0)
    Btn.Position = UDim2.new(0.1, 0, 0.7, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 200)
    Btn.Text = "AUTHENTICATE"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.Parent = Center
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.Parent = Btn
    
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, 0, 0.1, 0)
    Status.Position = UDim2.new(0, 0, 0.9, 0)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(255, 50, 50)
    Status.Font = Enum.Font.Gotham
    Status.Parent = Center
    
    local Waiting = true
    
    Btn.MouseButton1Click:Connect(function()
        if Box.Text == Runtime.State.Key then
            Status.TextColor3 = Color3.fromRGB(50, 255, 50)
            Status.Text = "ACCESS GRANTED"
            Runtime.State.Authenticated = true
            task.wait(1)
            Screen:Destroy()
            Waiting = false
        else
            Status.TextColor3 = Color3.fromRGB(255, 50, 50)
            Status.Text = "INVALID KEY"
            Box.Text = ""
        end
    end)
    
    repeat task.wait(0.1) until not Waiting
end

local InputHandler = {}
InputHandler.State = {
    W = false, A = false, S = false, D = false,
    Space = false, Ctrl = false, Shift = false
}
InputHandler.Janitor = Janitor.new()

function InputHandler.Start()
    InputHandler.Janitor:Clean()
    
    InputHandler.Janitor:Add(Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.W then InputHandler.State.W = true end
        if input.KeyCode == Enum.KeyCode.A then InputHandler.State.A = true end
        if input.KeyCode == Enum.KeyCode.S then InputHandler.State.S = true end
        if input.KeyCode == Enum.KeyCode.D then InputHandler.State.D = true end
        if input.KeyCode == Enum.KeyCode.Space then InputHandler.State.Space = true end
        if input.KeyCode == Enum.KeyCode.LeftControl then InputHandler.State.Ctrl = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then InputHandler.State.Shift = true end
    end))
    
    InputHandler.Janitor:Add(Services.UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then InputHandler.State.W = false end
        if input.KeyCode == Enum.KeyCode.A then InputHandler.State.A = false end
        if input.KeyCode == Enum.KeyCode.S then InputHandler.State.S = false end
        if input.KeyCode == Enum.KeyCode.D then InputHandler.State.D = false end
        if input.KeyCode == Enum.KeyCode.Space then InputHandler.State.Space = false end
        if input.KeyCode == Enum.KeyCode.LeftControl then InputHandler.State.Ctrl = false end
        if input.KeyCode == Enum.KeyCode.LeftShift then InputHandler.State.Shift = false end
    end))
end

local PhysicsHandler = {}
PhysicsHandler.Janitor = Janitor.new()
PhysicsHandler.Config = {
    Fly = {Enabled = false, Speed = 50, Vertical = 50, Bypass = true},
    Speed = {Enabled = false, Value = 16},
    Jump = {Enabled = false, Value = 50},
    NoClip = {Enabled = false}
}

function PhysicsHandler.GetRoot()
    if Services.Players.LocalPlayer.Character then
        return Services.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

function PhysicsHandler.GetHumanoid()
    if Services.Players.LocalPlayer.Character then
        return Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    end
    return nil
end

function PhysicsHandler.Update(dt)
    local Root = PhysicsHandler.GetRoot()
    local Hum = PhysicsHandler.GetHumanoid()
    
    if not Root or not Hum then return end
    
    if PhysicsHandler.Config.Fly.Enabled then
        Hum.PlatformStand = true
        Hum:ChangeState(Enum.HumanoidStateType.Physics)
        
        local CamCF = Services.Workspace.CurrentCamera.CFrame
        local MoveVector = Vector3.zero
        
        if InputHandler.State.W then MoveVector = MoveVector + CamCF.LookVector end
        if InputHandler.State.S then MoveVector = MoveVector - CamCF.LookVector end
        if InputHandler.State.A then MoveVector = MoveVector - CamCF.RightVector end
        if InputHandler.State.D then MoveVector = MoveVector + CamCF.RightVector end
        
        if MoveVector.Magnitude > 0 then
            MoveVector = MoveVector.Unit * PhysicsHandler.Config.Fly.Speed
        end
        
        local YVector = 0
        if InputHandler.State.Space then YVector = PhysicsHandler.Config.Fly.Vertical end
        if InputHandler.State.Ctrl then YVector = -PhysicsHandler.Config.Fly.Vertical end
        
        if PhysicsHandler.Config.Fly.Bypass then
            Root.AssemblyLinearVelocity = Vector3.new(MoveVector.X, YVector, MoveVector.Z)
            Root.AssemblyAngularVelocity = Vector3.zero
        else
            local BV = Root:FindFirstChild("HandlerFlightVelocity") or Instance.new("BodyVelocity")
            BV.Name = "HandlerFlightVelocity"
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            BV.Velocity = Vector3.new(MoveVector.X, YVector, MoveVector.Z)
            BV.Parent = Root
        end
    else
        if Hum.PlatformStand then Hum.PlatformStand = false end
        local BV = Root:FindFirstChild("HandlerFlightVelocity")
        if BV then BV:Destroy() end
    end
    
    if PhysicsHandler.Config.Speed.Enabled then
        Hum.WalkSpeed = PhysicsHandler.Config.Speed.Value
    end
    
    if PhysicsHandler.Config.Jump.Enabled then
        Hum.UseJumpPower = true
        Hum.JumpPower = PhysicsHandler.Config.Jump.Value
    end
    
    if PhysicsHandler.Config.NoClip.Enabled then
        for _, part in ipairs(Services.Players.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end

function PhysicsHandler.Start()
    PhysicsHandler.Janitor:Clean()
    PhysicsHandler.Janitor:Add(Services.RunService.RenderStepped:Connect(PhysicsHandler.Update))
end

local VisualsHandler = {}
VisualsHandler.Janitor = Janitor.new()
VisualsHandler.Cache = {}
VisualsHandler.Config = {
    ESP = {Enabled = false, Distance = 1000, Tracers = false, Boxes = true},
    World = {Fullbright = false, NoFog = false}
}

function VisualsHandler.DrawESP(plr)
    if not VisualsHandler.Config.ESP.Enabled then return end
    if plr == Services.Players.LocalPlayer then return end
    
    local Char = plr.Character
    if not Char then return end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    
    local Dist = (Services.Workspace.CurrentCamera.CFrame.Position - Root.Position).Magnitude
    if Dist > VisualsHandler.Config.ESP.Distance then return end
    
    if not VisualsHandler.Cache[plr] then
        VisualsHandler.Cache[plr] = {
            Box = Instance.new("Highlight"),
            Name = Drawing.new("Text")
        }
        VisualsHandler.Cache[plr].Box.Parent = Services.CoreGui
    end
    
    local Cache = VisualsHandler.Cache[plr]
    
    if VisualsHandler.Config.ESP.Boxes then
        Cache.Box.Parent = Char
        Cache.Box.FillColor = Color3.fromRGB(255, 0, 0)
        Cache.Box.OutlineColor = Color3.fromRGB(255, 255, 255)
        Cache.Box.FillTransparency = 0.6
    else
        Cache.Box.Parent = nil
    end
end

function VisualsHandler.Update()
    if not VisualsHandler.Config.ESP.Enabled then
        for _, v in pairs(VisualsHandler.Cache) do
            if v.Box then v.Box:Destroy() end
        end
        VisualsHandler.Cache = {}
    else
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            VisualsHandler.DrawESP(plr)
        end
    end
    
    if VisualsHandler.Config.World.Fullbright then
        Services.Lighting.Brightness = 2
        Services.Lighting.ClockTime = 14
        Services.Lighting.GlobalShadows = false
        Services.Lighting.Ambient = Color3.new(1,1,1)
    end
    
    if VisualsHandler.Config.World.NoFog then
        Services.Lighting.FogEnd = 9e9
        for _, v in ipairs(Services.Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then v:Destroy() end
        end
    end
end

function VisualsHandler.Start()
    VisualsHandler.Janitor:Clean()
    VisualsHandler.Janitor:Add(Services.RunService.Heartbeat:Connect(VisualsHandler.Update))
end

local UIHandler = {}
function UIHandler.Load()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Window = Rayfield:CreateWindow({
        Name = "APEX FRAMEWORK | " .. Runtime.State.Version,
        LoadingTitle = "Initializing Handlers...",
        LoadingSubtitle = "Authentication Validated",
        ConfigurationSaving = {Enabled = true, FolderName = "Apex", FileName = "Config"},
        KeySystem = false,
    })
    
    local MainTab = Window:CreateTab("Kinematics", 4483362458)
    local VisTab = Window:CreateTab("Visuals", 4483362458)
    
    MainTab:CreateSection("Movement Physics")
    
    MainTab:CreateToggle({
        Name = "Assembly Linear Fly",
        CurrentValue = false,
        Callback = function(v) PhysicsHandler.Config.Fly.Enabled = v end
    })
    
    MainTab:CreateSlider({
        Name = "Flight Speed",
        Range = {1, 500},
        Increment = 1,
        CurrentValue = 50,
        Callback = function(v) PhysicsHandler.Config.Fly.Speed = v end
    })
    
    MainTab:CreateToggle({
        Name = "Collision Bypass",
        CurrentValue = false,
        Callback = function(v) PhysicsHandler.Config.NoClip.Enabled = v end
    })
    
    MainTab:CreateToggle({
        Name = "Speed Override",
        CurrentValue = false,
        Callback = function(v) PhysicsHandler.Config.Speed.Enabled = v end
    })
    
    MainTab:CreateSlider({
        Name = "Speed Value",
        Range = {16, 300},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(v) PhysicsHandler.Config.Speed.Value = v end
    })
    
    VisTab:CreateSection("ESP Controller")
    
    VisTab:CreateToggle({
        Name = "Player ESP",
        CurrentValue = false,
        Callback = function(v) VisualsHandler.Config.ESP.Enabled = v end
    })
    
    VisTab:CreateToggle({
        Name = "Fullbright",
        CurrentValue = false,
        Callback = function(v) VisualsHandler.Config.World.Fullbright = v end
    })
    
    Rayfield:LoadConfiguration()
end

local Core = {}
function Core.Initialize()
    SecurityHandler.Init()
    AuthHandler.Execute()
    InputHandler.Start()
    PhysicsHandler.Start()
    VisualsHandler.Start()
    UIHandler.Load()
end

Core.Initialize()
