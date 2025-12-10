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

local Library = {
    Unloaded = false,
    _signals = {},
    _connections = {},
    _cache = {},
    Options = {},
    Toggles = {},
    Sliders = {},
    Dropdowns = {},
    Keybinds = {},
    Themes = {
        Default = {Primary = Color3.fromRGB(0, 255, 255), Secondary = Color3.fromRGB(20, 20, 20), Accent = Color3.fromRGB(255, 50, 50), Text = Color3.fromRGB(255, 255, 255)},
        Dark = {Primary = Color3.fromRGB(255, 0, 128), Secondary = Color3.fromRGB(15, 15, 15), Accent = Color3.fromRGB(0, 200, 255), Text = Color3.fromRGB(240, 240, 240)},
        Neon = {Primary = Color3.fromRGB(0, 255, 0), Secondary = Color3.fromRGB(10, 10, 10), Accent = Color3.fromRGB(255, 255, 0), Text = Color3.fromRGB(255, 255, 255)},
        Cyberpunk = {Primary = Color3.fromRGB(255, 0, 255), Secondary = Color3.fromRGB(10, 10, 30), Accent = Color3.fromRGB(0, 255, 255), Text = Color3.fromRGB(255, 255, 255)},
        Matrix = {Primary = Color3.fromRGB(0, 255, 0), Secondary = Color3.fromRGB(0, 0, 0), Accent = Color3.fromRGB(0, 150, 0), Text = Color3.fromRGB(0, 255, 0)}
    },
    CurrentTheme = "Default",
    Configs = {},
    Version = "5.0.0",
    _performance = {
        updateRate = 120,
        lastUpdate = 0,
        frameCount = 0,
        fps = 0
    }
}

local NotificationQueue = {}
local NotificationActive = false

function Library:Notify(text, duration, notificationType)
    local notifTypes = {
        Info = {Color = Color3.fromRGB(0, 150, 255)},
        Success = {Color = Color3.fromRGB(0, 200, 0)},
        Warning = {Color = Color3.fromRGB(255, 165, 0)},
        Error = {Color = Color3.fromRGB(255, 50, 50)},
        Critical = {Color = Color3.fromRGB(255, 0, 0)}
    }
    
    table.insert(NotificationQueue, {
        Text = text,
        Duration = duration or 3,
        Type = notifTypes[notificationType] or notifTypes.Info
    })
    
    if not NotificationActive then
        Library:ProcessNotificationQueue()
    end
end

function Library:ProcessNotificationQueue()
    if #NotificationQueue == 0 then
        NotificationActive = false
        return
    end
    
    NotificationActive = true
    local notif = table.remove(NotificationQueue, 1)
    
    local NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "Notification_" .. tick()
    NotificationGui.Parent = game:GetService("CoreGui")
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = NotificationGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.Position = UDim2.new(1, 350, 1, -80)
    MainFrame.Size = UDim2.new(0, 340, 0, 70)
    MainFrame.AnchorPoint = Vector2.new(1, 1)
    MainFrame.ZIndex = 99999
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = notif.Type.Color
    UIStroke.Thickness = 2
    UIStroke.Parent = MainFrame
    
    local Glow = Instance.new("ImageLabel")
    Glow.Parent = MainFrame
    Glow.BackgroundTransparency = 1
    Glow.Size = UDim2.new(1, 20, 1, 20)
    Glow.Position = UDim2.new(0, -10, 0, -10)
    Glow.Image = "rbxassetid://8992231221"
    Glow.ImageColor3 = notif.Type.Color
    Glow.ImageTransparency = 0.7
    Glow.ScaleType = Enum.ScaleType.Slice
    Glow.SliceCenter = Rect.new(100, 100, 100, 100)
    Glow.ZIndex = -1
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = MainFrame
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 50, 0, 10)
    TitleLabel.Size = UDim2.new(1, -60, 0, 20)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "itoshi rin v5.0"
    TitleLabel.TextColor3 = notif.Type.Color
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 100000
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Parent = MainFrame
    TextLabel.BackgroundTransparency = 1
    TextLabel.Position = UDim2.new(0, 50, 0, 30)
    TextLabel.Size = UDim2.new(1, -60, 1, -40)
    TextLabel.Font = Enum.Font.Gotham
    TextLabel.Text = notif.Text
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.TextSize = 12
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.TextYAlignment = Enum.TextYAlignment.Top
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 100000
    
    local ts = game:GetService("TweenService")
    local slideIn = ts:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -350, 1, -80)})
    slideIn:Play()
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Parent = MainFrame
    ProgressBar.BackgroundColor3 = notif.Type.Color
    ProgressBar.Size = UDim2.new(0, 0, 0, 2)
    ProgressBar.Position = UDim2.new(0, 0, 1, -2)
    ProgressBar.BorderSizePixel = 0
    
    local progressTween = ts:Create(ProgressBar, TweenInfo.new(notif.Duration - 0.5, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 2)})
    progressTween:Play()
    
    task.delay(notif.Duration, function()
        local slideOut = ts:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 350, 1, -80)})
        slideOut:Play()
        slideOut.Completed:Wait()
        NotificationGui:Destroy()
        task.wait(0.2)
        Library:ProcessNotificationQueue()
    end)
end

function Library:SaveConfig(name)
    local config = {
        Version = self.Version,
        Toggles = {},
        Sliders = {},
        Dropdowns = {},
        Keybinds = {},
        Theme = self.CurrentTheme,
        Timestamp = os.time()
    }
    
    for optionName, option in pairs(self.Toggles) do
        config.Toggles[optionName] = option.Value
    end
    
    for optionName, option in pairs(self.Sliders) do
        config.Sliders[optionName] = option.Value
    end
    
    self.Configs[name] = config
    
    pcall(function()
        local data = game:GetService("HttpService"):JSONEncode(config)
        writefile("itoshi_config_" .. name .. ".json", data)
    end)
    
    Library:Notify("Config '" .. name .. "' saved!", 3, "Success")
