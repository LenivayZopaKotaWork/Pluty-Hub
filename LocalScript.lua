-- Mobile toggle button (LocalScript) --
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- !!! Заменяй путь к InterfaceManager, если он не в ReplicatedStorage !!!
local successRequire, InterfaceManager = pcall(function()
	return require(game:GetService("ReplicatedStorage"):WaitForChild("InterfaceManager"))
end)
if not successRequire then
	warn("MobileMenuButton: failed to require InterfaceManager. Change the require() path if needed.")
	InterfaceManager = nil
end

-- helper: получить Enum.KeyCode по имени из настроек
local function getMenuKeyEnum()
	local name
	if InterfaceManager and InterfaceManager.Settings and InterfaceManager.Settings.MenuKeybind then
		name = InterfaceManager.Settings.MenuKeybind
	end
	if not name or name == "" then
		name = "LeftControl"
	end

	-- попытка взять Enum.KeyCode[name]
	local keyEnum = Enum.KeyCode[name]
	if not keyEnum then
		-- если пользователь мог указать односимвольную букву в нижнем регистре, попробуем заглавную
		if #name == 1 then
			keyEnum = Enum.KeyCode[string.upper(name)]
		end
	end
	return keyEnum or Enum.KeyCode.LeftControl
end

-- Попытка "запрессовать" клавишу через VirtualInputManager (работает в Studio / некоторых окружениях)
local function tryVirtualKeyPress(keyEnum)
	local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
	if not ok or not vim or type(vim.SendKeyEvent) ~= "function" then
		return false
	end

	local pressedOk, pressedErr = pcall(function()
		-- нажать
		vim:SendKeyEvent(true, keyEnum, false, game)
		task.wait(0.06)
		-- отпустить
		vim:SendKeyEvent(false, keyEnum, false, game)
	end)
	return pressedOk
end

-- Резервный способ: если библиотека (library) у InterfaceManager установлена и у неё есть метод toggle/open
local function tryLibraryToggle()
	if not InterfaceManager then return false end
	local lib = InterfaceManager.Library
	if not lib then return false end

	-- Попробуем несколько распространённых вариантов
	local tried = false
	local ok

	if type(lib.Toggle) == "function" then
		ok = pcall(function() lib:Toggle() end)
		tried = true
		if ok then return true end
	end

	if type(lib.ToggleMenu) == "function" then
		ok = pcall(function() lib:ToggleMenu() end)
		tried = true
		if ok then return true end
	end

	-- Если библиотека хранит GUI в поле Gui или Window - попытаемся переключить Visible/Enabled
	local guiCandidate = lib.Gui or lib.Window or lib.MainGui
	if typeof(guiCandidate) == "Instance" then
		tried = true
		ok = pcall(function()
			-- попытка переключить как Visible или Enabled
			if guiCandidate:IsA("ScreenGui") then
				guiCandidate.Enabled = not guiCandidate.Enabled
			elseif guiCandidate:FindFirstChildWhichIsA("Frame") or guiCandidate:IsA("Frame") then
				guiCandidate.Visible = not guiCandidate.Visible
			else
				-- общий fallback: попытаться сменить Visible если есть
				if guiCandidate.Visible ~= nil then
					guiCandidate.Visible = not guiCandidate.Visible
				end
			end
		end)
		if ok then return true end
	end

	-- Если библиотека сохранила Keybind UI (как в InterfaceManager: BuildInterfaceSection), попробуем вызвать у него возможные методы:
	if lib.MinimizeKeybind ~= nil then
		tried = true
		ok = pcall(function()
			-- возможные интерфейсы у keybind-контрола:
			if type(lib.MinimizeKeybind.Call) == "function" then
				lib.MinimizeKeybind:Call()
			elseif type(lib.MinimizeKeybind.Fire) == "function" then
				lib.MinimizeKeybind:Fire()
			elseif type(lib.MinimizeKeybind.SetValue) == "function" then
				-- если это UI элемент, ничего не делаем (на всякий случай)
				-- не трогаем SetValue, т.к. это изменит бинду
				error("MinimizeKeybind exists but has no callable action we can safely invoke.")
			else
				error("No callable on MinimizeKeybind")
			end
		end)
		if ok then return true end
	end

	return false
end

-- Создаём ScreenGui + кнопку (если уже есть — используем существующие)
local guiName = "MobileMenuButtonGui"
local screenGui = playerGui:FindFirstChild(guiName)
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = guiName
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
end

local btn = screenGui:FindFirstChild("MenuButton")
if not btn then
	btn = Instance.new("TextButton")
	btn.Name = "MenuButton"
	btn.Size = UDim2.new(0, 64, 0, 64)
	btn.Position = UDim2.new(0, 12, 0, 12)
	btn.AnchorPoint = Vector2.new(0, 0)
	btn.Text = "≡"
	btn.TextSize = 30
	btn.BackgroundTransparency = 0.15
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = screenGui
end

-- Показывать только на устройствах с тачем (телефоны/планшеты)
btn.Visible = UIS.TouchEnabled

-- Нажатие: сначала пробуем виртуальную клавишу, затем fallback библиотеке, если не получилось
btn.MouseButton1Click:Connect(function()
	-- берем Enum.KeyCode
	local keyEnum = getMenuKeyEnum()
	-- 1) попытка виртуального нажатия
	local ok = tryVirtualKeyPress(keyEnum)
	if ok then return end

	-- 2) fallback: попытка вызвать toggle у библиотеки
	local ok2 = tryLibraryToggle()
	if ok2 then return end

	-- 3) не удалось — логим
	warn("MobileMenuButton: не удалось симулировать нажатие клавиши и не найден toggle в библиотеке. Убедись, что VirtualInputManager доступен или что InterfaceManager.Library установлен и содержит метод Toggle/ToggleMenu/Gui.")
end)

-- ===== Перетаскивание кнопки (работает для touch и мыши) =====
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
	if not dragStart or not startPos then return end
	local delta = input.Position - dragStart
	btn.Position = UDim2.new(
		math.clamp(startPos.X.Scale, 0, 1),
		math.clamp(startPos.X.Offset + delta.X, 0, math.max(0, workspace.CurrentCamera.ViewportSize.X - btn.AbsoluteSize.X)),
		math.clamp(startPos.Y.Scale, 0, 1),
		math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(0, workspace.CurrentCamera.ViewportSize.Y - btn.AbsoluteSize.Y))
	)
end

btn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragInput = input
		dragStart = input.Position
		startPos = btn.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragInput = nil
				dragStart = nil
				startPos = nil
			end
		end)
	end
end)

-- отслеживаем движение курсора/пальца
UIS.InputChanged:Connect(function(input)
	if dragging and (input == dragInput) and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		update(input)
	end
end)

-- Конец скрипта
