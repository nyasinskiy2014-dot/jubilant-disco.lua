-- ╔═══════════════════════════════════════════════════╗
-- ║          RIVALS HUB  v2.0  |  by Claude           ║
-- ║       [RightShift] — Открыть / Закрыть            ║
-- ╚═══════════════════════════════════════════════════╝

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Workspace      = game:GetService("Workspace")
local HttpService    = game:GetService("HttpService")

local lp   = Players.LocalPlayer
local cam  = Workspace.CurrentCamera

-- ══════════════════════════════════════════════════════
--  КОНФИГ
-- ══════════════════════════════════════════════════════
local CFG = {
    -- Общее
    OpenKey   = Enum.KeyCode.RightShift,
    -- Aimbot
    AimbotOn       = false,
    AimbotFOV      = 120,
    AimbotSmooth   = 0.18,
    AimbotPart     = "Head",
    AimbotTeamCheck= true,
    AimbotVisible  = true,
    ShowFOVCircle  = true,
    -- ESP
    ESPOn          = false,
    ESPBoxes       = true,
    ESPNames       = true,
    ESPHealth      = true,
    ESPDistance    = true,
    ESPTeamCheck   = true,
    -- Player
    WalkSpeed      = 16,
    JumpPower      = 50,
    NoClipOn       = false,
    InfJumpOn      = false,
    AntiFallOn     = false,
    -- Misc
    AutoRespawn    = false,
    NotifyKills    = true,
}

-- ══════════════════════════════════════════════════════
--  ЦВЕТА
-- ══════════════════════════════════════════════════════
local C = {
    BG      = Color3.fromRGB(12, 12, 18),
    Panel   = Color3.fromRGB(20, 20, 30),
    Card    = Color3.fromRGB(28, 28, 40),
    Accent  = Color3.fromRGB(220, 50, 50),
    AccentD = Color3.fromRGB(160, 30, 30),
    Green   = Color3.fromRGB(50, 210, 110),
    Red     = Color3.fromRGB(220, 60, 60),
    Text    = Color3.fromRGB(235, 235, 255),
    Sub     = Color3.fromRGB(110, 110, 140),
    Border  = Color3.fromRGB(40, 40, 60),
    White   = Color3.fromRGB(255,255,255),
}

-- ══════════════════════════════════════════════════════
--  УТИЛИТЫ
-- ══════════════════════════════════════════════════════
local function tw(obj, props, t, style)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        props):Play()
end

local function round(n) return math.floor(n + 0.5) end

local function getChar(p)
    return p and p.Character
end

local function getHRP(p)
    local c = getChar(p)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum(p)
    local c = getChar(p)
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isEnemy(p)
    if not CFG.AimbotTeamCheck then return true end
    return p.Team ~= lp.Team
end

local function inFOV(pos)
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local sp, onScreen = cam:WorldToViewportPoint(pos)
    if not onScreen then return false end
    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
    return dist <= CFG.AimbotFOV
end

local function closestTarget()
    local best, bestDist = nil, math.huge
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and isEnemy(p) then
            local c = getChar(p)
            if c then
                local part = c:FindFirstChild(CFG.AimbotPart) or c:FindFirstChild("HumanoidRootPart")
                local hum  = getHum(p)
                if part and hum and hum.Health > 0 then
                    if CFG.AimbotVisible then
                        local ray = Ray.new(cam.CFrame.Position, (part.Position - cam.CFrame.Position).Unit * 1000)
                        local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {getChar(lp), cam})
                        if hit and not hit:IsDescendantOf(c) then continue end
                    end
                    local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if dist < bestDist and inFOV(part.Position) then
                            bestDist = dist
                            best = part
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ══════════════════════════════════════════════════════
--  GUI SETUP
-- ══════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name          = "RivalsHub"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn  = false
gui.Parent        = (gethui and gethui()) or game:GetService("CoreGui")

-- ── Фон-оверлей (blur-эффект имитация) ──────────────
local overlay = Instance.new("Frame", gui)
overlay.Size            = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
overlay.BackgroundTransparency = 1
overlay.ZIndex          = 0
overlay.Active          = false

