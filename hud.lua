local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Wait for player to load
local player = Players.LocalPlayer or Players:GetPlayers()[1]
repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- WebSocket Configuration
local WEBSOCKET_URL = "wss://your-replit-server.your-username.repl.co/"
local socket = nil
local RECONNECT_DELAY = 5 -- seconds

-- Create UI (your existing UI code here remains the same)
-- [Previous UI creation code...]

-- ========== Improved WebSocket Implementation ==========

local isRunning = false
local currentJobIdIndex = 0
local jobIds = {}
local teleportAttempts = 0
local MAX_TELEPORT_ATTEMPTS = 5

local function updateStatus(text, color)
    statusLabel.Text = "Status: "..text
    statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

-- Safe WebSocket connection function
local function connectWebSocket()
    updateStatus("Connecting...", Color3.fromRGB(255, 255, 0))
    
    local success, newSocket = pcall(function()
        return WebSocket.connect(WEBSOCKET_URL)
    end)
    
    if not success or not newSocket then
        updateStatus("Connection failed", Color3.fromRGB(255, 0, 0))
        warn("WebSocket connection failed:", newSocket)
        return nil
    end
    
    -- Message handler
    newSocket.OnMessage:Connect(function(message)
        local success, data = pcall(function()
            return HttpService:JSONDecode(message)
        end)
        
        if success and data and data.jobIds then
            jobIds = data.jobIds
            updateStatus("Connected - "..#jobIds.." servers", Color3.fromRGB(0, 255, 0))
            
            if isRunning and #jobIds > 0 then
                serverHop()
            end
        end
    end)
    
    -- Close handler
    newSocket.OnClose:Connect(function()
        if isRunning then
            warn("Connection closed - attempting reconnect in "..RECONNECT_DELAY.."s")
            updateStatus("Reconnecting...", Color3.fromRGB(255, 165, 0))
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        else
            updateStatus("Disconnected", Color3.fromRGB(255, 100, 100))
        end
    end)
    
    return newSocket
end

-- Safe server hop function
local function serverHop()
    if #jobIds == 0 then
        warn("No job ids available for teleport")
        updateStatus("No servers available", Color3.fromRGB(255, 0, 0))
        return false
    end
    
    currentJobIdIndex = currentJobIdIndex + 1
    if currentJobIdIndex > #jobIds then
        currentJobIdIndex = 1
    end

    local jobId = jobIds[currentJobIdIndex]
    updateStatus("Joining server "..currentJobIdIndex.."/"..#jobIds, Color3.fromRGB(0, 255, 255))
    print("Teleporting to job id:", jobId)

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
    
    if not success then
        warn("Teleport failed:", err)
        updateStatus("Teleport failed", Color3.fromRGB(255, 0, 0))
        teleportAttempts = teleportAttempts + 1
        return false
    end
    
    teleportAttempts = 0
    return true
end

-- Start/Stop functions with proper nil checks
startBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    
    isRunning = true
    teleportAttempts = 0
    updateStatus("Starting...", Color3.fromRGB(0, 255, 255))
    
    -- Initialize WebSocket connection
    socket = connectWebSocket()
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isRunning then return end
    
    isRunning = false
    if socket then
        pcall(function() socket:Close() end)
        socket = nil
    end
    updateStatus("Stopped", Color3.fromRGB(255, 100, 100))
end)

-- Cleanup
player.AncestryChanged:Connect(function(_, parent)
    if not parent then
        isRunning = false
        if socket then
            pcall(function() socket:Close() end)
        end
    end
end)
