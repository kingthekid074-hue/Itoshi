--!native
--!optimize 2
--!strict
--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local t_insert = table.insert
local t_remove = table.remove
local t_clear = table.clear
local s_clock = os.clock
local s_spawn = task.spawn
local s_wait = task.wait
local s_delay = task.delay
local m_min = math.min
local m_max = math.max

local CONSTANTS = {
	BURST_RATE = 20,
	FRAME_BUDGET = 0.012,
	RETRY_CAP = 4,
	BACKOFF_BASE = 0.25,
	REMOTE_KEY = "REMOTE_FUNCTION"
}

local function FastQueue()
	local queue = {
		_head = 1,
		_tail = 0,
		_data = table.create(500)
	}
	
	function queue:Push(val)
		self._tail += 1
		self._data[self._tail] = val
	end
	
	function queue:Pop()
		if self._head > self._tail then return nil end
		local val = self._data[self._head]
		self._data[self._head] = nil
		self._head += 1
		return val
	end
	
	function queue:Len()
		return self._tail - self._head + 1
	end
	
	return queue
end

local TaskManager = {}
TaskManager.__index = TaskManager

function TaskManager.new(network)
	local self = setmetatable({}, TaskManager)
	self._net = network
	self._highQ = FastQueue()
	self._normQ = FastQueue()
	self._active = false
	self._pending = 0
	return self
end

function TaskManager:Dispatch(method, remoteType, args, priority)
	local payload = {
		m = method,
		t = remoteType,
		a = args,
		r = 0
	}
	
	if priority then
		self._highQ:Push(payload)
	else
		self._normQ:Push(payload)
	end
	
	if not self._active then
		self._active = true
		s_spawn(function() self:_Loop() end)
	end
end

function TaskManager:_Loop()
	while self._highQ:Len() > 0 or self._normQ:Len() > 0 do
		local start = s_clock()
		local processed = 0
		
		while (s_clock() - start < CONSTANTS.FRAME_BUDGET) and processed < CONSTANTS.BURST_RATE do
			local job = self._highQ:Pop() or self._normQ:Pop()
			if not job then break end
			
			processed += 1
			s_spawn(function()
				local s, e = pcall(function()
					return self._net:FireServerConnection(job.m, job.t, unpack(job.a))
				end)
				
				if not s and job.r < CONSTANTS.RETRY_CAP then
					job.r += 1
					s_delay(CONSTANTS.BACKOFF_BASE * job.r, function()
						self._highQ:Push(job)
					end)
				end
			end)
		end
		RunService.Heartbeat:Wait()
	end
	self._active = false
end

local AssetScanner = {}
AssetScanner.__index = AssetScanner

function AssetScanner.new(manager)
	local self = setmetatable({}, AssetScanner)
	self._mgr = manager
	self._pData = Players.LocalPlayer:WaitForChild("PlayerData", 30)
	self._owned = self._pData:WaitForChild("Purchased", 30)
	self._root = ReplicatedStorage:WaitForChild("Assets")
	self._cache = {}
	return self
end

function AssetScanner:Check(cat, item)
	local k = cat .. item
	if self._cache[k] then return true end
	
	local f = self._owned:FindFirstChild(cat)
	if f and f:FindFirstChild(item) then
		self._cache[k] = true
		return true
	end
	return false
end

function AssetScanner:Validate(mod)
	if not mod:IsA("ModuleScript") then return false end
	local s, r = pcall(require, mod)
	return s and type(r) == "table" and not r.Exclusive
end

function AssetScanner:Run(cat, rec)
	local f = self._root:FindFirstChild(cat)
	if not f then return end
	
	local items = rec and f:GetDescendants() or f:GetChildren()
	local batch = 0
	
	for _, v in ipairs(items) do
		if batch > 50 then
			batch = 0
			RunService.Heartbeat:Wait()
		end
		
		if v:IsA("ModuleScript") then
			local isCfg = (rec and v.Name == "Config") or (not rec)
			if isCfg then
				local target = rec and v.Parent or v
				if target then
					if self:Validate(v) and not self:Check(cat, target.Name) then
						self._mgr:Dispatch("PurchaseContent", CONSTANTS.REMOTE_KEY, {target}, false)
					end
				end
			end
		end
		batch += 1
	end
end

function AssetScanner:UnlockRows()
	local base = {
		"CosmeticRows/SurvivorsRow/Row1/",
		"CosmeticRows/SurvivorsRow/Row2/",
		"CosmeticRows/KillersRow/"
	}
	for _, p in ipairs(base) do
		for i = 1, 7 do
			self._mgr:Dispatch("PurchaseSkinAsync", CONSTANTS.REMOTE_KEY, {p .. i}, true)
		end
	end
end

local function Init()
	if not game:IsLoaded() then game.Loaded:Wait() end
	local net = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"))
	local mgr = TaskManager.new(net)
	local scn = AssetScanner.new(mgr)
	
	local tasks = {
		{"Survivors", true},
		{"Killers", true},
		{"Skins", true},
		{"Emotes", false}
	}
	
	for _, t in ipairs(tasks) do
		s_spawn(function() scn:Run(t[1], t[2]) end)
	end
	
	s_spawn(function() scn:UnlockRows() end)
end

pcall(Init)
