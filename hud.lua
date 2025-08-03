-- AutoJoiner with Original GUI + Live WebSocket Hopping
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local WEBSOCKET_URL = "wss://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev/"
local HOP_INTERVAL = 2 -- seconds between hops
local RECONNECT_DELAY = 5

-- State
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local socket = nil
local isRunning = false
local lastHopTime = 0
local activeJobId = nil

-- Wait for player GUI
repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- Restore Original GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoJoinerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0.5, -150, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Draggable Logic (Original)
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

-- Original Title Label
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

-- Status Label (Modified)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 20)
statusLabel.Position = UDim2.new(0, 20, 0, 50)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Disconnected"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Server Info Label (New)
local serverInfoLabel = Instance.new("TextLabel")
serverInfoLabel.Size = UDim2.new(1, -40, 0, 20)
serverInfoLabel.Position = UDim2.new(0, 20, 0, 75)
serverInfoLabel.BackgroundTransparency = 1
serverInfoLabel.Text = "Server: None"
serverInfoLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
serverInfoLabel.Font = Enum.Font.Gotham
serverInfoLabel.TextSize = 14
serverInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
serverInfoLabel.Parent = frame

-- Original MPS Dropdown (Non-functional but preserved)
local mpsLabel = Instance.new("TextLabel")
mpsLabel.Size = UDim2.new(1, -40, 0, 20)
mpsLabel.Position = UDim2.new(0, 20, 0, 105)
mpsLabel.BackgroundTransparency = 1
mpsLabel.Text = "Select MPS Range:"
mpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
mpsLabel.Font = Enum.Font.GothamBold
mpsLabel.TextSize = 18
mpsLabel.TextXAlignment = Enum.TextXAlignment.Left
mpsLabel.Parent = frame

local mpsDropdown = Instance.new("TextButton")
mpsDropdown.Size = UDim2.new(1, -40, 0, 40)
mpsDropdown.Position = UDim2.new(0, 20, 0, 130)
mpsDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
mpsDropdown.BorderSizePixel = 0
mpsDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
mpsDropdown.Font = Enum.Font.GothamBold
mpsDropdown.TextSize = 18
mpsDropdown.Text = "1M-3M  ▼"
mpsDropdown.AutoButtonColor = false
mpsDropdown.Parent = frame

-- Original Start/Stop Buttons
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -40, 0, 40)
startBtn.Position = UDim2.new(0, 20, 0, 190)
startBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
startBtn.BorderSizePixel = 0
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 20
startBtn.Text = "Start"
startBtn.AutoButtonColor = false
startBtn.Parent = frame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -40, 0, 40)
stopBtn.Position = UDim2.new(0, 20, 0, 240)
stopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
stopBtn.BorderSizePixel = 0
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 20
stopBtn.Text = "Stop"
stopBtn.AutoButtonColor = false
stopBtn.Parent = frame

-- Original Minimize Button
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

-- Core Functions (Improved)
local function attemptTeleport(jobId)
    if not isRunning then return false end
    
    -- Rate limiting
    local currentTime = os.time()
    if currentTime - lastHopTime < HOP_INTERVAL then
        local waitTime = HOP_INTERVAL - (currentTime - lastHopTime)
        task.wait(waitTime)
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
    local success, data = pcall(function()
        return HttpService:JSONDecode(message)
    end)
    
    if not success then
        warn("Invalid message:", message)
        return
    end
    
    -- Supports both formats
    local jobId = data.jobId or (data.jobIds and data.jobIds[1])
    
    if jobId and type(jobId) == "string" then
        statusLabel.Text = "Status: Joining..."
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        attemptTeleport(jobId)
    else
        warn("Invalid job ID format")
    end
end

local function connectWebSocket()
    statusLabel.Text = "Status: Connecting..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    
    local newSocket = WebSocket.connect(WEBSOCKET_URL)
    
    newSocket.OnMessage:Connect(handleWebSocketMessage)
    
    newSocket.OnClose:Connect(function()
        if isRunning then
            statusLabel.Text = "Status: Reconnecting..."
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        else
            statusLabel.Text = "Status: Disconnected"
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    
    newSocket.OnError:Connect(function(err)
        warn("WebSocket error:", err)
        if isRunning then
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        end
    end)
    
    statusLabel.Text = "Status: Connected"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    return newSocket
end

-- Control Handlers
startBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    
    isRunning = true
    startBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    if not socket then
        socket = connectWebSocket()
    else
        statusLabel.Text = "Status: Waiting for servers..."
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isRunning then return end
    
    isRunning = false
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.Text = "Status: Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    serverInfoLabel.Text = "Server: None"
end)

-- Cleanup
player.AncestryChanged:Connect(function(_, parent)
    if not parent and socket then
        pcall(function() socket:Close() end)
    end
end)

-- Debug command (F3 to print state)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F3 then
        print("\n=== AUTOJOINER STATE ===")
        print("Running:", isRunning)
        print("Socket:", socket and "Connected" or "Disconnected")
        print("Last server:", activeJobId)
        print("Last hop:", os.time() - lastHopTime, "seconds ago")
        print("=========================")
    end
end)