-- ══════════════════════════════════════════════════════
--  КНОПКА ОТКРЫТИЯ (плавающая)
-- ══════════════════════════════════════════════════════
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size              = UDim2.new(0,44,0,44)
toggleBtn.Position          = UDim2.new(0, 16, 0.5, -22)
toggleBtn.BackgroundColor3  = C.Accent
toggleBtn.Text              = "R"
toggleBtn.TextColor3        = C.White
toggleBtn.Font              = Enum.Font.GothamBold
toggleBtn.TextSize          = 18
toggleBtn.ZIndex            = 20
toggleBtn.AutoButtonColor   = false
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", toggleBtn).Color = C.AccentD

-- Pulse анимация кнопки
local pulse = Instance.new("Frame", toggleBtn)
pulse.Size = UDim2.fromScale(1,1)
pulse.BackgroundColor3 = C.Accent
pulse.BackgroundTransparency = 0.5
pulse.ZIndex = 19
Instance.new("UICorner", pulse).CornerRadius = UDim.new(0,10)

task.spawn(function()
    while true do
        tw(pulse, {Size=UDim2.fromScale(1.5,1.5), BackgroundTransparency=1}, 0.8, Enum.EasingStyle.Sine)
        task.wait(0.8)
        pulse.Size = UDim2.fromScale(1,1)
        pulse.BackgroundTransparency = 0.5
        task.wait(0.2)
    end
end)

-- ══════════════════════════════════════════════════════
--  ГЛАВНОЕ ОКНО
-- ══════════════════════════════════════════════════════
local win = Instance.new("Frame", gui)
win.Size                = UDim2.new(0, 520, 0, 380)
win.Position            = UDim2.new(0.5, -260, 0.5, -190)
win.BackgroundColor3    = C.BG
win.BorderSizePixel     = 0
win.ZIndex              = 10
win.Visible             = false
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 14)

local winStroke = Instance.new("UIStroke", win)
winStroke.Color     = C.Border
winStroke.Thickness = 1.5

-- Тень
local shadow = Instance.new("ImageLabel", win)
shadow.Size = UDim2.new(1, 40, 1, 40)
shadow.Position = UDim2.new(0,-20,0,-20)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0,0,0)
shadow.ImageTransparency = 0.4
shadow.ZIndex = 9
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49,49,450,450)

-- ── Шапка ────────────────────────────────────────────
local header = Instance.new("Frame", win)
header.Size             = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = C.Panel
header.ZIndex           = 11
Instance.new("UICorner", header).CornerRadius = UDim.new(0,14)

-- Заглушка снизу у шапки
local headerFix = Instance.new("Frame", header)
headerFix.Size = UDim2.new(1,0,0,14)
headerFix.Position = UDim2.new(0,0,1,-14)
headerFix.BackgroundColor3 = C.Panel
headerFix.BorderSizePixel = 0
headerFix.ZIndex = 11

-- Акцентная полоска
local accentBar = Instance.new("Frame", header)
accentBar.Size = UDim2.new(0, 4, 0, 30)
accentBar.Position = UDim2.new(0, 14, 0.5, -15)
accentBar.BackgroundColor3 = C.Accent
accentBar.ZIndex = 12
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0,4)

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size     = UDim2.new(0,200,1,0)
titleLbl.Position = UDim2.new(0, 26, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text     = "RIVALS HUB"
titleLbl.Font     = Enum.Font.GothamBold
titleLbl.TextSize = 16
titleLbl.TextColor3 = C.Text
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex   = 12

local verLbl = Instance.new("TextLabel", header)
verLbl.Size     = UDim2.new(0,80,1,0)
verLbl.Position = UDim2.new(0, 130, 0, 0)
verLbl.BackgroundTransparency = 1
verLbl.Text     = "v2.0"
verLbl.Font     = Enum.Font.Gotham
verLbl.TextSize = 12
verLbl.TextColor3 = C.Sub
verLbl.TextXAlignment = Enum.TextXAlignment.Left
verLbl.ZIndex   = 12

-- Кнопка закрыть
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size             = UDim2.new(0, 28, 0, 28)
closeBtn.Position         = UDim2.new(1, -40, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = C.White
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 12
closeBtn.ZIndex           = 12
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,7)

-- Кнопка свернуть
local minBtn = Instance.new("TextButton", header)
minBtn.Size             = UDim2.new(0, 28, 0, 28)
minBtn.Position         = UDim2.new(1, -74, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 30)
minBtn.Text             = "—"
minBtn.TextColor3       = C.White
minBtn.Font             = Enum.Font.GothamBold
minBtn.TextSize         = 14
minBtn.ZIndex           = 12
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0,7)

