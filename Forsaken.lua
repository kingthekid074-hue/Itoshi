local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local sethidden = sethiddenproperty or function(...) end
local gethidden = gethiddenproperty or function(...) return nil end
local hookmeta = hookmetamethod or function(...) end

local Runtime = {
    Kernel = {
        Threads = {},
        Connections = {},
        Instances = {},
        Hooks = {},
        Signals = {}
    },
    Services = setmetatable({}, {
        __index = function(self, key)
            local s = game:GetService(key)
            rawset(self, key, cloneref(s))
            return s
        end
    })
}

local function SafeCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then return nil end
    return r
end

local function DisconnectKernel()
    for _, c in pairs(Runtime.Kernel.Connections) do if typeof(c) == "RBXScriptConnection" then c:Disconnect() end end
    for _, t in pairs(Runtime.Kernel.Threads) do task.cancel(t) end
    for _, i in pairs(Runtime.Kernel.Instances) do if i then i:Destroy() end end
    Runtime.Kernel = {Threads={}, Connections={}, Instances={}, Hooks={}, Signals={}}
end

DisconnectKernel()

local Library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Utils = {}
function Utils.NewVec3(x, y, z) return Vector3.new(x, y, z) end
function Utils.NewCFrame(pos, look) return CFrame.new(pos, look) end
function Utils.GetRoot(char) return char:FindFirstChild("HumanoidRootPart") end
function Utils.GetHum(char) return char:FindFirstChild("Humanoid") end

local Signal = {}
Signal.__index = Signal
function Signal.new()
    local self = setmetatable({}, Signal)
    self._bindable = Instance.new("BindableEvent")
    table.insert(Runtime.Kernel.Instances, self._bindable)
    return self
end
function Signal:Connect(cb)
    return self._bindable.Event:Connect(cb)
end
function Signal:Fire(...)
    self._bindable:Fire(...)
end

local Vector = {}
Vector.__index = Vector
function Vector.new(x, y, z)
    return setmetatable({x = x or 0, y = y or 0, z = z or 0}, Vector)
end
function Vector:Add(v) return Vector.new(self.x + v.x, self.y + v.y, self.z + v.z) end
function Vector:Sub(v) return Vector.new(self.x - v.x, self.y - v.y, self.z - v.z) end
function Vector:Mul(n) return Vector.new(self.x * n, self.y * n, self.z * n) end
function Vector:ToVector3() return Vector3.new(self.x, self.y, self.z) end

local PhysicsManager = {}
PhysicsManager.State = {
    Fly = {
        Active = false,
        Speed = 80,
        VerticalSpeed = 50,
        Acceleration = 5,
        Deceleration = 0.5,
        Velocity = Vector.new(0, 0, 0),
        MaxSpeed = 500,
        Mode = "Velocity", 
        Keys = {W=false, A=false, S=false, D=false, Up=false, Down=false}
    },
    Character = {
        Speed = {Active = false, Val = 16},
        Jump = {Active = false, Val = 50},
        NoClip = {Active = false},
        InfStamina = {Active = false},
        AntiRagdoll = {Active = false}
    }
}

