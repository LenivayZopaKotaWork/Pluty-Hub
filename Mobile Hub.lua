if getgenv().r3thexecuted then 
    print("Script already executed")
    return 
end
getgenv().r3thexecuted = false

    local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/LenivayZopaKota/Pluty-v0.0.1/refs/heads/main/Main.lua"))()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/LenivayZopaKota/Pluty-v0.0.1/refs/heads/main/SaveManager.lua"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/LenivayZopaKota/Pluty-v0.0.1/refs/heads/main/InterfaceManager.lua"))()
    local Players = game:GetService("Players");
    local ReplicatedStorage = game:GetService("ReplicatedStorage");
    local LocalPlayer = Players.LocalPlayer;
    local Workspace = game:GetService("Workspace");
    local CurrentCamera = Workspace.CurrentCamera;
    local RunService = game:GetService("RunService");

    local Window = Fluent:CreateWindow({
        Title = "Pluty Hub Mobile " .. Fluent.Version,
        SubTitle = "by Pluty",
        TabWidth = 160,
        Size = UDim2.fromOffset(420, 340),
        Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
    })

    --Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional


local Options = Fluent.Options

    ---------------------------------------------------------------Разделы-функций------------------------------------------
            --Emotions = Window:AddTab({ Title = "Emotions", Icon = "smile" }), -- На будущее, между Combat и Trolling

    local Tabs = {
        Visual = Window:AddTab({ Title = "Visual", Icon = "eye" }),
        Character = Window:AddTab({ Title = "Character", Icon = "user" }),
        Teleport = Window:AddTab({ Title = "Teleport", Icon = "arrow-right" }),
        Combat = Window:AddTab({ Title = "Combat", Icon = "sword" }),
        Trolling = Window:AddTab({ Title = "Trolling", Icon = "smile-plus" }),
        AutoFarm = Window:AddTab({ Title = "AutoFarm", Icon = "calculator" }),
        Spectator = Window:AddTab({ Title = "Spectator", Icon = "camera" }),
        Other = Window:AddTab({ Title = "Other", Icon = "file-cog" }),
        Server = Window:AddTab({ Title = "Server", Icon = "aperture" }),
        Main = Window:AddTab({ Title = "Main", Icon = "" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    }
    
-------------------------------------------Раздел Visusal------------------------------------------------------------
do
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer

    -- Конфиг ESP
    local ESPConfig = {
        HighlightMurderer = false,
        HighlightInnocent = false,
        HighlightSheriff = false
    }

    local Murder, Sheriff, Hero
    local roles = {}

    -- Создание или возврат Highlight
    local function GetHighlight(player)
        if player == LP then return nil end
        if not player.Character then return nil end

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

    -- Проверка жив ли игрок
    local function IsAlive(player)
        for name, data in pairs(roles) do
            if player.Name == name then
                return not data.Killed and not data.Dead
            end
        end
        return false
    end

    -- Обновление ролей
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

    -- Обновление подсветки
    local function UpdateHighlights()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LP then continue end
            local highlight = GetHighlight(player)
            if not highlight then continue end

            local show = false
            local color = Color3.new(1, 1, 1)

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

            highlight.Enabled = show
            highlight.FillColor = color
            highlight.OutlineColor = color
        end
    end

    -- Цикл обновления
    RunService.Heartbeat:Connect(function()
        UpdateRoles()
        UpdateHighlights()
    end)

    -- Тогглы во Fluent UI
    local VisualTab = Tabs.Visual
    VisualTab:AddToggle("MurdererToggle", {
        Title = "ESP Murderer",
        Default = ESPConfig.HighlightMurderer
    }):OnChanged(function(state)
        ESPConfig.HighlightMurderer = state
    end)

    VisualTab:AddToggle("SheriffToggle", {
        Title = "ESP Sheriff",
        Default = ESPConfig.HighlightSheriff
    }):OnChanged(function(state)
        ESPConfig.HighlightSheriff = state
    end)

    VisualTab:AddToggle("InnocentToggle", {
        Title = "ESP Innocent",
        Default = ESPConfig.HighlightInnocent
    }):OnChanged(function(state)
        ESPConfig.HighlightInnocent = state
    end)

        
    local gunDropESPEnabled = false
    local mapPaths = {
        "ResearchFacility", "Hospital3", "MilBase", "House2",
        "Workplace", "Mansion2", "BioLab", "Hotel", "Factory",
        "Bank2", "PoliceStation","BeachResort", "Office3"
    }

    -- Функции для управления Highlight
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

    -- Проверка и обновление подсветки единожды
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

    -- Цикл проверки каждые 2 секунды
    task.spawn(function()
        while true do
            scanGunDrops()
            task.wait(2)
        end
    end)



    local DropGunToggle = VisualTab:AddToggle("MyToggle", 
    {
        Title = "Esp Gun", 
        Description = "",
        Default = false,
        Callback = function(value)
            gunDropESPEnabled = value
        end
    })

    DropGunToggle:OnChanged(function(value)
        gunDropESPEnabled = value
        scanGunDrops()
    end)


    -- Кнопка сброса
    VisualTab:AddButton({
        Title = "UpDate Esp",
        Description = "",
        Callback = function()
            RemoveAllHighlights()
        end
    })



    local Section = Tabs.Visual:AddSection("Nicknames")

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local LP = Players.LocalPlayer

        local NameTagsConfig = {
            Enabled = false,
            TextSize = 14,
            ShowDistance = true
        }

        local nameTags = {}

        -- Создание метки для игрока
        local function CreateNameTag(player)
            if player == LP then return end
            if nameTags[player] then
                RemoveNameTag(player) -- пересоздаём, если уже есть
            end

            local character = player.Character
            if not character then return end

            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end

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

            nameTags[player] = {
                gui = billboard
            }
        end

        -- Удаление метки
        function RemoveNameTag(player)
            if nameTags[player] then
                if nameTags[player].gui then
                    nameTags[player].gui:Destroy()
                end
                nameTags[player] = nil
            end
        end

        -- Обновление текста
        local function UpdateNameTagText(player)
            local tagData = nameTags[player]
            if not tagData or not tagData.gui then return end

            local character = player.Character
            if not character then return end

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

        -- Автообновление каждые 0.5 секунды
        task.spawn(function()
            while true do
                task.wait(0.5)
                if NameTagsConfig.Enabled then
                    for _, player in ipairs(Players:GetPlayers()) do
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
                    -- Чистим лишние метки (на случай, если игрок вышел)
                    for p in pairs(nameTags) do
                        if not Players:FindFirstChild(p.Name) then
                            RemoveNameTag(p)
                        end
                    end
                else
                    -- Если выключено — удаляем все метки
                    for p in pairs(nameTags) do
                        RemoveNameTag(p)
                    end
                end
            end
        end)

        -- UI элементы
        local VisualTab = Tabs.Visual

        VisualTab:AddToggle("NameTagsToggle", {
            Title = "Show Nicknames",
            Default = NameTagsConfig.Enabled
        }):OnChanged(function(value)
            NameTagsConfig.Enabled = value
        end)

        VisualTab:AddSlider("NameTagsSize", {
            Title = "Nickname size",
            Description = "Adjusting text size",
            Default = NameTagsConfig.TextSize,
            Min = 8,
            Max = 32,
            Rounding = 1
        }):OnChanged(function(value)
            NameTagsConfig.TextSize = value
            for _, tagData in pairs(nameTags) do
                if tagData.gui and tagData.gui.Label then
                    tagData.gui.Label.TextSize = value
                end
            end
        end)

end
---------------------------------------------Раздел Character-------------------------------------------------

do

            local Section = Tabs.Character:AddSection("Character")


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local defwalk = 16
local walkspeed = defwalk
local loopstate = false
local humanoid

local haha = Tabs.Character:AddSlider("sliderws", {
    Title = "WalkSpeed",
    Description = "",
    Default = defwalk,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        walkspeed = tonumber(Value)
    end
})

-- Функция для обновления humanoid
local function UpdateHumanoid()
    if LP.Character then
        humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
    end
end

-- Обновляем humanoid при спавне персонажа
LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    UpdateHumanoid()
end)

-- Инициализируем
UpdateHumanoid()

-- Toggle
local hahah = Tabs.Character:AddToggle("togglews", {
    Title = "Toggle WalkSpeed",
    Description = "",
    Default = false,
    Callback = function(state)
        loopstate = state
    end
})

-- Постоянно применять скорость при включении toggle
RunService.Heartbeat:Connect(function()
    if loopstate and humanoid then
        humanoid.WalkSpeed = walkspeed
    elseif humanoid then
        humanoid.WalkSpeed = defwalk
    end
end)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local defJumpPower = 50
local jumpPower = defJumpPower
local loopstate = false
local humanoid

-- Слайдер для JumpPower
local JumpPowerSlider = Tabs.Character:AddSlider("JumpPowerSlider", {
    Title = "JumpPower",
    Description = "",
    Default = defJumpPower,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        jumpPower = tonumber(Value)
    end
})

-- Функция для обновления Humanoid
local function UpdateHumanoid()
    if LP.Character then
        humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
    end
end

-- Обновляем Humanoid при спавне персонажа
LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    UpdateHumanoid()
end)

-- Инициализируем
UpdateHumanoid()

-- Тумблер для активации JumpPower
local JumpPowerToggle = Tabs.Character:AddToggle("ToggleJumpPower", {
    Title = "Toggle JumpPower",
    Description = "",
    Default = false,
    Callback = function(state)
        loopstate = state
    end
})

-- Постоянно применять JumpPower при включении тумблера
RunService.Heartbeat:Connect(function()
    if loopstate and humanoid then
        humanoid.JumpPower = jumpPower
    elseif humanoid then
        humanoid.JumpPower = defJumpPower
    end
end)





local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local flyEnabled = false
local flySpeed = 50
local flyConnections = {}
local flyBodyVelocity, flyBodyGyro
local noclipEnabled = false
local noclipConnection

