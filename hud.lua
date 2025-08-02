local gui = script.Parent
local startButton = gui:WaitForChild("StartButton")
local pauseButton = gui:WaitForChild("PauseButton")
local okButton = gui:WaitForChild("OkButton")

-- Position & size buttons programmatically (optional)
startButton.Position = UDim2.new(0.5, -50, 0.3, 0)
pauseButton.Position = UDim2.new(0.5, -50, 0.45, 0)
okButton.Position = UDim2.new(0.5, -50, 0.6, 0)

startButton.Size = UDim2.new(0, 100, 0, 40)
pauseButton.Size = UDim2.new(0, 100, 0, 40)
okButton.Size = UDim2.new(0, 100, 0, 40)

-- Connect button events
startButton.MouseButton1Click:Connect(function()
	print("Start clicked")
end)

pauseButton.MouseButton1Click:Connect(function()
	print("Pause clicked")
end)

okButton.MouseButton1Click:Connect(function()
	print("OK clicked")
end)
