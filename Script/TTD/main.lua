--[[
    Auto Sell & Auto Summon Units - TTD/Delta
]]

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Require MultiboxFramework
local MultiboxFramework = require(game:GetService("ReplicatedStorage"):WaitForChild("MultiboxFramework"))

-- Tunggu sampai framework loaded
while not MultiboxFramework.Loaded do
    RunService.Heartbeat:Wait()
end

local SharedSettings = MultiboxFramework:WaitForModule("SharedSettings")
local TroopDatas = SharedSettings.TroopDatas
local TroopsSellData = SharedSettings.TroopsSellData

local PlayerDataReplica = MultiboxFramework.Replicate:WaitForReplica("PlayerData-" .. LocalPlayer.UserId)

-- ============================================================
-- KILL LOOP LAMA & HAPUS GUI LAMA
-- Setiap inject baru dapat token unik. Loop lama cek token,
-- jika tidak cocok langsung berhenti.
-- ============================================================
local INSTANCE_TOKEN = {}
_G._AutoToolsToken = INSTANCE_TOKEN  -- simpan token instansi ini ke _G

for _, gui in pairs(CoreGui:GetChildren()) do
    if gui.Name == "AutoSellGui" then
        gui:Destroy()
    end
end

-- ============================================================
-- BUAT GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoSellGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
    end
end)

pcall(function()
    if gethui then
        screenGui.Parent = gethui()
        return
    end
end)

if not screenGui.Parent then
    screenGui.Parent = CoreGui
end

-- MINIMIZED ICON (Round)
local minimizedIcon = Instance.new("ImageButton")
minimizedIcon.Name = "MinimizedIcon"
minimizedIcon.Size = UDim2.new(0, 50, 0, 50)
minimizedIcon.Position = UDim2.new(0.5, -25, 0, 20)
minimizedIcon.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
minimizedIcon.BorderSizePixel = 0
minimizedIcon.Active = true
minimizedIcon.Draggable = true
minimizedIcon.Visible = false
minimizedIcon.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = minimizedIcon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(60, 60, 80)
iconStroke.Thickness = 2
iconStroke.Parent = minimizedIcon

local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
iconLabel.TextSize = 24
iconLabel.Font = Enum.Font.GothamBold
iconLabel.Text = "⚔"
iconLabel.Parent = minimizedIcon

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Size = UDim2.new(0.95, 0, 0.9, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainSizeConstraint = Instance.new("UISizeConstraint")
mainSizeConstraint.MaxSize = Vector2.new(320, 480)
mainSizeConstraint.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 80)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleFill = Instance.new("Frame")
titleFill.Size = UDim2.new(1, 0, 0, 10)
titleFill.Position = UDim2.new(0, 0, 1, -10)
titleFill.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleFill.BorderSizePixel = 0
titleFill.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "⚔ Auto Tools"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
minimizeBtn.Position = UDim2.new(1, -66, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 18
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "-"
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    minimizedIcon.Visible = true
end)

local minDragStart
minimizedIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        minDragStart = minimizedIcon.AbsolutePosition
    end
end)

minimizedIcon.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local currentPos = minimizedIcon.AbsolutePosition
        if minDragStart and (currentPos - minDragStart).Magnitude < 5 then
            minimizedIcon.Visible = false
            mainFrame.Visible = true
        end
    end
end)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Container (ScrollingFrame)
local container = Instance.new("ScrollingFrame")
container.Name = "Container"
container.Size = UDim2.new(1, -16, 1, -56)
container.Position = UDim2.new(0, 8, 0, 48)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 3
container.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
container.CanvasSize = UDim2.new(0, 0, 0, 0)
container.AutomaticCanvasSize = Enum.AutomaticSize.Y
container.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = container

-- Helper Function to create Section Headers
local function createHeader(text, order)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -8, 0, 24)
    header.BackgroundTransparency = 1
    header.TextColor3 = Color3.fromRGB(200, 200, 255)
    header.TextSize = 14
    header.Font = Enum.Font.GothamBold
    header.Text = "-- " .. text .. " --"
    header.LayoutOrder = order
    header.Parent = container
end

-- ============================================================
-- GLOBAL STATE & CONFIG
-- ============================================================
local state = {
    autoSummonEnabled = false,
    autoSummonType = "Summon 1x",
    autoSummonInterval = 5,
    autoSellEnabled = false,
    autoSellInterval = 10,
    selectedRarities = {},
    sellRemoteId = "\226\129\130E",
    summon1xRemoteId = "\226\129\130>",
    summon9xRemoteId = "\226\129\130?",
    selectTradeRemoteId = "\226\129\130&",
    isListeningSell = false,
    isListeningSummon1x = false,
    isListeningSummon9x = false,
    isListeningSelectTrade = false
}

local configFolder = "TTD_AutoTools"
local configPath = configFolder .. "/config.json"

local function SaveConfig()
    pcall(function()
        if makefolder and not isfolder(configFolder) then
            makefolder(configFolder)
        end
        if writefile then
            local configState = {}
            for k, v in pairs(state) do
                if k ~= "autoSummonEnabled" and k ~= "autoSellEnabled" and not string.find(k, "isListening") then
                    configState[k] = v
                end
            end
            writefile(configPath, HttpService:JSONEncode(configState))
        end
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile and readfile and isfile(configPath) then
            local data = HttpService:JSONDecode(readfile(configPath))
            if data then
                for k, v in pairs(data) do
                    if k ~= "autoSummonEnabled" and k ~= "autoSellEnabled" and not string.find(k, "isListening") then
                        state[k] = v
                    end
                end
            end
        end
    end)
end

LoadConfig()

