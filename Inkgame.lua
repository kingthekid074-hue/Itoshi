if not getgenv().shared then
    getgenv().shared = {}
end

if not getgenv().itoshi_hub_loaded then
    getgenv().itoshi_hub_loaded = true
else
    local suc = pcall(function()
        shared.itoshi_hub_InkGame_Library:Unload()
    end)
    shared.LoadTries = shared.LoadTries or 0
    if not suc and shared.LoadTries < 3 then
        shared.LoadTries = shared.LoadTries + 1
        return 
    end
end
shared.LoadTries = 0

local Library, ThemeManager, SaveManager, Options, Toggles

local repo = "https://raw.githubusercontent.com/mstudio45/Obsidian/main/"
Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

Options = Library.Options
Toggles = Library.Toggles

shared.itoshi_hub_InkGame_Library = Library

local Window = Library:CreateWindow({
    Title = "Itoshi Hub - Ink Game",
    Footer = "Itoshi Hub",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = false,
    TabPadding = 2,
    MenuFadeTime = 0
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    AutoFarm = Window:AddTab("Auto Farm", "robot"),
    Dalgona = Window:AddTab("Dalgona", "circle"),
    Other = Window:AddTab("Other", "settings"),
    Misc = Window:AddTab("Misc", "folder"),
    Visuals = Window:AddTab("Visuals", "eye"),
    ["UI Settings"] = Window:AddTab("UI Settings", "sliders-horizontal"),
}

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

local Services = setmetatable({}, {
    __index = function(self, key)
        local suc, service = pcall(game.GetService, game, key)
        if suc and service then
            self[key] = service
            return service
        else
            warn(`[Services] Warning: "{key}" is not a valid Roblox service.`)
            return nil
        end
    end
})

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

local Players = Services.Players
local Lighting = Services.Lighting
local RunService = Services.RunService
local HttpService = Services.HttpService
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local ReplicatedStorage = Services.ReplicatedStorage
local ProximityPromptService = Services.ProximityPromptService

local lplr = Players.LocalPlayer
local localPlayer = lplr

local camera = workspace.CurrentCamera

type ESP = {
    Color: Color3,
    IsEntity: boolean,
    Object: Instance,
    Offset: Vector3,
    Text: string,
    TextParent: Instance,
    Type: string,
}

local Script = {
    GameStateChanged = Instance.new("BindableEvent"),
    GameState = "unknown",
    Services = Services,
    Maid = Maid.new(),
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

local States = {}

function Script.Functions.Alert(message: string, time_obj: number)
    Library:Notify(message, time_obj or 5)

    local sound = Instance.new("Sound", workspace) do
        sound.SoundId = "rbxassetid://4590662766"
        sound.Volume = 2
        sound.PlayOnRemove = true
        sound:Destroy()
    end
end

function Script.Functions.Warn(message: string)
    warn("Itoshi Hub WARN", message)
end

function Script.Functions.ESP(args: ESP)
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
        ESPManager.Humanoid = Instance.new("Humanoid", ESPManager.Object)
        ESPManager.Object.PrimaryPart.Transparency = 0.99
    end

    local highlight = Instance.new("Highlight") do
        highlight.Adornee = ESPManager.Object
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = ESPManager.Color
        highlight.FillTransparency = Options and Options.ESPFillTransparency and Options.ESPFillTransparency.Value or 0.5
        highlight.OutlineColor = ESPManager.Color
        highlight.OutlineTransparency = Options and Options.ESPOutlineTransparency and Options.ESPOutlineTransparency.Value or 0
        highlight.Enabled = Toggles and Toggles.ESPHighlight and Toggles.ESPHighlight.Value or false
        highlight.Parent = ESPManager.Object
    end

    table.insert(ESPManager.Highlights, highlight)
    

    local billboardGui = Instance.new("BillboardGui") do
        billboardGui.Adornee = ESPManager.TextParent or ESPManager.Object
        billboardGui.AlwaysOnTop = true
        billboardGui.ClipsDescendants = false
        billboardGui.Size = UDim2.new(0, 1, 0, 1)
        billboardGui.StudsOffset = ESPManager.Offset
        billboardGui.Parent = ESPManager.TextParent or ESPManager.Object
    end

    local textLabel = Instance.new("TextLabel") do
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.Oswald
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Text = ESPManager.Text
        textLabel.TextColor3 = ESPManager.Color
        textLabel.TextSize = Options and Options.ESPTextSize and Options.ESPTextSize.Value or 14
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.TextStrokeTransparency = 0.75
        textLabel.Parent = billboardGui
    end

    function ESPManager.SetColor(newColor: Color3)
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
                ESPManager.Object.PrimaryPart.Transparency = ESPManager.Object.PrimaryPart:GetAttribute("Transparency")
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
        for _, highlight in pairs(ESPManager.Highlights) do
            if Toggles and Toggles.ESPHighlight then
                highlight.Enabled = Toggles.ESPHighlight.Value
            end
            if Options and Options.ESPFillTransparency then
                highlight.FillTransparency = Options.ESPFillTransparency.Value
            end
            if Options and Options.ESPOutlineTransparency then
                highlight.OutlineTransparency = Options.ESPOutlineTransparency.Value
            end
        end
        if Options and Options.ESPTextSize then
            textLabel.TextSize = Options.ESPTextSize.Value
        end

        if Toggles and Toggles.ESPDistance and Toggles.ESPDistance.Value then
            textLabel.Text = string.format("%s\n[%s]", ESPManager.Text, math.floor(Script.Functions.DistanceFromCharacter(ESPManager.Object)))
        else
            textLabel.Text = ESPManager.Text
        end
    end)

    function ESPManager.GiveSignal(signal)
        table.insert(ESPManager.Connections, signal)
    end

    Script.ESPTable[ESPManager.Type][tableIndex] = ESPManager
    return ESPManager
end

function Script.Functions.SeekerESP(player : Player)
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
            Text = "HUNTER" .. player.Name .. "",
            Color = Color3.fromRGB(255, 0, 0),
            Offset = Vector3.new(0, 5, 0),
            Type = "Seeker"
        })
    end
end

function Script.Functions.HiderESP(player : Player)
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

function Script.Functions.PlayerESP(player: Player)
    if not (player.Character and player.Character.PrimaryPart and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0) then return end

    if not player.Character:FindFirstChild("PlayerChams") then
        local hl = Instance.new("Highlight")
        hl.Name = "PlayerChams"
        hl.Adornee = player.Character
        hl.FillColor = Options and Options.PlayerEspColor and Options.PlayerEspColor.Value or Color3.fromRGB(255, 255, 255)
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
        Color = Options and Options.PlayerEspColor and Options.PlayerEspColor.Value or Color3.fromRGB(255, 255, 255)
    })

    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            playerEsp.Text = getInfoText()
            
            local hl = player.Character:FindFirstChild("PlayerChams")
            if hl and Options and Options.PlayerEspColor then
                hl.FillColor = Options.PlayerEspColor.Value
            end
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
        warn("[Itoshi Hub SafeRequire]: Failure loading "..tostring(module).." ("..tostring(err)..")")
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
local EffectsModule
Script.Functions.OnLoad = function()
    EffectsModule = EffectsModule or Script.Functions.SafeRequire(ReplicatedStorage.Modules.Effects) or {
        AnnouncementTween = function(args)
            Script.Functions.Alert(args.AnnouncementDisplayText, args.DisplayTime)
        end
    }

    Script.Functions.EffectsNotification("Itoshi Hub Loaded Successfully", 5)
    Library:Notify("Welcome to Itoshi Hub!", 5)
end

function Script.Functions.EffectsNotification(text, dur)
    EffectsModule = EffectsModule or Script.Functions.SafeRequire(ReplicatedStorage.Modules.Effects) or {
        AnnouncementTween = function(args)
            Script.Functions.Alert(args.AnnouncementDisplayText, args.DisplayTime)
        end
    }

    dur = dur or 5
    text = tostring(text)

    EffectsModule.AnnouncementTween({
        AnnouncementOneLine = true,
        FasterTween = true,
        DisplayTime = dur,
        AnnouncementDisplayText = text
    })
end

Script.Functions.BypassRagdoll = function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character
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

Script.Functions.BypassDalgonaGame = function()
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character and Character:FindFirstChild("Humanoid")
    local PlayerGui = LocalPlayer.PlayerGui
    local DebrisBD = LocalPlayer:WaitForChild("DebrisBD")
    local CurrentCamera = workspace.CurrentCamera
    local EffectsFolder = workspace:FindFirstChild("Effects")
    local ImpactFrames = PlayerGui:FindFirstChild("ImpactFrames")

    local originalCameraType = CurrentCamera.CameraType
    local originalCameraSubject = CurrentCamera.CameraSubject
    local originalFieldOfView = CurrentCamera.FieldOfView

    local shapeModel, outlineModel, pickModel, redDotModel
    if EffectsFolder then
        for _, obj in pairs(EffectsFolder:GetChildren()) do
            if obj:IsA("Model") and obj.Name:match("Outline$") then
                outlineModel = obj
            elseif obj:IsA("Model") and not obj.Name:match("Outline$") and obj.Name ~= "Pick" and obj.Name ~= "RedDot" then
                shapeModel = obj
            elseif obj.Name == "Pick" then
                pickModel = obj
            elseif obj.Name == "RedDot" then
                redDotModel = obj
            end
        end
    end

    local progressBar = ImpactFrames and ImpactFrames:FindFirstChild("ProgressBar")

    local pickViewportModel
    if ImpactFrames then
        for _, obj in pairs(ImpactFrames:GetChildren()) do
            if obj:IsA("ViewportFrame") and obj:FindFirstChild("PickModel") then
                pickViewportModel = obj.PickModel
                break
            end
        end
    end

    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local DalgonaRemote = Remotes:WaitForChild("DALGONATEMPREMPTE")
    
    local cameraOverrideActive = true
    local cameraOverrideConnection
    
    task.spawn(function()
        SharedFunctions.CreateFolder(LocalPlayer, "RecentGameStartedMessage", 0.01)

        if shapeModel and shapeModel:FindFirstChild("shape") then
            TweenService:Create(shapeModel.shape, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                Position = shapeModel.shape.Position + Vector3.new(0, 0.5, 0)
            }):Play()
        end

        if shapeModel then
            for _, part in pairs(shapeModel:GetChildren()) do
                if part.Name == "DalgonaClickPart" and part:IsA("BasePart") then
                    TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                        Transparency = 1
                    }):Play()
                end
            end
        end

        if pickModel and pickModel.Parent then
            TweenService:Create(pickModel, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                Transparency = 1
            }):Play()
        end
        if redDotModel and redDotModel.Parent then
            TweenService:Create(redDotModel, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                Transparency = 1
            }):Play()
        end

        if pickViewportModel then
            for _, part in pairs(pickViewportModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                        Transparency = 1
                    }):Play()
                end
            end
        end

        if HumanoidRootPart then
            TweenService:Create(CurrentCamera, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                CFrame = HumanoidRootPart.CFrame * CFrame.new(0.0841674805, 8.45438766, 6.69675446, 0.999918401, -0.00898250192, 0.00907994807, 3.31699681e-08, 0.710912943, 0.703280032, -0.0127722733, -0.703222632, 0.710854948)
            }):Play()
        end

        SharedFunctions.Invisible(Character, 0, true)

        DalgonaRemote:FireServer({
            Success = true
        })

        task.wait(2)

        for _, obj in pairs({shapeModel, outlineModel, pickModel, redDotModel, progressBar}) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end

        UserInputService.MouseIconEnabled = true
        if PlayerGui:FindFirstChild("Hotbar") and PlayerGui.Hotbar:FindFirstChild("Backpack") then
            TweenService:Create(PlayerGui.Hotbar.Backpack, TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
        end
        if progressBar then
            DebrisBD:Fire(progressBar, 2)
            TweenService:Create(progressBar, TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
                Position = UDim2.new(progressBar.Position.X.Scale, 0, progressBar.Position.Y.Scale + 1, 0)
            }):Play()
        end

        task.wait(0.5)
        cameraOverrideActive = false
        
        CurrentCamera.CameraType = Enum.CameraType.Custom
        if Humanoid then
            CurrentCamera.CameraSubject = Humanoid
        end
        CurrentCamera.FieldOfView = originalFieldOfView or 70
        
        camera = CurrentCamera
    end)

    cameraOverrideConnection = RunService.RenderStepped:Connect(function()
        if not cameraOverrideActive then
            cameraOverrideConnection:Disconnect()
            return
        end
        
        if CurrentCamera.CameraType == Enum.CameraType.Scriptable then
            CurrentCamera.CameraType = Enum.CameraType.Custom
        end
        
        if Humanoid and CurrentCamera.CameraSubject ~= Humanoid then
            CurrentCamera.CameraSubject = Humanoid
        end
    end)

    return function()
        cameraOverrideActive = false
        if cameraOverrideConnection then
            cameraOverrideConnection:Disconnect()
        end
        
        for _, obj in pairs({shapeModel, outlineModel, pickModel, redDotModel, progressBar}) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end

        UserInputService.MouseIconEnabled = true
        CurrentCamera.CameraType = Enum.CameraType.Custom
        if Humanoid then
            CurrentCamera.CameraSubject = Humanoid
        end
        CurrentCamera.FieldOfView = originalFieldOfView or 70
        
        camera = CurrentCamera
    end
end
Script.Functions.GetRootPart = function()
    if not lplr.Character then return nil end
    local rp = lplr.Character:FindFirstChild("HumanoidRootPart")
    return rp
end
local KillauraDebug = false
local tools = {"Fork", "Bottle", "Knife", "Power Hold", "Push"}
Script.Functions.GetFork = function()
    local res
    for _, index in pairs(tools) do
        local tool = lplr.Character:FindFirstChild(index) or lplr:FindFirstChild("Backpack") and lplr.Backpack:FindFirstChild(index)
        if tool then
            if KillauraDebug then print("[Itoshi Hub Killaura Debug] Found tool:", tool.Name, "in", tool.Parent and tool.Parent.Name or "nil") end
            res = tool
            break
        end
    end
    if not res then
        if KillauraDebug then print("[Itoshi Hub Killaura Debug] No valid tool found!") end
    end
    return res
end

function Script.Functions.GetDalgonaRemote()
    return game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):FindFirstChild("DALGONATEMPREMPTE")
end

function Script.Functions.DistanceFromCharacter(position: Instance | Vector3)
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

function Script.Functions.SetupOtherPlayerConnection(player: Player)
    if player.Character then
        if Toggles and Toggles.PlayerESP and Toggles.PlayerESP.Value then
            Script.Functions.PlayerESP(player)
        end
    end

    if Library then
        Library:GiveSignal(player.CharacterAdded:Connect(function(newCharacter)
            task.delay(0.1, function()
                if Toggles and Toggles.PlayerESP and Toggles.PlayerESP.Value then
                    Script.Functions.PlayerESP(player)
                end
            end)
        end))
    end
end

function Script.Functions.DisableAntiFling()
    if Toggles and Toggles.AntiFlingToggle and Toggles.AntiFlingToggle.Value then
        Toggles.AntiFlingToggle:SetValue(false)
    end
end

function Script.Functions.EnableAntiFling()
    if Toggles and Toggles.AntiFlingToggle and not Toggles.AntiFlingToggle.Value then
        Toggles.AntiFlingToggle:SetValue(true)
    end
end

function Script.Functions.WinRLGL()
    if not lplr.Character then return end
    local call = Toggles and Toggles.AntiFlingToggle and Toggles.AntiFlingToggle.Value
    Script.Functions.DisableAntiFling()
    lplr.Character:PivotTo(CFrame.new(Vector3.new(-100.8, 1030, 115)))
    if call then
        task.delay(0.5, Script.Functions.EnableAntiFling)
    end
end

function Script.Functions.WinJumpRope()
    if not lplr.Character then return end
    local call = Toggles and Toggles.AntiFlingToggle and Toggles.AntiFlingToggle.Value
    Script.Functions.DisableAntiFling()
    lplr.Character:PivotTo(CFrame.new(Vector3.new(732.4, 197.14, 931.1644)))
    if call then
        task.delay(0.5, Script.Functions.EnableAntiFling)
    end
end

function Script.Functions.TeleportSafe()
    if not lplr.Character then return end
    pcall(function()
        Script.Temp.OldLocation = CFrame.new(lplr.Character.HumanoidRootPart.Position)
    end)
    local call = Toggles and Toggles.AntiFlingToggle and Toggles.AntiFlingToggle.Value
    Script.Functions.DisableAntiFling()
    lplr.Character:PivotTo(CFrame.new(Vector3.new(-108, 329.1, 462.1)))
    if call then
        task.delay(0.5, Script.Functions.EnableAntiFling)
    end