-- ── Боковое меню вкладок ─────────────────────────────
local sidebar = Instance.new("Frame", win)
sidebar.Size             = UDim2.new(0, 110, 1, -52)
sidebar.Position         = UDim2.new(0, 0, 0, 52)
sidebar.BackgroundColor3 = C.Panel
sidebar.ZIndex           = 11

local sidebarFix = Instance.new("Frame", sidebar)
sidebarFix.Size = UDim2.new(1,0,0,6)
sidebarFix.BackgroundColor3 = C.Panel
sidebarFix.BorderSizePixel = 0
sidebarFix.ZIndex = 11

local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding         = UDim.new(0, 4)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 10)

-- Нижний скруглённый угол сайдбара
local sideCorner = Instance.new("UICorner", sidebar)
sideCorner.CornerRadius = UDim.new(0,14)

local sideRFix = Instance.new("Frame", sidebar)
sideRFix.Size = UDim2.new(0,14,1,0)
sideRFix.Position = UDim2.new(1,-14,0,0)
sideRFix.BackgroundColor3 = C.Panel
sideRFix.BorderSizePixel = 0
sideRFix.ZIndex = 11

-- ── Контентная зона ──────────────────────────────────
local content = Instance.new("Frame", win)
content.Size             = UDim2.new(1, -120, 1, -62)
content.Position         = UDim2.new(0, 115, 0, 57)
content.BackgroundTransparency = 1
content.ZIndex           = 11

-- ══════════════════════════════════════════════════════
--  ТАБЛИЦЫ ВКЛАДОК
-- ══════════════════════════════════════════════════════
local tabs        = {}
local tabPages    = {}
local activeTab   = nil

local TAB_LIST = {
    {name="Aimbot", icon="🎯"},
    {name="ESP",    icon="👁"},
    {name="Player", icon="⚡"},
    {name="Misc",   icon="⚙"},
    {name="Скрипт", icon="📦"},
}

local function makeTabBtn(tabInfo)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size             = UDim2.new(1, -16, 0, 38)
    btn.BackgroundColor3 = C.Card
    btn.BackgroundTransparency = 1
    btn.Text             = tabInfo.icon.."  "..tabInfo.name
    btn.TextColor3       = C.Sub
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.ZIndex           = 12
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    -- Индикатор слева
    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0,3,0,20)
    ind.Position = UDim2.new(0,0,0.5,-10)
    ind.BackgroundColor3 = C.Accent
    ind.BackgroundTransparency = 1
    ind.ZIndex = 13
    Instance.new("UICorner", ind).CornerRadius = UDim.new(0,2)

    tabs[tabInfo.name] = {btn=btn, ind=ind}

    btn.MouseButton1Click:Connect(function()
        -- Деактивировать старый
        if activeTab then
            local old = tabs[activeTab]
            tw(old.btn, {BackgroundTransparency=1, TextColor3=C.Sub}, 0.18)
            tw(old.ind, {BackgroundTransparency=1}, 0.18)
            if tabPages[activeTab] then
                tabPages[activeTab].Visible = false
            end
        end
        -- Активировать новый
        activeTab = tabInfo.name
        tw(btn, {BackgroundTransparency=0.6, TextColor3=C.Text}, 0.18)
        tw(ind, {BackgroundTransparency=0}, 0.18)
        btn.BackgroundColor3 = C.Accent
        if tabPages[tabInfo.name] then
            tabPages[tabInfo.name].Visible = true
        end
    end)

    btn.MouseEnter:Connect(function()
        if activeTab ~= tabInfo.name then
            tw(btn, {BackgroundTransparency=0.8, TextColor3=Color3.fromRGB(180,180,210)}, 0.12)
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= tabInfo.name then
            tw(btn, {BackgroundTransparency=1, TextColor3=C.Sub}, 0.12)
        end
    end)
