-- Real-Time Server Hopper
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local WEBSOCKET_URL = "wss://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev/"
local HOP_INTERVAL = 2 -- Minimum seconds between hops
local RECONNECT_DELAY = 5

-- State
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local socket = nil
local isRunning = false
local lastHopTime = 0
local activeJobId = nil

-- Wait for player GUI
repeat task.wait(1) until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LiveAutoJoiner"
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 150)
frame.Position = UDim2.new(0.5, -125, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.Text = "STATUS: Ready"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = frame

local currentServerLabel = Instance.new("TextLabel")
currentServerLabel.Size = UDim2.new(1, -20, 0, 20)
currentServerLabel.Position = UDim2.new(0, 10, 0, 45)
currentServerLabel.Text = "Server: None"
currentServerLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
currentServerLabel.Font = Enum.Font.Gotham
currentServerLabel.Parent = frame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 40)
startBtn.Position = UDim2.new(0, 10, 0, 75)
startBtn.Text = "START"
startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
startBtn.Parent = frame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -20, 0, 40)
stopBtn.Position = UDim2.new(0, 10, 0, 120)
stopBtn.Text = "STOP"
stopBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 80)
stopBtn.Parent = frame

-- Core Functions
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
    currentServerLabel.Text = "Server: "..(jobId and string.sub(jobId, 1, 8).."..." or "None")
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
    
    if not success then
        warn("Teleport failed:", err)
        statusLabel.Text = "STATUS: Failed - Retrying"
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
    
    -- Supports both single ID and array formats
    local jobId = data.jobId or (data.jobIds and data.jobIds[1])
    
    if jobId and type(jobId) == "string" then
        statusLabel.Text = "STATUS: Received server"
        attemptTeleport(jobId)
    else
        warn("Invalid job ID format")
    end
end

local function connectWebSocket()
    statusLabel.Text = "STATUS: Connecting..."
    
    local newSocket = WebSocket.connect(WEBSOCKET_URL)
    
    newSocket.OnMessage:Connect(handleWebSocketMessage)
    
    newSocket.OnClose:Connect(function()
        if isRunning then
            statusLabel.Text = "STATUS: Reconnecting..."
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        end
    end)
    
    newSocket.OnError:Connect(function(err)
        warn("WebSocket error:", err)
        if isRunning then
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        end
    end)
    
    statusLabel.Text = "STATUS: Connected"
    return newSocket
end

-- Controls
startBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    
    isRunning = true
    startBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
    stopBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 60)
    
    if not socket then
        socket = connectWebSocket()
    else
        statusLabel.Text = "STATUS: Waiting for servers..."
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isRunning then return end
    
    isRunning = false
    startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
    stopBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 80)
    statusLabel.Text = "STATUS: Stopped"
    currentServerLabel.Text = "Server: None"
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
        print("\n=== LIVE HOPPER STATE ===")
        print("Running:", isRunning)
        print("Socket:", socket and "Connected" or "Disconnected")
        print("Last server:", activeJobId)
        print("Last hop:", os.time() - lastHopTime, "seconds ago")
        print("=========================")
    end
end)