end

function Script.Functions.TeleportBackFromSafe()
    local OldLocation = Script.Temp.OldLocation
    if not OldLocation then
        warn("[Itoshi Hub Invalid location]")
        return
    end
    if not lplr.Character then return end
    local call = Toggles and Toggles.AntiFlingToggle and Toggles.AntiFlingToggle.Value
    Script.Functions.DisableAntiFling()
    lplr.Character:PivotTo(OldLocation)
    if call then
        task.delay(0.5, Script.Functions.EnableAntiFling)
    end
end

function Script.Functions.TeleportSafeHidingSpot()
    if not lplr.Character then return end
    local call = Toggles and Toggles.AntiFlingToggle and Toggles.AntiFlingToggle.Value
    Script.Functions.DisableAntiFling()
    lplr.Character:PivotTo(CFrame.new(Vector3.new(229.9, 1005.3, 169.4)))
    if call then
        task.delay(0.5, Script.Functions.EnableAntiFling)
    end
end

function Script.Functions.WinGlassBridge()
    if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = lplr.Character.HumanoidRootPart
    local state = Toggles and Toggles.AntiFlingToggle and Toggles.AntiFlingToggle.Value
    if state then
        Script.Functions.DisableAntiFling()
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    lplr.Character:PivotTo(CFrame.new(-203.9, 525.7, -1534.3485))
    if state then
        task.delay(0.2, Script.Functions.EnableAntiFling)
    end
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

    local function doDalgona()
    if not autoFarmActive then return end
    if not debug or not debug.getregistry or not debug.setupvalue then return end

    local dalgonaScript = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Games"):WaitForChild("DalgonaClient")
    
    for _, fn in ipairs(debug.getregistry()) do
        if typeof(fn) == "function" and islclosure(fn) then
            local info = debug.getinfo(fn)
            if info and info.nups == 73 then
                pcall(function()
                    debug.setupvalue(fn, 31, 9e9)
                end)
                break
            end
        end
    end
end
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
            doDalgona()
        end
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        autoFarmActive = not autoFarmActive
        toggleBtn.Text = "Auto Farm: " .. (autoFarmActive and "ON" or "OFF")
        toggleBtn.BackgroundColor3 = autoFarmActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
        
        if autoFarmActive then
            doDalgona()
            Library:Notify("Auto Farm enabled!", 3)
        else
            Library:Notify("Auto Farm disabled!", 3)
        end
    end)

    return gui
end

-- Auto Farm Tab
local AutoFarmGroup = Tabs.AutoFarm:AddLeftGroupbox("Auto Farm Settings", "robot") do
    AutoFarmGroup:AddToggle("AutoFarmToggle", {
        Text = "Enable Auto Farm",
        Default = false
    }):AddKeyPicker("AutoFarmKey", {
        Mode = "Toggle",
        Default = "F",
        Text = "Auto Farm Toggle",
        SyncToggleState = true
    })
    
    AutoFarmGroup:AddLabel("Minigame Positions")
    AutoFarmGroup:AddLabel("RLGL: -45, 1023.3, 95.1")
    AutoFarmGroup:AddLabel("Lights Out: 195.6, 122.7, -93.1")
    AutoFarmGroup:AddLabel("Glass Bridge: -206.4, 520.7, -1534.0")
    
    AutoFarmGroup:AddLabel("Auto Farm Tools")
    AutoFarmGroup:AddLabel("Pocket Sand → RLGL")
    AutoFarmGroup:AddLabel("Fork/Soda/Bottle/Kimbap → Lights Out")
    
    AutoFarmGroup:AddButton("Create Auto Farm GUI", function()
        createAutoFarmGUI()
        Library:Notify("Auto Farm GUI created!", 3)
    end)
    
    Toggles.AutoFarmToggle:OnChanged(function(value)
        autoFarmActive = value
        if value then
            Library:Notify("Auto Farm enabled!", 3)
            local char = lplr.Character
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        checkTool(tool.Name)
                    end
                end
            end
            for _, tool in ipairs(lplr.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    checkTool(tool.Name)
                end
            end
        else
            Library:Notify("Auto Farm disabled!", 3)
        end
    end)
end

-- Dalgona Tab
local DalgonaGroup = Tabs.Dalgona:AddLeftGroupbox("Dalgona Features", "circle") do
    DalgonaGroup:AddButton("Complete Dalgona Game", function()
        task.spawn(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            if not ReplicatedStorage then
                Library:Notify("ReplicatedStorage not found!", 5)
                return
            end
            local DalgonaClientModule = ReplicatedStorage:FindFirstChild("Modules") and
                                        ReplicatedStorage.Modules:FindFirstChild("Games") and
                                        ReplicatedStorage.Modules.Games:FindFirstChild("DalgonaClient")
            if not DalgonaClientModule then
                Library:Notify("DalgonaClient module not found!", 5)
                return
            end
            
            local success = false
            for _, func in pairs(debug.getregistry()) do
                if typeof(func) == "function" and islclosure(func) then
                    local info = debug.getinfo(func)
                    if info and info.nups == 73 then
                        local suc, err = pcall(function()
                            debug.setupvalue(func, 31, 9e9)
                        end)
                        if suc then
                            success = true
                            break
                        end
                    end
                end
            end
            
            if success then
                Library:Notify("Dalgona completed successfully!", 5)
            else
                Library:Notify("Failed to complete Dalgona!", 5)
            end
        end)
    end)
    
    DalgonaGroup:AddButton("Free Lighter", function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        LocalPlayer:SetAttribute("HasLighter", true)
        Library:Notify("Lighter unlocked!", 5)
    end)
    
    DalgonaGroup:AddToggle("UnbreakableCookie", {
        Text = "Unbreakable Cookie",
        Default = false
    })
end

-- Logic Auto Mingle
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local ImpactFrames = PlayerGui:WaitForChild("ImpactFrames", 10)
    local HBGQTE = require(ReplicatedStorage.Modules.HBGQTE)

    if ImpactFrames then
        ImpactFrames.ChildAdded:Connect(function(child)
            if child.Name == "OuterRingTemplate" then
                task.spawn(function()
                    local inner = ImpactFrames:WaitForChild("InnerTemplate", 1)
                    if inner then
                        local successData = {
                            ["Inner"] = inner,
                            ["Outer"] = child,
                            ["Duration"] = 0.05,
                            ["StartedAt"] = tick()
                        }
                        pcall(function()
                            HBGQTE.Pressed(false, successData)
                        end)
                    end
                end)
            end
        end)
    end
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Itoshi Hub",
        Text = "Auto QTE Enabled",
        Duration = 3
    })
    
    Library:Notify("Auto QTE activated!", 3)
end)

local MAIN_ESP_META = {
    {
        metaName = "PlayerESP",
        text = "Player",
        default = false,
        color = {
            metaName = "PlayerEspColor",
            default = Color3.fromRGB(255, 255, 255)
        },
        func = function()
            for _, player in pairs(Players:GetPlayers()) do
                if player == localPlayer then continue end
                Script.Functions.PlayerESP(player)
            end
        end
    },
    {
        metaName = "GuardESP",
        text = "Guard",
        default = false,
        color = {
            metaName = "GuardEspColor",
            default = Color3.fromRGB(200, 100, 200)
        },
        func = function()
            local live = workspace:FindFirstChild("Live")
            if not live then return end
            for _, descendant in pairs(live:GetChildren()) do
                if descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == "Live" and descendant:FindFirstChild("TypeOfGuard") then
                    if string.find(descendant.Name, "RebelGuard") or string.find(descendant.Name, "FinalRebel") or string.find(descendant.Name, "HallwayGuard") or string.find(string.lower(descendant.Name), "aggro") then
                        Script.Functions.GuardESP(descendant)
                    end
                end
            end
        end,
        descendantcheck = function(descendant)
            if descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == "Live" and descendant:FindFirstChild("TypeOfGuard") then
                if string.find(descendant.Name, "RebelGuard") or string.find(descendant.Name, "FinalRebel") or string.find(descendant.Name, "HallwayGuard") or string.find(string.lower(descendant.Name), "aggro") then
                    Script.Functions.GuardESP(descendant)
                end
            end
        end
    }
}

local ESP_META = {
    {
        metaName = "HiderESP",
        text = "Hider",
        default = false,
        color = {
            metaName = "HiderEspColor",
            default = Color3.fromRGB(0, 255, 0)
        },
        checkType = "player"
    },
    {
        metaName = "SeekerESP",
        text = "Seeker",
        default = false,
        color = {
            metaName = "SeekerEspColor",
            default = Color3.fromRGB(255, 0, 0)
        },
        checktype = "player"
    },
    {
        metaName = "KeyESP",
        text = "Key",
        default = false,
        color = {
            metaName = "KeyEspColor",
            default = Color3.fromRGB(255, 255, 0)
        },
        checktype = "key",
        descendantcheck = function(descendant)
            local hideAndSeekMap = workspace:FindFirstChild("Effects")
            if not hideAndSeekMap then return end
            if descendant:IsA("Model") and descendant.Parent and string.find(descendant.Name, "DroppedKey") then
                Script.Functions.KeyESP(descendant)
            end
        end
    },
    {
        metaName = "DoorESP",
        text = "Door",
        default = false,
        color = {
            metaName = "DoorEspColor",
            default = Color3.fromRGB(0, 128, 255)
        },
        checktype = "door",
        descendantcheck = function(descendant)
            local hideAndSeekMap = workspace:FindFirstChild("HideAndSeekMap")
            if not hideAndSeekMap then return end
            if descendant:IsA("Model") and descendant.Name == "FullDoorAnimated" and descendant.Parent and descendant.Parent.Parent and descendant.Parent.Parent.Name == "NEWFIXEDDOORS" then
                Script.Functions.DoorESP(descendant)
            end
        end
    },
    {
        metaName = "EscapeDoorESP",
        text = "Escape Door",
        default = false,
        color = {
            metaName = "EscapeDoorEspColor",
            default = Color3.fromRGB(255, 0, 255)
        },
        checktype = "escapedoor",
        descendantcheck = function(descendant)
            local hideAndSeekMap = workspace:FindFirstChild("HideAndSeekMap")
            if not hideAndSeekMap then return end
            if descendant:IsA("Model") and descendant.Name == "EXITDOOR" and descendant.Parent ~= nil and descendant:GetAttribute("CANESCAPE") then
                Script.Functions.EscapeDoorESP(descendant)
            end
        end
    },
}

local MainESPGroup = Tabs.Visuals:AddLeftGroupbox("Main ESP", "eye") do
    for _, meta in pairs(MAIN_ESP_META) do
        MainESPGroup:AddToggle(meta.metaName, {
            Text = meta.text,
            Default = meta.default
        }):AddColorPicker(meta.color.metaName, {
            Default = meta.color.default
        })

        Toggles[meta.metaName]:OnChanged(function(call)
            if call then
                if meta.func then
                    meta.func(call)
                end
            else
                for _, esp in pairs(Script.ESPTable[meta.text]) do
                    esp.Destroy()
                end
            end
        end)

        if meta.descendantcheck then
            Library:GiveSignal(workspace.DescendantAdded:Connect(function(descendant)
                if not Toggles[meta.metaName].Value then return end
                meta.descendantcheck(descendant)
            end))
        end
    end
end

local ESPGroupBox = Tabs.Visuals:AddLeftGroupbox("Hide and Seek ESP", "search") do
    for _, meta in pairs(ESP_META) do
        ESPGroupBox:AddToggle(meta.metaName, {
            Text = meta.text,
            Default = meta.default
        }):AddColorPicker(meta.color.metaName, {
            Default = meta.color.default
        })

        Toggles[meta.metaName]:OnChanged(function(call)
            if call then
                if not string.find(Script.GameState, "HideAndSeek") then return end
                if meta.checktype == "player" then
                    for _, player in pairs(Players:GetPlayers()) do
                        Script.Functions[meta.metaName](player)
                    end
                elseif meta.checktype == "key" then
                    local hideAndSeekMap = workspace:FindFirstChild("Effects")
                    if hideAndSeekMap then
                        local keysFolder = hideAndSeekMap
                        if keysFolder then
                            for _, key in pairs(keysFolder:GetChildren()) do
                                Script.Functions.KeyESP(key)
                            end
                        end
                    end
                elseif meta.checktype == "door" then
                    local hideAndSeekMap = workspace:FindFirstChild("HideAndSeekMap")
                    if hideAndSeekMap then
                        local newFixedDoors = hideAndSeekMap:FindFirstChild("NEWFIXEDDOORS")
                        if newFixedDoors then
                            for _, floor in pairs(newFixedDoors:GetChildren()) do
                                if floor.Name:match("^Floor") then
                                    for _, door in pairs(floor:GetChildren()) do
                                        Script.Functions.DoorESP(door)
                                    end
                                end
                            end
                        end
                    end
                elseif meta.checktype == "escapedoor" then
                    local hideAndSeekMap = workspace:FindFirstChild("HideAndSeekMap")
                    if hideAndSeekMap then
                        for _, descendant in ipairs(hideAndSeekMap:GetDescendants()) do
                            if descendant:IsA("Model") and descendant.Name == "EXITDOOR" and descendant.Parent ~= nil and descendant:GetAttribute("CANESCAPE") then
                                Script.Functions.EscapeDoorESP(descendant)
                            end
                        end
                    end
                end
            else
                Script.ESPTable[meta.text] = Script.ESPTable[meta.text] or {}
                for _, esp in pairs(Script.ESPTable[meta.text]) do
                    esp.Destroy()
                end
            end
        end)

        Options[meta.color.metaName]:OnChanged(function(value)
            Script.ESPTable[meta.text] = Script.ESPTable[meta.text] or {}
            for _, esp in pairs(Script.ESPTable[meta.text]) do
                esp.SetColor(value)
            end
        end)

        if meta.descendantcheck then
            Library:GiveSignal(workspace.DescendantAdded:Connect(function(descendant)
                if not string.find(Script.GameState, "HideAndSeek") then return end
                if not Toggles[meta.metaName].Value then return end
                meta.descendantcheck(descendant)
            end))
        end
    end
end

local ESPSettingsGroupBox = Tabs.Visuals:AddRightGroupbox("ESP Settings", "sliders") do
    ESPSettingsGroupBox:AddToggle("ESPHighlight", {
        Text = "Enable Highlight",
        Default = true,
    })

    ESPSettingsGroupBox:AddToggle("ESPDistance", {
        Text = "Show Distance",
        Default = true,
    })

    ESPSettingsGroupBox:AddSlider("ESPFillTransparency", {
        Text = "Fill Transparency",
        Default = 0.75,
        Min = 0,
        Max = 1,
        Rounding = 2
    })

    ESPSettingsGroupBox:AddSlider("ESPOutlineTransparency", {
        Text = "Outline Transparency",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2
    })

    ESPSettingsGroupBox:AddSlider("ESPTextSize", {
        Text = "Text Size",
        Default = 22,
        Min = 16,
        Max = 26,
        Rounding = 0
    })
end