end

for _, t in ipairs(TAB_LIST) do
    makeTabBtn(t)
end

-- ══════════════════════════════════════════════════════
--  КОНСТРУКТОР ЭЛЕМЕНТОВ СТРАНИЦ
-- ══════════════════════════════════════════════════════
local function makePage(tabName)
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.fromScale(1,1)
    page.Position = UDim2.fromScale(0,0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.Accent
    page.BorderSizePixel = 0
    page.Visible = false
    page.ZIndex = 12

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8)
    Instance.new("UIPadding", page).PaddingRight = UDim.new(0,6)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 16)
    end)

    tabPages[tabName] = page
    return page
end

-- Заголовок раздела
local function sectionTitle(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1,0,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = C.Accent
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 13
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0,4)
    return lbl
end

-- Карточка-контейнер
local function makeCard(parent)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1,0,0,42)
    card.BackgroundColor3 = C.Card
    card.ZIndex = 13
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,9)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = C.Border
    stroke.Thickness = 1
    return card
end

-- Переключатель (toggle)
local function makeToggle(parent, labelText, key, callback)
    local card = makeCard(parent)
    card.Size = UDim2.new(1,0,0,46)

    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(0.7,0,1,0)
    lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = C.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 14

    -- Track
    local track = Instance.new("Frame", card)
    track.Size = UDim2.new(0,40,0,22)
    track.Position = UDim2.new(1,-54,0.5,-11)
    track.BackgroundColor3 = CFG[key] and C.Green or C.Border
    track.ZIndex = 14
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    -- Knob
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0,16,0,16)
    knob.Position = CFG[key]
        and UDim2.new(1,-19,0.5,-8)
        or  UDim2.new(0,3,0.5,-8)
    knob.BackgroundColor3 = C.White
    knob.ZIndex = 15
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local state = CFG[key]

    local btn = Instance.new("TextButton", card)
    btn.Size = UDim2.fromScale(1,1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 15

    btn.MouseButton1Click:Connect(function()
        state = not state
        CFG[key] = state
        tw(track, {BackgroundColor3 = state and C.Green or C.Border}, 0.2)
        tw(knob,  {Position = state
            and UDim2.new(1,-19,0.5,-8)
            or  UDim2.new(0,3,0.5,-8)}, 0.2)
        if callback then callback(state) end
    end)

    return card
end

-- Слайдер
local function makeSlider(parent, labelText, key, min, max, suffix)
    suffix = suffix or ""
    local card = makeCard(parent)
    card.Size = UDim2.new(1,0,0,60)

    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(0.6,0,0,22)
    lbl.Position = UDim2.new(0,14,0,6)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = C.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 14

    local valLbl = Instance.new("TextLabel", card)
    valLbl.Size = UDim2.new(0.35,0,0,22)
    valLbl.Position = UDim2.new(0.65,0,0,6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(CFG[key])..suffix
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextColor3 = C.Accent
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 14

    local trackBg = Instance.new("Frame", card)
    trackBg.Size = UDim2.new(1,-28,0,6)
    trackBg.Position = UDim2.new(0,14,0,38)
    trackBg.BackgroundColor3 = C.Border
    trackBg.ZIndex = 14
    Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", trackBg)
    fill.Size = UDim2.new((CFG[key]-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = C.Accent
    fill.ZIndex = 15
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", trackBg)
    knob.Size = UDim2.new(0,14,0,14)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((CFG[key]-min)/(max-min),0,0.5,0)
    knob.BackgroundColor3 = C.White
    knob.ZIndex = 16
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local dragging = false
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = trackBg.AbsolutePosition
            local sz  = trackBg.AbsoluteSize
            local rel = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            local val = round(min + rel*(max-min))
            CFG[key] = val
            valLbl.Text = tostring(val)..suffix
            fill.Size = UDim2.new(rel,0,1,0)
            knob.Position = UDim2.new(rel,0,0.5,0)
        end
    end)

    return card
end

-- Кнопка действия
local function makeButton(parent, labelText, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,0,0,42)
    btn.BackgroundColor3 = C.Accent
    btn.Text = labelText
    btn.TextColor3 = C.White
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.ZIndex = 13
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,9)

    btn.MouseButton1Click:Connect(function()
        tw(btn, {BackgroundColor3=C.AccentD}, 0.1)
        task.wait(0.1)
        tw(btn, {BackgroundColor3=C.Accent}, 0.15)
        if callback then callback() end
    end)
    btn.MouseEnter:Connect(function()
        tw(btn, {BackgroundColor3=Color3.fromRGB(240,70,70)}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, {BackgroundColor3=C.Accent}, 0.12)
    end)
    return btn
end

-- ══════════════════════════════════════════════════════
--  СТРАНИЦА: AIMBOT
-- ══════════════════════════════════════════════════════
local aimPage = makePage("Aimbot")
sectionTitle(aimPage, "⚙ Основное")
makeToggle(aimPage, "Aimbot включён",        "AimbotOn")
makeToggle(aimPage, "Только видимые цели",   "AimbotVisible")
makeToggle(aimPage, "Проверка команды",      "AimbotTeamCheck")
makeToggle(aimPage, "Показывать FOV круг",   "ShowFOVCircle")
sectionTitle(aimPage, "🎛 Параметры")
makeSlider(aimPage,  "FOV",                  "AimbotFOV",    10, 400, "px")
makeSlider(aimPage,  "Плавность",            "AimbotSmooth", 1, 20, "")

-- ══════════════════════════════════════════════════════
--  СТРАНИЦА: ESP
-- ══════════════════════════════════════════════════════
local espPage = makePage("ESP")
sectionTitle(espPage, "⚙ Основное")
makeToggle(espPage, "ESP включён",      "ESPOn")
makeToggle(espPage, "Боксы",            "ESPBoxes")
makeToggle(espPage, "Имена",            "ESPNames")
makeToggle(espPage, "Здоровье",         "ESPHealth")
makeToggle(espPage, "Дистанция",        "ESPDistance")
makeToggle(espPage, "Проверка команды", "ESPTeamCheck")

-- ══════════════════════════════════════════════════════
--  СТРАНИЦА: PLAYER
-- ══════════════════════════════════════════════════════
local plrPage = makePage("Player")
sectionTitle(plrPage, "🏃 Движение")
makeSlider(plrPage, "Скорость ходьбы",   "WalkSpeed",  16, 100, "")
makeSlider(plrPage, "Высота прыжка",     "JumpPower",  50, 250, "")
makeToggle(plrPage, "NoClip",            "NoClipOn")
makeToggle(plrPage, "Бесконечный прыжок","InfJumpOn")
makeToggle(plrPage, "Нет урона от падения","AntiFallOn")
sectionTitle(plrPage, "⚡ Быстрые действия")
makeButton(plrPage, "Применить скорость / прыжок", function()
    local hum = getHum(lp)
    if hum then
        hum.WalkSpeed = CFG.WalkSpeed
        hum.JumpPower = CFG.JumpPower
    end
end)

-- ══════════════════════════════════════════════════════
--  СТРАНИЦА: MISC
-- ══════════════════════════════════════════════════════
local miscPage = makePage("Misc")
sectionTitle(miscPage, "🔧 Разное")
makeToggle(miscPage, "Авто-респавн",       "AutoRespawn")
makeToggle(miscPage, "Уведомления о киллах","NotifyKills")
sectionTitle(miscPage, "🗑 Прочее")
makeButton(miscPage, "Сбросить настройки", function()
    CFG.WalkSpeed = 16
    CFG.JumpPower = 50
    local hum = getHum(lp)
    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
end)

-- ══════════════════════════════════════════════════════
--  СТРАНИЦА: СКРИПТ
-- ══════════════════════════════════════════════════════
local scrPage = makePage("Скрипт")

local statusCard = makeCard(scrPage)
statusCard.Size = UDim2.new(1,0,0,52)
local statusLbl = Instance.new("TextLabel", statusCard)
statusLbl.Size = UDim2.fromScale(1,1)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "⏳ Ожидание загрузки..."
statusLbl.Font = Enum.Font.GothamSemibold
statusLbl.TextSize = 13
statusLbl.TextColor3 = C.Sub
statusLbl.ZIndex = 14

sectionTitle(scrPage, "📦 Загрузка скриптов")

local SCRIPT_URLS = {
    {label = "Rivals Latest (GitHub)", url = "https://raw.githubusercontent.com/Sheeshablee73/Scriptss/main/Rivals%20Latest.lua"},
    {label = "Pastebin Backup",         url = "https://pastebin.com/raw/RZK9XdtH"},
}

local function tryLoadScripts()
    statusLbl.Text = "⏳ Загружаю..."
    statusLbl.TextColor3 = Color3.fromRGB(220,180,50)
    for _, s in ipairs(SCRIPT_URLS) do
        local ok, msg = pcall(function()
            local code = game:HttpGet(s.url, true)
            loadstring(code)()
        end)
        if ok then
            statusLbl.Text = "✅ Загружен: "..s.label
            statusLbl.TextColor3 = C.Green
            return
        else
            warn("[RivalsHub] Не удалось загрузить "..s.label..": "..tostring(msg))
        end
    end
    statusLbl.Text = "❌ Все источники недоступны"
    statusLbl.TextColor3 = C.Red
end

for _, s in ipairs(SCRIPT_URLS) do
    makeButton(scrPage, "▶  "..s.label, function()
        statusLbl.Text = "⏳ Загружаю: "..s.label
        statusLbl.TextColor3 = Color3.fromRGB(220,180,50)
        task.spawn(function()
            local ok, msg = pcall(function()
                loadstring(game:HttpGet(s.url, true))()
            end)
            if ok then
                statusLbl.Text = "✅ Загружен: "..s.label
                statusLbl.TextColor3 = C.Green
            else
                statusLbl.Text = "❌ Ошибка: "..tostring(msg):sub(1,40)
                statusLbl.TextColor3 = C.Red
            end
        end)
    end)
end

makeButton(scrPage, "🔄 Загрузить все (автоматически)", function()
    task.spawn(tryLoadScripts)
end)

-- ══════════════════════════════════════════════════════
--  ПЕРЕТАСКИВАНИЕ ОКНА
-- ══════════════════════════════════════════════════════
local dragging, dragStart, startPos = false, nil, nil

header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = win.Position
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        win.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ══════════════════════════════════════════════════════
--  ОТКРЫТЬ / ЗАКРЫТЬ
-- ══════════════════════════════════════════════════════
local menuOpen    = false
local minimized   = false

local function openMenu()
    menuOpen = true
    win.Visible = true
    win.Size = UDim2.new(0,520,0,0)
    win.BackgroundTransparency = 1
    tw(win, {Size=UDim2.new(0,520,0,380), BackgroundTransparency=0}, 0.3, Enum.EasingStyle.Back)
    tw(overlay, {BackgroundTransparency=0.55}, 0.25)
    -- Активировать первую вкладку
    if not activeTab then
        tabs["Aimbot"].btn.MouseButton1Click:Fire()
    end
end

local function closeMenu()
    menuOpen = false
    tw(win, {Size=UDim2.new(0,520,0,0), BackgroundTransparency=1}, 0.25, Enum.EasingStyle.Quart)
    tw(overlay, {BackgroundTransparency=1}, 0.2)
    task.wait(0.3)
    win.Visible = false
end

toggleBtn.MouseButton1Click:Connect(function()
    if menuOpen then closeMenu() else openMenu() end
end)

closeBtn.MouseButton1Click:Connect(function()
    closeMenu()
end)

-- Свернуть / развернуть
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tw(win, {Size=UDim2.new(0,520,0,52)}, 0.2)
        sidebar.Visible = false
        content.Visible = false
    else
        tw(win, {Size=UDim2.new(0,520,0,380)}, 0.25, Enum.EasingStyle.Back)
        task.wait(0.15)
        sidebar.Visible = true
        content.Visible = true
    end
end)

-- Клавиша
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == CFG.OpenKey then
        if menuOpen then closeMenu() else openMenu() end
    end
end)

