repeat wait() until game:IsLoaded()

local UIS = game:GetService("UserInputService")
local Touchscreen = UIS.TouchEnabled

getgenv().Device = Touchscreen and "Mobile" or "PC"
if getgenv().Device == "Mobile" then
    game.Players.LocalPlayer:Kick("Mobile Don't Support")
else
    warn("PC SUPPORT")
    loadstring("https://raw.githubusercontent.com/LenivayZopaKota/Pluty-v0.0.1/refs/heads/main/Pluty%20Hub.lua")
end
