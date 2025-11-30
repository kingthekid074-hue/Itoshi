local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Itoshi Hub | Ultimate",
    LoadingTitle = "Loading Itoshi Hub...",
    LoadingSubtitle = "Best & Strongest",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ItoshiHub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinv",
        RememberJoins = true
    },
    KeySystem = true,
    KeySettings = {
        Title = "Itoshi Hub | Key System",
        Subtitle = "Enter the key to continue",
        Note = "Key: FFDGDLFYUFOHDWHHFXX",
        FileName = "ItoshiKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"FFDGDLFYUFOHDWHHFXX"} 
    }
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local State = {
    Fly = false,
    FlySpeed = 50,
    Speed = false,
    SpeedVal = 16,
    Jump = false,
    JumpVal = 50,
    Noclip = false,
    ESP = false,
    Fullbright = false
}

local ESP_Storage = {}
local Input = {W = false, A = false, S = false, D = false, Space = false, Ctrl = false}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then Input.W = true end
    if input.KeyCode == Enum.KeyCode.A then Input.A = true end
    if input.KeyCode == Enum.KeyCode.S then Input.S = true end
    if input.KeyCode == Enum.KeyCode.D then Input.D = true end
    if input.KeyCode == Enum.KeyCode.Space then Input.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftControl then Input.Ctrl = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then Input.W = false end
    if input.KeyCode == Enum.KeyCode.A then Input.A = false end
    if input.KeyCode == Enum.KeyCode.S then Input.S = false end
    if input.KeyCode == Enum.KeyCode.D then Input.D = false end
    if input.KeyCode == Enum.KeyCode.Space then Input.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftControl then Input.Ctrl = false end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    if not LocalPlayer.Character then return end
    local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    if State.Fly and Root and Hum then
        Hum.PlatformStand = true
        local speed = State.FlySpeed
        local velocity = Vector3.zero
        local cf = Camera.CFrame

        if Input.W then velocity = velocity + cf.LookVector end
        if Input.S then velocity = velocity - cf.LookVector end
        if Input.A then velocity = velocity - cf.RightVector end
        if Input.D then velocity = velocity + cf.RightVector end
        
        if velocity.Magnitude > 0 then
            velocity = velocity.Unit * speed
        end

        local yVelocity = 0
        if Input.Space then yVelocity = speed end
        if Input.Ctrl then yVelocity = -speed end

        Root.Velocity = Vector3.new(velocity.X, yVelocity, velocity.Z)
        
        Root.CFrame = CFrame.new(Root.Position + (velocity * deltaTime)) * CFrame.new(0, yVelocity * deltaTime, 0)
        Root.Velocity = Vector3.new(0, 0, 0) 
    elseif not State.Fly and Hum and Hum.PlatformStand then
        Hum.PlatformStand = false
    end
end)

RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if Hum then
        if State.Speed then
            Hum.WalkSpeed = State.SpeedVal
        end
        if State.Jump then
            Hum.UseJumpPower = true
            Hum.JumpPower = State.JumpVal
        end
    end

    if State.Noclip then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if State.ESP then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not ESP_Storage[plr] or not ESP_Storage[plr].Parent then
                        local hl = Instance.new("Highlight")
                        hl.Name = "ItoshiESP"
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.Parent = plr.Character
                        ESP_Storage[plr] = hl
                    end
                end
            end
        else
            for i, v in pairs(ESP_Storage) do
                if v then v:Destroy() end
            end
            ESP_Storage = {}
        end

        if State.Fullbright then
            Lighting.ClockTime = 12
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1,1,1)
        end
    end
end)

local MainTab = Window:CreateTab("Main", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

MainTab:CreateSection("Movement")

MainTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(Value)
        State.Fly = Value
    end,
})

MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 1,
    Suffix = " Speed",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        State.FlySpeed = Value
    end,
})

MainTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = false,
    Flag = "WalkSpeed",
    Callback = function(Value)
        State.Speed = Value
    end,
})

MainTab:CreateSlider({
    Name = "WalkSpeed Value",
    Range = {16, 500},
    Increment = 1,
    Suffix = " Speed",
    CurrentValue = 16,
    Flag = "SpeedVal",
    Callback = function(Value)
        State.SpeedVal = Value
    end,
})

MainTab:CreateToggle({
    Name = "Enable JumpPower",
    CurrentValue = false,
    Flag = "JumpPower",
    Callback = function(Value)
        State.Jump = Value
    end,
})

MainTab:CreateSlider({
    Name = "JumpPower Value",
    Range = {50, 500},
    Increment = 1,
    Suffix = " Power",
    CurrentValue = 50,
    Flag = "JumpVal",
    Callback = function(Value)
        State.JumpVal = Value
    end,
})

MainTab:CreateToggle({
    Name = "Noclip (Walk Through Walls)",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        State.Noclip = Value
    end,
})

VisualsTab:CreateSection("ESP & World")

VisualsTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        State.ESP = Value
    end,
})

VisualsTab:CreateToggle({
    Name = "Fullbright (See in Dark)",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(Value)
        State.Fullbright = Value
    end,
})

Rayfield:LoadConfiguration()