-- ══════════════════════════════════════════════════════
--  ЛОГИКА: FOV CIRCLE
-- ══════════════════════════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Radius    = CFG.AimbotFOV
fovCircle.Color     = Color3.fromRGB(255,60,60)
fovCircle.Thickness = 1.5
fovCircle.Filled    = false
fovCircle.Transparency = 0.6

-- ══════════════════════════════════════════════════════
--  ЛОГИКА: ESP DRAWINGS
-- ══════════════════════════════════════════════════════
local espCache = {}

local function clearESP(p)
    if espCache[p] then
        for _, d in pairs(espCache[p]) do pcall(function() d:Remove() end) end
        espCache[p] = nil
    end
end

local function getESP(p)
    if not espCache[p] then
        espCache[p] = {
            box     = Drawing.new("Square"),
            name    = Drawing.new("Text"),
            health  = Drawing.new("Text"),
            dist    = Drawing.new("Text"),
        }
        local d = espCache[p]
        d.box.Filled = false; d.box.Color = C.Red; d.box.Thickness = 1.5
        d.name.Size  = 13; d.name.Color = C.White; d.name.Font = 2; d.name.Center = true; d.name.Outline = true
        d.health.Size = 11; d.health.Font = 2; d.health.Center = true; d.health.Outline = true
        d.dist.Size  = 11; d.dist.Color  = Color3.fromRGB(180,180,255); d.dist.Font = 2; d.dist.Center = true; d.dist.Outline = true
    end
    return espCache[p]