function PhysicsManager.FlyLogic(dt)
    if not PhysicsManager.State.Fly.Active then return end
    local Plr = Runtime.Services.Players.LocalPlayer
    local Char = Plr.Character
    if not Char then return end
    local Root = Utils.GetRoot(Char)
    local Hum = Utils.GetHum(Char)
    if not Root or not Hum then return end

    Hum.PlatformStand = true
    Hum:ChangeState(Enum.HumanoidStateType.Physics)

    local Cam = Runtime.Services.Workspace.CurrentCamera.CFrame
    local TargetVel = Vector.new(0,0,0)
    local Keys = PhysicsManager.State.Fly.Keys

    if Keys.W then TargetVel = TargetVel:Add(Vector.new(Cam.LookVector.X, Cam.LookVector.Y, Cam.LookVector.Z)) end
    if Keys.S then TargetVel = TargetVel:Sub(Vector.new(Cam.LookVector.X, Cam.LookVector.Y, Cam.LookVector.Z)) end
    if Keys.A then TargetVel = TargetVel:Sub(Vector.new(Cam.RightVector.X, Cam.RightVector.Y, Cam.RightVector.Z)) end
    if Keys.D then TargetVel = TargetVel:Add(Vector.new(Cam.RightVector.X, Cam.RightVector.Y, Cam.RightVector.Z)) end
    
    local VSpeed = 0
    if Keys.Up then VSpeed = PhysicsManager.State.Fly.VerticalSpeed end
    if Keys.Down then VSpeed = -PhysicsManager.State.Fly.VerticalSpeed end

    local Normalized = TargetVel:ToVector3().Unit
    if Normalized.X ~= Normalized.X then Normalized = Vector3.zero end
    
    local FinalSpeed = PhysicsManager.State.Fly.Speed
    local NewVelocity = Normalized * FinalSpeed
    
    local Attachment = Root:FindFirstChild("TitaniumFlyAtt") or Instance.new("Attachment")
    Attachment.Name = "TitaniumFlyAtt"
    Attachment.Parent = Root
    
    local LinearVelocity = Root:FindFirstChild("TitaniumFlyVel") or Instance.new("LinearVelocity")
    LinearVelocity.Name = "TitaniumFlyVel"
    LinearVelocity.Attachment0 = Attachment
    LinearVelocity.MaxForce = 9e9
    LinearVelocity.VectorVelocity = Vector3.new(NewVelocity.X, VSpeed ~= 0 and VSpeed or NewVelocity.Y, NewVelocity.Z)
    LinearVelocity.Parent = Root
    
    local AlignOrientation = Root:FindFirstChild("TitaniumFlyRot") or Instance.new("AlignOrientation")
    AlignOrientation.Name = "TitaniumFlyRot"
    AlignOrientation.Attachment0 = Attachment
    AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    AlignOrientation.CFrame = Cam
    AlignOrientation.MaxTorque = 9e9
    AlignOrientation.Responsiveness = 200
    AlignOrientation.Parent = Root

    if not table.find(Runtime.Kernel.Instances, Attachment) then
        table.insert(Runtime.Kernel.Instances, Attachment)
        table.insert(Runtime.Kernel.Instances, LinearVelocity)
        table.insert(Runtime.Kernel.Instances, AlignOrientation)
    end
end

function PhysicsManager.CharacterLogic()
    local Plr = Runtime.Services.Players.LocalPlayer
    local Char = Plr.Character
    if not Char then return end
    local Hum = Utils.GetHum(Char)
    if not Hum then return end

    if PhysicsManager.State.Character.Speed.Active then
        Hum.WalkSpeed = PhysicsManager.State.Character.Speed.Val
    end
    
    if PhysicsManager.State.Character.Jump.Active then
        Hum.UseJumpPower = true
        Hum.JumpPower = PhysicsManager.State.Character.Jump.Val
    end
    
    if PhysicsManager.State.Character.NoClip.Active then
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
    
    if PhysicsManager.State.Character.InfStamina.Active then
        local Stamina = Char:FindFirstChild("Stamina")
        if Stamina then Stamina.Value = 100 end
    end
    
    if PhysicsManager.State.Character.AntiRagdoll.Active then
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end
end

local InputManager = {}
function InputManager.Init()
    local Input = Runtime.Services.UserInputService
    table.insert(Runtime.Kernel.Connections, Input.InputBegan:Connect(function(io, gp)
        if gp then return end
        if io.KeyCode == Enum.KeyCode.W then PhysicsManager.State.Fly.Keys.W = true end
        if io.KeyCode == Enum.KeyCode.A then PhysicsManager.State.Fly.Keys.A = true end
        if io.KeyCode == Enum.KeyCode.S then PhysicsManager.State.Fly.Keys.S = true end
        if io.KeyCode == Enum.KeyCode.D then PhysicsManager.State.Fly.Keys.D = true end
        if io.KeyCode == Enum.KeyCode.Space then PhysicsManager.State.Fly.Keys.Up = true end
        if io.KeyCode == Enum.KeyCode.LeftControl then PhysicsManager.State.Fly.Keys.Down = true end
    end))
    
    table.insert(Runtime.Kernel.Connections, Input.InputEnded:Connect(function(io)
        if io.KeyCode == Enum.KeyCode.W then PhysicsManager.State.Fly.Keys.W = false end
        if io.KeyCode == Enum.KeyCode.A then PhysicsManager.State.Fly.Keys.A = false end
        if io.KeyCode == Enum.KeyCode.S then PhysicsManager.State.Fly.Keys.S = false end
        if io.KeyCode == Enum.KeyCode.D then PhysicsManager.State.Fly.Keys.D = false end
        if io.KeyCode == Enum.KeyCode.Space then PhysicsManager.State.Fly.Keys.Up = false end
        if io.KeyCode == Enum.KeyCode.LeftControl then PhysicsManager.State.Fly.Keys.Down = false end
    end))
end

