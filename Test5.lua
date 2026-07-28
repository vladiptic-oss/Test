--[[
    Restore Peace - Авто-озеленение земли с Fly для телефона.
    Ищет тёмную землю, находит образец зелени и красит только землю.
    Fly: зажми свайп для поворота камеры, двойной тап для полёта вперёд.
--]]

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local cam = workspace.CurrentCamera

-- ===== ГЛОБАЛЬНЫЙ СЧЁТЧИК =====
local scoreValue = workspace:FindFirstChild("GlobalGrassScore")
if not scoreValue then
    scoreValue = Instance.new("NumberValue")
    scoreValue.Name = "GlobalGrassScore"
    scoreValue.Value = 0
    scoreValue.Parent = workspace
end

-- ===== ПЕРЕМЕННЫЕ СОСТОЯНИЯ =====
local paintEnabled = false
local speedEnabled = false
local flyEnabled = false
local paintedBlocks = {}        -- запоминаем уже покрашенные блоки
local grassColorSamples = {}   -- образцы цвета травы
local bodyGyro, bodyVelocity

-- ===== ФУНКЦИЯ ОПРЕДЕЛЕНИЯ ЗЕМЛИ И ТРАВЫ =====
local function isDarkGround(part)
    if not part:IsA("BasePart") then return false end
    if part.Transparency > 0.7 then return false end
    local c = part.BrickColor.Color
    local r, g, b = c.r, c.g, c.b
    -- Тёмная земля: коричневая или серая (R и G близки, но не ярко-зелёные)
    return (r > 0.2 and g > 0.15 and b < 0.3) or (math.abs(r - g) < 0.15 and r < 0.5 and b < 0.3)
end

local function isGreenSample(part)
    if not part:IsA("BasePart") then return false end
    if part.Transparency > 0.7 then return false end
    local c = part.BrickColor.Color
    local r, g, b = c.r, c.g, c.b
    -- Ярко-зелёный: много зелёного, мало красного и синего
    return g > 0.5 and r < 0.4 and b < 0.4
end

-- Сканирование: найти хотя бы один образец зелени
local function scanForGreen()
    grassColorSamples = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isGreenSample(obj) then
            local c = obj.BrickColor.Color
            table.insert(grassColorSamples, c)
            break -- хватит одного
        end
    end
end

-- Проверка, является ли цвет похожим на собранный образец
local function matchesGrassColor(part)
    if #grassColorSamples == 0 then return false end
    local c = part.BrickColor.Color
    local sample = grassColorSamples[1]
    local diff = math.abs(c.r - sample.r) + math.abs(c.g - sample.g) + math.abs(c.b - sample.b)
    return diff < 0.4
end

-- ===== ОКРАШИВАНИЕ =====
local function paint()
    if not paintEnabled or scoreValue.Value >= 100 then return end
    for _, v in ipairs(workspace:GetDescendants()) do
        if isDarkGround(v) and not paintedBlocks[v] then
            -- Красим в ярко-зелёный, имитируя траву
            v.BrickColor = BrickColor.new("Bright green")
            v.Material = Enum.Material.Grass
            paintedBlocks[v] = true
            scoreValue.Value += 1
            if scoreValue.Value >= 100 then
                paintEnabled = false
                break
            end
        end
    end
end

-- ===== ПОЛЁТ ДЛЯ ТЕЛЕФОНА =====
function enableFly()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = player.Character.HumanoidRootPart
    local hum = player.Character.Humanoid
    hum.PlatformStand = true

    bodyGyro = Instance.new("BodyGyro", root)
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = root.CFrame

    bodyVelocity = Instance.new("BodyVelocity", root)
    bodyVelocity.MaxForce = Vector3.new(4e5, 4e5, 4e5)
    bodyVelocity.Velocity = Vector3.zero

    -- Управление: свайп = поворот камеры
    UserInputService.TouchPan:Connect(function(info, gameProcessed)
        if not flyEnabled or gameProcessed then return end
        local rot = Vector3.new(-info.Delta.Y * 0.3, -info.Delta.X * 0.3, 0)
        bodyGyro.CFrame = bodyGyro.CFrame * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), 0)
    end)

    -- Двойной тап = рывок вперёд
    local lastTap = 0
    UserInputService.TouchTap:Connect(function()
        if not flyEnabled then return end
        local now = tick()
        if now - lastTap < 0.3 then
            bodyVelocity.Velocity = cam.CFrame.LookVector * 80
        end
        lastTap = now
    end)