local coinsLabel = nil
local statusLabel = nil  -- forward declaration agar bisa diakses oleh tradeBtn callback
local listenTradeBtn = nil
local idTradeInput = nil
local rarityCountLabels = {}

-- ============================================================
-- STATISTICS SECTION
-- ============================================================
createHeader("STATISTICS", 1)

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -8, 0, 30)
statsFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
statsFrame.LayoutOrder = 2
statsFrame.Parent = container
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 6)

coinsLabel = Instance.new("TextLabel", statsFrame)
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(1, -20, 1, 0)
coinsLabel.Position = UDim2.new(0, 10, 0, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.TextSize = 14
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Text = "💰 Coins: 0"
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ============================================================
-- AUTO SUMMON SECTION
-- ============================================================
createHeader("AUTO SUMMON", 10)

local autoSummonFrame = Instance.new("Frame")
autoSummonFrame.Size = UDim2.new(1, -8, 0, 140)
autoSummonFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
autoSummonFrame.LayoutOrder = 11
autoSummonFrame.Parent = container
Instance.new("UICorner", autoSummonFrame).CornerRadius = UDim.new(0, 6)

-- Toggle
local asToggleLabel = Instance.new("TextLabel", autoSummonFrame)
asToggleLabel.Size = UDim2.new(0, 120, 0, 30)
asToggleLabel.Position = UDim2.new(0, 10, 0, 5)
asToggleLabel.BackgroundTransparency = 1
asToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
asToggleLabel.Font = Enum.Font.Gotham
asToggleLabel.TextSize = 14
asToggleLabel.Text = "Enable Auto Summon:"
asToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

local asToggleBtn = Instance.new("TextButton", autoSummonFrame)
asToggleBtn.Size = UDim2.new(0, 22, 0, 22)
asToggleBtn.Position = UDim2.new(1, -30, 0, 9)
asToggleBtn.BackgroundColor3 = state.autoSummonEnabled and Color3.fromRGB(0, 160, 60) or Color3.fromRGB(55, 55, 65)
asToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
asToggleBtn.Font = Enum.Font.GothamBold
asToggleBtn.Text = state.autoSummonEnabled and "✓" or ""
Instance.new("UICorner", asToggleBtn).CornerRadius = UDim.new(0, 4)

asToggleBtn.MouseButton1Click:Connect(function()
    state.autoSummonEnabled = not state.autoSummonEnabled
    if state.autoSummonEnabled then
        asToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
        asToggleBtn.Text = "✓"
    else
        asToggleBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        asToggleBtn.Text = ""
    end
    SaveConfig()
end)

-- Type
local asTypeLabel = Instance.new("TextLabel", autoSummonFrame)
asTypeLabel.Size = UDim2.new(0, 120, 0, 30)
asTypeLabel.Position = UDim2.new(0, 10, 0, 35)
asTypeLabel.BackgroundTransparency = 1
asTypeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
asTypeLabel.Font = Enum.Font.Gotham
asTypeLabel.TextSize = 14
asTypeLabel.Text = "Summon Type:"
asTypeLabel.TextXAlignment = Enum.TextXAlignment.Left

local asTypeBtn = Instance.new("TextButton", autoSummonFrame)
asTypeBtn.Size = UDim2.new(0, 100, 0, 24)
asTypeBtn.Position = UDim2.new(1, -110, 0, 38)
asTypeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
asTypeBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
asTypeBtn.Font = Enum.Font.GothamBold
asTypeBtn.TextSize = 12
asTypeBtn.Text = state.autoSummonType
Instance.new("UICorner", asTypeBtn).CornerRadius = UDim.new(0, 4)

asTypeBtn.MouseButton1Click:Connect(function()
    if state.autoSummonType == "Summon 1x" then
        state.autoSummonType = "Summon 9x"
    else
        state.autoSummonType = "Summon 1x"
    end
    asTypeBtn.Text = state.autoSummonType
    SaveConfig()
end)

-- Interval
local asIntervalLabel = Instance.new("TextLabel", autoSummonFrame)
asIntervalLabel.Size = UDim2.new(0, 120, 0, 30)
asIntervalLabel.Position = UDim2.new(0, 10, 0, 65)
asIntervalLabel.BackgroundTransparency = 1
asIntervalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
asIntervalLabel.Font = Enum.Font.Gotham
asIntervalLabel.TextSize = 14
asIntervalLabel.Text = "Interval (seconds):"
asIntervalLabel.TextXAlignment = Enum.TextXAlignment.Left

local asIntervalInput = Instance.new("TextBox", autoSummonFrame)
asIntervalInput.Size = UDim2.new(0, 50, 0, 24)
asIntervalInput.Position = UDim2.new(1, -60, 0, 68)
asIntervalInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
asIntervalInput.TextColor3 = Color3.fromRGB(255, 255, 255)
asIntervalInput.Font = Enum.Font.Gotham
asIntervalInput.TextSize = 14
asIntervalInput.Text = tostring(state.autoSummonInterval)
Instance.new("UICorner", asIntervalInput).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", asIntervalInput).Color = Color3.fromRGB(100, 100, 120)

asIntervalInput.FocusLost:Connect(function()
    local val = tonumber(asIntervalInput.Text)
    if val and val > 0 then
        state.autoSummonInterval = val
        SaveConfig()
    else
        asIntervalInput.Text = tostring(state.autoSummonInterval)
    end
end)

-- Listen Summon 1X Button
local listen1xBtn = Instance.new("TextButton", autoSummonFrame)
listen1xBtn.Size = UDim2.new(0.5, -55, 0, 26)
listen1xBtn.Position = UDim2.new(0, 10, 0, 105)
listen1xBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
listen1xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
listen1xBtn.Font = Enum.Font.GothamBold
listen1xBtn.TextSize = 11
listen1xBtn.Text = "🎧 LISTEN 1X"
Instance.new("UICorner", listen1xBtn).CornerRadius = UDim.new(0, 4)

local id1xInput = Instance.new("TextBox", autoSummonFrame)
id1xInput.Size = UDim2.new(0, 40, 0, 26)
id1xInput.Position = UDim2.new(0.5, -41, 0, 105)
id1xInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
id1xInput.TextColor3 = Color3.fromRGB(255, 255, 255)
id1xInput.Font = Enum.Font.GothamBold
id1xInput.TextSize = 12
id1xInput.Text = string.gsub(state.summon1xRemoteId or "", "\226\129\130", "")
Instance.new("UICorner", id1xInput).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", id1xInput).Color = Color3.fromRGB(100, 100, 120)
id1xInput.FocusLost:Connect(function()
    if id1xInput.Text ~= "" then
        state.summon1xRemoteId = "\226\129\130" .. id1xInput.Text
        SaveConfig()
    else
        id1xInput.Text = string.gsub(state.summon1xRemoteId or "", "\226\129\130", "")
    end
end)

listen1xBtn.MouseButton1Click:Connect(function()
    if state.isListeningSummon1x then
        state.isListeningSummon1x = false
        listen1xBtn.Text = "🎧 LISTEN 1X"
        listen1xBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        if statusLabel then
            statusLabel.Text = "Berhenti mendengarkan Summon 1x"
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    else
        state.isListeningSummon1x = true
        listen1xBtn.Text = "MENDENGARKAN..."
        listen1xBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        if statusLabel then
            statusLabel.Text = "Silakan Summon 1x di dalam game"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        end
    end
end)

-- Listen Summon 9X Button
local listen9xBtn = Instance.new("TextButton", autoSummonFrame)
listen9xBtn.Size = UDim2.new(0.5, -55, 0, 26)
listen9xBtn.Position = UDim2.new(0.5, 6, 0, 105)
listen9xBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
listen9xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
listen9xBtn.Font = Enum.Font.GothamBold
listen9xBtn.TextSize = 11
listen9xBtn.Text = "🎧 LISTEN 9X"
Instance.new("UICorner", listen9xBtn).CornerRadius = UDim.new(0, 4)

local id9xInput = Instance.new("TextBox", autoSummonFrame)
id9xInput.Size = UDim2.new(0, 40, 0, 26)
id9xInput.Position = UDim2.new(1, -44, 0, 105)
id9xInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
id9xInput.TextColor3 = Color3.fromRGB(255, 255, 255)
id9xInput.Font = Enum.Font.GothamBold
id9xInput.TextSize = 12
id9xInput.Text = string.gsub(state.summon9xRemoteId or "", "\226\129\130", "")
Instance.new("UICorner", id9xInput).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", id9xInput).Color = Color3.fromRGB(100, 100, 120)
id9xInput.FocusLost:Connect(function()
    if id9xInput.Text ~= "" then
        state.summon9xRemoteId = "\226\129\130" .. id9xInput.Text
        SaveConfig()
    else
        id9xInput.Text = string.gsub(state.summon9xRemoteId or "", "\226\129\130", "")
    end
end)

listen9xBtn.MouseButton1Click:Connect(function()
    if state.isListeningSummon9x then
        state.isListeningSummon9x = false
        listen9xBtn.Text = "🎧 LISTEN 9X"
        listen9xBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        if statusLabel then
            statusLabel.Text = "Berhenti mendengarkan Summon 9x"
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    else
        state.isListeningSummon9x = true
        listen9xBtn.Text = "MENDENGARKAN..."
        listen9xBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        if statusLabel then
            statusLabel.Text = "Silakan Summon 9x di dalam game"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        end
    end
end)

-- ============================================================
-- AUTO SELL SECTION
-- ============================================================
createHeader("AUTO SELL", 20)

local autoSellFrame = Instance.new("Frame")
autoSellFrame.Size = UDim2.new(1, -8, 0, 105)
autoSellFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
autoSellFrame.LayoutOrder = 21
autoSellFrame.Parent = container
Instance.new("UICorner", autoSellFrame).CornerRadius = UDim.new(0, 6)

-- Toggle
local sellToggleLabel = Instance.new("TextLabel", autoSellFrame)
sellToggleLabel.Size = UDim2.new(0, 120, 0, 30)
sellToggleLabel.Position = UDim2.new(0, 10, 0, 5)
sellToggleLabel.BackgroundTransparency = 1
sellToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sellToggleLabel.Font = Enum.Font.Gotham
sellToggleLabel.TextSize = 14
sellToggleLabel.Text = "Enable Auto Sell:"
sellToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

local sellToggleBtn = Instance.new("TextButton", autoSellFrame)
sellToggleBtn.Size = UDim2.new(0, 22, 0, 22)
sellToggleBtn.Position = UDim2.new(1, -30, 0, 9)
sellToggleBtn.BackgroundColor3 = state.autoSellEnabled and Color3.fromRGB(0, 160, 60) or Color3.fromRGB(55, 55, 65)
sellToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellToggleBtn.Font = Enum.Font.GothamBold
sellToggleBtn.Text = state.autoSellEnabled and "✓" or ""
Instance.new("UICorner", sellToggleBtn).CornerRadius = UDim.new(0, 4)

sellToggleBtn.MouseButton1Click:Connect(function()
    state.autoSellEnabled = not state.autoSellEnabled
    if state.autoSellEnabled then
        sellToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
        sellToggleBtn.Text = "✓"
    else
        sellToggleBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        sellToggleBtn.Text = ""
    end
    SaveConfig()
end)

-- Interval
local sellIntervalLabel = Instance.new("TextLabel", autoSellFrame)
sellIntervalLabel.Size = UDim2.new(0, 120, 0, 30)
sellIntervalLabel.Position = UDim2.new(0, 10, 0, 35)
sellIntervalLabel.BackgroundTransparency = 1
sellIntervalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sellIntervalLabel.Font = Enum.Font.Gotham
sellIntervalLabel.TextSize = 14
sellIntervalLabel.Text = "Interval (seconds):"
sellIntervalLabel.TextXAlignment = Enum.TextXAlignment.Left

local sellIntervalInput = Instance.new("TextBox", autoSellFrame)
sellIntervalInput.Size = UDim2.new(0, 50, 0, 24)
sellIntervalInput.Position = UDim2.new(1, -60, 0, 38)
sellIntervalInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
sellIntervalInput.TextColor3 = Color3.fromRGB(255, 255, 255)
sellIntervalInput.Font = Enum.Font.Gotham
sellIntervalInput.TextSize = 14
sellIntervalInput.Text = tostring(state.autoSellInterval)
Instance.new("UICorner", sellIntervalInput).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", sellIntervalInput).Color = Color3.fromRGB(100, 100, 120)

sellIntervalInput.FocusLost:Connect(function()
    local val = tonumber(sellIntervalInput.Text)
    if val and val > 0 then
        state.autoSellInterval = val
        SaveConfig()
    else
        sellIntervalInput.Text = tostring(state.autoSellInterval)
    end
end)

-- Listen Sell Button
local listenSellBtn = Instance.new("TextButton", autoSellFrame)
listenSellBtn.Size = UDim2.new(1, -65, 0, 26)
listenSellBtn.Position = UDim2.new(0, 10, 0, 70)
listenSellBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
listenSellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
listenSellBtn.Font = Enum.Font.GothamBold
listenSellBtn.TextSize = 13
listenSellBtn.Text = "🎧 LISTEN SELL ID"
Instance.new("UICorner", listenSellBtn).CornerRadius = UDim.new(0, 4)

local idSellInput = Instance.new("TextBox", autoSellFrame)
idSellInput.Size = UDim2.new(0, 40, 0, 26)
idSellInput.Position = UDim2.new(1, -50, 0, 70)
idSellInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
idSellInput.TextColor3 = Color3.fromRGB(255, 255, 255)
idSellInput.Font = Enum.Font.GothamBold
idSellInput.TextSize = 12
idSellInput.Text = string.gsub(state.sellRemoteId or "", "\226\129\130", "")
Instance.new("UICorner", idSellInput).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", idSellInput).Color = Color3.fromRGB(100, 100, 120)
idSellInput.FocusLost:Connect(function()
    if idSellInput.Text ~= "" then
        state.sellRemoteId = "\226\129\130" .. idSellInput.Text
        SaveConfig()
    else
        idSellInput.Text = string.gsub(state.sellRemoteId or "", "\226\129\130", "")
    end
end)

listenSellBtn.MouseButton1Click:Connect(function()
    if state.isListeningSell then
        state.isListeningSell = false
        listenSellBtn.Text = "🎧 LISTEN SELL ID"
        listenSellBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        if statusLabel then
            statusLabel.Text = "Berhenti mendengarkan ID"
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    else
        state.isListeningSell = true
        listenSellBtn.Text = "MENDENGARKAN... (JUAL UNIT DI GAME)"
        listenSellBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        if statusLabel then
            statusLabel.Text = "Silakan jual unit di dalam game"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        end
    end
end)

-- ============================================================
-- PENDING UI UPDATES (dieksekusi di main thread via Heartbeat)
-- karena modifikasi GUI tidak bisa dilakukan di dalam __namecall hook
-- ============================================================
local pendingUIUpdates = {}

game:GetService("RunService").Heartbeat:Connect(function()
    while #pendingUIUpdates > 0 do
        local upd = table.remove(pendingUIUpdates, 1)
        local t = upd.type
        local id = upd.displayId
        
        if t == "sell" then
            listenSellBtn.Text = "✅ ID: " .. id
            listenSellBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
            idSellInput.Text = id
            if statusLabel then
                statusLabel.Text = "Berhasil ID Sell: " .. id
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
            SaveConfig()
            task.delay(2, function()
                if not state.isListeningSell then
                    listenSellBtn.Text = "🎧 LISTEN SELL ID"
                    listenSellBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
                end
            end)
        elseif t == "trade" then
            if listenTradeBtn then
                listenTradeBtn.Text = "✅ ID: " .. id
                listenTradeBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
            end
            if idTradeInput then
                idTradeInput.Text = id
            end
            if statusLabel then
                statusLabel.Text = "✅ SELESAI! ID Select Trade: " .. id
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
            SaveConfig()
            task.delay(2, function()
                if not state.isListeningSelectTrade and listenTradeBtn then
                    listenTradeBtn.Text = "🎧 LISTEN SELECT TRADE ID"
                    listenTradeBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
                end
            end)
        elseif t == "summon1x" then
            listen1xBtn.Text = "✅ ID: " .. id
            listen1xBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
            id1xInput.Text = id
            if statusLabel then
                statusLabel.Text = "Berhasil ID Summon 1x: " .. id
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
            SaveConfig()
            task.delay(2, function()
                if not state.isListeningSummon1x then
                    listen1xBtn.Text = "🎧 LISTEN 1X"
                    listen1xBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
                end
            end)
        elseif t == "summon9x" then
            listen9xBtn.Text = "✅ ID: " .. id
            listen9xBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
            id9xInput.Text = id
            if statusLabel then
                statusLabel.Text = "Berhasil ID Summon 9x: " .. id
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
            SaveConfig()
            task.delay(2, function()
                if not state.isListeningSummon9x then
                    listen9xBtn.Text = "🎧 LISTEN 9X"
                    listen9xBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
                end
            end)
        end
    end
end)

-- Hook Namecall to capture the ID
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if (tostring(method) == "FireServer" or tostring(method) == "InvokeServer") and tostring(self.Name) == "DataRemote" then
        if type(args[1]) == "table" then
            for _, packet in pairs(args[1]) do
                if type(packet) == "table" and type(packet[1]) == "string" then
                    local possibleId = packet[1]
                    local displayId = string.gsub(possibleId, "\226\129\130", "")
                    local param2 = packet[2]
                    local param3 = packet[3]
                    
                    -- DEBUG: print struktur paket saat listening sell atau trade
                    if state.isListeningSell or state.isListeningSelectTrade then
                        local p2type = type(param2)
                        local p3type = type(param3)
                        local p2val = (p2type == "string") and param2 or ("["..p2type.."]") 
                        local p3val = (p3type == "string") and param3 or ("["..p3type.."]") 
                        print("[LISTEN DEBUG] packet[1]="..tostring(possibleId).." | param2="..p2val.." | param3="..p3val)
                    end
                    
                    -- Cek Listen Sell (param2 = tabel list UID)
                    if state.isListeningSell and type(param2) == "table" then
                        state.sellRemoteId = possibleId
                        state.isListeningSell = false
                        table.insert(pendingUIUpdates, { type = "sell", displayId = displayId })
                    
                    -- Cek Listen Select Trade (param2 = "Troops", param3 = string uid)
                    elseif state.isListeningSelectTrade and param2 == "Troops" and type(param3) == "string" then
                        state.selectTradeRemoteId = possibleId
                        state.isListeningSelectTrade = false
                        table.insert(pendingUIUpdates, { type = "trade", displayId = displayId })
                        
                    -- Cek Listen Summon 1X (tidak ada param2)
                    elseif state.isListeningSummon1x and param2 == nil then
                        state.summon1xRemoteId = possibleId
                        state.isListeningSummon1x = false
                        table.insert(pendingUIUpdates, { type = "summon1x", displayId = displayId })
                        
                    -- Cek Listen Summon 9X (tidak ada param2)
                    elseif state.isListeningSummon9x and param2 == nil then
                        state.summon9xRemoteId = possibleId
                        state.isListeningSummon9x = false
                        table.insert(pendingUIUpdates, { type = "summon9x", displayId = displayId })
                    end
                end
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

-- ============================================================
-- RARITY TOGGLES (For Manual & Auto Sell)
-- ============================================================
createHeader("RARITY TO SELL", 30)

local availableRarities = {}
for rarity, _ in pairs(TroopsSellData) do
    table.insert(availableRarities, rarity)
end
table.sort(availableRarities)

if #availableRarities == 0 then
    availableRarities = {"Basic", "Uncommon", "Rare", "Epic", "Legendary"}
end

local rarityColors = {
    ["Basic"]     = Color3.fromRGB(150, 150, 150),
    ["Uncommon"]  = Color3.fromRGB(80, 180, 80),
    ["Rare"]      = Color3.fromRGB(60, 120, 220),
    ["Epic"]      = Color3.fromRGB(160, 60, 220),
    ["Legendary"] = Color3.fromRGB(220, 180, 40),
    ["Mythic"]    = Color3.fromRGB(220, 50, 50),
    ["Secret"]    = Color3.fromRGB(255, 100, 180),
}

if type(state.selectedRarities) ~= "table" then
    state.selectedRarities = {}
end

for i, rarity in ipairs(availableRarities) do
    if state.selectedRarities[rarity] == nil then
        state.selectedRarities[rarity] = false
    end

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "Toggle_" .. rarity
    toggleFrame.Size = UDim2.new(1, -8, 0, 36)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.LayoutOrder = 30 + i
    toggleFrame.Parent = container

    Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 6)

    local colorBar = Instance.new("Frame", toggleFrame)
    colorBar.Size = UDim2.new(0, 4, 0, 20)
    colorBar.Position = UDim2.new(0, 8, 0.5, -10)
    colorBar.BackgroundColor3 = rarityColors[rarity] or Color3.fromRGB(150, 150, 150)
    colorBar.BorderSizePixel = 0
    Instance.new("UICorner", colorBar).CornerRadius = UDim.new(0, 2)

    local label = Instance.new("TextLabel", toggleFrame)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 20, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(210, 210, 210)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.Text = rarity
    label.TextXAlignment = Enum.TextXAlignment.Left

    local countLabel = Instance.new("TextLabel", toggleFrame)
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(0, 50, 1, 0)
    countLabel.Position = UDim2.new(1, -145, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    countLabel.TextSize = 12
    countLabel.Font = Enum.Font.Gotham
    countLabel.Text = "[ 0 ]"
    countLabel.TextXAlignment = Enum.TextXAlignment.Right
    rarityCountLabels[rarity] = countLabel

    local sellPrice = TroopsSellData[rarity]
    if sellPrice then
        local priceLabel = Instance.new("TextLabel", toggleFrame)
        priceLabel.Size = UDim2.new(0, 50, 1, 0)
        priceLabel.Position = UDim2.new(1, -90, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        priceLabel.TextSize = 12
        priceLabel.Font = Enum.Font.Gotham
        priceLabel.Text = "$" .. tostring(sellPrice)
        priceLabel.TextXAlignment = Enum.TextXAlignment.Right
    end

    local toggleBtn = Instance.new("TextButton", toggleFrame)
    toggleBtn.Size = UDim2.new(0, 22, 0, 22)
    toggleBtn.Position = UDim2.new(1, -30, 0.5, -11)
    toggleBtn.BackgroundColor3 = state.selectedRarities[rarity] and Color3.fromRGB(0, 160, 60) or Color3.fromRGB(55, 55, 65)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 14
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Text = state.selectedRarities[rarity] and "✓" or ""
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)
    local tbStroke = Instance.new("UIStroke", toggleBtn)
    tbStroke.Color = state.selectedRarities[rarity] and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 100)

    toggleBtn.MouseButton1Click:Connect(function()
        state.selectedRarities[rarity] = not state.selectedRarities[rarity]
        if state.selectedRarities[rarity] then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
            toggleBtn.Text = "✓"
            tbStroke.Color = Color3.fromRGB(0, 200, 80)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
            toggleBtn.Text = ""
            tbStroke.Color = Color3.fromRGB(80, 80, 100)
        end
        SaveConfig()
    end)
