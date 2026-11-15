--==================================================
--            SEA SEA 🌊  |  MOBILE V4.1
--        (giao diện mới + HUD trên màn hình)
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Dọn bản cũ nếu chạy lại script (tránh chồng kết nối / GUI)
if _G.SeaSeaCleanup then
    pcall(_G.SeaSeaCleanup)
end
do
    local oldGui = PlayerGui:FindFirstChild("SeaSea")
    if oldGui then oldGui:Destroy() end
    local oldMarker = workspace:FindFirstChild("SEA_SEA_ElevatorMarker")
    if oldMarker then oldMarker:Destroy() end
    local oldLabel = PlayerGui:FindFirstChild("SEA_SEA_ElevatorLabel")
    if oldLabel then oldLabel:Destroy() end
end

local Connections = {}
local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

--==================================================
-- SETTINGS
--==================================================

local Speed = 16
local JumpPower = 50
local Bright = false
local Fog = false
local FPSOn = false
local CoordsOn = false

local SavedElevatorPosition = nil
local ElevatorESPOn = true
local ElevatorMarker = nil
local ElevatorHighlight = nil
local ElevatorBillboard = nil

local function Humanoid()
    local c = Player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function Root()
    local c = Player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function ApplySpeed()
    local h = Humanoid()
    if h then h.WalkSpeed = Speed end
end

local function ApplyJump()
    local h = Humanoid()
    if h then
        h.UseJumpPower = true
        h.JumpPower = JumpPower
    end
end

--==================================================
-- THEME + HELPER UI
--==================================================

local C = {
    Bg      = Color3.fromRGB(8, 22, 38),
    Card    = Color3.fromRGB(16, 38, 62),
    Header  = Color3.fromRGB(0, 105, 175),
    Accent  = Color3.fromRGB(45, 175, 250),
    Btn     = Color3.fromRGB(26, 68, 105),
    BtnMain = Color3.fromRGB(0, 120, 195),
    Danger  = Color3.fromRGB(150, 45, 55),
    Input   = Color3.fromRGB(8, 26, 44),
    Text    = Color3.new(1, 1, 1),
    Sub     = Color3.fromRGB(140, 195, 225),
    On      = Color3.fromRGB(40, 200, 130),
    Off     = Color3.fromRGB(70, 90, 110),
}

local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local function Round(o, r)
    New("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function NextOrder(parent)
    local n = (parent:GetAttribute("n") or 0) + 1
    parent:SetAttribute("n", n)
    return n
end

--==================================================
-- GUI KHUNG CHÍNH
--==================================================

local Gui = New("ScreenGui", {
    Name = "SeaSea",
    ResetOnSpawn = false,
    DisplayOrder = 999,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local Viewport = workspace.CurrentCamera.ViewportSize
local W = math.clamp(Viewport.X - 24, 240, 300)
local H = math.clamp(Viewport.Y - 60, 280, 520)

local Main = New("Frame", {
    Size = UDim2.fromOffset(W, H),
    Position = UDim2.fromOffset((Viewport.X - W) / 2, (Viewport.Y - H) / 2),
    BackgroundColor3 = C.Bg,
    BorderSizePixel = 0,
}, Gui)
Round(Main, 14)
New("UIStroke", { Color = C.Accent, Thickness = 1.5, Transparency = 0.2 }, Main)

-- Header
local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = C.Header,
    BorderSizePixel = 0,
    Active = true,
}, Main)
Round(Header, 14)
New("Frame", { -- che góc bo phía dưới của header
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = C.Header,
    BorderSizePixel = 0,
}, Header)

New("TextLabel", {
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = "🌊 SEA SEA",
    TextColor3 = C.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local Min = New("TextButton", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1, -40, 0.5, -16),
    BackgroundColor3 = Color3.fromRGB(0, 70, 120),
    Text = "—",
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.Text,
}, Header)
Round(Min, 8)

-- Vùng cuộn
local Scroll = New("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 50),
    Size = UDim2.new(1, 0, 1, -54),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.Accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, Main)
New("UIPadding", {
    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10),
    PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8),
}, Scroll)
New("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Scroll)

--==================================================
-- THÀNH PHẦN UI TÁI SỬ DỤNG
--==================================================

local function Section(title)
    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.Card,
        BorderSizePixel = 0,
        LayoutOrder = NextOrder(Scroll),
    }, Scroll)
    Round(card, 10)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
    }, card)
    New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, card)
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = NextOrder(card),
    }, card)
    return card