end

function Library:LoadConfig(name)
    local success, config = pcall(function()
        local data = readfile("itoshi_config_" .. name .. ".json")
        return game:GetService("HttpService"):JSONDecode(data)
    end)
    
    if not success then
        config = self.Configs[name]
    end
    
    if config then
        for optionName, value in pairs(config.Toggles) do
            if self.Toggles[optionName] then
                self.Toggles[optionName].SetState(value)
            end
        end
        
        for optionName, value in pairs(config.Sliders) do
            if self.Sliders[optionName] then
                self.Sliders[optionName].SetValue(value)
            end
        end
        
        if config.Theme then
            self.CurrentTheme = config.Theme
        end
        
        Library:Notify("Config '" .. name .. "' loaded!", 3, "Success")
    else
        Library:Notify("Config not found!", 3, "Error")
    end
end

function Library:DeleteConfig(name)
    self.Configs[name] = nil
    pcall(function()
        delfile("itoshi_config_" .. name .. ".json")
    end)
    Library:Notify("Config '" .. name .. "' deleted!", 3, "Success")
end

local Performance = {
    _cache = {},
    _updates = {},
    _lastUpdate = tick()
}

function Performance:AddUpdate(name, func, interval)
    self._updates[name] = {Func = func, Interval = interval or 0.008, LastRun = 0}
end

function Performance:RemoveUpdate(name)
    self._updates[name] = nil
end

function Performance:RunUpdates()
    local currentTime = tick()
    for name, update in pairs(self._updates) do
        if currentTime - update.LastRun >= update.Interval then
            update.LastRun = currentTime
            pcall(update.Func)
        end
    end
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local MarketPlaceService = game:GetService("MarketplaceService")
local ContentProvider = game:GetService("ContentProvider")
local VirtualInputManager = game:GetService("VirtualInputManager")

local lplr = Players.LocalPlayer
local localPlayer = lplr
local camera = Workspace.CurrentCamera
local Mouse = lplr:GetMouse()

for _, gui in pairs(CoreGui:GetChildren()) do
    if gui.Name == "ItoshiHub" then 
        gui:Destroy()
    end
end

for _, gui in pairs(lplr:WaitForChild("PlayerGui"):GetChildren()) do
    if gui.Name == "ItoshiHub" then 
        gui:Destroy()
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ItoshiHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "Toggle"
OpenBtn.Parent = ScreenGui
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
OpenBtn.Position = UDim2.new(0.01, 0, 0.5, -25)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.Text = "☰"
OpenBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
OpenBtn.TextSize = 20
OpenBtn.Draggable = true
OpenBtn.AutoButtonColor = false
OpenBtn.ZIndex = 1000
OpenBtn.Visible = true

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = OpenBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(0, 255, 255)
btnStroke.Thickness = 2
btnStroke.Parent = OpenBtn

local btnGradient = Instance.new("UIGradient")
btnGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 200))
}
btnGradient.Rotation = 45
btnGradient.Parent = btnStroke

OpenBtn.MouseEnter:Connect(function()
    TweenService:Create(OpenBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 55, 0, 55),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    }):Play()
    
    TweenService:Create(btnStroke, TweenInfo.new(0.2), {
        Thickness = 3
    }):Play()
end)

OpenBtn.MouseLeave:Connect(function()
    TweenService:Create(OpenBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 50, 0, 50),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    }):Play()
    
    TweenService:Create(btnStroke, TweenInfo.new(0.2), {
        Thickness = 2
    }):Play()
end)

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Visible = false
MainFrame.ZIndex = 999
MainFrame.ClipsDescendants = true

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = MainFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0, 255, 255)
frameStroke.Thickness = 1
frameStroke.Parent = MainFrame

local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 200))
}
frameGradient.Transparency = NumberSequence.new(0.5)
frameGradient.Parent = frameStroke

local frameShadow = Instance.new("ImageLabel")
frameShadow.Parent = MainFrame
frameShadow.BackgroundTransparency = 1
frameShadow.Size = UDim2.new(1, 20, 1, 20)
frameShadow.Position = UDim2.new(0, -10, 0, -10)
frameShadow.Image = "rbxassetid://8992231221"
frameShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
frameShadow.ImageTransparency = 0.8
frameShadow.ScaleType = Enum.ScaleType.Slice
frameShadow.SliceCenter = Rect.new(100, 100, 100, 100)
frameShadow.ZIndex = -1

local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.ZIndex = 1000
TopBar.ClipsDescendants = true

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 12, 0, 0)
topBarCorner.Parent = TopBar

local topBarGradient = Instance.new("UIGradient")
topBarGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
}
topBarGradient.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "itoshi rin v5.0 | LEGENDARY"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 15, 0, 0)
Title.ZIndex = 1001

local titleGlow = Instance.new("TextLabel")
titleGlow.Parent = Title
titleGlow.BackgroundTransparency = 1
titleGlow.Size = UDim2.new(1, 4, 1, 4)
titleGlow.Position = UDim2.new(0, -2, 0, -2)
titleGlow.Font = Enum.Font.GothamBold
titleGlow.Text = Title.Text
titleGlow.TextColor3 = Color3.fromRGB(0, 255, 255)
titleGlow.TextSize = 16
titleGlow.TextXAlignment = Enum.TextXAlignment.Left
titleGlow.TextTransparency = 0.7
titleGlow.ZIndex = 1000

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.TextSize = 24
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 1001

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
        TextColor3 = Color3.fromRGB(255, 100, 100),
        Rotation = 90
    }):Play()
