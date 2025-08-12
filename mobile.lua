-- mobile.lua (ставить на raw.github и грузить через loadstring)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

-- проверяем, действительно ли устройство тачевое — если нет, выходим
if not UIS.TouchEnabled then
    -- не мобильное устройство — ничего не делаем
    return
end

-- Поиск ModuleScript InterfaceManager по всему дереву (ждём появления)
local function findModuleScriptByName(name, waitInterval)
    waitInterval = waitInterval or 0.4
    while true do
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("ModuleScript") and obj.Name == name then
                return obj
            end
        end
        task.wait(waitInterval)
    end
end

local moduleInst = findModuleScriptByName("InterfaceManager")
local ok, InterfaceManager = pcall(require, moduleInst)
if not ok or type(InterfaceManager) ~= "table" then
    warn("mobile.lua: не удалось require InterfaceManager; кнопка всё равно будет показываться, но бинду может не быть.")
    InterfaceManager = InterfaceManager or {}
end

-- Ждём, пока появятся Settings (если их нет)
if not InterfaceManager.Settings then
    local tries = 0
    repeat
        task.wait(0.2)
        tries = tries + 1
        if tries % 10 == 0 then
            -- попытаемся ре-require (на случай, если модуль перезаписали)
            local ok2, m = pcall(require, moduleInst)
            if ok2 and type(m) == "table" then InterfaceManager = m end
        end
    until InterfaceManager.Settings
end

-- Получаем имя бинда и мапим в Enum.KeyCode
local function getMenuKeyEnum()
    local name = "LeftControl" -- дефолт
    if InterfaceManager and InterfaceManager.Settings and type(InterfaceManager.Settings.MenuKeybind) == "string" and InterfaceManager.Settings.MenuKeybind ~= "" then
        name = InterfaceManager.Settings.MenuKeybind
    end

    local keyEnum = Enum.KeyCode[name]
    if not keyEnum and #name == 1 then
        keyEnum = Enum.KeyCode[string.upper(name)]
    end
    return keyEnum or Enum.KeyCode.LeftControl
end

-- Попытка отправить виртуальную клавишу (если доступен VirtualInputManager)
local function tryVirtualKeyPress(keyEnum)
    local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    if not ok or not vim or type(vim.SendKeyEvent) ~= "function" then
        return false
    end

    local success, err = pcall(function()
        vim:SendKeyEvent(true, keyEnum, false, game)
        task.wait(0.06)
        vim:SendKeyEvent(false, keyEnum, false, game)
    end)
    return success
end

-- Fallback: попробовать вызвать toggle у библиотеки (если InterfaceManager.Library существует)
local function tryLibraryToggle()
    if not InterfaceManager or not InterfaceManager.Library then return false end
    local lib = InterfaceManager.Library
    local ok

    if type(lib.Toggle) == "function" then
        ok = pcall(function() lib:Toggle() end)
        if ok then return true end
    end
    if type(lib.ToggleMenu) == "function" then
        ok = pcall(function() lib:ToggleMenu() end)
        if ok then return true end
    end

    -- попытка переключить видимость Gui/Window
    local guiCandidate = lib.Gui or lib.Window or lib.MainGui
    if typeof(guiCandidate) == "Instance" then
        ok = pcall(function()
            if guiCandidate:IsA("ScreenGui") then
                guiCandidate.Enabled = not guiCandidate.Enabled
            elseif guiCandidate:IsA("Frame") then
                guiCandidate.Visible = not guiCandidate.Visible
            else
                if guiCandidate.Visible ~= nil then
                    guiCandidate.Visible = not guiCandidate.Visible
                end
            end
        end)
        if ok then return true end
    end

    -- попытаться вызвать MinimizeKeybind (если это контрол с callable)
    if lib.MinimizeKeybind ~= nil then
        ok = pcall(function()
            if type(lib.MinimizeKeybind.Call) == "function" then
                lib.MinimizeKeybind:Call()
            elseif type(lib.MinimizeKeybind.Fire) == "function" then
                lib.MinimizeKeybind:Fire()
            else
                error("no callable on MinimizeKeybind")
            end
        end)
        if ok then return true end
    end

    return false
end

-- Создаём GUI (не будет пересоздан, если уже есть)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local guiName = "PlutyMobileMenuGui"
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
    btn.BackgroundTransparency = 0.12
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = screenGui
end

btn.Visible = true -- показываем, потому что мы загружены только на mobile

-- Ограничения на экран, чтобы не вытащить кнопку за пределы
local function clampPosition(xOffset, yOffset)
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local btnW, btnH = btn.AbsoluteSize.X, btn.AbsoluteSize.Y
    local x = math.clamp(xOffset, 0, math.max(0, viewport.X - btnW))
    local y = math.clamp(yOffset, 0, math.max(0, viewport.Y - btnH))
    return x, y
end

-- Нажатие по кнопке
btn.MouseButton1Click:Connect(function()
    local keyEnum = getMenuKeyEnum()
    local ok = tryVirtualKeyPress(keyEnum)
    if ok then return end
    -- fallback
    local ok2 = tryLibraryToggle()
    if ok2 then return end
    warn("mobile.lua: не удалось симулировать клавишу и не найден toggle в библиотеке.")
end)

-- Перетаскивание (touch / mouse)
local dragging = false
local dragInput, dragStartPos, startGuiPos

btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragInput = input
        dragStartPos = input.Position
        startGuiPos = btn.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging or input ~= dragInput then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        local newX = startGuiPos.X.Offset + delta.X
        local newY = startGuiPos.Y.Offset + delta.Y
        newX, newY = clampPosition(newX, newY)
        btn.Position = UDim2.new(0, newX, 0, newY)
    end
end)

-- Готово
print("mobile.lua: мобильная кнопка загружена")
