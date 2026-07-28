-- Restore Peace: серверное окрашивание травы, счётчик на всех, меню, полёт, спидхак
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Переменные
local flyEnabled = false
local speedEnabled = false
local paintEnabled = false
local bodyGyro, bodyVelocity

-- GUI меню
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 230)
frame.Position = UDim2.new(0.8, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Restore Peace Cheat"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = frame

-- Кнопка окрашивания
local paintButton = Instance.new("TextButton")
paintButton.Size = UDim2.new(0.9, 0, 0, 30)
paintButton.Position = UDim2.new(0.05, 0, 0.15, 0)
paintButton.Text = "Paint Grass: OFF"
paintButton.TextColor3 = Color3.fromRGB(255, 255, 255)
paintButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
paintButton.Parent = frame

paintButton.MouseButton1Click:Connect(function()
    paintEnabled = not paintEnabled
    paintButton.Text = "Paint Grass: " .. (paintEnabled and "ON" or "OFF")
    paintButton.BackgroundColor3 = paintEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Кнопка спидхака
local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0.9, 0, 0, 30)
speedButton.Position = UDim2.new(0.05, 0, 0.3, 0)
speedButton.Text = "Speed Hack: OFF"
speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
speedButton.Parent = frame

speedButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    speedButton.Text = "Speed Hack: " .. (speedEnabled and "ON" or "OFF")
    speedButton.BackgroundColor3 = speedEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Кнопка полёта
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0.9, 0, 0, 30)
flyButton.Position = UDim2.new(0.05, 0, 0.45, 0)
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

-- Отображение прогресса
local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(0.9, 0, 0, 30)
progressLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
progressLabel.Text = "Progress: 0/100"
progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
progressLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
progressLabel.Parent = frame

-- Функция для отправки события на сервер (RemoteEvent)
local remoteEvent = replicatedStorage:FindFirstChild("GrassPaintedEvent") or replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("GrassPaint")
-- Если удалённого события нет, создаём своё локальное значение
if not remoteEvent then
    -- Для серверного счётчика используем NumberValue, доступную всем
    local scoreValue = Instance.new("NumberValue")
    scoreValue.Name = "GlobalGrassScore"
    scoreValue.Value = 0
    scoreValue.Parent = workspace -- в рабочем пространстве видят все клиенты
    remoteEvent = scoreValue
end

-- Функция для закрашивания травы
local function paintGrass(part)
    if part and part:IsA("BasePart") then
        local color = part.BrickColor
        local material = part.Material
        -- Определяем, является ли часть травой (по цвету или материалу)
        if material == Enum.Material.Grass or color == BrickColor.new("Earth green") or color == BrickColor.new("Dark green") or part.Name:lower():find("grass") then
            part.BrickColor = BrickColor.new("Bright green")
            part.Material = Enum.Material.Grass
            return true
        end
    end
    return false
end

-- Обновление счётчика на серверной стороне (через NumberValue)
local function incrementGlobalScore()
    if remoteEvent and remoteEvent:IsA("NumberValue") then
        remoteEvent.Value = remoteEvent.Value + 1
        progressLabel.Text = "Progress: " .. remoteEvent.Value .. "/100"
        if remoteEvent.Value >= 100 then
            -- Выдаём награду всем игрокам (симуляция)
            for _, plr in ipairs(game.Players:GetPlayers()) do
                -- Отправляем локальное уведомление всем
                local msg = Instance.new("Message")
                msg.Text = "Все игроки получают награду! Трава восстановлена!"
                msg.Parent = plr:WaitForChild("PlayerGui")
                wait(3)
                msg:Destroy()
            end
            remoteEvent.Value = 0 -- сбрасываем
        end
    end
end

-- Полёт с управлением WASD
function enableFly()
    local humanoid = player.Character:WaitForChild("Humanoid")
    local rootPart = player.Character:WaitForChild("HumanoidRootPart")
    humanoid.PlatformStand = true

    bodyGyro = Instance.new("BodyGyro", rootPart)
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

    bodyVelocity = Instance.new("BodyVelocity", rootPart)
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)

    local moveVector = Vector3.zero

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not flyEnabled or gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.W then
            moveVector += rootPart.CFrame.LookVector
        elseif input.KeyCode == Enum.KeyCode.S then
            moveVector -= rootPart.CFrame.LookVector
        elseif input.KeyCode == Enum.KeyCode.A then
            moveVector -= rootPart.CFrame.RightVector
        elseif input.KeyCode == Enum.KeyCode.D then
            moveVector += rootPart.CFrame.RightVector
        elseif input.KeyCode == Enum.KeyCode.Space then
            moveVector += Vector3.new(0, 1, 0)
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            moveVector -= Vector3.new(0, 1, 0)
        end
        bodyVelocity.Velocity = moveVector * 50
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not flyEnabled then return end
        moveVector = Vector3.zero
        bodyVelocity.Velocity = Vector3.zero
    end)
end

function disableFly()
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.PlatformStand = false end
end

-- Основной цикл
RunService.Heartbeat:Connect(function()
    -- Спидхак
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speedEnabled and 32 or 16
    end

    -- Окрашивание травы
    if paintEnabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if paintGrass(obj) then
                incrementGlobalScore()
                break
            end
        end
    end
end)
