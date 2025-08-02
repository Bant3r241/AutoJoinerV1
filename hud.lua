local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]

repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyRangeGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 260)
frame.Position = UDim2.new(0.5, -110, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 0, 30)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundTransparency = 1
label.Text = "Select Money Range:"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.SourceSansSemibold
label.TextSize = 18
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = frame

-- Dropdown main button
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1, -20, 0, 35)
dropdown.Position = UDim2.new(0, 10, 0, 45)
dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdown.Font = Enum.Font.SourceSansSemibold
dropdown.TextSize = 18
dropdown.Text = "1M+ ▼"
dropdown.Parent = frame

-- Dropdown options container
local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.new(1, -20, 0, 0) -- start closed (height 0)
optionsFrame.Position = UDim2.new(0, 10, 0, 80)
optionsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
optionsFrame.BorderSizePixel = 0
optionsFrame.ClipsDescendants = true
optionsFrame.Parent = frame

local moneyRanges = {"1M+", "10M+", "100M+", "1B+", "10B+"}
local optionButtons = {}
local isOpen = false

local function toggleDropdown()
    if isOpen then
        optionsFrame:TweenSize(UDim2.new(1, -20, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    else
        optionsFrame:TweenSize(UDim2.new(1, -20, 0, #moneyRanges * 35), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    end
    isOpen = not isOpen
end

dropdown.MouseButton1Click:Connect(toggleDropdown)

for i, range in ipairs(moneyRanges) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, (i-1)*35)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 18
    btn.Text = range
    btn.Parent = optionsFrame

    btn.MouseButton1Click:Connect(function()
        dropdown.Text = range .. " ▼"
        toggleDropdown()
        print("Selected money range:", range)
    end)
    table.insert(optionButtons, btn)
end

-- Buttons below dropdown
local function createButton(text, positionY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 20
    btn.Text = text
    btn.Parent = frame
    return btn
end

local startBtn = createButton("Start", 170)
local pauseBtn = createButton("Pause", 220)
local resumeBtn = createButton("Resume", 270)

startBtn.MouseButton1Click:Connect(function()
    print("Start clicked")
end)
pauseBtn.MouseButton1Click:Connect(function()
    print("Pause clicked")
end)
resumeBtn.MouseButton1Click:Connect(function()
    print("Resume clicked")
end)
