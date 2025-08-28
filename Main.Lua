-- Services
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')
local UserInputService = game:GetService('UserInputService')
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass('Humanoid')
local rootPart = character:WaitForChild('HumanoidRootPart')
local camera = workspace.CurrentCamera

-- WindUI
local WindUI = loadstring(
    game:HttpGet(
        'https://github.com/Footagesus/WindUI/releases/latest/download/main.lua'
    )
)()
local Window = WindUI:CreateWindow({
    Title = 'Lz Hub | Hunting Season',
    Icon = 'door-open',
    Author = 'Yallsum.Lz#0',
    Folder = 'Lz Hub',
    Size = UDim2.fromOffset(680, 500),
    Transparent = true,
    Theme = 'Dark',
    Resizable = false,
    SideBarWidth = 200,
    HideSearchBar = false,
    User = { Enabled = true, Anonymous = false },
})
Window:DisableTopbarButtons({ 'Fullscreen' })

-- Variables
local espEnabled = false
local aimbotEnabled = false
local fovCircleEnabled = false
local fovCircleSize = 100
local aimbotType = 'Snap Aimbot'
local walkSpeedEnabled = false
local flyEnabled = false
local walkSpeedValue = 16
local flySpeedValue = 50
local flying = false
local bodyVelocity, bodyGyro

-- FOV Circle
local fovCircle = Drawing.new('Circle')
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Filled = false
fovCircle.Radius = fovCircleSize

-- Functions
local function isR15(char)
    return char:FindFirstChild('UpperTorso') ~= nil
end

local function getAnimalPart(model)
    if model.PrimaryPart then
        return model.PrimaryPart
    end
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA('BasePart') then
            return v
        end
    end
    return nil
end

-- ESP
local function createESP(model)
    local part = getAnimalPart(model)
    if not part or part:FindFirstChild('ESP') then
        return
    end
    local billboard = Instance.new('BillboardGui')
    billboard.Name = 'ESP'
    billboard.Size = UDim2.new(0, 150, 0, 50)
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    local label = Instance.new('TextLabel')
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.Parent = billboard
    task.spawn(function()
        while billboard.Parent do
            local dist = (rootPart.Position - part.Position).Magnitude
            label.Text = model.Name .. ' [' .. math.floor(dist) .. 'm]'
            task.wait(0.1)
        end
    end)
end

local function removeAllESP()
    local folder = Workspace:FindFirstChild('Animals')
    if folder then
        for _, animal in pairs(folder:GetChildren()) do
            local part = getAnimalPart(animal)
            if part and part:FindFirstChild('ESP') then
                part.ESP:Destroy()
            end
        end
    end
end

-- Closest animal for aimbot
local function getClosestAnimal()
    local closest = nil
    local minDist = math.huge
    local folder = Workspace:FindFirstChild('Animals')
    if not folder then
        return nil
    end
    for _, animal in pairs(folder:GetChildren()) do
        local part = getAnimalPart(animal)
        if part then
            local screenPos, onScreen =
                camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local screenCenter = Vector2.new(
                    camera.ViewportSize.X / 2,
                    camera.ViewportSize.Y / 2
                )
                local dist = (
                    Vector2.new(screenPos.X, screenPos.Y) - screenCenter
                ).Magnitude
                if dist <= fovCircleSize and dist < minDist then
                    minDist = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

-- ========== Main Tab ==========
local Main = Window:Tab({ Title = 'Main', Icon = 'target', Locked = false })
Main:Section({ Title = 'ESP', TextXAlignment = 'Left', TextSize = 17 })
Main:Toggle({
    Title = 'ESP Toggle',
    Desc = 'Toggle the ESP function On/Off',
    Type = 'Toggle',
    Default = false,
    Callback = function(state)
        espEnabled = state
        if not state then
            removeAllESP()
        end
    end,
})

local AimbotSection =
    Main:Section({ Title = 'Aimbot', TextXAlignment = 'Left', TextSize = 17 })
