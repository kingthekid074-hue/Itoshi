local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end
local Services = setmetatable({}, {__index = function(t, k) return cloneref(game:GetService(k)) end})

-- SERVICES
local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local ReplicatedStorage = Services.ReplicatedStorage
local VirtualInputManager = Services.VirtualInputManager
local CoreGui = Services.CoreGui
local Lighting = Services.Lighting

local LocalPlayer = Players.LocalPlayer

-- CONFIG
local Itoshi = {
    Settings = {
        Combat = {
            KillAura = {Enabled = true, Range = 25},
            AutoBlock = {Enabled = true, Range = 20, AutoFace = true},
            Hitbox = {Enabled = true, Size = 25}
        },
        Utility = {
            AutoGenerator = {
                Enabled = false,
                InstantFix = true, -- Uses Remote RF found in video
                Teleport = false   
            }
        },
        Visuals = {
            ESP = {Enabled = false},
            GenESP = {Enabled = false},
            Fullbright = false
        }
    },
    Cache = {
        Generators = {}
    }
}

-- KEY SYSTEM
if not getgenv().ItoshiAuth then
    local S = Instance.new("ScreenGui", CoreGui)
    local F = Instance.new("Frame", S)
    F.Size = UDim2.new(0,300,0,150)
    F.Position = UDim2.new(0.5,-150,0.5,-75)
    F.BackgroundColor3 = Color3.fromRGB(15,15,15)
    local B = Instance.new("TextBox", F)
    B.Size = UDim2.new(0.8,0,0.3,0)
    B.Position = UDim2.new(0.1,0,0.3,0)
    B.Text = ""
    B.PlaceholderText = "Key..."
    local Btn = Instance.new("TextButton", F)
    Btn.Size = UDim2.new(0.8,0,0.3,0)
    Btn.Position = UDim2.new(0.1,0,0.65,0)
    Btn.Text = "INJECT REMOTE EXPLOIT"
    Btn.BackgroundColor3 = Color3.fromRGB(0,150,255)
    
    Btn.MouseButton1Click:Connect(function()
        if B.Text == "FFDGDLFYUFOHDWHHFXX" then
            S:Destroy()
            getgenv().ItoshiAuth = true
        end
    end)
    repeat task.wait(0.1) until getgenv().ItoshiAuth
end

-- // GENERATOR EXPLOIT (THE MAGIC) //
local GenSys = {}

function GenSys.Refresh()
    table.clear(Itoshi.Cache.Generators)
    -- Specific path from your screenshot/video
    local Map = Workspace:FindFirstChild("Map")
    local Ingame = Map and Map:FindFirstChild("Ingame")
    local InnerMap = Ingame and Ingame:FindFirstChild("Map")
    local GenFolder = InnerMap and InnerMap:FindFirstChild("Generator")

    if GenFolder then
        for _, Obj in pairs(GenFolder:GetChildren()) do
            -- Check for "Remotes" folder and "RF" (RemoteFunction) as seen in video
            if Obj:FindFirstChild("Remotes") then
                local RF = Obj.Remotes:FindFirstChild("RF")
                if RF and RF:IsA("RemoteFunction") then
                    table.insert(Itoshi.Cache.Generators, {Model = Obj, Remote = RF})
                end
            end
        end
    end
end

function GenSys.InstantFix()
    if not Itoshi.Settings.Utility.AutoGenerator.InstantFix then return end
    
    for _, Gen in pairs(Itoshi.Cache.Generators) do
        -- Verify if not already done
        local Prog = Gen.Model:FindFirstChild("Progress") 
        if Prog and (Prog:IsA("NumberValue") and Prog.Value < 100) then
            -- FIRE THE REMOTE DIRECTLY
            -- This bypasses the puzzle entirely by telling the server "I finished"
            task.spawn(function()
                pcall(function()
                    -- Trying common exploit args for this specific structure
                    Gen.Remote:InvokeServer(true)      
                    Gen.Remote:InvokeServer()          
                end)
            end)
        end
    end
end

-- // COMBAT (Standard) //
local Combat = {}
function Combat.Update()
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    
    if Itoshi.Settings.Combat.KillAura.Enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local TRoot = p.Character.HumanoidRootPart
                if (MyRoot.Position - TRoot.Position).Magnitude <= Itoshi.Settings.Combat.KillAura.Range then
                    MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TRoot.Position.X, MyRoot.Position.Y, TRoot.Position.Z))
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                end
            end
        end
    end
    
    if Itoshi.Settings.Combat.Hitbox.Enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size, Itoshi.Settings.Combat.Hitbox.Size)
                p.Character.HumanoidRootPart.Transparency = 0.6
                p.Character.HumanoidRootPart.CanCollide = false
            end
        end
    end
end

-- UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub",
    LoadingTitle = "Bypassing...",
    ConfigurationSaving = {Enabled = true, FolderName = "ItoshiHub", FileName = "RemoteCfg"},
    KeySystem = false, 
})

local TabGen = Window:CreateTab("Utility", 4483362458)
local TabC = Window:CreateTab("Combat", 4483362458)
local TabV = Window:CreateTab("Visuals", 4483362458)

TabGen:CreateToggle({Name = "Auto Generator (Instant Remote)", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Utility.AutoGenerator.InstantFix = v 
end})

TabC:CreateToggle({Name = "Kill Aura", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.KillAura.Enabled = v end})
TabC:CreateToggle({Name = "Hitbox Expander", CurrentValue = true, Callback = function(v) Itoshi.Settings.Combat.Hitbox.Enabled = v end})

TabV:CreateToggle({Name = "Generator ESP", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Visuals.GenESP = v 
    if v then
        for _, G in pairs(Itoshi.Cache.Generators) do
            if G.Model and not G.Model:FindFirstChild("ESP") then
                local b = Instance.new("BillboardGui", G.Model)
                b.Name = "ESP"
                b.Size = UDim2.new(0,100,0,50)
                b.AlwaysOnTop = true
                local t = Instance.new("TextLabel", b)
                t.Size = UDim2.new(1,0,1,0)
                t.BackgroundTransparency = 1
                t.TextColor3 = Color3.new(0,1,0)
                t.Text = "GEN"
            end
        end
    else
        for _, G in pairs(Itoshi.Cache.Generators) do
            if G.Model and G.Model:FindFirstChild("ESP") then G.Model.ESP:Destroy() end
        end
    end
end})

TabV:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) 
    Itoshi.Settings.Visuals.Fullbright = v 
end})


RunService.RenderStepped:Connect(function()
    if Itoshi.Settings.Utility.AutoGenerator.InstantFix then
        SecureCall(GenSys.InstantFix)
    end
    SecureCall(Combat.Update)
    
    if Itoshi.Settings.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        SecureCall(GenSys.Refresh)
    end
end)

Rayfield:LoadConfiguration()
