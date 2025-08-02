local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
repeat wait() until player:FindFirstChild("PlayerGui")

local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "MySimpleGui"

local function createButton(name, pos, text)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 100, 0, 40)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 18
    btn.Parent = gui
    return btn
end

local startBtn = createButton("Start", UDim2.new(0.5, -50, 0.4, 0), "Start")
local pauseBtn = createButton("Pause", UDim2.new(0.5, -50, 0.5, 0), "Pause")
local okBtn = createButton("OK", UDim2.new(0.5, -50, 0.6, 0), "OK")

startBtn.MouseButton1Click:Connect(function()
    print("Start clicked")
end)

pauseBtn.MouseButton1Click:Connect(function()
    print("Pause clicked")
end)

okBtn.MouseButton1Click:Connect(function()
    print("OK clicked")
end)