Main:Dropdown({
    Title = 'Aimbot Type',
    Values = { 'Snap Aimbot', 'Silent Aim' },
    Value = 'Snap Aimbot',
    Callback = function(option)
        aimbotType = option
    end,
})
Main:Slider({
    Title = 'Fov Circle Size',
    Step = 1,
    Value = { Min = 10, Max = 250, Default = 100 },
    Callback = function(val)
        fovCircleSize = tonumber(val)
        fovCircle.Radius = tonumber(val)
    end,
})
Main:Toggle({
    Title = 'Aimbot Toggle',
    Desc = 'Toggle the aimbot function On/Off',
    Type = 'Toggle',
    Default = false,
    Callback = function(state)
        aimbotEnabled = state
    end,
})
Main:Toggle({
    Title = 'FovCircle Toggle',
    Desc = 'Show/Hide the FOV circle',
    Type = 'Toggle',
    Default = false,
    Callback = function(state)
        fovCircleEnabled = state
    end,
})

-- ========== Local Player ==========
local LocalPlayerTab =
    Window:Tab({ Title = 'Local Player', Icon = 'box', Locked = false })
LocalPlayerTab:Section({
    Title = 'Movement',
    TextXAlignment = 'Left',
    TextSize = 17,
})
LocalPlayerTab:Slider({
    Title = 'Walk Speed',
    Step = 1,
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(val)
        walkSpeedValue = val
        if walkSpeedEnabled and humanoid then
            humanoid.WalkSpeed = val
        end
    end,
})
LocalPlayerTab:Toggle({
    Title = 'Walkspeed Toggle',
    Desc = 'Toggles the speed hack',
    Type = 'Toggle',
    Default = false,
    Callback = function(state)
        walkSpeedEnabled = state
        if humanoid then
            humanoid.WalkSpeed = state and walkSpeedValue or 16
        end
    end,
})
LocalPlayerTab:Slider({
    Title = 'Fly Speed',
    Step = 1,
    Value = { Min = 16, Max = 500, Default = 50 },
    Callback = function(val)
        flySpeedValue = val
    end,
})
LocalPlayerTab:Toggle({
    Title = 'Flight Toggle',
    Desc = 'Toggles the fly hack',
    Type = 'Toggle',
    Default = false,
    Callback = function(state)
        flyEnabled = state
    end,
})

-- ========== Misc ==========
local Misc = Window:Tab({ Title = 'Misc', Icon = 'wand', Locked = false })
Misc:Button({
    Title = 'Javis Jerk It',
    Desc = 'Gives Jarvis a funny animation tool',
    Locked = false,
    Callback = function()
        local backpack = player:FindFirstChild('Backpack')
        if not humanoid or not backpack then
            return
        end
        local tool = Instance.new('Tool')
        tool.Name = 'Jerk Off'
        tool.ToolTip = 'Jarvis Touch My Tip'
        tool.RequiresHandle = false
        tool.Parent = backpack
        local jorkin = false
        local track = nil
        local function stopTomfoolery()
            jorkin = false
            if track then
                track:Stop()
                track:Destroy()
                track = nil
            end
        end
        tool.Equipped:Connect(function()
            jorkin = true
        end)
        tool.Unequipped:Connect(stopTomfoolery)
        humanoid.Died:Connect(stopTomfoolery)
        task.spawn(function()
            while true do
                task.wait(0.05)
                if not jorkin then
                    continue
                end
                if not track then
                    local anim = Instance.new('Animation')
                    anim.AnimationId = isR15(character)
                            and 'rbxassetid://698251653'
                        or 'rbxassetid://72042024'
                    track = humanoid:LoadAnimation(anim)
                end
                track:Play()
                track:AdjustSpeed(isR15(character) and 0.7 or 0.65)
                track.TimePosition = 0.6
                local endTime = isR15(character) and 0.7 or 0.65
                while track and track.TimePosition < endTime do
                    task.wait(0.02)
                end
                if track then
                    track:Stop()
                    track:Destroy()
                    track = nil
                end
            end
        end)
    end,
})

-- ========== Settings Tab ==========
local Settings =
    Window:Tab({ Title = 'Settings', Icon = 'settings', Locked = false })
local ThemesSection = Settings:Section({
    Title = 'Themes',
    TextXAlignment = 'Left',
    TextSize = 17,
})