end

-- ══════════════════════════════════════════════════════
--  ГЛАВНЫЙ LOOP
-- ══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local vp = cam.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2

    -- FOV Circle
    if CFG.AimbotOn and CFG.ShowFOVCircle then
        fovCircle.Visible  = true
        fovCircle.Radius   = CFG.AimbotFOV
        fovCircle.Position = Vector2.new(cx, cy)
    else
        fovCircle.Visible = false
    end

    -- Aimbot
    if CFG.AimbotOn then
        local target = closestTarget()
        if target and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local sp = cam:WorldToViewportPoint(target.Position)
            local smooth = math.clamp(CFG.AimbotSmooth / 10, 0.01, 1)
            cam.CFrame = cam.CFrame:Lerp(
                CFrame.new(cam.CFrame.Position, target.Position),
                smooth
            )
        end
    end

    -- ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p == lp then continue end
        if CFG.ESPTeamCheck and p.Team == lp.Team then
            clearESP(p); continue
        end

        local c   = getChar(p)
        local hum = getHum(p)
        local hrp = getHRP(p)

        if not (c and hum and hrp) or hum.Health <= 0 then
            clearESP(p); continue
        end

        local d = getESP(p)
        local head = c:FindFirstChild("Head")

        -- Box
        if CFG.ESPOn and CFG.ESPBoxes and head then
            local topSP,    vis1 = cam:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            local bottomSP, vis2 = cam:WorldToViewportPoint(hrp.Position  - Vector3.new(0,3,0))
            if vis1 and vis2 and topSP.Z > 0 then
                local h = math.abs(topSP.Y - bottomSP.Y)
                local w = h * 0.6
                d.box.Visible  = true
                d.box.Size     = Vector2.new(w, h)
                d.box.Position = Vector2.new(topSP.X - w/2, topSP.Y)
                -- цвет по хп
                local hp = hum.Health / hum.MaxHealth
                d.box.Color = Color3.fromRGB(
                    round((1-hp)*255), round(hp*200), 50)
            else
                d.box.Visible = false
            end
        else
            d.box.Visible = false
        end

        -- Имя
        if CFG.ESPOn and CFG.ESPNames and head then
            local sp, vis = cam:WorldToViewportPoint(head.Position + Vector3.new(0,1.5,0))
            if vis and sp.Z > 0 then
                d.name.Visible  = true
                d.name.Text     = p.Name
                d.name.Position = Vector2.new(sp.X, sp.Y)
            else d.name.Visible = false end
        else d.name.Visible = false end

        -- Хп
        if CFG.ESPOn and CFG.ESPHealth and head then
            local sp, vis = cam:WorldToViewportPoint(head.Position + Vector3.new(0,2.5,0))
            if vis and sp.Z > 0 then
                d.health.Visible  = true
                local hp = round(hum.Health)
                d.health.Text     = hp.." HP"
                d.health.Color    = Color3.fromRGB(50, 210, 110)
                d.health.Position = Vector2.new(sp.X, sp.Y)
            else d.health.Visible = false end
        else d.health.Visible = false end

        -- Дистанция
        if CFG.ESPOn and CFG.ESPDistance then
            local myHRP = getHRP(lp)
            if myHRP then
                local dist = round((hrp.Position - myHRP.Position).Magnitude)
                local sp, vis = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0,4,0))
                if vis and sp.Z > 0 then
                    d.dist.Visible  = true
                    d.dist.Text     = dist.."m"
                    d.dist.Position = Vector2.new(sp.X, sp.Y)
                else d.dist.Visible = false end
            end
        else d.dist.Visible = false end
    end
