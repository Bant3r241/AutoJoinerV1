local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer or Players:GetPlayers()[1]
local PLACE_ID = game.PlaceId  -- Your game’s place ID

-- GUI creation (compact)
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local frame = Instance.new("Frame", screenGui)
frame.Size, frame.Position = UDim2.new(0,300,0,400), UDim2.new(0.5,-150,0.3,0)
frame.BackgroundColor3, frame.BorderSizePixel = Color3.new(0,0,0), 0

local function createTextBtn(parent,text,posY)
    local btn = Instance.new("TextButton", parent)
    btn.Size, btn.Position = UDim2.new(1,-40,0,40), UDim2.new(0,20,0,posY)
    btn.BackgroundColor3, btn.TextColor3 = Color3.new(0.235,0.235,0.235), Color3.new(1,1,1)
    btn.Font, btn.TextSize, btn.AutoButtonColor = Enum.Font.GothamBold, 20, false
    btn.Text = text
    return btn
end

local title = Instance.new("TextLabel", frame)
title.Size, title.Position = UDim2.new(1,-40,0,40), UDim2.new(0,20,0,15)
title.Text, title.TextColor3 = "AutoJoiner", Color3.new(0.353,0,0.353)
title.Font, title.TextSize = Enum.Font.GothamBold, 22
title.BackgroundTransparency, title.TextXAlignment = 1, Enum.TextXAlignment.Left

-- Dropdown
local mpsDropdown = createTextBtn(frame, "1M-3M ▼", 85)
local options = {"1M-3M","3M+"}
local optsFrame = Instance.new("Frame",frame)
optsFrame.Size, optsFrame.Position, optsFrame.BackgroundColor3 = UDim2.new(1,-40,0,0), UDim2.new(0,20,0,125), Color3.new(0.196,0.196,0.196)
optsFrame.ClipsDescendants = true
local dropdownOpen

mpsDropdown.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    optsFrame:TweenSize( UDim2.new(1,-40,0, dropdownOpen and #options * 40 or 0),
        Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true )
end)

for i,opt in ipairs(options) do
    local b = Instance.new("TextButton", optsFrame)
    b.Size, b.Position = UDim2.new(1,0,0,40), UDim2.new(0,0,0,(i-1)*40)
    b.BackgroundColor3, b.TextColor3 = Color3.new(0.274,0.274,0.274), Color3.new(1,1,1)
    b.Font, b.TextSize, b.Text = Enum.Font.GothamBold, 18, opt
    b.AutoButtonColor = false
    b.MouseButton1Click:Connect(function()
        mpsDropdown.Text = opt .. " ▼"
        dropdownOpen = false
        optsFrame:TweenSize(UDim2.new(1,-40,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end)
end

local startBtn = createTextBtn(frame, "Start", 190)
local stopBtn  = createTextBtn(frame, "Stop", 240)

-- Minimize/restore
local minimizeBtn = Instance.new("ImageButton", frame)
minimizeBtn.Size, minimizeBtn.Position = UDim2.new(0,40,0,40), UDim2.new(1,-40,0,0)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Image = "rbxassetid://2398054"  -- Internet Fail Cat
minimizeBtn.AutoButtonColor = false

local restoreImg = minimizeBtn:Clone()
restoreImg.Parent = screenGui
restoreImg.Position = UDim2.new(0,20,0,20)
restoreImg.Visible = false

minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible, restoreImg.Visible = false, true
end)
restoreImg.MouseButton1Click:Connect(function()
    frame.Visible, restoreImg.Visible = true, false
end)

-- Server hop functionality
startBtn.MouseButton1Click:Connect(function()
    spawn(function()
        local ok, res = pcall(function()
            return HttpService:GetAsync("https://your-api.com/latest-jobid")
        end)
        if ok then
            local data = HttpService:JSONDecode(res)
            if data.jobId then
                TeleportService:TeleportToPlaceInstance(PLACE_ID, data.jobId, player)
            else
                warn("Server Hop: invalid jobId")
            end
        else
            warn("Server Hop failed:", res)
        end
    end)
end)
