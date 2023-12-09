-- This is a flag "system" that I have created for a commission.

local flag = {}
flag.__index = flag

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TeamService = game:GetService("Teams")
local TweenService = game:GetService("TweenService")

local TeamA = game.ReplicatedStorage.CustomTeams.America
local TeamB =  game.ReplicatedStorage.CustomTeams.Ukraine

local TextureA = "http://www.roblox.com/asset/?id=9835648"
local TextureB = "http://www.roblox.com/asset/?id=9835648"
local Uncaptured = "http://www.roblox.com/asset/?id=9835648"
-- TextureId

local DecalA = "rbxasset://textures/ui/GuiImagePlaceholder.png"
local DecalB = "rbxasset://textures/ui/GuiImagePlaceholder.png"
local DecalC = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- For the unpactured decal
-- Team Images

local config = {
	RequiredDistance = 20,
	UnclaimedTransparency = 0.5, -- The transparency of a flag that is not claimed by someone.
	ClaimDuration = 10, -- The time taken to claim a flag.
	PointAmount = 100

}

function flag.new(model: Model)
	local Table = setmetatable({}, flag)

	Table.Model = model
	Table.Flag = model:WaitForChild("Flag"):WaitForChild("FlagTexture")

	Table.BillBoard = model:WaitForChild("BillboardGui")
	Table.ProgressBar = Table.BillBoard:WaitForChild("Bar"):WaitForChild("Progress")

	Table.ProgressValue = 0
	Table.IsCaptured, Table.CapturedTeam = false, ""

	Table.Players = {}

	if not Table.Flag or not Table.BillBoard or not Table.ProgressBar then
		warn("Missing required elements in the model.")
		return nil
	end

	RunService.Heartbeat:Connect(function()
		Table:CheckForNearestPlayer()
	end)

	spawn(function()
		while true do
			task.wait(1)
			for i, v in pairs(Table.Players) do
				Table:CheckPlayersTeams()
			end
		end
	end)
	return Table
end


function flag:CheckForNearestPlayer()
	for _, player in pairs(Players:GetPlayers()) do
		if player:GetAttribute("PlayerTeam") == "Neutral" then
			continue
		end
		local character = player.Character or player.CharacterAdded:Wait()
		local Root = character:WaitForChild("HumanoidRootPart")

		local distance = math.floor((Root.Position - self.Model.PrimaryPart.Position).Magnitude)

		if distance <= config.RequiredDistance then
			if not self.Players[player] then
				self.Players[player] = true
			end
		else
			if self.Players[player] then
				self.Players[player] = nil
			end
		end


	end

end

function flag:CheckPlayersTeams2()
	self.Interupted = false

	local a = false
	local first
	local b = false
	local second

	for player, _ in pairs(self.Players) do
		local Team = player:GetAttribute("PlayerTeam")
		if Team == TeamA.Name then
			first = player
			a = true

		elseif Team == TeamB.Name then
			second = player
			b = true

		end
	end
	
	if a and b then
		self.Interupted = true
	end
	warn(self.Interupted, " SELF.INTERRUPT BRO!!!")

end


function flag:CheckPlayersTeams()
	self.Interupted = false

	local a = false
	local first
	local b = false
	local second

	for player, _ in pairs(self.Players) do
		local Team = player:GetAttribute("PlayerTeam")
		if Team == TeamA.Name then
			first = player
			a = true

		elseif Team == TeamB.Name then
			second = player
			b = true

		end
	end

	if a and not b and self.CapturedTeam ~= TeamA.Name then
		self:UpdateFlagState("Capture", TeamA, TextureA, first)

	elseif b and not a and self.CapturedTeam ~= TeamB.Name then
		self:UpdateFlagState("Capture", TeamB, TextureB, second)

	elseif a and b then
		self.Interupted = true
		self:UpdateFlagState("Uncaptured", Uncaptured)

	elseif not a and not b and not self.IsCaptured then
		self.Interupted = true
		self:UpdateFlagState("Uncaptured", Uncaptured)

	end
end

