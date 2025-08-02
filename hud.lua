local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]

repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyRangeGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create draggable frame with vibrant colors and smooth animations
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 350)  -- Larger size to fit all elements
frame.Position = UDim2.new(0.5, -140, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(34, 42, 53)  -- Dark background with color
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Add a gradient background for a colorful effect
local gradient = Instance.new("UIGradient")
gradient.Parent = frame
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 153, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 102, 102))
})
gradient.Rotation = 45

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

-- Label with colorful text
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -40, 0, 20)
label.Position = UDim2.new(0, 20, 0, 15)
label.BackgroundTransparency = 1
label.Text = "Select Money Range:"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = frame

-- Dropdown main button with color effects
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1, -40, 0, 40)
dropdown.Position = UDim2.new(0, 20, 0, 40)
dropdown.BackgroundColor3 = Color3.fromRGB(55, 135, 255)  -- Colorful background
dropdown.BorderSizePixel = 0
dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdown.Font = Enum.Font.GothamBold
dropdown.TextSize = 18
dropdown.Text = "1M+  ▼"
dropdown.AutoButtonColor = false
dropdown.Parent = frame

-- Dropdown container
local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.new(1, -40, 0, 0)
optionsFrame.Position = UDim2.new(0, 20, 0, 80)
optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 125, 250)
optionsFrame.BorderSizePixel = 0
optionsFrame.ClipsDescendants = true
optionsFrame.Parent = frame

local moneyRanges = {"1M+", "10M+", "100M+", "1B+", "10B+", "50B+"}
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
    btn.BackgroundColor3 = Color3.fromRGB(85, 165, 255)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Text = range
    btn.AutoButtonColor = false
    btn.Parent = optionsFrame

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(115, 195, 255)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(85, 165, 255)
    end)

    btn.MouseButton1Click:Connect(function()
        dropdown.Text = range .. "  ▼"
        toggleDropdown()
        print("Selected money range:", range)
    end)
end

-- Create animated buttons for Start and Stop
local function createAnimatedButton(text, positionY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 50)
    btn.Position = UDim2.new(0, 20, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = frame

    -- Add animation effect on hover
    btn.MouseEnter:Connect(function()
        btn:TweenSize(UDim2.new(1, -40, 0, 60), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        btn.BackgroundColor3 = Color3.fromRGB(85, 185, 255)
    end)

    btn.MouseLeave:Connect(function()
        btn:TweenSize(UDim2.new(1, -40, 0, 50), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        btn.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
    end)

    return btn
end

local startBtn = createAnimatedButton("Start", 150)
local stopBtn = createAnimatedButton("Stop", 210)

startBtn.MouseButton1Click:Connect(function()
    print("Start clicked")
    -- Add any start functionality here
end)

stopBtn.MouseButton1Click:Connect(function()
    print("Stop clicked")
    -- Add any stop functionality here
end)
