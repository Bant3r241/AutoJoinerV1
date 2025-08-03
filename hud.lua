-- AutoJoiner with Exact Format Parsing
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local WEBSOCKET_URL = "wss://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev/"
local HOP_INTERVAL = 2 -- seconds between hops
local RECONNECT_DELAY = 5
local MAX_RETRIES = 3

-- State
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local socket = nil
local isRunning = false
local isPaused = false
local lastHopTime = 0
local activeJobId = nil
local selectedMpsRange = "1M-3M"
local connectionAttempts = 0

-- Wait for player GUI
repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- Main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoJoinerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 550)
frame.Position = UDim2.new(0.5, -150, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Draggable Logic
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

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 0, 40)
titleLabel.Position = UDim2.new(0, 20, 0, 15)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "AutoJoiner"
titleLabel.TextColor3 = Color3.fromRGB(90, 0, 90)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = frame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 20)
statusLabel.Position = UDim2.new(0, 20, 0, 60)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Disconnected"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Server Info Label
local serverInfoLabel = Instance.new("TextLabel")
serverInfoLabel.Size = UDim2.new(1, -40, 0, 20)
serverInfoLabel.Position = UDim2.new(0, 20, 0, 85)
serverInfoLabel.BackgroundTransparency = 1
serverInfoLabel.Text = "Server: None"
serverInfoLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
serverInfoLabel.Font = Enum.Font.Gotham
serverInfoLabel.TextSize = 14
serverInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
serverInfoLabel.Parent = frame

-- MPS Dropdown System
local mpsLabel = Instance.new("TextLabel")
mpsLabel.Size = UDim2.new(1, -40, 0, 20)
mpsLabel.Position = UDim2.new(0, 20, 0, 110)
mpsLabel.BackgroundTransparency = 1
mpsLabel.Text = "Select MPS Range:"
mpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
mpsLabel.Font = Enum.Font.GothamBold
mpsLabel.TextSize = 18
mpsLabel.TextXAlignment = Enum.TextXAlignment.Left
mpsLabel.Parent = frame

local mpsDropdown = Instance.new("TextButton")
mpsDropdown.Size = UDim2.new(1, -40, 0, 40)
mpsDropdown.Position = UDim2.new(0, 20, 0, 135)
mpsDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
mpsDropdown.BorderSizePixel = 0
mpsDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
mpsDropdown.Font = Enum.Font.GothamBold
mpsDropdown.TextSize = 18
mpsDropdown.Text = "1M-3M  ▼"
mpsDropdown.AutoButtonColor = false
mpsDropdown.Parent = frame

local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.new(1, -40, 0, 0)
optionsFrame.Position = UDim2.new(0, 20, 0, 175)
optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
optionsFrame.BorderSizePixel = 0
optionsFrame.ClipsDescendants = true
optionsFrame.ZIndex = 2
optionsFrame.Parent = frame

local mpsRanges = {"1M-3M", "3M-5M", "5M+"}
local isDropdownOpen = false

local function toggleDropdown()
    if isDropdownOpen then
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)
        mpsDropdown.Text = selectedMpsRange.."  ▼"
    else
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, #mpsRanges * 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)
        mpsDropdown.Text = selectedMpsRange.."  ▲"
    end
    isDropdownOpen = not isDropdownOpen
end

mpsDropdown.MouseButton1Click:Connect(toggleDropdown)

-- Create dropdown options
for i, range in ipairs(mpsRanges) do
    local option = Instance.new("TextButton")
    option.Size = UDim2.new(1, 0, 0, 40)
    option.Position = UDim2.new(0, 0, 0, (i-1)*40)
    option.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    option.BorderSizePixel = 0
    option.Text = range
    option.TextColor3 = Color3.fromRGB(255, 255, 255)
    option.Font = Enum.Font.GothamBold
    option.TextSize = 18
    option.AutoButtonColor = false
    option.ZIndex = 3
    option.Parent = optionsFrame
    
    option.MouseButton1Click:Connect(function()
        selectedMpsRange = range
        toggleDropdown()
        statusLabel.Text = "Status: Filter set to "..range
        statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    end)
end

-- Start Button
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -40, 0, 40)
startBtn.Position = UDim2.new(0, 20, 0, 320)
startBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
startBtn.BorderSizePixel = 0
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 20
startBtn.Text = "Start"
startBtn.AutoButtonColor = false
startBtn.Parent = frame

-- Stop Button
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -40, 0, 40)
stopBtn.Position = UDim2.new(0, 20, 0, 370)
stopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
stopBtn.BorderSizePixel = 0
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 20
stopBtn.Text = "Stop"
stopBtn.AutoButtonColor = false
stopBtn.Parent = frame

-- Resume Button
local resumeBtn = Instance.new("TextButton")
resumeBtn.Size = UDim2.new(1, -40, 0, 40)
resumeBtn.Position = UDim2.new(0, 20, 0, 420)
resumeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
resumeBtn.BorderSizePixel = 0
resumeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resumeBtn.Font = Enum.Font.GothamBold
resumeBtn.TextSize = 20
resumeBtn.Text = "Resume"
resumeBtn.AutoButtonColor = false
resumeBtn.Parent = frame

-- Minimize Button
local minimizeBtn = Instance.new("ImageButton")
minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
minimizeBtn.Position = UDim2.new(1, -40, 0, 0)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Image = "rbxassetid://2398054"
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = frame

local minimizedImage = Instance.new("ImageButton")
minimizedImage.Size = UDim2.new(0, 40, 0, 40)
minimizedImage.Position = UDim2.new(0, 20, 0, 20)
minimizedImage.BackgroundTransparency = 1
minimizedImage.Image = "rbxassetid://2398054"
minimizedImage.Visible = false
minimizedImage.Parent = screenGui

minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    minimizedImage.Visible = true
end)

minimizedImage.MouseButton1Click:Connect(function()
    frame.Visible = true
    minimizedImage.Visible = false
end)

-- WebSocket Functions
local function attemptTeleport(jobId)
    if not isRunning or isPaused then return false end
    
    local currentTime = os.time()
    if currentTime - lastHopTime < HOP_INTERVAL then
        task.wait(HOP_INTERVAL - (currentTime - lastHopTime))
    end
    
    lastHopTime = os.time()
    activeJobId = jobId
    serverInfoLabel.Text = "Server: "..(jobId and string.sub(jobId, 1, 8).."..." or "None")
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
    
    if not success then
        warn("Teleport failed:", err)
        statusLabel.Text = "Status: Failed - Retrying"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return false
    end
    
    return true
end

local function handleWebSocketMessage(message)
    if isPaused then return end
    
    print("[WebSocket] Raw message:", message)
    
    -- EXACT FORMAT PARSING FOR:
    -- job id "ID123" Server name "Test Server" MoneyPerSec "1.5M"
    local jobId, serverName, mpsValue = message:match('job id%s+"([^"]+)"%s+Server name%s+"([^"]+)"%s+MoneyPerSec%s+"([%d%.]+)M"')
    
    -- Alternative parsing if exact match fails
    if not jobId then
        jobId, mpsValue = message:match('job id%s+"([^"]+)"%s+.*MoneyPerSec%s+"([%d%.]+)M"')
    end
    
    -- More flexible parsing
    if not jobId then
        jobId = message:match('job id%s+"([^"]+)"')
        mpsValue = message:match('MoneyPerSec%s+"([%d%.]+)M"')
    end
    
    -- Final fallback
    if not jobId or not mpsValue then
        statusLabel.Text = "Status: Checking format..."
        jobId = jobId or message:match('job id%s+([%w-]+)')
        mpsValue = mpsValue or message:match('MoneyPerSec%s+([%d%.]+)M')
    end
    
    -- Validate results
    if not jobId or not mpsValue then
        statusLabel.Text = "Status: Invalid format"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        print("[ERROR] Expected format:")
        print('job id "ABC123" Server name "Test Server" MoneyPerSec "1.5M"')
        print("Received:", message)
        return
    end
    
    -- Convert MPS to number
    local mps = tonumber(mpsValue)
    if not mps then
        statusLabel.Text = "Status: Invalid MPS value"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    -- Apply MPS filter
    local shouldJoin = false
    local mpsMillions = mps -- Already in millions
    
    if selectedMpsRange == "1M-3M" then
        shouldJoin = (mpsMillions >= 1 and mpsMillions <= 3)
    elseif selectedMpsRange == "3M-5M" then
        shouldJoin = (mpsMillions > 3 and mpsMillions <= 5)
    elseif selectedMpsRange == "5M+" then
        shouldJoin = (mpsMillions > 5)
    end
    
    -- Take action
    if shouldJoin then
        statusLabel.Text = string.format("Joining %s (%.1fM/s)", string.sub(jobId, 1, 8), mpsMillions)
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        attemptTeleport(jobId)
    else
        statusLabel.Text = string.format("Skipping %s (%.1fM/s)", string.sub(jobId, 1, 8), mpsMillions)
        statusLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
    end
    
    print(string.format("Parsed - JobID: %s | Server: %s | MPS: %.1fM | Action: %s",
        jobId, serverName or "N/A", mpsMillions, shouldJoin and "Joining" or "Skipping"))
end

local function connectWebSocket()
    if not isRunning then return end
    
    connectionAttempts = connectionAttempts + 1
    statusLabel.Text = string.format("Connecting (%d/%d)...", connectionAttempts, MAX_RETRIES)
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    
    -- Close existing connection
    if socket then
        pcall(function() socket:Close() end)
        socket = nil
    end
    
    local success, err = pcall(function()
        socket = WebSocket.connect(WEBSOCKET_URL)
        
        socket.OnMessage:Connect(handleWebSocketMessage)
        
        socket.OnClose:Connect(function()
            if isRunning and not isPaused and connectionAttempts < MAX_RETRIES then
                task.wait(RECONNECT_DELAY)
                connectWebSocket()
            end
        end)
        
        connectionAttempts = 0
        statusLabel.Text = "Status: Connected"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)
    
    if not success then
        print("[ERROR] Connection failed:", err)
        if connectionAttempts < MAX_RETRIES then
            task.wait(RECONNECT_DELAY)
            connectWebSocket()
        else
            statusLabel.Text = "Status: Connection failed"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            isRunning = false
        end
    end
end

-- Control Handlers
startBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    isRunning = true
    isPaused = false
    connectionAttempts = 0
    connectWebSocket()
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isRunning then return end
    isRunning = false
    isPaused = false
    if socket then
        pcall(function() socket:Close() end)
        socket = nil
    end
    statusLabel.Text = "Status: Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

resumeBtn.MouseButton1Click:Connect(function()
    if not isRunning or not isPaused then return end
    isPaused = false
    statusLabel.Text = "Status: Resumed"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
end)

-- Debugging
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F5 then
        print("\n=== DEBUG INFO ===")
        print("WebSocket URL:", WEBSOCKET_URL)
        print("Connected:", socket and "Yes" or "No")
        print("Running:", isRunning and "Yes" or "No")
        print("Paused:", isPaused and "Yes" or "No")
        print("Last Job ID:", activeJobId or "None")
        print("Selected MPS:", selectedMpsRange)
        print("Connection Attempts:", connectionAttempts)
        print("=========================")
    end
end)

-- Cleanup
player.AncestryChanged:Connect(function(_, parent)
    if not parent and socket then
        pcall(function() socket:Close() end)
    end
end)