local FunGroupBox = Tabs.Main:AddLeftGroupbox("Fun", "zap") do
    FunGroupBox:AddToggle("InkGameAutowin", {
        Text = "Autowin",
        Default = false
    })

    Toggles.InkGameAutowin:OnChanged(function(call)
        if call then
            Script.Functions.Alert("Autowin enabled!", 3)
            task.spawn(function()
                Script.Functions.EffectsNotification("Autowin enabled!", 5)
            end)
            Script.Functions.HandleAutowin()
        else
            Script.Functions.Alert("Autowin disabled!", 3)
        end
    end)

    FunGroupBox:AddToggle("FlingAuraToggle", {
        Text = "Fling",
        Default = false
    })
    
    FunGroupBox:AddToggle("AntiFlingToggle", {
        Text = "Anti Fling",
        Default = false
    })
    
    Toggles.AntiFlingToggle:OnChanged(function(call)
        if call then
            if not hookmetamethod then
                Script.Functions.Alert("Your exploit does not support this", 3)
                Toggles.AntiFlingToggle:SetValue(false)
                return
            end
            Script.Temp.PauseAntiFling = nil
            Script.Functions.Alert("Anti Fling Enabled", 3)
            Script.Temp.AntiFlingActive = true
            Script.Temp.AntiFlingLoop = task.spawn(function()
                local lastSafeCFrame = nil
                while Script.Temp.AntiFlingActive and not Library.Unloaded do
                    if Script.Temp.PauseAntiFling then return end
                    local character = lplr.Character
                    local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
                    if root then
                        local gs = Script.GameState
                        local isActiveGame = gs and gs ~= "" and States[gs] ~= nil
                        for _, part in pairs(character:GetDescendants()) do
                            if part:IsA("BodyMover") or part:IsA("BodyVelocity") or part:IsA("BodyGyro") or part:IsA("BodyThrust") or part:IsA("BodyAngularVelocity") then
                                part:Destroy()
                            end
                        end
                        local maxVel = 100
                        local vel = root.Velocity
                        if vel.Magnitude > maxVel then
                            root.Velocity = Vector3.new(
                                math.clamp(vel.X, -maxVel, maxVel),
                                math.clamp(vel.Y, -maxVel, maxVel),
                                math.clamp(vel.Z, -maxVel, maxVel)
                            )
                        end
                        if not lastSafeCFrame or (root.Position - lastSafeCFrame.Position).Magnitude < 20 then
                            lastSafeCFrame = root.CFrame
                        elseif isActiveGame and (root.Position - lastSafeCFrame.Position).Magnitude > 50 then
                            root.CFrame = lastSafeCFrame
                            root.Velocity = Vector3.zero
                        end
                    end
                    task.wait(0.05)
                end
            end)
        else
            Script.Functions.Alert("Anti Fling Disabled", 3)
            Script.Temp.AntiFlingActive = false
            if Script.Temp.AntiFlingLoop then
                task.cancel(Script.Temp.AntiFlingLoop)
            end
        end
    end)

    FunGroupBox:AddToggle("GhostMode", {
        Text = "Ghost Mode",
        Default = false
    })

    Toggles.GhostMode:OnChanged(function(enabled)
        if enabled then
            Script.Functions.Alert("Ghost Mode Activated", 3)
            Script.Temp.GhostModeEnabled = true
            
            local function setupGhostAppearance()
                local character = lplr.Character
                if not character then return end
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end
                
                rootPart.Transparency = 0.4
                rootPart.Color = Color3.fromRGB(200, 200, 255)
                rootPart.Material = Enum.Material.Neon
            end

            local function hideCharacterParts()
                local character = lplr.Character
                if not character then return end
                
                for _, child in ipairs(character:GetDescendants()) do
                    if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                        child.LocalTransparencyModifier = 1
                    elseif child:IsA("Decal") then
                        child.Transparency = 1
                    elseif child:IsA("LayerCollector") then
                        child.Enabled = false
                    end
                end
            end

            setupGhostAppearance()
            hideCharacterParts()

            Script.Temp.GhostModeLoop = RunService.Heartbeat:Connect(function()
                if not Script.Temp.GhostModeEnabled then return end
                
                local character = lplr.Character
                if not character then return end
                
                local humanoid = character:FindFirstChild("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not humanoid or not rootPart or humanoid.RigType == Enum.HumanoidRigType.R6 then return end
                
                for _, child in ipairs(character:GetDescendants()) do
                    if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                        child.LocalTransparencyModifier = 1
                    elseif child:IsA("Decal") then
                        child.Transparency = 1
                    elseif child:IsA("LayerCollector") then
                        child.Enabled = false
                    end
                end
                
                local originalCFrame = rootPart.CFrame
                local originalCameraOffset = humanoid.CameraOffset

                local floatingOffset = Vector3.new(0, humanoid.HipHeight + (rootPart.Size.Y / 2) - 0.8, 0)
                rootPart.CFrame = (rootPart.CFrame - floatingOffset) * CFrame.Angles(0, 0, math.rad(180))
                humanoid.CameraOffset = Vector3.new(0, -4.5, 0)
                
                local ghostAnimation = Instance.new("Animation")
                ghostAnimation.AnimationId = "http://www.roblox.com/asset/?id=11360825341"
                local animationTrack = humanoid.Animator:LoadAnimation(ghostAnimation)
                animationTrack.Priority = Enum.AnimationPriority.Action4
                animationTrack:Play()
                animationTrack.TimePosition = 0.15
                animationTrack:AdjustSpeed(0)
                
                RunService.RenderStepped:Wait()
                animationTrack:Stop()
                
                humanoid.CameraOffset = originalCameraOffset
                rootPart.CFrame = originalCFrame
            end)

            Script.Temp.GhostModeRespawn = lplr.CharacterAdded:Connect(function()
                if Script.Temp.GhostModeEnabled then
                    task.wait(0.6)
                    if Toggles.GhostMode.Value then
                        Toggles.GhostMode:SetValue(false)
                        Toggles.GhostMode:SetValue(true)
                    end
                end
            end)
        else
            Script.Functions.Alert("Ghost Mode Deactivated", 3)
            Script.Temp.GhostModeEnabled = false
            
            if Script.Temp.GhostModeLoop then
                Script.Temp.GhostModeLoop:Disconnect()
                Script.Temp.GhostModeLoop = nil
            end
            
            if Script.Temp.GhostModeRespawn then
                Script.Temp.GhostModeRespawn:Disconnect()
                Script.Temp.GhostModeRespawn = nil
            end

            local function restoreCharacterAppearance()
                local character = lplr.Character
                if not character then return end
                
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Transparency = 1
                end
                
                for _, child in ipairs(character:GetDescendants()) do
                    if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                        child.LocalTransparencyModifier = 0
                    elseif child:IsA("Decal") then
                        child.Transparency = 0
                    elseif child:IsA("LayerCollector") then
                        child.Enabled = true
                    end
                end
            end

            restoreCharacterAppearance()
        end
    end)

    FunGroupBox:AddToggle("LightningGodAwakening", {
        Text = "Aura Awakening",
        Default = false
    })

    Toggles.LightningGodAwakening:OnChanged(function(enabled)
        if enabled then
            Script.Functions.Alert("Aura Awakening Enabled", 3)
            Script.Temp.LightningGodEnabled = true
            
            local function executeLightningGodEffect()
                local character = lplr.Character
                if not character then return end
                
                local LightningGodModule = Script.Functions.SafeRequire(ReplicatedStorage.Modules.AbilityEffectsModules.LIGHTNINGGODAWAKENINGCLIENTEFFECTS)
                if not LightningGodModule then
                    Script.Functions.Alert("Aura module not found!", 3)
                    return
                end
                
                local InterruptedFolder = Instance.new("Folder")
                InterruptedFolder.Name = "LightningGodInterrupted"
                InterruptedFolder.Parent = character
                
                local success, err = pcall(function()
                    LightningGodModule({
                        InterruptedFolder = InterruptedFolder,
                        Character = character,
                        ModuleName = "LIGHTNINGGODAWAKENING",
                        TimeLength = 5
                    })
                end)
                
                if not success then
                    Script.Functions.Alert("No aura due: " .. tostring(err), 3)
                else
                    Script.Functions.Alert("Gained aura", 3)
                end
                
                task.delay(6, function()
                    if InterruptedFolder and InterruptedFolder.Parent then
                        InterruptedFolder:Destroy()
                    end
                end)
            end
            
            executeLightningGodEffect()
            
            Script.Temp.LightningGodLoop = task.spawn(function()
                repeat
                    task.wait(10)
                    if Script.Temp.LightningGodEnabled then
                        executeLightningGodEffect()
                    end
                until not Script.Temp.LightningGodEnabled or Library.Unloaded
            end)
            
            Script.Temp.LightningGodRespawn = lplr.CharacterAdded:Connect(function()
                if Script.Temp.LightningGodEnabled then
                    task.wait(1)
                    executeLightningGodEffect()
                end
            end)
        else
            Script.Functions.Alert("Aura Awakening Disabled", 3)
            Script.Temp.LightningGodEnabled = false
            
            if Script.Temp.LightningGodLoop then
                task.cancel(Script.Temp.LightningGodLoop)
                Script.Temp.LightningGodLoop = nil
            end
            
            if Script.Temp.LightningGodRespawn then
                Script.Temp.LightningGodRespawn:Disconnect()
                Script.Temp.LightningGodRespawn = nil
            end
        end
    end)
end

local function getNearestEnemy(maxDist)
    maxDist = maxDist or 15
    local closest, closestDist = nil, math.huge
    local char = lplr.Character
    if not char then return nil end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            if hum.Health > 0 then
                local dist = (root.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if dist < closestDist and dist <= maxDist then
                    closest = player.Character.HumanoidRootPart
                    closestDist = dist
                end
            end
        end
    end
    if closest then
        if KillauraDebug then print("[Itoshi Hub Killaura Debug] Nearest enemy at:", closest.Position, "Distance:", closestDist) end
    else
        if KillauraDebug then print("[Itoshi Hub Killaura Debug] No enemy in range.") end
    end
    return closest
end

Script.Functions.FireForkRemote = function(targetCFrame)
    local fork = Script.Functions.GetFork()
    if not fork then if KillauraDebug then print("[Itoshi Hub Killaura Debug] FireForkRemote: No tool to use!") end return end

    if fork.Parent.Name == "Backpack" then
        if KillauraDebug then print("[Itoshi Hub Killaura Debug] Equipping tool from backpack:", fork.Name) end
        lplr.Character.Humanoid:EquipTool(fork)
    else
        if KillauraDebug then print("[Itoshi Hub Killaura Debug] Tool already equipped:", fork.Name) end
    end

    fork = Script.Functions.GetFork()
    if KillauraDebug then print("[Itoshi Hub Killaura Debug] Using tool:", fork and fork.Name or "nil") end
    if not fork then if KillauraDebug then print("[Itoshi Hub Killaura Debug] FireForkRemote: Tool missing after equip!") end return end

    if KillauraDebug then print("[Itoshi Hub Killaura Debug] Firing UsedTool remote (1st call)") end
    local args = {
        "UsingMoveCustom",
        fork,
        nil,
        {
            Clicked = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UsedTool"):FireServer(unpack(args))
    if KillauraDebug then print("[Itoshi Hub Killaura Debug] Firing UsedTool remote (2nd call)") end
    local args2 = {
        "UsingMoveCustom",
        fork,
        true,
        {
            Clicked = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UsedTool"):FireServer(unpack(args2))
end

Script.Functions.JoinDiscordServer = function()
    local sInvite = "blank"
    
    local function getInviteCode(sInvite)
        for i = #sInvite, 1, -1 do
            local char = sInvite:sub(i, i)
            if char == "/" then
                return sInvite:sub(i + 1, #sInvite)
            end
        end
        return sInvite
    end
    
    local function getInviteData(sInvite)
        local success, result = pcall(function()
            return HttpService:JSONDecode(request({
                Url = "https://ptb.discord.com/api/invites/".. getInviteCode(sInvite),
                Method = "GET"
            }).Body)
        end)
        if not success then
            warn("Failed to get invite data:\n".. result)
            return
        end
        return success, result
    end

    local success, result = getInviteData(sInvite)
    if success and result then
        request({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com"
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = {
                    code = result.code
                },
                nonce = HttpService:GenerateGUID(false)
            })
        })
    end
    pcall(function()
        setclipboard("discord.gg/blank")
    end)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Itoshi Hub",
        Text = "Discord link copied to clipboard!",
        Duration = 10,
    })
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

local KillauraGroupBox = Tabs.Main:AddLeftGroupbox("Killaura", "sword") do
    KillauraGroupBox:AddToggle("KillauraInkGame", {
        Text = "Kill aura",
        Default = false
    })

    KillauraGroupBox:AddSlider("KillauraRange", {
        Text = "Kill aura Range",
        Default = 15,
        Min = 1,
        Max = 30,
        Rounding = 1
    })

    KillauraGroupBox:AddToggle("PushAura", {
        Text = "Push Aura",
        Default = false
    }):OnChanged(function(call)
        if call then
            local i = table.find(tools, "Push")
            if not i then
                table.insert(tools, "Push")
            end
            Script.Functions.Alert("Enable Kill aura first to use", 1.5)
        else
            local i = table.find(tools, "Push")
            if i then
                table.remove(tools, i)
            end
        end
    end)

    KillauraGroupBox:AddToggle("KillauraFaceTarget", {
        Text = "Look at target",
        Default = true
    })

    Toggles.KillauraInkGame:OnChanged(function(call)
    if call then
        pcall(function()
            if Toggles.RedLightGodmode.Value then
                Toggles.RedLightGodmode:SetValue(false)
            end
        end)
        local fork = Script.Functions.GetFork()
        if not fork then
            Script.Functions.Alert("No Weapon ?!", 3)
            Toggles.KillauraInkGame:SetValue(false)
            return
        end
        task.spawn(function()
            while Toggles.KillauraInkGame.Value and not Library.Unloaded do
                if Script.GameState == "RedLightGreenLight" then 
                    task.wait(1)
                    continue 
                end
                
                local target = getNearestEnemy(Options.KillauraRange and Options.KillauraRange.Value or 15)
                if target then
                    if Toggles.KillauraFaceTarget.Value then
                        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.CFrame = CFrame.new(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z))
                        end
                    end
                    Script.Functions.FireForkRemote()
                    local args = {
                        CFrame.new(lplr.Character.HumanoidRootPart.Position)
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("rootCFrame"):FireServer(unpack(args))
                    task.wait(0.15)
                else
                    task.wait(0.1)
                end
            end
        end)
    end
end)
local fireproximityprompt = fireproximityprompt or function(prompt)
    prompt.HoldDuration = 0
    prompt:InputHoldBegin()
end

local GreenLightRedLightGroup = Tabs.Main:AddLeftGroupbox("Red Light / Green Light", "traffic-light") do
    GreenLightRedLightGroup:AddToggle("RedLightGodmode", {
        Text = "Godmode",
        Default = false
    })
    
    local RLGL_OriginalNamecall
    Toggles.RedLightGodmode:OnChanged(function(enabled)
        if enabled then
            if not hookmetamethod then
                Script.Functions.Alert("Your executor does not support this", 3)
                Toggles.RedLightGodmode:SetValue(false)
                return
            end
            local TrafficLightImage = lplr.PlayerGui:FindFirstChild("ImpactFrames") and lplr.PlayerGui.ImpactFrames:FindFirstChild("TrafficLightEmpty")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local lastRootPartCFrame = nil
            local isGreenLight = true
            if TrafficLightImage and ReplicatedStorage:FindFirstChild("Effects") and ReplicatedStorage.Effects:FindFirstChild("Images") and ReplicatedStorage.Effects.Images:FindFirstChild("TrafficLights") and ReplicatedStorage.Effects.Images.TrafficLights:FindFirstChild("GreenLight") then
                isGreenLight = TrafficLightImage.Image == ReplicatedStorage.Effects.Images.TrafficLights.GreenLight.Image
            end
            local function updateState()
                local character = lplr.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root then
                    lastRootPartCFrame = root.CFrame
                end
            end
            updateState()
            local RLGL_Connection = ReplicatedStorage.Remotes.Effects.OnClientEvent:Connect(function(EffectsData)
                if EffectsData.EffectName ~= "TrafficLight" then return end
                isGreenLight = EffectsData.GreenLight == true
                updateState()
            end)
            Script.Temp.RLGL_Connection = RLGL_Connection
            RLGL_OriginalNamecall = RLGL_OriginalNamecall or hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                local method = getnamecallmethod()
                if tostring(self) == "rootCFrame" and method == "FireServer" and Script.GameState == "RedLightGreenLight" then
                    if Toggles.RedLightGodmode.Value and not isGreenLight and lastRootPartCFrame then
                        args[1] = lastRootPartCFrame
                        return RLGL_OriginalNamecall(self, unpack(args))
                    end
                end
                return RLGL_OriginalNamecall(self, ...)
            end)
            Script.Temp.RLGL_OriginalNamecall = RLGL_OriginalNamecall
            Script.Functions.Alert("RLGL Godmode Enabled", 3)
        else
            if Script.Temp.RLGL_Connection then
                pcall(function() Script.Temp.RLGL_Connection:Disconnect() end)
                Script.Temp.RLGL_Connection = nil
            end
            if Script.Temp.RLGL_OriginalNamecall then
                hookmetamethod(game, "__namecall", Script.Temp.RLGL_OriginalNamecall)
                Script.Temp.RLGL_OriginalNamecall = nil
            end
        Script.Functions.Alert("RLGL Godmode Disabled", 3)
        end
    end)
    GreenLightRedLightGroup:AddButton("Complete RLGL", function()
        if not game.Workspace:FindFirstChild("RedLightGreenLight") then
            Script.Functions.Alert("Game didn't start yet")
            return
        end
        Script.Functions.WinRLGL()
    end)
    GreenLightRedLightGroup:AddButton("Remove Injured Walking", function()
        if lplr.Character and lplr.Character:FindFirstChild("InjuredWalking") then
            lplr.Character.InjuredWalking:Destroy()
        end
        Script.Functions.BypassRagdoll()
    end)

    GreenLightRedLightGroup:AddButton("Bring Random Injured Player", function()
        local injuredPlayer, carryPrompt = Script.Functions.FindInjuredPlayer()
        if not injuredPlayer or not carryPrompt then
            Script.Functions.Alert("No one is injured", 2)
            return
        end
        if lplr.Character and injuredPlayer.Character and injuredPlayer.Character.PrimaryPart then
            Script.Temp.PauseAntiFling = true
            if Toggles.RedLightGodmode.Value then
                Toggles.RedLightGodmode:SetValue(false)
            end
            lplr.Character:PivotTo(injuredPlayer.Character:GetPrimaryPartCFrame())
            task.wait(0.2)
            Script.Functions.FireCarryPrompt(injuredPlayer)
            task.wait(0.2)
            Script.Functions.WinRLGL()
            task.wait(0.2)
            Script.Functions.UnCarryPerson()
            task.wait(0.2)
            Script.Temp.PauseAntiFling = false
        end
    end)

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

    GreenLightRedLightGroup:AddDropdown("RLGLInjuredPlayer", {
        Text = "Bring Injured Player",
        Values = {},
        AllowNull = true
    })
    local function RefreshRLGLInjuredDropdown()
        local injured = Script.Functions.GetAllInjuredPlayers()
        local names = {}
        for _, entry in ipairs(injured) do
            table.insert(names, entry.player.DisplayName .. " [" .. entry.player.Name .. "]")
        end
        Options.RLGLInjuredPlayer:SetValues(names)
    end
    Library:GiveSignal(Players.PlayerAdded:Connect(RefreshRLGLInjuredDropdown))
    Library:GiveSignal(Players.PlayerRemoving:Connect(RefreshRLGLInjuredDropdown))
    RefreshRLGLInjuredDropdown()
    Options.RLGLInjuredPlayer:OnChanged(function(val)
        if not val then return end
        local injured = Script.Functions.GetAllInjuredPlayers()
        local selected = nil
        for _, entry in ipairs(injured) do
            local display = entry.player.DisplayName .. " [" .. entry.player.Name .. "]"
            if display == val then
                selected = entry
                break
            end
        end
        if not selected then
            Script.Functions.Alert("No one is injured", 2)
            return
        end
        local injuredPlayer, carryPrompt = selected.player, selected.carryPrompt
        if lplr.Character and injuredPlayer.Character and injuredPlayer.Character.PrimaryPart then
            Script.Temp.PauseAntiFling = true
            if Toggles.RedLightGodmode.Value then
                Toggles.RedLightGodmode:SetValue(false)
            end
            lplr.Character:PivotTo(injuredPlayer.Character:GetPrimaryPartCFrame())
            task.wait(0.2)
            Script.Functions.FireCarryPrompt(injuredPlayer)
            task.wait(0.2)
            Script.Functions.WinRLGL()
            task.wait(0.2)
            Script.Functions.UnCarryPerson()
            task.wait(0.2)
            Script.Temp.PauseAntiFling = false
        end
    end)

    task.spawn(function()
        repeat
            if Script.GameState == "RedLightGreenLight" then
                RefreshRLGLInjuredDropdown()
            else
                Options.RLGLInjuredPlayer:SetValues({})
                Options.RLGLInjuredPlayer:SetValue(nil)
            end
            task.wait(3)
        until Library.Unloaded
    end)

    local bringLoopThread = nil
    GreenLightRedLightGroup:AddToggle("LoopBringPlayers", {
        Text = "Loop Bring Players",
        Default = false
    }):OnChanged(function(val)
        if val then
            bringLoopThread = task.spawn(function()
                while Toggles.LoopBringPlayers.Value and Script.GameState == "RedLightGreenLight" and not Library.Unloaded do
                    local injuredPlayer, carryPrompt = Script.Functions.FindInjuredPlayer()
                    if injuredPlayer and carryPrompt and lplr.Character and injuredPlayer.Character and injuredPlayer.Character.PrimaryPart then
                        Script.Temp.PauseAntiFling = true
                        if Toggles.RedLightGodmode.Value then
                            Toggles.RedLightGodmode:SetValue(false)
                        end
                        lplr.Character:PivotTo(injuredPlayer.Character:GetPrimaryPartCFrame())
                        task.wait(0.2)
                        Script.Functions.FireCarryPrompt(injuredPlayer)
                        task.wait(0.2)
                        Script.Functions.WinRLGL()
                        task.wait(0.2)
                        Script.Functions.UnCarryPerson()
                        task.wait(0.2)
                        Script.Temp.PauseAntiFling = false
                    end
                    task.wait(1)
                end
            end)
        else
            if bringLoopThread then
                task.cancel(bringLoopThread)
                bringLoopThread = nil
            end
        end
    end)
    Toggles.LoopBringPlayers:SetVisible(false)
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

local DalgonaGameGroup = Tabs.Main:AddLeftGroupbox("Dalgona Game", "circle") do
    DalgonaGameGroup:AddButton("Finish Dalgona Game", function()
        if not Script.Functions.GetDalgonaRemote() then
            Script.Functions.Alert("Game hasn't started yet")
            return
        end
        Script.Functions.CompleteDalgonaGame()
        Script.Functions.BypassDalgonaGame()
        Script.Functions.Alert("Completed Dalgona Game", 2)
        Script.Functions.RestartRemotesScript()
        Script.Functions.Alert("Camera should be fixed", 3)
        task.spawn(function()
            repeat 
                task.wait(1)
                Script.Functions.CheckPlayersVisibility()
            until not Script.Functions.GetDalgonaRemote()
        end)
    end)
    DalgonaGameGroup:AddToggle("ImmuneDalgonaGame", {
        Text = "Unbreakable Cookie",
        Default = false
    })
end

Toggles.ImmuneDalgonaGame:OnChanged(function(call)
    if call then
        if not hookmetamethod then
            Script.Functions.Alert("Your executor doesn't support this", 5)
            Toggles.ImmuneDalgonaGame:SetValue(false)
            return
        end
        local DalgonaRemoteHook
        DalgonaRemoteHook = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local method = getnamecallmethod()

            if tostring(self) == "DALGONATEMPREMPTE" and method == "FireServer" then
                if args[1] ~= nil and type(args[1]) == "table" and args[1].CrackAmount ~= nil then
                    Script.Functions.Alert("Blocked crack attempt", 3)
                    return nil
                end
            end
            
            return DalgonaRemoteHook(self, unpack(args))
        end)
        Script.Temp.DalgonaRemoteHook = DalgonaRemoteHook
        Script.Functions.Alert("Cookie won't break", 3)
    else
        if not hookmetamethod then return end
        if not Script.Temp.DalgonaRemoteHook then return end
        hookmetamethod(game, '__namecall', Script.Temp.DalgonaRemoteHook)
    end
end)

local TugOfWarGroup = Tabs.Main:AddLeftGroupbox("Tug Of War", "spline") do
    TugOfWarGroup:AddToggle("AutoPull", {
        Text = "Quick Pull",
        Default = false
    })
    TugOfWarGroup:AddToggle("PerfectPull", {
        Text = "Perfect Pull",
        Default = true
    })
end

local MingleGroup = Tabs.Main:AddLeftGroupbox("Mingle", "users") do
    MingleGroup:AddToggle("AutoMingleQTE", {
        Text = "Auto Mingle",
        Default = false
    })
    local RemoteForQTE
    Toggles.AutoMingleQTE:OnChanged(function(call)
        Script.Temp.AutoMingleQTEActive = call
        if call then
            Script.Temp.AutoMingleQTEThread = task.spawn(function()
                while Script.Temp.AutoMingleQTEActive and not Library.Unloaded do
                    local character = lplr.Character
                    if character then
                        if not RemoteForQTE then
                            for _, obj in pairs(character:GetChildren()) do
                                if obj:IsA("RemoteEvent") and obj.Name == "RemoteForQTE" then
                                    RemoteForQTE = obj
                                    break
                                end
                            end
                        end
                        pcall(function()
                            RemoteForQTE:FireServer()
                        end)
                    end
                    task.wait(0.5)
                end
            end)
        else
            if Script.Temp.AutoMingleQTEThread then
                task.cancel(Script.Temp.AutoMingleQTEThread)
            end
        end
    end)
end

local GlassBridgeGroup = Tabs.Main:AddLeftGroupbox("Glass Bridge", "bridge") do
    GlassBridgeGroup:AddButton("Complete Glass Bridge Game", function()
        if not workspace:FindFirstChild("GlassBridge") then
            Script.Functions.Alert("Game didn't start yet")
            return
        end
        Script.Functions.WinGlassBridge()
    end)
    GlassBridgeGroup:AddButton("Reveal Glass Bridge", function()
        if not workspace:FindFirstChild("GlassBridge") then
            Script.Functions.Alert("Game didn't start yet")
            return
        end
        Script.Functions.RevealGlassBridge()
    end)
end

function Script.Functions.FetchHider()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplr and player:GetAttribute("IsHider") and player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            if hum.Health > 0 and not player.Character:FindFirstChild("Dead") then
                return player
            end
        end
    end
    return nil
end

function Script.Functions.GetKnife()
    local tool = lplr.Character and lplr.Character:FindFirstChild("Knife")
    if not tool and lplr:FindFirstChild("Backpack") then
        tool = lplr.Backpack:FindFirstChild("Knife")
    end
    return tool
end

function Script.Functions.FireKnifeRemote(target)
    local knife = Script.Functions.GetKnife()
    if not knife then return end
    if knife.Parent == lplr.Backpack then
        local humanoid = lplr.Character and lplr.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:EquipTool(knife)
        end
        knife = Script.Functions.GetKnife()
        if not knife or knife.Parent ~= lplr.Character then return end
    end
    local args = {
        "UsingMoveCustom",
        knife,
        nil,
        {
            Clicked = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UsedTool"):FireServer(unpack(args))

    local args2 = {
        "UsingMoveCustom",
        knife,
        true,
        {
            Clicked = true
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UsedTool"):FireServer(unpack(args2))
end

local HideAndSeekGroup = Tabs.Main:AddRightGroupbox("H.A.S", "search") do
    HideAndSeekGroup:AddToggle("TeleportToHider", {
        Text = "Teleport To Hider",
        Default = false
    }):AddKeyPicker("TTH", {
        Mode = "Toggle",
        Default = "P",
        Text = "Teleport To Hider",
        SyncToggleState = true
    })
    Toggles.TeleportToHider:OnChanged(function(call)
        if call then
            task.spawn(function()
                task.delay(0.5, function()
                    if Toggles.TeleportToHider.Value then
                        Toggles.TeleportToHider:SetValue(false)
                    end
                end)
            end)
            if not lplr.Character then return end
            if Script.GameState ~= "HideAndSeek" then 
                Script.Functions.Alert("Game didn't start yet")
                return
            end
            local hider = Script.Functions.GetHider()
            if not hider then
                Script.Functions.Alert("No hider found")
                return 
            end
            lplr.Character:PivotTo(hider:GetPrimaryPartCFrame())
        end
    end)
    HideAndSeekGroup:AddToggle("StaminaBypass", {
        Text = "Infinite Stamina",
        Default = false
    })
    Toggles.StaminaBypass:OnChanged(function(enabled)
        if enabled then
            Script.Temp.StaminaBypassLoop = task.spawn(function()
                while Toggles.StaminaBypass.Value and not Library.Unloaded do
                    local char = lplr.Character
                    if char then
                        local stamina = char:FindFirstChild("StaminaVal")
                        if stamina then
                            stamina.Value = 100
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            if Script.Temp.StaminaBypassLoop then
                task.cancel(Script.Temp.StaminaBypassLoop)
                Script.Temp.StaminaBypassLoop = nil
            end
        end
    end)
    HideAndSeekGroup:AddButton("Teleport to Safe Hiding Spot", function()
        if Script.GameState ~= "HideAndSeek" then 
            Script.Functions.Alert("Game didn't start yet")
            return
        end
        Script.Functions.TeleportSafeHidingSpot()
    end)

    HideAndSeekGroup:AddToggle("KillHidersToggle", {
        Text = "Hiders Killaura",
        Default = false
    }):OnChanged(function(enabled)
        if enabled then
            Script.Temp.KillHidersActive = true
            task.spawn(function()
                while Script.Temp.KillHidersActive and Script.GameState == "HideAndSeek" and not Library.Unloaded do
                    local hider = Script.Functions.FetchHider()
                    if not hider then
                        Script.Functions.Alert("No hiders found!", 2)
                        break
                    end
                    local hiderChar = hider.Character
                    local hiderRoot = hiderChar and hiderChar:FindFirstChild("HumanoidRootPart")
                    local myChar = lplr.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if hiderRoot and myRoot then
                        if (myRoot.Position - hiderRoot.Position).Magnitude > 6 then
                            myChar:PivotTo(CFrame.new(hiderRoot.Position + Vector3.new(0, 0, 3)))
                            Script.Functions.FireKnifeRemote(hider)
                            task.wait(0.2)
                        else
                            Script.Functions.FireKnifeRemote(hider)
                            task.wait(0.25)
                        end
                    else
                        task.wait(0.5)
                    end
                    while hider and hider.Character and hider.Character:FindFirstChild("Humanoid") and hider.Character.Humanoid.Health > 0 and not hider.Character:FindFirstChild("Dead") and Script.Temp.KillHidersActive and Script.GameState == "HideAndSeek" do
                        Script.Functions.FireKnifeRemote(hider)
                        task.wait(0.25)
                    end
                end
                Script.Temp.KillHidersActive = false
                if Toggles.KillHidersToggle.Value then
                    Toggles.KillHidersToggle:SetValue(false)
                end
            end)
        else
            Script.Temp.KillHidersActive = false
        end
    end)
end

local JumpRopeGroup = Tabs.Main:AddRightGroupbox("Jump Rope", "spline") do
    JumpRopeGroup:AddToggle("AutoSurviveJumpRope", {
        Text = "Anti Fall",
        Default = false
    }):OnChanged(function(enabled)
        if enabled then
            if not Script.Temp.JumpRope_AutoSurviveCon then
                local char = lplr.Character
                if char and workspace:FindFirstChild("JumpRope") and workspace.JumpRope:FindFirstChild("FallColllisionYClient") then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local fallY = workspace.JumpRope.FallColllisionYClient.Position.y
                    pcall(function()
                        workspace.JumpRope.FallColllisionYClient:Destroy()
                    end)
                    Script.Temp.JumpRope_AutoSurviveCon = RunService.RenderStepped:Connect(function()
                        if root and fallY and root.Position.Y <= fallY then
                            root.CFrame = root.CFrame + Vector3.new(0, 5, 0)
                        end
                    end)
                else
                    Script.Functions.Alert("Game didn't start yet", 3)
                    Toggles.AutoSurviveJumpRope:SetValue(false)
                end
            end
        else
            if Script.Temp.JumpRope_AutoSurviveCon then
                Script.Temp.JumpRope_AutoSurviveCon:Disconnect()
                Script.Temp.JumpRope_AutoSurviveCon = nil
            end
        end
    end)

    JumpRopeGroup:AddButton("Remove Fall Detection", function()
        local suc = pcall(function()
            workspace.JumpRope.FallColllisionYClient:Destroy()
            workspace.JumpRope.FallColllisionY:Destroy()
            workspace.JumpRope.COLLISIONCHECK:Destroy()
        end)
        if suc then
            Script.Functions.Alert("Removed fall detection!", 1.5)
        else
            Script.Functions.Alert("Fall detection not found!", 3)
        end
    end)

    JumpRopeGroup:AddButton("Complete Jump Rope Game", function() 
        Script.Functions.WinJumpRope()
        if not lplr.Character then return end
        local a = lplr.Character:FindFirstChild("SafeJumpRope") or Instance.new("Folder")
        a.Name = "SafeJumpRope"
        a.Parent = lplr.Character
    end)

    JumpRopeGroup:AddToggle("AutoPerfectJumpRope", {
        Text = "Auto Perfect",
        Default = false
    }):OnChanged(function(call)
        if call then
            if not Script.Temp.JumpRope_AutoPerfectCon then
                Script.Temp.JumpRope_AutoPerfectCon = game:GetService("RunService").RenderStepped:Connect(function()
                    local char = lplr.Character
                    if char then
                        local indicator = nil
                        for _, obj in ipairs(char:GetDescendants()) do
                            if obj:IsA("NumberValue") and obj.Name:lower():find("indicator") then
                                indicator = obj
                                break
                            end
                        end
                        if indicator then
                            indicator.Value = 0
                        end
                    end
                end)
            end
        else
            if Script.Temp.JumpRope_AutoPerfectCon then
                Script.Temp.JumpRope_AutoPerfectCon:Disconnect()
                Script.Temp.JumpRope_AutoPerfectCon = nil
            end
        end
    end)
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

local RebelGroup = Tabs.Main:AddRightGroupbox("Rebel", "sword") do
    RebelGroup:AddToggle("ExpandGuardHitbox", {
        Text = "Make Guard Hitbox Bigger",
        Default = false
    })

    local processedModels = {}
    local TARGET_SIZE = Vector3.new(4, 4, 4)
    local DEFAULT_SIZE = Vector3.new(1, 1, 1)

    local function isPlayerCharacter(model)
        return Players:FindFirstChild(model.Name) ~= nil
    end

    local function processModel(model)
        if not model or not model:IsA("Model") then return end
        if isPlayerCharacter(model) then return end
        if not isGuard(model) then return end
        if processedModels[model] then return end

        local head = model:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then return end

        processedModels[model] = head
    end

    local function cleanup()
        for model, head in pairs(processedModels) do
            if head and head.Parent then
                pcall(function()
                    head.Size = DEFAULT_SIZE
                    head.CanCollide = true
                end)
            end
            local highlight = model:FindFirstChild("_HeadHighlighter")
            if highlight then
                highlight:Destroy()
            end
        end
        processedModels = {}
    end

    Toggles.ExpandGuardHitbox:OnChanged(function(call)
        if call then
            task.spawn(function()
                repeat
                    local liveFolder = workspace:FindFirstChild("Live")
                    if not Toggles.ExpandGuardHitbox.Value or not liveFolder then return end
                    for _, model in ipairs(liveFolder:GetChildren()) do
                        processModel(model)
                    end
                    for model, head in pairs(processedModels) do
                        if model and model.Parent and head and head.Parent then
                            if head.Size ~= TARGET_SIZE then
                                head.Size = TARGET_SIZE
                                head.CanCollide = false
                            end
                        else
                            processedModels[model] = nil
                        end
                    end
                    task.wait(3)
                until not Toggles.ExpandGuardHitbox.Value or Library.Unloaded
            end)
        else
            cleanup()
        end
    end)
    
    RebelGroup:AddButton("Bring All Guards", function()
        pcall(function()
            Script.Temp.ValidGuards = {}
            local Live = workspace:WaitForChild("Live")
            for _, v in pairs(Live:GetChildren()) do
                if isGuard(v) then
                    table.insert(Script.Temp.ValidGuards, v)
                end
            end
        end)
        for i = 1, Options.BringLoopSlider and Options.BringLoopSlider.Value or 250 do
            task.wait()
            Script.Functions.PivotRebelGuardsToPlayer()
        end
    end)

    RebelGroup:AddSlider("BringLoopSlider", {
        Text = "Bring Guards Loop",
        Default = 100,
        Min = 10,
        Max = 300,
        Rounding = 1
    })

    RebelGroup:AddToggle("GunMods", { Text = "Gun Mods", Default = false })
    
    local originalGunStats = {}
    local originalDamageValues = {}
    local function patchGunStats(enable)
        local Guns = ReplicatedStorage:FindFirstChild("Weapons") and ReplicatedStorage.Weapons:FindFirstChild("Guns")
        if not Guns then return end
        local GunDamageValues = Script.Functions.SafeRequire(ReplicatedStorage.Modules.GunDamageValues)
        for _, gun in pairs(Guns:GetChildren()) do
            if enable then
                if not originalGunStats[gun.Name] then
                    originalGunStats[gun.Name] = {}
                    for _, stat in ipairs({"Spread", "FireRateCD", "MaxBullets", "ReloadingSpeed"}) do
                        if gun:FindFirstChild(stat) then
                            originalGunStats[gun.Name][stat] = gun[stat].Value
                        end
                    end
                end
                if gun:FindFirstChild("Spread") then gun.Spread.Value = 0 end
                if gun:FindFirstChild("FireRateCD") then gun.FireRateCD.Value = 0.01 end
                if gun:FindFirstChild("MaxBullets") then gun.MaxBullets.Value = 999 end
                if gun:FindFirstChild("ReloadingSpeed") then gun.ReloadingSpeed.Value = 0.01 end

                if GunDamageValues and GunDamageValues[gun.Name] then
                    if not originalDamageValues[gun.Name] then
                        originalDamageValues[gun.Name] = {}
                        for part, dmg in pairs(GunDamageValues[gun.Name]) do
                            originalDamageValues[gun.Name][part] = dmg
                        end
                    end
                    for part, _ in pairs(GunDamageValues[gun.Name]) do
                        GunDamageValues[gun.Name][part] = 9999
                    end
                end
            else
                if originalGunStats[gun.Name] then
                    for stat, val in pairs(originalGunStats[gun.Name]) do
                        if gun:FindFirstChild(stat) then
                            gun[stat].Value = val
                        end
                    end
                end
                if GunDamageValues and GunDamageValues[gun.Name] and originalDamageValues[gun.Name] then
                    for part, val in pairs(originalDamageValues[gun.Name]) do
                        GunDamageValues[gun.Name][part] = val
                    end
                end
            end
        end
    end

    Toggles.GunMods:OnChanged(function(enabled)
        patchGunStats(enabled)
    end)

    RebelGroup:AddToggle("AutoSteal", {
        Text = "Auto GrabGuns",
        Default = false
    })
end

Script.Temp.ValidGuards = {}
task.spawn(function()
    pcall(function()
        local Live = workspace:WaitForChild("Live")
        for _, v in pairs(Live:GetChildren()) do
            if isGuard(v) then
                table.insert(Script.Temp.ValidGuards, v)
            end
        end
        Library:GiveSignal(Live.ChildAdded:Connect(function(v)
            if isGuard(v) then
                table.insert(Script.Temp.ValidGuards, v)
            end
        end))
        Library:GiveSignal(Live.ChildRemoved:Connect(function(v)
            if isGuard(v) then
                local index = table.find(Script.Temp.ValidGuards, v)
                if index then
                    table.remove(Script.Temp.ValidGuards, index)
                end
            end
        end))
    end)
end)

local function getNearestGuard(originPos, wallcheckEnabled, character)
    local closest, closestDist = nil, math.huge
    for _, model in ipairs(Script.Temp.ValidGuards or {}) do
        if isGuard(model) then
            local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
            if part then
                local canSee = true
                if wallcheckEnabled then
                    canSee = Script.Functions.Wallcheck(character, model)
                end
                if canSee then
                    local dist = (part.Position - originPos).Magnitude
                    if dist < closestDist then
                        closest = part
                        closestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

local AimbotGroup = Tabs.Main:AddRightGroupbox("Aimbot", "bow-arrow") do
    AimbotGroup:AddToggle("GuardAimbot", { Text = "Guard Aimbot", Default = false })
    AimbotGroup:AddToggle("PlayerAimbot", { Text = "Player Aimbot", Default = false })
    AimbotGroup:AddToggle("AimbotWallcheck", { Text = "Wallcheck", Default = true })
    AimbotGroup:AddSlider("AimSpeed", {
        Text = "Aim Speed",
        Default = 0.2,
        Min = 0.01,
        Max = 1,
        Rounding = 2
    })

    local function getNearestPlayer(camPos, wallcheckEnabled, character)
        local closest, closestDist = nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and not player.Character:FindFirstChild("Dead") then
                local part = player.Character.HumanoidRootPart
                if not wallcheckEnabled or Script.Functions.Wallcheck(character, player.Character) then
                    local dist = (part.Position - camPos).Magnitude
                    if dist < closestDist then
                        closest = part
                        closestDist = dist
                    end
                end
            end
        end
        return closest
    end

    if Script.Temp.AimBotConnection then
        Script.Temp.AimBotConnection:Disconnect()
        Script.Temp.AimBotConnection = nil
    end
    local function updateAimbot()
        if Script.Temp.AimBotConnection then
            Script.Temp.AimBotConnection:Disconnect()
            Script.Temp.AimBotConnection = nil
        end
        if Toggles.GuardAimbot.Value or Toggles.PlayerAimbot.Value then
            Script.Temp.AimBotConnection = RunService.RenderStepped:Connect(function()
                if not (Toggles.GuardAimbot.Value or Toggles.PlayerAimbot.Value) or not lplr.Character then return end
                local cam = workspace.CurrentCamera
                local camPos = cam.CFrame.Position
                local aimTarget = nil
                local guardTarget, guardDist = nil, math.huge
                local playerTarget, playerDist = nil, math.huge
                if Toggles.GuardAimbot.Value then
                    guardTarget = getNearestGuard(camPos, Toggles.AimbotWallcheck.Value, lplr.Character)
                    if guardTarget then
                        guardDist = (guardTarget.Position - camPos).Magnitude
                    end
                end
                if Toggles.PlayerAimbot.Value then
                    playerTarget = getNearestPlayer(camPos, Toggles.AimbotWallcheck.Value, lplr.Character)
                    if playerTarget then
                        playerDist = (playerTarget.Position - camPos).Magnitude
                    end
                end
                if guardTarget and playerTarget then
                    if guardDist <= playerDist then
                        aimTarget = guardTarget
                    else
                        aimTarget = playerTarget
                    end
                else
                    aimTarget = guardTarget or playerTarget
                end
                if aimTarget then
                    local look = (aimTarget.Position - camPos).Unit
                    local aimSpeed = Options.AimSpeed and Options.AimSpeed.Value or 0.2
                    cam.CFrame = cam.CFrame:Lerp(CFrame.new(camPos, camPos + look), aimSpeed)
                end
            end)
        end
    end
    Toggles.GuardAimbot:OnChanged(updateAimbot)
    Toggles.PlayerAimbot:OnChanged(updateAimbot)
    Toggles.AimbotWallcheck:OnChanged(updateAimbot)
end

local AutoShootGroup = Tabs.Main:AddRightGroupbox("Auto Shoot", "target") do
    AutoShootGroup:AddToggle("AutoShoot", { Text = "Auto Shoot", Default = false })
    AutoShootGroup:AddToggle("AutoShootWallcheck", { Text = "Wallcheck", Default = true })

    Toggles.AutoShoot:OnChanged(function(enabled)
        if enabled then
            Script.Temp.AutoShootActive = true
            task.spawn(function()
                while Script.Temp.AutoShootActive and not Library.Unloaded do
                    local character = lplr.Character
                    if character and not character:FindFirstChild("Dead") then
                        local heldGun = nil
                        for _, tool in ipairs(character:GetChildren()) do
                            if tool:IsA("Tool") and tool:FindFirstChild("Handle") and string.find(tool.Name, "MP5") then
                                heldGun = tool
                                break
                            end
                        end
                        if heldGun then
                            local root = character:FindFirstChild("HumanoidRootPart")
                            local target = getNearestGuard(root and root.Position or Vector3.zero, Toggles.AutoShootWallcheck.Value, character)
                            if target and (target.Position - root.Position).Magnitude < 100 then
                                local map = workspace:FindFirstChild("Map")
                                local baseplate = map and map:FindFirstChild("Baseplate") or workspace
                                local firePos = root.Position
                                local bulletPos = target.Position
                                local args = {
                                    heldGun,
                                    {
                                        ClientRayInstance = baseplate,
                                        ClientRayNormal = Vector3.yAxis,
                                        ClientRayPosition = bulletPos,
                                        FiredGun = true,
                                        HitTargets = {},
                                        bulletSizeC = Vector3.new(0.01, 0.01, (bulletPos - firePos).Magnitude),
                                        bulletCF = CFrame.new(firePos, bulletPos),
                                        FirePosition = firePos
                                    }
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("FiredGunClient"):FireServer(unpack(args))
                                task.wait(0.15)
                            else
                                task.wait(0.1)
                            end
                        else
                            task.wait(0.2)
                        end
                    else
                        task.wait(0.5)
                    end
                end
            end)
        else
            Script.Temp.AutoShootActive = false
        end
    end)
end

function Script.Functions.CleanTable(tab)
    local res = {}
    for i,v in pairs(tab) do 
        table.insert(res, tostring(i))
    end
    return res
end

function Script.Functions.GetEmotesMeta()
    local Animations = ReplicatedStorage:WaitForChild("Animations", 10)
    if not Animations then Script.Functions.Warn("[GetEmotesMeta]: Animations folder timeout!"); return end
    local Emotes = Animations:WaitForChild("Emotes", 10)
    if not Emotes then Script.Functions.Warn("[GetEmotesMeta]: Emotes folder timeout!"); return end
    local res = {}
    for i, v in pairs(Emotes:GetChildren()) do
        if v.ClassName ~= "Animation" then continue end
        if not v.AnimationId then continue end

        if res[v.Name] then
            Script.Functions.Warn("The emote "..tostring(v.Name).." is already in the list! This might be a duplicate or an error in the game...")
        end

        res[v.Name] = {
            anim = v.AnimationId,
            object = v
        }
    end
    Script.Temp.EmoteList = res
    return res
end

function Script.Functions.RefreshEmoteList()
    local w = function(str) Script.Functions.Warn("List"..tostring(str)) end
    local res = Script.Functions.GetEmotesMeta()
    if not res then w("res not found!") return end
    if not Options.EmotesList then w("Emotes List Option not found!") return end
    Options.EmotesList:SetValues(Script.Functions.CleanTable(res))
end

function Script.Functions.HookEmotesFolder()
    Script.Functions.RefreshEmoteList()
    local Animations = ReplicatedStorage:WaitForChild("Animations")
    local Emotes = Animations:WaitForChild("Emotes")
    Library:GiveSignal(Emotes.ChildAdded:Connect(Script.Functions.RefreshEmoteList))
    Library:GiveSignal(Emotes.ChildRemoved:Connect(Script.Functions.RefreshEmoteList))
end

function Script.Functions.ValidateEmote(emote : string)
    return Script.Temp.EmoteList ~= nil and Script.Temp.EmoteList[emote]
end

function Script.Functions.PlayEmote(emoteId, emoteObject)

    local character = lplr and lplr.Character
    if not character then
        Script.Functions.Alert("No character found!", 3)
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        Script.Functions.Alert("No humanoid found!", 3)
        return
    end

    if Script.Temp.EmoteTrack and typeof(Script.Temp.EmoteTrack) == "Instance" and Script.Temp.EmoteTrack:IsA("AnimationTrack") then
        pcall(function() Script.Temp.EmoteTrack:Stop() end)
        Script.Temp.EmoteTrack = nil
    end

    local animId = emoteId
    if emoteObject and emoteObject.AnimationId then
        animId = emoteObject.AnimationId
    end
    if not animId or animId == "" then
        Script.Functions.Alert("Invalid AnimationId!", 3)
        return
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track
    local success, err = pcall(function()
        track = humanoid:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action
        track:Play()
        Script.Temp.EmoteTrack = track
    end)
    if not success or not track then
        Script.Functions.Alert("Failed to play emote!", 3)
        return
    end
end

local EmotesGroup = Tabs.Misc:AddRightGroupbox("Misc", "smile") do
    EmotesGroup:AddDropdown("EmotesList", { 
        Text = 'Emotes List', 
        Values = {}, 
        AllowNull = true 
    })
    task.spawn(Script.Functions.HookEmotesFolder)
    EmotesGroup:AddButton("Play Emote", function()
        if Options.EmotesList.Value then
            local emoteId = Script.Functions.ValidateEmote(Options.EmotesList.Value)
            if emoteId and emoteId.anim and emoteId.object then
                Script.Functions.PlayEmote(emoteId.anim, emoteId.object)
            else
                Script.Functions.Alert("Error! Invalid emote selected")
                Options.EmotesList:SetValue(nil)
                Script.Functions.RefreshEmoteList()
            end
        else
            Script.Functions.Alert("No Emote Selected!", 3)
        end
    end)
    EmotesGroup:AddButton("Stop Emoting", function()
        if Script.Temp.EmoteTrack and typeof(Script.Temp.EmoteTrack) == "Instance" and Script.Temp.EmoteTrack:IsA("AnimationTrack") then
            pcall(function() Script.Temp.EmoteTrack:Stop() end)
            Script.Temp.EmoteTrack = nil
        end
    end)
end

local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc", "folder") do
    MiscGroup:AddToggle("AntiRagdoll", {
        Text = "Anti Ragdoll + No Stun",
        Default = false
    })

    MiscGroup:AddButton("Remove Ragdoll Effect", Script.Functions.BypassRagdoll)

    MiscGroup:AddDivider()
    MiscGroup:AddToggle("SpectateModeToggler", {
        Text = "Enable Spectator Mode",
        Default = false
    })
    Toggles.SpectateModeToggler:OnChanged(function(call)
        workspace.Values.CanSpectateIfWonGame.Value = call
    end)
    MiscGroup:AddDivider()
    MiscGroup:AddButton("Fix Camera", function()
        
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
                camera.CameraSubject = lplr.Character:FindFirstChild("Humanoid")
            end
        end
    end)
    MiscGroup:AddButton("Reset Camera", Script.Functions.FixCamera)
    MiscGroup:AddButton("Skip Cutscene", function()
      
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
                camera.CameraSubject = lplr.Character:FindFirstChild("Humanoid")
            end
        end
    end)
    MiscGroup:AddDivider()
    MiscGroup:AddToggle("TeleportToSafePlace", {
        Text = "Teleport To Safe Zone",
        Default = false
    }):AddKeyPicker("TTSPKey", {
        Mode = "Toggle",
        Default = "L",
        Text = "Teleport To Safe Zone",
        SyncToggleState = true
    })
    Toggles.TeleportToSafePlace:OnChanged(function(call)
        if call then
            Script.Functions.Alert("Teleported to Safe Zone, disable to go back", 3)
            Script.Functions.TeleportSafe()
        else
            Script.Functions.TeleportBackFromSafe()
        end
    end)

    function Script.Functions.ToggleTPTSP()
        pcall(function()
            if not Toggles.TeleportToSafePlace.Value then
                Toggles.TeleportToSafePlace:SetValue(true)
            end
        end)
    end

    function Script.Functions.CleanAntiVoid()
        if Script.Temp.AntiVoidLoop then
            task.cancel(Script.Temp.AntiVoidLoop)
            Script.Temp.AntiVoidLoop = nil
        end
        
        if Script.Temp.AntiVoidConnection then
            Script.Temp.AntiVoidConnection:Disconnect()
            Script.Temp.AntiVoidConnection = nil
        end
        
        if Script.Temp.AntiVoidRespawn then
            Script.Temp.AntiVoidRespawn:Disconnect()
            Script.Temp.AntiVoidRespawn = nil
        end
        
        if Script.Temp.AntiVoidPart then
            Script.Temp.AntiVoidPart:Destroy()
            Script.Temp.AntiVoidPart = nil
        end
    end

    MiscGroup:AddToggle("AntiVoid", {
        Text = "Anti Void",
        Default = false
    })

    Toggles.AntiVoid:OnChanged(function(enabled)
        if enabled then
            Script.Functions.Alert("Anti Void Enabled", 3)
            Script.Temp.AntiVoidEnabled = true
            Script.Temp.AntiVoidPart = nil
            Script.Temp.AntiVoidConnection = nil
            
            local function createAntiVoidPart()
                if Script.Temp.AntiVoidPart then
                    Script.Temp.AntiVoidPart:Destroy()
                end
                
                Script.Temp.AntiVoidPart = Instance.new("Part")
                Script.Temp.AntiVoidPart.Size = Vector3.new(10000, 1, 10000)
                Script.Temp.AntiVoidPart.Transparency = 0.5
                Script.Temp.AntiVoidPart.Material = Enum.Material.ForceField
                Script.Temp.AntiVoidPart.Color = Color3.fromRGB(0, 255, 255)
                Script.Temp.AntiVoidPart.CanCollide = true
                Script.Temp.AntiVoidPart.Anchored = true
                Script.Temp.AntiVoidPart.CanQuery = false
                Script.Temp.AntiVoidPart.Parent = workspace
                
                local debounce = tick()
                Script.Temp.AntiVoidConnection = Script.Temp.AntiVoidPart.Touched:Connect(function(touchedPart)
                    if touchedPart.Parent == lplr.Character and lplr.Character:FindFirstChild("Humanoid") and lplr.Character.Humanoid.Health > 0 and debounce < tick() then
                        local rootPart = lplr.Character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            debounce = tick() + 0.1
                            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 100, rootPart.Velocity.Z)
                        end
                    end
                end)
            end
            
            createAntiVoidPart()
            
            Script.Temp.AntiVoidLoop = task.spawn(function()
                repeat
                    if lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") and Script.Temp.AntiVoidPart then
                        local rootPart = lplr.Character.HumanoidRootPart
                        local rayCheck = RaycastParams.new()
                        rayCheck.RespectCanCollide = true
                        rayCheck.FilterDescendantsInstances = {camera, lplr.Character, Script.Temp.AntiVoidPart}
                        rayCheck.CollisionGroup = rootPart.CollisionGroup
                        
                        local ray = workspace:Raycast(rootPart.Position, Vector3.new(0, -1000, 0), rayCheck)
                        if ray then
                            Script.Temp.AntiVoidPart.Position = ray.Position - Vector3.new(0, 15, 0)
                        end
                    end
                    task.wait(0.1)
                until not Script.Temp.AntiVoidEnabled or Library.Unloaded
                end)
            
            Script.Temp.AntiVoidRespawn = lplr.CharacterAdded:Connect(function()
                if Script.Temp.AntiVoidEnabled then
                    task.wait(0.6)
                    createAntiVoidPart()
                end
            end)
        else
            Script.Functions.Alert("Anti Void Disabled", 3)
            Script.Temp.AntiVoidEnabled = false
            
            Script.Functions.CleanAntiVoid()
        end
    end)

    MiscGroup:AddButton("Fix Players Visibility", Script.Functions.CheckPlayersVisibility)
end

Toggles.AntiRagdoll:OnChanged(function(call)
    if call then
        Script.Functions.Alert("Anti Ragdoll + No Stun Enabled", 3)
        Script.Functions.BypassRagdoll()
        if Script.Temp.AntiRagdollLoop then
            task.cancel(Script.Temp.AntiRagdollLoop)
        end
        Script.Temp.AntiRagdollLoop = task.spawn(function()
            while Toggles.AntiRagdoll.Value and not Library.Unloaded do
                Script.Functions.BypassRagdoll()
                task.wait(0.1)
            end
        end)
    else
        Script.Functions.Alert("Anti Ragdoll + No Stun Disabled", 3)
        if Script.Temp.AntiRagdollLoop then
            task.cancel(Script.Temp.AntiRagdollLoop)
            Script.Temp.AntiRagdollLoop = nil
        end
        if Script.Temp.RagdollBlockConn then
            Script.Temp.RagdollBlockConn:Disconnect()
            Script.Temp.RagdollBlockConn = nil
        end
    end
end)

Library:GiveSignal(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        camera = workspace.CurrentCamera
    end
end))

local PlayerGroupBox = Tabs.Main:AddRightGroupbox("Player", "user") do
    PlayerGroupBox:AddSlider("SpeedSlider", {
        Text = "Walk Speed",
        Default = 30,
        Min = 0,
        Max = 100,
        Rounding = 1
    })
    
    PlayerGroupBox:AddToggle("SpeedToggle", {
        Text = "Speed",
        Default = false
    }):AddKeyPicker("SpeedKey", {
        Mode = "Toggle",
        Default = "C",
        Text = "Speed",
        SyncToggleState = true
    })

    PlayerGroupBox:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false
    }):AddKeyPicker("NoclipKey", {
        Mode = "Toggle",
        Default = "N",
        Text = "Noclip",
        SyncToggleState = true
    })

    PlayerGroupBox:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false
    })

    PlayerGroupBox:AddToggle("Fly", {
        Text = "Fly",
        Default = false
    })
    
    PlayerGroupBox:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 40,
        Min = 10,
        Max = 100,
        Rounding = 1,
        Compact = true,
    })
