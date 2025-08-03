local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- WebSocket Configuration
local WEBSOCKET_URL = "wss://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev/"
local socket = nil
local RECONNECT_DELAY = 5 -- seconds

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoJoinerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create draggable frame with black background
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0.5, -150, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Draggable logic (keep your existing drag code)
-- [Previous drag implementation...]

-- UI Elements (keep your existing UI creation code)
-- [Previous UI creation code...]

-- ========== IMPROVED WebSocket Auto-Joiner Logic ==========

local PLACE_ID = game.PlaceId
local isRunning = false
local currentJobIdIndex = 0
local jobIds = {}
local teleportAttempts = 0
local MAX_TELEPORT_ATTEMPTS = 5
local connectionAttempts = 0
local MAX_CONNECTION_ATTEMPTS = 3

-- Enhanced status updates
local function updateStatus(text, color)
    if statusLabel then
        statusLabel.Text = "Status: "..text
        statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    end
end

-- Safe WebSocket connection with retries
local function connectWebSocket()
    if connectionAttempts >= MAX_CONNECTION_ATTEMPTS then
        updateStatus("Max connection attempts", Color3.fromRGB(255, 0, 0))
        return nil
    end

    connectionAttempts += 1
    updateStatus("Connecting (Attempt "..connectionAttempts..")", Color3.fromRGB(255, 255, 0))
    
    local success, newSocket = pcall(function()
        return WebSocket.connect(WEBSOCKET_URL)
    end)
    
    if not success or not newSocket then
        warn("WebSocket connection failed:", newSocket)
        task.wait(RECONNECT_DELAY)
        return connectWebSocket()
    end

    connectionAttempts = 0
    
    -- Message handler
    newSocket.OnMessage:Connect(function(message)
        local success, data = pcall(HttpService.JSONDecode, HttpService, message)
        if success and data and data.jobIds then
            jobIds = data.jobIds
            updateStatus("Active: "..#jobIds.." servers", Color3.fromRGB(0, 255, 0))
            
            if isRunning and #jobIds > 0 then
                serverHop()
            end
        end
    end)
    
    -- Close handler
    newSocket.OnClose:Connect(function()
        if isRunning then
            warn("Connection closed - reconnecting")
            updateStatus("Reconnecting...", Color3.fromRGB(255, 165, 0))
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        else
            updateStatus("Disconnected", Color3.fromRGB(255, 100, 100))
        end
    end)
    
    -- Error handler
    newSocket.OnError:Connect(function(err)
        warn("WebSocket error:", err)
        updateStatus("Connection error", Color3.fromRGB(255, 0, 0))
    end)
    
    updateStatus("Connected successfully", Color3.fromRGB(0, 255, 0))
    return newSocket
end

-- Improved server hop with validation
local function serverHop()
    if not player or not player.Parent then
        updateStatus("Player invalid", Color3.fromRGB(255, 0, 0))
        return false
    end
    
    if #jobIds == 0 then
        warn("No job ids available")
        updateStatus("No servers available", Color3.fromRGB(255, 0, 0))
        return false
    end
    
    currentJobIdIndex = (currentJobIdIndex % #jobIds) + 1
    local jobId = jobIds[currentJobIdIndex]
    
    if not jobId or type(jobId) ~= "string" then
        warn("Invalid job ID format")
        return false
    end

    updateStatus("Joining server "..currentJobIdIndex.."/"..#jobIds, Color3.fromRGB(0, 255, 255))
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, player)
    end)
    
    if not success then
        warn("Teleport failed:", err)
        updateStatus("Teleport failed", Color3.fromRGB(255, 0, 0))
        teleportAttempts += 1
        return false
    end
    
    teleportAttempts = 0
    return true
end

-- Enhanced start/stop controls
startBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    
    isRunning = true
    teleportAttempts = 0
    connectionAttempts = 0
    updateStatus("Starting...", Color3.fromRGB(0, 255, 255))
    
    -- Connect WebSocket
    socket = connectWebSocket()
    
    -- Fallback if initial connection fails
    if not socket and isRunning then
        task.delay(RECONNECT_DELAY, function()
            if isRunning then
                socket = connectWebSocket()
            end
        end)
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isRunning then return end
    
    isRunning = false
    if socket then
        pcall(function()
            socket:Close()
            socket = nil
        end)
    end
    updateStatus("Stopped", Color3.fromRGB(255, 100, 100))
end)

-- Comprehensive cleanup
local function cleanUp()
    isRunning = false
    if socket then
        pcall(function()
            socket:Close()
            socket = nil
        end)
    end
end

player.AncestryChanged:Connect(function(_, parent)
    if not parent then
        cleanUp()
    end
end)

game:BindToClose(function()
    cleanUp()
end)

-- Initial status
updateStatus("Ready to connect", Color3.fromRGB(200, 200, 200))
