local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Debug initialization
print("=== AutoJoiner Initializing ===")

-- Player setup with error handling
local player = Players.LocalPlayer
if not player then
    player = Players:GetPlayers()[1]
    if not player then
        warn("No player found! Retrying...")
        repeat task.wait(1) until #Players:GetPlayers() > 0
        player = Players:GetPlayers()[1]
    end
end
print("Player identified:", player.Name)

-- Wait for PlayerGui with timeout
local playerGui
local startTime = os.time()
repeat 
    playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        task.wait(1)
        print("Waiting for PlayerGui...")
        if os.time() - startTime > 10 then
            warn("PlayerGui not found after 10 seconds!")
            return
        end
    end
until playerGui
playerGui = player:WaitForChild("PlayerGui")
print("PlayerGui loaded successfully")

-- WebSocket Configuration
local WEBSOCKET_URL = "wss://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev/"
print("WebSocket URL:", WEBSOCKET_URL)

-- UI Creation Functions
local function createLabel(name, text, position, parent)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Text = text
    label.Position = position
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createButton(name, text, position, parent)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Position = position
    button.Size = UDim2.new(1, -40, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.AutoButtonColor = false
    button.Parent = parent
    return button
end

-- Main GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoJoinerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0.5, -150, 0.3, 0)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Title
createLabel("Title", "AutoJoiner", UDim2.new(0, 20, 0, 15), frame).TextSize = 22

-- Status label
local statusLabel = createLabel("Status", "Status: Initializing", UDim2.new(0, 20, 0, 50), frame)

-- Create buttons with verification
local startBtn = createButton("StartButton", "Start", UDim2.new(0, 20, 0, 210), frame)
local stopBtn = createButton("StopButton", "Stop", UDim2.new(0, 20, 0, 260), frame)

-- WebSocket Implementation
local socket = nil
local isRunning = false
local jobIds = {}
local currentJobIdIndex = 0
local RECONNECT_DELAY = 5
local MAX_TELEPORT_ATTEMPTS = 5

local function updateStatus(text, color)
    if statusLabel then
        statusLabel.Text = "Status: "..text
        statusLabel.TextColor3 = color or Color3.new(1, 1, 1)
    end
    print("Status:", text)
end

local function connectWebSocket()
    if not WebSocket then
        updateStatus("WebSocket not supported", Color3.new(1, 0, 0))
        return nil
    end

    updateStatus("Connecting...", Color3.new(1, 1, 0))
    
    local success, newSocket = pcall(function()
        return WebSocket.connect(WEBSOCKET_URL)
    end)
    
    if not success then
        updateStatus("Connection failed", Color3.new(1, 0, 0))
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
            updateStatus("Connected: "..#jobIds.." servers", Color3.new(0, 1, 0))
            
            if isRunning and #jobIds > 0 then
                task.spawn(serverHop)
            end
        end
    end)
    
    -- Close handler
    newSocket.OnClose:Connect(function()
        if isRunning then
            updateStatus("Reconnecting...", Color3.new(1, 0.5, 0))
            task.wait(RECONNECT_DELAY)
            socket = connectWebSocket()
        else
            updateStatus("Disconnected", Color3.new(1, 0.3, 0.3))
        end
    end)
    
    updateStatus("Connected successfully", Color3.new(0, 1, 0))
    return newSocket
end

local function serverHop()
    if not player or not player.Parent then
        updateStatus("Player invalid", Color3.new(1, 0, 0))
        return false
    end
    
    if #jobIds == 0 then
        updateStatus("No servers available", Color3.new(1, 0, 0))
        return false
    end
    
    currentJobIdIndex = (currentJobIdIndex % #jobIds) + 1
    local jobId = jobIds[currentJobIdIndex]
    
    updateStatus("Joining server "..currentJobIdIndex, Color3.new(0, 1, 1))
    print("Attempting teleport to:", jobId)

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
    
    if not success then
        updateStatus("Teleport failed", Color3.new(1, 0, 0))
        warn("Teleport error:", err)
        return false
    end
    
    return true
end

-- Button handlers with protection
local function safeConnect()
    if isRunning then return end
    
    isRunning = true
    updateStatus("Starting...", Color3.new(0, 1, 1))
    socket = connectWebSocket()
end

local function safeDisconnect()
    if not isRunning then return end
    
    isRunning = false
    if socket then
        pcall(function() socket:Close() end)
        socket = nil
    end
    updateStatus("Stopped", Color3.new(1, 0.3, 0.3))
end

-- Connect buttons
startBtn.MouseButton1Click:Connect(safeConnect)
stopBtn.MouseButton1Click:Connect(safeDisconnect)

-- Cleanup
game:BindToClose(function()
    if socket then
        pcall(function() socket:Close() end)
    end
end)

updateStatus("Ready to connect", Color3.new(0.8, 0.8, 0.8))
print("=== AutoJoiner Initialization Complete ===")
