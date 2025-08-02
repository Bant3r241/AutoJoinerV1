local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]

repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyRangeGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create draggable frame with black background
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 350)  -- Adjusted size to fit all elements
frame.Position = UDim2.new(0.5, -140, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Black background
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Function to create animated red border around the frame
local function createAnimatedBorder()
    -- Top border
    local topBorder = Instance.new("Frame")
    topBorder.Size = UDim2.new(1, 0, 0, 2)
    topBorder.Position = UDim2.new(0, 0, 0, 0)
    topBorder.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- Red color
    topBorder.BorderSizePixel = 0
    topBorder.Parent = frame

    -- Bottom border
    local bottomBorder = Instance.new("Frame")
    bottomBorder.Size = UDim2.new(1, 0, 0, 2)
    bottomBorder.Position = UDim2.new(0, 0, 1, -2)
    bottomBorder.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    bottomBorder.BorderSizePixel = 0
    bottomBorder.Parent = frame

    -- Left border
    local leftBorder = Instance.new("Frame")
    leftBorder.Size = UDim2.new(0, 2, 1, 0)
    leftBorder.Position = UDim2.new(0, 0, 0, 0)
    leftBorder.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    leftBorder.BorderSizePixel = 0
    leftBorder.Parent = frame

    -- Right border
    local rightBorder = Instance.new("Frame")
    rightBorder.Size = UDim2.new(0, 2, 1, 0)
    rightBorder.Position = UDim2.new(1, -2, 0, 0)
    rightBorder.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    rightBorder.BorderSizePixel = 0
    rightBorder.Parent = frame

    -- Animation for red border (using TweenService)
    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true)

    -- Top border animation
    local topTween = TweenService:Create(topBorder, tweenInfo, {Size = UDim2.new(1, 0, 0, 2)})
    -- Bottom border animation
    local bottomTween = TweenService:Create(bottomBorder, tweenInfo, {Size = UDim2.new(1, 0, 0, 2)})
    -- Left border animation
    local leftTween = TweenService:Create(leftBorder, tweenInfo, {Size = UDim2.new(0, 2, 1, 0)})
    -- Right border animation
    local rightTween = TweenService:Create(rightBorder, tweenInfo, {Size = UDim2.new(0, 2, 1, 0)})

    -- Start animations
    topTween:Play()
    bottomTween:Play()
    leftTween:Play()
    rightTween:Play()
end

-- Call function to create animated red border
createAnimatedBorder()

-- Draggable logic
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Label with white text
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -40, 0, 20)
label.Position = UDim2.new(0, 20, 0, 15)
label.BackgroundTransparency = 1
label.Text = "Select Money Range:"
label.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = frame

-- Dropdown main button with red border
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1, -40, 0, 40)
dropdown.Position = UDim2.new(0, 20, 0, 40)
dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  -- Dark gray background
dropdown.BorderSizePixel = 2  -- Thin red border
dropdown.BorderColor3 = Color3.fromRGB(255, 0, 0)  -- Red border
dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
dropdown.Font = Enum.Font.GothamBold
dropdown.TextSize = 18
dropdown.Text = "1M+  ▼"
dropdown.AutoButtonColor = false
dropdown.Parent = frame

-- Dropdown container
local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.new(1, -40, 0, 0)
optionsFrame.Position = UDim2.new(0, 20, 0, 80)
optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)  -- Dark gray background
optionsFrame.BorderSizePixel = 2
optionsFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)  -- Red border
optionsFrame.ClipsDescendants = true
optionsFrame.Parent = frame

local moneyRanges = {"1M+", "10M+", "100M+", "1B+", "10B+"}
local isOpen = false

local function toggleDropdown()
    if isOpen then
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    else
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, #moneyRanges * 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    end
    isOpen = not isOpen
end

dropdown.MouseButton1Click:Connect(toggleDropdown)

for i, range in ipairs(moneyRanges) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, (i-1)*40)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)  -- Dark gray background for options
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Text = range
    btn.AutoButtonColor = false
    btn.Parent = optionsFrame

    btn.MouseButton1Click:Connect(function()
        dropdown.Text = range .. "  ▼"
        toggleDropdown()
        print("Selected money range:", range)
    end)
end

-- Create static Start and Stop buttons
local function createButton(text, positionY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 50)
    btn.Position = UDim2.new(0, 20, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  -- Dark gray background
    btn.BorderSizePixel = 2  -- Red border around the button
    btn.BorderColor3 = Color3.fromRGB(255, 0, 0)  -- Red border
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = frame

    return btn
end

local startBtn = createButton("Start", 150)
local stopBtn = createButton("Stop", 210)

startBtn.MouseButton1Click:Connect(function()
    print("Start clicked")
    -- Add any start functionality here
end)

stopBtn.MouseButton1Click:Connect(function()
    print("Stop clicked")
    -- Add any stop functionality here
end)
