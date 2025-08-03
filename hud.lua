-- AutoJoiner Complete Script
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Player initialization
local player = Players.LocalPlayer or Players:GetPlayers()[1]
repeat task.wait(1) until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local WEBSOCKET_URL = "wss://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev/"
local RECONNECT_DELAY = 5
local TELEPORT_DELAY = 2
local MAX_ATTEMPTS = 10

-- State management
local socket = nil
local isRunning = false
local jobIds = {}
local currentJobIdIndex = 0
local attemptCount = 0
local lastHopTime = 0

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoJoinerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Status display
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Server count display
local serverCountLabel = Instance.new("TextLabel")
serverCountLabel.Size = UDim2.new(1, -20, 0, 20)
serverCountLabel.Position = UDim2.new(0, 10, 0, 40)
serverCountLabel.BackgroundTransparency = 1
serverCountLabel.Text = "Servers: 0"
serverCountLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
serverCountLabel.Font = Enum.Font.Gotham
serverCountLabel.TextSize = 12
serverCountLabel.TextXAlignment = Enum.TextXAlignment.Left
serverCountLabel.Parent = frame

-- Control buttons
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 40)
startBtn.Position = UDim2.new(0, 10, 0, 70)
startBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
startBtn.Text = "START"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 18
startBtn.Parent = frame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -20, 0, 40)
stopBtn.Position = UDim2.new(0, 10, 0, 120)
stopBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
stopBtn.Text = "STOP"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 18
stopBtn.Parent = frame

-- WebSocket Management
local function connectWebSocket()
    if not WebSocket then
        statusLabel.Text = "Error: WebSocket not supported"
        return nil
    end

    statusLabel.Text = "Connecting..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    local success, newSocket = pcall(function()
        return WebSocket.connect(WEBSOCKET_URL)
    end)
    
    if not success then
        statusLabel.Text = "Connection failed"
        statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        warn("WebSocket connection failed:", newSocket)
        return nil
    end
    
    -- Message handler
    newSocket.OnMessage:Connect(function(message)
        local success, data = pcall(function()
            return HttpService:JSONDecode(message)
        end)
        
        if success and data and data.jobIds and #data.jobIds > 0 then
            jobIds = data.jobIds
            serverCountLabel.Text = "Servers: "..#jobIds
            
            if isRunning then
                attemptCount = 0
                serverHop()
            end
        end
    end)
    
    -- Connection closed handler
    newSocket.OnClose:Connect(function()
        if isRunning then
            statusLabel.Text = "Reconnecting..."
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        end
    end)
    
    -- Error handler
    newSocket.OnError:Connect(function(err)
        warn("WebSocket error:", err)
        if isRunning then
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        end
    end)
    
    statusLabel.Text = "Connected"
    statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    return newSocket
end

-- Server hopping logic
local function serverHop()
    if not isRunning or #jobIds == 0 then return end
    
    -- Throttle hopping attempts
    if os.time() - lastHopTime < TELEPORT_DELAY then
        task.wait(TELEPORT_DELAY - (os.time() - lastHopTime))
    end
    
    currentJobIdIndex = (currentJobIdIndex % #jobIds) + 1
    local jobId = jobIds[currentJobIdIndex]
    lastHopTime = os.time()
    
    statusLabel.Text = "Joining server "..currentJobIdIndex.."/"..#jobIds
    statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
    
    if not success then
        attemptCount = attemptCount + 1
        warn("Teleport attempt "..attemptCount.." failed:", err)
        
        if attemptCount >= MAX_ATTEMPTS then
            statusLabel.Text = "Max attempts reached"
            statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            isRunning = false
            return
        end
        
        task.wait(TELEPORT_DELAY)
        serverHop() -- Try next server
    end
end

-- Control functions
local function startJoining()
    if isRunning then return end
    
    isRunning = true
    attemptCount = 0
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
    stopBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    
    if not socket then
        socket = connectWebSocket()
    elseif #jobIds > 0 then
        serverHop()
    end
end

local function stopJoining()
    if not isRunning then return end
    
    isRunning = false
    startBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
    stopBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 80)
    
    statusLabel.Text = "Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
end

-- Button connections
startBtn.MouseButton1Click:Connect(startJoining)
stopBtn.MouseButton1Click:Connect(stopJoining)

-- Cleanup on player leave
player.AncestryChanged:Connect(function(_, parent)
    if not parent and socket then
        pcall(function() socket:Close() end)
    end
end)

-- Debug info
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F3 then
        print("\n=== DEBUG INFO ===")
        print("Running:", isRunning)
        print("Socket:", socket and "Connected" or "Disconnected")
        print("Job IDs:", #jobIds)
        print("Current index:", currentJobIdIndex)
        print("Attempts:", attemptCount)
        print("=================")
    end
end)