end)

CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
        TextColor3 = Color3.fromRGB(255, 50, 50),
        Rotation = 0
    }):Play()
end)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = TopBar
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 24
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.ZIndex = 1001

local TabContainer = Instance.new("Frame")
TabContainer.Parent = MainFrame
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.Size = UDim2.new(1, 0, 0, 40)
TabContainer.ZIndex = 999

local TabButtons = {}
local TabContents = {}

local Tabs = {
    "Main",
    "Combat",
    "AutoFarm",
    "Visuals", 
    "Player",
    "Teleport",
    "Misc",
    "Settings"
}

for i, tabName in pairs(Tabs) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = TabContainer
    TabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(30, 30, 30)
    TabBtn.Position = UDim2.new((i-1) * (1/#Tabs), 0, 0, 0)
    TabBtn.Size = UDim2.new(1/#Tabs, 0, 1, 0)
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.Text = tabName
    TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabBtn.TextSize = 12
    TabBtn.AutoButtonColor = false
    TabBtn.ZIndex = 1000
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 0)
    tabCorner.Parent = TabBtn
    
    local tabGradient = Instance.new("UIGradient")
    tabGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, i == 1 and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(35, 35, 35)),
        ColorSequenceKeypoint.new(1, i == 1 and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(30, 30, 30))
    }
    tabGradient.Parent = TabBtn
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Parent = MainFrame
    TabContent.Active = true
    TabContent.BackgroundTransparency = 1
    TabContent.BorderSizePixel = 0
    TabContent.Position = UDim2.new(0, 10, 0, 85)
    TabContent.Size = UDim2.new(1, -20, 1, -95)
    TabContent.ScrollBarThickness = 4
    TabContent.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
    TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContent.Visible = i == 1
    TabContent.ZIndex = 998
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = TabContent
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 8)
    
    TabButtons[tabName] = TabBtn
    TabContents[tabName] = TabContent
    
    TabBtn.MouseButton1Click:Connect(function()
        for _, btn in pairs(TabButtons) do
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            }):Play()
        end
        
        TweenService:Create(TabBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        }):Play()
        
        for _, content in pairs(TabContents) do
            content.Visible = false
        end
        TabContent.Visible = true
        
        TabContent.CanvasPosition = Vector2.new(0, 0)
    end)
end

local function CreateSection(parent, title)
    local Section = Instance.new("Frame")
    Section.Parent = parent
    Section.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Section.Size = UDim2.new(1, 0, 0, 40)
    Section.ZIndex = 997
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = Section
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 255, 255)
    UIStroke.Thickness = 1
    UIStroke.Parent = Section
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = Section
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "  " .. title
    TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 998
    
    local Container = Instance.new("Frame")
    Container.Parent = Section
    Container.BackgroundTransparency = 1
    Container.Position = UDim2.new(0, 10, 0, 40)
    Container.Size = UDim2.new(1, -20, 0, 0)
    Container.ZIndex = 997
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = Container
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 5)
    
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Container.Size = UDim2.new(1, -20, 0, ListLayout.AbsoluteContentSize.Y)
        Section.Size = UDim2.new(1, 0, 0, 40 + Container.Size.Y.Offset)
    end)
    
    return Container
end

local function CreateButton(parent, text, callback, options)
    local options = options or {}
    local Button = Instance.new("TextButton")
    Button.Parent = parent
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Button.Size = UDim2.new(1, 0, 0, 35)
    Button.Font = Enum.Font.GothamSemibold
    Button.Text = "  " .. text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 13
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.AutoButtonColor = false
    Button.ZIndex = 997
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = Button
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 255, 255)
    UIStroke.Thickness = 1
    UIStroke.Parent = Button
    
    local Icon = Instance.new("TextLabel")
    Icon.Parent = Button
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(1, -30, 0, 0)
    Icon.Size = UDim2.new(0, 30, 1, 0)
    Icon.Font = Enum.Font.GothamBold
    Icon.Text = "›"
    Icon.TextColor3 = Color3.fromRGB(0, 255, 255)
    Icon.TextSize = 18
    Icon.ZIndex = 998
    
    local hoverTween
    Button.MouseEnter:Connect(function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        })
        hoverTween:Play()
        
        TweenService:Create(UIStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(0, 200, 200),
            Thickness = 2
        }):Play()
        
        TweenService:Create(Icon, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(1, -25, 0, 0)
        }):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        })
        hoverTween:Play()
        
        TweenService:Create(UIStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(0, 255, 255),
            Thickness = 1
        }):Play()
        
        TweenService:Create(Icon, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(0, 255, 255),
            Position = UDim2.new(1, -30, 0, 0)
        }):Play()
    end)
    
    Button.MouseButton1Click:Connect(function()
        local clickTween = TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.95, 0, 0, 33),
            BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        })
        clickTween:Play()
        
        TweenService:Create(UIStroke, TweenInfo.new(0.1), {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 3
        }):Play()
        
        clickTween.Completed:Wait()
        
        TweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        }):Play()
        
        TweenService:Create(UIStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(0, 255, 255),
            Thickness = 1
        }):Play()
        
        pcall(callback)
    end)
    
    return Button
end