-- Обновить humanoid и rootPart
local humanoid, rootPart
local function UpdateHumanoid()
    if LP.Character then
        humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
        rootPart = LP.Character:FindFirstChild("HumanoidRootPart")
    end
end

LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    UpdateHumanoid()

    -- Перезапуск полёта при возрождении
    if flyEnabled then startFly() end
    if noclipEnabled then startNoclip() end
end)

UpdateHumanoid()

-- Отключение коллизий
local function updateCollisions(state)
    if LP.Character then
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not state
            end
        end
    end
end

-- Fly Start
local function startFly()
    UpdateHumanoid()
    if not (humanoid and rootPart) then return end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyGyro = Instance.new("BodyGyro")

    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.P = 10000
    flyBodyGyro.D = 500

    flyBodyGyro.Parent = rootPart
    flyBodyVelocity.Parent = rootPart

    updateCollisions(true)
    humanoid.PlatformStand = true

    local camera = workspace.CurrentCamera
    local activeKeys = {}

    flyConnections.InputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
            activeKeys[input.KeyCode] = true
        end
    end)

    flyConnections.InputEnded = UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            activeKeys[input.KeyCode] = nil
        end
    end)

    flyConnections.Heartbeat = RunService.Heartbeat:Connect(function()
        if not (flyBodyVelocity and flyBodyGyro) then return end

        local moveVector = Vector3.zero
        local cam = camera.CFrame
        local forward = cam.LookVector
        local right = cam.RightVector
        local up = Vector3.new(0, 1, 0)

        if activeKeys[Enum.KeyCode.W] then moveVector += forward end
        if activeKeys[Enum.KeyCode.S] then moveVector -= forward end
        if activeKeys[Enum.KeyCode.A] then moveVector -= right end
        if activeKeys[Enum.KeyCode.D] then moveVector += right end
        if activeKeys[Enum.KeyCode.Space] then moveVector += up end
        if activeKeys[Enum.KeyCode.LeftShift] then moveVector -= up end

        flyBodyGyro.CFrame = cam
        if moveVector.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveVector.Unit * flySpeed
        else
            flyBodyVelocity.Velocity = Vector3.zero
        end
    end)
end

-- Fly Stop
local function stopFly()
    updateCollisions(false)

    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end

    for _, conn in pairs(flyConnections) do
        conn:Disconnect()
    end
    flyConnections = {}

    if humanoid then
        humanoid.PlatformStand = false
    end
end

-- Noclip
local function startNoclip()
    noclipEnabled = true
    noclipConnection = RunService.Stepped:Connect(function()
        if LP.Character then
            for _, part in ipairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    noclipEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- Fly Toggle
local FlyToggle = Tabs.Character:AddToggle("FlyToggle", {
    Title = "Fly",
    Default = false,
    Callback = function(state)
        flyEnabled = state
        if state then
            startFly()
        else
            stopFly()
        end
    end
})

--  Fly Speed Slider
local FlySpeedSlider = Tabs.Character:AddSlider("FlySpeedSlider", {
    Title = "FlySpeed",
    Description = "",
    Default = 50,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Callback = function(value)
        flySpeed = value
    end
})

--  Noclip Toggle
local NoclipToggle = Tabs.Character:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Default = false,
    Callback = function(state)
        if state then
            startNoclip()
        else
            stopNoclip()
        end
    end
})


    -- Noclip System
    local noclipEnabled = false
    local noclipConnection

    local function noclipLoop()
        while noclipEnabled do
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
            game:GetService("RunService").Stepped:Wait()
        end
    end

    



        local Section = Tabs.Character:AddSection("Respawn")



    Tabs.Character:AddButton({
    Title = "Character Respawn",
    Description = "Respawns your character",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        
        -- Сохраняем текущие состояния
        local wasFlying = flyEnabled
        local wasNoclip = noclipEnabled
        
        -- Отключаем системы перед респавном
        if flyEnabled then
            FlyToggle:SetValue(false)
        end
        if noclipEnabled then
            NoclipToggle:SetValue(false)
        end
        
        -- Основная логика респавна
        if player.Character then
            player.Character:BreakJoints()
        end
        
        -- Задержка для гарантии респавна
        task.wait(0.5)
        
        -- Восстановление состояний после респавна
        if wasFlying then
            FlyToggle:SetValue(true)
        end
        if wasNoclip then
            NoclipToggle:SetValue(true)
        end
    end
})

end

-----------------------------------------------------------Раздел Teleport--------------------------------------------

do
    local Section = Tabs.Teleport:AddSection("Teleport to a person")


local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local teleportTarget = nil

-- Функция обновления списка игроков
local function updateTeleportPlayers()
    local playersList = {"Select Player"}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playersList, player.Name)
        end
    end
    return playersList
end

-- Создание выпадающего списка
local Dropdown = Tabs.Teleport:AddDropdown("PlayerTeleport", {
    Title = "Players",
    Values = updateTeleportPlayers(),
    Multi = false,
    Default = "Select Player"
})

-- Обработчик выбора игрока
Dropdown:OnChanged(function(selected)
    if selected ~= "Select Player" then
        teleportTarget = Players:FindFirstChild(selected)
    else
        teleportTarget = nil
    end
end)

-- Автообновление списка игроков
Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    Dropdown:SetValues(updateTeleportPlayers())
end)

Players.PlayerRemoving:Connect(function()
    Dropdown:SetValues(updateTeleportPlayers())
end)

-- Логика телепорта (без изменений)
local function teleportToPlayer()
    if teleportTarget and teleportTarget.Character then
        local targetRoot = teleportTarget.Character:FindFirstChild("HumanoidRootPart")
        local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if targetRoot and localRoot then
            localRoot.CFrame = targetRoot.CFrame
            Fluent:Notify({
                Title = "Teleport",
                Content = "Successfully teleported to "..teleportTarget.Name,
                Duration = 3
            })
        end
    else
        Fluent:Notify({
            Title = "Error",
            Content = "Target not found or unavailable",
            Duration = 3
        })
    end
end

-- Кнопка для активации телепорта
Tabs.Teleport:AddButton({
    Title = "Teleport to Selected",
    Callback = teleportToPlayer
})

Tabs.Teleport:AddButton({
		Title = "Update players list",
		Callback = function()
			teleportDropdown:Refresh(updateTeleportPlayers());
		end
	});

    
        
    local Section = Tabs.Teleport:AddSection("Teleport to")


    
        Tabs.Teleport:AddButton({
        Title = "Teleport to Lobby",
        Description = "Teleport to the main lobby area",
        Callback = function()
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(112.961197, 140.252960, 46.383835)
        end
    })




    Tabs.Teleport:AddButton({
        Title = "Teleport to Sheriff",
        Description = "",
        Callback = function()
			local plrs = game:GetService("Players")
        	for i,v in pairs(plrs:GetPlayers()) do
            	if v.Character and (v.Character:FindFirstChild("Gun") or (v.Backpack and v.Backpack:FindFirstChild("Gun"))) then
                	game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
            	end
        	end
		end
	});

    


    Tabs.Teleport:AddButton({
        Title = "Teleport to Murderer",
        Description = "",
        Callback = function()
			local plrs = game:GetService("Players")
        	for i,v in pairs(plrs:GetPlayers()) do
            	if v.Character and (v.Character:FindFirstChild("Knife") or (v.Backpack and v.Backpack:FindFirstChild("Knife"))) then
                	game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
            	end
        	end
		end
	});



    local Section = Tabs.Teleport:AddSection("GrabGun")



        
            -------------------- GrabGun System --------------------
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local Workspace = game:GetService("Workspace")

        local gunDropESPEnabled = true
        local autoGrabEnabled = false
        local notifiedGunDrops = {}

        local mapGunDrops = {
            "ResearchFacility", "Hospital3", "MilBase", "House2", "Workplace",
            "Mansion2", "BioLab", "Hotel", "Factory", "Bank2", "PoliceStation",
            "Yacht", "Office3", "BeachResort"
        }

        local autoGrabLocked = false -- блокировка до конца раунда
        local lastGrabTime = 0
        local grabAttempts = 0

        -- Быстрый телепорт
        local function grabGunFast(gunDrop)
            if not gunDrop or not LocalPlayer.Character then return false end
            if LocalPlayer.Backpack:FindFirstChild("Gun") or LocalPlayer.Character:FindFirstChild("Gun") then 
                return true -- Gun уже есть
            end

            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return false end

            local originalCFrame = root.CFrame
            root.CFrame = gunDrop.CFrame + Vector3.new(0, 2.5, 0)

            task.delay(0.15, function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
                end
            end)

            task.wait(0.2) -- даём время поднять
            return LocalPlayer.Backpack:FindFirstChild("Gun") or LocalPlayer.Character:FindFirstChild("Gun")
        end

        -- Поиск GunDrop
        local function checkForGunDrops()
            if autoGrabLocked then return end -- если заблокировано до конца раунда, выходим
            if autoGrabEnabled and (tick() - lastGrabTime) < 2 then return end -- задержка между попытками

            for _, mapName in ipairs(mapGunDrops) do
                local map = Workspace:FindFirstChild(mapName)
                if map then
                    local gunDrop = map:FindFirstChild("GunDrop")
                    if gunDrop then
                        if not notifiedGunDrops[gunDrop] then
                            notifiedGunDrops = {}
                            notifiedGunDrops[gunDrop] = true

                            if gunDropESPEnabled then
                                Fluent:Notify({
                                    Title = "Gun Drop Spawned",
                                    Content = "A gun has appeared on the map: " .. mapName,
                                    Icon = "alert-circle",
                                    Duration = 5
                                })
                            end

                            if autoGrabEnabled then
                                lastGrabTime = tick()
                                grabAttempts += 1
                                local success = grabGunFast(gunDrop)
                                if success then
                                    autoGrabLocked = true -- подняли, значит отключаем до конца раунда
                                elseif grabAttempts >= 2 then
                                    autoGrabLocked = true -- два раза не получилось, отключаем
                                end
                            end
                        elseif autoGrabEnabled then
                            lastGrabTime = tick()
                            grabAttempts += 1
                            local success = grabGunFast(gunDrop)
                            if success then
                                autoGrabLocked = true
                            elseif grabAttempts >= 2 then
                                autoGrabLocked = true
                            end
                        end
                    end
                end
            end
        end

        -- Ручной вызов
        local function manualGrabGun()
            for _, mapName in ipairs(mapGunDrops) do
                local map = Workspace:FindFirstChild(mapName)
                if map then
                    local gunDrop = map:FindFirstChild("GunDrop")
                    if gunDrop then
                        grabGunFast(gunDrop)
                        return
                    end
                end
            end
            Fluent:Notify({
                Title = "Gun System",
                Content = "No GunDrop found on map",
                Icon = "x",
                Duration = 3
            })
        end

        -- Сброс при респавне
        LocalPlayer.CharacterAdded:Connect(function()
            autoGrabLocked = false
            grabAttempts = 0
        end)

        -- UI элементы
        local NotifyToggle = Tabs.Teleport:AddToggle("NotifyGunToggle", {
            Title = "Notify GunDrop",
            Default = true
        })
        NotifyToggle:OnChanged(function()
            gunDropESPEnabled = Options.NotifyGunToggle.Value
        end)

        local AutoGrabToggle = Tabs.Teleport:AddToggle("AutoGrabGun", {
            Title = "Auto Grab Gun",
            Default = false
        })
        AutoGrabToggle:OnChanged(function()
            autoGrabEnabled = Options.AutoGrabGun.Value
            Fluent:Notify({
                Title = "Gun System",
                Content = autoGrabEnabled and "Auto Grab Gun enabled" or "Auto Grab Gun disabled",
                Icon = autoGrabEnabled and "check-circle" or "x",
                Duration = 3
            })
        end)

        Tabs.Teleport:AddButton({
            Title = "Grab Gun",
            Callback = function()
                manualGrabGun()
            end
        })

        
        task.spawn(function()
            if not LocalPlayer.Character then
                LocalPlayer.CharacterAdded:Wait()
            end
            while task.wait(0.3) do
                checkForGunDrops()
            end
        end)