local VisualsManager = {}
VisualsManager.Settings = {
    ESP = {
        Enabled = false,
        Boxes = true,
        Names = true,
        Health = true,
        Distance = true,
        Tracers = false,
        MaxDist = 3000,
        FillColor = Color3.fromRGB(255, 0, 0),
        OutlineColor = Color3.fromRGB(255, 255, 255)
    },
    World = {
        Fullbright = false,
        NoFog = false,
        Ambience = Color3.new(1,1,1)
    }
}
VisualsManager.Cache = {}

function VisualsManager.Draw(plr)
    if not VisualsManager.Settings.ESP.Enabled then return end
    if plr == Runtime.Services.Players.LocalPlayer then return end
    
    local Char = plr.Character
    if not Char then return end
    local Root = Utils.GetRoot(Char)
    if not Root then return end
    
    local Dist = (Runtime.Services.Workspace.CurrentCamera.CFrame.Position - Root.Position).Magnitude
    if Dist > VisualsManager.Settings.ESP.MaxDist then 
        if VisualsManager.Cache[plr] then
            VisualsManager.Cache[plr].Highlight:Destroy()
            VisualsManager.Cache[plr] = nil
        end
        return 
    end
    
    if not VisualsManager.Cache[plr] then
        VisualsManager.Cache[plr] = {
            Highlight = Instance.new("Highlight")
        }
        VisualsManager.Cache[plr].Highlight.Parent = Runtime.Services.CoreGui
    end
    
    local HL = VisualsManager.Cache[plr].Highlight
    HL.Adornee = Char
    HL.FillColor = VisualsManager.Settings.ESP.FillColor
    HL.OutlineColor = VisualsManager.Settings.ESP.OutlineColor
    HL.FillTransparency = 0.5
    HL.OutlineTransparency = 0
    HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    HL.Parent = Char
end