end

function Script.Functions.HookShittyAntiFlingDetection()
    -- Anti Fling detection hook
    return true
end

function Script.Functions.RevertAntiFlingDetection()
    -- Revert anti fling detection
    return true
end

Library:GiveSignal(lplr.CharacterAdded:Connect(Script.Functions.HookShittyAntiFlingDetection))
pcall(Script.Functions.HookShittyAntiFlingDetection)

Toggles.FlingAuraToggle:OnChanged(function(call)
    local function setNoclip(state)
        if Toggles.Noclip.Value ~= state then
            Toggles.Noclip:SetValue(state)
        end
    end

    local function stopFlingAura()
        Script.Temp.FlingAuraActive = false
        setNoclip(false)
        if Script.Temp.FlingAuraDeathConn then
            Script.Temp.FlingAuraDeathConn:Disconnect()
            Script.Temp.FlingAuraDeathConn = nil
        end
    end

    if call then
        Script.Functions.Alert("Fling Enabled", 3)
        Script.Temp.FlingAuraActive = true
        Script.Functions.HookShittyAntiFlingDetection()
        pcall(function()
            if not Toggles.PatchFlingAnticheat.Value then
                Toggles.PatchFlingAnticheat:SetValue(true)
            end
        end)
        setNoclip(true)
        local player = lplr
        local function getRoot(character)
            return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
        end
        local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            Script.Temp.FlingAuraDeathConn = humanoid.Died:Connect(stopFlingAura)
        end
        task.spawn(function()
            local movel = 0.1
            while Script.Temp.FlingAuraActive and not Library.Unloaded do
                local character = player.Character
                local root = getRoot(character)
                if character and character.Parent and root and root.Parent then
                    local originalVel = root.Velocity
                    root.Velocity = originalVel * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    if character and character.Parent and root and root.Parent then
                        root.Velocity = originalVel
                    end
                    RunService.Stepped:Wait()
                    if character and character.Parent and root and root.Parent then
                        root.Velocity = originalVel + Vector3.new(0, movel, 0)
                        movel = -movel
                    end
                end
                RunService.Heartbeat:Wait()
            end
        end)
    else
        pcall(function()
            if Toggles.PatchFlingAnticheat.Value then
                Toggles.PatchFlingAnticheat:SetValue(false)
            end
        end)
        Script.Functions.Alert("Fling Disabled", 3)
        Script.Functions.RevertAntiFlingDetection()
        stopFlingAura()
    end
end)

