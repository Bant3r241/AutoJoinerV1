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
statusLabel.Position = UDim2.new(0, 20, 0, 50)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Disconnected"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- MPS Dropdown Label
local mpsLabel = Instance.new("TextLabel")
mpsLabel.Size = UDim2.new(1, -40, 0, 20)
mpsLabel.Position = UDim2.new(0, 20, 0, 80)
mpsLabel.BackgroundTransparency = 1
mpsLabel.Text = "Select MPS Range:"
mpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
mpsLabel.Font = Enum.Font.GothamBold
mpsLabel.TextSize = 18
mpsLabel.TextXAlignment = Enum.TextXAlignment.Left
mpsLabel.Parent = frame

-- MPS Dropdown Button
local mpsDropdown = Instance.new("TextButton")
mpsDropdown.Size = UDim2.new(1, -40, 0, 40)
mpsDropdown.Position = UDim2.new(0, 20, 0, 105)
mpsDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
mpsDropdown.BorderSizePixel = 0
mpsDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
mpsDropdown.Font = Enum.Font.GothamBold
mpsDropdown.TextSize = 18
mpsDropdown.Text = "1M-3M  ▼"
mpsDropdown.AutoButtonColor = false
mpsDropdown.Parent = frame

-- Dropdown container for MPS options
local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.new(1, -40, 0, 0)
optionsFrame.Position = UDim2.new(0, 20, 0, 145)
optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
optionsFrame.BorderSizePixel = 0
optionsFrame.ClipsDescendants = true
optionsFrame.Parent = frame

local mpsRanges = {"1M-3M", "3M+"}
local isOpen = false
local selectedMpsRange = mpsRanges[1]  -- default selection

local function toggleDropdown()
    if isOpen then
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    else
        optionsFrame:TweenSize(UDim2.new(1, -40, 0, #mpsRanges * 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    end
    isOpen = not isOpen
end

mpsDropdown.MouseButton1Click:Connect(toggleDropdown)

for i, range in ipairs(mpsRanges) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, (i - 1) * 40)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Text = range
    btn.AutoButtonColor = false
    btn.Parent = optionsFrame

    btn.MouseButton1Click:Connect(function()
        mpsDropdown.Text = range .. "  ▼"
        selectedMpsRange = range
        toggleDropdown()
    end)
end

-- Start and Stop buttons creator
local function createButton(text, positionY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = frame
    return btn
end

local startBtn = createButton("Start", 210)
local stopBtn = createButton("Stop", 260)

-- Minimize Button
local minimizeBtn = Instance.new("ImageButton")
minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
minimizeBtn.Position = UDim2.new(1, -40, 0, 0)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Image = "rbxassetid://2398054"
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = frame

-- Minimized Image Button
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

-- ========== WebSocket Auto-Joiner Logic ==========

local PLACE_ID = game.PlaceId
local isRunning = false
local currentJobIdIndex = 0
local jobIds = {}
local teleportAttempts = 0
local MAX_TELEPORT_ATTEMPTS = 5

local function updateStatus(text, color)
    statusLabel.Text = "Status: "..text
    statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

local function connectWebSocket()
    updateStatus("Connecting...", Color3.fromRGB(255, 255, 0))
    
    local newSocket = WebSocket.connect(WEBSOCKET_URL)
    
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
    
    newSocket.OnError:Connect(function(error)
        warn("WebSocket error:", error)
        updateStatus("Connection error", Color3.fromRGB(255, 0, 0))
    end)
    
    return newSocket
end

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
        TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, player)
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

startBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    
    isRunning = true
    teleportAttempts = 0
    updateStatus("Starting...", Color3.fromRGB(0, 255, 255))
    
    -- Connect WebSocket
    socket = connectWebSocket()
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isRunning then return end
    
    isRunning = false
    if socket then
        socket:Close()
        socket = nil
    end
    updateStatus("Stopped", Color3.fromRGB(255, 100, 100))
end)

-- Clean up when player leaves
player.AncestryChanged:Connect(function(_, parent)
    if not parent and socket then
        socket:Close()
    end
end)