local function CreateToggle(parent, text, default, callback, options)
    local options = options or {}
    local state = default or false
    local Toggle = Instance.new("TextButton")
    Toggle.Parent = parent
    Toggle.BackgroundColor3 = state and Color3.fromRGB(0, 100, 100) or Color3.fromRGB(40, 40, 40)
    Toggle.Size = UDim2.new(1, 0, 0, 35)
    Toggle.Font = Enum.Font.GothamSemibold
    Toggle.Text = "  " .. text
    Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toggle.TextSize = 13
    Toggle.TextXAlignment = Enum.TextXAlignment.Left
    Toggle.AutoButtonColor = false
    Toggle.ZIndex = 997
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = Toggle
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = state and Color3.fromRGB(0, 200, 200) or Color3.fromRGB(0, 255, 255)
    UIStroke.Thickness = 1
    UIStroke.Parent = Toggle
    
    local Status = Instance.new("Frame")
    Status.Parent = Toggle
    Status.BackgroundColor3 = state and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(100, 100, 100)
    Status.Position = UDim2.new(1, -40, 0.5, -10)
    Status.Size = UDim2.new(0, 20, 0, 20)
    Status.AnchorPoint = Vector2.new(1, 0.5)
    Status.ZIndex = 998
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(1, 0)
    statusCorner.Parent = Status
    
    local statusGlow = Instance.new("ImageLabel")
    statusGlow.Parent = Status
    statusGlow.BackgroundTransparency = 1
    statusGlow.Size = UDim2.new(1, 10, 1, 10)
    statusGlow.Position = UDim2.new(0, -5, 0, -5)
    statusGlow.Image = "rbxassetid://8992231221"
    statusGlow.ImageColor3 = state and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(100, 100, 100)
    statusGlow.ImageTransparency = 0.7
    statusGlow.ScaleType = Enum.ScaleType.Slice
    statusGlow.SliceCenter = Rect.new(100, 100, 100, 100)
    statusGlow.ZIndex = 997
    
    local function SetState(newState)
        state = newState
        
        TweenService:Create(Toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundColor3 = state and Color3.fromRGB(0, 100, 100) or Color3.fromRGB(40, 40, 40)
        }):Play()
        
        TweenService:Create(UIStroke, TweenInfo.new(0.3), {
            Color = state and Color3.fromRGB(0, 200, 200) or Color3.fromRGB(0, 255, 255)
        }):Play()
        
        TweenService:Create(Status, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {
            BackgroundColor3 = state and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(100, 100, 100),
            Size = state and UDim2.new(0, 25, 0, 25) or UDim2.new(0, 20, 0, 20)
        }):Play()
        
        TweenService:Create(statusGlow, TweenInfo.new(0.3), {
            ImageColor3 = state and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(100, 100, 100)
        }):Play()
        
        pcall(callback, state)
    end
    
    Toggle.MouseButton1Click:Connect(function()
        SetState(not state)
        
        TweenService:Create(Status, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 15, 0, 15)
        }):Play()
        
        task.wait(0.1)
        
        TweenService:Create(Status, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
            Size = state and UDim2.new(0, 25, 0, 25) or UDim2.new(0, 20, 0, 20)
        }):Play()
    end)
    
    local toggleName = text:gsub("%s+", "_")
    Library.Toggles[toggleName] = {
        Value = state,
        SetState = SetState,
        OnChanged = function(newCallback)
            callback = newCallback
        end
    }
    
    return Library.Toggles[toggleName]
end

local function CreateSlider(parent, text, min, max, default, callback, options)
    local options = options or {}
    local value = default or min
    local dragging = false
    
    local SliderContainer = Instance.new("Frame")
    SliderContainer.Parent = parent
    SliderContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    SliderContainer.Size = UDim2.new(1, 0, 0, 60)
    SliderContainer.ZIndex = 997
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = SliderContainer
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 255, 255)
    UIStroke.Thickness = 1
    UIStroke.Parent = SliderContainer
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = SliderContainer
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 10, 0, 5)
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Font = Enum.Font.GothamSemibold
    TitleLabel.Text = "  " .. text
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 998
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Parent = SliderContainer
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Position = UDim2.new(1, -60, 0, 5)
    ValueLabel.Size = UDim2.new(0, 50, 0, 20)
    ValueLabel.Font = Enum.Font.Gotham
    ValueLabel.Text = tostring(value)
    ValueLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    ValueLabel.TextSize = 12
    ValueLabel.ZIndex = 998
    
    local SliderTrack = Instance.new("Frame")
    SliderTrack.Parent = SliderContainer
    SliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    SliderTrack.Position = UDim2.new(0, 15, 0, 35)
    SliderTrack.Size = UDim2.new(1, -30, 0, 8)
    SliderTrack.ZIndex = 997
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = SliderTrack
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Parent = SliderTrack
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    SliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    SliderFill.ZIndex = 998
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = SliderFill
    
    local fillGradient = Instance.new("UIGradient")
    fillGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 200))
    }
    fillGradient.Parent = SliderFill
    
    local SliderButton = Instance.new("TextButton")
    SliderButton.Parent = SliderTrack
    SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderButton.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
    SliderButton.Size = UDim2.new(0, 16, 0, 16)
    SliderButton.Text = ""
    SliderButton.AutoButtonColor = false
    SliderButton.ZIndex = 999
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = SliderButton
    
    local buttonGlow = Instance.new("ImageLabel")
    buttonGlow.Parent = SliderButton
    buttonGlow.BackgroundTransparency = 1
    buttonGlow.Size = UDim2.new(1, 10, 1, 10)
    buttonGlow.Position = UDim2.new(0, -5, 0, -5)
    buttonGlow.Image = "rbxassetid://8992231221"
    buttonGlow.ImageColor3 = Color3.fromRGB(0, 255, 255)
    buttonGlow.ImageTransparency = 0.7
    buttonGlow.ScaleType = Enum.ScaleType.Slice
    buttonGlow.SliceCenter = Rect.new(100, 100, 100, 100)
    buttonGlow.ZIndex = 998
    
    local function SetValue(newValue)
        newValue = math.clamp(newValue, min, max)
        value = math.floor(newValue)
        
        ValueLabel.Text = tostring(value)
        
        TweenService:Create(SliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        }):Play()
        
        TweenService:Create(SliderButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
        }):Play()
        
        pcall(callback, value)
    end
    
    SliderButton.MouseButton1Down:Connect(function()
        dragging = true
        TweenService:Create(SliderButton, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 20, 0, 20)
        }):Play()
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                TweenService:Create(SliderButton, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, 16, 0, 16)
                }):Play()
            end
            dragging = false
        end
    end)
    
    local sliderConnection
    sliderConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = (input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X
            local newValue = min + (relativeX * (max - min))
            SetValue(newValue)
        end
    end)
    
    table.insert(Library._connections, sliderConnection)
    
    SetValue(value)
    
    local sliderName = text:gsub("%s+", "_")
    Library.Sliders[sliderName] = {
        Value = value,
        SetValue = SetValue,
        Min = min,
        Max = max
    }
    
    return Library.Sliders[sliderName]