end
do

    local Section = Tabs.Combat:AddSection("Sheriff")


        
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        local RunService = game:GetService("RunService")
        local UserInputService = game:GetService("UserInputService")

        local LocalPlayer = Players.LocalPlayer
        local Camera = Workspace and Workspace.CurrentCamera

        
        local PRIORITY_PARTS = {
            "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head",
            "RightUpperLeg", "LeftUpperLeg", "RightUpperArm", "LeftUpperArm",
            "RightLowerLeg", "LeftLowerLeg", "RightLowerArm", "LeftLowerArm"
        }
        local CHECK_GUN_INTERVAL = 4       
        local FIND_TARGET_INTERVAL = 0.4   
        local AIM_SMOOTHNESS = 1           
        local NOTIFY_DURATION = 4

        
        local previousMouseBehavior = nil
        local notifiedNoGun = false
        local uiToggle, uiKeybind = nil, nil
        local fallbackToggle = false
        local fallbackKeyToggled = false
        local fallbackKeyEnum = Enum.KeyCode.E 

        
        local function GetCamera()
            Camera = Camera or (Workspace and Workspace.CurrentCamera)
            return Camera
        end

        local function HasGun()
        
            local char = LocalPlayer and LocalPlayer.Character
            if char then
                for _, v in ipairs(char:GetChildren()) do
                    if v:IsA("Tool") then
                        local nm = tostring(v.Name):lower()
                        if nm == "gun" or nm:find("gun") then
                            return true
                        end
                    end
                end
            end
            
            local backpack = LocalPlayer and LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, v in ipairs(backpack:GetChildren()) do
                    if v:IsA("Tool") then
                        local nm = tostring(v.Name):lower()
                        if nm == "gun" or nm:find("gun") then
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function IsMurderer(player)
            if not player or player == LocalPlayer then return false end
            if player.Character and player.Character:FindFirstChild("Knife") then return true end
            if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife") then return true end
            return false
        end

        local function IsInViewport(part)
            local cam = GetCamera()
            if not cam or not part then return false end
            local sp, onScreen = cam:WorldToViewportPoint(part.Position)
            if not onScreen then return false end
            local vx, vy = sp.X, sp.Y
            local vs = cam.ViewportSize
            if vx < 0 or vy < 0 or vx > vs.X or vy > vs.Y then return false end
            return true
        end

        local function IsPartVisible(part)
            if not part or not part.Position then return false end
            local cam = GetCamera()
            if not cam then return false end
            if not IsInViewport(part) then return false end

            local origin = cam.CFrame.Position
            local dir = (part.Position - origin)
            if dir.Magnitude <= 0.01 then return true end

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = { LocalPlayer.Character }
            local res = Workspace:Raycast(origin, dir, params)
            if not res then return true end
            if res.Instance and res.Instance:IsDescendantOf(part.Parent) then return true end
            return false
        end

        local function FindVisibleMurdererPart()
            local cam = GetCamera()
            if not cam then return nil, nil end
            local camPos = cam.CFrame.Position
            local bestDist = math.huge
            local bestPart, bestPlayer = nil, nil

            for _, plr in ipairs(Players:GetPlayers()) do
                if IsMurderer(plr) and plr.Character then
                    local char = plr.Character
                    local foundForPlayer = false
                    for _, name in ipairs(PRIORITY_PARTS) do
                        local part = char:FindFirstChild(name)
                        if part and part:IsA("BasePart") and IsPartVisible(part) then
                            local dist = (camPos - part.Position).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                bestPart = part
                                bestPlayer = plr
                            end
                            foundForPlayer = true
                            break
                        end
                    end
                    if not foundForPlayer then
                        for _, desc in ipairs(char:GetDescendants()) do
                            if desc:IsA("BasePart") and IsPartVisible(desc) then
                                local dist = (camPos - desc.Position).Magnitude
                                if dist < bestDist then
                                    bestDist = dist
                                    bestPart = desc
                                    bestPlayer = plr
                                end
                                break
                            end
                        end
                    end
                end
            end

            return bestPart, bestPlayer
        end

        local function AimCameraAtPart(part)
            if not part then return end
            local cam = GetCamera()
            if not cam then return end
            pcall(function()
                local camPos = cam.CFrame.Position
                local desired = CFrame.new(camPos, part.Position)
                if AIM_SMOOTHNESS >= 0.999 then
                    cam.CFrame = desired
                else
                    cam.CFrame = cam.CFrame:Lerp(desired, math.clamp(AIM_SMOOTHNESS, 0, 1))
                end
            end)
        end

        
        local function SetShiftLockOn()
        
            if previousMouseBehavior == nil then
                pcall(function() previousMouseBehavior = UserInputService.MouseBehavior end)
            end
            pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end)
        end

        local function RestoreMouseBehavior()
            pcall(function()
                if previousMouseBehavior ~= nil then
                    UserInputService.MouseBehavior = previousMouseBehavior
                else
                    
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end
            end)
            previousMouseBehavior = nil
        end

        
        local function FluentNotify(title, content)
            pcall(function()
                if typeof(Fluent) == "table" and type(Fluent.Notify) == "function" then
                    Fluent:Notify({
                        Title = title,
                        Content = content,
                        Icon = "alert-circle",
                        Duration = NOTIFY_DURATION
                    })
                else
                   
                    print("[AimBot] " .. title .. " - " .. content)
                end
            end)
        end

        
        local function NotifyNoGunOnce()
            if notifiedNoGun then return end
            notifiedNoGun = true
            FluentNotify("AimBot disabled — no Gun", "Equip a Gun to enable AimBot.")
        end
        local function ResetNoGunNotification()
            notifiedNoGun = false
        end

       
        local function GetToggleState()
            if uiToggle then
                local ok, val = pcall(function()
                    if uiToggle.GetState then return uiToggle:GetState() end
                    if uiToggle.GetValue then return uiToggle:GetValue() end
                    if uiToggle.Value ~= nil then return uiToggle.Value end
                    if Options and Options.AimBotToggle and Options.AimBotToggle.Value ~= nil then return Options.AimBotToggle.Value end
                    return false
                end)
                if ok and type(val) == "boolean" then return val end
            end
            return fallbackToggle
        end

        local function GetKeybindState()
            if uiKeybind then
                local ok, val = pcall(function()
                    if uiKeybind.GetState then return uiKeybind:GetState() end
                    if uiKeybind.GetValue then return uiKeybind:GetValue() end
                    
                    if uiKeybind.Value ~= nil and type(uiKeybind.Value) == "boolean" then return uiKeybind.Value end
                    return false
                end)
                if ok and type(val) == "boolean" then return val end
            end
            return fallbackKeyToggled
        end

        
        local mainThread = nil
        local function StartMainThread()
            if mainThread then return end
            mainThread = task.spawn(function()
                while true do
                    
                    task.wait(0.05)

                    if not GetToggleState() or not GetKeybindState() then
                       
                        RestoreMouseBehavior()
                        task.wait(0.15)
                        continue
                    end

                    
                    if not HasGun() then
                        NotifyNoGunOnce()
                        while GetToggleState() and GetKeybindState() and not HasGun() do
                            task.wait(CHECK_GUN_INTERVAL)
                        end
                    end

                    if not GetToggleState() or not GetKeybindState() then
                        RestoreMouseBehavior()
                        task.wait(0.1)
                        continue
                    end

                    ResetNoGunNotification()

                    
                    while GetToggleState() and GetKeybindState() and HasGun() do
                        
                        local part, plr = FindVisibleMurdererPart()
                        if part and plr and plr.Character then
                            
                            SetShiftLockOn()
                            while GetToggleState() and GetKeybindState() and HasGun() and plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 and IsPartVisible(part) do
                            
                                RunService.RenderStepped:Wait()
                                AimCameraAtPart(part)
                                
                                if plr and plr.Character then
                                    local newPart = plr.Character:FindFirstChild(part.Name)
                                    if newPart and newPart:IsA("BasePart") then
                                        part = newPart
                                    end
                                end
                            end
                            
                            RestoreMouseBehavior()
                        else
                            
                            task.wait(FIND_TARGET_INTERVAL)
                        end

                        
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
                            RestoreMouseBehavior()
                            break
                        end
                    end

                    RestoreMouseBehavior()
                    task.wait(0.1)
                end
            end)
        end

        
        local function SafeAddToggle(tab, id, props)
            local ok, res = pcall(function() return tab:AddToggle(id, props) end)
            if ok then return res end
            return nil
        end
        local function SafeAddKeybind(tab, id, props)
            local ok, res = pcall(function() return tab:AddKeybind(id, props) end)
            if ok then return res end
            return nil
        end

        if Tabs and Tabs.Combat then
            uiToggle = SafeAddToggle(Tabs.Combat, "AimBotToggle", { Title = "AimBot", Default = false })
            uiKeybind = SafeAddKeybind(Tabs.Combat, "AimBotKey", { Title = "AimBot Key", Mode = "Toggle", Default = "E" })

            
            pcall(function() if uiToggle.SetValue then uiToggle:SetValue(false) end end)
            pcall(function() if uiKeybind.SetValue then uiKeybind:SetValue("E", "Toggle") end end)

            
            pcall(function()
                uiToggle:OnChanged(function(val)
                    fallbackToggle = val
                    if val then
                        FluentNotify("AimBot Enabled", "AimBot is now enabled.")
                    else
                        FluentNotify("AimBot Disabled", "AimBot has been disabled.")
                        
                        RestoreMouseBehavior()
                    end
                end)
            end)

            
            pcall(function()
                uiKeybind:OnChanged(function(val)
                    fallbackKeyToggled = val
                    if val then
                        FluentNotify("Aim Key Enabled", "Aim key activated.")
                    else
                        FluentNotify("Aim Key Disabled", "Aim key deactivated.")
                        RestoreMouseBehavior()
                    end
                end)
            end)
        else
           
            fallbackToggle = false
            fallbackKeyToggled = false
            fallbackKeyEnum = Enum.KeyCode.E
            FluentNotify("AimBot UI missing", "Using fallback keyboard controls: T toggle, E key toggle.")

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.T then
                    fallbackToggle = not fallbackToggle
                    FluentNotify("AimBot Toggle", (fallbackToggle and "Enabled" or "Disabled"))
                    if not fallbackToggle then RestoreMouseBehavior() end
                elseif input.KeyCode == fallbackKeyEnum then
                    fallbackKeyToggled = not fallbackKeyToggled
                    FluentNotify("Aim Key", (fallbackKeyToggled and "Activated" or "Deactivated"))
                    if not fallbackKeyToggled then RestoreMouseBehavior() end
                end
            end)
        end

        
        do
            local configuredKey = nil
            pcall(function()
                if uiKeybind and uiKeybind.Value and type(uiKeybind.Value) == "string" then
                    configuredKey = uiKeybind.Value:upper()
                    if Enum.KeyCode[configuredKey] then fallbackKeyEnum = Enum.KeyCode[configuredKey] end
                end
            end)

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if uiKeybind and uiKeybind.GetState then return end
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == fallbackKeyEnum then
                    fallbackKeyToggled = not fallbackKeyToggled
                    FluentNotify("Aim Key", (fallbackKeyToggled and "Activated" or "Deactivated"))
                    if not fallbackKeyToggled then RestoreMouseBehavior() end
                end
            end)
        end

    
        StartMainThread()

       
        LocalPlayer.CharacterAdded:Connect(function(character)
            
            RestoreMouseBehavior()
           
            notifiedNoGun = false

         
            task.spawn(function()
                local ok, hum = pcall(function() return character:WaitForChild("Humanoid", 30) end)
                if ok and hum then
                    hum.Died:Connect(function()
                        RestoreMouseBehavior()
                       
                        pcall(function() FluentNotify("You died", "AimBot paused on death.") end)
                    end)
                else
                    
                    RestoreMouseBehavior()
                end
            end)
        end)

 
        LocalPlayer.CharacterRemoving:Connect(function()
            RestoreMouseBehavior()
        end)


        task.spawn(function()
            task.wait(600)
            RestoreMouseBehavior()
        end)

  
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local UserInputService = game:GetService("UserInputService")

        local LocalPlayer = Players.LocalPlayer
        local Camera = Workspace and Workspace.CurrentCamera

        local BULLET_SPEED = 1200          
        local PREDICT_ITERATIONS = 1       
        local SHOT_COOLDOWN = 0.03         
        local REMOTE_ARG1 = 1
        local REMOTE_ARG3 = "AH2"


        local lastShot = 0
        local uiToggle, uiKeybind = nil, nil

        local configuredInput = { Type = "Key", Code = Enum.KeyCode.R }


        local cachedGunName = nil
        local cachedRemote = nil


        local RaycastParams_new = RaycastParams.new


        local function GetCamera()
            Camera = Camera or (Workspace and Workspace.CurrentCamera)
            return Camera
        end

        local function LocalAlive()
            local ch = LocalPlayer and LocalPlayer.Character
            if not ch then return false end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            return hum and hum.Health > 0
        end

        local function FindMurdererPlayerFast()
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer then
                    local char = pl.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            if char:FindFirstChild("Knife") then
                                return pl
                            end
                            local bp = pl:FindFirstChild("Backpack")
                            if bp and bp:FindFirstChild("Knife") then
                                return pl
                            end
                        end
                    end
                end
            end
            return nil
        end

        local function GetPreferredPart(plr)
            if not plr or not plr.Character then return nil end
            local char = plr.Character
            local prefer = { "HumanoidRootPart", "UpperTorso", "Torso", "Head", "LowerTorso" }
            for _, name in ipairs(prefer) do
                local p = char:FindFirstChild(name)
                if p and p:IsA("BasePart") then return p end
            end
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then return d end
            end
            return nil
        end

        local function IsPartVisibleFast(part)
            if not part then return false end
            local cam = GetCamera()
            if not cam then return false end
            local sp, onScreen = cam:WorldToViewportPoint(part.Position)
            if not onScreen then return false end
            local vx, vy = sp.X, sp.Y
            local vs = cam.ViewportSize
            if vx < 0 or vy < 0 or vx > vs.X or vy > vs.Y then return false end

            local origin = cam.CFrame.Position
            local dir = (part.Position - origin)
            if dir.Magnitude <= 0.01 then return true end

            local params = RaycastParams_new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = { LocalPlayer.Character }
            local res = Workspace:Raycast(origin, dir, params)
            if not res then return true end
            return res.Instance and res.Instance:IsDescendantOf(part.Parent)
        end

        local function PredictPositionFast(part)
            if not part then return nil end
            local cam = GetCamera()
            if not cam then return part.Position end

            local origin = cam.CFrame.Position
            local targetPos = part.Position

            local vel = Vector3.new(0,0,0)
            pcall(function() vel = part.AssemblyLinearVelocity end)
            if (vel == Vector3.new(0,0,0) or vel == nil) and part.Velocity then vel = part.Velocity end

            local predicted = targetPos
            for i = 1, PREDICT_ITERATIONS do
                local dist = (predicted - origin).Magnitude
                local t = (BULLET_SPEED > 0) and (dist / BULLET_SPEED) or 0.0001
                predicted = targetPos + vel * t
            end
            return predicted
        end

        local function GetLocalGunObjectFast()
            local char = LocalPlayer and LocalPlayer.Character
            if char then
                local g = char:FindFirstChild("Gun")
                if g and g:IsA("Tool") then return g end
                for _, o in ipairs(char:GetChildren()) do
                    if o:IsA("Tool") and o:FindFirstChild("IsGun") then return o end
                end
            end
            local bp = LocalPlayer and LocalPlayer:FindFirstChild("Backpack")
            if bp then
                local g = bp:FindFirstChild("Gun")
                if g and g:IsA("Tool") then return g end
                for _, o in ipairs(bp:GetChildren()) do
                    if o:IsA("Tool") and o:FindFirstChild("IsGun") then return o end
                end
            end
            return nil
        end

        local function EnsureGunEquippedFast()
            local gun = GetLocalGunObjectFast()
            if not gun then return nil end
            if LocalPlayer.Character and gun.Parent ~= LocalPlayer.Character then
                pcall(function() gun.Parent = LocalPlayer.Character end)
                task.wait(0.01)
            end
            if LocalPlayer.Character then
                local g = LocalPlayer.Character:FindFirstChild(gun.Name)
                if g and g:IsA("Tool") then return g end
            end
            return gun
        end


        local function GetCachedRemoteForGun(gun)
            if not gun then
                cachedGunName = nil
                cachedRemote = nil
                return nil
            end


            if cachedGunName == gun.Name and cachedRemote and cachedRemote.Parent and cachedRemote:IsDescendantOf(gun) then
                return cachedRemote
            end

            cachedGunName = nil
            cachedRemote = nil

            local ok, knifeLocal = pcall(function() return gun:FindFirstChild("KnifeLocal") end)
            if ok and knifeLocal then
                local cb = knifeLocal:FindFirstChild("CreateBeam")
                if cb then
                    local rf = cb:FindFirstChildWhichIsA("RemoteFunction")
                    if rf then
                        cachedGunName = gun.Name
                        cachedRemote = rf
                        return rf
                    end
                end
            end

            for _, desc in ipairs(gun:GetDescendants()) do
                if desc:IsA("RemoteFunction") then
                    local pname = desc.Parent and tostring(desc.Parent.Name):lower() or ""
                    if pname:find("create") or pname:find("beam") or pname:find("knife") then
                        cachedGunName = gun.Name
                        cachedRemote = desc
                        return desc
                    end
                end
            end

            for _, desc in ipairs(gun:GetDescendants()) do
                if desc:IsA("RemoteFunction") then
                    cachedGunName = gun.Name
                    cachedRemote = desc
                    return desc
                end
            end


            cachedGunName = nil
            cachedRemote = nil
            return nil
        end


        local function ResetCaches()
            cachedGunName = nil
            cachedRemote = nil
        end


        local function SilentShootOnceFast()
            local now = tick()
            if now - lastShot < SHOT_COOLDOWN then return false end
            lastShot = now

            if not LocalAlive() then return false end

            local murderer = FindMurdererPlayerFast()
            if not murderer then return false end

            local part = GetPreferredPart(murderer)
            if not part then return false end
            if not IsPartVisibleFast(part) then return false end

            local aimPos = PredictPositionFast(part) or part.Position

            local gun = EnsureGunEquippedFast()
            if not gun then return false end

            local rf = GetCachedRemoteForGun(gun)
            if not rf then return false end

            local ok, res = pcall(function() return rf:InvokeServer(REMOTE_ARG1, aimPos, REMOTE_ARG3) end)
            if ok then
                return true
            else
                warn("[SilentAimFast] Invoke error:", res)
               
                ResetCaches()
                return false
            end
        end


        local function SafeAddToggle(tab, id, props)
            local ok, obj = pcall(function() return tab:AddToggle(id, props) end)
            if ok and obj then return obj end
            return nil
        end
        local function SafeAddKeybind(tab, id, props)
            local ok, obj = pcall(function() return tab:AddKeybind(id, props) end)
            if ok and obj then return obj end
            return nil
        end

    
        local function ParseKeybindValue(v)

            if typeof(v) == "EnumItem" then
                if v.EnumType == Enum.KeyCode then
                    return { Type = "Key", Code = v }
                elseif v.EnumType == Enum.UserInputType then
                    return { Type = "Mouse", Code = v }
                end
            end


            if type(v) == "table" and v.Type and v.Code then
                return v
            end


            if type(v) == "string" then
                local s = v

                s = s:gsub("^Enum%.KeyCode%.", ""):gsub("^Enum%.UserInputType%.", ""):upper()

                local mouseDigit = s:match("(%d+)$")
                if mouseDigit then
                    local d = tonumber(mouseDigit)
                    if d == 1 then return { Type = "Mouse", Code = Enum.UserInputType.MouseButton1 } end
                    if d == 2 then return { Type = "Mouse", Code = Enum.UserInputType.MouseButton2 } end
                    if d == 3 then return { Type = "Mouse", Code = Enum.UserInputType.MouseButton3 } end

                end


                if s:match("^MB%d") or s:match("^MOUSE%d") or s:match("^MOUSEBUTTON") then
                    local num = s:match("%d+")
                    if num == "1" then return { Type = "Mouse", Code = Enum.UserInputType.MouseButton1 } end
                    if num == "2" then return { Type = "Mouse", Code = Enum.UserInputType.MouseButton2 } end
                    if num == "3" then return { Type = "Mouse", Code = Enum.UserInputType.MouseButton3 } end
                end


                if Enum.KeyCode[s] then
                    return { Type = "Key", Code = Enum.KeyCode[s] }
                end


                if #s == 1 and Enum.KeyCode[s] then
                    return { Type = "Key", Code = Enum.KeyCode[s] }
                end


                local maybe = s:gsub("_", "")
                if Enum.KeyCode[maybe] then
                    return { Type = "Key", Code = Enum.KeyCode[maybe] }
                end
            end


            return { Type = "Key", Code = Enum.KeyCode.R }
        end


        if Tabs and Tabs.Combat then
            uiToggle = SafeAddToggle(Tabs.Combat, "SilentAimToggle", { Title = "SilentAim", Default = false })
            uiKeybind = SafeAddKeybind(Tabs.Combat, "SilentAimKey", { Title = "Silent Aim Key", Mode = "Toggle", Default = "R" })

            pcall(function() if uiToggle.SetValue then uiToggle:SetValue(false) end end)
            pcall(function() if uiKeybind.SetValue then uiKeybind:SetValue("R", "Toggle") end end)


            pcall(function()
                uiToggle:OnChanged(function(val)
                    if typeof(Fluent) == "table" and type(Fluent.Notify) == "function" then
                        Fluent:Notify({ Title = "Silent Aim", Content = val and "Enabled" or "Disabled", Duration = 2 })
                    end

                end)
            end)

            pcall(function()
                uiKeybind:OnChanged(function(v)
                    configuredInput = ParseKeybindValue(v)
                    if typeof(Fluent) == "table" and type(Fluent.Notify) == "function" then
                        Fluent:Notify({ Title = "Silent Aim", Content = "Keybind: "..tostring(v), Duration = 2 })
                    end
                end)
            end)


            pcall(function()
                local raw = nil
                if uiKeybind then
    
                    if uiKeybind.Value ~= nil then raw = uiKeybind.Value
                    elseif uiKeybind.GetState and type(uiKeybind.GetState) == "function" then

                        pcall(function() raw = uiKeybind:GetState() end)
                    elseif uiKeybind.GetValue and type(uiKeybind.GetValue) == "function" then
                        pcall(function() raw = uiKeybind:GetValue() end)
                    end
                end
                if raw ~= nil then
                    configuredInput = ParseKeybindValue(raw)
                else
                    configuredInput = { Type = "Key", Code = Enum.KeyCode.R }
                end
            end)
        else

            configuredInput = { Type = "Key", Code = Enum.KeyCode.R }
            warn("[SilentAimFast] Tabs.Combat not found; using fallback key R.")
        end


        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            local enabled = false
            if uiToggle then
                local ok, v = pcall(function()
                    if uiToggle.GetState then return uiToggle:GetState() end
                    if uiToggle.GetValue then return uiToggle:GetValue() end
                    if uiToggle.Value ~= nil then return uiToggle.Value end
                    if Options and Options.SilentAimToggle and Options.SilentAimToggle.Value ~= nil then return Options.SilentAimToggle.Value end
                    return false
                end)
                if ok then enabled = v end
            else
                enabled = true 
            end
            if not enabled then return end


            local matched = false
            if configuredInput.Type == "Mouse" then
                if input.UserInputType == configuredInput.Code then matched = true end
            else
                if input.KeyCode == configuredInput.Code then matched = true end
            end
            if not matched then return end


            pcall(function()
                local ok = SilentShootOnceFast()
                if ok and typeof(Fluent) == "table" and type(Fluent.Notify) == "function" then
                    Fluent:Notify({ Title = "Silent Aim", Content = "Shot fired", Duration = 0.6 })
                end
            end)
        end)
        if LocalPlayer then
            LocalPlayer.CharacterAdded:Connect(function(char)

                task.spawn(function()
                    local hum = char:WaitForChild("Humanoid", 10)
                    if hum then
                        hum.Died:Connect(function()
                            ResetCaches()
                        end)
                    end
                end)
            end)
            LocalPlayer.CharacterRemoving:Connect(function()
                ResetCaches()
            end)
        end



        local Section = Tabs.Combat:AddSection("Murder")

            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local LocalPlayer = Players.LocalPlayer


            local killActive = false
            local attackDelay = 0.15
            local targetRoles = {"Sheriff", "Hero", "Innocent"}

    
            local function getPlayerRole(player)
                local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
                if roles and roles[player.Name] then
                    return roles[player.Name].Role
                end
            end

            local function equipKnife()
                local char = LocalPlayer.Character
                if not char then return false end
                if char:FindFirstChild("Knife") then return true end

                local knife = LocalPlayer.Backpack:FindFirstChild("Knife")
                if knife then
                    knife.Parent = char
                    return true
                end
                return false
            end

            local function getNearestTarget()
                local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not localRoot then return nil end

                local targets = {}
                local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()

                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and roles and roles[player.Name] then
                        local role = roles[player.Name].Role
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")

                        if table.find(targetRoles, role) and humanoid and humanoid.Health > 0 and targetRoot then
                            table.insert(targets, {
                                Player = player,
                                Distance = (localRoot.Position - targetRoot.Position).Magnitude
                            })
                        end
                    end
                end

                table.sort(targets, function(a, b) return a.Distance < b.Distance end)
                return targets[1] and targets[1].Player or nil
            end
            local function attackTarget(target)
                if not target or not target.Character then return false end
                local humanoid = target.Character:FindFirstChild("Humanoid")
                if not humanoid or humanoid.Health <= 0 then return false end

                if not equipKnife() then return false end

                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                if targetRoot and localRoot then
                    localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1.5)
                end

                local knife = LocalPlayer.Character:FindFirstChild("Knife")
                if knife and knife:FindFirstChild("Stab") then
                    for _ = 1, 5 do 
                        knife.Stab:FireServer("Down")
                    end
                    return true
                end
                return false
            end

            local function killTargets()
                if killActive then return end
                killActive = true

                task.spawn(function()
                    while killActive do
                        local target = getNearestTarget()
                        if not target then
                            killActive = false
                            break
                        end
                        attackTarget(target)
                        task.wait(attackDelay)
                    end
                end)
            end

            local function stopKilling()
                killActive = false
            end

           
            local Toggle = Tabs.Combat:AddToggle("KillAllToggle", {Title = "Kill All", Default = false})
            Toggle:OnChanged(function()
                if Options.KillAllToggle.Value then
                    killTargets()
                else
                    stopKilling()
                end
            end)

           
            local Slider = Tabs.Combat:AddSlider("KillAllDelay", {
                Title = "Attack Delay",
                Default = 0.15,
                Min = 0.05,
                Max = 1,
                Rounding = 2,
                Callback = function(Value)
                    attackDelay = Value
                end
            })
            Slider:OnChanged(function(Value)
                attackDelay = Value
            end)

            Tabs.Combat:AddButton({
                Title = "Equip Knife",
                Callback = function()
                    equipKnife()
                end
            })