end

-- ============================================================
-- AUTO SELECT TRADE BUTTON
-- ============================================================
local tradeBtn = Instance.new("TextButton", container)
tradeBtn.Size = UDim2.new(1, -8, 0, 42)
tradeBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
tradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tradeBtn.TextSize = 16
tradeBtn.Font = Enum.Font.GothamBold
tradeBtn.Text = "🔄 AUTO SELECT TRADE"
tradeBtn.LayoutOrder = 98
Instance.new("UICorner", tradeBtn).CornerRadius = UDim.new(0, 8)

-- Listen Select Trade Button
local tradeListenRow = Instance.new("Frame", container)
tradeListenRow.Size = UDim2.new(1, -8, 0, 32)
tradeListenRow.BackgroundTransparency = 1
tradeListenRow.LayoutOrder = 99

listenTradeBtn = Instance.new("TextButton", tradeListenRow)
listenTradeBtn.Size = UDim2.new(1, -50, 1, 0)
listenTradeBtn.Position = UDim2.new(0, 0, 0, 0)
listenTradeBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
listenTradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
listenTradeBtn.TextSize = 13
listenTradeBtn.Font = Enum.Font.GothamBold
listenTradeBtn.Text = "🎧 LISTEN SELECT TRADE ID"
Instance.new("UICorner", listenTradeBtn).CornerRadius = UDim.new(0, 8)

