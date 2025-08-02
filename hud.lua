-- Simple GUI with Start, Pause, OK buttons for Roblox
-- Waits safely for Player and PlayerGui to load

local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]

-- Wait until player and PlayerGui exist
repeat task.wait() until player and player:FindFirstChild("PlayerGui")

local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Function to create a button
local function createButton(name, position, text)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 120, 0, 50)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 22
    button.Font = Enum.Font.SourceSansBold
    button.Text = text
    button.Parent = screenGui
    return button
end

-- Create buttons
local startBtn = createButton("StartButton", UDim2.new(0.5, -60, 0.4, 0), "Start")
local pauseBtn = createButton("PauseButton", UDim2.new(0.5, -60, 0.5, 0), "Pause")
local okBtn = createButton("OkButton", UDim2.new(0.5, -60, 0.6, 0), "OK")

-- Connect button events
startBtn.MouseButton1Click:Connect(function()
    print("Start clicked")
end)

pauseBtn.MouseButton1Click:Connect(function()
    print("Pause clicked")
end)

okBtn.MouseButton1Click:Connect(function()
    print("OK clicked")
end)
