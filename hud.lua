local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]

repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyRangeGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create draggable frame with darker purple background
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)  -- Size to fit elements
frame.Position = UDim2.new(0.5, -150, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(52, 11, 98)  -- Darker purple background
frame.BorderSizePixel = 0
frame.Parent = screenGui

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
label.Text = "Select Money Filter:"
label.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = frame

-- Dropdown main button
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1, -40, 0, 40)
dropdown.Position = UDim2.new(0, 20, 0, 40)
dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  -- Dark gray background
dropdown.BorderSizePixel = 0  -- No border
dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
dropdown.Font = Enum.Font.GothamBold
dropdown.TextSize = 18
dropdown.Text = "1M-3M  ▼"
dropdown.AutoButtonColor = false
dropdown.Parent = frame

-- Dropdown container
local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.new(1, -40, 0, 0)
optionsFrame.Position = UDim2.new(0, 20, 0, 80)
optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)  -- Dark gray background
optionsFrame.BorderSizePixel = 0  -- No border
optionsFrame.ClipsDescendants = true
optionsFrame.Parent = frame

local moneyRanges = {"1M-3M", "3M-10M"}
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
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0  -- No border
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = frame

    return btn
end

local startBtn = createButton("Start", 250)
local stopBtn = createButton("Stop", 300)

startBtn.MouseButton1Click:Connect(function()
    print("Start clicked")
    -- Add any start functionality here
end)

stopBtn.MouseButton1Click:Connect(function()
    print("Stop clicked")
    -- Add any stop functionality here
end)

-- Add "Made By BrainGPT" text
local madeByLabel = Instance.new("TextLabel")
madeByLabel.Size = UDim2.new(1, -40, 0, 20)
madeByLabel.Position = UDim2.new(0, 20, 1, -30)
madeByLabel.BackgroundTransparency = 1
madeByLabel.Text = "Made By BrainGPT"
madeByLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
madeByLabel.Font = Enum.Font.GothamBold
madeByLabel.TextSize = 14
madeByLabel.TextXAlignment = Enum.TextXAlignment.Left
madeByLabel.Parent = frame