end

function disableFly()
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.PlatformStand = false
    end
end

-- ===== ГРАФИЧЕСКОЕ МЕНЮ =====
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 230)
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Active = true

-- Перетаскивание
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
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.TextColor3 = Color3.new(1,1,1)
title.Text = "RESTORE PEACE"
title.Font = Enum.Font.GothamBold

-- Кнопка окрашивания
local paintBtn = Instance.new("TextButton", frame)
paintBtn.Size = UDim2.new(0.9, 0, 0, 30)
paintBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
paintBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
paintBtn.TextColor3 = Color3.new(1,1,1)
paintBtn.Text = "SCAN & PAINT"
paintBtn.Font = Enum.Font.GothamBold
paintBtn.MouseButton1Click:Connect(function()
    if paintEnabled then return end
    scanForGreen()          -- ищем образец зелени
    paintEnabled = true
    paintBtn.Text = "PAINTING..."
    paintBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
end)

-- Прогресс
local progress = Instance.new("TextLabel", frame)
progress.Size = UDim2.new(0.9, 0, 0, 30)
progress.Position = UDim2.new(0.05, 0, 0.28, 0)
progress.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
progress.TextColor3 = Color3.new(1,1,1)
progress.Text = "READY: 0/100"
progress.Font = Enum.Font.Gotham

-- Кнопка Speed
local speedBtn = Instance.new("TextButton", frame)
speedBtn.Size = UDim2.new(0.9, 0, 0, 30)
speedBtn.Position = UDim2.new(0.05, 0, 0.41, 0)
speedBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
speedBtn.TextColor3 = Color3.new(1,1,1)
speedBtn.Text = "SPEED: OFF"
speedBtn.Font = Enum.Font.GothamBold
speedBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    speedBtn.Text = "SPEED: " .. (speedEnabled and "ON" or "OFF")
    speedBtn.BackgroundColor3 = speedEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Кнопка Fly
local flyBtn = Instance.new("TextButton", frame)
flyBtn.Size = UDim2.new(0.9, 0, 0, 30)
flyBtn.Position = UDim2.new(0.05, 0, 0.54, 0)
flyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
flyBtn.TextColor3 = Color3.new(1,1,1)
flyBtn.Text = "FLY: OFF"
flyBtn.Font = Enum.Font.GothamBold
flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = "FLY: " .. (flyEnabled and "ON" or "OFF")
    flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    if flyEnabled then enableFly() else disableFly() end
end)

-- Кнопка Reset
local resetBtn = Instance.new("TextButton", frame)
resetBtn.Size = UDim2.new(0.9, 0, 0, 30)
resetBtn.Position = UDim2.new(0.05, 0, 0.67, 0)
resetBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.Text = "RESET"
resetBtn.Font = Enum.Font.GothamBold
resetBtn.MouseButton1Click:Connect(function()
    paintEnabled = false
    paintedBlocks = {}
    grassColorSamples = {}
    scoreValue.Value = 0
    progress.Text = "READY: 0/100"
    paintBtn.Text = "SCAN & PAINT"
    paintBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
end)

-- ===== ГЛАВНЫЙ ЦИКЛ =====
RunService.Heartbeat:Connect(function()
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = speedEnabled and 40 or 16
    end
    if paintEnabled then
        paint()
        progress.Text = "PAINTED: " .. scoreValue.Value .. "/100"
        if scoreValue.Value >= 100 then
            progress.Text = "DONE: 100/100"
            paintEnabled = false
            paintBtn.Text = "SCAN & PAINT"
            paintBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
        end
    end
end)