Toggles.Fly:SetVisible(false)
Options.FlySpeed:SetVisible(false)

Toggles.Noclip:OnChanged(function(call)
    Script.Temp.NoclipParts = Script.Temp.NoclipParts or {}
    if call then
        Script.Functions.Alert("Noclip Enabled", 3)
        local function NoclipLoop()
            if lplr.Character ~= nil then
                for _, child in pairs(lplr.Character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide == true then
                        child.CanCollide = false
                        Script.Temp.NoclipParts[child] = true
                    end
                end
            end
        end
        task.spawn(function()
            repeat 
                RunService.Heartbeat:Wait()
                NoclipLoop()
            until not Toggles.Noclip.Value or Library.Unloaded
        end)
    else
        Script.Functions.Alert("Noclip Disabled", 3)
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

Options.SpeedSlider:OnChanged(function(val)
    if not Toggles.SpeedToggle.Value then return end
    if not lplr.Character then return end
    if not lplr.Character:FindFirstChild("Humanoid") then return end
    lplr.Character.Humanoid.WalkSpeed = Options.SpeedSlider.Value
end)

Toggles.SpeedToggle:OnChanged(function(call)
    if call then
        Script.Functions.Alert("Speed Enabled", 3)
        if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            Script.Temp.OldSpeed = lplr.Character.Humanoid.WalkSpeed
            lplr.Character.Humanoid.WalkSpeed = Options.SpeedSlider.Value
        end
        task.spawn(function()
            repeat
                task.wait(0.5)
                if not Toggles.SpeedToggle.Value then return end
                if not lplr.Character then return end
                if not lplr.Character:FindFirstChild("Humanoid") then return end
                if call then
                    lplr.Character.Humanoid.WalkSpeed = Options.SpeedSlider.Value
                end
            until not Toggles.SpeedToggle.Value or Library.Unloaded
        end)
    else
        Script.Functions.Alert("Speed Disabled", 3)
        if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.WalkSpeed = 31
            Script.Temp.OldSpeed = nil
        end
    end
end)    

local controlModule

Toggles.Fly:OnChanged(function(value)
    local rootPart = Script.Functions.GetRootPart()
    if not rootPart then return end

    local humanoid = Script.Functions.GetHumanoid()
    if humanoid then
        humanoid.PlatformStand = value
    end

    local flyBody = Script.Temp.FlyBody or Instance.new("BodyVelocity")
    flyBody.Velocity = Vector3.zero
    flyBody.MaxForce = Vector3.one * 9e9
    Script.Temp.FlyBody = flyBody

    Script.Temp.FlyBody.Parent = value and rootPart or nil

    if value then
        controlModule = controlModule or Script.Functions.SafeRequire(lplr:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        Script.Connections["Fly"] = RunService.RenderStepped:Connect(function()
            local moveVector = controlModule:GetMoveVector()
            local velocity = -((camera.CFrame.LookVector * moveVector.Z) - (camera.CFrame.RightVector * moveVector.X)) * Options.FlySpeed.Value

            Script.Temp.FlyBody.Velocity = velocity
        end)
    else
        if Script.Connections["Fly"] then
            Script.Connections["Fly"]:Disconnect()
        end
    end
end)

function Script.Functions.SpoofFlingVelocity(call)
    if call then
        local spoofedValue = Vector3.new(0, 0, 0)
        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            Script.Functions.Alert("No HumanoidRootPart found!", 3)
            return
        end

        if not Script.Temp.OriginalIndex then
            Script.Temp.OriginalIndex = hookmetamethod(game, "__index", function() end)
            hookmetamethod(game, "__index", Script.Temp.OriginalIndex)
        end
        if not Script.Temp.OriginalNewIndex then
            Script.Temp.OriginalNewIndex = hookmetamethod(game, "__newindex", function() end)
            hookmetamethod(game, "__newindex", Script.Temp.OriginalNewIndex)
        end

        local lastVelocity, lastAssemblyLinearVelocity
        local spoofedProps = {
            Velocity = spoofedValue,
            AssemblyLinearVelocity = spoofedValue
        }

        local index, newindex

        index = hookmetamethod(game, "__index", function(self, key)
            if not checkcaller() and typeof(self) == "Instance" and self == root then
                if spoofedProps[key] ~= nil then
                    return spoofedProps[key]
                end
            end
            return Script.Temp.OriginalIndex(self, key)
        end)

        newindex = hookmetamethod(game, "__newindex", function(self, key, value)
            if not checkcaller() and typeof(self) == "Instance" and self == root then
                if spoofedProps[key] ~= nil then
                    if key == "Velocity" then
                        lastVelocity = value
                        return
                    elseif key == "AssemblyLinearVelocity" then
                        lastAssemblyLinearVelocity = value
                        return
                    end
                end
            end
            return Script.Temp.OriginalNewIndex(self, key, value)
        end)

        Script.Temp.SpoofedIndex = index
        Script.Temp.SpoofedNewIndex = newindex
        Script.Temp.LastVelocity = lastVelocity
        Script.Temp.LastAssemblyLinearVelocity = lastAssemblyLinearVelocity

        Script.Functions.Alert("Fling Velocity Spoofing Enabled!", 3)
    else
        if Script.Temp.SpoofedIndex then
            hookmetamethod(game, "__index", Script.Temp.OriginalIndex)
            Script.Temp.SpoofedIndex = nil
        end
        if Script.Temp.SpoofedNewIndex then
            hookmetamethod(game, "__newindex", Script.Temp.OriginalNewIndex)
            Script.Temp.SpoofedNewIndex = nil
        end
        
        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        if root then
            if Script.Temp.LastVelocity then 
                root.Velocity = Script.Temp.LastVelocity 
                Script.Temp.LastVelocity = nil
            end
            if Script.Temp.LastAssemblyLinearVelocity then 
                root.AssemblyLinearVelocity = Script.Temp.LastAssemblyLinearVelocity 
                Script.Temp.LastAssemblyLinearVelocity = nil
            end
        end
        
        Script.Functions.Alert("Fling Velocity Spoofing Disabled!", 3)
    end
end

function Script.Functions.FlingCharacterHook(call)
    if call then
        local function PatchFlingAnticheat()
            local char = lplr.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local anticheatStates = { "Stun", "Anchor", "RotateDisabled", "CantRun", "InCutscene", "DisableHeadLookAt" }
            if not Script.Temp.FlingAnticheatChildConn then
                Script.Temp.FlingAnticheatChildConn = char.ChildAdded:Connect(function(child)
                    if table.find(anticheatStates, child.Name) then
                        child:Destroy()
                    end
                end)
            end

            if not Script.Temp.FlingAnticheatMT then
                local mt = getrawmetatable(root)
                Script.Temp.FlingAnticheatOldNewIndex = mt.__newindex
                setreadonly(mt, false)
                mt.__newindex = function(self, key, value)
                    if self == root and key == "Anchored" and value == true then
                        return
                    end
                    return Script.Temp.FlingAnticheatOldNewIndex(self, key, value)
                end
                setreadonly(mt, true)
                Script.Temp.FlingAnticheatMT = mt
            end
        end

        local function onChar(char)
            task.wait(1)
            PatchFlingAnticheat()
        end
        Script.Temp.FlingAnticheatCharConn = lplr.CharacterAdded:Connect(onChar)
        if lplr.Character then
            PatchFlingAnticheat()
        end
        Script.Functions.Alert("Anticheat Patched!", 3)
    else
        if Script.Temp.FlingAnticheatCharConn then
            Script.Temp.FlingAnticheatCharConn:Disconnect()
            Script.Temp.FlingAnticheatCharConn = nil
        end
        if Script.Temp.FlingAnticheatChildConn then
            Script.Temp.FlingAnticheatChildConn:Disconnect()
            Script.Temp.FlingAnticheatChildConn = nil
        end
        if Script.Temp.FlingAnticheatMT and Script.Temp.FlingAnticheatOldNewIndex then
            local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local mt = Script.Temp.FlingAnticheatMT
                setreadonly(mt, false)
                mt.__newindex = Script.Temp.FlingAnticheatOldNewIndex
                setreadonly(mt, true)
            end
            Script.Temp.FlingAnticheatMT = nil
            Script.Temp.FlingAnticheatOldNewIndex = nil
        end
        Script.Functions.Alert("Anticheat Patch Disabled!", 3)
    end
end

function Script.Functions.BlockAnticheatRemote(call)
    if call then
        if not hookmetamethod then
            return
        else
            Script.Functions.Alert("Disabled Anticheat Remote", 3)
        end
        local AnticheatHook
        AnticheatHook = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local method = getnamecallmethod()

            if tostring(self) == "TemporaryReachedBindable" and method == "FireServer" then
                if args[1] ~= nil and type(args[1]) == "table" and (args[1].FallingPlayer ~= nil or args[1].funnydeath ~= nil) then
                    return nil
                end
            end

            if tostring(self) == "RandomOtherRemotes" and method == "FireServer" then
                if args[1] ~= nil and type(args[1]) == "table" and args[1].FallenOffMap ~= nil then
                    return nil
                end
            end
            
            return AnticheatHook(self, unpack(args))
        end)
        Script.Temp.AnticheatHook = AnticheatHook
    else
        if not hookmetamethod then return end
        if not Script.Temp.AnticheatHook then return end
        hookmetamethod(game, '__namecall', Script.Temp.AnticheatHook)
    end
end

function Script.Functions.CEAnticheatPatch(call)
    if call then
        local humanoidRootPart = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = lplr.Character and lplr.Character:FindFirstChild("Humanoid")
        if not humanoidRootPart or not humanoid then 
            Script.Functions.Alert("Error bypassing AC! HumanoidRootPart or Humanoid not found!")
            return
        end
        pcall(function()
            workspace.Effects.SpawnLocation:Clone().Parent = workspace
            workspace.Effects.SpawnLocation:Destroy()
        end)
        Script.Temp.HRPCON = humanoidRootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
            if humanoidRootPart.Anchored then
                humanoidRootPart.Anchored = false
            end
        end)
        local RunService = Services.RunService or game:GetService("RunService")
        Script.Temp.ALVCON = RunService.Heartbeat:Connect(function()
            local char = lplr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if root and hum then
                if root.AssemblyLinearVelocity == Vector3.new(0,0,0) and hum.MoveDirection.Magnitude > 0.1 then
                    local speed = hum.WalkSpeed or 16
                    local moveDirection = hum.MoveDirection
                    root.AssemblyLinearVelocity = (moveDirection * speed) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                end
            end
        end)
    else
        if Script.Temp.HRPCON then
            pcall(function()
                Script.Temp.HRPCON:Disconnect()
            end)
            Script.Temp.HRPCON = nil
        end
        if Script.Temp.ALVCON then
            pcall(function()
                Script.Temp.ALVCON:Disconnect()
            end)
            Script.Temp.ALVCON = nil
        end
    end
end

local AnticheatPatchGroup = Tabs.Main:AddRightGroupbox("AC Bypass", "shield") do
    local Registry = {
        FlingVelocity = {
            Text = "Spoof Fling Velocity",
            Function = Script.Functions.SpoofFlingVelocity,
            Enabled = true,
            Running = false
        },
        CharacterHook = {
            Text = "Fling Character Hook",
            Function = Script.Functions.FlingCharacterHook,
            Enabled = true,
            Running = false
        },
        AnticheatRemote = {
            Text = "Block Anticheat Remote",
            Function = Script.Functions.BlockAnticheatRemote,
            Enabled = true,
            Running = false
        }
    }
    AnticheatPatchGroup:AddToggle("PatchFlingAnticheat", {
        Text = "Enabled",
        Default = false
    }):OnChanged(function(call)
       
        if hookmetamethod then
            for _, reg in pairs(Registry) do
                if call and reg.Enabled and not reg.Running then
                    reg.Running = call
                    reg.Function(call)
                elseif not call and reg.Enabled and reg.Running then
                    reg.Running = call
                    reg.Function(call)
                end 
            end
        else
            Script.Functions.Alert("[AC Bypass]: Might not work due your executor", 3)
            Script.Functions.CEAnticheatPatch(call)
        end
    end)
    for metaName, reg in pairs(Registry) do
        AnticheatPatchGroup:AddToggle(metaName, {
            Text = reg.Text,
            Default = reg.Enabled
        }):OnChanged(function(call)
            Registry[metaName].Enabled = call
            if Registry[metaName].Running and not Registry[metaName].Enabled then
                Registry[metaName].Function(call)
                Registry[metaName].Running = call
            end
        end)
    end
end

local SecurityGroupBox = Tabs.Main:AddRightGroupbox("Security", "shield") do
    SecurityGroupBox:AddToggle("AntiAfk", {
        Text = "Anti AFK",
        Default = true
    })
    Toggles.AntiAfk:OnChanged(function(call)
        if call then
            local VirtualUser = Services.VirtualUser
            Script.Temp.AntiAfkConnection = lplr.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
                wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
            end)
        else
            if not Script.Temp.AntiAfkConnection then return end
            pcall(function()
                Script.Temp.AntiAfkConnection:Disconnect()
            end)
        end
    end)
    SecurityGroupBox:AddToggle("StaffDetector", {
        Text = "Staff Detector",
        Default = true
    })
    Toggles.StaffDetector:OnChanged(function(call)
        if call then
            local STAFF_GROUP_ID = 12398672
            local STAFF_MIN_RANK = 120
            local staffRoles = {
                [120] = "moderator",
                [254] = "dev",
                [255] = "owner"
            }
            Script.Temp.DetectedStaff = Script.Temp.DetectedStaff or {}
            local function checkPlayerStaff(player)
                local success, rank = pcall(function()
                    return player:GetRankInGroup(STAFF_GROUP_ID)
                end)
                if success and rank and rank >= STAFF_MIN_RANK then
                    local roleName = staffRoles[rank] or ("rank " .. tostring(rank))
                    Script.Functions.Alert("[StaffDetector] Staff detected: " .. player.Name .. " (" .. roleName .. ")", 10)
                    Script.Temp.DetectedStaff[player.UserId] = {Name = player.Name, Role = roleName}
                    return true
                end
                return false
            end
            Script.Temp.StaffDetectorConnections = Script.Temp.StaffDetectorConnections or {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    checkPlayerStaff(player)
                end
            end
            Script.Temp.StaffDetectorConnections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
                if player ~= localPlayer then
                    task.wait(1)
                    checkPlayerStaff(player)
                end
            end)
            Script.Temp.StaffDetectorConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
                local staffInfo = Script.Temp.DetectedStaff and Script.Temp.DetectedStaff[player.UserId]
                if staffInfo then
                    Script.Functions.Alert("[StaffDetector] Staff left: " .. staffInfo.Name .. " (" .. staffInfo.Role .. ")", 10)
                    Script.Temp.DetectedStaff[player.UserId] = nil
                end
            end)
        else
            if Script.Temp.StaffDetectorConnections then
                for _, conn in pairs(Script.Temp.StaffDetectorConnections) do
                    pcall(function() conn:Disconnect() end)
                end
                Script.Temp.StaffDetectorConnections = nil
            end
            Script.Temp.DetectedStaff = nil
            Script.Functions.Alert("[StaffDetector] Staff detection disabled.", 3)
        end
    end)
