-- This is a datastore and some market place service related script, for a lore game that I was working on.

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("Data_A22.7")

local stringData = {"race", "gender", "dan", "Current_Zone", "hairstyle", "haircolor", "HairName"}
local numberData = {"money", "level", "RaceSpins", "GenderSpins"}
local serverComms = game.ReplicatedStorage.ServerComms
local racesFolder = serverComms.races

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = require(ReplicatedStorage.Modules.dataModule)

_G.DataStoreKey = "-main_userData"

local function initializePlayerData(player)
	local folder = Instance.new("Folder", player)
	folder.Name = "PlayerData"

	module.Misc(player)
	
	local data = {}

	for _, stringValueName in pairs(stringData) do
		local dataInstance = Instance.new("StringValue", folder)
		dataInstance.Name = stringValueName
		data[stringValueName] = dataInstance
	end

	for _, numberValueName in pairs(numberData) do
		local dataInstance = Instance.new("NumberValue", folder)
		dataInstance.Name = numberValueName
		data[numberValueName] = dataInstance
	end

	return data
end


game.Players.PlayerAdded:Connect(function(player)
	local flag = false
	player.CharacterAdded:Connect(function(char)
		if flag then return end
		local playerData = player:FindFirstChild("PlayerData")
		if playerData then
			flag = true
			module.PlayerMorph(player, playerData, workspace.SpawnLocation.CFrame)
			flag = false
		end
		wait(1)
		
	end)

	local success, data = pcall(function()
		return DataStore:GetAsync(player.UserId .. "-main_userData")
	end)

	local playerData = player:FindFirstChild("PlayerData") or initializePlayerData(player)

	if success and data then
		for _, stringValueName in pairs(stringData) do
			if data[stringValueName] then
				playerData[stringValueName].Value = data[stringValueName]
			end
		end

		for _, numberValueName in pairs(numberData) do
			if data[numberValueName] then
				playerData[numberValueName].Value = tonumber(data[numberValueName])
			end
		end

		print("Player data is loaded.")
	else
		print("Failed to load player data.")
		warn(data)
		warn(debug.traceback())
		module.randomData(playerData)
	end

	flag = true
	module.PlayerMorph(player, playerData, workspace.SpawnLocation.CFrame)
	flag = false
end)

function saveData(player)
	local playerData = player:FindFirstChild("PlayerData")
	if not playerData then
		return
	end

	local dataToSave = {}

	for _, stringValueName in pairs(stringData) do
		dataToSave[stringValueName] = playerData[stringValueName].Value
	end

	for _, numberValueName in pairs(numberData) do
		dataToSave[numberValueName] = playerData[numberValueName].Value
	end

	local success, fail = pcall(function()
		DataStore:SetAsync(player.UserId.."-main_userData", dataToSave)
	end)

	if success then
		print("Player data is saved.")
	else
		print("Failed to save player data.")
		warn(fail)
	end
end

game.Players.PlayerRemoving:Connect(function(player)
	saveData(player)
end)

game:BindToClose(function()
	for _, player in pairs(game.Players:GetPlayers()) do
		saveData(player)
	end
end)


local function setRarityText(frame, rarity)
	local rarityData = ReplicatedStorage.ServerComms.races:FindFirstChild(rarity)
	local rarityName = rarityData.RarityName.Value
	local rarityValue = rarityData.Rarity.Value

	frame.Rarity.Text = rarityName
	frame:WaitForChild("Rarity_Precentage").Text = "%" .. rarityValue

	local color3
	if rarityName == "Epic" then
		color3 = Color3.fromRGB(255, 29, 33)
	elseif rarityName == "Rare" then
		color3 = Color3.fromRGB(0, 255, 30)
	else
		color3 = Color3.fromRGB(140, 140, 140)  
	end
	frame.Rarity.TextColor3 = color3
end

local function getRandomRaceData()
	local races = ReplicatedStorage.ServerComms.races:GetChildren()
	return races[math.random(1, #races)].Name
end

local function rerollRace(player: Player)
	local mainRace = module.getRandomRace(player)
	local frame = player.PlayerGui:WaitForChild("MainMenu").RaceSpin
	frame.Visible = true

	for i = 1, math.random(15, 25) do
		local race = getRandomRaceData()
		frame.Race.Text = race
		setRarityText(frame, race)
		wait(0.02 * i)
	end

	wait(0.5)
	frame.Race.Text = mainRace
	setRarityText(frame, mainRace)
	wait(0.2)
	player.PlayerData.race.Value = mainRace
	frame.Visible = false
end

ReplicatedStorage.RerollRace.OnServerEvent:Connect(function(player: Player)
	player.PlayerData.RaceSpins.Value -= 1
	rerollRace(player)

end)
ReplicatedStorage.GenderSpinned.OnServerEvent:Connect(function(player: Player, b)
	player.PlayerData.GenderSpins.Value -= 1
	player.PlayerData.gender.Value = b

end)

game:GetService("MarketplaceService").ProcessReceipt = function(rinfo)
	local player = game.Players:GetPlayerByUserId(rinfo.PlayerId)
	if player then
		local Raceproducts = {
			["Product1"] = {
				product = 1681892895,
				amount = 1
			},
			["Product2"] = {
				product = 1681901940,
				amount = 2
			},
			["Product3"] = {
				product = 1681893504,
				amount = 5
			},
			["Product4"] = {
				product = 1681899754,
				amount = 10
			},
			["Product5"] = {
				product = 1681899992,
				amount = 20
			},

		}
		local Genderproducts = {
			["Product1"] = {
				product = 1681908635,
				amount = 1
			},

		}
		local product = rinfo.ProductId
		for i,v in pairs(Raceproducts) do
			if product == v.product then
				player.PlayerData.RaceSpins.Value += v.amount
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		for i,v in pairs(Genderproducts) do
			if product == v.product then
				player.PlayerData.GenderSpins.Value += v.amount
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
	end

end


