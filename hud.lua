local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]

repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyRangeGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create draggable frame (increased size)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 300)  -- Increased width and height to accommodate all options
frame.Position = UDim2.new(0.5, -125, 0.3, 0)  -- Adjusted for new size
frame.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
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

-- Label
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -40, 0, 20)
label.Position = UDim2.new(0, 20, 0, 15)
label.BackgroundTransparency = 1
label.Text = "Select Money Range:"
label.TextColor3 = Color3.fromRGB(220, 220, 220)
label.Font = Enum.Font.GothamSemibold
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = frame

-- Dropdown main button
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1, -40, 0, 30)
dropdown.Position = UDim2.new(0, 20, 0, 40)
dropdown.BackgroundColor3 = Color3.fromRGB(57, 60, 64)
dropdown.BorderSizePixel = 0
dropdown.TextColor3 = Color3.fromRGB(220, 220, 220)
dropdown.Font = Enum.Font.GothamSemibold
dropdown.TextSize = 16
dropdown.Text = "1M+  ▼"
dropdown.AutoButtonColor = false
dropdown.Parent = frame

-- Dropdown container (increased size to fit more options)
local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.new(1, -40, 0, 0)
optionsFrame.Position = UDim2.new(0, 20, 0, 70)
optionsFrame.BackgroundColor3 = Color3.fromRGB(57, 60, 64)
optionsFrame.BorderSizePixel = 0
optionsFrame.ClipsDescendants = true
optionsFrame.Parent = frame

local moneyRanges = {"1M+", "10M+", "100M+", "1B+", "10B+", "50B+"}  -- Added more range options
local isOpen = false

local function toggleDropdown()
    if isOpen then
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    else
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, #moneyRanges * 30), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    end
    isOpen = not isOpen
end

dropdown.MouseButton1Click:Connect(toggleDropdown)

for i, range in ipairs(moneyRanges) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, (i-1)*30)
    btn.BackgroundColor3 = Color3.fromRGB(45, 48, 52)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.Text = range
    btn.AutoButtonColor = false
    btn.Parent = optionsFrame

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(65, 68, 72)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(45, 48, 52)
    end)

    btn.MouseButton1Click:Connect(function()
        dropdown.Text = range .. "  ▼"
        toggleDropdown()
        print("Selected money range:", range)
    end)
end

-- Button creator with style
local function createButton(text, positionY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 35)
    btn.Position = UDim2.new(0, 20, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(57, 60, 64)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 18
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = frame

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(77, 80, 84)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(57, 60, 64)
    end)

    return btn
end

local startBtn = createButton("Start", 175)  -- Adjusted button positions to fit the new size
local pauseBtn = createButton("Pause", 215)
local resumeBtn = createButton("Resume", 255)

startBtn.MouseButton1Click:Connect(function()
    print("Start clicked")
end)
pauseBtn.MouseButton1Click:Connect(function()
    print("Pause clicked")
end)
resumeBtn.MouseButton1Click:Connect(function()
    print("Resume clicked")
end)
