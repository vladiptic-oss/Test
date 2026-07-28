-- Автоматический сборщик травы с самообучением
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local flyEnabled, speedEnabled, paintActive = false, false, false
local bodyGyro, bodyVelocity
local paintedBlocks = {}
local grassColors = {} -- таблица обнаруженных цветов травы

-- Глобальный счётчик
local scoreValue = workspace:FindFirstChild("GlobalGrassScore")
if not scoreValue then
    scoreValue = Instance.new("NumberValue")
    scoreValue.Name = "GlobalGrassScore"
    scoreValue.Value = 0
    scoreValue.Parent = workspace
end

-- Сканирование карты и сбор образцов травы
local function scanForGrass()
    grassColors = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.BrickColor then
            local c = obj.BrickColor.Color
            local r, g, b = c.r, c.g, c.b
            -- Зелёные оттенки: много зелёного, мало красного и синего
            if g > 0.3 and r < 0.5 and b < 0.5 and obj.Transparency < 0.9 then
                table.insert(grassColors, c)
            end
        end
    end
end

-- Меню
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 260)
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true

local drag, startPos, dStart
frame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        drag, startPos, dStart = true, i.Position, frame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then drag = false end
        end)
    end
end)
frame.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.Touch then
        local delta = i.Position - startPos
        frame.Position = UDim2.new(dStart.X.Scale, dStart.X.Offset + delta.X, dStart.Y.Scale, dStart.Y.Offset + delta.Y)
    end
end)

-- Заголовок
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "RESTORE PEACE"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(50,50,50)

-- Scan & Start
local scanBtn = Instance.new("TextButton", frame)
scanBtn.Size, scanBtn.Position = UDim2.new(0.9, 0, 0, 30), UDim2.new(0.05, 0, 0.12, 0)
scanBtn.Text = "Scan & Paint"
scanBtn.TextColor3 = Color3.new(1,1,1)
scanBtn.BackgroundColor3 = Color3.fromRGB(50,150,200)
scanBtn.MouseButton1Click:Connect(function()
    if not paintActive then
        scanForGrass() -- сканируем перед стартом
        paintActive = true
        scanBtn.Text = "Painting..."
        scanBtn.BackgroundColor3 = Color3.fromRGB(200,200,50)
    end
end)

-- Прогресс
local progress = Instance.new("TextLabel", frame)
progress.Size, progress.Position = UDim2.new(0.9, 0, 0, 30), UDim2.new(0.05, 0, 0.27, 0)
progress.Text = "Ready: 0/100"
progress.TextColor3 = Color3.new(1,1,1)
progress.BackgroundColor3 = Color3.fromRGB(50,50,50)

-- Speed
local speedBtn = Instance.new("TextButton", frame)
speedBtn.Size, speedBtn.Position = UDim2.new(0.9, 0, 0, 30), UDim2.new(0.05, 0, 0.42, 0)
speedBtn.Text = "Speed: OFF"
speedBtn.TextColor3 = Color3.new(1,1,1)
speedBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
speedBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    speedBtn.Text = "Speed: "..(speedEnabled and "ON" or "OFF")
    speedBtn.BackgroundColor3 = speedEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

-- Fly
local flyBtn = Instance.new("TextButton", frame)
flyBtn.Size, flyBtn.Position = UDim2.new(0.9, 0, 0, 30), UDim2.new(0.05, 0, 0.57, 0)
flyBtn.Text = "Fly: OFF"
flyBtn.TextColor3 = Color3.new(1,1,1)
flyBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = "Fly: "..(flyEnabled and "ON" or "OFF")
    flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
    if flyEnabled then enableFly() else disableFly() end
end)