function flag:FlagUpdateLook(state, plr)
	if state == "Increase" then
		for i = config.ClaimDuration, 0, -1 do
			local tweenInfo = TweenInfo.new(.3, Enum.EasingStyle.Linear)
			local tween = TweenService:Create(self.ProgressBar, tweenInfo, {Size = UDim2.new(self.ProgressValue, 0, 1, 0)})
			self.ProgressValue = self.ProgressValue + 0.1

			delay(0, function()
				self:CheckPlayersTeams2()
			end)
			if self.Interupted or not self.Players[plr] then
				warn("Stopped the progress!!!! INTERRUPT!!")
				tween:Cancel()
				self:ResetValues()
				return false
			end

			tween:Play()
			task.wait(1)

		end
		self.ProgressValue = 1
		return true

	elseif state == "Decrease" then
		self.ProgressValue = 1
		for i = config.ClaimDuration, 0, -1 do
			warn("DECREASED")
			local tweenInfo = TweenInfo.new(.3, Enum.EasingStyle.Linear)
			local tween = TweenService:Create(self.ProgressBar, tweenInfo, {Size = UDim2.new(self.ProgressValue, 0, 1, 0)})
			self.ProgressValue = self.ProgressValue - 0.1

			delay(0, function()
				self:CheckPlayersTeams2()
			end)
			if self.Interupted or not self.Players[plr] then
				self.ProgressValue = 1
				local tween = TweenService:Create(self.ProgressBar, tweenInfo, {Size = UDim2.new(self.ProgressValue, 0, 1, 0)})
				tween:Play()
				if plr:GetAttribute("PlayerTeam") == "America" then
					self.ProgressBar.BackgroundColor3 = game.ReplicatedStorage.CustomTeams.Ukraine.Color.Value
					
				else
					self.ProgressBar.BackgroundColor3 = game.ReplicatedStorage.CustomTeams.America.Color.Value

				end
				return false
			end

			tween:Play()
			task.wait(1)

		end
		local a = self:FlagUpdateLook("Increase", plr)
		if a == false then
			return false
		end
		self.ProgressValue = 0
	end
end


function flag:UpdateFlagState(state, team, txt, plr)
	if state == "Uncaptured" then
		self:ResetValues()
		self.BillBoard.CapturePoint.PointName.Text = "-"
		TweenService:Create(self.ProgressBar, TweenInfo.new(1, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()

	elseif state == "Capture" and team then
		if team ~= Uncaptured then
			self.ProgressBar.BackgroundColor3 = game.ReplicatedStorage.CustomTeams:FindFirstChild(plr:GetAttribute("PlayerTeam")).Color.Value
		elseif team == Uncaptured then
			self.ProgressBar.BackgroundColor3 = Color3.fromRGB(96, 129, 79)
		
		end
		
		local a
		if self.CapturedTeam ~= "" then
			a = self:FlagUpdateLook("Decrease", plr)

		else
			a = self:FlagUpdateLook("Increase", plr)

		end
		if a == false then
			return
		end
		self.Flag.Transparency = 0
		plr.Playerlist.Points.Value += config.PointAmount
		game.ReplicatedStorage.Playerlist:FindFirstChild(plr:GetAttribute("PlayerTeam")).Value += config.PointAmount
	
		self.Flag.TextureID = txt
		self.IsCaptured = true
		self.CapturedTeam = team.Name
		local text = plr:GetAttribute("PlayerTeam")
		local img
		if text == TeamB.Name then
			img = DecalB
		elseif text == TeamA.Name  then
			img = DecalA
		
		end
		self.BillBoard.CapturePoint.PointName.Text = string.sub(text, 1, 1)
		self.BillBoard.CapturePoint.Image = img
		if self.CapturedTeam ~= "" then
			self:Notify()
			
		end
	end
end

function flag:Notify()
	for _, player in pairs(Players:GetPlayers()) do
		local PlayerGui = player.PlayerGui
		local Popup = PlayerGui.Popups.TextLabel
		
		delay(0, function()
			Popup.Text = `{self.CapturedTeam} has captured {self.Model.Name}`
			TweenService:Create(Popup, TweenInfo.new(1), {TextTransparency = 0}):Play()
			wait(5)
			TweenService:Create(Popup, TweenInfo.new(1), {TextTransparency = 1}):Play()
			
		end)

	end
end

function flag:ResetValues()
	TweenService:Create(self.ProgressBar, TweenInfo.new(1, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()
	self.IsCaptured = false
	self.CapturedTeam = ""
	self.ProgressValue = 0
	self.Flag.Transparency = config.UnclaimedTransparency
	self.Flag.TextureID = Uncaptured
	self.BillBoard.CapturePoint.PointName.Text = "-"
	self.BillBoard.CapturePoint.Image = DecalC
end
return flag