end

local PerformanceGroupBox = Tabs.Misc:AddRightGroupbox("Performance", "gauge") do
    PerformanceGroupBox:AddToggle("LowGFX", {
        Text = "Low GFX",
        Default = false
    }):OnChanged(function(call)
        if call then 
            Script.Temp.LowGFX_Originals = Script.Temp.LowGFX_Originals or {}
            local Terrain = workspace:FindFirstChildOfClass('Terrain')
            if Terrain then
                Script.Temp.LowGFX_Originals.Terrain = {
                    WaterWaveSize = Terrain.WaterWaveSize,
                    WaterWaveSpeed = Terrain.WaterWaveSpeed,
                    WaterReflectance = Terrain.WaterReflectance,
                    WaterTransparency = Terrain.WaterTransparency
                }
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
            end
            Script.Temp.LowGFX_Originals.Lighting = {
                GlobalShadows = Lighting.GlobalShadows,
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart
            }
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.FogStart = 9e9
            pcall(function()
                Script.Temp.LowGFX_Originals.QualityLevel = settings().Rendering.QualityLevel
                settings().Rendering.QualityLevel = 1
            end)
            Script.Temp.LowGFX_Originals.BaseParts = {}
            for i,v in pairs(game:GetDescendants()) do
                if v:IsA("BasePart") then
                    Script.Temp.LowGFX_Originals.BaseParts[v] = {
                        Material = v.Material,
                        Reflectance = v.Reflectance,
                        BackSurface = v.BackSurface,
                        BottomSurface = v.BottomSurface,
                        FrontSurface = v.FrontSurface,
                        LeftSurface = v.LeftSurface,
                        RightSurface = v.RightSurface,
                        TopSurface = v.TopSurface
                    }
                    v.Material = "Plastic"
                    v.Reflectance = 0
                    v.BackSurface = "SmoothNoOutlines"
                    v.BottomSurface = "SmoothNoOutlines"
                    v.FrontSurface = "SmoothNoOutlines"
                    v.LeftSurface = "SmoothNoOutlines"
                    v.RightSurface = "SmoothNoOutlines"
                    v.TopSurface = "SmoothNoOutlines"
                elseif v:IsA("Decal") then
                    Script.Temp.LowGFX_Originals[v] = v.Transparency
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    Script.Temp.LowGFX_Originals[v] = v.Lifetime
                    v.Lifetime = NumberRange.new(0)
                end
            end
            Script.Temp.LowGFX_Originals.PostEffects = {}
            for i,v in pairs(Lighting:GetDescendants()) do
                if v:IsA("PostEffect") then
                    Script.Temp.LowGFX_Originals.PostEffects[v] = v.Enabled
                    v.Enabled = false
                end
            end
            Script.Temp.LowGFX_DescendantConn = workspace.DescendantAdded:Connect(function(child)
                task.spawn(function()
                    if child:IsA('ForceField') or child:IsA('Sparkles') or child:IsA('Smoke') or child:IsA('Fire') or child:IsA('Beam') then
                        RunService.Heartbeat:Wait()
                        child:Destroy()
                    end
                end)
            end)
        else
            local Terrain = workspace:FindFirstChildOfClass('Terrain')
            if Terrain and Script.Temp.LowGFX_Originals and Script.Temp.LowGFX_Originals.Terrain then
                Terrain.WaterWaveSize = Script.Temp.LowGFX_Originals.Terrain.WaterWaveSize
                Terrain.WaterWaveSpeed = Script.Temp.LowGFX_Originals.Terrain.WaterWaveSpeed
                Terrain.WaterReflectance = Script.Temp.LowGFX_Originals.Terrain.WaterReflectance
                Terrain.WaterTransparency = Script.Temp.LowGFX_Originals.Terrain.WaterTransparency
            end
            if Script.Temp.LowGFX_Originals and Script.Temp.LowGFX_Originals.Lighting then
                Lighting.GlobalShadows = Script.Temp.LowGFX_Originals.Lighting.GlobalShadows
                Lighting.FogEnd = Script.Temp.LowGFX_Originals.Lighting.FogEnd
                Lighting.FogStart = Script.Temp.LowGFX_Originals.Lighting.FogStart
            end
            pcall(function()
                if Script.Temp.LowGFX_Originals and Script.Temp.LowGFX_Originals.QualityLevel then
                    settings().Rendering.QualityLevel = Script.Temp.LowGFX_Originals.QualityLevel
                end
            end)
            if Script.Temp.LowGFX_Originals and Script.Temp.LowGFX_Originals.BaseParts then
                for v, props in pairs(Script.Temp.LowGFX_Originals.BaseParts) do
                    if v and v.Parent then
                        v.Material = props.Material
                        v.Reflectance = props.Reflectance
                        v.BackSurface = props.BackSurface
                        v.BottomSurface = props.BottomSurface
                        v.FrontSurface = props.FrontSurface
                        v.LeftSurface = props.LeftSurface
                        v.RightSurface = props.RightSurface
                        v.TopSurface = props.TopSurface
                    end
                end
            end
            if Script.Temp.LowGFX_Originals then
                for v, val in pairs(Script.Temp.LowGFX_Originals) do
                    if typeof(v) == "Instance" and v:IsA("Decal") then
                        v.Transparency = val
                    elseif typeof(v) == "Instance" and (v:IsA("ParticleEmitter") or v:IsA("Trail")) then
                        v.Lifetime = val
                    end
                end
            end
            if Script.Temp.LowGFX_Originals and Script.Temp.LowGFX_Originals.PostEffects then
                for v, enabled in pairs(Script.Temp.LowGFX_Originals.PostEffects) do
                    if v and v.Parent then
                        v.Enabled = enabled
                    end
                end
            end
            if Script.Temp.LowGFX_DescendantConn then
                Script.Temp.LowGFX_DescendantConn:Disconnect()
                Script.Temp.LowGFX_DescendantConn = nil
            end
            Script.Temp.LowGFX_Originals = nil
        end
    end)
    PerformanceGroupBox:AddToggle("DisableEffects", {
        Text = "Disable Effects",
        Default = false
    })
    function Script.Functions.SafeCleanEffects()
        if not workspace:FindFirstChild("Effects") then return end
        for _, v in pairs(workspace.Effects:GetDescendants()) do
            if v.ClassName ~= "Folder" then
                pcall(function()
                    v:Destroy()
                end)
            end
        end
    end
    Toggles.DisableEffects:OnChanged(function(call)
        if call then
            local Effects = workspace:WaitForChild("Effects", 15)
            if not Effects then return end
            Effects:ClearAllChildren()
            Script.Temp.DisableEffectsConnection = Effects.ChildAdded:Connect(function(child)
                if child.ClassName == "Folder" then return end
                pcall(function()
                    child:Destroy()
                    Script.Functions.SafeCleanEffects()
                end)
            end)
        else
            if Script.Temp.DisableEffectsConnection then
                pcall(function()
                    Script.Temp.DisableEffectsConnection:Disconnect()
                end)
                Script.Temp.DisableEffectsConnection = nil
            end
        end
    end)
    PerformanceGroupBox:AddButton("Clear Effects", function()
        if workspace:FindFirstChild("Effects") then
            Script.Functions.SafeCleanEffects()
        end
    end)