end

local function Label(parent, text)
    return New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Sub,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = NextOrder(parent),
    }, parent)
end

local function Row(parent)
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = NextOrder(parent),
    }, parent)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, row)
    return row
end

local function CellSize(n)
    return UDim2.new(1 / n, -6 * (n - 1) / n, 1, 0)
end

local function Btn(row, n, text, callback, color)
    local b = New("TextButton", {
        Size = CellSize(n),
        BackgroundColor3 = color or C.Btn,
        Text = text,
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextWrapped = true,
        LayoutOrder = NextOrder(row),
    }, row)
    Round(b, 8)
    Connect(b.Activated, callback)
    return b
end

local function Input(row, n, default, placeholder)
    local t = New("TextBox", {
        Size = CellSize(n),
        BackgroundColor3 = C.Input,
        TextColor3 = C.Text,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Color3.fromRGB(120, 150, 170),
        Text = tostring(default),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ClearTextOnFocus = false,
        LayoutOrder = NextOrder(row),
    }, row)
    Round(t, 8)
    return t
end

local function Toggle(parent, text, initial, callback)
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = C.Btn,
        BorderSizePixel = 0,
        LayoutOrder = NextOrder(parent),
    }, parent)
    Round(f, 8)
    New("TextLabel", {
        Size = UDim2.new(1, -62, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)

    local pill = New("Frame", {
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = C.Off,
        BorderSizePixel = 0,
    }, f)
    Round(pill, 10)
    local knob = New("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = C.Text,
        BorderSizePixel = 0,
    }, pill)
    Round(knob, 8)

    local hit = New("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
    }, f)

    local state = false
    local function set(v, silent)
        state = v
        local info = TweenInfo.new(0.15)
        TweenService:Create(pill, info, { BackgroundColor3 = v and C.On or C.Off }):Play()
        TweenService:Create(knob, info, {
            Position = v and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
        }):Play()
        if not silent then callback(v) end
    end
    Connect(hit.Activated, function() set(not state) end)
    set(initial, true)
    return set
end

--==================================================
-- HUD HIỂN THỊ TRÊN MÀN HÌNH GAME
--==================================================

local HUD = New("Frame", {
    Name = "SeaSeaHUD",
    Size = UDim2.fromOffset(0, 0),
    AutomaticSize = Enum.AutomaticSize.XY,
    Position = UDim2.fromOffset(10, 65),
    BackgroundColor3 = C.Bg,
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
    Visible = false,
}, Gui)
Round(HUD, 9)

New("UIPadding", {
    PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
}, HUD)