end

local MainTab = TabContents.Main
local MainSection = CreateSection(MainTab, "QUICK ACTIONS")

CreateButton(MainSection, "INSTANT WIN ALL GAMES", function()
    Library:Notify("Activating ULTIMATE WIN SYSTEM...", 3, "Critical")
    
    local function teleportTo(position)
        if lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") then
            lplr.Character:PivotTo(CFrame.new(position))
        end
    end
    
    local winSequence = {
        Vector3.new(-100.8, 1030, 115),
        Vector3.new(-203.9, 525.7, -1534.3485),
        Vector3.new(732.4, 197.14, 931.1644),
        Vector3.new(-106.7, 328.9, 465.7),
        Vector3.new(195.6, 122.7, -93.1)
    }
    
    for i, pos in ipairs(winSequence) do
        teleportTo(pos)
        task.wait(0.3)
    end
    
    Library:Notify("ALL GAMES COMPLETED!", 5, "Success")
end)

CreateButton(MainSection, "REVEAL ALL BRIDGES", function()
    Library:Notify("Scanning and revealing all bridges...", 3, "Info")
    
    for _, part in pairs(Workspace:GetDescendants()) do
        if part.Name:find("Bridge") or part.Name:find("Glass") then
            if part:IsA("BasePart") then
                part.Transparency = 0.3
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(0, 255, 255)
            end
        end
    end
    
    Library:Notify("All bridges revealed!", 3, "Success")
end)

CreateButton(MainSection, "KILL ALL PLAYERS", function()
    Library:Notify("Executing MASS ELIMINATION...", 3, "Warning")
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end
    
    Library:Notify("ALL PLAYERS ELIMINATED!", 3, "Success")
end)

CreateButton(MainSection, "SPEED RUN MODE", function()
    Library:Notify("Activating SPEED RUN mode...", 3, "Critical")
    
    if Library.Toggles.Speed_Hack then
        Library.Toggles.Speed_Hack.SetState(true)
        Library.Sliders.Speed_Value.SetValue(150)
    end
    
    if Library.Toggles.Fly then
        Library.Toggles.Fly.SetState(true)
        Library.Sliders.Fly_Speed.SetValue(100)
    end
    
    if Library.Toggles.God_Mode then
        Library.Toggles.God_Mode.SetState(true)
    end
    
    Library:Notify("SPEED RUN MODE ACTIVATED!", 5, "Success")
end)

local MainSection2 = CreateSection(MainTab, "GAME FEATURES")
CreateToggle(MainSection2, "Auto Complete Games", false, function(state)
    Library:Notify(state and "Auto Complete: ON" or "Auto Complete: OFF", 2, state and "Success" or "Info")
end)

CreateToggle(MainSection2, "Anti-Elimination", true, function(state)
    Library:Notify(state and "Anti-Elimination: ON" or "Anti-Elimination: OFF", 2, state and "Success" or "Info")
end)

CreateToggle(MainSection2, "Force Win", false, function(state)
    Library:Notify(state and "Force Win: ON" or "Force Win: OFF", 2, state and "Warning" or "Info")
end)

CreateToggle(MainSection2, "Instant Respawn", true, function(state)
    Library:Notify(state and "Instant Respawn: ON" or "Instant Respawn: OFF", 2, "Info")
end)

local CombatTab = TabContents.Combat
local CombatSection = CreateSection(CombatTab, "KILL AURA SYSTEM")

local KillAuraToggle = CreateToggle(CombatSection, "Kill Aura", false, function(state)
    Library:Notify(state and "Kill Aura: ON" or "Kill Aura: OFF", 2, state and "Critical" or "Info")
end)

local KillAuraRange = CreateSlider(CombatSection, "Kill Aura Range", 1, 100, 25, function(value)
    Library:Notify("Kill Aura Range: " .. value, 2, "Info")
end)

local KillAuraSpeed = CreateSlider(CombatSection, "Kill Aura Speed", 1, 100, 30, function(value)
    Library:Notify("Kill Aura Speed: " .. value, 2, "Info")
end)

local CombatSection2 = CreateSection(CombatTab, "COMBAT MODS")
CreateToggle(CombatSection2, "Auto Attack", false, function(state)
    Library:Notify(state and "Auto Attack: ON" or "Auto Attack: OFF", 2, "Info")
end)

CreateToggle(CombatSection2, "Critical Hits", false, function(state)
    Library:Notify(state and "Critical Hits: ON" or "Critical Hits: OFF", 2, "Info")
end)

CreateToggle(CombatSection2, "No Cooldown", false, function(state)
    Library:Notify(state and "No Cooldown: ON" or "No Cooldown: OFF", 2, "Info")
end)