end
do

    local Section = Tabs.Trolling:AddSection("Fling")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local trollTarget = nil
    local FlingActive = false
    getgenv().OldPos = nil
    getgenv().FPDH = workspace.FallenPartsDestroyHeight

    local function updateTrollingPlayers()
        local playersList = {"Select Player"}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(playersList, player.Name)
            end
        end
        return playersList
    end

 
    local Dropdown = Tabs.Trolling:AddDropdown("PlayerTrolling", {
        Title = "Players",
        Values = updateTrollingPlayers(),
        Multi = false,
        Default = "Select Player"
    })

    Dropdown:OnChanged(function(selected)
        if selected ~= "Select Player" then
            trollTarget = Players:FindFirstChild(selected)
        else
            trollTarget = nil
        end
    end)

 
    Players.PlayerAdded:Connect(function()
        task.wait(1)
        Dropdown:SetValues(updateTrollingPlayers())
    end)

    Players.PlayerRemoving:Connect(function()
        Dropdown:SetValues(updateTrollingPlayers())
    end)


    local function Message(Title, Text, Time)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = Title,
            Text = Text,
            Duration = Time or 5
        })
    end


    local function SkidFling(TargetPlayer)
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        local TCharacter = TargetPlayer and TargetPlayer.Character
        if not TCharacter then return end

        local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        local TRootPart = THumanoid and THumanoid.RootPart
        local THead = TCharacter:FindFirstChild("Head")
        local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
        local Handle = Accessory and Accessory:FindFirstChild("Handle")

        if Character and Humanoid and RootPart then
            if RootPart.Velocity.Magnitude < 50 then
                getgenv().OldPos = RootPart.CFrame
            end

            if THumanoid and THumanoid.Sit then
                return Message("Error", TargetPlayer.Name .. " is sitting", 2)
            end

            if THead then
                workspace.CurrentCamera.CameraSubject = THead
            elseif Handle then
                workspace.CurrentCamera.CameraSubject = Handle
            elseif THumanoid and TRootPart then
                workspace.CurrentCamera.CameraSubject = THumanoid
            end

            if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

            local FPos = function(BasePart, Pos, Ang)
                RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            end

            local SFBasePart = function(BasePart)
                local TimeToWait = 2
                local Time = tick()
                local Angle = 0
                repeat
                    if RootPart and THumanoid then
                        if BasePart.Velocity.Magnitude < 50 then
                            Angle = Angle + 100
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                        else
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                            task.wait()
                        end
                    end
                until Time + TimeToWait < tick() or not FlingActive
            end

            workspace.FallenPartsDestroyHeight = 0/0

            local BV = Instance.new("BodyVelocity")
            BV.Parent = RootPart
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

            if TRootPart then
                SFBasePart(TRootPart)
            elseif THead then
                SFBasePart(THead)
            elseif Handle then
                SFBasePart(Handle)
            else
                return Message("Error", TargetPlayer.Name .. " has no valid parts", 2)
            end

            BV:Destroy()
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            workspace.CurrentCamera.CameraSubject = Humanoid

            if getgenv().OldPos then
                repeat
                    RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                    Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                    Humanoid:ChangeState("GettingUp")
                    for _, part in pairs(Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                        end
                    end
                    task.wait()
                until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
                workspace.FallenPartsDestroyHeight = getgenv().FPDH
            end
        else
            return Message("Error", "Your character is not ready", 2)
        end
    end

    Tabs.Trolling:AddButton({
    Title = "Fling Target",
    Description = "",
    Callback = function()
        if not trollTarget or not trollTarget:IsA("Player") then
            return Message("Error", "No player selected", 2)
        end

        FlingActive = true
        task.spawn(function()
            SkidFling(trollTarget)
            FlingActive = false
            UpdateStatus()
        end)
    end
})
    local Section = Tabs.Trolling:AddSection("Fling roles")

    Tabs.Trolling:AddButton({
        Title = "Fling Sheriff",
        Description = "",
        Callback = function()
            local sheriff = nil
            local players = game:GetService("Players")

            
            for _, player in ipairs(players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and player.Character then
                    local hasGunInChar = player.Character:FindFirstChild("Gun")
                    local hasGunInBackpack = player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun")

                    if hasGunInChar or hasGunInBackpack then
                        sheriff = player
                        break
                    end
                end
            end

            
            if sheriff then
                FlingActive = true
                task.spawn(function()
                    SkidFling(sheriff)
                    FlingActive = false
                    UpdateStatus()
                end)
            else
                Message("Info", "Sheriff not found", 3)
            end
        end
    })
    Tabs.Trolling:AddButton({
        Title = "Fling Murderer",
        Description = "",
        Callback = function()
            local murderer = nil
            local players = game:GetService("Players")
            for _, player in ipairs(players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and player.Character then
                    local hasKnifeInChar = player.Character:FindFirstChild("Knife")
                    local hasKnifeInBackpack = player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife")

                    if hasKnifeInChar or hasKnifeInBackpack then
                        murderer = player
                        break
                    end
                end
            end
            if murderer then
                FlingActive = true
                task.spawn(function()
                    SkidFling(murderer)
                    FlingActive = false
                    UpdateStatus()
                end)
            else
                Message("Info", "Murderer not found", 3)
            end
        end
    })
end
do
        local Section = Tabs.AutoFarm:AddSection("AutoFarm")
        local SmoothSaveMode = false
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        local LP = Players.LocalPlayer
        local AutoFarmRunning = false
        local Mode = "Smooth"
        local TeleportDelay = 3
        local SmoothSpeed = 25
        local SpawnCFrame = CFrame.new(112.961197, 140.252960, 46.383835)
        local Maps = {
            "Factory","Hospital3","MilBase","House2","Workplace","Mansion2",
            "BioLab","Hotel","Bank2","PoliceStation","ResearchFacility",
            "Lobby","BeachResort", "Yacht", "Office3"
        }
        local function IsCollectableCoin(part)
            return part:FindFirstChild("TouchInterest") ~= nil
        end
        local function GetClosestCoin()
            if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return nil end
            local hrp = LP.Character.HumanoidRootPart
            local closest, bestDist = nil, math.huge
            for _, mapName in ipairs(Maps) do
                local map = Workspace:FindFirstChild(mapName)
                if map and map:FindFirstChild("CoinContainer") then
                    for _, coin in ipairs(map.CoinContainer:GetChildren()) do
                        if IsCollectableCoin(coin) then
                            local pos = coin.Position
                            if pos then
                                local dist = (hrp.Position - pos).Magnitude
                                if dist < bestDist then
                                    bestDist = dist
                                    closest = coin
                                end
                            end
                        end
                    end
                end
            end
            return closest
        end
        local function IsCoinBagVisible()
            local gui = LP:FindFirstChild("PlayerGui")
            if not gui then return false end

            local beachBall = gui:FindFirstChild("MainGUI", true)
                and gui.MainGUI:FindFirstChild("Game", true)
                and gui.MainGUI.Game:FindFirstChild("CoinBags", true)
                and gui.MainGUI.Game.CoinBags:FindFirstChild("Container", true)
                and gui.MainGUI.Game.CoinBags.Container:FindFirstChild("BeachBall")
            return beachBall and beachBall.Visible
        end
        local function IsBagFull()
            local gui = LP:FindFirstChild("PlayerGui")
            if not gui then return false end
            local fullLabel = gui:FindFirstChild("MainGUI", true)
                and gui.MainGUI:FindFirstChild("Game", true)
                and gui.MainGUI.Game:FindFirstChild("CoinBags", true)
                and gui.MainGUI.Game.CoinBags:FindFirstChild("Container", true)
                and gui.MainGUI.Game.CoinBags.Container:FindFirstChild("BeachBall", true)
                and gui.MainGUI.Game.CoinBags.Container.BeachBall:FindFirstChild("Full")
            return fullLabel and fullLabel.Visible
        end
        local function KillPlayer()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
        local function TeleportFarm()
            local coin = GetClosestCoin()
            if coin and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local pos = coin.Position
                LP.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
                task.wait(0.3)
                LP.Character.HumanoidRootPart.CFrame = SpawnCFrame
            end
        end
        local function SmoothFarm()
        local coin = GetClosestCoin()
        if coin and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local pos = coin.Position
            local hrp = LP.Character.HumanoidRootPart
            local dist = (pos - hrp.Position).Magnitude
            if dist > 0 then
                local totalTime = dist / SmoothSpeed
                local start = tick()
                local startPos = hrp.Position
                while tick() - start < totalTime do
                    if not AutoFarmRunning or not IsCoinBagVisible() then return end
                    local alpha = (tick() - start) / totalTime
                    local interpolated = startPos:Lerp(pos, alpha)
                    if SmoothSaveMode then
                        interpolated = interpolated - Vector3.new(0, 2.5, 0)
                        hrp.CFrame = CFrame.new(interpolated) * CFrame.Angles(math.rad(90), 0, 0)
                    else
                        hrp.CFrame = CFrame.new(interpolated)
                    end

                    task.wait(0.015) 
                end
            end
        end
    end
        task.spawn(function()
            while true do
                task.wait(0.8)
                if AutoFarmRunning then
                    if not IsCoinBagVisible() then
                        continue
                    end
                    if IsBagFull() then
                        print("Мешок заполнен. Самоубийство.")
                        KillPlayer()
                        continue
                    end
                    if Mode == "Teleport" then
                        task.wait(TeleportDelay)
                        TeleportFarm()
                    else
                        SmoothFarm()
                    end
                end
            end
        end)
        local Dropdown = Tabs.AutoFarm:AddDropdown("", {
            Title = "AutoFarm Mode",
            Values = { "Teleport", "Smooth" },
            Multi = false,
            Default = "Smooth",
        })
        Dropdown:SetValue("Smooth")
        Dropdown:OnChanged(function(Value)
            Mode = Value
            print("Режим фарма:", Value)
        end)
        local SliderTeleport = Tabs.AutoFarm:AddSlider("", {
            Title = "Teleportation frequency",
            Description = "",
            Default = TeleportDelay,
            Min = 0,
            Max = 5,
            Rounding = 1,
        })
        SliderTeleport:OnChanged(function(Value)
            TeleportDelay = Value
        end)
        local SliderSmooth = Tabs.AutoFarm:AddSlider("", {
            Title = "Smoothness Move Speed",
            Description = "",
            Default = SmoothSpeed,
            Min = 20,
            Max = 100,
            Rounding = 1,
        })
        SliderSmooth:OnChanged(function(Value)
            SmoothSpeed = Value
        end)
        local Toggle = Tabs.AutoFarm:AddToggle("", {
            Title = "EnableAutoFarm",
            Default = false,
        })
        Toggle:OnChanged(function(Value)
            AutoFarmRunning = Value
            print("AutoFarm:", Value and "Включен" or "Выключен")
        end)   
        local SmoothSaveToggle = Tabs.AutoFarm:AddToggle("", {
        Title = "Save Mode for Smooth",
        Description = "",
        Default = false,
    })
    SmoothSaveToggle:OnChanged(function(Value)
        SmoothSaveMode = Value
        print("Save Mode:", Value and "ВКЛ" or "ВЫКЛ")
    end)
    local mapNames = {
        "ResearchFacility", "Hospital3", "MilBase", "House2", "Workplace",
        "Mansion2", "BioLab", "Hotel", "Factory", "Bank2", "PoliceStation", "BeachResort", "Yacht", "Office3"
    }
    local function getAllCoins()
        local coins = {}
        local workspace = game:GetService("Workspace")
        for _, mapName in pairs(mapNames) do
            local mapFolder = workspace:FindFirstChild(mapName)
            if mapFolder then
                local coinContainer = mapFolder:FindFirstChild("CoinContainer")
                if coinContainer then
                    for _, child in pairs(coinContainer:GetChildren()) do
                        if child:IsA("BasePart") and child:FindFirstChildWhichIsA("TouchTransmitter") then
                            table.insert(coins, child)
                        end
                    end
                end
            end
        end
        return coins
    end
    local function clearBoxes()
        for _, adorn in pairs(game:GetService("CoreGui"):GetChildren()) do
            if adorn:IsA("BoxHandleAdornment") and adorn.Name == "CoinESP" then
                adorn:Destroy()
            end
        end
    end
    local function showBoxes()
        clearBoxes()
        local coins = getAllCoins()
        for _, coin in pairs(coins) do
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "CoinESP"
            box.Adornee = coin
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Size = coin.Size
            box.Color3 = Color3.fromRGB(255, 215, 0) 
            box.Transparency = 0.3
            box.Parent = game:GetService("CoreGui")
        end
    end
    local isRunning = false
    local function startCoinESP()
        if isRunning then return end
        isRunning = true
        task.spawn(function()
            while isRunning do
                showBoxes()
                task.wait(1.2)
            end
        end)
    end
    local function stopCoinESP()
        isRunning = false
        clearBoxes()
    end
    local Toggle = Tabs.AutoFarm:AddToggle("MyToggle", {
        Title = "Showing coins through walls",
        Default = false
    })
    Toggle:OnChanged(function(value)
        if value then
            startCoinESP()
        else
            stopCoinESP()
        end
    end)
    Options.MyToggle:SetValue(false)
end
do
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local Camera = workspace.CurrentCamera
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local function getPlayerRole(player)
            local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if roles then
                local data = roles:InvokeServer()
                if data and data[player.Name] then
                    return data[player.Name].Role
                end
            end
            return nil
        end
        local function trackPlayer(player)
            if player and player.Character and player.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
                Fluent:Notify({
                    Title = "Spectator",
                    Content = "Now spectating: " .. player.Name,
                    Duration = 2
                })
            end
        end
        local function returnToSelf()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
                Fluent:Notify({
                    Title = "Spectator",
                    Content = "Returned to yourself",
                    Duration = 2
                })
            end
        end
        local function getPlayerList()
            local list = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    table.insert(list, p.Name)
                end
            end
            return list
        end
            local Section = Tabs.Spectator:AddSection("Tracker")
        local Dropdown = Tabs.Spectator:AddDropdown("SpectateDropdown", {
            Title = "Select Player",
            Values = getPlayerList(),
            Multi = false,
            Default = 1,
        })

        local selectedPlayerName = Dropdown.Value

        Dropdown:OnChanged(function(Value)
            selectedPlayerName = Value
            Fluent:Notify({
                Title = "Spectator",
                Content = "Selected player: " .. Value,
                Duration = 2
            })
        end)
        Tabs.Spectator:AddButton({
            Title = "Spectate the selected player",
            Description = "",
            Callback = function()
                local player = Players:FindFirstChild(selectedPlayerName)
                if player then
                    trackPlayer(player)
                else
                    Fluent:Notify({
                        Title = "Spectator",
                        Content = "Player not found",
                        Duration = 2
                    })
                end
            end
        })
        local Section = Tabs.Spectator:AddSection("Spectate to roles")
        Tabs.Spectator:AddButton({
            Title = "Spectate the Sheriff",
            Description = "",
            Callback = function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and getPlayerRole(player) == "Sheriff" then
                        trackPlayer(player)
                        return
                    end
                end
                Fluent:Notify({
                    Title = "Spectator",
                    Content = "Sheriff not found",
                    Duration = 2
                })
            end
        })
        Tabs.Spectator:AddButton({
            Title = "Spectate the Murder",
            Description = "",
            Callback = function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and getPlayerRole(player) == "Murderer" then
                        trackPlayer(player)
                        return
                    end
                end
                Fluent:Notify({
                    Title = "Spectator",
                    Content = "Murder not found",
                    Duration = 2
                })
            end
        })
        local Section = Tabs.Spectator:AddSection("Spectate to yourself")
        Tabs.Spectator:AddButton({
            Title = "Return to yourself",
            Description = "Stop spectating and return",
            Callback = function()
                returnToSelf()
            end
        })
        Players.PlayerAdded:Connect(function()
            Dropdown:SetValues(getPlayerList())
        end)
        Players.PlayerRemoving:Connect(function()
            Dropdown:SetValues(getPlayerList())
        end)
end
do
    local Section = Tabs.Other:AddSection("Other")
    local VirtualUser = game:GetService("VirtualUser")
    local antiAFKEnabled = false
    local antiAFKThread
    local delayMinutes = 5
    Tabs.Other:AddToggle("AntiAFK", {
        Title = "Anti-AFK",
        Default = false,
        Callback = function(state)
            antiAFKEnabled = state
            if state then
                antiAFKThread = task.spawn(function()
                    while antiAFKEnabled do
                        task.wait(delayMinutes * 60)
                        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        task.wait(0.1)
                        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        Fluent:Notify({
                            Title = "Anti-AFK",
                            Content = "Activity simulated after " .. delayMinutes .. " min",
                            Duration = 2
                        })
                    end
                end)
                Fluent:Notify({
                    Title = "Anti-AFK",
                    Content = "Anti-AFK activated (every " .. delayMinutes .. " min)",
                    Duration = 2
                })
            else
                antiAFKEnabled = false
                Fluent:Notify({
                    Title = "Anti-AFK",
                    Content = "Anti-AFK deactivated",
                    Duration = 2
                })
            end
        end
    })
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local AntiFlingToggle = Tabs.Other:AddToggle("AntiFling", {Title = "Anti-Fling", Default = false})
        local function AntiFling()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.Velocity.Magnitude > 100 then
                        part.Velocity = Vector3.zero
                    end
                    if part.RotVelocity.Magnitude > 100 then
                        part.RotVelocity = Vector3.zero
                    end
                    if part.Velocity.Magnitude > 2000 then
                        part.Anchored = true
                        task.delay(0.1, function()
                            if part then part.Anchored = false end
                        end)
                    end
                end
            end
        end
        AntiFlingToggle:OnChanged(function(state)
            if state then
                getgenv().AntiFlingActive = true
                task.spawn(function()
                    while getgenv().AntiFlingActive do
                        AntiFling()
                        task.wait(0.1) -- проверка каждые 0.1 сек
                    end
                end)
            else
                getgenv().AntiFlingActive = false
            end
        end)
    local Section = Tabs.Other:AddSection("X-ray")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local LP = Players.LocalPlayer
    local XrayEnabled = false
    local XrayTransparency = 0.4 
    local XrayLoop
    local function SetXrayTransparency(transparency)
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(LP.Character or Instance.new("Model")) then
                if v.Transparency ~= transparency then
                    pcall(function()
                        v.LocalTransparencyModifier = transparency
                    end)
                end
            end
        end
    end

    local function ResetXray()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(LP.Character or Instance.new("Model")) then
                pcall(function()
                    v.LocalTransparencyModifier = 0
                end)
            end
        end
    end
   local function ToggleXrayLoop(state)
    if state then
        XrayLoop = task.spawn(function()
            while XrayEnabled do
                SetXrayTransparency(XrayTransparency)
                task.wait(1.5)
            end
        end)
    else
        if XrayLoop then
            task.cancel(XrayLoop)
            XrayLoop = nil
        end
        ResetXray() 
    end
end
    local XrayToggle = Tabs.Other:AddToggle("MyToggle", {
        Title = "X-ray Mode",
        Default = false
    })
    XrayToggle:OnChanged(function(Value)
        XrayEnabled = Value
        ToggleXrayLoop(Value)
        print("X-ray mode:", Value and "ВКЛ" or "ВЫКЛ")
    end)
    Options.MyToggle:SetValue(false)
    local XraySlider = Tabs.Other:AddSlider("Slider", {
        Title = "X-ray Intensity",
        Description = "",
        Default = 40, -- 40%
        Min = 20,
        Max = 80,
        Rounding = 0,
        Callback = function(Value)
            XrayTransparency = Value / 100
            print("X-ray Transparency set to:", XrayTransparency)
            if XrayEnabled then
                SetXrayTransparency(XrayTransparency)
            end
        end
    })
    XraySlider:SetValue(40)
end
do

        local Section = Tabs.Server:AddSection("Actions with the server")
        local function RejoinGame()
        local TeleportService = game:GetService("TeleportService")
        local placeId = game.PlaceId  
        local serverId = game.JobId  
        TeleportService:TeleportToPlaceInstance(placeId, serverId, game.Players.LocalPlayer)
    end
    Tabs.Server:AddButton({
        Title = "Rejoin Game",  
        Description = "", 
        Callback = function()
            RejoinGame()  
        end
    })
        local function ServerHop()
        local TeleportService = game:GetService("TeleportService")
        local placeId = game.PlaceId 
        TeleportService:Teleport(placeId, game.Players.LocalPlayer)
    end
    Tabs.Server:AddButton({
        Title = "Server Hop",  
        Description = "",  
        Callback = function()
            ServerHop()  
        end
    })
end
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({""})

InterfaceManager:SetFolder("FluentConfig")
SaveManager:SetFolder("FluentConfig/MM2")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

loadstring(game:HttpGet("https://raw.githubusercontent.com/LenivayZopaKotaWork/Pluty-Hub/refs/heads/main/qwerty.lua"))()



		local UIS = game:GetService("UserInputService")
		local VirtualInputManager = game:GetService("VirtualInputManager")
		local Players = game:GetService("Players")
		
		local player = Players.LocalPlayer
		local playerGui = player:WaitForChild("PlayerGui")
		
		-- === Создаём GUI ===
		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Name = "MobileMenuButton"
		ScreenGui.Parent = playerGui
		ScreenGui.IgnoreGuiInset = true
		ScreenGui.ResetOnSpawn = false
		
		local ImageButton = Instance.new("ImageButton")
		ImageButton.Size = UDim2.new(0, 80, 0, 80)
		ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
		ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0) -- По центру
		ImageButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		ImageButton.Image = "" -- можно вставить иконку
		ImageButton.Parent = ScreenGui
		
		-- Если хотим скрывать на ПК — можно раскомментировать:
		-- if not UIS.TouchEnabled then ImageButton.Visible = false end
		
		-- === Ограничение, чтобы кнопка не вылазила за экран ===
		local function adjustButtonPosition()
		    local screenWidth = ScreenGui.AbsoluteSize.X
		    local screenHeight = ScreenGui.AbsoluteSize.Y
		    local buttonWidth = ImageButton.Size.X.Offset
		    local buttonHeight = ImageButton.Size.Y.Offset
		
		    local posX = math.clamp(ImageButton.Position.X.Offset, 0, screenWidth - buttonWidth)
		    local posY = math.clamp(ImageButton.Position.Y.Offset, 0, screenHeight - buttonHeight)
		
		    ImageButton.Position = UDim2.new(0, posX, 0, posY)
		end
		
		ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(adjustButtonPosition)
		adjustButtonPosition()
		
		-- === При клике эмулируем LeftControl ===
		local function pressKey(keyCode)
		    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		    task.wait(0.05)
		    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
		end
		
		ImageButton.MouseButton1Click:Connect(function()
		    pressKey(Enum.KeyCode.LeftControl)
		end)
		
		-- === Перетаскивание ===
		local dragging = false
		local dragInput, dragStart, startPos
		
		ImageButton.InputBegan:Connect(function(input)
		    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		        dragging = true
		        dragStart = input.Position
		        startPos = ImageButton.Position
		
		        input.Changed:Connect(function()
		            if input.UserInputState == Enum.UserInputState.End then
		                dragging = false
		                adjustButtonPosition()
		            end
		        end)
		    end
		end)
		
		ImageButton.InputChanged:Connect(function(input)
		    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		        dragInput = input
		    end
		end)
		
		UIS.InputChanged:Connect(function(input)
		    if input == dragInput and dragging then
		        local delta = input.Position - dragStart
		        ImageButton.Position = UDim2.new(
		            startPos.X.Scale,
		            startPos.X.Offset + delta.X,
		            startPos.Y.Scale,
		            startPos.Y.Offset + delta.Y
		        )
		    end
		end)



			----Button
												-- === КНОПКА SILENT AIM ДЛЯ МОБИЛКИ ===
						local UIS = game:GetService("UserInputService")
						local VirtualInputManager = game:GetService("VirtualInputManager")
						local Players = game:GetService("Players")
						local TweenService = game:GetService("TweenService")
						
						local player = Players.LocalPlayer
						local playerGui = player:WaitForChild("PlayerGui")
						
						-- === Создаём GUI ===
						local ScreenGui = Instance.new("ScreenGui")
						ScreenGui.Name = "SilentAimButton"
						ScreenGui.Parent = playerGui
						ScreenGui.IgnoreGuiInset = true
						ScreenGui.ResetOnSpawn = false
						
						-- === Надпись ===
						local Label = Instance.new("TextLabel")
						Label.Size = UDim2.new(0, 80, 0, 18)
						Label.AnchorPoint = Vector2.new(0.5, 1)
						Label.BackgroundTransparency = 1
						Label.Text = "Silent Aim"
						Label.TextColor3 = Color3.fromRGB(255, 255, 255)
						Label.TextScaled = true
						Label.Font = Enum.Font.GothamBold
						Label.Parent = ScreenGui
						
						local strokeText = Instance.new("UIStroke")
						strokeText.Thickness = 2
						strokeText.Color = Color3.fromRGB(0, 0, 0)
						strokeText.Parent = Label
						
						-- === Кнопка ===
						local ImageButton = Instance.new("ImageButton")
						ImageButton.Size = UDim2.new(0, 60, 0, 60) -- Меньше размера
						ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
						ImageButton.Position = UDim2.new(0.85, 0, 0.5, 0)
						ImageButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Тёмно-серый фон
						ImageButton.Image = "rbxassetid://1648938003"
						ImageButton.Parent = ScreenGui
						
						-- Обводка кнопки (красная)
						local buttonStroke = Instance.new("UIStroke")
						buttonStroke.Thickness = 3
						buttonStroke.Color = Color3.fromRGB(255, 0, 0)
						buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
						buttonStroke.Parent = ImageButton
						
						-- === Подсветка при наведении ===
						ImageButton.MouseEnter:Connect(function()
						    TweenService:Create(buttonStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(255, 80, 80)}):Play()
						end)
						ImageButton.MouseLeave:Connect(function()
						    TweenService:Create(buttonStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(255, 0, 0)}):Play()
						end)
						
						-- === Функция нажатия клавиши ===
						local function pressKey(keyCode)
						    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
						    task.wait(0.05)
						    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
						end
						
						-- === Анимация клика ===
						local function animateClick()
						    local tweenDown = TweenService:Create(ImageButton, TweenInfo.new(0.08), {Size = UDim2.new(0, 54, 0, 54)})
						    local tweenUp = TweenService:Create(ImageButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 60, 0, 60)})
						    tweenDown:Play()
						    tweenDown.Completed:Wait()
						    tweenUp:Play()
						end
						
						-- === При клике нажимаем R ===
						ImageButton.MouseButton1Click:Connect(function()
						    animateClick()
						    pressKey(Enum.KeyCode.R)
						end)
						
						-- === Перетаскивание ===
						local dragging, dragInput, dragStart, startPos
						
						local function adjustButtonPosition()
						    local screenWidth, screenHeight = ScreenGui.AbsoluteSize.X, ScreenGui.AbsoluteSize.Y
						    local buttonWidth, buttonHeight = ImageButton.Size.X.Offset, ImageButton.Size.Y.Offset
						
						    local posX = math.clamp(ImageButton.Position.X.Offset, 0, screenWidth - buttonWidth)
						    local posY = math.clamp(ImageButton.Position.Y.Offset, 0, screenHeight - buttonHeight)
						
						    ImageButton.Position = UDim2.new(0, posX, 0, posY)
						    Label.Position = UDim2.new(0, posX + buttonWidth / 2, 0, posY - 3)
						end
						
						ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(adjustButtonPosition)
						
						ImageButton.InputBegan:Connect(function(input)
						    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						        dragging = true
						        dragStart = input.Position
						        startPos = ImageButton.Position
						
						        input.Changed:Connect(function()
						            if input.UserInputState == Enum.UserInputState.End then
						                dragging = false
						                adjustButtonPosition()
						            end
						        end)
						    end
						end)
						
						ImageButton.InputChanged:Connect(function(input)
						    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						        dragInput = input
						    end
						end)
						
						UIS.InputChanged:Connect(function(input)
						    if input == dragInput and dragging then
						        local delta = input.Position - dragStart
						        ImageButton.Position = UDim2.new(
						            startPos.X.Scale,
						            startPos.X.Offset + delta.X,
						            startPos.Y.Scale,
						            startPos.Y.Offset + delta.Y
						        )
						        Label.Position = UDim2.new(
						            startPos.X.Scale,
						            startPos.X.Offset + delta.X + ImageButton.Size.X.Offset / 2,
						            startPos.Y.Scale,
						            startPos.Y.Offset + delta.Y - 3
						        )
						    end
						end)
						
						task.delay(0.1, function()
						    ImageButton.Position = UDim2.new(0.85, 0, 0.5, 0)
						    Label.Position = UDim2.new(0.85, 0, 0.5, -33)
						end)

