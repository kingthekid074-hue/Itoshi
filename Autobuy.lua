local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local CONSTANTS = {
	BATCH_THRESHOLD = 0.05,
	MAX_CONCURRENCY = 12,
	RETRY_LIMIT = 5,
	EXPONENTIAL_BACKOFF = 1.5,
	GC_CYCLE = 60,
	TIMEOUT = 15,
	REMOTE_KEY = "REMOTE_FUNCTION"
}

local Types = {}
type GenericFunction = (...any) -> ...any
type TaskData = {
	ID: string,
	Fn: GenericFunction,
	Args: {any},
	Retries: number,
	Priority: number,
	Created: number
}

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._bindable = Instance.new("BindableEvent")
	return self
end

function Signal:Connect(callback)
	return self._bindable.Event:Connect(callback)
end

function Signal:Fire(...)
	self._bindable:Fire(...)
end

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue.new()
	local self = setmetatable({}, PriorityQueue)
	self._items = {}
	self._count = 0
	return self
end

function PriorityQueue:Enqueue(item: TaskData)
	table.insert(self._items, item)
	self._count += 1
	table.sort(self._items, function(a, b) 
		return a.Priority > b.Priority 
	end)
end

function PriorityQueue:Dequeue(): TaskData?
	if self._count == 0 then return nil end
	self._count -= 1
	return table.remove(self._items, 1)
end

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(networkModule)
	local self = setmetatable({}, Scheduler)
	self._queue = PriorityQueue.new()
	self._network = networkModule
	self._active = 0
	self._running = false
	self._signal = Signal.new()
	self._completed = {}
	return self
end

function Scheduler:Push(method: string, remoteType: string, ...: any)
	local args = {...}
	self._queue:Enqueue({
		ID = HttpService:GenerateGUID(false),
		Fn = function(...) 
			return self._network:FireServerConnection(method, remoteType, ...) 
		end,
		Args = args,
		Retries = 0,
		Priority = 1,
		Created = os.clock()
	})
	self._signal:Fire()
end

function Scheduler:PushHighPriority(method: string, remoteType: string, ...: any)
	local args = {...}
	self._queue:Enqueue({
		ID = HttpService:GenerateGUID(false),
		Fn = function(...) 
			return self._network:FireServerConnection(method, remoteType, ...) 
		end,
		Args = args,
		Retries = 0,
		Priority = 10,
		Created = os.clock()
	})
	self._signal:Fire()
end

function Scheduler:Start()
	if self._running then return end
	self._running = true
	
	task.spawn(function()
		while self._running do
			if self._active < CONSTANTS.MAX_CONCURRENCY then
				local taskData = self._queue:Dequeue()
				if taskData then
					self._active += 1
					task.spawn(function()
						self:_Execute(taskData)
					end)
				else
					self._signal._bindable.Event:Wait()
				end
			else
				RunService.Heartbeat:Wait()
			end
		end
	end)
end

function Scheduler:_Execute(taskData: TaskData)
	local success, result = pcall(function()
		return taskData.Fn(unpack(taskData.Args))
	end)

	self._active -= 1
	
	if not success then
		taskData.Retries += 1
		if taskData.Retries <= CONSTANTS.RETRY_LIMIT then
			task.delay(CONSTANTS.EXPONENTIAL_BACKOFF * taskData.Retries, function()
				self._queue:Enqueue(taskData)
				self._signal:Fire()
			end)
		end
	else
		self._completed[taskData.ID] = true
	end
end

local AssetController = {}
AssetController.__index = AssetController

function AssetController.new(scheduler)
	local self = setmetatable({}, AssetController)
	self._scheduler = scheduler
	self._player = Players.LocalPlayer
	self._data = self._player:WaitForChild("PlayerData", 30)
	self._purchased = self._data:WaitForChild("Purchased", 30)
	self._assets = ReplicatedStorage:WaitForChild("Assets")
	self._cache = {}
	return self
end

function AssetController:IsOwned(category: string, name: string): boolean
	local key = category .. "::" .. name
	if self._cache[key] then return true end
	
	local catFolder = self._purchased:FindFirstChild(category)
	if not catFolder then return false end
	
	local item = catFolder:FindFirstChild(name)
	if item then
		self._cache[key] = true
		return true
	end
	return false
end

function AssetController:Validate(module: Instance): (boolean, any)
	if not module:IsA("ModuleScript") then return false, nil end
	local s, r = pcall(require, module)
	if not s or type(r) ~= "table" then return false, nil end
	return true, r
end

function AssetController:Scan(category: string, recursive: boolean)
	local root = self._assets:FindFirstChild(category)
	if not root then return end
	
	local iterator = recursive and root:GetDescendants() or root:GetChildren()
	
	for _, item in ipairs(iterator) do
		if item:IsA("ModuleScript") then
			local isConfig = (recursive and item.Name == "Config") or (not recursive)
			if isConfig then
				local target = recursive and item.Parent or item
				if not target then continue end
				
				local valid, data = self:Validate(item)
				if valid and not data.Exclusive then
					if not self:IsOwned(category, target.Name) then
						self._scheduler:Push("PurchaseContent", CONSTANTS.REMOTE_KEY, target)
					end
				end
			end
		end
	end
end

function AssetController:ForceUnlockRows()
	local paths = {
		"CosmeticRows/SurvivorsRow/Row1/",
		"CosmeticRows/SurvivorsRow/Row2/",
		"CosmeticRows/KillersRow/"
	}
	
	for _, basePath in ipairs(paths) do
		for i = 1, 7 do
			local fullPath = basePath .. tostring(i)
			self._scheduler:PushHighPriority("PurchaseSkinAsync", CONSTANTS.REMOTE_KEY, fullPath)
		end
	end
end

local function Initialize()
	if not game:IsLoaded() then game.Loaded:Wait() end
	
	local NetworkModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"))
	local MainScheduler = Scheduler.new(NetworkModule)
	local Controller = AssetController.new(MainScheduler)
	
	MainScheduler:Start()
	
	local Targets = {
		{Name = "Survivors", Recursive = true},
		{Name = "Killers", Recursive = true},
		{Name = "Skins", Recursive = true},
		{Name = "Emotes", Recursive = false}
	}
	
	for _, t in ipairs(Targets) do
		task.defer(function()
			Controller:Scan(t.Name, t.Recursive)
		end)
	end
	
	task.defer(function()
		Controller:ForceUnlockRows()
	end)
end

task.spawn(Initialize)
