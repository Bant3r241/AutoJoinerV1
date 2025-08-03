local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Wait for player to load properly
local player = Players.LocalPlayer
repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

-- WebSocket Configuration
local WEBSOCKET_URL = "wss://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev/"
local socket = nil
local RECONNECT_DELAY = 5 -- seconds

-- Create UI (your existing UI creation code here)
-- [Previous UI creation code...]

-- ========== WebSocket Implementation with Full Error Handling ==========

local isRunning = false
local currentJobIdIndex = 0
local jobIds = {}
local teleportAttempts = 0
local MAX_TELEPORT_ATTEMPTS = 5

-- Verify WebSocket exists
if not WebSocket then
    warn("WebSocket is not available in this environment")
    updateStatus("WebSocket not supported", Color3.fromRGB(255, 0, 0))
    return
end

local function updateStatus(text, color)
    if statusLabel then
        statusLabel.Text = "Status: "..text
        statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    end
end

-- Safe WebSocket connection with full error handling
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
    if newSocket.OnMessage then
        newSocket.OnMessage:Connect(function(message)
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(message)
            end)
            
            if decodeSuccess and data and data.jobIds then
                jobIds = data.jobIds
                updateStatus("Connected - "..#jobIds.." servers", Color3.fromRGB(0, 255, 0))
                
                if isRunning and #jobIds > 0 then
                    serverHop()
                end
            end
        end)
    else
        warn("WebSocket does not have OnMessage event")
    end
    
    -- Close handler
    if newSocket.OnClose then
        newSocket.OnClose:Connect(function()
            if isRunning then
                warn("Connection closed - attempting reconnect")
                updateStatus("Reconnecting...", Color3.fromRGB(255, 165, 0))
                task.wait(RECONNECT_DELAY)
                socket = connectWebSocket()
            else
                updateStatus("Disconnected", Color3.fromRGB(255, 100, 100))
            end
        end)
    end
    
    return newSocket
end

-- Safe server hop with teleport validation
local function serverHop()
    if not player or not player:IsDescendantOf(game) then
        updateStatus("Player not valid", Color3.fromRGB(255, 0, 0))
        return false
    end
    
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
    if not jobId or type(jobId) ~= "string" then
        warn("Invalid job ID:", jobId)
        return false
    end

    updateStatus("Joining server "..currentJobIdIndex.."/"..#jobIds, Color3.fromRGB(0, 255, 255))
    
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

-- Start/Stop with complete safety checks
startBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    
    isRunning = true
    teleportAttempts = 0
    updateStatus("Starting...", Color3.fromRGB(0, 255, 255))
    
    -- Initialize WebSocket connection
    socket = connectWebSocket()
    
    -- Fallback if connection fails
    if not socket and isRunning then
        task.delay(5, function()
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

-- Cleanup when player leaves
local function cleanup()
    isRunning = false
    if socket then
        pcall(function() socket:Close() end)
        socket = nil
    end
end

player.AncestryChanged:Connect(function(_, parent)
    if not parent then
        cleanup()
    end
end)

game:BindToClose(function()
    cleanup()
end)