end

Library:GiveSignal(lplr.CharacterAdded:Connect(function(char)
    if not Toggles.SpeedToggle.Value then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    hum.WalkSpeed = Options.SpeedSlider.Value
end))

local lastCleanupFunction = function() end

pcall(function()
    Script.GameState = workspace.Values.CurrentGame.Value
end)

local function setNoclip(state)
    if Toggles.Noclip.Value ~= state then
        Toggles.Noclip:SetValue(state)
    end
end

function Script.Functions.HandleAutowin()
    if lastCleanupFunction then
        pcall(lastCleanupFunction)
    end
    setNoclip(false)

    pcall(function()
        Script.GameState = workspace.Values.CurrentGame.Value
    end)

    if States[Script.GameState] then
        Script.Functions.Alert("[Autowin]: Running on "..tostring(Script.GameState))
        task.spawn(function()
            Script.Functions.EffectsNotification("[Autowin]: Running on "..tostring(Script.GameState), 10)
        end)
        lastCleanupFunction = States[Script.GameState]()
    else
        task.spawn(function()
            Script.Functions.EffectsNotification("[Autowin]: Waiting for the next game...", 10)
        end)
        Script.Functions.Alert("[Autowin]: Waiting for the next game...")
    end
end

States = {
    RedLightGreenLight = function()
        local call = true
        task.spawn(function()
            repeat
                Script.Functions.WinRLGL()
                task.wait(5)
            until not call or not Toggles.InkGameAutowin.Value or Script.GameState ~= "RedLightGreenLight"
        end)
        if not Toggles.AntiFlingToggle.Value then
            Toggles.AntiFlingToggle:SetValue(true)
        end
        return function()
            call = false
            if Toggles.AntiFlingToggle.Value then
                Toggles.AntiFlingToggle:SetValue(false)
            end
        end
    end,
    Mingle = function()
        if not Toggles.AutoMingleQTE.Value then
            Toggles.AutoMingleQTE:SetValue(true)
        end
        return function()
            if Toggles.AutoMingleQTE.Value then
                Toggles.AutoMingleQTE:SetValue(false)
            end
        end
    end,
    TugOfWar = function()
        if not Toggles.AutoPull.Value then
            Toggles.AutoPull:SetValue(true)
        end
        if not Toggles.PerfectPull.Value then
            Toggles.PerfectPull:SetValue(true)
        end

        return function()
            if Toggles.AutoPull.Value then
                Toggles.AutoPull:SetValue(false)
            end
        end
    end,
    GlassBridge = function()
        task.spawn(function()
            Script.Functions.RevealGlassBridge()
        end)
        local call = true
        task.spawn(function()
            task.wait(15)
            repeat
                Script.Functions.WinGlassBridge()
                task.wait(3)
            until not call or not Toggles.InkGameAutowin.Value or Library.Unloaded
        end)
        return function()
            call = false
        end
    end,
    HideAndSeek = function()
        if lplr:GetAttribute("IsHider") then
            Script.Functions.ToggleTPTSP()
        else
            Script.Functions.Alert("[Autowin]: Hide and Seek support for Seekers soon...")
        end
    end,
    LightsOut = Script.Functions.ToggleTPTSP,
    Dalgona = function()
        task.spawn(function()
            repeat task.wait() until Script.Functions.GetDalgonaRemote() or not Toggles.InkGameAutowin.Value or Library.Unloaded
            if not Toggles.InkGameAutowin.Value then return end
            task.wait(3)
            Script.Functions.CompleteDalgonaGame()
            Script.Functions.BypassDalgonaGame()
            Script.Functions.RestartRemotesScript()
        task.spawn(function()
            repeat 
                task.wait(1)
                Script.Functions.CheckPlayersVisibility()
            until not Script.Functions.GetDalgonaRemote()
        end)
            task.delay(3, function()
                Script.Functions.CompleteDalgonaGame()
                Script.Functions.BypassDalgonaGame()
                Script.Functions.RestartRemotesScript()
            end)
        end)

        return function()
            Script.Functions.CheckPlayersVisibility()
        end
    end,
    JumpRope = function()
        local call = true
        task.spawn(function()
            task.wait(15)
            repeat
                Script.Functions.WinJumpRope()
                task.wait(3)
            until not call or not Toggles.InkGameAutowin.Value or Library.Unloaded
        end)
        return function()
            call = false
        end
    end
}