-- Reset
local resetBtn = Instance.new("TextButton", frame)
resetBtn.Size, resetBtn.Position = UDim2.new(0.9, 0, 0, 30), UDim2.new(0.05, 0, 0.72, 0)
resetBtn.Text = "Reset"
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.BackgroundColor3 = Color3.fromRGB(150,100,50)
resetBtn.MouseButton1Click:Connect(function()
    scoreValue.Value = 0
    paintedBlocks = {}
    grassColors = {}
    progress.Text = "Ready: 0/100"
    paintActive = false
    scanBtn.Text = "Scan & Paint"
    scanBtn.BackgroundColor3 = Color3.fromRGB(50,150,200)
end)

-- Проверка, является ли блок травой (по образцам)
local function isGrass(part)
    if not part:IsA("BasePart") or paintedBlocks[part] then return false end
    if part.Transparency > 0.8 then return false end
    local c = part.BrickColor.Color
    for _, sample in ipairs(grassColors) do
        local diff = math.abs(c.r - sample.r) + math.abs(c.g - sample.g) + math.abs(c.b - sample.b)
        if diff < 0.3 then return true end
    end
    return false
end

-- Окрашивание
local function paint()
    if not paintActive or scoreValue.Value >= 100 then return end
    for _, v in ipairs(workspace:GetDescendants()) do
        if isGrass(v) then
            v.BrickColor = BrickColor.new("Bright green")
            paintedBlocks[v] = true
            scoreValue.Value += 1
            progress.Text = "Painting: "..scoreValue.Value.."/100"
            if scoreValue.Value >= 100 then
                progress.Text = "Done: 100/100"
                paintActive = false
                scanBtn.Text = "Scan & Paint"
                scanBtn.BackgroundColor3 = Color3.fromRGB(50,150,200)
                break
            end
        end
    end
end

-- Полёт
function enableFly()
    local char = player.Character
    local root, hum = char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Humanoid")
    hum.PlatformStand = true

    bodyGyro = Instance.new("BodyGyro", root)
    bodyGyro.MaxTorque = Vector3.new(9e4,9e4,9e4)
    bodyVelocity = Instance.new("BodyVelocity", root)
    bodyVelocity.MaxForce = Vector3.new(4e5,4e5,4e5)

    local cam = workspace.CurrentCamera
    local keys = {}
    local rotX, rotY = 0, 0

    UserInputService.TouchPan:Connect(function(info, gameProcessed)
        if not flyEnabled or gameProcessed then return end
        rotY = rotY - info.Delta.X * 0.5
        rotX = math.clamp(rotX - info.Delta.Y * 0.5, -80, 80)
        bodyGyro.CFrame = CFrame.new(root.Position) * CFrame.fromEulerAnglesYXZ(math.rad(rotY), math.rad(rotX), 0)
    end)

    UserInputService.InputBegan:Connect(function(i, g)
        if not flyEnabled or g then return end
        keys[i.KeyCode] = true
    end)
    UserInputService.InputEnded:Connect(function(i)
        keys[i.KeyCode] = false
    end)

    RunService:BindToRenderStep("FlyUpdate", 200, function()
        if not flyEnabled then return end
        local dir = cam.CFrame.LookVector * (keys[Enum.KeyCode.W] and 1 or keys[Enum.KeyCode.S] and -1 or 0)
            + cam.CFrame.RightVector * (keys[Enum.KeyCode.D] and 1 or keys[Enum.KeyCode.A] and -1 or 0)
        dir = dir + Vector3.new(0, (keys[Enum.KeyCode.Space] and 1 or 0) + (keys[Enum.KeyCode.LeftShift] and -1 or 0), 0)
        bodyVelocity.Velocity = dir * 50
    end)
end

function disableFly()
    RunService:UnbindFromRenderStep("FlyUpdate")
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
    player.Character.Humanoid.PlatformStand = false
end

-- Главный цикл
RunService.Heartbeat:Connect(function()
    local h = player.Character and player.Character:FindFirstChild("Humanoid")
    if h then h.WalkSpeed = speedEnabled and 32 or 16 end
    paint()
    wait(0.05) -- быстро
end)