New("UIListLayout", {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, HUD)

local function HUDLabel(name, order, text)
    return New("TextLabel", {
        Name = name,
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Text,
        TextStrokeTransparency = 0.5,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
        Visible = false,
    }, HUD)
end

local HUD_FPS = HUDLabel("FPS", 1, "FPS: --")
local HUD_Coord = HUDLabel("Coordinates", 2, "XYZ: --")
local HUD_Elevator = HUDLabel("Elevator", 3, "🛗 --")

-- Mũi tên trên màn hình chỉ về tọa độ thang máy đã lưu
local WaypointArrow = New("TextLabel", {
    Name = "SEA_SEA_WaypointArrow",
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.new(0.5, -27, 0, 82),
    BackgroundTransparency = 1,
    Text = "▲",
    TextColor3 = Color3.fromRGB(255, 220, 0),
    TextStrokeColor3 = Color3.new(0, 0, 0),
    TextStrokeTransparency = 0,
    Font = Enum.Font.GothamBlack,
    TextSize = 42,
    Visible = false,
    ZIndex = 20,
}, Gui)

local WaypointHint = New("TextLabel", {
    Name = "SEA_SEA_WaypointHint",
    Size = UDim2.fromOffset(210, 24),
    Position = UDim2.new(0.5, -105, 0, 132),
    BackgroundColor3 = C.Bg,
    BackgroundTransparency = 0.2,
    Text = "THANG MÁY • -- studs",
    TextColor3 = Color3.fromRGB(255, 230, 100),
    TextStrokeTransparency = 0.5,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    Visible = false,
    ZIndex = 20,
}, Gui)
Round(WaypointHint, 7)

local function RefreshHUD()
    HUD_FPS.Visible = FPSOn
    HUD_Coord.Visible = CoordsOn
    HUD_Elevator.Visible = SavedElevatorPosition ~= nil
    HUD.Visible = FPSOn or CoordsOn or SavedElevatorPosition ~= nil
    local showWaypoint = SavedElevatorPosition ~= nil and ElevatorESPOn
    WaypointArrow.Visible = showWaypoint
    WaypointHint.Visible = showWaypoint
end

--==================================================
-- TỐC ĐỘ
--==================================================

local SpeedCard = Section("⚡ TỐC ĐỘ")
local SpeedText = Label(SpeedCard, "Hiện tại: 16")

local function SetSpeed(v)
    Speed = math.clamp(v, 0, 100)
    SpeedText.Text = "Hiện tại: " .. Speed
    ApplySpeed()
end

local SpeedRow = Row(SpeedCard)
local SpeedInput = Input(SpeedRow, 3, 16, "Speed")

local function ApplySpeedInput()
    local v = tonumber(SpeedInput.Text)
    if v and v >= 0 and v <= 100 then
        SetSpeed(v)
    end
    SpeedInput.Text = tostring(Speed)
end

Btn(SpeedRow, 3, "✔ Áp dụng", ApplySpeedInput, C.BtnMain)
Btn(SpeedRow, 3, "↺ 16", function()
    SetSpeed(16)
    SpeedInput.Text = "16"
end)
Connect(SpeedInput.FocusLost, function(enter)
    if enter then ApplySpeedInput() end
end)

local SpeedStep = Row(SpeedCard)
Btn(SpeedStep, 2, "➖ Giảm (-4)", function()
    SetSpeed(Speed - 4)
    SpeedInput.Text = tostring(Speed)
end)
Btn(SpeedStep, 2, "➕ Tăng (+4)", function()
    SetSpeed(Speed + 4)
    SpeedInput.Text = tostring(Speed)
end)

--==================================================
-- NHẢY
--==================================================

local JumpCard = Section("⬆️ ĐỘ CAO NHẢY")
local JumpText = Label(JumpCard, "JumpPower: 50")

local function SetJump(v)
    JumpPower = math.clamp(v, 0, 300)
    JumpText.Text = "JumpPower: " .. JumpPower
    ApplyJump()
end

local JumpRow = Row(JumpCard)
local JumpInput = Input(JumpRow, 3, 50, "Jump")

local function ApplyJumpInput()
    local v = tonumber(JumpInput.Text)
    if v and v >= 0 and v <= 300 then
        SetJump(v)
    end
    JumpInput.Text = tostring(JumpPower)
end

Btn(JumpRow, 3, "✔ Áp dụng", ApplyJumpInput, C.BtnMain)
Btn(JumpRow, 3, "↺ 50", function()
    SetJump(50)
    JumpInput.Text = "50"
end)
Connect(JumpInput.FocusLost, function(enter)
    if enter then ApplyJumpInput() end
end)

--==================================================
-- ÁNH SÁNG / FULLBRIGHT
--==================================================

local LightCard = Section("☀️ ÁNH SÁNG")

local Original = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation,
}

