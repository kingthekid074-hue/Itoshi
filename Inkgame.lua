if not getgenv().shared then getgenv().shared = {} end
if getgenv().itoshi_hub_loaded then
    pcall(function() 
        if shared.itoshi_hub_InkGame_Library then
            shared.itoshi_hub_InkGame_Library:Unload()
        end
    end)
    if getgenv().ItoshiMobileGui then getgenv().ItoshiMobileGui:Destroy() end
end
getgenv().itoshi_hub_loaded = true

local Library = {}
Library.Unloaded = false
Library.Options = {}
Library.Toggles = {}
Library._signals = {}

function Library:Notify(text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "itoshi rin",
        Text = text,
        Duration = duration or 3
    })
end

function Library:Unload()
    Library.Unloaded = true
    if self._unloadCallback then
        pcall(self._unloadCallback)
    end
end

function Library:GiveSignal(signal)
    table.insert(self._signals, signal)
    return signal
end

function Library:OnUnload(callback)
    self._unloadCallback = callback
end

-- Create Itoshi Rin interface
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local lplr = Players.LocalPlayer
local localPlayer = lplr
local camera = workspace.CurrentCamera

-- Clear existing GUI
for _, gui in pairs(CoreGui:GetChildren()) do
    if gui.Name == "itoshi hub" then gui:Destroy() end
end
if lplr:WaitForChild("PlayerGui"):FindFirstChild("itoshi rin") then
    lplr.PlayerGui["itoshi rin"]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "itoshi rin"
ScreenGui.ResetOnSpawn = false

if not pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = lplr:WaitForChild("PlayerGui")
end

local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "Toggle"
OpenBtn.Parent = ScreenGui
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
OpenBtn.Position = UDim2.new(0.1, 0, 0.2, 0)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.Text = "RIN"
OpenBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
OpenBtn.TextSize = 18.000
OpenBtn.Draggable = true
OpenBtn.AutoButtonColor = false
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
local openStroke = Instance.new("UIStroke", OpenBtn)
openStroke.Color = Color3.fromRGB(0, 255, 255)
openStroke.Thickness = 2

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -150)
MainFrame.Size = UDim2.new(0, 250, 0, 320)
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Color3.fromRGB(0, 255, 255)
mainStroke.Thickness = 1

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "itoshi rin"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextSize = 20.000

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = MainFrame
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 1.000
CloseBtn.Position = UDim2.new(0.9, -30, 0, 5)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.TextSize = 18.000
CloseBtn.AutoButtonColor = false

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

local Scroller = Instance.new("ScrollingFrame")
Scroller.Parent = MainFrame
Scroller.Active = true
Scroller.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Scroller.BackgroundTransparency = 1.000
Scroller.BorderSizePixel = 0
Scroller.Position = UDim2.new(0, 10, 0, 50)
Scroller.Size = UDim2.new(1, -20, 1, -60)
Scroller.ScrollBarThickness = 4
Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Scroller
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- GUI element creation functions
local function createButton(text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Parent = Scroller
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Btn.Size = UDim2.new(1, 0, 0, 35)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 14.000
    Btn.AutoButtonColor = false
    local btnCorner = Instance.new("UICorner", Btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    local btnStroke = Instance.new("UIStroke", Btn)
    btnStroke.Color = Color3.fromRGB(0, 255, 255)
    btnStroke.Thickness = 1
    
    Btn.MouseButton1Click:Connect(function()
        pcall(callback)
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        task.wait(0.1)
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
    end)
    
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
    end)
    
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
    end)
    
    return Btn
end

local function createToggle(text, default, callback)
    local state = default or false
    local Btn = Instance.new("TextButton")
    Btn.Parent = Scroller
    Btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 150) or Color3.fromRGB(35, 35, 35)
    Btn.Size = UDim2.new(1, 0, 0, 35)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.Text = text .. (state and " [ON]" or " [OFF]")
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 14.000
    Btn.AutoButtonColor = false
    local btnCorner = Instance.new("UICorner", Btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    local btnStroke = Instance.new("UIStroke", Btn)
    btnStroke.Color = Color3.fromRGB(0, 255, 255)
    btnStroke.Thickness = 1
    
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 150) or Color3.fromRGB(35, 35, 35)
        Btn.Text = text .. (state and " [ON]" or " [OFF]")
        pcall(callback, state)
    end)
    
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0, 180, 180) or Color3.fromRGB(45, 45, 45)}):Play()
    end)
    
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0, 150, 150) or Color3.fromRGB(35, 35, 35)}):Play()
    end)
    
    local toggleObj = {
        Value = state,
        SetState = function(newState)
            state = newState
            Btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 150) or Color3.fromRGB(35, 35, 35)
            Btn.Text = text .. (state and " [ON]" or " [OFF]")
            pcall(callback, state)
        end,
        OnChanged = function(newCallback)
            callback = newCallback
        end
    }
    
    return toggleObj
end

local function createLabel(text)
    local Label = Instance.new("TextLabel")
    Label.Parent = Scroller
    Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Label.BackgroundTransparency = 1.000
    Label.Size = UDim2.new(1, 0, 0, 25)
    Label.Font = Enum.Font.GothamSemibold
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(0, 255, 255)
    Label.TextSize = 14.000
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    return Label
end

local function createDivider()
    local Divider = Instance.new("Frame")
    Divider.Parent = Scroller
    Divider.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    Divider.BackgroundTransparency = 0.5
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.BorderSizePixel = 0
    
    return Divider
end

local function createSlider(text, min, max, default, callback)
    local Container = Instance.new("Frame")
    Container.Parent = Scroller
    Container.BackgroundTransparency = 1
    Container.Size = UDim2.new(1, 0, 0, 60)
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Container
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Font = Enum.Font.GothamSemibold
    Label.Text = text .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(0, 255, 255)
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Slider = Instance.new("Frame")
    Slider.Parent = Container
    Slider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Slider.Position = UDim2.new(0, 0, 0, 25)
    Slider.Size = UDim2.new(1, 0, 0, 15)
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 4)
    
    local Fill = Instance.new("Frame")
    Fill.Parent = Slider
    Fill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 4)
    
    local Value = default
    
    Slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = RunService.RenderStepped:Connect(function()
                local mouse = game:GetService("UserInputService"):GetMouseLocation()
                local absolutePosition = Slider.AbsolutePosition
                local absoluteSize = Slider.AbsoluteSize
                
                local relativeX = math.clamp((mouse.X - absolutePosition.X) / absoluteSize.X, 0, 1)
                Value = math.floor(min + (max - min) * relativeX)
                Fill.Size = UDim2.new(relativeX, 0, 1, 0)
                Label.Text = text .. ": " .. Value
                pcall(callback, Value)
            end)
            
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    return {
        Value = Value,
        SetValue = function(newValue)
            Value = math.clamp(newValue, min, max)
            Fill.Size = UDim2.new((Value - min) / (max - min), 0, 1, 0)
            Label.Text = text .. ": " .. Value
            pcall(callback, Value)
        end
    }