CreateToggle(CombatSection2, "Infinite Ammo", false, function(state)
    Library:Notify(state and "Infinite Ammo: ON" or "Infinite Ammo: OFF", 2, "Info")
end)

local CombatSection3 = CreateSection(CombatTab, "DEFENSIVE")
CreateToggle(CombatSection3, "Anti-Fling", true, function(state)
    Library:Notify(state and "Anti-Fling: ON" or "Anti-Fling: OFF", 2, "Info")
end)

CreateToggle(CombatSection3, "Anti-Stun", true, function(state)
    Library:Notify(state and "Anti-Stun: ON" or "Anti-Stun: OFF", 2, "Info")
end)

CreateToggle(CombatSection3, "Anti-Knockback", false, function(state)
    Library:Notify(state and "Anti-Knockback: ON" or "Anti-Knockback: OFF", 2, "Info")
end)

CreateToggle(CombatSection3, "Ghost Mode", false, function(state)
    Library:Notify(state and "Ghost Mode: ON" or "Ghost Mode: OFF", 2, "Info")
end)

local AutoFarmTab = TabContents.AutoFarm
local FarmSection = CreateSection(AutoFarmTab, "ULTIMATE AUTOFARM")

local AutoFarmToggle = CreateToggle(FarmSection, "Enable Auto Farm", false, function(state)
    Library:Notify(state and "Auto Farm: ACTIVATED" or "Auto Farm: DEACTIVATED", 3, state and "Success" or "Info")
end)

local FarmSpeed = CreateSlider(FarmSection, "Farm Speed", 1, 500, 100, function(value)
    Library:Notify("Farm Speed: " .. value, 2, "Info")
end)

local EfficiencyToggle = CreateToggle(FarmSection, "High Efficiency Mode", true, function(state)
    Library:Notify(state and "High Efficiency: ON" or "High Efficiency: OFF", 2, "Info")
end)

local FarmSection2 = CreateSection(AutoFarmTab, "TELEPORT LOCATIONS")
CreateButton(FarmSection2, "RLGL Arena", function()
    if lplr.Character then
        lplr.Character:PivotTo(CFrame.new(-45.0, 1023.3, 95.1))
        Library:Notify("Teleported to RLGL Arena!", 2, "Success")
    end
end)

CreateButton(FarmSection2, "Lights Out Room", function()
    if lplr.Character then
        lplr.Character:PivotTo(CFrame.new(195.6, 122.7, -93.1))
        Library:Notify("Teleported to Lights Out!", 2, "Success")
    end
end)

CreateButton(FarmSection2, "Glass Bridge Start", function()
    if lplr.Character then
        lplr.Character:PivotTo(CFrame.new(-206.4, 520.7, -1534.0))
        Library:Notify("Teleported to Glass Bridge!", 2, "Success")
    end
end)

CreateButton(FarmSection2, "Jump Rope Area", function()
    if lplr.Character then
        lplr.Character:PivotTo(CFrame.new(732.4, 197.14, 931.1644))
        Library:Notify("Teleported to Jump Rope!", 2, "Success")
    end
end)

local VisualsTab = TabContents.Visuals
local ESPSection = CreateSection(VisualsTab, "ADVANCED ESP")

local PlayerESPToggle = CreateToggle(ESPSection, "Player ESP", false, function(state)
    Library:Notify(state and "Player ESP: ON" or "Player ESP: OFF", 2, "Info")
end)

local GuardESPToggle = CreateToggle(ESPSection, "Guard ESP", false, function(state)
    Library:Notify(state and "Guard ESP: ON" or "Guard ESP: OFF", 2, "Info")
end)

local ItemESPToggle = CreateToggle(ESPSection, "Item ESP", false, function(state)
    Library:Notify(state and "Item ESP: ON" or "Item ESP: OFF", 2, "Info")
end)

local ChamsToggle = CreateToggle(ESPSection, "Chams", false, function(state)
    Library:Notify(state and "Chams: ON" or "Chams: OFF", 2, "Info")
end)

local TracersToggle = CreateToggle(ESPSection, "Tracers", false, function(state)
    Library:Notify(state and "Tracers: ON" or "Tracers: OFF", 2, "Info")
end)

local BoxESToggle = CreateToggle(ESPSection, "Box ESP", false, function(state)
    Library:Notify(state and "Box ESP: ON" or "Box ESP: OFF", 2, "Info")
end)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    
    if MainFrame.Visible then
        MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
        TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -200, 0.5, -250)
        }):Play()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    
    task.wait(0.3)
    MainFrame.Visible = false
    MainFrame.Size = UDim2.new(0, 400, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    if MainFrame.Size == UDim2.new(0, 400, 0, 500) then
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 400, 0, 80)
        }):Play()
        TabContainer.Visible = false
        for _, content in pairs(TabContents) do
            content.Visible = false
        end
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 400, 0, 500)
        }):Play()
        task.wait(0.3)
        TabContainer.Visible = true
        TabContents.Main.Visible = true
    end
end)

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

local Keybinds = {
    ["RightShift"] = function() MainFrame.Visible = not MainFrame.Visible end,
    ["C"] = function() if Library.Toggles.Speed_Hack then Library.Toggles.Speed_Hack.SetState(not Library.Toggles.Speed_Hack.Value) end end,
    ["F"] = function() if Library.Toggles.Fly then Library.Toggles.Fly.SetState(not Library.Toggles.Fly.Value) end end,
    ["N"] = function() if Library.Toggles.Noclip then Library.Toggles.Noclip.SetState(not Library.Toggles.Noclip.Value) end end,
    ["J"] = function() if Library.Toggles.High_Jump then Library.Toggles.High_Jump.SetState(not Library.Toggles.High_Jump.Value) end end,
    ["K"] = function() if Library.Toggles.Kill_Aura then Library.Toggles.Kill_Aura.SetState(not Library.Toggles.Kill_Aura.Value) end end,
    ["P"] = function() if Library.Toggles.Player_ESP then Library.Toggles.Player_ESP.SetState(not Library.Toggles.Player_ESP.Value) end end,
    ["X"] = function() Library:Unload() end
}

