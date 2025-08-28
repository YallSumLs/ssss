-- Load WindUI
local WindUI = loadstring(game:HttpGet('https://github.com/Footagesus/WindUI/releases/latest/download/main.lua'))()

-- Create Window
local Window = WindUI:CreateWindow({
    Title = 'Hunting Season | موسم الصيد',
    Icon = 'door-open',
    Author = 'Example UI',
    Folder = 'HuntingSeason',
})

-- Create Main Tab
local MainTab = Window:Tab({
    Title = 'Main',
    Icon = 'bird',
    Locked = false,
})

-- Services
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

-- Constants
local LOCAL_PLAYER = Players.LocalPlayer
local ANIMALS_FOLDER = Workspace:WaitForChild('Animals')
local DEAD_ANIMALS_FOLDER = Workspace:FindFirstChild('DeadAnimals')

-- Trackers
local trackers = {}

-- Utility
local function round(n) return math.floor(n + 0.5) end

local function getTargetPart(model)
    if model.PrimaryPart then return model.PrimaryPart end
    local root = model:FindFirstChild('HumanoidRootPart') or model:FindFirstChild('Head')
    if root and root:IsA('BasePart') then return root end
    for _, inst in ipairs(model:GetDescendants()) do
        if inst:IsA('BasePart') then return inst end
    end
    return nil
end

local function createBillboard(nameText, adornee, color)
    local gui = Instance.new('BillboardGui')
    gui.Name = 'AnimalTag'
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(200, 50)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.Adornee = adornee
    gui.LightInfluence = 0

    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = nameText .. ' | 0m'
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.3
    label.TextColor3 = color or Color3.fromRGB(255,255,255)
    label.Parent = gui

    return gui, label
end

local function createHighlight(model, color)
    local h = Instance.new('Highlight')
    h.Name = 'AnimalHighlight'
    h.Adornee = model
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = color or Color3.fromRGB(255,170,0)
    h.Parent = model
    return h
end

local function attach(model, dead)
    if trackers[model] then return end
    local part = getTargetPart(model)
    if not part then return end

    local highlightColor = dead and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,170,0)
    local highlight = createHighlight(model, highlightColor)
    local nameText = dead and ('Dead ' .. model.Name) or model.Name
    local gui, label = createBillboard(nameText, part, highlightColor)
    gui.Parent = LOCAL_PLAYER:WaitForChild('PlayerGui')

    local conns = {}
    table.insert(conns, RunService.RenderStepped:Connect(function()
        local char = LOCAL_PLAYER.Character
        if not char then return end
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if not hrp then return end
        local dist = (hrp.Position - part.Position).Magnitude
        label.Text = string.format('%s | %dm', nameText, round(dist))
    end))

    trackers[model] = { gui = gui, highlight = highlight, conns = conns }
end

local function detach(model)
    local t = trackers[model]
    if not t then return end
    for _, c in ipairs(t.conns) do
        pcall(function() c:Disconnect() end)
    end
    if t.gui then t.gui:Destroy() end
    if t.highlight then t.highlight:Destroy() end
    trackers[model] = nil
end

-- Dropdown to filter ESP
local ESPFilter = MainTab:Dropdown({
    Title = 'ESP Types',
    Values = { 'Animal', 'DeadAnimal' },
    Value = { 'Animal' }, -- default selection
    Multi = true,
    AllowNone = false,
    Callback = function(selection)
        print('Selected ESP categories: ', game:GetService('HttpService'):JSONEncode(selection))
    end
})

-- ESP Toggle
MainTab:Toggle({
    Title = 'Enable ESP',
    Default = false,
    Callback = function(state)
        local filter = ESPFilter.Value

        if state then
            -- Live Animals
            if table.find(filter, 'Animal') then
                for _, child in ipairs(ANIMALS_FOLDER:GetChildren()) do
                    if child:IsA('Model') then attach(child, false) end
                end
                trackers['AnimalChildAdded'] = ANIMALS_FOLDER.ChildAdded:Connect(function(child)
                    if child:IsA('Model') then attach(child, false) end
                end)
            end

            -- Dead Animals
            if DEAD_ANIMALS_FOLDER and table.find(filter, 'DeadAnimal') then
                for _, dead in ipairs(DEAD_ANIMALS_FOLDER:GetChildren()) do
                    if dead:IsA('Model') then attach(dead, true) end
                end
                trackers['DeadChildAdded'] = DEAD_ANIMALS_FOLDER.ChildAdded:Connect(function(dead)
                    if dead:IsA('Model') then attach(dead, true) end
                end)
            end
        else
            for model, _ in pairs(trackers) do
                if model ~= 'AnimalChildAdded' and model ~= 'DeadChildAdded' then
                    detach(model)
                end
            end
            if trackers['AnimalChildAdded'] then trackers['AnimalChildAdded']:Disconnect() trackers['AnimalChildAdded'] = nil end
            if trackers['DeadChildAdded'] then trackers['DeadChildAdded']:Disconnect() trackers['DeadChildAdded'] = nil end
        end
    end
})

-- WalkSpeed NumberValue
local walkValue = Instance.new('NumberValue')
walkValue.Name = 'Walks'
walkValue.Parent = LOCAL_PLAYER
walkValue.Value = 16

-- WalkSpeed Slider
MainTab:Slider({
    Title = 'WalkSpeed',
    Step = 1,
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(speed)
        walkValue.Value = tonumber(speed)
    end,
})

-- WalkSpeed Toggle
local walkSpeedConn
MainTab:Toggle({
    Title = 'Enable WalkSpeed',
    Default = false,
    Callback = function(state)
        if state then
            if walkSpeedConn then walkSpeedConn:Disconnect() end
            walkSpeedConn = RunService.RenderStepped:Connect(function()
                local char = LOCAL_PLAYER.Character
                if char and char:FindFirstChild('Humanoid') then
                    char.Humanoid.WalkSpeed = walkValue.Value
                end
            end)
        else
            if walkSpeedConn then walkSpeedConn:Disconnect() walkSpeedConn = nil end
            local char = LOCAL_PLAYER.Character
            if char and char:FindFirstChild('Humanoid') then
                char.Humanoid.WalkSpeed = 16
            end
        end
    end
})