end

local function createDropdown(text, values, default, callback)
    local Container = Instance.new("Frame")
    Container.Parent = Scroller
    Container.BackgroundTransparency = 1
    Container.Size = UDim2.new(1, 0, 0, 50)
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Container
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Font = Enum.Font.GothamSemibold
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(0, 255, 255)
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Dropdown = Instance.new("TextButton")
    Dropdown.Parent = Container
    Dropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Dropdown.Position = UDim2.new(0, 0, 0, 25)
    Dropdown.Size = UDim2.new(1, 0, 0, 25)
    Dropdown.Font = Enum.Font.GothamSemibold
    Dropdown.Text = default or "Select"
    Dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    Dropdown.TextSize = 12
    Dropdown.AutoButtonColor = false
    Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 4)
    
    local stroke = Instance.new("UIStroke", Dropdown)
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 1
    
    local Value = default
    local Open = false
    
    local function updateDropdown()
        if Open then
            for _, child in pairs(Container:GetChildren()) do
                if child.Name == "DropdownItem" then
                    child:Destroy()
                end
            end
            
            for i, option in pairs(values) do
                local Item = Instance.new("TextButton")
                Item.Name = "DropdownItem"
                Item.Parent = Container
                Item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                Item.Position = UDim2.new(0, 0, 0, 25 + (i * 25))
                Item.Size = UDim2.new(1, 0, 0, 25)
                Item.Font = Enum.Font.GothamSemibold
                Item.Text = option
                Item.TextColor3 = Color3.fromRGB(255, 255, 255)
                Item.TextSize = 12
                Item.AutoButtonColor = false
                Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 4)
                
                Item.MouseButton1Click:Connect(function()
                    Value = option
                    Dropdown.Text = option
                    pcall(callback, option)
                    Open = false
                    updateDropdown()
                end)
                
                Container.Size = UDim2.new(1, 0, 0, 25 + ((i + 1) * 25))
            end
        else
            for _, child in pairs(Container:GetChildren()) do
                if child.Name == "DropdownItem" then
                    child:Destroy()
                end
            end
            Container.Size = UDim2.new(1, 0, 0, 50)
        end
    end
    
    Dropdown.MouseButton1Click:Connect(function()
        Open = not Open
        updateDropdown()
    end)
    
    return {
        Value = Value,
        SetValue = function(newValue)
            Value = newValue
            Dropdown.Text = newValue
            pcall(callback, newValue)
        end,
        SetValues = function(newValues)
            values = newValues
            updateDropdown()
        end
    }
end

-- Automatically update Scroller size
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroller.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

-- Initialize Script object
local Script = {
    GameStateChanged = Instance.new("BindableEvent"),
    GameState = "unknown",
    Connections = {},
    Functions = {},
    ESPTable = {
        Player = {},
        Seeker = {},
        Hider = {},
        Guard = {},
        Door = {},
        None = {},
        Key = {},
        EscapeDoor = {}
    },
    Temp = {}
}

-- Maid System
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({Tasks = {}}, Maid)
end

function Maid:Add(task)
    if typeof(task) == "RBXScriptConnection" or (typeof(task) == "Instance" and task.Destroy) or typeof(task) == "function" then
        table.insert(self.Tasks, task)
    end
    return task
end

function Maid:Clean()
    for _, task in ipairs(self.Tasks) do
        pcall(function()
            if typeof(task) == "RBXScriptConnection" then
                task:Disconnect()
            elseif typeof(task) == "Instance" then
                task:Destroy()
            elseif typeof(task) == "function" then
                task()
            end
        end)
    end
    table.clear(self.Tasks)
    self.Tasks = {}
end

Script.Maid = Maid.new()

-- Shared Functions
local SharedFunctions = {}

function SharedFunctions.GetBoosts(arg1, arg2, arg3)
    local boosts = arg1 and arg1:FindFirstChild("Boosts")
    if boosts then
        local boostVal = boosts:FindFirstChild(arg2)
        if boostVal then
            if arg2 == "Faster Sprint" then
                return 3.5 * boostVal.Value
            elseif arg2 == "Damage Boost" then
                return 30 * boostVal.Value
            else
                return 20 * boostVal.Value
            end
        end
    end
    return 5
end