-- Lưu thông số Atmosphere để có thể khôi phục đúng trạng thái ban đầu
local OriginalAtmospheres = {}
for _, obj in ipairs(Lighting:GetDescendants()) do
    if obj:IsA("Atmosphere") then
        table.insert(OriginalAtmospheres, {
            Object = obj,
            Density = obj.Density,
            Haze = obj.Haze,
            Glare = obj.Glare,
        })
    end
end

local BrightnessValue = 10
local FullbrightCorrection = nil

local function RestoreLighting()
    Lighting.Brightness = Original.Brightness
    Lighting.GlobalShadows = Original.GlobalShadows
    Lighting.Ambient = Original.Ambient
    Lighting.OutdoorAmbient = Original.OutdoorAmbient
    Lighting.FogEnd = Fog and 100000 or Original.FogEnd
    Lighting.ExposureCompensation = Original.ExposureCompensation

    for _, saved in ipairs(OriginalAtmospheres) do
        if saved.Object and saved.Object.Parent then
            saved.Object.Density = Fog and 0 or saved.Density
            saved.Object.Haze = Fog and 0 or saved.Haze
            saved.Object.Glare = Fog and 0 or saved.Glare
        end
    end

    if FullbrightCorrection then
        FullbrightCorrection:Destroy()
        FullbrightCorrection = nil
    end
end

local function ApplyBrightness()
    if not Bright then return end

    Lighting.Brightness = BrightnessValue
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    Lighting.ExposureCompensation = math.clamp(Original.ExposureCompensation + 1, -5, 5)

    -- Tăng sáng nhẹ bằng hiệu ứng riêng, không sửa các ColorCorrectionEffect của game
    if not FullbrightCorrection then
        FullbrightCorrection = Instance.new("ColorCorrectionEffect")
        FullbrightCorrection.Name = "SEA_SEA_FullbrightCorrection"
        FullbrightCorrection.Parent = Lighting
    end
    FullbrightCorrection.Brightness = 0.12
    FullbrightCorrection.Contrast = 0
    FullbrightCorrection.Saturation = 0.05
end

local function ApplyFog()
    Lighting.FogEnd = Fog and 100000 or Original.FogEnd
    for _, saved in ipairs(OriginalAtmospheres) do
        if saved.Object and saved.Object.Parent then
            saved.Object.Density = Fog and 0 or saved.Density
            saved.Object.Haze = Fog and 0 or saved.Haze
            saved.Object.Glare = Fog and 0 or saved.Glare
        end
    end
end

local BrightnessText = Label(LightCard, "Độ sáng: 10 / 10")
local BrightnessRow = Row(LightCard)
local BrightnessInput = Input(BrightnessRow, 3, 10, "0 - 10")

local function SetBrightness(value)
    BrightnessValue = math.clamp(value, 0, 10)
    BrightnessText.Text = "Độ sáng: " .. tostring(BrightnessValue) .. " / 10"
    if Bright then ApplyBrightness() end
end

local function ApplyBrightnessInput()
    local value = tonumber(BrightnessInput.Text)
    if value and value >= 0 and value <= 10 then
        SetBrightness(value)
    end
    BrightnessInput.Text = tostring(BrightnessValue)
end

Btn(BrightnessRow, 3, "✔ Áp dụng", ApplyBrightnessInput, C.BtnMain)
Btn(BrightnessRow, 3, "↺ 10", function()
    SetBrightness(10)
    BrightnessInput.Text = "10"
end)
Connect(BrightnessInput.FocusLost, function(enter)
    if enter then ApplyBrightnessInput() end
end)

Toggle(LightCard, "☀️ Fullbright", false, function(on)
    Bright = on
    if on then
        ApplyBrightness()
    else
        RestoreLighting()
    end
end)

Toggle(LightCard, "🌫️ Tắt sương mù", false, function(on)
    Fog = on
    ApplyFog()
end)

--==================================================
-- ĐỊNH VỊ THANG MÁY
--==================================================