function VisualsManager.Update()
    if not VisualsManager.Settings.ESP.Enabled then
        for i, v in pairs(VisualsManager.Cache) do
            if v.Highlight then v.Highlight:Destroy() end
        end
        VisualsManager.Cache = {}
    else
        for _, p in ipairs(Runtime.Services.Players:GetPlayers()) do
            VisualsManager.Draw(p)
        end
    end
    
    if VisualsManager.Settings.World.Fullbright then
        Runtime.Services.Lighting.Brightness = 2
        Runtime.Services.Lighting.ClockTime = 14
        Runtime.Services.Lighting.GlobalShadows = false
        Runtime.Services.Lighting.Ambient = VisualsManager.Settings.World.Ambience
        Runtime.Services.Lighting.OutdoorAmbient = VisualsManager.Settings.World.Ambience
    end
    
    if VisualsManager.Settings.World.NoFog then
        Runtime.Services.Lighting.FogEnd = 1e9
        for _, v in ipairs(Runtime.Services.Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then v:Destroy() end
        end
    end
end

local AutoFarmManager = {}
AutoFarmManager.Config = {
    Active = false,
    Method = "Tween", 
    Target = "Closest",
    Distance = 10,
    Delay = 0.1
}

function AutoFarmManager.GetTarget()
    local Closest = nil
    local MaxDist = 9e9
    for _, v in ipairs(Runtime.Services.Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= Runtime.Services.Players.LocalPlayer.Character then
            local Root = Utils.GetRoot(v)
            if Root then
                local Dist = (Utils.GetRoot(Runtime.Services.Players.LocalPlayer.Character).Position - Root.Position).Magnitude
                if Dist < MaxDist then
                    MaxDist = Dist
                    Closest = Root
                end
            end
        end
    end
    return Closest
end

function AutoFarmManager.Loop()
    if not AutoFarmManager.Config.Active then return end
    local Target = AutoFarmManager.GetTarget()
    if Target then
        local Root = Utils.GetRoot(Runtime.Services.Players.LocalPlayer.Character)
        if Root then
            Root.CFrame = Target.CFrame * CFrame.new(0, 0, AutoFarmManager.Config.Distance)
            -- Attack logic here
        end
    end
end

local Interface = {}
function Interface.Load()
    local Window = Library:CreateWindow({
        Name = "Titanium Core | Forsaken",
        LoadingTitle = "Initializing Kernel...",
        LoadingSubtitle = "Bypassing Physics Engine...",
        ConfigurationSaving = {Enabled = true, FolderName = "Titanium", FileName = "Forsaken"},
        KeySystem = false, 
    })
    
    local TabMain = Window:CreateTab("Kinematics", 4483362458)
    local TabVis = Window:CreateTab("Visuals", 4483362458)
    local TabWorld = Window:CreateTab("World", 4483362458)
    local TabFarm = Window:CreateTab("Automation", 4483362458)

    TabMain:CreateSection("Flight Engine (LinearVelocity)")
    
    TabMain:CreateToggle({
        Name = "Enable Flight",
        CurrentValue = false,
        Callback = function(v) 
            PhysicsManager.State.Fly.Active = v
            if not v then
                local Char = Runtime.Services.Players.LocalPlayer.Character
                if Char then
                    local Root = Utils.GetRoot(Char)
                    local Hum = Utils.GetHum(Char)
                    if Root then
                        for _, c in pairs(Root:GetChildren()) do
                            if c.Name:find("Titanium") then c:Destroy() end
                        end
                    end
                    if Hum then Hum.PlatformStand = false Hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
                end
            end
        end
    })
    
    TabMain:CreateSlider({
        Name = "Flight Speed",
        Range = {10, 500},
        Increment = 1,
        CurrentValue = 80,
        Callback = function(v) PhysicsManager.State.Fly.Speed = v end
    })
    
    TabMain:CreateSlider({
        Name = "Vertical Velocity",
        Range = {10, 300},
        Increment = 1,
        CurrentValue = 50,
        Callback = function(v) PhysicsManager.State.Fly.VerticalSpeed = v end
    })

    TabMain:CreateSection("Character Physics")
    
    TabMain:CreateToggle({
        Name = "Speed Hack",
        CurrentValue = false,
        Callback = function(v) PhysicsManager.State.Character.Speed.Active = v end
    })
    
    TabMain:CreateSlider({
        Name = "WalkSpeed",
        Range = {16, 400},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(v) PhysicsManager.State.Character.Speed.Val = v end
    })
    
    TabMain:CreateToggle({
        Name = "Jump Boost",
        CurrentValue = false,
        Callback = function(v) PhysicsManager.State.Character.Jump.Active = v end
    })
    
    TabMain:CreateSlider({
        Name = "Jump Power",
        Range = {50, 500},
        Increment = 1,
        CurrentValue = 50,
        Callback = function(v) PhysicsManager.State.Character.Jump.Val = v end
    })
    
    TabMain:CreateToggle({
        Name = "Phase (Noclip)",
        CurrentValue = false,
        Callback = function(v) PhysicsManager.State.Character.NoClip.Active = v end
    })
    
    TabMain:CreateToggle({
        Name = "Infinite Stamina",
        CurrentValue = false,
        Callback = function(v) PhysicsManager.State.Character.InfStamina.Active = v end
    })

    TabVis:CreateSection("ESP Controller")
    
    TabVis:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = false,
        Callback = function(v) VisualsManager.Settings.ESP.Enabled = v end
    })
    
    TabVis:CreateColorPicker({
        Name = "ESP Fill Color",
        Color = Color3.fromRGB(255, 0, 0),
        Callback = function(v) VisualsManager.Settings.ESP.FillColor = v end
    })
    
    TabVis:CreateSlider({
        Name = "Render Distance",
        Range = {100, 5000},
        Increment = 100,
        CurrentValue = 3000,
        Callback = function(v) VisualsManager.Settings.ESP.MaxDist = v end
    })
    
    TabWorld:CreateSection("Environment")
    
    TabWorld:CreateToggle({
        Name = "Fullbright",
        CurrentValue = false,
        Callback = function(v) VisualsManager.Settings.World.Fullbright = v end
    })
    
    TabWorld:CreateToggle({
        Name = "No Fog",
        CurrentValue = false,
        Callback = function(v) VisualsManager.Settings.World.NoFog = v end
    })
    
    TabFarm:CreateToggle({
        Name = "Auto Farm (Closest)",
        CurrentValue = false,
        Callback = function(v) AutoFarmManager.Config.Active = v end
    })
    
    Library:LoadConfiguration()
end

local Core = {}
function Core.Boot()
    InputManager.Init()
    
    table.insert(Runtime.Kernel.Connections, Runtime.Services.RunService.RenderStepped:Connect(function(dt)
        SafeCall(PhysicsManager.FlyLogic, dt)
    end))
    
    table.insert(Runtime.Kernel.Connections, Runtime.Services.RunService.Stepped:Connect(function()
        SafeCall(PhysicsManager.CharacterLogic)
        SafeCall(AutoFarmManager.Loop)
    end))
    
    table.insert(Runtime.Kernel.Connections, Runtime.Services.RunService.Heartbeat:Connect(function()
        if tick() % 0.1 < 0.05 then
            SafeCall(VisualsManager.Update)
        end
    end))
    
    Interface.Load()
end

Core.Boot()
