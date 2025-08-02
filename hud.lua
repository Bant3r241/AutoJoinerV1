local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "AutoJoinerGUI"
screenGui.ResetOnSpawn = false

-- Create frame
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0.5, -150, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0

-- Create title
local titleLabel = Instance.new("TextLabel", frame)
titleLabel.Size = UDim2.new(1, -40, 0, 40)
titleLabel.Position = UDim2.new(0, 20, 0, 15)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "AutoJoiner"
titleLabel.TextColor3 = Color3.fromRGB(90, 0, 90)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Create MPS Dropdown
local mpsDropdown = Instance.new("TextButton", frame)
mpsDropdown.Size = UDim2.new(1, -40, 0, 40)
mpsDropdown.Position = UDim2.new(0, 20, 0, 85)
mpsDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
mpsDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
mpsDropdown.Font = Enum.Font.GothamBold
mpsDropdown.TextSize = 18
mpsDropdown.Text = "1M-3M  ▼"
mpsDropdown.AutoButtonColor = false

local optionsFrame = Instance.new("Frame", frame)
optionsFrame.Size = UDim2.new(1, -40, 0, 0)
optionsFrame.Position = UDim2.new(0, 20, 0, 125)
optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
optionsFrame.ClipsDescendants = true

local mpsRanges = {"1M-3M", "3M+"}
local isOpen = false
mpsDropdown.MouseButton1Click:Connect(function()
    if isOpen then
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    else
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, #mpsRanges * 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    end
    isOpen = not isOpen
end)

-- Create MPS options
for i, range in ipairs(mpsRanges) do
    local btn = Instance.new("TextButton", optionsFrame)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, (i-1) * 40)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Text = range
    btn.AutoButtonColor = false

    btn.MouseButton1Click:Connect(function()
        mpsDropdown.Text = range .. "  ▼"
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        isOpen = false
    end)
end

-- Create Start and Stop buttons
local function createButton(text, yPosition)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, yPosition)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.AutoButtonColor = false
    return btn
end

local startBtn = createButton("Start", 190)
local stopBtn = createButton("Stop", 240)

startBtn.MouseButton1Click:Connect(function()
    print("Start clicked")
    -- Add your Start functionality here
end)

stopBtn.MouseButton1Click:Connect(function()
    print("Stop clicked")
    -- Add your Stop functionality here
end)

-- Minimize button
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
minimizeBtn.Position = UDim2.new(1, -40, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.Text = "-"
minimizeBtn.AutoButtonColor = false

local minimizedImage = Instance.new("ImageButton", frame)
minimizedImage.Size = UDim2.new(0, 40, 0, 40)
minimizedImage.Position = UDim2.new(1, -40, 0, 0)
minimizedImage.BackgroundTransparency = 1
minimizedImage.Image = "rbxassetid://2398054"  -- Your image asset
minimizedImage.Visible = false

minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    minimizedImage.Visible = true
end)

minimizedImage.MouseButton1Click:Connect(function()
    frame.Visible = true
    minimizedImage.Visible = false
end)