function SharedFunctions.Invisible(arg1, arg2, arg3)
    for _, part in ipairs(arg1:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
            part.CanCollide = false
            part.CastShadow = false
            part.CanQuery = false
            part.CanTouch = false
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
        end
    end
end

function SharedFunctions.CreateFolder(parent, name, lifetime, opts)
    local Folder = Instance.new("Folder")
    Folder.Name = name
    if opts then
        if opts.ObjectValue then
            Folder.Value = opts.ObjectValue
        end
        if opts.Attributes then
            for k, v in pairs(opts.Attributes) do
                Folder:SetAttribute(k, v)
            end
        end
    end
    Folder.Parent = parent
    if lifetime then
        task.delay(lifetime, function()
            if Folder and Folder.Parent then
                Folder:Destroy()
            end
        end)
    end
    return Folder
end

Script.Functions = {}

function Script.Functions.Alert(message, time_obj)
    Library:Notify(message, time_obj or 5)

    local sound = Instance.new("Sound", workspace) 
    sound.SoundId = "rbxassetid://4590662766"
    sound.Volume = 2
    sound.PlayOnRemove = true
    sound:Destroy()
end

function Script.Functions.Warn(message)
    warn("itoshi rin WARN", message)
end

-- ESP System
function Script.Functions.ESP(args)
    if not args.Object then return Script.Functions.Warn("ESP Object is nil") end

    local ESPManager = {
        Object = args.Object,
        Text = args.Text or "No Text",
        TextParent = args.TextParent,
        Color = args.Color or Color3.new(),
        Offset = args.Offset or Vector3.zero,
        IsEntity = args.IsEntity or false,
        Type = args.Type or "None",

        Highlights = {},
        Humanoid = nil,
        RSConnection = nil,

        Connections = {}
    }

    local tableIndex = #Script.ESPTable[ESPManager.Type] + 1

    if ESPManager.IsEntity and ESPManager.Object.PrimaryPart and ESPManager.Object.PrimaryPart.Transparency == 1 then
        ESPManager.Object:SetAttribute("Transparency", ESPManager.Object.PrimaryPart.Transparency)
        if not ESPManager.Object:FindFirstChildOfClass("Humanoid") then
            ESPManager.Humanoid = Instance.new("Humanoid", ESPManager.Object)
        end
        ESPManager.Object.PrimaryPart.Transparency = 0.99
    end

    local highlight = Instance.new("Highlight") 
    highlight.Adornee = ESPManager.Object
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = ESPManager.Color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = ESPManager.Color
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.Parent = ESPManager.Object

    table.insert(ESPManager.Highlights, highlight)
    
    local billboardGui = Instance.new("BillboardGui") 
    billboardGui.Adornee = ESPManager.TextParent or ESPManager.Object
    billboardGui.AlwaysOnTop = true
    billboardGui.ClipsDescendants = false
    billboardGui.Size = UDim2.new(0, 1, 0, 1)
    billboardGui.StudsOffset = ESPManager.Offset
    billboardGui.Parent = ESPManager.TextParent or ESPManager.Object

    local textLabel = Instance.new("TextLabel") 
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Oswald
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = ESPManager.Text
    textLabel.TextColor3 = ESPManager.Color
    textLabel.TextSize = 14
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextStrokeTransparency = 0.75
    textLabel.Parent = billboardGui

    function ESPManager.SetColor(newColor)
        ESPManager.Color = newColor

        for _, highlight in pairs(ESPManager.Highlights) do
            highlight.FillColor = newColor
            highlight.OutlineColor = newColor
        end

        textLabel.TextColor3 = newColor
    end

    function ESPManager.Destroy()
        if ESPManager.RSConnection then
            ESPManager.RSConnection:Disconnect()
        end

        if ESPManager.IsEntity and ESPManager.Object then
            if ESPManager.Object.PrimaryPart then
                ESPManager.Object.PrimaryPart.Transparency = ESPManager.Object.PrimaryPart:GetAttribute("Transparency") or 0
            end
            if ESPManager.Humanoid then
                ESPManager.Humanoid:Destroy()
            end
        end

        for _, highlight in pairs(ESPManager.Highlights) do
            highlight:Destroy()
        end
        if billboardGui then billboardGui:Destroy() end

        if Script.ESPTable[ESPManager.Type][tableIndex] then
            Script.ESPTable[ESPManager.Type][tableIndex] = nil
        end

        for _, conn in pairs(ESPManager.Connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        ESPManager.Connections = {}
    end

    ESPManager.RSConnection = RunService.RenderStepped:Connect(function()
        if not ESPManager.Object or not ESPManager.Object:IsDescendantOf(workspace) then
            ESPManager.Destroy()
            return
        end
    end)

    function ESPManager.GiveSignal(signal)
        table.insert(ESPManager.Connections, signal)
    end

    Script.ESPTable[ESPManager.Type][tableIndex] = ESPManager
    return ESPManager
end

function Script.Functions.SeekerESP(player)
    if player:GetAttribute("IsHunter") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        if not player.Character:FindFirstChild("HunterGlow") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "HunterGlow"
            highlight.Adornee = player.Character
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.2
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = player.Character
        end

        local esp = Script.Functions.ESP({
            Object = player.Character,
            Text = "HUNTER " .. player.Name .. "",
            Color = Color3.fromRGB(255, 0, 0),
            Offset = Vector3.new(0, 5, 0),
            Type = "Seeker"
        })
        
        player:GetAttributeChangedSignal("IsHunter"):Once(function()
            if not player:GetAttribute("IsHunter") then
                esp.Destroy()
                local hl = player.Character:FindFirstChild("HunterGlow")
                if hl then hl:Destroy() end
            end
        end)
    end
end

function Script.Functions.HiderESP(player)
    if player:GetAttribute("IsHider") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        if not player.Character:FindFirstChild("HiderGlow") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "HiderGlow"
            highlight.Adornee = player.Character
            highlight.FillColor = Color3.fromRGB(0, 255, 100)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = player.Character
        end

        local dist = math.floor((player.Character.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)
        
        local esp = Script.Functions.ESP({
            Object = player.Character,
            Text = string.format("TARGET: %s [%d m]", player.Name, dist),
            Color = Color3.fromRGB(0, 255, 100),
            Offset = Vector3.new(0, 4, 0),
            Type = "Hider"
        })

        player:GetAttributeChangedSignal("IsHider"):Once(function()
            if not player:GetAttribute("IsHider") then
                esp.Destroy()
                local hl = player.Character:FindFirstChild("HiderGlow")
                if hl then hl:Destroy() end
            end
        end)
    end
end

function Script.Functions.KeyESP(key)
    if key:IsA("Model") and key.PrimaryPart then
        if not key:FindFirstChild("KeyGlow") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "KeyGlow"
            highlight.Adornee = key
            highlight.FillColor = Color3.fromRGB(255, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.2
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = key
        end

        local dist = math.floor((key.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)

        local esp = Script.Functions.ESP({
            Object = key,
            Text = string.format(" KEY: %s [%d m]", key.Name, dist),
            Color = Color3.fromRGB(255, 255, 0),
            Offset = Vector3.new(0, 2, 0),
            Type = "Key",
            IsEntity = true
        })
    end
end

function Script.Functions.DoorESP(door)
    if door:IsA("Model") and door.Name == "FullDoorAnimated" and door.PrimaryPart then
        if not door:FindFirstChild("DoorGlow") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "DoorGlow"
            highlight.Adornee = door
            highlight.FillColor = Color3.fromRGB(0, 150, 255)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.4
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = door
        end

        local keyNeeded = door:GetAttribute("KeyNeeded") or "None"
        local dist = math.floor((door.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)

        local esp = Script.Functions.ESP({
            Object = door,
            Text = string.format(" DOOR [Key: %s] [%d m]", keyNeeded, dist),
            Color = Color3.fromRGB(0, 150, 255),
            Offset = Vector3.new(0, 3, 0),
            Type = "Door",
            IsEntity = true
        })
    end
end

function Script.Functions.EscapeDoorESP(door)
    if door:IsA("Model") and door.Name == "EXITDOOR" and door.PrimaryPart and door:GetAttribute("CANESCAPE") then
        if not door:FindFirstChild("WinGlow") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "WinGlow"
            highlight.Adornee = door
            highlight.FillColor = Color3.fromRGB(50, 255, 50)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.1
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = door
        end

        local dist = math.floor((door.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)

        local esp = Script.Functions.ESP({
            Object = door,
            Text = string.format("ESCAPE OPEN [%d m] ✅", dist),
            Color = Color3.fromRGB(50, 255, 50),
            Offset = Vector3.new(0, 5, 0),
            Type = "EscapeDoor",
            IsEntity = true
        })
    end
end

function Script.Functions.GuardESP(character)
    if character and character:FindFirstChild("HumanoidRootPart") then
        if not character:FindFirstChild("GuardGlow") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "GuardGlow"
            highlight.Adornee = character
            highlight.FillColor = Color3.fromRGB(255, 140, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.2
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = character
        end

        local dist = math.floor((character.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)

        local esp = Script.Functions.ESP({
            Object = character,
            Text = string.format(" GUARD [%d m]", dist),
            Color = Color3.fromRGB(255, 140, 0),
            Offset = Vector3.new(0, 4, 0),
            Type = "Guard"
        })

        table.insert(esp.Connections, character.ChildAdded:Connect(function(v)
            if v.Name == "Dead" and v.ClassName == "Folder" then
                esp.Destroy()
                local hl = character:FindFirstChild("GuardGlow")
                if hl then hl:Destroy() end
            end
        end))
    end
end

function Script.Functions.PlayerESP(player)
    if not (player.Character and player.Character.PrimaryPart and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0) then return end

    if not player.Character:FindFirstChild("PlayerChams") then
        local hl = Instance.new("Highlight")
        hl.Name = "PlayerChams"
        hl.Adornee = player.Character
        hl.FillColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineColor = Color3.fromRGB(0, 0, 0)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
        hl.Parent = player.Character
    end

    local function getInfoText()
        local health = math.floor(player.Character.Humanoid.Health)
        local maxHealth = math.floor(player.Character.Humanoid.MaxHealth)
        local dist = math.floor((player.Character.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude)
        local tool = player.Character:FindFirstChildOfClass("Tool")
        local toolName = tool and tool.Name or "[None]"
        
        return string.format("%s\nHP: %d/%d\nDist: %dm\nItem: %s", player.DisplayName, health, maxHealth, dist, toolName)
    end

    local playerEsp = Script.Functions.ESP({
        Type = "Player",
        Object = player.Character,
        Text = getInfoText(),
        TextParent = player.Character.PrimaryPart,
        Color = Color3.fromRGB(255, 255, 255)
    })

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            playerEsp.Text = getInfoText()
        else
            if connection then connection:Disconnect() end
            playerEsp.Destroy()
            local hl = player.Character and player.Character:FindFirstChild("PlayerChams")
            if hl then hl:Destroy() end
        end
    end)

    playerEsp.GiveSignal(connection)
end

Script.Functions.SafeRequire = function(module)
    if Script.Temp[tostring(module)] then return Script.Temp[tostring(module)] end
    local suc, err = pcall(function()
        return require(module)
    end)
    if not suc then
        warn("[itoshi rin SafeRequire]: Failure loading "..tostring(module).." ("..tostring(err)..")")
    else
        Script.Temp[tostring(module)] = err
    end
    return suc and err
end

Script.Functions.ExecuteClick = function()
    local args = {
        "Clicked"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Replication"):WaitForChild("Event"):FireServer(unpack(args))    
end

Script.Functions.CompleteDalgonaGame = function()
    Script.Functions.ExecuteClick()
    local args = {
        {
            Completed = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DALGONATEMPREMPTE"):FireServer(unpack(args))

    local args = {
        {
            Success = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DALGONATEMPREMPTE"):FireServer(unpack(args))
end

Script.Functions.PullRope = function(perfect)
    local args = {}
    if perfect then
        args = {
            {
                GameQTE = true
            }
        }
    else
        args = {
            {
                Failed = true
            }
        }
    end
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TemporaryReachedBindable"):FireServer(unpack(args))
end

function Script.Functions.RevealGlassBridge()
    local function SafeRevealGlass()
        local glassHolder = workspace:FindFirstChild("GlassBridge") and workspace.GlassBridge:FindFirstChild("GlassHolder")
        if not glassHolder then return end

        for _, tilePair in pairs(glassHolder:GetChildren()) do
            for _, tileModel in pairs(tilePair:GetChildren()) do
                if tileModel:IsA("Model") and tileModel.PrimaryPart then
                    local primaryPart = tileModel.PrimaryPart
                    if tileModel:FindFirstChild("Itoshi_ESP") then
                        tileModel.Itoshi_ESP:Destroy()
                    end
                    
                    local isBreakable = false
                    if primaryPart:FindFirstChild("TouchInterest") then 
                        isBreakable = true 
                    elseif primaryPart.CanCollide == false then
                        isBreakable = true
                    end
                    
                    local targetColor = isBreakable and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "Itoshi_ESP"
                    highlight.Adornee = tileModel
                    highlight.FillColor = targetColor
                    highlight.FillTransparency = 0.6
                    highlight.OutlineColor = targetColor
                    highlight.OutlineTransparency = 0.2
                    highlight.Parent = tileModel
                end
            end
        end
    end
    
    SafeRevealGlass()
    Library:Notify("Glass Bridge revealed", 5)
end

Script.Functions.BypassRagdoll = function()
    local Character = lplr.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local Torso = Character:FindFirstChild("Torso")
    if not (Humanoid and HumanoidRootPart and Torso) then return end

    if Script.Temp.RagdollBlockConn then
        Script.Temp.RagdollBlockConn:Disconnect()
    end
    Script.Temp.RagdollBlockConn = Character.ChildAdded:Connect(function(child)
        if child.Name == "Ragdoll" then
            pcall(function() child:Destroy() end)
            pcall(function()
                Humanoid.PlatformStand = false
                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            end)
        end
    end)

    for _, child in ipairs(Character:GetChildren()) do
        if child.Name == "Ragdoll" then
            pcall(function() child:Destroy() end)
        end
    end

    for _, folderName in pairs({"Stun", "RotateDisabled", "RagdollWakeupImmunity", "InjuredWalking"}) do
        local folder = Character:FindFirstChild(folderName)
        if folder then
            folder:Destroy()
        end
    end

    for _, obj in pairs(HumanoidRootPart:GetChildren()) do
        if obj:IsA("BallSocketConstraint") or obj.Name:match("^CacheAttachment") then
            obj:Destroy()
        end
    end
    local joints = {"Left Hip", "Left Shoulder", "Neck", "Right Hip", "Right Shoulder"}
    for _, jointName in pairs(joints) do
        local motor = Torso:FindFirstChild(jointName)
        if motor and motor:IsA("Motor6D") and not motor.Part0 then
            motor.Part0 = Torso
        end
    end
    for _, part in pairs(Character:GetChildren()) do
        if part:IsA("BasePart") and part:FindFirstChild("BoneCustom") then
            part.BoneCustom:Destroy()
        end
    end
end

function Script.Functions.GetRootPart()
    if not lplr.Character then return nil end
    local rp = lplr.Character:FindFirstChild("HumanoidRootPart")
    return rp
end

local tools = {"Fork", "Bottle", "Knife", "Power Hold", "Push"}

Script.Functions.GetFork = function()
    local res
    for _, index in pairs(tools) do
        local tool = lplr.Character:FindFirstChild(index) or lplr:FindFirstChild("Backpack") and lplr.Backpack:FindFirstChild(index)
        if tool then
            res = tool
            break
        end
    end
    return res
end

function Script.Functions.GetDalgonaRemote()
    return game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):FindFirstChild("DALGONATEMPREMPTE")
end

function Script.Functions.DistanceFromCharacter(position)
    if typeof(position) == "Instance" then
        position = position:GetPivot().Position
    end

    local alive = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    local rootPart = alive and lplr.Character.HumanoidRootPart
    
    if not alive then
        return (camera.CFrame.Position - position).Magnitude
    end

    return (rootPart.Position - position).Magnitude
end

Script.Functions.FixCamera = function()
    if workspace.CurrentCamera then
        pcall(function()
            workspace.CurrentCamera:Destroy()
        end)
    end
    local new = Instance.new("Camera")
    new.Parent = workspace
    workspace.CurrentCamera = new
    new.CameraType = Enum.CameraType.Custom
    new.CameraSubject = lplr.Character.Humanoid
end

Script.Functions.RestoreVisibility = function(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "BoneCustom" then
            if part.Transparency >= 0.99 or part.LocalTransparencyModifier >= 0.99 then
                part.Transparency = 0
                part.LocalTransparencyModifier = 0
            end
        end
    end

    pcall(function()
        character.HumanoidRootPart.Transparency = 1
    end)
    pcall(function()
        if character:FindFirstChild("Head") and character.Head:FindFirstChild("BoneCustom") then
            character.Head.BoneCustom.Transparency = 1
        end
    end)

    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Clothing") then
            if item:IsA("Accessory") then
                local handle = item:FindFirstChild("Handle")
                if handle and handle.Transparency >= 0.99 then
                    handle.Transparency = 0
                end
            end
        end
    end
end

Script.Functions.CheckPlayersVisibility = function()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            Script.Functions.RestoreVisibility(player.Character)
        end
    end
end

function Script.Functions.SetupOtherPlayerConnection(player)
    if player.Character then
        if playerEspToggle and playerEspToggle.Value then
            Script.Functions.PlayerESP(player)
        end
    end
end

function Script.Functions.WinRLGL()
    if not lplr.Character then return end
    lplr.Character:PivotTo(CFrame.new(Vector3.new(-100.8, 1030, 115)))
end

function Script.Functions.WinJumpRope()
    if not lplr.Character then return end
    lplr.Character:PivotTo(CFrame.new(Vector3.new(732.4, 197.14, 931.1644)))
end

function Script.Functions.TeleportSafe()
    if not lplr.Character then return end
    pcall(function()
        Script.Temp.OldLocation = CFrame.new(lplr.Character.HumanoidRootPart.Position)
    end)
    lplr.Character:PivotTo(CFrame.new(Vector3.new(-108, 329.1, 462.1)))
end

function Script.Functions.TeleportBackFromSafe()
    local OldLocation = Script.Temp.OldLocation
    if not OldLocation then
        warn("[itoshi rin Invalid location]")
        return
    end
    if not lplr.Character then return end
    lplr.Character:PivotTo(OldLocation)
end

function Script.Functions.TeleportSafeHidingSpot()
    if not lplr.Character then return end
    lplr.Character:PivotTo(CFrame.new(Vector3.new(229.9, 1005.3, 169.4)))
end

function Script.Functions.WinGlassBridge()
    if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = lplr.Character.HumanoidRootPart
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    lplr.Character:PivotTo(CFrame.new(-203.9, 525.7, -1534.3485))
end

function Script.Functions.GetHider()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == lplr then continue end
        if not plr.Character then continue end
        if not plr:GetAttribute("IsHider") then continue end
        if plr.Character ~= nil and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            return plr.Character
        else
            continue
        end
    end
end

function Script.Functions.FindCarryPrompt(plr)
    if not plr.Character then return false end
    if not plr.Character:FindFirstChild("HumanoidRootPart") then return false end
    if not (plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0) then return false end

    local CarryPrompt = plr.Character.HumanoidRootPart:FindFirstChild("CarryPrompt")
    return CarryPrompt
end

function Script.Functions.FireCarryPrompt(plr)
    local CarryPrompt = Script.Functions.FindCarryPrompt(plr)
    if not CarryPrompt then return false end

    local suc = pcall(function() fireproximityprompt(CarryPrompt) end)
    return suc
end

function Script.Functions.FindInjuredPlayer()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == lplr then continue end
        if plr:GetAttribute("IsDead") then continue end
        local CarryPrompt = Script.Functions.FindCarryPrompt(plr)
        if not CarryPrompt then continue end
        if plr.Character and plr.Character:FindFirstChild("SafeRedLightGreenLight") then continue end
        if plr.Character and plr.Character:FindFirstChild("IsBeingHeld") then continue end
        return plr, CarryPrompt
    end
end

function Script.Functions.UnCarryPerson()
    local args = {
        {
            tryingtoleave = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ClickedButton"):FireServer(unpack(args))    
end

function Script.Functions.RestartRemotesScript()
    if lplr.Character and lplr.Character:FindFirstChild("Remotes") then
        local Remotes = lplr.Character:FindFirstChild("Remotes")
        pcall(function()
            Remotes.Disabled = true
            Remotes.Enabled = false
        end)
        task.wait(0.5)
        pcall(function()
            Remotes.Disabled = false
            Remotes.Enabled = true
        end)
    end
end

function Script.Functions.GetAllInjuredPlayers()
    local injured = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == lplr then continue end
        if plr:GetAttribute("IsDead") then continue end
        local CarryPrompt = Script.Functions.FindCarryPrompt(plr)
        if not CarryPrompt then continue end
        if plr.Character and plr.Character:FindFirstChild("SafeRedLightGreenLight") then continue end
        if plr.Character and plr.Character:FindFirstChild("IsBeingHeld") then continue end
        table.insert(injured, {player = plr, carryPrompt = CarryPrompt})
    end
    return injured
end

function Script.Functions.Wallcheck(attackerCharacter, targetCharacter, additionalIgnore)
    if not (attackerCharacter and targetCharacter) then
        return false
    end
    local humanoidRootPart = attackerCharacter.PrimaryPart
    local targetRootPart = targetCharacter.PrimaryPart
    if not (humanoidRootPart and targetRootPart) then
        return false
    end
    local origin = humanoidRootPart.Position
    local targetPosition = targetRootPart.Position
    local direction = targetPosition - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.RespectCanCollide = true
    local ignoreList = {attackerCharacter}
    if additionalIgnore and typeof(additionalIgnore) == "table" then
        for _, item in pairs(additionalIgnore) do
            table.insert(ignoreList, item)
        end
    end
    raycastParams.FilterDescendantsInstances = ignoreList

    local maxAttempts = 5
    local currentOrigin = origin
    for i = 1, maxAttempts do
        local raycastResult = workspace:Raycast(currentOrigin, targetPosition - currentOrigin, raycastParams)
        if not raycastResult then
            return true 
        end
        if raycastResult.Instance:IsDescendantOf(targetCharacter) then
            return true
        end
        if (not raycastResult.Instance.CanCollide) or (raycastResult.Instance.Transparency > 0.8) then
            table.insert(ignoreList, raycastResult.Instance)
            raycastParams.FilterDescendantsInstances = ignoreList
            currentOrigin = raycastResult.Position + (direction.Unit * 0.1)
        else
            return false
        end
    end
    return false
end

local function isGuard(model)
    if not model:IsA("Model") or model == lplr.Character then return false end
    if not model:FindFirstChild("TypeOfGuard") then return end
    local lower = model.Name:lower()
    local descendant = model
    if string.find(descendant.Name, "Rebel") or string.find(descendant.Name, "FinalRebel") or string.find(descendant.Name, "HallwayGuard") or string.find(string.lower(descendant.Name), "aggro") then
        local hum = model:FindFirstChild("Humanoid")
        if not hum then return false end
        return not model:FindFirstChild("Dead") and hum.Health > 0
    end
    return false
end

function Script.Functions.PivotRebelGuardsToPlayer()
    local myChar = lplr.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = myChar.HumanoidRootPart
    local myPos = myRoot.Position
    local forward = myRoot.CFrame.LookVector
    local offsetDist = 4
    local sideOffset = 2
    local guardCount = 0
    for _, guard in ipairs(Script.Temp.ValidGuards or {}) do
        if isGuard(guard) and guard:FindFirstChild("HumanoidRootPart") then
            guardCount = guardCount + 1
            local angle = (guardCount - 1) * math.rad(30) - math.rad(15 * ((#Script.Temp.ValidGuards or 1) - 1))
            local offset = CFrame.fromAxisAngle(Vector3.new(0,1,0), angle) * Vector3.new(0, 0, -offsetDist)
            local targetPos = myRoot.Position + myRoot.CFrame:VectorToWorldSpace(offset)
            local targetCFrame = CFrame.new(targetPos, myRoot.Position)
            guard:PivotTo(targetCFrame)
        end
    end
end

function Script.Functions.SkipDialogue()
    local args = {
        "Skipped"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DialogueRemote"):FireServer(unpack(args))    
end

function Script.Functions.CastVote(vote)
    local args = {
        {
            Voting = vote
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ExtraTemporaryRemote"):FireServer(unpack(args))
end

-- Mobile GUI (تضمين واجهة الموبايل)
do
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    local MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "ItoshiHubMobileToggle"
    MobileGui.ResetOnSpawn = false
    MobileGui.IgnoreGuiInset = true
    
    pcall(function() MobileGui.Parent = CoreGui end)
    if not MobileGui.Parent then MobileGui.Parent = PlayerGui end
    
    getgenv().ItoshiMobileGui = MobileGui

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Parent = MobileGui
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ToggleBtn.BackgroundTransparency = 0.3
    ToggleBtn.Position = UDim2.new(0, 20, 0.5, 0)
    ToggleBtn.Size = UDim2.new(0, 60, 0, 60)
    ToggleBtn.Font = Enum.Font.SourceSansBold
    ToggleBtn.Text = "☰"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 24.000
    ToggleBtn.AutoButtonColor = true
    ToggleBtn.Draggable = true
    ToggleBtn.Active = true

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = ToggleBtn
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 50, 50)
    UIStroke.Thickness = 2
    UIStroke.Parent = ToggleBtn
    
    local function safeToggle()
        pcall(function()
            MainFrame.Visible = not MainFrame.Visible
        end)
    end
    
    ToggleBtn.MouseButton1Click:Connect(safeToggle)
    
    local UIS = game:GetService("UserInputService")
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightShift and not gameProcessed then
            safeToggle()
        end
    end)
end

-- Auto Farm System
local autoFarmActive = false
local savedPositions = {
    rlglPos = Vector3.new(-45.0, 1023.3, 95.1),
    lightsOutPos = Vector3.new(195.6, 122.7, -93.1),
    glassBridgePos = Vector3.new(-206.4, 520.7, -1534.0)
}

local lightsOutItems = {
    ["Fork"] = true,
    ["Soda"] = true,
    ["Bottle"] = true,
    ["Kimbap"] = true
}

-- Auto Farm GUI
local function createAutoFarmGUI()
    local playerGui = lplr:WaitForChild("PlayerGui")
    
    local oldGui = playerGui:FindFirstChild("AutoFarmGUI")
    if oldGui then
        oldGui:Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoFarmGUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 160, 0, 60)
    frame.Position = UDim2.new(0.05, 0, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 140, 0, 40)
    toggleBtn.Position = UDim2.new(0, 10, 0, 10)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.Gotham
    toggleBtn.TextSize = 16
    toggleBtn.Text = "Auto Farm: OFF"
    toggleBtn.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.Parent = toggleBtn

    local function checkTool(toolName)
        if not autoFarmActive then return end

        local char = lplr.Character
        if not char then return end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if toolName == "Pocket Sand" then
            root.CFrame = CFrame.new(savedPositions.rlglPos)
            Library:Notify("Teleported to RLGL!", 3)
        elseif lightsOutItems[toolName] then
            root.CFrame = CFrame.new(savedPositions.lightsOutPos)
            Library:Notify("Teleported to Lights Out!", 3)
        end
    end

    if lplr:FindFirstChild("Backpack") then
        lplr.Backpack.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") then
                checkTool(tool.Name)
            end
        end)
    end

    lplr.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") then
                checkTool(tool.Name)
            end
        end)

        task.wait(0.5)

        if autoFarmActive then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root.Position.Y > 500 then
                root.CFrame = CFrame.new(savedPositions.glassBridgePos)
                Library:Notify("Teleported to Glass Bridge!", 3)
            end
        end
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        autoFarmActive = not autoFarmActive
        toggleBtn.Text = "Auto Farm: " .. (autoFarmActive and "ON" or "OFF")
        toggleBtn.BackgroundColor3 = autoFarmActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
        
        if autoFarmActive then
            Library:Notify("Auto Farm enabled!", 3)
        else
            Library:Notify("Auto Farm disabled!", 3)
        end
    end)

    return gui
end

-- إنشاء واجهة GUI الرئيسية مع جميع الميزات
createLabel("=== Main Features ===")

local killauraToggle = createToggle("Killaura", false, function(state)
    if state then
        Library:Notify("Killaura enabled!", 3)
        task.spawn(function()
            while killauraToggle.Value and not Library.Unloaded do
                local target = nil
                local closestDist = math.huge
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (lplr.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                        if dist < closestDist then
                            target = player.Character.HumanoidRootPart
                            closestDist = dist
                        end
                    end
                end
                
                if target and lplr.Character and closestDist < 15 then
                    local fork = Script.Functions.GetFork()
                    if fork then
                        if fork.Parent.Name == "Backpack" then
                            lplr.Character.Humanoid:EquipTool(fork)
                        end
                        
                        local args = {
                            "UsingMoveCustom",
                            fork,
                            nil,
                            {
                                Clicked = true
                            }
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UsedTool"):FireServer(unpack(args))
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        Library:Notify("Killaura disabled!", 3)
    end
end)

local speedToggle = createToggle("Speed", false, function(state)
    if state and lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
        lplr.Character.Humanoid.WalkSpeed = 50
        Library:Notify("Speed enabled!", 3)
    elseif lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
        lplr.Character.Humanoid.WalkSpeed = 16
        Library:Notify("Speed disabled!", 3)
    end
end)

local noclipToggle = createToggle("Noclip", false, function(state)
    Script.Temp.NoclipParts = Script.Temp.NoclipParts or {}
    if state then
        Library:Notify("Noclip enabled!", 3)
        task.spawn(function()
            repeat 
                if lplr.Character ~= nil then
                    for _, child in pairs(lplr.Character:GetDescendants()) do
                        if child:IsA("BasePart") and child.CanCollide == true then
                            child.CanCollide = false
                            Script.Temp.NoclipParts[child] = true
                        end
                    end
                end
                task.wait(0.1)
            until not noclipToggle.Value or Library.Unloaded
        end)
    else
        Library:Notify("Noclip disabled!", 3)
        if lplr.Character ~= nil and Script.Temp.NoclipParts then
            for part, _ in pairs(Script.Temp.NoclipParts) do
                if part and part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            Script.Temp.NoclipParts = {}
        end
    end
end)

local infiniteJumpToggle = createToggle("Infinite Jump", false, function(state)
    if state then
        Library:Notify("Infinite Jump enabled!", 3)
        Script.Temp.InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
                lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        Library:Notify("Infinite Jump disabled!", 3)
        if Script.Temp.InfiniteJumpConnection then
            Script.Temp.InfiniteJumpConnection:Disconnect()
        end
    end
end)

local flyToggle = createToggle("Fly", false, function(state)
    if state then
        Library:Notify("Fly enabled! Use WASD to fly", 3)
        local rootPart = Script.Functions.GetRootPart()
        if not rootPart then return end

        local humanoid = lplr.Character and lplr.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end

        local flyBody = Instance.new("BodyVelocity")
        flyBody.Velocity = Vector3.zero
        flyBody.MaxForce = Vector3.one * 9e9
        Script.Temp.FlyBody = flyBody
        flyBody.Parent = rootPart

        local controlModule = require(lplr:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        Script.Temp.FlyConnection = RunService.RenderStepped:Connect(function()
            local moveVector = controlModule:GetMoveVector()
            local velocity = -((camera.CFrame.LookVector * moveVector.Z) - (camera.CFrame.RightVector * moveVector.X)) * 40
            Script.Temp.FlyBody.Velocity = velocity
        end)
    else
        Library:Notify("Fly disabled!", 3)
        if Script.Temp.FlyBody then
            Script.Temp.FlyBody:Destroy()
        end
        if Script.Temp.FlyConnection then
            Script.Temp.FlyConnection:Disconnect()
        end
        local humanoid = lplr.Character and lplr.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end)

createDivider()
createLabel("=== Auto Farm ===")

local autoFarmToggle = createToggle("Auto Farm", false, function(state)
    autoFarmActive = state
    if state then
        Library:Notify("Auto Farm enabled!", 3)
        createAutoFarmGUI()
    else
        Library:Notify("Auto Farm disabled!", 3)
    end
end)

createButton("Create Auto Farm GUI", createAutoFarmGUI)

createDivider()
createLabel("=== Dalgona ===")

local unbreakableCookieToggle = createToggle("Unbreakable Cookie", false, function(state)
    if state then
        Library:Notify("Unbreakable Cookie enabled!", 3)
    else
        Library:Notify("Unbreakable Cookie disabled!", 3)
    end
end)

createButton("Complete Dalgona Game", function()
    Library:Notify("Completing Dalgona Game...", 3)
    task.spawn(function()
        Script.Functions.CompleteDalgonaGame()
        Library:Notify("Dalgona completed successfully!", 5)
    end)
end)

createDivider()
createLabel("=== Visuals (ESP) ===")

local playerEspToggle = createToggle("Player ESP", false, function(state)
    if state then
        Library:Notify("Player ESP enabled!", 3)
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                Script.Functions.PlayerESP(player)
            end
        end
    else
        Library:Notify("Player ESP disabled!", 3)
        for _, esp in pairs(Script.ESPTable.Player) do
            esp.Destroy()
        end
    end
end)

local guardEspToggle = createToggle("Guard ESP", false, function(state)
    if state then
        Library:Notify("Guard ESP enabled!", 3)
        local live = workspace:FindFirstChild("Live")
        if live then
            for _, descendant in pairs(live:GetChildren()) do
                if descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == "Live" and descendant:FindFirstChild("TypeOfGuard") then
                    if string.find(descendant.Name, "RebelGuard") or string.find(descendant.Name, "FinalRebel") or string.find(descendant.Name, "HallwayGuard") or string.find(string.lower(descendant.Name), "aggro") then
                        Script.Functions.GuardESP(descendant)
                    end
                end
            end
        end
    else
        Library:Notify("Guard ESP disabled!", 3)
        for _, esp in pairs(Script.ESPTable.Guard) do
            esp.Destroy()
        end
    end
end)

local hiderEspToggle = createToggle("Hider ESP", false, function(state)
    if state then
        Library:Notify("Hider ESP enabled!", 3)
        for _, player in pairs(Players:GetPlayers()) do
            if player:GetAttribute("IsHider") then
                Script.Functions.HiderESP(player)
            end
        end
    else
        Library:Notify("Hider ESP disabled!", 3)
        for _, esp in pairs(Script.ESPTable.Hider) do
            esp.Destroy()
        end
    end
end)

local seekerEspToggle = createToggle("Seeker ESP", false, function(state)
    if state then
        Library:Notify("Seeker ESP enabled!", 3)
        for _, player in pairs(Players:GetPlayers()) do
            if player:GetAttribute("IsHunter") then
                Script.Functions.SeekerESP(player)
            end
        end
    else
        Library:Notify("Seeker ESP disabled!", 3)
        for _, esp in pairs(Script.ESPTable.Seeker) do
            esp.Destroy()
        end
    end
end)

createDivider()
createLabel("=== Other ===")

local fullbrightToggle = createToggle("Fullbright", false, function(state)
    if state then
        Script.Temp.FullbrightSettings = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Ambient = Lighting.Ambient
        }
        
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        
        Script.Temp.FullbrightConn = Lighting.Changed:Connect(function()
            if not fullbrightToggle.Value then return end
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        end)
        Library:Notify("Fullbright enabled!", 3)
    else
        local settings = Script.Temp.FullbrightSettings or {}
        for k, v in pairs(settings) do
            Lighting[k] = v
        end
        
        if Script.Temp.FullbrightConn then
            Script.Temp.FullbrightConn:Disconnect()
            Script.Temp.FullbrightConn = nil
        end
        Library:Notify("Fullbright disabled!", 3)
    end
end)

local antiAfkToggle = createToggle("Anti AFK", true, function(state)
    local VirtualUser = game:GetService("VirtualUser")
    if state then
        Script.Temp.AntiAfkConnection = lplr.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
        end)
        Library:Notify("Anti AFK enabled!", 3)
    else
        if Script.Temp.AntiAfkConnection then
            Script.Temp.AntiAfkConnection:Disconnect()
        end
        Library:Notify("Anti AFK disabled!", 3)
    end
end)

local antiRagdollToggle = createToggle("Anti Ragdoll", false, function(state)
    if state then
        Script.Functions.BypassRagdoll()
        Library:Notify("Anti Ragdoll enabled!", 3)
        Script.Temp.AntiRagdollLoop = task.spawn(function()
            while antiRagdollToggle.Value and not Library.Unloaded do
                Script.Functions.BypassRagdoll()
                task.wait(0.1)
            end
        end)
    else
        Library:Notify("Anti Ragdoll disabled!", 3)
        if Script.Temp.AntiRagdollLoop then
            task.cancel(Script.Temp.AntiRagdollLoop)
            Script.Temp.AntiRagdollLoop = nil
        end
    end
end)

createDivider()
createLabel("=== Game Features ===")

createButton("Complete RLGL", function()
    if not workspace:FindFirstChild("RedLightGreenLight") then
        Library:Notify("Game didn't start yet", 3)
        return
    end
    Script.Functions.WinRLGL()
    Library:Notify("Completed RLGL!", 3)
end)

createButton("Complete Glass Bridge", function()
    if not workspace:FindFirstChild("GlassBridge") then
        Library:Notify("Game didn't start yet", 3)
        return
    end
    Script.Functions.WinGlassBridge()
    Library:Notify("Completed Glass Bridge!", 3)
end)

createButton("Reveal Glass Bridge", function()
    if not workspace:FindFirstChild("GlassBridge") then
        Library:Notify("Game didn't start yet", 3)
        return
    end
    Script.Functions.RevealGlassBridge()
end)

createButton("Complete Jump Rope", function()
    Script.Functions.WinJumpRope()
    Library:Notify("Completed Jump Rope!", 3)
end)

createButton("Teleport to Safe Zone", function()
    Script.Functions.TeleportSafe()
    Library:Notify("Teleported to Safe Zone!", 3)
end)

createButton("Teleport to Hiding Spot", function()
    Script.Functions.TeleportSafeHidingSpot()
    Library:Notify("Teleported to Hiding Spot!", 3)
end)

createDivider()
createLabel("=== Security ===")

local staffDetectorToggle = createToggle("Staff Detector", true, function(state)
    if state then
        Library:Notify("Staff Detector enabled!", 3)
    else
        Library:Notify("Staff Detector disabled!", 3)
    end
end)

local antiDeathToggle = createToggle("Anti Death", false, function(state)
    if state then
        Library:Notify("Anti Death enabled!", 3)
    else
        Library:Notify("Anti Death disabled!", 3)
    end
end)

createDivider()
createLabel("=== Performance ===")

local lowGfxToggle = createToggle("Low GFX", false, function(state)
    if state then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        pcall(function()
            settings().Rendering.QualityLevel = 1
        end)
        Library:Notify("Low GFX enabled!", 3)
    else
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
        pcall(function()
            settings().Rendering.QualityLevel = 10
        end)
        Library:Notify("Low GFX disabled!", 3)
    end
end)

createDivider()
createLabel("=== Settings ===")

createButton("Fix Camera", function()
    Script.Functions.FixCamera()
    Library:Notify("Camera fixed!", 3)
end)

createButton("Fix Players Visibility", function()
    Script.Functions.CheckPlayersVisibility()
    Library:Notify("Players visibility fixed!", 3)
end)

createButton("Remove Ragdoll Effect", function()
    Script.Functions.BypassRagdoll()
    Library:Notify("Ragdoll effect removed!", 3)
end)

createButton("Unload", function()
    Library:Unload()
    ScreenGui:Destroy()
    Library:Notify("itoshi rin unloaded!", 3)
end)

-- Setup ESP connections
Library:GiveSignal(Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        Script.Functions.SetupOtherPlayerConnection(player)
    end
end))

Library:GiveSignal(Players.PlayerRemoving:Connect(function(player)
    if Script.ESPTable then
        local function clearESP(typeTable)
            if not typeTable then return end
            for i, esp in pairs(typeTable) do
                if esp.Object == player.Character or esp.TextParent == player.Character or esp.Object == player then
                    if esp.Destroy then esp.Destroy() end
                    typeTable[i] = nil
                end
            end
        end

        if Script.ESPTable.Player then clearESP(Script.ESPTable.Player) end
        if Script.ESPTable.Seeker then clearESP(Script.ESPTable.Seeker) end
        if Script.ESPTable.Hider then clearESP(Script.ESPTable.Hider) end
    end
end))

-- Setup Anti AFK by default
if antiAfkToggle.Value then
    local VirtualUser = game:GetService("VirtualUser")
    Script.Temp.AntiAfkConnection = lplr.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
    end)
end

-- Setup game state tracking
if workspace:WaitForChild("Values"):WaitForChild("CurrentGame") then
    Script.GameState = workspace.Values.CurrentGame.Value
    
    Library:GiveSignal(workspace.Values.CurrentGame:GetPropertyChangedSignal("Value"):Connect(function()
        Script.GameState = workspace.Values.CurrentGame.Value
        Script.GameStateChanged:Fire(Script.GameState)
    end))
end

Library:Notify("itoshi rin loaded successfully with all features!", 5)

-- Store library in shared
shared.itoshi_hub_InkGame_Library = Library

-- Unload function
Library:OnUnload(function()
    if Library._signals then
        for _, v in pairs(Library._signals) do
            pcall(function()
                v:Disconnect()
            end)
        end
    end
    pcall(function()
        Script.Maid:Clean()
    end)
    for _, conn in pairs(Script.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    for _, conn in pairs(Script.Temp) do
        pcall(function()
            if conn and typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            elseif conn and typeof(conn) == "Instance" then
                conn:Destroy()
            end
        end)
    end
    table.clear(Script.Temp)
    table.clear(Script.Connections)
    for _, espType in pairs(Script.ESPTable) do
        for _, esp in pairs(espType) do
            pcall(esp.Destroy)
        end
    end
    Library.Unloaded = true
    getgenv().itoshi_hub_loaded = false
    shared.itoshi_hub_InkGame_Library = nil
end)
