-- This is a qucik quest system that I made for a commission.

local quest = {}
quest.__index = quest

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modules = ReplicatedStorage.Modules

local config = {
	distanceRequired = 45,
	spawnDelay = 10
}

function quest.new(name, SpawnLocation)
	local Table = setmetatable({}, quest)

	local questData = require(modules.questData)
	questData = questData[name]

	Table.Data = questData
	Table.Spawn = SpawnLocation
	
	Table.CanRun = Table:BeforeRun()
	
	Table.AlreadySpawned = false
	Table.SpawnDelay = false

	Table:checkForNearestPlayer()
	return Table
end

function quest:BeforeRun()
	for index, data in pairs(self.Data) do
		if data == nil or data == "" or not workspace:FindFirstChild("NPCs") or not self.Spawn then
			warn("The quest data/files are not available or one of the data is corrupted.")
			return false
		end
	end

	return true
end

function quest:checkForNearestPlayer()
	if not self.CanRun then
		return
	end
	RunService.Heartbeat:Connect(function()
		if self.AlreadySpawned or self.SpawnDelay then
			return
		end

		for _, player in pairs(Players:GetPlayers()) do
			local character = player.Character or player.CharacterAdded:Wait()
			local Root
			pcall(function()
				Root = character:WaitForChild("HumanoidRootPart")
				
			end)

			if not character or not Root then
				continue
			end

			if not self.AlreadySpawned then
				local distance = math.floor((Root.Position - self.Spawn.Position).Magnitude)

				if distance <= config.distanceRequired then
					self:SpawnNPC()
					self.AlreadySpawned = true
				end
			end
		end
	end)
end


function quest:SpawnNPC()
	if not self.CanRun then
		return
	end

	if self.AlreadySpawned then
		return
	end

	local clone = ReplicatedStorage:FindFirstChild("NPCs"):FindFirstChild(self.Data.Enemy):Clone()
	clone.Parent = workspace
	clone:MoveTo(self.Spawn.Position)

	self.Connection = clone.Humanoid.Died:Connect(function()

		self.Connection:Disconnect()
		self.AlreadySpawned = false

		self:SetSpawnDelay()  
		task.wait(3)
		clone:Destroy()
	end)
end

function quest:SetSpawnDelay()
	self.SpawnDelay = true
	delay(config.spawnDelay, function()
		self.SpawnDelay = false
	end)
end


function quest:reward()
	if not self.CanRun then
		return
	end

end

return quest
