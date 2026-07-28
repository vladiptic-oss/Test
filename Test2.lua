-- Restore Peace: меню с ручным управлением, серверный счётчик
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Отключение всех функций по умолчанию
local flyEnabled = false
local speedEnabled = false
local paintActive = false
local bodyGyro, bodyVelocity

-- Глобальный счётчик
local scoreValue = workspace:FindFirstChild("GlobalGrassScore")
if not scoreValue then
    scoreValue = Instance.new("NumberValue")
    scoreValue.Name = "GlobalGrassScore"
    scoreValue.Value = 0
    scoreValue.Parent = workspace
end

-- GUI меню
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 260)
frame.Position = UDim2.new(0.8, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Restore Peace"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = frame

-- Кнопка запуска окрашивания
local startPaintButton = Instance.new("TextButton")
startPaintButton.Size = UDim2.new(0.9, 0, 0, 30)
startPaintButton.Position = UDim2.new(0.05, 0, 0.1, 0)
startPaintButton.Text = "Start Painting"
startPaintButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startPaintButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
startPaintButton.Parent = frame

startPaintButton.MouseButton1Click:Connect(function()
    if not paintActive then
        paintActive = true
        startPaintButton.Text = "Painting..."
        startPaintButton.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
    end
end)

-- Индикатор прогресса
local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(0.9, 0, 0, 30)
progressLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
progressLabel.Text = "Progress: 0/100"
progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
progressLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
progressLabel.Parent = frame

-- Кнопка спидхака
local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0.9, 0, 0, 30)
speedButton.Position = UDim2.new(0.05, 0, 0.4, 0)
speedButton.Text = "Speed: OFF"
speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
speedButton.Parent = frame

speedButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    speedButton.Text = "Speed: " .. (speedEnabled and "ON" or "OFF")
    speedButton.BackgroundColor3 = speedEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Кнопка полёта
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0.9, 0, 0, 30)
flyButton.Position = UDim2.new(0.05, 0, 0.55, 0)
flyButton.Text = "Fly: OFF"
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
flyButton.Parent = frame

flyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    flyButton.BackgroundColor3 = flyEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    if flyEnabled then
        enableFly()
    else
        disableFly()
    end
end)

-- Сброс счётчика
local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0.9, 0, 0, 30)
resetButton.Position = UDim2.new(0.05, 0, 0.7, 0)
resetButton.Text = "Reset Counter"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
resetButton.Parent = frame

resetButton.MouseButton1Click:Connect(function()
    scoreValue.Value = 0
    progressLabel.Text = "Progress: 0/100"
    paintActive = false
    startPaintButton.Text = "Start Painting"
    startPaintButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
end)

-- Функция определения травы
local function isGrass(part)
    return part:IsA("BasePart") and (
        part.Material == Enum.Material.Grass or
        part.BrickColor == BrickColor.new("Earth green") or
        part.BrickColor == BrickColor.new("Dark green") or
        part.Name:lower():find("grass")
    )
end

-- Функция окрашивания
local function paintGrass()
    if not paintActive or scoreValue.Value >= 100 then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isGrass(obj) and obj.BrickColor ~= BrickColor.new("Bright green") then
            obj.BrickColor = BrickColor.new("Bright green")
            obj.Material = Enum.Material.Grass
            scoreValue.Value += 1
            progressLabel.Text = "Progress: " .. scoreValue.Value .. "/100"
            break
        end
    end
    if scoreValue.Value >= 100 then
        for _, plr in ipairs(game.Players:GetPlayers()) do
            local msg = Instance.new("Message")
            msg.Text = "Вся трава окрашена! Награда выдана!"
            msg.Parent = plr:WaitForChild("PlayerGui")
            wait(3)
            msg:Destroy()
        end
        paintActive = false
        startPaintButton.Text = "Start Painting"
        startPaintButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    end
end

-- Полёт с управлением WASD
function enableFly()
    local rootPart = player.Character:WaitForChild("HumanoidRootPart")
    player.Character:WaitForChild("Humanoid").PlatformStand = true

    bodyGyro = Instance.new("BodyGyro", rootPart)
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

    bodyVelocity = Instance.new("BodyVelocity", rootPart)
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)

    local moveVector = Vector3.zero

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not flyEnabled or gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.W then moveVector += rootPart.CFrame.LookVector
        elseif input.KeyCode == Enum.KeyCode.S then moveVector -= rootPart.CFrame.LookVector
        elseif input.KeyCode == Enum.KeyCode.A then moveVector -= rootPart.CFrame.RightVector
        elseif input.KeyCode == Enum.KeyCode.D then moveVector += rootPart.CFrame.RightVector
        elseif input.KeyCode == Enum.KeyCode.Space then moveVector += Vector3.new(0, 1, 0)
        elseif input.KeyCode == Enum.KeyCode.LeftShift then moveVector -= Vector3.new(0, 1, 0) end
        bodyVelocity.Velocity = moveVector * 50
    end)

    UserInputService.InputEnded:Connect(function()
        if not flyEnabled then return end
        moveVector = Vector3.zero
        bodyVelocity.Velocity = Vector3.zero
    end)
end

function disableFly()
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
    player.Character.Humanoid.PlatformStand = false
end

-- Основной цикл
RunService.Heartbeat:Connect(function()
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speedEnabled and 32 or 16
    end
    paintGrass()
    wait(0.5)
end)