local ElevCard = Section("🛗 ĐỊNH VỊ THANG MÁY")
local ElevatorStatus = Label(ElevCard, "Thang máy: Chưa lưu")

local function RemoveElevatorMarker()
    if ElevatorMarker then
        ElevatorMarker:Destroy()
        ElevatorMarker = nil
    end
    if ElevatorBillboard then
        ElevatorBillboard:Destroy()
        ElevatorBillboard = nil
    end
    ElevatorHighlight = nil
end

local function CreateElevatorMarker()
    RemoveElevatorMarker()
    if not SavedElevatorPosition then return end

    local marker = New("Part", {
        Name = "SEA_SEA_ElevatorMarker",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(7, 7, 7),
        CFrame = CFrame.new(SavedElevatorPosition),
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(255, 210, 0),
        Transparency = ElevatorESPOn and 0.1 or 1,
    }, workspace)
    ElevatorMarker = marker

    ElevatorHighlight = New("Highlight", {
        Name = "SEA_SEA_ElevatorHighlight",
        Adornee = marker,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        FillColor = Color3.fromRGB(255, 200, 0),
        OutlineColor = Color3.fromRGB(255, 255, 150),
        FillTransparency = 0.15,
        OutlineTransparency = 0,
        Enabled = ElevatorESPOn,
    }, marker)

    local billboard = New("BillboardGui", {
        Name = "SEA_SEA_ElevatorLabel",
        Adornee = marker,
        Size = UDim2.fromOffset(220, 55),
        StudsOffset = Vector3.new(0, 5, 0),
        AlwaysOnTop = true,
        Enabled = ElevatorESPOn,
    }, PlayerGui)
    New("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "📍 THANG MÁY",
        TextColor3 = Color3.fromRGB(255, 220, 0),
        TextStrokeColor3 = Color3.new(0, 0, 0),
        TextStrokeTransparency = 0,
        Font = Enum.Font.GothamBold,
        TextScaled = true,
    }, billboard)
    ElevatorBillboard = billboard
end

local ElevRow = Row(ElevCard)
Btn(ElevRow, 2, "📌 Lưu vị trí", function()
    local root = Root()
    if not root then
        ElevatorStatus.Text = "Không tìm thấy nhân vật"
        return
    end
    SavedElevatorPosition = root.Position
    CreateElevatorMarker()
    ElevatorStatus.Text = "Thang máy: 0.0 studs"
    HUD_Elevator.Text = "🛗 0 studs"
    RefreshHUD()
end, C.BtnMain)
Btn(ElevRow, 2, "✖ Xóa vị trí", function()
    SavedElevatorPosition = nil
    RemoveElevatorMarker()
    ElevatorStatus.Text = "Thang máy: Chưa lưu"
    RefreshHUD()
end, C.Danger)

Toggle(ElevCard, "👁️ Hiện định vị", true, function(on)
    ElevatorESPOn = on
    if ElevatorHighlight then ElevatorHighlight.Enabled = on end
    if ElevatorBillboard then ElevatorBillboard.Enabled = on end
    if ElevatorMarker then ElevatorMarker.Transparency = on and 0.1 or 1 end
end)

--==================================================
-- THÔNG TIN (điều khiển HUD)
--==================================================

local InfoCard = Section("📊 THÔNG TIN")

Toggle(InfoCard, "📊 Hiện FPS", false, function(on)
    FPSOn = on
    HUD_FPS.Text = "FPS: --"
    HUD_FPS.TextColor3 = C.Text
    RefreshHUD()
end)
Toggle(InfoCard, "📍 Hiện tọa độ", false, function(on)
    CoordsOn = on
    RefreshHUD()
end)

--==================================================
-- KÉO THẢ (CHẠM + CHUỘT) + NÚT NỔI
--==================================================