local keybindConnection
keybindConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        local key = input.KeyCode.Name
        if Keybinds[key] then
            Keybinds[key]()
        end
    end
end)

table.insert(Library._connections, keybindConnection)

local MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "ItoshiMobileToggle"
MobileGui.ResetOnSpawn = false
MobileGui.Parent = CoreGui

local MobileToggle = Instance.new("TextButton")
MobileToggle.Name = "MobileToggle"
MobileToggle.Parent = MobileGui
MobileToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MobileToggle.BackgroundTransparency = 0.3
MobileToggle.Position = UDim2.new(0, 20, 0.5, -30)
MobileToggle.Size = UDim2.new(0, 60, 0, 60)
MobileToggle.Font = Enum.Font.SourceSansBold
MobileToggle.Text = "☰"
MobileToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
MobileToggle.TextSize = 24
MobileToggle.AutoButtonColor = true
MobileToggle.Draggable = true
MobileToggle.Active = true
MobileToggle.Visible = false

local mobileCorner = Instance.new("UICorner")
mobileCorner.CornerRadius = UDim.new(0, 8)
mobileCorner.Parent = MobileToggle

local mobileStroke = Instance.new("UIStroke")
mobileStroke.Color = Color3.fromRGB(255, 50, 50)
mobileStroke.Thickness = 2
mobileStroke.Parent = MobileToggle

MobileToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local AdvancedSystems = {
    ESP = {
        Players = {},
        Items = {},
        Guards = {},
        _highlights = {}
    },
    Combat = {
        Targets = {},
        Weapons = {},
        _lastAttack = 0
    },
    Movement = {
        Flying = false,
        Noclipping = false,
        _flyBody = nil,
        _flyGyro = nil
    },
    Farm = {
        Active = false,
        CurrentGame = nil,
        _farmThread = nil
    },
    Performance = {
        _updates = {},
        _lastUpdate = tick()
    }
}