Library:GiveSignal(workspace:WaitForChild("Values"):WaitForChild("CurrentGame"):GetPropertyChangedSignal("Value"):Connect(function()
    Script.GameState = workspace.Values.CurrentGame.Value
    Script.GameStateChanged:Fire(Script.GameState)

    if not Script.GameState then return end
    Script.GameState = tostring(Script.GameState)

    if Toggles.InkGameAutowin.Value then
        Script.Functions.HandleAutowin()
    end

    if string.find(Script.GameState, "HideAndSeek") then
        for _, meta in pairs(ESP_META) do
            if not Toggles[meta.metaName] then continue end
            if Toggles[meta.metaName].Value then
                Toggles[meta.metaName]:SetValue(false)
                Toggles[meta.metaName]:SetValue(true)
            end
        end
        for _, espType in pairs(Script.ESPTable.Key) do
            if not espType.Destroy then continue end
            pcall(espType.Destroy)
        end
    end
end))

Toggles.AutoPull:OnChanged(function(call)
    if call then
        task.spawn(function()
            repeat
                Script.Functions.PullRope(Toggles.PerfectPull.Value)
                task.wait()
            until not Toggles.AutoPull.Value or Library.Unloaded
        end)
    end
end)

function Script.Functions.SkipDialogue()
    local args = {
        "Skipped"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DialogueRemote"):FireServer(unpack(args))    
end

local Useful = Tabs.Other:AddRightGroupbox("Useful Stuff", "star") do
    Useful:AddToggle("AutoSkipDialog", {
        Text = "Auto Skip Dialogue",
        Default = false
    }):OnChanged(function(call)
        if call then
            Script.Temp.AutoSkipDialogLoop = task.spawn(function()
                local lplr = game:GetService("Players").LocalPlayer
                local PlayerGui = lplr:FindFirstChild("PlayerGui")
                local DialogueFrameAnnouncement = PlayerGui and PlayerGui:FindFirstChild("DialogueGUI") and PlayerGui.DialogueGUI:FindFirstChild("DialogueFrameAnnouncement")
                while Toggles.AutoSkipDialog.Value and not Library.Unloaded do
                    if lplr:GetAttribute("_DialogueOpen") or (DialogueFrameAnnouncement and DialogueFrameAnnouncement.Visible) then
                        Script.Functions.SkipDialogue()
                    end
                    task.wait(1)
                end
            end)
        else
            if Script.Temp.AutoSkipDialogLoop then
                task.cancel(Script.Temp.AutoSkipDialogLoop)
                Script.Temp.AutoSkipDialogLoop = nil
            end
        end
    end)

    Useful:AddToggle("FullbrightToggle", {
        Text = "Fullbright",
        Default = false
    }):OnChanged(function(enabled)
        Script.Temp.FullbrightSettings = Script.Temp.FullbrightSettings or {}
        Script.Temp.FullbrightConn = Script.Temp.FullbrightConn or nil
        if enabled then
            local settings = Script.Temp.FullbrightSettings
            settings.Brightness = Lighting.Brightness
            settings.ClockTime = Lighting.ClockTime
            settings.FogEnd = Lighting.FogEnd
            settings.GlobalShadows = Lighting.GlobalShadows
            settings.OutdoorAmbient = Lighting.OutdoorAmbient
            settings.Ambient = Lighting.Ambient
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            if Script.Temp.FullbrightConn then
                Script.Temp.FullbrightConn:Disconnect()
            end
            Script.Temp.FullbrightConn = Lighting.Changed:Connect(function()
                if not Toggles.FullbrightToggle.Value then return end
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            end)
        else
            local settings = Script.Temp.FullbrightSettings or {}
            for k, v in pairs(settings) do
                Lighting[k] = v
            end
            if Script.Temp.FullbrightConn then
                Script.Temp.FullbrightConn:Disconnect()
                Script.Temp.FullbrightConn = nil
            end
        end
    end)
end

local votes = {"StopPlaying", "KeepPlaying"}
function Script.Functions.CastVote(vote)
    local args = {
        {
            Voting = vote
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ExtraTemporaryRemote"):FireServer(unpack(args))
end

local AutoVoteGroup = Tabs.Other:AddRightGroupbox("Auto Vote") do
    AutoVoteGroup:AddToggle("AutoVoteToggle", {
        Text = "Auto Vote",
        Default = false
    })
    AutoVoteGroup:AddDropdown("VoteOptions", {
        Text = "Vote Options",
        Values = votes,
        Default = "KeepPlaying"
    })
end

local AntiDeathGroup = Tabs.Other:AddRightGroupbox("Anti Death", "skull") do
    AntiDeathGroup:AddToggle("AntiDeathToggle", {
        Text = "Anti Death",
        Default = false
    })

    AntiDeathGroup:AddSlider("AntiDeathHealthThreshold", {
        Text = "Health Threshold",
        Default = 30,
        Min = 10,
        Max = 90,
        Rounding = 1
    })
    
    Script.Temp.AntiDeathTPToggled = false
    Toggles.AntiDeathToggle:OnChanged(function(call)
        if call then
            Script.Temp.AntiDeathTask = task.spawn(function()
                repeat
                    task.wait()
                    if lplr.Character then
                        local hum = lplr.Character:FindFirstChildOfClass("Humanoid")
                        if not hum then return end
                        if hum.Health <= Options.AntiDeathHealthThreshold.Value then
                            if Script.Temp.AntiDeathTPToggled then return end
                            if Toggles.PlayerAttachToggle and Toggles.PlayerAttachToggle.Value then
                                Toggles.PlayerAttachToggle:SetValue(false)
                            else
                                Script.Temp.AntiDeathTPToggled = true
                            end
                            Script.Functions.ToggleTPTSP()
                        else
                            if Toggles.TeleportToSafePlace.Value and Script.Temp.AntiDeathTPToggled then
                                Toggles.TeleportToSafePlace:SetValue(false)
                            end
                        end
                    end
                until not Toggles.AntiDeathToggle.Value or Library.Unloaded
            end)    
        else
            if Script.Temp.AntiDeathTask then
                task.cancel(Script.Temp.AntiDeathTask)
                Script.Temp.AntiDeathTask = nil
            end
        end
    end)
end

local InteractionGroup = Tabs.Other:AddLeftGroupbox("Interaction", "hand-pointer") do
    InteractionGroup:AddToggle("NoInteractDelay", {
        Text = "Instant Interact",
        Default = false
    })
    InteractionGroup:AddSlider("PromptReachSlider", {
        Text = "Interaction Reach Multiplier",
        Default = 1.5,
        Min = 1,
        Max = 2,
        Rounding = 1
    })
    InteractionGroup:AddToggle("PromptReachToggle", {
        Text = "Interaction Reach",
        Default = false
    })

    Script.Temp.ActivePrompts = {}

    local function updateAllPrompts()
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                if not Script.Temp.ActivePrompts[prompt] then
                    Script.Temp.ActivePrompts[prompt] = prompt.MaxActivationDistance
                end
                if Toggles.PromptReachToggle.Value then
                    prompt.MaxActivationDistance = Script.Temp.ActivePrompts[prompt] * Options.PromptReachSlider.Value
                else
                    prompt.MaxActivationDistance = Script.Temp.ActivePrompts[prompt]
                end
            end
        end
    end

    Options.PromptReachSlider:OnChanged(function(val)
        if not Toggles.PromptReachToggle.Value then return end
        for _, prompt in pairs(Script.Temp.ActivePrompts) do
            if prompt:IsA("ProximityPrompt") then
                if not Script.Temp.ActivePrompts[prompt] then
                    Script.Temp.ActivePrompts[prompt] = prompt.MaxActivationDistance
                end
                if Toggles.PromptReachToggle.Value then
                    prompt.MaxActivationDistance = Script.Temp.ActivePrompts[prompt] * Options.PromptReachSlider.Value
                else
                    prompt.MaxActivationDistance = Script.Temp.ActivePrompts[prompt]
                end
            end
        end
    end)

    Toggles.PromptReachToggle:OnChanged(function(enabled)
        updateAllPrompts()
    end)

    Library:GiveSignal(workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ProximityPrompt") then
            Script.Temp.ActivePrompts[obj] = obj.MaxActivationDistance
            if Toggles.PromptReachToggle.Value then
                obj.MaxActivationDistance = Script.Temp.ActivePrompts[obj] * Options.PromptReachSlider.Value
            end
            obj.Destroying:Once(function()
                if Script.Temp.ActivePrompts[obj] then
                    Script.Temp.ActivePrompts[obj] = nil
                end
            end)
        end
    end))
end

local PlayerAttachGroupBox = Tabs.Other:AddLeftGroupbox("Player Attach", "users-round") do
    PlayerAttachGroupBox:AddToggle("PlayerAttachToggle", {
        Text = "Player Attach",
        Default = false
    }):AddKeyPicker("PAT", {
        Mode = "Toggle",
        Default = "K",
        Text = "Player Attach",
        SyncToggleState = true
    })
    PlayerAttachGroupBox:AddSlider("PlayerAttachRange", {
        Text = "Attach Range",
        Default = 50,
        Min = 1,
        Max = 100,
        Rounding = 1
    })
    PlayerAttachGroupBox:AddDropdown("PlayerAttachMovementType", {
        Text = "Movement Type",
        Values = {"Teleport", "Tween", "Velocity"},
        Default = "Tween"
    })
    PlayerAttachGroupBox:AddSlider("PlayerAttachTweenDuration", {
        Text = "Tween Duration",
        Default = 3,
        Min = 1,
        Max = 10,
        Rounding = 1
    })
    PlayerAttachGroupBox:AddToggle("PlayerAttachBehindTarget", {
        Text = "Stay Behind Target",
        Default = false
    })
    PlayerAttachGroupBox:AddSlider("PlayerAttachBehindDistance", {
        Text = "Behind Distance",
        Default = 3,
        Min = 1,
        Max = 10,
        Rounding = 1
    })

    Toggles.PlayerAttachToggle:OnChanged(function(call)
        if call then
            Script.Temp.PlayerAttachActive = true
            task.spawn(function()
                local lastUpdate = 0
                local updateInterval = 0.05
                while Script.Temp.PlayerAttachActive and not Library.Unloaded do
                    local currentTime = tick()
                    if currentTime - lastUpdate >= updateInterval then
                        if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then
                            task.wait(0.1)
                            lastUpdate = currentTime
                            continue
                        end
                        local players = Players:GetPlayers()
                        local closestPlayer = nil
                        local closestDistance = Options.PlayerAttachRange.Value
                        for _, player in pairs(players) do
                            if player ~= lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                                local distance = (player.Character.HumanoidRootPart.Position - lplr.Character.HumanoidRootPart.Position).Magnitude
                                if distance < closestDistance then
                                    closestPlayer = player
                                    closestDistance = distance
                                end
                            end
                        end
                        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local rootPart = lplr.Character.HumanoidRootPart
                            local targetRoot = closestPlayer.Character.HumanoidRootPart
                            local finalCFrame = targetRoot.CFrame
                            if Toggles.PlayerAttachBehindTarget.Value then
                                local targetLookVector = targetRoot.CFrame.LookVector
                                local behindPosition = targetRoot.Position - (targetLookVector * Options.PlayerAttachBehindDistance.Value)
                                finalCFrame = CFrame.new(behindPosition, targetRoot.Position)
                            end
                            local moveType = Options.PlayerAttachMovementType.Value
                            if moveType == "Teleport" then
                                rootPart.CFrame = finalCFrame
                            elseif moveType == "Tween" then
                                local tweenInfo = TweenInfo.new(Options.PlayerAttachTweenDuration.Value / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                                local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = finalCFrame})
                                tween:Play()
                            elseif moveType == "Velocity" then
                                local direction = (finalCFrame.Position - rootPart.Position).Unit
                                local distance = (finalCFrame.Position - rootPart.Position).Magnitude
                                local speed = math.min(distance * 2, 50)
                                rootPart.Velocity = direction * speed
                            end
                            lastUpdate = currentTime
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else
            Script.Temp.PlayerAttachActive = false
        end
    end)
end

Library:GiveSignal(ProximityPromptService.PromptShown:Connect(function(prompt)
    if Toggles.NoInteractDelay.Value then
        prompt.HoldDuration = 0
    end
    if Toggles.AutoSteal and Toggles.AutoSteal.Value then
        if prompt.Name == "StealPrompt" then
            prompt.HoldDuration = 0
            fireproximityprompt(prompt, 1)
        end
    end
end))

Library:GiveSignal(UserInputService.JumpRequest:Connect(function()
    if Toggles.InfiniteJump.Value then
        if not lplr.Character then return end
        if not lplr.Character:FindFirstChild("Humanoid") then return end
        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

for _, player in pairs(Players:GetPlayers()) do
    if player == localPlayer then continue end
    Script.Functions.SetupOtherPlayerConnection(player)
end

Library:GiveSignal(Players.PlayerAdded:Connect(function(player)
    if player == localPlayer then return end
    Script.Functions.SetupOtherPlayerConnection(player)
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
task.spawn(function() pcall(Script.Functions.OnLoad) end)

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
            if conn.Disconnect then
                conn:Disconnect()
            elseif conn.Destroy then
                conn:Destroy()
            else
                conn:Disconnect()
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
    pcall(Script.Functions.RevertAntiFlingDetection)
    pcall(Script.Functions.TeleportBackFromSafe)
    pcall(Script.Functions.CleanAntiVoid)
    Library.Unloaded = true
    getgenv().itoshi_hub_loaded = false
    shared.itoshi_hub_InkGame_Library = nil
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "menu")
local CreditsGroup = Tabs["UI Settings"]:AddRightGroupbox("Credits", "code-xml")

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = false, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind

CreditsGroup:AddLabel("Made by Itoshi")
CreditsGroup:AddLabel("Version: 2.0")
CreditsGroup:AddLabel("Itoshi Hub - Ink Game")
CreditsGroup:AddButton("Copy Discord", function()
    setclipboard("https://discord.gg/ePV8YQ8U67")
    Library:Notify("Discord link copied!", 3)
end)
