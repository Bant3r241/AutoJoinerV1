local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

repeat task.wait() until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")

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
statusLabel.Text = "Status: Idle"
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
        print("Selected MPS range:", range)
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

-- ========== Improved Server Hopping Logic ==========

local PLACE_ID = 109983668079237 -- Your Roblox place ID
local JOBID_ENDPOINT = "https://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev" -- Removed trailing slash

local isRunning = false
local currentJobIdIndex = 0
local jobIds = {}
local hoppingTask
local teleportAttempts = 0
local MAX_TELEPORT_ATTEMPTS = 5

local function updateStatus(text, color)
    statusLabel.Text = "Status: "..text
    statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

-- Improved fetch with retry logic
local function fetchJobIds()
    local attempts = 0
    local maxAttempts = 3
    local delayBetweenAttempts = 2
    
    while attempts < maxAttempts do
        attempts += 1
        
        local success, response = pcall(function()
            updateStatus("Fetching servers...", Color3.fromRGB(255, 255, 0))
            return HttpService:GetAsync(JOBID_ENDPOINT)
        end)
        
        if success then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            
            if ok and type(data) == "table" and #data > 0 then
                updateStatus("Fetched "..#data.." servers", Color3.fromRGB(0, 255, 0))
                return data
            else
                warn("Failed to decode job ids JSON or data not a table")
            end
        else
            warn("Attempt "..attempts.." failed to fetch job ids:", response)
        end
        
        if attempts < maxAttempts then
            task.wait(delayBetweenAttempts)
        end
    end
    
    updateStatus("Fetch failed", Color3.fromRGB(255, 0, 0))
    return nil
end

-- Improved server hop with error handling
local function serverHop()
    if #jobIds == 0 then
        warn("No job ids available for teleport")
        updateStatus("No servers found", Color3.fromRGB(255, 0, 0))
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
        return false
    end
    
    return true
end

startBtn.MouseButton1Click:Connect(function()
    if isRunning then
        print("AutoJoiner already running")
        return
    end
    
    isRunning = true
    teleportAttempts = 0
    updateStatus("Starting...", Color3.fromRGB(0, 255, 255))
    print("AutoJoiner started")

    -- Spawn the loop that fetches jobIds and teleports
    hoppingTask = task.spawn(function()
        while isRunning and teleportAttempts < MAX_TELEPORT_ATTEMPTS do
            print("Fetching job IDs...")
            local fetchedJobIds = fetchJobIds()

            if fetchedJobIds and #fetchedJobIds > 0 then
                jobIds = fetchedJobIds
                if serverHop() then
                    teleportAttempts = 0
                else
                    teleportAttempts += 1
                end
            else
                warn("No valid job ids fetched")
                teleportAttempts += 1
            end

            if isRunning then
                -- Wait between attempts, but check isRunning frequently
                local waitTime = 0
                while waitTime < 5 and isRunning do
                    task.wait(0.5)
                    waitTime += 0.5
                end
            end
        end
        
        if teleportAttempts >= MAX_TELEPORT_ATTEMPTS then
            updateStatus("Max attempts reached", Color3.fromRGB(255, 0, 0))
            warn("Max teleport attempts reached")
        end
        
        isRunning = false
        print("AutoJoiner loop ended")
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not isRunning then
        print("AutoJoiner is not running")
        return
    end
    isRunning = false
    updateStatus("Stopped", Color3.fromRGB(255, 100, 100))
    print("AutoJoiner stopped")
end)

-- Clean up on player leaving
player.AncestryChanged:Connect(function(_, parent)
    if not parent then
        isRunning = false
        if hoppingTask then
            task.cancel(hoppingTask)
        end
    end
end)