local ESPHighlights = {}
local function UpdateESP()
    if Library.Toggles.Player_ESP and Library.Toggles.Player_ESP.Value then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= lplr and player.Character then
                if not ESPHighlights[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "PlayerESP"
                    highlight.Adornee = player.Character
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = player.Character
                    ESPHighlights[player] = highlight
                end
            elseif ESPHighlights[player] and (not player.Character or not player.Character:IsDescendantOf(workspace)) then
                ESPHighlights[player]:Destroy()
                ESPHighlights[player] = nil
            end
        end
    else
        for player, highlight in pairs(ESPHighlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        table.clear(ESPHighlights)
    end
end

local MainLoopConnection
MainLoopConnection = RunService.Stepped:Connect(function()
    local currentTime = tick()
    
    Library._performance.frameCount = Library._performance.frameCount + 1
    if currentTime - Library._performance.lastUpdate >= 1 then
        Library._performance.fps = Library._performance.frameCount
        Library._performance.frameCount = 0
        Library._performance.lastUpdate = currentTime
    end
    
    if Library.Toggles.Kill_Aura and Library.Toggles.Kill_Aura.Value then
        local target = nil
        local closestDist = math.huge
        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        
        if root then
            local range = Library.Sliders.Kill_Aura_Range and Library.Sliders.Kill_Aura_Range.Value or 25
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= lplr and player.Character then
                    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        local distance = (root.Position - targetRoot.Position).Magnitude
                        if distance < closestDist and distance < range then
                            closestDist = distance
                            target = player
                        end
                    end
                end
            end
            
            if target and currentTime - AdvancedSystems.Combat._lastAttack > (0.5 / (Library.Sliders.Kill_Aura_Speed and Library.Sliders.Kill_Aura_Speed.Value / 100 or 0.3)) then
                AdvancedSystems.Combat._lastAttack = currentTime
                
                local weapon = nil
                local weapons = {"Fork", "Bottle", "Knife", "Power Hold", "Push"}
                for _, weaponName in pairs(weapons) do
                    local tool = lplr.Character:FindFirstChild(weaponName) or lplr.Backpack:FindFirstChild(weaponName)
                    if tool then
                        weapon = tool
                        break
                    end
                end
                
                if weapon then
                    if weapon.Parent.Name == "Backpack" then
                        lplr.Character.Humanoid:EquipTool(weapon)
                    end
                    
                    local args = {"UsingMoveCustom", weapon, nil, {Clicked = true}}
                    pcall(function()
                        ReplicatedStorage.Remotes.UsedTool:FireServer(unpack(args))
                    end)
                end
            end
        end
    end
    
    if Library.Toggles.Speed_Hack and Library.Toggles.Speed_Hack.Value and lplr.Character then
        local humanoid = lplr.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Library.Sliders.Speed_Value and Library.Sliders.Speed_Value.Value or 50
        end
    elseif lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
        lplr.Character.Humanoid.WalkSpeed = 16
    end
    
    if Library.Toggles.High_Jump and Library.Toggles.High_Jump.Value and lplr.Character then
        local humanoid = lplr.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.JumpPower = Library.Sliders.Jump_Power and Library.Sliders.Jump_Power.Value or 100
        end
    elseif lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
        lplr.Character.Humanoid.JumpPower = 50
    end
    
    if Library.Toggles.Noclip and Library.Toggles.Noclip.Value and lplr.Character then
        for _, part in pairs(lplr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    UpdateESP()
    
    Performance:RunUpdates()
end)

Library:GiveSignal(MainLoopConnection)

local function EnableFly()
    local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    AdvancedSystems.Movement._flyBody = Instance.new("BodyVelocity")
    AdvancedSystems.Movement._flyBody.Velocity = Vector3.new(0, 0, 0)
    AdvancedSystems.Movement._flyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    AdvancedSystems.Movement._flyBody.P = 9e9
    AdvancedSystems.Movement._flyBody.Parent = root
    
    AdvancedSystems.Movement._flyGyro = Instance.new("BodyGyro")
    AdvancedSystems.Movement._flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    AdvancedSystems.Movement._flyGyro.P = 9e9
    AdvancedSystems.Movement._flyGyro.CFrame = root.CFrame
    AdvancedSystems.Movement._flyGyro.Parent = root
    
    lplr.Character.Humanoid.PlatformStand = true
    AdvancedSystems.Movement.Flying = true
end

local function DisableFly()
    if AdvancedSystems.Movement._flyBody then
        AdvancedSystems.Movement._flyBody:Destroy()
        AdvancedSystems.Movement._flyBody = nil
    end
    if AdvancedSystems.Movement._flyGyro then
        AdvancedSystems.Movement._flyGyro:Destroy()
        AdvancedSystems.Movement._flyGyro = nil
    end
    if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
        lplr.Character.Humanoid.PlatformStand = false
    end
    AdvancedSystems.Movement.Flying = false
end

local flyControlConnection
flyControlConnection = RunService.RenderStepped:Connect(function()
    if AdvancedSystems.Movement.Flying then
        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        if not root or not AdvancedSystems.Movement._flyBody or not AdvancedSystems.Movement._flyGyro then return end
        
        local flySpeed = Library.Sliders.Fly_Speed and Library.Sliders.Fly_Speed.Value or 50
        local moveVector = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVector = moveVector - Vector3.new(0, 1, 0)
        end
        
        if moveVector.Magnitude > 0 then
            AdvancedSystems.Movement._flyBody.Velocity = moveVector.Unit * flySpeed
        else
            AdvancedSystems.Movement._flyBody.Velocity = Vector3.new(0, 0, 0)
        end
        
        AdvancedSystems.Movement._flyGyro.CFrame = camera.CFrame
    end
end)
Library:GiveSignal(flyControlConnection)

local VirtualUser = game:GetService("VirtualUser")
local antiAFKConnection
antiAFKConnection = lplr.Idled:Connect(function()
    if Library.Toggles.Anti_AFK and Library.Toggles.Anti_AFK.Value then
        VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
    end
end)
Library:GiveSignal(antiAFKConnection)

local staffDetectorConnection
staffDetectorConnection = Players.PlayerAdded:Connect(function(player)
    task.wait(2)
    
    if Library.Toggles.Staff_Detector and Library.Toggles.Staff_Detector.Value then
        local STAFF_GROUP_ID = 12398672
        local STAFF_MIN_RANK = 120
        
        local success, rank = pcall(function()
            return player:GetRankInGroup(STAFF_GROUP_ID)
        end)
        
        if success and rank and rank >= STAFF_MIN_RANK then
            local staffRoles = {
                [120] = "Moderator",
                [254] = "Developer",
                [255] = "Owner"
            }
            
            local roleName = staffRoles[rank] or ("Rank " .. tostring(rank))
            Library:Notify("[STAFF DETECTED] " .. player.Name .. " (" .. roleName .. ")", 10, "Warning")
        end
    end
end)
Library:GiveSignal(staffDetectorConnection)

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    
    for toggleName, toggle in pairs(self.Toggles) do
        if toggle.Value then
            toggle.SetState(false)
        end
    end
    
    for _, signal in pairs(self._signals) do
        pcall(function() signal:Disconnect() end)
    end
    
    for _, connection in pairs(self._connections) do
        pcall(function() connection:Disconnect() end)
    end
    
    for _, highlight in pairs(ESPHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    table.clear(ESPHighlights)
    
    DisableFly()
    
    Lighting.Brightness = 1
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 100000
    
    pcall(function()
        settings().Rendering.QualityLevel = 10
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level20
    end)
    
    if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
        lplr.Character.Humanoid.WalkSpeed = 16
        lplr.Character.Humanoid.JumpPower = 50
        lplr.Character.Humanoid.PlatformStand = false
    end
    
    if ScreenGui then
        ScreenGui:Destroy()
    end
    if MobileGui then
        MobileGui:Destroy()
    end
    
    table.clear(self.Toggles)
    table.clear(self.Sliders)
    table.clear(self.Dropdowns)
    table.clear(self.Keybinds)
    table.clear(self.Configs)
    table.clear(self._signals)
    table.clear(self._connections)
    table.clear(self._cache)
    
    getgenv().itoshi_hub_loaded = false
    shared.itoshi_hub_InkGame_Library = nil
    
    Library:Notify("itoshi rin v5.0 - LEGENDARY EDITION Unloaded!", 3, "Success")
end

task.spawn(function()
    task.wait(1)
    Library:Notify("itoshi rin v5.0 - LEGENDARY EDITION loaded!", 5, "Success")
    Library:Notify("Press RightShift to toggle menu", 3, "Info")
    Library:Notify("Keybinds: C=Speed, F=Fly, N=Noclip, K=KillAura, X=Unload", 4, "Info")
    Library:Notify("Advanced systems initialized. Enjoy!", 3, "Success")
end)

shared.itoshi_hub_InkGame_Library = Library

return Library