idTradeInput = Instance.new("TextBox", tradeListenRow)
idTradeInput.Size = UDim2.new(0, 40, 1, 0)
idTradeInput.Position = UDim2.new(1, -40, 0, 0)
idTradeInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
idTradeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
idTradeInput.Font = Enum.Font.GothamBold
idTradeInput.TextSize = 12
idTradeInput.Text = string.gsub(state.selectTradeRemoteId or "", "\226\129\130", "")
Instance.new("UICorner", idTradeInput).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", idTradeInput).Color = Color3.fromRGB(100, 100, 120)
idTradeInput.FocusLost:Connect(function()
    if idTradeInput.Text ~= "" then
        state.selectTradeRemoteId = "\226\129\130" .. idTradeInput.Text
        SaveConfig()
    else
        idTradeInput.Text = string.gsub(state.selectTradeRemoteId or "", "\226\129\130", "")
    end
end)

listenTradeBtn.MouseButton1Click:Connect(function()
    if state.isListeningSelectTrade then
        state.isListeningSelectTrade = false
        listenTradeBtn.Text = "🎧 LISTEN SELECT TRADE ID"
        listenTradeBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        if statusLabel then
            statusLabel.Text = "Berhenti mendengarkan Select Trade"
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    else
        state.isListeningSelectTrade = true
        listenTradeBtn.Text = "MENDENGARKAN... (KLIK UNIT DI TRADE)"
        listenTradeBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        if statusLabel then
            statusLabel.Text = "Silakan klik unit di menu trade game"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        end
    end
end)

