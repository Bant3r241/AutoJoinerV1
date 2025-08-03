-- AutoJoiner with Enhanced Message Parsing
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

-- Draggable Logic (same as before)
local dragging, dragInput, dragStart, startPos
-- ... [Previous draggable code remains unchanged] ...

-- UI Elements (same structure as before)
-- ... [Previous UI creation code remains unchanged] ...

-- Improved WebSocket Message Handler
local function handleWebSocketMessage(message)
    if isPaused then return end
    
    print("[WebSocket] Raw message:", message) -- Debug output
    
    -- Parse using multiple possible formats
    local jobId, mpsValue
    
    -- Format 1: Multi-line text
    -- New Server Detected "Name"
    -- Money/sec $1.5m
    -- job id "abc123"
    if not jobId then
        jobId = message:match('job id%s*["\']([^"\']+)["\']')
        mpsValue = message:match('Money/sec%s*%$([%d%.]+)m')
    end
    
    -- Format 2: JSON
    -- {"jobId":"abc123","mps":1.5}
    if not jobId then
        local success, data = pcall(HttpService.JSONDecode, HttpService, message)
        if success then
            jobId = data.jobId or data.jobid or data.serverId
            mpsValue = data.mps or data.moneyPerSecond or data.rate
        end
    end
    
    -- Format 3: Compact text
    -- Server: abc123 | MPS: 1.5m
    if not jobId then
        jobId = message:match('Server:%s*([%w-]+)')
        mpsValue = message:match('MPS:%s*([%d%.]+)m')
    end
    
    -- Validate results
    if not jobId or not mpsValue then
        statusLabel.Text = "Status: Unrecognized format"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        print("[ERROR] Failed to parse. Sample formats:")
        print('1. New Server "Name"\nMoney/sec $1.5m\njob id "abc123"')
        print('2. {"jobId":"abc123","mps":1.5}')
        print('3. Server: abc123 | MPS: 1.5m')
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
    local mpsMillions = mps -- Already in millions format
    
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
end

-- Robust WebSocket Connection
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
        print("Connected:", socket and true or false)
        print("Running:", isRunning)
        print("Paused:", isPaused)
        print("Last Job ID:", activeJobId)
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