local function MakeDraggable(handle, target, onTap)
    local dragging, moved = false, false
    local track, startPos, startObj

    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, moved = true, false
            track = input
            startPos = input.Position
            startObj = target.Position

            local ender
            ender = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    ender:Disconnect()
                    if dragging then
                        dragging = false
                        if not moved and onTap then onTap() end
                    end
                end
            end)
        end
    end)

    Connect(UIS.InputChanged, function(input)
        if dragging and (input == track
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = input.Position - startPos
            if d.Magnitude > 6 then moved = true end
            if moved then
                local vp = workspace.CurrentCamera.ViewportSize
                local sz = target.AbsoluteSize
                local x = math.clamp(startObj.X.Offset + d.X, 0, math.max(vp.X - sz.X, 0))
                local y = math.clamp(startObj.Y.Offset + d.Y, 0, math.max(vp.Y - sz.Y, 0))
                target.Position = UDim2.fromOffset(x, y)
            end
        end
    end)
end

local Floating = New("TextButton", {
    Size = UDim2.fromOffset(52, 52),
    Position = UDim2.fromOffset(12, Viewport.Y * 0.5),
    Text = "🌊",
    TextSize = 26,
    BackgroundColor3 = C.Header,
    TextColor3 = C.Text,
    AutoButtonColor = false,
    Visible = false,
}, Gui)
Round(Floating, 26)
New("UIStroke", { Color = C.Accent, Thickness = 2 }, Floating)

Connect(Min.Activated, function()
    Main.Visible = false
    Floating.Visible = true
end)

MakeDraggable(Header, Main)
MakeDraggable(Floating, Floating, function()
    Main.Visible = true
    Floating.Visible = false
end)

--==================================================
-- CẬP NHẬT LIVE
--==================================================

local Frames = 0
local LastTime = os.clock()
local LastSlow = 0

Connect(RunService.RenderStepped, function()
    local now = os.clock()

    if FPSOn then
        Frames += 1
        if now - LastTime >= 1 then
            HUD_FPS.Text = "FPS: " .. Frames
            HUD_FPS.TextColor3 = Frames >= 50 and C.On
                or Frames >= 30 and Color3.fromRGB(255, 200, 60)
                or Color3.fromRGB(255, 90, 90)
            Frames = 0
            LastTime = now
        end
    end

    -- Phần còn lại cập nhật 4 lần/giây cho nhẹ máy
    if now - LastSlow < 0.25 then return end
    LastSlow = now

    RefreshHUD()

    local root = Root()
    if not root then return end

    if CoordsOn then
        local p = root.Position
        HUD_Coord.Text = string.format("XYZ: %.0f, %.0f, %.0f", p.X, p.Y, p.Z)
    end

    if SavedElevatorPosition then
        local offset = SavedElevatorPosition - root.Position
        local dist = offset.Magnitude
        HUD_Elevator.Text = string.format("🛗 %.0f studs", dist)
        ElevatorStatus.Text = string.format("Thang máy: %.1f studs", dist)
        WaypointHint.Text = string.format("THANG MÁY • %.0f studs", dist)

        -- Xoay mũi tên theo hướng điểm đã lưu so với hướng camera
        local camera = workspace.CurrentCamera
        local flatOffset = Vector3.new(offset.X, 0, offset.Z)
        if camera and flatOffset.Magnitude > 0.01 and ElevatorESPOn then
            local direction = flatOffset.Unit
            local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
            local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
            if look.Magnitude > 0.01 and right.Magnitude > 0.01 then
                local rightDot = direction:Dot(right.Unit)
                local forwardDot = direction:Dot(look.Unit)
                WaypointArrow.Rotation = math.deg(math.atan2(rightDot, forwardDot))
            end
        end
    end
end)

--==================================================
-- HỒI SINH
--==================================================

Connect(Player.CharacterAdded, function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    ApplySpeed()
    ApplyJump()
end)

--==================================================
-- DỌN DẸP (khi chạy lại script)
--==================================================

_G.SeaSeaCleanup = function()
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    RemoveElevatorMarker()
    if Bright or Fog then RestoreLighting() end
    if Gui then Gui:Destroy() end
end

print("🌊 SEA SEA MOBILE V4.1 đã khởi động!")
