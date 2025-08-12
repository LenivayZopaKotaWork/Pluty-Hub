local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Подключаем InterfaceManager (замени путь на свой, если он в другом месте!)
local InterfaceManager = require(game.ReplicatedStorage:WaitForChild("InterfaceManager"))

-- Функция получения текущей клавиши из настроек Fluent
local function getMenuKeyCode()
    local keyName = InterfaceManager.Settings.MenuKeybind
    return Enum.KeyCode[keyName] or Enum.KeyCode.LeftControl
end

-- Создаём ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileMenuButton"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- Создаём кнопку
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 60, 0, 60)
button.Position = UDim2.new(0, 10, 0, 10)
button.Text = "≡"
button.TextSize = 30
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Parent = screenGui

-- Показывать кнопку только на телефонах
button.Visible = UIS.TouchEnabled

-- Нажатие по кнопке = имитация нажатия клавиши меню
button.MouseButton1Click:Connect(function()
    local keyCode = getMenuKeyCode()
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end)

-- Перетаскивание кнопки
local dragging = false
local dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    button.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

button.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        update(input)
    end
end)
