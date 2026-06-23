	-- // Services
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local LP = Players.LocalPlayer

		-- // Configs
		local ESPConfig = {
			HighlightMurderer = false,
			HighlightInnocent = false,
			HighlightSheriff = false
		}

		local NameTagsConfig = {
			Enabled = false,
			TextSize = 14,
			ShowDistance = true
		}

		local Murder, Sheriff, Hero
		local roles = {}
		local gunDropESPEnabled = false
		local nameTags = {}

		-- // Utility Functions
		local function GetHighlight(player)
			if player == LP then 
				return nil
			end
			if not player.Character then
				return nil
			end

			local highlight = player.Character:FindFirstChild("Highlight")
			if not highlight then
				highlight = Instance.new("Highlight")
				highlight.Name = "Highlight"
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Adornee = player.Character
				highlight.Parent = player.Character
			end
			return highlight
		end

		local function IsAlive(player)
			for name, data in pairs(roles) do
				if player.Name == name then
					return not data.Killed and not data.Dead
				end
			end
			return false
		end

		local function UpdateRoles()
			local success, data = pcall(function()
				return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
			end)
			if success and type(data) == "table" then
				roles = data
				Murder, Sheriff, Hero = nil, nil, nil
				for name, info in pairs(roles) do
					if info.Role == "Murderer" then
						Murder = name
					elseif info.Role == "Sheriff" then
						Sheriff = name
					elseif info.Role == "Hero" then
						Hero = name
					end
				end
			end
		end

		local function UpdateHighlights()
			for _, player in ipairs(Players:GetPlayers()) do
				if player == LP then
					continue
				end
				local highlight = GetHighlight(player)
				if not highlight then
					continue
				end

				local show = false
				local color = Color3.new(1, 1, 1)

				-- Проверяем роли
				if ESPConfig.HighlightMurderer and player.Name == Murder and IsAlive(player) then
					color = Color3.fromRGB(255, 0, 0) -- Murderer
					show = true
				elseif ESPConfig.HighlightSheriff and player.Name == Sheriff and IsAlive(player) then
					color = Color3.fromRGB(0, 0, 255) -- Sheriff
					show = true
				elseif ESPConfig.HighlightSheriff and player.Name == Hero and IsAlive(player) and (not Sheriff or not IsAlive(Players[Sheriff])) then
					color = Color3.fromRGB(255, 255, 0) -- Hero
					show = true
				elseif ESPConfig.HighlightInnocent and IsAlive(player) and player.Name ~= Murder and player.Name ~= Sheriff and player.Name ~= Hero then
					color = Color3.fromRGB(0, 255, 0) -- Innocent
					show = true
				end

				-- Если игрок не имеет роли, окрашиваем в серый
				if not show then
					color = Color3.fromRGB(169, 169, 169) -- Серый цвет для тех, кто не имеет роли
					show = true
				end

				highlight.Enabled = show
				highlight.FillColor = color
				highlight.OutlineColor = color
			end
		end

		RunService.Heartbeat:Connect(function()
			UpdateRoles()
			UpdateHighlights()
		end)

		-- // Gun ESP
		local mapPaths = {
			"ResearchFacility", "Hospital3", "MilBase", "House2",
			"Workplace", "Mansion2", "BioLab", "Hotel", "Factory",
			"Bank2", "PoliceStation", "BeachResort", "Office3", "Barn", "Farmhouse"
		}

		local function createGunDropHighlight(gunDrop)
			if gunDrop and not gunDrop:FindFirstChild("GunDropHighlight") then
				local highlight = Instance.new("Highlight")
				highlight.Name = "GunDropHighlight"
				highlight.FillColor = Color3.fromRGB(0, 255, 255)
				highlight.OutlineColor = Color3.fromRGB(0, 128, 128)
				highlight.Adornee = gunDrop
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = gunDrop
			end
		end

		local function removeGunDropHighlight(gunDrop)
			if gunDrop and gunDrop:FindFirstChild("GunDropHighlight") then
				gunDrop.GunDropHighlight:Destroy()
			end
		end

		local function scanGunDrops()
			for _, mapName in ipairs(mapPaths) do
				local map = workspace:FindFirstChild(mapName)
				if map then
					local gunDrop = map:FindFirstChild("GunDrop")
					if gunDrop then
						if gunDropESPEnabled then
							createGunDropHighlight(gunDrop)
						else
							removeGunDropHighlight(gunDrop)
						end
					end
				end
			end
		end

		task.spawn(function()
			while true do
				scanGunDrops()
				task.wait(2)
			end
		end)

		-- // Nicknames
		local function CreateNameTag(player)
			if player == LP then
				return
			end
			if nameTags[player] then
				nameTags[player].gui:Destroy()
				nameTags[player] = nil
			end

			local character = player.Character
			if not character then
				return
			end
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				return
			end

			local billboard = Instance.new("BillboardGui")
			local textLabel = Instance.new("TextLabel")

			billboard.Name = "NameTag"
			billboard.Adornee = humanoidRootPart
			billboard.Size = UDim2.new(0, 200, 0, 50)
			billboard.StudsOffset = Vector3.new(0, 2.5, 0)
			billboard.AlwaysOnTop = true
			billboard.MaxDistance = 1000
			billboard.Parent = character

			textLabel.Name = "Label"
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.TextStrokeTransparency = 0.5
			textLabel.TextColor3 = Color3.new(1, 1, 1)
			textLabel.TextSize = NameTagsConfig.TextSize
			textLabel.Font = Enum.Font.GothamBold
			textLabel.Parent = billboard

			nameTags[player] = { gui = billboard }
		end

		local function RemoveNameTag(player)
			if nameTags[player] then
				if nameTags[player].gui then
					nameTags[player].gui:Destroy()
				end
				nameTags[player] = nil
			end
		end

		local function UpdateNameTagText(player)
			local tagData = nameTags[player]
			if not tagData or not tagData.gui then
				return
			end
			local character = player.Character
			if not character then
				return
			end
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")

			if not humanoidRootPart or not lpHRP then
				tagData.gui.Label.Text = player.Name
				return
			end

			local distance = (humanoidRootPart.Position - lpHRP.Position).Magnitude
			if NameTagsConfig.ShowDistance then
				tagData.gui.Label.Text = string.format("%s [%d]", player.Name, math.floor(distance))
			else
				tagData.gui.Label.Text = player.Name
			end
		end

		task.spawn(function()
			while true do
				task.wait(0.5)
				if NameTagsConfig.Enabled then
					for _, player in ipairs(Players:GetPlayers())
					do
					if player ~= LP then
						local char = player.Character
						local hrp = char and char:FindFirstChild("HumanoidRootPart")
						if hrp then
							if not nameTags[player] or not nameTags[player].gui or nameTags[player].gui.Adornee ~= hrp then
								CreateNameTag(player)
							end
							UpdateNameTagText(player)
						else
							RemoveNameTag(player)
						end
					end
				end

				-- Очищаем метки для покинувших игроков
				for p in pairs(nameTags) do
					if not Players:FindFirstChild(p.Name) then
						RemoveNameTag(p)
					end
				end
			else
				-- Отключаем все метки, если функция выключена
				for p in pairs(nameTags) do
					RemoveNameTag(p)
				end
			end
			task.wait(0.5)
		end
		end)
