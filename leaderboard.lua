-- This is a leaderboard script, the name explains what it does, ordered datastores.

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("DataA22.830")
local KDLeaderboard = DataStoreService:GetOrderedDataStore("KDLeaderboardA22.56")
local GCLeaderboard = DataStoreService:GetOrderedDataStore("GCLeaderboardA23.56")

local Players = game:GetService("Players")

game.Players.PlayerAdded:Connect(function(player: Player) 
	repeat wait(5) until player:FindFirstChild("PlayerData") ~= nil
	task.wait(5)
	
	while true do
		saveData(player)
		task.wait(15)
	end
	
end)

game.Players.PlayerRemoving:Connect(function(player: Player) 
	saveData(player)
end)
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

function saveData(player: Player)
	local PlayerData = player:WaitForChild("PlayerData")

	local Coins = PlayerData:WaitForChild("coins")
	local Gems = PlayerData:WaitForChild("gems")
	local Kills = PlayerData:WaitForChild("ServerKills")

	local success, result = pcall(function()
		KDLeaderboard:SetAsync(player.UserId, Kills.Value)
		GCLeaderboard:SetAsync(player.UserId, Coins.Value + Gems.Value)
	end)
end

function ClearOld(leaderboard: Model)
	for _, frame in pairs(leaderboard.SurfaceGui.Frame:GetChildren()) do
		if frame.Name == "Template" then
			frame:Destroy()
		end
	end
end

function GetDisplayName(userId)
	local UserService = game:GetService("UserService")

	local success, UserInfo = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync({userId})
	end)

	if success then
		return UserInfo[1].DisplayName 
	else
		warn("Failed to retrieve user info:", UserInfo)
		return "Error"
	end
end

function GetUserData(UserId)
	local format = UserId.."-data"
	
	local data
	local success, result = pcall(function()
		data = DataStore:GetAsync(format)
	end)
	
	if success and data then
		return data
	end
end

function CloneFrame(leaderboard, UserId, info)
	local data = GetUserData(UserId)
	local Frame = leaderboard.SurfaceGui.Frame

	if leaderboard.Name == "KD_Leaderboard" then
		local clone = Frame.UIGridLayout.Template:Clone()
		clone.KillsLabel.Text = tostring("Kills: "..data.serverkills)
		clone.DeathLabel.Text = tostring("Deaths: "..data.totaldeaths)
		
		clone.Username.Text = info.DisplayName
		clone.ldname.Text = info.UserName
		
		clone.ImageLabel.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..UserId.."&width=420&height=420&format=png"
		clone.Parent = Frame
		
	else
		local clone = Frame.UIGridLayout.Template:Clone()
		clone.CoinLabel.Text = tostring("Coins: "..data.coins)
		clone.GemLabel.Text = tostring("Gems: "..data.gems)

		clone.Username.Text = info.DisplayName
		clone.ldname.Text = info.UserName
		
	
		clone.ImageLabel.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..UserId.."&width=420&height=420&format=png"
		clone.Parent = Frame
		
	end
end

function Init(store: OrderedDataStore, leaderboard)
	spawn(function()
		while true do
			warn(leaderboard.Name)
			ClearOld(leaderboard)
			local a = {}
			local success, result = pcall(function()
				return store:GetSortedAsync(false, 10, 1):GetCurrentPage()
			end)

			if success then
				for i, v in pairs(result) do
					table.insert(a, {v.key, tostring(i), v.value})
				end

				for i, v in pairs(a) do
					local userId = v[1]
					local rank = v[2]
					local value = v[3]
					warn(userId, rank, value)
					local params = {
						UserName = Players:GetNameFromUserIdAsync(userId),
						DisplayName = GetDisplayName(tonumber(userId))
					}
					CloneFrame(leaderboard, userId, params) 
					
				end

				wait(30)
			else
				warn("Issue fetching leaderboard.")
			end
		end
	end)
end

Init(KDLeaderboard, workspace.KD_Leaderboard)
Init(GCLeaderboard, workspace.GemCoinLeaderboard)