end)

-- ══════════════════════════════════════════════════════
--  ЛОГИКА: NoClip / InfJump / AntiFall / Speed
-- ══════════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    local c   = getChar(lp)
    local hum = getHum(lp)
    if not (c and hum) then return end

    if CFG.NoClipOn then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    if CFG.AntiFallOn then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if CFG.InfJumpOn then
        local hum = getHum(lp)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Авто-применение скорости при spawn
Players.LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.5)
        hum.WalkSpeed = CFG.WalkSpeed
        hum.JumpPower = CFG.JumpPower
    end
end)

-- ══════════════════════════════════════════════════════
--  УВЕДОМЛЕНИЕ ПРИ ЗАГРУЗКЕ
-- ══════════════════════════════════════════════════════
local notif = Instance.new("Frame", gui)
notif.Size = UDim2.new(0,260,0,52)
notif.Position = UDim2.new(1,-270, 1,-70)
notif.BackgroundColor3 = C.Panel
notif.ZIndex = 30
Instance.new("UICorner", notif).CornerRadius = UDim.new(0,10)
local notifStroke = Instance.new("UIStroke", notif)
notifStroke.Color = C.Accent

local notifLbl = Instance.new("TextLabel", notif)
notifLbl.Size = UDim2.fromScale(1,1)
notifLbl.BackgroundTransparency = 1
notifLbl.Text = "✅  RIVALS HUB загружен!\n[RightShift] — открыть"
notifLbl.Font = Enum.Font.GothamSemibold
notifLbl.TextSize = 12
notifLbl.TextColor3 = C.Text
notifLbl.ZIndex = 31

task.spawn(function()
    task.wait(3.5)
    tw(notif, {Position=UDim2.new(1,10,1,-70), BackgroundTransparency=1}, 0.4)
    tw(notifLbl, {TextTransparency=1}, 0.4)
    task.wait(0.5)
    notif:Destroy()
end)

print("✅ RIVALS HUB v2.0 — загружен! [RightShift] = открыть")
