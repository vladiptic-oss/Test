-- Restore Peace: полный чит-пакет
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Функция для зелёной земли (имитация клика по земле)
local function paintGreen(part)
    if part and part.Name == "Ground" or part:IsA("BasePart") then
        part.BrickColor = BrickColor.new("Bright green")
        part.Material = Enum.Material.Grass
    end
end

-- Красим всю землю при запуске
for _, obj in ipairs(workspace:GetDescendants()) do
    paintGreen(obj)
end

-- Новые части тоже будут зелёными
workspace.DescendantAdded:Connect(function(obj)
    wait(0.5)
    paintGreen(obj)
end)

-- Спидхак (ускорение персонажа)
local function speedHack()
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 32 -- стандарт 16, так что х2
    end
end

-- Полёт (зажимаем пробел)
local function fly()
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.P = 9e4
        bodyGyro.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
        bodyGyro.Parent = player.Character.HumanoidRootPart

        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0.5, 0)
        bodyVelocity.MaxForce = Vector3.new(4e5, 4e5, 4e5)
        bodyVelocity.Parent = player.Character.HumanoidRootPart

        game:GetService("UserInputService").JumpRequest:Connect(function()
            bodyVelocity.Velocity = bodyVelocity.Velocity + Vector3.new(0, 50, 0)
        end)
    end
end

-- Защита от бана: рандомизация действий
local function antiBan()
    -- случайная задержка между окрашиваниями
    wait(math.random(0.1, 0.5))
    -- иногда "пропускаем" объекты, чтобы не палиться
    if math.random(1, 10) > 2 then
        return true
    end
    return false
end

-- Основной цикл
RunService.Heartbeat:Connect(function()
    if antiBan() then
        speedHack()
        -- Перекрашиваем всё вокруг каждые 5 секунд
        if tick() % 5 == 0 then
            for _, obj in ipairs(workspace:GetDescendants()) do
                paintGreen(obj)
            end
        end
    end
end)

-- Включаем полёт сразу
fly()