local function isTroopEquippedLocal(equippedTroopIds, uid)
    if not equippedTroopIds then return false end
    for _, equippedUid in pairs(equippedTroopIds) do
        if equippedUid == uid then
            return true
        end
    end
    return false
end

tradeBtn.MouseButton1Click:Connect(function()
    local playerData = PlayerDataReplica:GetData()
    local inventory = playerData.Inventory
    local equippedTroopIds = playerData.EquippedTroopIds
    
    if type(inventory) ~= "table" or type(inventory.Troops) ~= "table" then
        statusLabel.Text = "⚠ Format inventory tidak valid"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    local addedCount = 0
    tradeBtn.Text = "Memilih Unit..."
    
    local success, err = pcall(function()
        for itemId, uidTable in pairs(inventory.Troops) do
            local troopData = TroopDatas[itemId]
            if troopData then
                local rarity = troopData.Rarity or "Basic"
                if state.selectedRarities[rarity] then
                    for uid, instanceData in pairs(uidTable) do
                        if instanceData.ReallyLocked ~= true
                            and not isTroopEquippedLocal(equippedTroopIds, uid)
                            and not instanceData.SignedBy
                        then
                            local args = {
                                {
                                    {
                                        state.selectTradeRemoteId,
                                        "Troops",
                                        uid
                                    }
                                }
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("NetworkingContainer"):WaitForChild("DataRemote"):FireServer(unpack(args))
                            addedCount = addedCount + 1
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end)
    
    if not success then
        statusLabel.Text = "⚠ Error: " .. tostring(err)
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        statusLabel.Text = string.format("✓ Berhasil memilih %d unit", addedCount)
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
    
    tradeBtn.Text = "🔄 AUTO SELECT TRADE"
end)

-- ============================================================
-- STATUS & MANUAL SELL BUTTON
-- ============================================================
local separator = Instance.new("Frame", container)
separator.Size = UDim2.new(1, -20, 0, 1)
separator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
separator.BorderSizePixel = 0
separator.LayoutOrder = 100

-- statusLabel sudah di-forward-declare di atas, sekarang di-assign
statusLabel = Instance.new("TextLabel", container)
statusLabel.Size = UDim2.new(1, -8, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Pilih rarity lalu tekan Sell"
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.LayoutOrder = 101

local sellBtn = Instance.new("TextButton", container)
sellBtn.Size = UDim2.new(1, -8, 0, 42)
sellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellBtn.TextSize = 16
sellBtn.Font = Enum.Font.GothamBold
sellBtn.Text = "🗑 SELL SELECTED UNITS"
sellBtn.LayoutOrder = 102
Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 8)

-- ============================================================
-- CONFIRMATION UI (For Manual Sell)
-- ============================================================
local confirmFrame = Instance.new("Frame", mainFrame)
confirmFrame.Size = UDim2.new(1, 0, 1, 0)
confirmFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
confirmFrame.BackgroundTransparency = 0.5
confirmFrame.Visible = false
confirmFrame.ZIndex = 10

local confirmBox = Instance.new("Frame", confirmFrame)
confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
confirmBox.Size = UDim2.new(0.9, 0, 0, 150)
confirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
confirmBox.BorderSizePixel = 0
confirmBox.ZIndex = 11
Instance.new("UICorner", confirmBox).CornerRadius = UDim.new(0, 8)

local confirmSizeConstraint = Instance.new("UISizeConstraint")
confirmSizeConstraint.MaxSize = Vector2.new(260, 150)
confirmSizeConstraint.Parent = confirmBox

local confirmTitle = Instance.new("TextLabel", confirmBox)
confirmTitle.Size = UDim2.new(1, 0, 0, 30)
confirmTitle.Position = UDim2.new(0, 0, 0, 10)
confirmTitle.BackgroundTransparency = 1
confirmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmTitle.TextSize = 18
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.Text = "Confirm Sell"
confirmTitle.ZIndex = 12

local confirmText = Instance.new("TextLabel", confirmBox)
confirmText.Size = UDim2.new(1, -20, 0, 40)
confirmText.Position = UDim2.new(0, 10, 0, 40)
confirmText.BackgroundTransparency = 1
confirmText.TextColor3 = Color3.fromRGB(200, 200, 200)
confirmText.TextSize = 14
confirmText.Font = Enum.Font.Gotham
confirmText.TextWrapped = true
confirmText.Text = "Are you sure?"
confirmText.ZIndex = 12

local confirmYes = Instance.new("TextButton", confirmBox)
confirmYes.Size = UDim2.new(0, 100, 0, 35)
confirmYes.Position = UDim2.new(0, 20, 1, -45)
confirmYes.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
confirmYes.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmYes.TextSize = 14
confirmYes.Font = Enum.Font.GothamBold
confirmYes.Text = "Yes"
confirmYes.ZIndex = 12
Instance.new("UICorner", confirmYes).CornerRadius = UDim.new(0, 6)

local confirmNo = Instance.new("TextButton", confirmBox)
confirmNo.Size = UDim2.new(0, 100, 0, 35)
confirmNo.Position = UDim2.new(1, -120, 1, -45)
confirmNo.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
confirmNo.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmNo.TextSize = 14
confirmNo.Font = Enum.Font.GothamBold
confirmNo.Text = "No"
confirmNo.ZIndex = 12
Instance.new("UICorner", confirmNo).CornerRadius = UDim.new(0, 6)

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function splitTable(tbl, chunkSize)
    local chunks = {}
    for i = 1, #tbl, chunkSize do
        local chunk = {}
        for j = i, math.min(i + chunkSize - 1, #tbl) do
            table.insert(chunk, tbl[j])
        end
        table.insert(chunks, chunk)
    end
    return chunks
end

local function isEquipped(equippedTroopIds, uid)
    if not equippedTroopIds then return false end
    for _, equippedUid in pairs(equippedTroopIds) do
        if equippedUid == uid then
            return true
        end
    end
    return false
end

local function collectUnitsToSell()
    local playerData = PlayerDataReplica:GetData()
    local inventory = playerData.Inventory
    local equippedTroopIds = playerData.EquippedTroopIds

    local unitsToSell = {}
    local totalValue = 0

    if type(inventory) ~= "table" or type(inventory.Troops) ~= "table" then
        return unitsToSell, totalValue, "Format inventory tidak valid"
    end

    local PROTECT_SERIALS = true

    for itemId, uidTable in pairs(inventory.Troops) do
        local troopData = TroopDatas[itemId]
        if troopData then
            local rarity = troopData.Rarity or "Basic"

            if state.selectedRarities[rarity] and TroopsSellData[rarity] then
                for uid, instanceData in pairs(uidTable) do
                    local hasSerial = PROTECT_SERIALS and instanceData.Serial and tonumber(instanceData.Serial) ~= nil
                    
                    if instanceData.ReallyLocked ~= true
                        and not isEquipped(equippedTroopIds, uid)
                        and not instanceData.SignedBy
                        and not hasSerial
                    then
                        table.insert(unitsToSell, uid)
                        totalValue = totalValue + (TroopsSellData[rarity] or 0)
                    end
                end
            end
        end
    end

    return unitsToSell, totalValue, nil
end

local function performSell(unitsToSell)
    local chunks = splitTable(unitsToSell, 100)
    for _, chunk in ipairs(chunks) do
        local success, err = pcall(function()
            local args = { { { state.sellRemoteId, chunk } } }
            game:GetService("ReplicatedStorage"):WaitForChild("NetworkingContainer"):WaitForChild("DataRemote"):FireServer(unpack(args))
        end)
        if not success then
            warn("[AutoSell]", err)
        end
        task.wait(0.1)
    end
end

-- ============================================================
-- BACKGROUND LOOPS
-- ============================================================

-- UI STATS UPDATER
task.spawn(function()
    while task.wait(1) do
        local playerData = PlayerDataReplica:GetData()
        if playerData then
            -- Update Coins
            local currentCoins = (playerData.Currencies and playerData.Currencies.Coins) and tonumber(playerData.Currencies.Coins) or 0
            if coinsLabel then coinsLabel.Text = "💰 Coins: " .. tostring(currentCoins) end
            
            -- Update Unit Counts
            local inventory = playerData.Inventory
            if type(inventory) == "table" and type(inventory.Troops) == "table" then
                local rarityCounts = {}
                for rarity, _ in pairs(TroopsSellData) do rarityCounts[rarity] = 0 end
                
                for itemId, uidTable in pairs(inventory.Troops) do
                    local troopData = TroopDatas[itemId]
                    if troopData then
                        local rarity = troopData.Rarity or "Basic"
                        if rarityCounts[rarity] ~= nil then
                            for uid, _ in pairs(uidTable) do
                                rarityCounts[rarity] = rarityCounts[rarity] + 1
                            end
                        end
                    end
                end
                
                for rarity, count in pairs(rarityCounts) do
                    if rarityCountLabels[rarity] then
                        rarityCountLabels[rarity].Text = "[ " .. tostring(count) .. " ]"
                    end
                end
            end
        end
    end
end)

-- AUTO SUMMON
task.spawn(function()
    while true do
        task.wait(math.max(state.autoSummonInterval, 1))
        
        -- Hentikan jika ini adalah instance lama (sudah di-inject ulang)
        if _G._AutoToolsToken ~= INSTANCE_TOKEN then break end
        
        if not state.autoSummonEnabled then
            continue
        end
        
        local cost = (state.autoSummonType == "Summon 9x") and 900 or 100
        local playerData = PlayerDataReplica:GetData()
        local currentCoins = (playerData and playerData.Currencies and playerData.Currencies.Coins) and tonumber(playerData.Currencies.Coins) or 0
        
        if currentCoins >= cost then
            local success, err = pcall(function()
                local charArg = (state.autoSummonType == "Summon 9x") and state.summon9xRemoteId or state.summon1xRemoteId
                local args = { { { charArg } } }
                game:GetService("ReplicatedStorage"):WaitForChild("NetworkingContainer"):WaitForChild("DataRemote"):FireServer(unpack(args))
            end)
            
            if success then
                statusLabel.Text = string.format("[Summon] %s selesai (Koin: %d)", state.autoSummonType, currentCoins)
                statusLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
            else
                warn("[AutoSummon] Error:", err)
                statusLabel.Text = "[Summon] Error - cek output"
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        else
            statusLabel.Text = string.format("[Summon] Koin tidak cukup! (%d/%d)", currentCoins, cost)
            statusLabel.TextColor3 = Color3.fromRGB(255, 160, 60)
        end
    end
end)

-- AUTO SELL
task.spawn(function()
    while true do
        task.wait(math.max(state.autoSellInterval, 1))
        
        -- Hentikan jika ini adalah instance lama (sudah di-inject ulang)
        if _G._AutoToolsToken ~= INSTANCE_TOKEN then break end
        
        if not state.autoSellEnabled then
            continue
        end
        
        local unitsToSell, totalValue, errorMsg = collectUnitsToSell()
        if errorMsg then
            statusLabel.Text = "[Sell] " .. errorMsg
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        elseif #unitsToSell > 0 then
            performSell(unitsToSell)
            statusLabel.Text = string.format("[Sell] %d unit terjual ($%s)", #unitsToSell, tostring(totalValue))
            statusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
        end
    end
end)

-- ============================================================
-- MANUAL SELL EVENT
-- ============================================================
local isSelling = false

local function finishSelling()
    sellBtn.Text = "🗑 SELL SELECTED UNITS"
    sellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    isSelling = false
end

sellBtn.MouseButton1Click:Connect(function()
    if isSelling then return end
    isSelling = true

    local unitsToSell, totalValue, errorMsg = collectUnitsToSell()

    if errorMsg then
        statusLabel.Text = "⚠ " .. errorMsg
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        finishSelling()
        return
    end

    if #unitsToSell == 0 then
        statusLabel.Text = "Tidak ada unit yang memenuhi syarat"
        statusLabel.TextColor3 = Color3.fromRGB(255, 160, 60)
        sellBtn.Text = "TIDAK ADA UNIT!"
        sellBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 20)
        task.wait(1.5)
        statusLabel.Text = "Pilih rarity lalu tekan Sell"
        statusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
        finishSelling()
        return
    end

    confirmText.Text = string.format("Sell %d units for %d coins?", #unitsToSell, totalValue)
    confirmFrame.Visible = true
    
    local yesConn, noConn
    
    local function cleanupConfirm()
        confirmFrame.Visible = false
        if yesConn then yesConn:Disconnect() end
        if noConn then noConn:Disconnect() end
    end
    
    yesConn = confirmYes.MouseButton1Click:Connect(function()
        cleanupConfirm()
        
        statusLabel.Text = string.format("Mengirim %d unit, total $%s", #unitsToSell, tostring(totalValue))
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    
        sellBtn.Text = string.format("Menjual %d unit...", #unitsToSell)
        sellBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
    
        performSell(unitsToSell)
        task.wait(1.5)
    
        statusLabel.Text = string.format("✓ Request terkirim (%d unit)", #unitsToSell)
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    
        finishSelling()
    end)
    
    noConn = confirmNo.MouseButton1Click:Connect(function()
        cleanupConfirm()
        statusLabel.Text = "Pilih rarity lalu tekan Sell"
        statusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
        finishSelling()
    end)
end)

print("[AutoTools] GUI & Config loaded successfully!")