-- Add multiple themes
local themeList = {
    {
        Name = 'Aqua',
        Accent = '#008080',
        Dialog = '#004c4c',
        Outline = '#00ffff',
        Text = '#ccffff',
        Placeholder = '#66cccc',
        Background = '#002626',
        Button = '#006666',
        Icon = '#33ffff',
    },
    {
        Name = 'Crimson',
        Accent = '#8B0000',
        Dialog = '#4C0000',
        Outline = '#FF0000',
        Text = '#FF6666',
        Placeholder = '#FF9999',
        Background = '#330000',
        Button = '#660000',
        Icon = '#FF3333',
    },
    {
        Name = 'Sunset',
        Accent = '#FF4500',
        Dialog = '#8B2E00',
        Outline = '#FF8C00',
        Text = '#FFD700',
        Placeholder = '#FFA500',
        Background = '#331A00',
        Button = '#FF6347',
        Icon = '#FFB347',
    },
    {
        Name = 'Emerald',
        Accent = '#50C878',
        Dialog = '#205E3B',
        Outline = '#2E8B57',
        Text = '#A9DFBF',
        Placeholder = '#98FB98',
        Background = '#00331A',
        Button = '#1E7F5C',
        Icon = '#2EE8AC',
    },
    {
        Name = 'Lavender',
        Accent = '#E6E6FA',
        Dialog = '#B0C4DE',
        Outline = '#9370DB',
        Text = '#D8BFD8',
        Placeholder = '#E0B0FF',
        Background = '#2B0033',
        Button = '#9370DB',
        Icon = '#DDA0DD',
    },
    {
        Name = 'Neon',
        Accent = '#39FF14',
        Dialog = '#0DFF0D',
        Outline = '#00FF00',
        Text = '#99FF99',
        Placeholder = '#66FF66',
        Background = '#002600',
        Button = '#00FF00',
        Icon = '#33FF33',
    },
    {
        Name = 'Ruby',
        Accent = '#AA0114',
        Dialog = '#55000A',
        Outline = '#FF0011',
        Text = '#FF6699',
        Placeholder = '#FF3366',
        Background = '#330005',
        Button = '#770011',
        Icon = '#FF1144',
    },
}

for _, th in pairs(themeList) do
    WindUI:AddTheme(th)
end

-- Theme dropdown
ThemesSection:Dropdown({
    Title = 'Select Theme',
    Values = {
        'Aqua',
        'Crimson',
        'Sunset',
        'Emerald',
        'Lavender',
        'Neon',
        'Ruby',
    },
    Value = 'Aqua',
    Callback = function(selectedTheme)
        WindUI:SetTheme(selectedTheme)
        WindUI:Notify({
            Title = 'Theme Changed',
            Content = 'Applied ' .. selectedTheme .. ' theme!',
            Duration = 3,
            Icon = 'bird',
        })
    end,
})

-- ========== Loops ==========
task.spawn(function()
    while true do
        if espEnabled then
            local folder = Workspace:FindFirstChild('Animals')
            if folder then
                for _, animal in pairs(folder:GetChildren()) do
                    createESP(animal)
                end
            end
        end
        task.wait(0.2)
    end
end)

RunService.RenderStepped:Connect(function()
    fovCircle.Position =
        Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovCircle.Visible = fovCircleEnabled

    -- Fly
    if flyEnabled and not flying then
        flying = true
        bodyVelocity = Instance.new('BodyVelocity')
        bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = rootPart
        bodyGyro = Instance.new('BodyGyro')
        bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bodyGyro.CFrame = rootPart.CFrame
        bodyGyro.Parent = rootPart
    elseif not flyEnabled and flying then
        flying = false
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        if bodyGyro then
            bodyGyro:Destroy()
            bodyGyro = nil
        end
    end
    if flying and bodyVelocity and bodyGyro then
        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end
        if moveDir.Magnitude > 0 then
            bodyVelocity.Velocity = moveDir.Unit * flySpeedValue
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        bodyGyro.CFrame = CFrame.new(
            rootPart.Position,
            rootPart.Position + camera.CFrame.LookVector
        )
    end

    -- Aimbot
    if aimbotEnabled then
        local targetPart = getClosestAnimal()
        if targetPart and aimbotType == 'Snap Aimbot' then
            camera.CFrame =
                CFrame.new(camera.CFrame.Position, targetPart.Position)
        end
    end
end)
