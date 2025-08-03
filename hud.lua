local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
print("1. Player identified:", player.Name)

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Wait for player GUI
repeat 
    task.wait(1)
    print("2. Waiting for PlayerGui...")
until player and player:FindFirstChild("PlayerGui")
local playerGui = player:WaitForChild("PlayerGui")
print("3. PlayerGui found")

-- WebSocket Configuration
local WEBSOCKET_URL = "wss://cd9df660-ee00-4af8-ba05-5112f2b5f870-00-xh16qzp1xfp5.janeway.replit.dev/"
print("4. WebSocket URL set:", WEBSOCKET_URL)

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoJoinerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
print("5. ScreenGui created")

-- [Insert all your existing UI creation code here]
print("6. UI elements created")

-- ========== DEBUGGING VERSION ==========
print("7. Starting main logic...")

local socket = nil
local isRunning = false
local jobIds = {}

-- Debug status function
local function updateStatus(text, color)
    print("STATUS:", text)
    if statusLabel then
        statusLabel.Text = "Status: "..text
        statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    end
end

-- Test WebSocket connection
print("8. Testing WebSocket support...")
if not WebSocket then
    updateStatus("ERROR: WebSocket not available", Color3.fromRGB(255, 0, 0))
    print("9. CRITICAL: WebSocket API not found")
    return -- Stop script if no WebSocket support
else
    print("9. WebSocket API available")
end

-- Basic connection test
local function testConnection()
    print("10. Attempting test connection...")
    local testSocket, err = pcall(WebSocket.connect, WEBSOCKET_URL)
    if not testSocket then
        updateStatus("Connection test failed", Color3.fromRGB(255, 0, 0))
        print("11. CONNECTION FAILED:", err)
        return false
    end
    print("11. Connection test successful")
    pcall(function() testSocket:Close() end)
    return true
end

if not testConnection() then
    updateStatus("Server unavailable", Color3.fromRGB(255, 100, 0))
    print("12. Aborting due to connection failure")
    return
end

print("13. Proceeding with main functions...")

-- [Rest of your existing WebSocket and teleport code]
-- Add print statements before each major operation like:
-- print("Attempting WebSocket connect...")
-- print("Received message:", message)
-- print("Attempting teleport to:", jobId)

-- Modified start button with debug
startBtn.MouseButton1Click:Connect(function()
    print("START BUTTON PRESSED")
    if isRunning then 
        print("Already running")
        return 
    end
    
    isRunning = true
    print("Attempting connection...")
    socket = connectWebSocket()
end)

-- Add this debug function
local function debugInfo()
    print("\n=== DEBUG INFO ===")
    print("Running:", isRunning)
    print("Socket state:", socket and "Connected" or "Disconnected")
    print("Job IDs count:", #jobIds)
    print("Last status:", statusLabel and statusLabel.Text or "No status label")
    print("Place ID:", game.PlaceId)
    print("Player:", player.Name)
    print("=================\n")
end

-- Add debug command (press F3)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F3 then
        debugInfo()
    end
end)

print("14. Script initialization complete")
updateStatus("Ready - Press Start", Color3.fromRGB(0, 200, 0))
