--[[
	RedlineUI
	A standalone, modern dark UI library for Roblox (single-file).
	Theme: dark background with deep red accents, Lucide-style vector icons,
	smooth tween-based animations, mobile + desktop support.

	This file contains NO game-specific logic. It is a generic UI toolkit:
	Window, Tabs, Toggle, Button, Slider, Dropdown, ColorPicker, Input,
	Keybind, Notifications, a confirmation modal on close, and a draggable
	minimized "orb" state.

	Usage (from your own project):
		local RedlineUI = loadstring(game:HttpGet("..."))() -- or require(...)
		local Window = RedlineUI:CreateWindow({ Title = "My App" })
		local Tab = Window:CreateTab({ Title = "Main", Icon = "home" })
		Tab:CreateButton({ Title = "Click me", Callback = function() end })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local RedlineUI = {}
RedlineUI.__index = RedlineUI

----------------------------------------------------------------
-- THEME
----------------------------------------------------------------

RedlineUI.Theme = {
	-- Backgrounds
	Background      = Color3.fromRGB(15, 13, 14),     -- main window bg, near-black
	Elevated         = Color3.fromRGB(22, 18, 19),     -- cards / panels
	ElevatedHover    = Color3.fromRGB(28, 22, 23),
	Sidebar          = Color3.fromRGB(11, 10, 10),     -- darkest, for sidebar/tab rail
	Stroke           = Color3.fromRGB(40, 30, 31),
	StrokeLight      = Color3.fromRGB(55, 38, 40),

	-- Accent (deep red)
	Accent           = Color3.fromRGB(176, 32, 42),    -- primary deep red
	AccentHover      = Color3.fromRGB(199, 44, 54),
	AccentMuted      = Color3.fromRGB(90, 24, 30),
	AccentGlow       = Color3.fromRGB(255, 70, 80),

	-- Text
	Text             = Color3.fromRGB(235, 230, 230),
	TextDim          = Color3.fromRGB(160, 150, 150),
	TextFaint        = Color3.fromRGB(110, 100, 100),

	-- Status
	Success          = Color3.fromRGB(70, 190, 120),
	Warning          = Color3.fromRGB(230, 170, 60),
	Error            = Color3.fromRGB(220, 70, 70),
	Info             = Color3.fromRGB(90, 150, 220),

	Font             = Enum.Font.GothamMedium,
	FontBold         = Enum.Font.GothamBold,
	FontSemibold     = Enum.Font.GothamSemibold,

	CornerRadius     = UDim.new(0, 10),
	CornerRadiusSm   = UDim.new(0, 6),
}

----------------------------------------------------------------
-- ICON MAP (Lucide-style icon glyphs rendered via vector paths)
-- We use a lightweight approach: each icon is drawn from simple
-- shapes (frames/UICorner/rotations) composed at runtime, matching
-- Lucide's minimal line-icon aesthetic without requiring external
-- image assets.
----------------------------------------------------------------

local Icons = {}
RedlineUI.Icons = Icons

local function newStroke(parent, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1.6
	s.Color = color or RedlineUI.Theme.Text
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function newCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or RedlineUI.Theme.CornerRadiusSm
	c.Parent = parent
	return c
end

-- Generic icon canvas: returns a Frame sized to `size` you can parent
-- icon primitives into. Each icon-builder function receives this frame.
local function iconCanvas(size)
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(size, size)
	f.BackgroundTransparency = 1
	return f
end

-- line: a thin rotated frame acting as a stroke segment
local function iconLine(parent, x1, y1, x2, y2, color, thickness)
	local dx, dy = x2 - x1, y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)
	local angle = math.atan2(dy, dx)

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.fromOffset(x1, y1)
	line.Size = UDim2.fromOffset(length, thickness or 1.6)
	line.Rotation = math.deg(angle)
	line.BackgroundColor3 = color or RedlineUI.Theme.Text
	line.BorderSizePixel = 0
	newCorner(line, UDim.new(1, 0))
	line.Parent = parent
	return line
end

local function iconCircle(parent, cx, cy, radius, color, filled, thickness)
	local circle = Instance.new("Frame")
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromOffset(cx, cy)
	circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
	circle.BackgroundColor3 = color or RedlineUI.Theme.Text
	circle.BackgroundTransparency = filled and 0 or 1
	circle.BorderSizePixel = 0
	newCorner(circle, UDim.new(1, 0))
	if not filled then
		newStroke(circle, thickness or 1.6, color)
	end
	circle.Parent = parent
	return circle
end

local function iconRect(parent, x, y, w, h, color, radius, filled, thickness)
	local rect = Instance.new("Frame")
	rect.Position = UDim2.fromOffset(x, y)
	rect.Size = UDim2.fromOffset(w, h)
	rect.BackgroundColor3 = color or RedlineUI.Theme.Text
	rect.BackgroundTransparency = filled and 0 or 1
	rect.BorderSizePixel = 0
	newCorner(rect, UDim.new(0, radius or 2))
	if not filled then
		newStroke(rect, thickness or 1.6, color)
	end
	rect.Parent = parent
	return rect
end

-- Icon definitions (18x18 grid, Lucide-like proportions)
Icons.Definitions = {
	home = function(color)
		local c = iconCanvas(18)
		iconLine(c, 2, 9, 9, 2.5, color, 1.6)
		iconLine(c, 9, 2.5, 16, 9, color, 1.6)
		iconRect(c, 4, 9, 10, 7, color, 1, false, 1.6)
		iconRect(c, 7.5, 11.5, 3, 4.5, color, 1, false, 1.6)
		return c
	end,
	settings = function(color)
		local c = iconCanvas(18)
		iconCircle(c, 9, 9, 2.6, color, false, 1.6)
		for i = 0, 5 do
			local angle = math.rad(i * 60)
			local x1 = 9 + math.cos(angle) * 5.4
			local y1 = 9 + math.sin(angle) * 5.4
			local x2 = 9 + math.cos(angle) * 7.4
			local y2 = 9 + math.sin(angle) * 7.4
			iconLine(c, x1, y1, x2, y2, color, 1.6)
		end
		return c
	end,
	user = function(color)
		local c = iconCanvas(18)
		iconCircle(c, 9, 6, 3.2, color, false, 1.6)
		iconRect(c, 3, 11, 12, 6, color, 6, false, 1.6)
		return c
	end,
	bell = function(color)
		local c = iconCanvas(18)
		iconRect(c, 6.5, 2.5, 5, 5, color, 5, false, 1.6) -- placeholder top arc via rounded rect
		iconLine(c, 4.5, 6, 4.5, 11, color, 1.6)
		iconLine(c, 13.5, 6, 13.5, 11, color, 1.6)
		iconLine(c, 4.5, 11, 13.5, 11, color, 1.6)
		iconLine(c, 3, 13.2, 15, 13.2, color, 1.6)
		iconCircle(c, 9, 15.4, 1.3, color, true)
		return c
	end,
	x = function(color)
		local c = iconCanvas(18)
		iconLine(c, 4, 4, 14, 14, color, 1.8)
		iconLine(c, 14, 4, 4, 14, color, 1.8)
		return c
	end,
	check = function(color)
		local c = iconCanvas(18)
		iconLine(c, 3.5, 9.5, 7, 13.5, color, 1.8)
		iconLine(c, 7, 13.5, 14.5, 4.5, color, 1.8)
		return c
	end,
	chevronDown = function(color)
		local c = iconCanvas(18)
		iconLine(c, 4, 6.5, 9, 12, color, 1.7)
		iconLine(c, 9, 12, 14, 6.5, color, 1.7)
		return c
	end,
	chevronUp = function(color)
		local c = iconCanvas(18)
		iconLine(c, 4, 11.5, 9, 6, color, 1.7)
		iconLine(c, 9, 6, 14, 11.5, color, 1.7)
		return c
	end,
	minus = function(color)
		local c = iconCanvas(18)
		iconLine(c, 4, 9, 14, 9, color, 1.8)
		return c
	end,
	search = function(color)
		local c = iconCanvas(18)
		iconCircle(c, 8, 8, 4.5, color, false, 1.6)
		iconLine(c, 11.3, 11.3, 15.5, 15.5, color, 1.8)
		return c
	end,
	sliders = function(color)
		local c = iconCanvas(18)
		iconLine(c, 4, 3, 4, 15, color, 1.6)
		iconLine(c, 9, 3, 9, 15, color, 1.6)
		iconLine(c, 14, 3, 14, 15, color, 1.6)
		iconCircle(c, 4, 6, 1.7, color, true)
		iconCircle(c, 9, 11, 1.7, color, true)
		iconCircle(c, 14, 8, 1.7, color, true)
		return c
	end,
	palette = function(color)
		local c = iconCanvas(18)
		iconCircle(c, 9, 9, 6.5, color, false, 1.6)
		iconCircle(c, 6.2, 7, 1.1, color, true)
		iconCircle(c, 9, 5, 1.1, color, true)
		iconCircle(c, 12, 7, 1.1, color, true)
		iconCircle(c, 11.4, 11.6, 1.1, color, true)
		return c
	end,
	keyboard = function(color)
		local c = iconCanvas(18)
		iconRect(c, 2.5, 5, 13, 8, color, 2, false, 1.6)
		iconRect(c, 4.5, 7.2, 1.4, 1.4, color, 1, true)
		iconRect(c, 7, 7.2, 1.4, 1.4, color, 1, true)
		iconRect(c, 9.5, 7.2, 1.4, 1.4, color, 1, true)
		iconRect(c, 12, 7.2, 1.4, 1.4, color, 1, true)
		iconRect(c, 4.5, 9.8, 9, 1.4, color, 1, true)
		return c
	end,
	type = function(color)
		local c = iconCanvas(18)
		iconLine(c, 4, 4, 14, 4, color, 1.6)
		iconLine(c, 9, 4, 9, 14, color, 1.6)
		iconLine(c, 6.5, 14, 11.5, 14, color, 1.6)
		return c
	end,
	info = function(color)
		local c = iconCanvas(18)
		iconCircle(c, 9, 9, 7, color, false, 1.6)
		iconCircle(c, 9, 5.6, 0.9, color, true)
		iconLine(c, 9, 8, 9, 13, color, 1.7)
		return c
	end,
	alertTriangle = function(color)
		local c = iconCanvas(18)
		iconLine(c, 9, 2.5, 2, 15, color, 1.7)
		iconLine(c, 9, 2.5, 16, 15, color, 1.7)
		iconLine(c, 2, 15, 16, 15, color, 1.7)
		iconLine(c, 9, 6.5, 9, 10.5, color, 1.6)
		iconCircle(c, 9, 12.8, 0.8, color, true)
		return c
	end,
	checkCircle = function(color)
		local c = iconCanvas(18)
		iconCircle(c, 9, 9, 7, color, false, 1.6)
		iconLine(c, 5.5, 9.3, 8, 12, color, 1.7)
		iconLine(c, 8, 12, 13, 6.5, color, 1.7)
		return c
	end,
	xCircle = function(color)
		local c = iconCanvas(18)
		iconCircle(c, 9, 9, 7, color, false, 1.6)
		iconLine(c, 6, 6, 12, 12, color, 1.6)
		iconLine(c, 12, 6, 6, 12, color, 1.6)
		return c
	end,
	logOut = function(color)
		local c = iconCanvas(18)
		iconRect(c, 3, 3, 7, 12, color, 2, false, 1.6)
		iconLine(c, 8, 9, 16, 9, color, 1.6)
		iconLine(c, 12.5, 5.5, 16, 9, color, 1.6)
		iconLine(c, 12.5, 12.5, 16, 9, color, 1.6)
		return c
	end,
	pin = function(color)
		local c = iconCanvas(18)
		iconCircle(c, 9, 7, 4, color, false, 1.6)
		iconLine(c, 9, 11, 9, 16, color, 1.6)
		return c
	end,
}

function Icons.Create(name, color, size)
	local builder = Icons.Definitions[name]
	if not builder then
		builder = Icons.Definitions.info
	end
	local icon = builder(color or RedlineUI.Theme.Text)
	if size and size ~= 18 then
		local scale = size / 18
		icon.Size = UDim2.fromOffset(size, size)
		for _, child in ipairs(icon:GetChildren()) do
			-- scale offsets proportionally
			if child:IsA("Frame") then
				child.Position = UDim2.fromOffset(child.Position.X.Offset * scale, child.Position.Y.Offset * scale)
				child.Size = UDim2.fromOffset(child.Size.X.Offset * scale, child.Size.Y.Offset * scale)
			end
		end
	end
	return icon
end

----------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------

local function tween(obj, props, duration, style, direction)
	duration = duration or 0.18
	style = style or Enum.EasingStyle.Quint
	direction = direction or Enum.EasingDirection.Out
	local t = TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
	t:Play()
	return t
end

local function makeDraggable(handle, target, onDragStart, onDragEnd)
	local dragging = false
	local dragInput, mousePos, framePos

	local function update(input)
		local delta = input.Position - mousePos
		local newPos = UDim2.new(
			framePos.X.Scale, framePos.X.Offset + delta.X,
			framePos.Y.Scale, framePos.Y.Offset + delta.Y
		)
		target.Position = newPos
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			mousePos = input.Position
			framePos = target.Position
			if onDragStart then onDragStart() end

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if dragging then
						dragging = false
						if onDragEnd then onDragEnd() end
					end
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

local function getGui()
	local existing = CoreGui:FindFirstChild("RedlineUI_ScreenGui")
	if existing then
		existing:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "RedlineUI_ScreenGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999

	local ok = pcall(function()
		gui.Parent = CoreGui
	end)
	if not ok then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	return gui
end

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
end

----------------------------------------------------------------
-- ROOT GUI
----------------------------------------------------------------

local ScreenGui = getGui()
RedlineUI.ScreenGui = ScreenGui

----------------------------------------------------------------
-- NOTIFICATIONS
----------------------------------------------------------------

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "Notifications"
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.AnchorPoint = Vector2.new(1, 1)
NotificationHolder.Position = UDim2.new(1, -20, 1, -20)
NotificationHolder.Size = UDim2.fromOffset(320, 500)
NotificationHolder.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.Parent = NotificationHolder
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationLayout.Padding = UDim.new(0, 10)

local NOTIF_ICON = {
	success = "checkCircle",
	error = "xCircle",
	warning = "alertTriangle",
	info = "info",
}

local NOTIF_COLOR = {
	success = RedlineUI.Theme.Success,
	error = RedlineUI.Theme.Error,
	warning = RedlineUI.Theme.Warning,
	info = RedlineUI.Theme.Info,
}

function RedlineUI:Notify(opts)
	opts = opts or {}
	local kind = opts.Type or "info"
	local title = opts.Title or "Notification"
	local content = opts.Content or ""
	local duration = opts.Duration or 4

	local card = Instance.new("Frame")
	card.Name = "Notification"
	card.BackgroundColor3 = RedlineUI.Theme.Elevated
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ClipsDescendants = true
	card.LayoutOrder = -os.clock() * 1000
	card.Parent = NotificationHolder
	newCorner(card, RedlineUI.Theme.CornerRadius)
	local stroke = newStroke(card, 1, RedlineUI.Theme.Stroke)

	local accentBar = Instance.new("Frame")
	accentBar.BackgroundColor3 = NOTIF_COLOR[kind] or RedlineUI.Theme.Accent
	accentBar.BorderSizePixel = 0
	accentBar.Size = UDim2.new(0, 3, 1, 0)
	accentBar.Parent = card
	newCorner(accentBar, UDim.new(1, 0))

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 14)
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.Parent = card

	local iconWrap = Instance.new("Frame")
	iconWrap.BackgroundTransparency = 1
	iconWrap.Size = UDim2.fromOffset(20, 20)
	iconWrap.Position = UDim2.fromOffset(0, 1)
	iconWrap.Parent = card

	local icon = Icons.Create(NOTIF_ICON[kind] or "info", NOTIF_COLOR[kind] or RedlineUI.Theme.Accent, 20)
	icon.Parent = iconWrap

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = RedlineUI.Theme.FontBold
	titleLabel.Text = title
	titleLabel.TextColor3 = RedlineUI.Theme.Text
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Position = UDim2.fromOffset(32, 0)
	titleLabel.Size = UDim2.new(1, -32, 0, 18)
	titleLabel.Parent = card

	local contentLabel = Instance.new("TextLabel")
	contentLabel.BackgroundTransparency = 1
	contentLabel.Font = RedlineUI.Theme.Font
	contentLabel.Text = content
	contentLabel.TextColor3 = RedlineUI.Theme.TextDim
	contentLabel.TextSize = 13
	contentLabel.TextWrapped = true
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	contentLabel.Position = UDim2.fromOffset(32, 20)
	contentLabel.Size = UDim2.new(1, -32, 0, 0)
	contentLabel.AutomaticSize = Enum.AutomaticSize.Y
	contentLabel.Parent = card

	-- entrance animation
	card.Position = UDim2.fromOffset(40, 0)
	local targetTransparency = 0
	card.BackgroundTransparency = 1
	stroke.Transparency = 1
	tween(card, { BackgroundTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.22, Enum.EasingStyle.Back)
	tween(stroke, { Transparency = 0 }, 0.22)

	task.delay(duration, function()
		if not card or not card.Parent then return end
		local fade = tween(card, { BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 0) }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(stroke, { Transparency = 1 }, 0.2)
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("TextLabel") then
				tween(d, { TextTransparency = 1 }, 0.2)
			end
		end
		fade.Completed:Wait()
		card:Destroy()
	end)

	return card
end

----------------------------------------------------------------
-- CONFIRM MODAL (generic, reusable)
----------------------------------------------------------------

local ModalLayer = Instance.new("Frame")
ModalLayer.Name = "ModalLayer"
ModalLayer.BackgroundTransparency = 1
ModalLayer.Size = UDim2.fromScale(1, 1)
ModalLayer.Visible = false
ModalLayer.ZIndex = 1000
ModalLayer.Parent = ScreenGui

function RedlineUI:Confirm(opts)
	opts = opts or {}
	local title = opts.Title or "Are you sure?"
	local message = opts.Message or "This action cannot be undone."
	local confirmText = opts.ConfirmText or "Yes"
	local cancelText = opts.CancelText or "No"
	local onConfirm = opts.OnConfirm
	local onCancel = opts.OnCancel
	local danger = opts.Danger ~= false

	ModalLayer.Visible = true
	for _, c in ipairs(ModalLayer:GetChildren()) do c:Destroy() end

	local backdrop = Instance.new("Frame")
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.ZIndex = 1000
	backdrop.Parent = ModalLayer

	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.45)
	box.Size = UDim2.fromOffset(360, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.BackgroundColor3 = RedlineUI.Theme.Elevated
	box.ZIndex = 1001
	box.Parent = ModalLayer
	newCorner(box, RedlineUI.Theme.CornerRadius)
	local boxStroke = newStroke(box, 1, RedlineUI.Theme.StrokeLight)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 22)
	pad.PaddingBottom = UDim.new(0, 18)
	pad.PaddingLeft = UDim.new(0, 22)
	pad.PaddingRight = UDim.new(0, 22)
	pad.Parent = box

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 14)
	layout.Parent = box

	local iconRow = Instance.new("Frame")
	iconRow.BackgroundTransparency = 1
	iconRow.Size = UDim2.new(1, 0, 0, 40)
	iconRow.LayoutOrder = 1
	iconRow.Parent = box

	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.fromOffset(40, 40)
	iconBg.BackgroundColor3 = danger and RedlineUI.Theme.AccentMuted or RedlineUI.Theme.Elevated
	iconBg.Parent = iconRow
	newCorner(iconBg, RedlineUI.Theme.CornerRadiusSm)

	local iconInner = Icons.Create(danger and "alertTriangle" or "info", danger and RedlineUI.Theme.AccentGlow or RedlineUI.Theme.Info, 20)
	iconInner.AnchorPoint = Vector2.new(0.5, 0.5)
	iconInner.Position = UDim2.fromScale(0.5, 0.5)
	iconInner.Parent = iconBg

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = RedlineUI.Theme.FontBold
	titleLabel.Text = title
	titleLabel.TextColor3 = RedlineUI.Theme.Text
	titleLabel.TextSize = 17
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Size = UDim2.new(1, 0, 0, 22)
	titleLabel.LayoutOrder = 2
	titleLabel.Parent = box

	local messageLabel = Instance.new("TextLabel")
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = RedlineUI.Theme.Font
	messageLabel.Text = message
	messageLabel.TextColor3 = RedlineUI.Theme.TextDim
	messageLabel.TextSize = 14
	messageLabel.TextWrapped = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.Size = UDim2.new(1, 0, 0, 0)
	messageLabel.AutomaticSize = Enum.AutomaticSize.Y
	messageLabel.LayoutOrder = 3
	messageLabel.Parent = box

	local btnRow = Instance.new("Frame")
	btnRow.BackgroundTransparency = 1
	btnRow.Size = UDim2.new(1, 0, 0, 38)
	btnRow.LayoutOrder = 4
	btnRow.Parent = box

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.Padding = UDim.new(0, 10)
	btnLayout.Parent = btnRow

	local function closeModal()
		tween(backdrop, { BackgroundTransparency = 1 }, 0.18)
		tween(box, { Position = UDim2.fromScale(0.5, 0.47) }, 0.16)
		for _, d in ipairs(box:GetDescendants()) do
			if d:IsA("TextLabel") then tween(d, { TextTransparency = 1 }, 0.14) end
		end
		tween(box, { BackgroundTransparency = 1 }, 0.16)
		task.delay(0.18, function()
			ModalLayer.Visible = false
		end)
	end

	local function makeButton(text, isPrimary)
		local btn = Instance.new("TextButton")
		btn.AutoButtonColor = false
		btn.Font = RedlineUI.Theme.FontSemibold
		btn.Text = text
		btn.TextSize = 14
		btn.TextColor3 = isPrimary and Color3.new(1, 1, 1) or RedlineUI.Theme.Text
		btn.BackgroundColor3 = isPrimary and RedlineUI.Theme.Accent or RedlineUI.Theme.Elevated
		btn.Size = UDim2.fromOffset(90, 36)
		btn.Parent = btnRow
		newCorner(btn, RedlineUI.Theme.CornerRadiusSm)
		if not isPrimary then
			newStroke(btn, 1, RedlineUI.Theme.Stroke)
		end

		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundColor3 = isPrimary and RedlineUI.Theme.AccentHover or RedlineUI.Theme.ElevatedHover }, 0.12)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundColor3 = isPrimary and RedlineUI.Theme.Accent or RedlineUI.Theme.Elevated }, 0.12)
		end)
		return btn
	end

	local cancelBtn = makeButton(cancelText, false)
	local confirmBtn = makeButton(confirmText, true)

	confirmBtn.MouseButton1Click:Connect(function()
		closeModal()
		if onConfirm then onConfirm() end
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		closeModal()
		if onCancel then onCancel() end
	end)

	-- entrance
	backdrop.BackgroundTransparency = 1
	box.BackgroundTransparency = 1
	boxStroke.Transparency = 1
	box.Position = UDim2.fromScale(0.5, 0.47)
	for _, d in ipairs(box:GetDescendants()) do
		if d:IsA("TextLabel") then d.TextTransparency = 1 end
	end

	tween(backdrop, { BackgroundTransparency = 0.45 }, 0.2)
	tween(box, { BackgroundTransparency = 0, Position = UDim2.fromScale(0.5, 0.45) }, 0.22, Enum.EasingStyle.Back)
	tween(boxStroke, { Transparency = 0 }, 0.22)
	for _, d in ipairs(box:GetDescendants()) do
		if d:IsA("TextLabel") then tween(d, { TextTransparency = 0 }, 0.2) end
	end
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------

function RedlineUI:CreateWindow(opts)
	opts = opts or {}
	local title = opts.Title or "Redline"
	local subtitle = opts.Subtitle or ""
	local size = opts.Size or (isMobile() and UDim2.fromOffset(360, 480) or UDim2.fromOffset(620, 420))

	local Window = {}
	Window.Tabs = {}
	Window._tabButtons = {}

	-- Backdrop blur-ish dim layer not needed; window floats freely.

	local Main = Instance.new("Frame")
	Main.Name = "Window"
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.Position = UDim2.fromScale(0.5, 0.5)
	Main.Size = size
	Main.BackgroundColor3 = RedlineUI.Theme.Background
	Main.ClipsDescendants = true
	Main.Parent = ScreenGui
	newCorner(Main, RedlineUI.Theme.CornerRadius)
	newStroke(Main, 1, RedlineUI.Theme.Stroke)

	-- subtle drop shadow via ImageLabel
	local shadow = Instance.new("ImageLabel")
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.55
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.fromScale(0.5, 0.52)
	shadow.Size = UDim2.new(1, 60, 1, 60)
	shadow.BackgroundTransparency = 1
	shadow.ZIndex = -1
	shadow.Parent = Main

	----------------------------------------------------------------
	-- TOP BAR
	----------------------------------------------------------------
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.BackgroundColor3 = RedlineUI.Theme.Sidebar
	TopBar.Size = UDim2.new(1, 0, 0, 44)
	TopBar.Parent = Main
	newCorner(TopBar, RedlineUI.Theme.CornerRadius)

	-- mask bottom corners of topbar square
	local topBarMask = Instance.new("Frame")
	topBarMask.BackgroundColor3 = RedlineUI.Theme.Sidebar
	topBarMask.BorderSizePixel = 0
	topBarMask.Position = UDim2.new(0, 0, 1, -10)
	topBarMask.Size = UDim2.new(1, 0, 0, 10)
	topBarMask.Parent = TopBar

	local accentDot = Instance.new("Frame")
	accentDot.AnchorPoint = Vector2.new(0, 0.5)
	accentDot.Position = UDim2.fromOffset(16, 22)
	accentDot.Size = UDim2.fromOffset(8, 8)
	accentDot.BackgroundColor3 = RedlineUI.Theme.Accent
	accentDot.Parent = TopBar
	newCorner(accentDot, UDim.new(1, 0))
	local accentGlowStroke = newStroke(accentDot, 3, RedlineUI.Theme.AccentMuted)
	accentGlowStroke.Transparency = 0.4

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = RedlineUI.Theme.FontBold
	TitleLabel.Text = title
	TitleLabel.TextColor3 = RedlineUI.Theme.Text
	TitleLabel.TextSize = 15
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
	TitleLabel.Position = UDim2.fromOffset(32, 22)
	TitleLabel.Size = UDim2.fromOffset(220, 18)
	TitleLabel.Parent = TopBar

	if subtitle ~= "" then
		local SubtitleLabel = Instance.new("TextLabel")
		SubtitleLabel.BackgroundTransparency = 1
		SubtitleLabel.Font = RedlineUI.Theme.Font
		SubtitleLabel.Text = subtitle
		SubtitleLabel.TextColor3 = RedlineUI.Theme.TextFaint
		SubtitleLabel.TextSize = 11
		SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		SubtitleLabel.AnchorPoint = Vector2.new(0, 0.5)
		SubtitleLabel.Position = UDim2.fromOffset(32 + TitleLabel.TextBounds.X + 0, 23)
		SubtitleLabel.Size = UDim2.fromOffset(160, 14)
		SubtitleLabel.Parent = TopBar
	end

	-- window controls (minimize / close)
	local function makeTopBarButton(iconName, posFromRight)
		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = RedlineUI.Theme.Elevated
		btn.BackgroundTransparency = 1
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -posFromRight, 0, 22)
		btn.Size = UDim2.fromOffset(28, 28)
		btn.Parent = TopBar
		newCorner(btn, RedlineUI.Theme.CornerRadiusSm)

		local icon = Icons.Create(iconName, RedlineUI.Theme.TextDim, 15)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Parent = btn

		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundTransparency = 0 }, 0.12)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundTransparency = 1 }, 0.12)
		end)

		return btn, icon
	end

	local closeBtn, closeIcon = makeTopBarButton("x", 14)
	local minimizeBtn, minimizeIcon = makeTopBarButton("minus", 48)

	closeBtn.MouseEnter:Connect(function()
		tween(closeIcon:FindFirstChildWhichIsA("Frame"), {}, 0) -- no-op safe call
	end)

	----------------------------------------------------------------
	-- BODY: Sidebar (tab rail) + Content
	----------------------------------------------------------------
	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.BackgroundTransparency = 1
	Body.Position = UDim2.fromOffset(0, 44)
	Body.Size = UDim2.new(1, 0, 1, -44)
	Body.Parent = Main

	local sidebarWidth = isMobile() and 64 or 168

	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.BackgroundColor3 = RedlineUI.Theme.Sidebar
	Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
	Sidebar.Parent = Body

	local TabList = Instance.new("ScrollingFrame")
	TabList.Name = "TabList"
	TabList.BackgroundTransparency = 1
	TabList.BorderSizePixel = 0
	TabList.Position = UDim2.fromOffset(0, 12)
	TabList.Size = UDim2.new(1, 0, 1, -90)
	TabList.ScrollBarThickness = 2
	TabList.ScrollBarImageColor3 = RedlineUI.Theme.Accent
	TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	TabList.Parent = Sidebar

	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 4)
	TabListLayout.Parent = TabList

	local TabListPad = Instance.new("UIPadding")
	TabListPad.PaddingLeft = UDim.new(0, 8)
	TabListPad.PaddingRight = UDim.new(0, 8)
	TabListPad.Parent = TabList

	-- Player display (bottom of sidebar, WindUI-style)
	local PlayerCard = Instance.new("Frame")
	PlayerCard.Name = "PlayerCard"
	PlayerCard.BackgroundColor3 = RedlineUI.Theme.Elevated
	PlayerCard.AnchorPoint = Vector2.new(0, 1)
	PlayerCard.Position = UDim2.new(0, 8, 1, -8)
	PlayerCard.Size = UDim2.new(1, -16, 0, 56)
	PlayerCard.Parent = Sidebar
	newCorner(PlayerCard, RedlineUI.Theme.CornerRadiusSm)
	newStroke(PlayerCard, 1, RedlineUI.Theme.Stroke)

	local Avatar = Instance.new("ImageLabel")
	Avatar.Name = "Avatar"
	Avatar.BackgroundColor3 = RedlineUI.Theme.AccentMuted
	Avatar.AnchorPoint = Vector2.new(0, 0.5)
	Avatar.Position = UDim2.fromOffset(8, 28)
	Avatar.Size = UDim2.fromOffset(40, 40)
	Avatar.Parent = PlayerCard
	newCorner(Avatar, UDim.new(1, 0))
	local avatarStroke = newStroke(Avatar, 1.5, RedlineUI.Theme.Accent)

	pcall(function()
		local userId = LocalPlayer.UserId
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size100x100
		local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
		Avatar.Image = content
	end)

	local NameLabel = Instance.new("TextLabel")
	NameLabel.BackgroundTransparency = 1
	NameLabel.Font = RedlineUI.Theme.FontSemibold
	NameLabel.Text = LocalPlayer.DisplayName or LocalPlayer.Name
	NameLabel.TextColor3 = RedlineUI.Theme.Text
	NameLabel.TextSize = 13
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.Position = UDim2.fromOffset(56, 10)
	NameLabel.Size = UDim2.new(1, -64, 0, 16)
	NameLabel.Visible = not isMobile()
	NameLabel.Parent = PlayerCard

	local HandleLabel = Instance.new("TextLabel")
	HandleLabel.BackgroundTransparency = 1
	HandleLabel.Font = RedlineUI.Theme.Font
	HandleLabel.Text = "@" .. LocalPlayer.Name
	HandleLabel.TextColor3 = RedlineUI.Theme.TextFaint
	HandleLabel.TextSize = 11
	HandleLabel.TextXAlignment = Enum.TextXAlignment.Left
	HandleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	HandleLabel.Position = UDim2.fromOffset(56, 28)
	HandleLabel.Size = UDim2.new(1, -64, 0, 14)
	HandleLabel.Visible = not isMobile()
	HandleLabel.Parent = PlayerCard

	local statusDot = Instance.new("Frame")
	statusDot.AnchorPoint = Vector2.new(1, 1)
	statusDot.Position = UDim2.new(1, 6, 1, 6)
	statusDot.Size = UDim2.fromOffset(11, 11)
	statusDot.BackgroundColor3 = RedlineUI.Theme.Success
	statusDot.Parent = Avatar
	newCorner(statusDot, UDim.new(1, 0))
	newStroke(statusDot, 2, RedlineUI.Theme.Sidebar)

	----------------------------------------------------------------
	-- CONTENT AREA
	----------------------------------------------------------------
	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.BackgroundTransparency = 1
	Content.Position = UDim2.fromOffset(sidebarWidth, 0)
	Content.Size = UDim2.new(1, -sidebarWidth, 1, 0)
	Content.Parent = Body

	local ContentPad = Instance.new("UIPadding")
	ContentPad.PaddingTop = UDim.new(0, 16)
	ContentPad.PaddingLeft = UDim.new(0, 18)
	ContentPad.PaddingRight = UDim.new(0, 18)
	ContentPad.PaddingBottom = UDim.new(0, 16)
	ContentPad.Parent = Content

	----------------------------------------------------------------
	-- DRAG (top bar drags whole window)
	----------------------------------------------------------------
	makeDraggable(TopBar, Main)

	----------------------------------------------------------------
	-- MINIMIZE -> ORB
	----------------------------------------------------------------
	local Orb = Instance.new("TextButton")
	Orb.Name = "MinimizedOrb"
	Orb.Text = ""
	Orb.AutoButtonColor = false
	Orb.AnchorPoint = Vector2.new(0.5, 0.5)
	Orb.Position = UDim2.fromOffset(60, 60)
	Orb.Size = UDim2.fromOffset(56, 56)
	Orb.BackgroundColor3 = RedlineUI.Theme.Background
	Orb.Visible = false
	Orb.ZIndex = 500
	Orb.Parent = ScreenGui
	newCorner(Orb, UDim.new(1, 0))
	local orbStroke = newStroke(Orb, 1.5, RedlineUI.Theme.Accent)

	local orbIcon = Icons.Create("home", RedlineUI.Theme.Accent, 22)
	orbIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	orbIcon.Position = UDim2.fromScale(0.5, 0.5)
	orbIcon.Parent = Orb

	local orbPulse = Instance.new("Frame")
	orbPulse.AnchorPoint = Vector2.new(0.5, 0.5)
	orbPulse.Position = UDim2.fromScale(0.5, 0.5)
	orbPulse.Size = UDim2.fromScale(1, 1)
	orbPulse.BackgroundTransparency = 1
	orbPulse.ZIndex = 499
	orbPulse.Parent = Orb
	newCorner(orbPulse, UDim.new(1, 0))
	local orbPulseStroke = newStroke(orbPulse, 2, RedlineUI.Theme.Accent)
	orbPulseStroke.Transparency = 0.5

	task.spawn(function()
		while Orb.Parent do
			if Orb.Visible then
				orbPulse.Size = UDim2.fromScale(1, 1)
				orbPulseStroke.Transparency = 0.2
				tween(orbPulse, { Size = UDim2.fromScale(1.35, 1.35) }, 1.1, Enum.EasingStyle.Sine)
				tween(orbPulseStroke, { Transparency = 1 }, 1.1, Enum.EasingStyle.Sine)
			end
			task.wait(1.2)
		end
	end)

	-- orb drag (separate from "click to open" — track movement distance)
	do
		local dragging = false
		local moved = false
		local dragInput, mousePos, framePos

		Orb.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				moved = false
				mousePos = input.Position
				framePos = Orb.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						if dragging then
							dragging = false
							if not moved then
								-- treat as click -> restore window
								Window:Restore()
							end
						end
					end
				end)
			end
		end)

		Orb.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - mousePos
				if delta.Magnitude > 4 then moved = true end
				Orb.Position = UDim2.new(
					framePos.X.Scale, framePos.X.Offset + delta.X,
					framePos.Y.Scale, framePos.Y.Offset + delta.Y
				)
			end
		end)
	end

	function Window:Minimize()
		tween(Main, { Size = UDim2.fromOffset(0, 0) }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		local mainStroke = Main:FindFirstChildOfClass("UIStroke")
		if mainStroke then tween(mainStroke, { Transparency = 1 }, 0.18) end
		task.delay(0.2, function()
			Main.Visible = false
			Main.Size = size
			Orb.Visible = true
			Orb.Size = UDim2.fromOffset(0, 0)
			tween(Orb, { Size = UDim2.fromOffset(56, 56) }, 0.25, Enum.EasingStyle.Back)
		end)
	end

	function Window:Restore()
		tween(Orb, { Size = UDim2.fromOffset(0, 0) }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.16, function()
			Orb.Visible = false
			Orb.Size = UDim2.fromOffset(56, 56)
			Main.Visible = true
			Main.Size = UDim2.fromOffset(0, 0)
			tween(Main, { Size = size }, 0.26, Enum.EasingStyle.Back)
		end)
	end

	minimizeBtn.MouseButton1Click:Connect(function()
		Window:Minimize()
	end)

	----------------------------------------------------------------
	-- CLOSE -> CONFIRM MODAL
	----------------------------------------------------------------
	function Window:Close()
		tween(Main, { Size = UDim2.fromOffset(Main.Size.X.Offset, 0), BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.2, function()
			Main:Destroy()
			Orb:Destroy()
		end)
	end

	closeBtn.MouseButton1Click:Connect(function()
		RedlineUI:Confirm({
			Title = "Close the UI?",
			Message = "This will fully unload the interface. You'll need to re-execute the script to bring it back. This action is irreversible.",
			ConfirmText = "Yes",
			CancelText = "No",
			Danger = true,
			OnConfirm = function()
				Window:Close()
			end,
		})
	end)

	----------------------------------------------------------------
	-- TABS
	----------------------------------------------------------------
	function Window:CreateTab(tabOpts)
		tabOpts = tabOpts or {}
		local tabTitle = tabOpts.Title or "Tab"
		local tabIcon = tabOpts.Icon or "home"

		local Tab = {}

		local Page = Instance.new("ScrollingFrame")
		Page.Name = tabTitle .. "Page"
		Page.BackgroundTransparency = 1
		Page.BorderSizePixel = 0
		Page.Size = UDim2.fromScale(1, 1)
		Page.ScrollBarThickness = 3
		Page.ScrollBarImageColor3 = RedlineUI.Theme.Accent
		Page.CanvasSize = UDim2.new(0, 0, 0, 0)
		Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Page.Visible = false
		Page.Parent = Content

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 10)
		PageLayout.Parent = Page

		local TabBtn = Instance.new("TextButton")
		TabBtn.Text = ""
		TabBtn.AutoButtonColor = false
		TabBtn.BackgroundColor3 = RedlineUI.Theme.Elevated
		TabBtn.BackgroundTransparency = 1
		TabBtn.Size = UDim2.new(1, 0, 0, 38)
		TabBtn.Parent = TabList
		newCorner(TabBtn, RedlineUI.Theme.CornerRadiusSm)

		local TabIcon = Icons.Create(tabIcon, RedlineUI.Theme.TextDim, 17)
		TabIcon.AnchorPoint = Vector2.new(0, 0.5)
		TabIcon.Position = isMobile() and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 12, 0.5, 0)
		TabIcon.Parent = TabBtn

		local TabLabel
		if not isMobile() then
			TabLabel = Instance.new("TextLabel")
			TabLabel.BackgroundTransparency = 1
			TabLabel.Font = RedlineUI.Theme.FontSemibold
			TabLabel.Text = tabTitle
			TabLabel.TextColor3 = RedlineUI.Theme.TextDim
			TabLabel.TextSize = 13
			TabLabel.TextXAlignment = Enum.TextXAlignment.Left
			TabLabel.AnchorPoint = Vector2.new(0, 0.5)
			TabLabel.Position = UDim2.new(0, 40, 0.5, 0)
			TabLabel.Size = UDim2.new(1, -48, 0, 18)
			TabLabel.Parent = TabBtn
		end

		local activeBar = Instance.new("Frame")
		activeBar.AnchorPoint = Vector2.new(0, 0.5)
		activeBar.Position = UDim2.new(0, 0, 0.5, 0)
		activeBar.Size = UDim2.new(0, 3, 0, 0)
		activeBar.BackgroundColor3 = RedlineUI.Theme.Accent
		activeBar.Parent = TabBtn
		newCorner(activeBar, UDim.new(1, 0))

		local function setActive(active)
			Page.Visible = active
			tween(TabBtn, { BackgroundTransparency = active and 0 or 1 }, 0.15)
			tween(activeBar, { Size = UDim2.new(0, 3, 0, active and 20 or 0) }, 0.18, Enum.EasingStyle.Back)
			if TabLabel then
				tween(TabLabel, { TextColor3 = active and RedlineUI.Theme.Text or RedlineUI.Theme.TextDim }, 0.15)
			end
			for _, child in ipairs(TabIcon:GetDescendants()) do
				if child:IsA("Frame") then
					local isStroke = child:FindFirstChildOfClass("UIStroke")
				end
			end
		end

		TabBtn.MouseButton1Click:Connect(function()
			for _, t in ipairs(Window._tabButtons) do
				t.setActive(false)
			end
			setActive(true)
		end)

		TabBtn.MouseEnter:Connect(function()
			if not Page.Visible then
				tween(TabBtn, { BackgroundTransparency = 0.6 }, 0.12)
			end
		end)
		TabBtn.MouseLeave:Connect(function()
			if not Page.Visible then
				tween(TabBtn, { BackgroundTransparency = 1 }, 0.12)
			end
		end)

		table.insert(Window._tabButtons, { setActive = setActive })

		if #Window._tabButtons == 1 then
			setActive(true)
		end

		----------------------------------------------------------------
		-- TAB COMPONENTS
		----------------------------------------------------------------

		local function sectionContainer(labelText)
			local section = Instance.new("Frame")
			section.BackgroundColor3 = RedlineUI.Theme.Elevated
			section.Size = UDim2.new(1, 0, 0, 0)
			section.AutomaticSize = Enum.AutomaticSize.Y
			section.Parent = Page
			newCorner(section, RedlineUI.Theme.CornerRadius)
			newStroke(section, 1, RedlineUI.Theme.Stroke)

			local pad = Instance.new("UIPadding")
			pad.PaddingTop = UDim.new(0, 14)
			pad.PaddingBottom = UDim.new(0, 14)
			pad.PaddingLeft = UDim.new(0, 14)
			pad.PaddingRight = UDim.new(0, 14)
			pad.Parent = section

			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 12)
			layout.Parent = section

			return section
		end

		local rowCount = 0
		local function nextOrder()
			rowCount += 1
			return rowCount
		end

		function Tab:CreateButton(o)
			o = o or {}
			local row = sectionContainer()
			row.LayoutOrder = nextOrder()

			local btn = Instance.new("TextButton")
			btn.Text = ""
			btn.AutoButtonColor = false
			btn.BackgroundTransparency = 1
			btn.Size = UDim2.new(1, 0, 0, 20)
			btn.Parent = row

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Button"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -28, 1, 0)
			label.Parent = btn

			local arrow = Icons.Create("chevronDown", RedlineUI.Theme.Accent, 16)
			arrow.Rotation = -90
			arrow.AnchorPoint = Vector2.new(1, 0.5)
			arrow.Position = UDim2.new(1, 0, 0.5, 0)
			arrow.Parent = btn

			btn.MouseEnter:Connect(function()
				tween(row, { BackgroundColor3 = RedlineUI.Theme.ElevatedHover }, 0.12)
			end)
			btn.MouseLeave:Connect(function()
				tween(row, { BackgroundColor3 = RedlineUI.Theme.Elevated }, 0.12)
			end)
			btn.MouseButton1Click:Connect(function()
				tween(row, { BackgroundColor3 = RedlineUI.Theme.AccentMuted }, 0.08)
				task.delay(0.08, function()
					tween(row, { BackgroundColor3 = RedlineUI.Theme.Elevated }, 0.18)
				end)
				if o.Callback then o.Callback() end
			end)

			return row
		end

		function Tab:CreateToggle(o)
			o = o or {}
			local state = o.Default or false
			local row = sectionContainer()
			row.LayoutOrder = nextOrder()

			local holder = Instance.new("Frame")
			holder.BackgroundTransparency = 1
			holder.Size = UDim2.new(1, 0, 0, 20)
			holder.Parent = row

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Toggle"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -50, 1, 0)
			label.Parent = holder

			local switch = Instance.new("TextButton")
			switch.Text = ""
			switch.AutoButtonColor = false
			switch.AnchorPoint = Vector2.new(1, 0.5)
			switch.Position = UDim2.new(1, 0, 0.5, 0)
			switch.Size = UDim2.fromOffset(40, 22)
			switch.BackgroundColor3 = state and RedlineUI.Theme.Accent or RedlineUI.Theme.Stroke
			switch.Parent = holder
			newCorner(switch, UDim.new(1, 0))

			local knob = Instance.new("Frame")
			knob.Size = UDim2.fromOffset(16, 16)
			knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
			knob.BackgroundColor3 = Color3.new(1, 1, 1)
			knob.Parent = switch
			newCorner(knob, UDim.new(1, 0))

			local function setState(v, fireCallback)
				state = v
				tween(switch, { BackgroundColor3 = state and RedlineUI.Theme.Accent or RedlineUI.Theme.Stroke }, 0.15)
				tween(knob, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.15, Enum.EasingStyle.Back)
				if fireCallback ~= false and o.Callback then o.Callback(state) end
			end

			switch.MouseButton1Click:Connect(function()
				setState(not state)
			end)

			if state and o.Callback then o.Callback(state) end

			return { Set = function(v) setState(v, false) end, Get = function() return state end }
		end

		function Tab:CreateSlider(o)
			o = o or {}
			local min = o.Min or 0
			local max = o.Max or 100
			local value = math.clamp(o.Default or min, min, max)
			local decimals = o.Decimals or 0

			local row = sectionContainer()
			row.LayoutOrder = nextOrder()

			local topRow = Instance.new("Frame")
			topRow.BackgroundTransparency = 1
			topRow.Size = UDim2.new(1, 0, 0, 18)
			topRow.Parent = row

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Slider"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -60, 1, 0)
			label.Parent = topRow

			local valueLabel = Instance.new("TextLabel")
			valueLabel.BackgroundTransparency = 1
			valueLabel.Font = RedlineUI.Theme.Font
			valueLabel.Text = tostring(value)
			valueLabel.TextColor3 = RedlineUI.Theme.Accent
			valueLabel.TextSize = 13
			valueLabel.TextXAlignment = Enum.TextXAlignment.Right
			valueLabel.AnchorPoint = Vector2.new(1, 0)
			valueLabel.Position = UDim2.new(1, 0, 0, 0)
			valueLabel.Size = UDim2.fromOffset(50, 18)
			valueLabel.Parent = topRow

			local track = Instance.new("Frame")
			track.BackgroundColor3 = RedlineUI.Theme.Stroke
			track.Size = UDim2.new(1, 0, 0, 6)
			track.Position = UDim2.fromOffset(0, 30)
			track.Parent = row
			newCorner(track, UDim.new(1, 0))

			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = RedlineUI.Theme.Accent
			fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			fill.Parent = track
			newCorner(fill, UDim.new(1, 0))

			local knob = Instance.new("Frame")
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
			knob.Size = UDim2.fromOffset(14, 14)
			knob.BackgroundColor3 = Color3.new(1, 1, 1)
			knob.ZIndex = 2
			knob.Parent = track
			newCorner(knob, UDim.new(1, 0))
			newStroke(knob, 2, RedlineUI.Theme.Accent)

			local dragger = Instance.new("TextButton")
			dragger.Text = ""
			dragger.BackgroundTransparency = 1
			dragger.Size = UDim2.new(1, 0, 0, 24)
			dragger.Position = UDim2.fromOffset(0, 18)
			dragger.Parent = row

			local function setFromAlpha(alpha)
				alpha = math.clamp(alpha, 0, 1)
				local raw = min + (max - min) * alpha
				if decimals == 0 then
					raw = math.floor(raw + 0.5)
				else
					local mult = 10 ^ decimals
					raw = math.floor(raw * mult + 0.5) / mult
				end
				value = raw
				local realAlpha = (value - min) / (max - min)
				fill.Size = UDim2.new(realAlpha, 0, 1, 0)
				knob.Position = UDim2.new(realAlpha, 0, 0.5, 0)
				valueLabel.Text = tostring(value) .. (o.Suffix and (" " .. o.Suffix) or "")
				if o.Callback then o.Callback(value) end
			end

			local sliding = false
			dragger.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(alpha)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(alpha)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)

			return {
				Set = function(v)
					setFromAlpha((v - min) / (max - min))
				end,
				Get = function() return value end,
			}
		end

		function Tab:CreateInput(o)
			o = o or {}
			local row = sectionContainer()
			row.LayoutOrder = nextOrder()

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Input"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, 0, 0, 18)
			label.Parent = row

			local box = Instance.new("Frame")
			box.BackgroundColor3 = RedlineUI.Theme.Background
			box.Size = UDim2.new(1, 0, 0, 34)
			box.Position = UDim2.fromOffset(0, 26)
			box.Parent = row
			newCorner(box, RedlineUI.Theme.CornerRadiusSm)
			local boxStroke = newStroke(box, 1, RedlineUI.Theme.Stroke)

			local textBox = Instance.new("TextBox")
			textBox.BackgroundTransparency = 1
			textBox.Font = RedlineUI.Theme.Font
			textBox.PlaceholderText = o.Placeholder or ""
			textBox.PlaceholderColor3 = RedlineUI.Theme.TextFaint
			textBox.Text = o.Default or ""
			textBox.TextColor3 = RedlineUI.Theme.Text
			textBox.TextSize = 13
			textBox.TextXAlignment = Enum.TextXAlignment.Left
			textBox.ClearTextOnFocus = false
			textBox.Size = UDim2.new(1, -20, 1, 0)
			textBox.Position = UDim2.fromOffset(10, 0)
			textBox.Parent = box

			textBox.Focused:Connect(function()
				tween(boxStroke, { Color = RedlineUI.Theme.Accent }, 0.15)
			end)
			textBox.FocusLost:Connect(function(enter)
				tween(boxStroke, { Color = RedlineUI.Theme.Stroke }, 0.15)
				if o.Callback then o.Callback(textBox.Text, enter) end
			end)

			return { Set = function(v) textBox.Text = v end, Get = function() return textBox.Text end }
		end

		function Tab:CreateKeybind(o)
			o = o or {}
			local currentKey = o.Default or Enum.KeyCode.RightShift
			local listening = false

			local row = sectionContainer()
			row.LayoutOrder = nextOrder()

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Keybind"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -110, 1, 0)
			label.Parent = row

			local keyBtn = Instance.new("TextButton")
			keyBtn.AutoButtonColor = false
			keyBtn.Font = RedlineUI.Theme.FontSemibold
			keyBtn.Text = currentKey.Name
			keyBtn.TextColor3 = RedlineUI.Theme.Accent
			keyBtn.TextSize = 12
			keyBtn.BackgroundColor3 = RedlineUI.Theme.Background
			keyBtn.AnchorPoint = Vector2.new(1, 0.5)
			keyBtn.Position = UDim2.new(1, 0, 0.5, 0)
			keyBtn.Size = UDim2.fromOffset(96, 30)
			keyBtn.Parent = row
			newCorner(keyBtn, RedlineUI.Theme.CornerRadiusSm)
			local keyStroke = newStroke(keyBtn, 1, RedlineUI.Theme.Stroke)

			keyBtn.MouseButton1Click:Connect(function()
				listening = true
				keyBtn.Text = "..."
				tween(keyStroke, { Color = RedlineUI.Theme.Accent }, 0.15)
			end)

			UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if listening and input.UserInputType == Enum.UserInputType.Keyboard then
					currentKey = input.KeyCode
					keyBtn.Text = currentKey.Name
					listening = false
					tween(keyStroke, { Color = RedlineUI.Theme.Stroke }, 0.15)
					if o.Callback then o.Callback(currentKey) end
				elseif not listening and not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == currentKey and o.OnPress then
						o.OnPress()
					end
				end
			end)

			return { Set = function(k) currentKey = k; keyBtn.Text = k.Name end, Get = function() return currentKey end }
		end

		function Tab:CreateDropdown(o)
			o = o or {}
			local options = o.Options or {}
			local selected = o.Default or options[1]
			local open = false

			local row = sectionContainer()
			row.LayoutOrder = nextOrder()
			row.ClipsDescendants = false
			row.ZIndex = 5

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Dropdown"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, 0, 0, 18)
			label.Parent = row

			local box = Instance.new("TextButton")
			box.Text = ""
			box.AutoButtonColor = false
			box.BackgroundColor3 = RedlineUI.Theme.Background
			box.Size = UDim2.new(1, 0, 0, 34)
			box.Position = UDim2.fromOffset(0, 26)
			box.ZIndex = 5
			box.Parent = row
			newCorner(box, RedlineUI.Theme.CornerRadiusSm)
			local boxStroke = newStroke(box, 1, RedlineUI.Theme.Stroke)

			local selectedLabel = Instance.new("TextLabel")
			selectedLabel.BackgroundTransparency = 1
			selectedLabel.Font = RedlineUI.Theme.Font
			selectedLabel.Text = tostring(selected or "Select...")
			selectedLabel.TextColor3 = RedlineUI.Theme.Text
			selectedLabel.TextSize = 13
			selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
			selectedLabel.Position = UDim2.fromOffset(10, 0)
			selectedLabel.Size = UDim2.new(1, -40, 1, 0)
			selectedLabel.ZIndex = 5
			selectedLabel.Parent = box

			local chevron = Icons.Create("chevronDown", RedlineUI.Theme.TextDim, 16)
			chevron.AnchorPoint = Vector2.new(1, 0.5)
			chevron.Position = UDim2.new(1, -10, 0.5, 0)
			chevron.ZIndex = 5
			chevron.Parent = box

			local list = Instance.new("Frame")
			list.BackgroundColor3 = RedlineUI.Theme.Elevated
			list.Position = UDim2.fromOffset(0, 62)
			list.Size = UDim2.new(1, 0, 0, 0)
			list.ClipsDescendants = true
			list.ZIndex = 6
			list.Parent = row
			newCorner(list, RedlineUI.Theme.CornerRadiusSm)
			newStroke(list, 1, RedlineUI.Theme.StrokeLight)

			local listLayout = Instance.new("UIListLayout")
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Parent = list

			for _, opt in ipairs(options) do
				local optBtn = Instance.new("TextButton")
				optBtn.Text = ""
				optBtn.AutoButtonColor = false
				optBtn.BackgroundTransparency = 1
				optBtn.Size = UDim2.new(1, 0, 0, 32)
				optBtn.ZIndex = 6
				optBtn.Parent = list

				local optLabel = Instance.new("TextLabel")
				optLabel.BackgroundTransparency = 1
				optLabel.Font = RedlineUI.Theme.Font
				optLabel.Text = tostring(opt)
				optLabel.TextColor3 = RedlineUI.Theme.TextDim
				optLabel.TextSize = 13
				optLabel.TextXAlignment = Enum.TextXAlignment.Left
				optLabel.Position = UDim2.fromOffset(12, 0)
				optLabel.Size = UDim2.new(1, -16, 1, 0)
				optLabel.ZIndex = 6
				optLabel.Parent = optBtn

				optBtn.MouseEnter:Connect(function()
					tween(optBtn, { BackgroundTransparency = 0.85 }, 0.1)
					optBtn.BackgroundColor3 = RedlineUI.Theme.Accent
				end)
				optBtn.MouseLeave:Connect(function()
					tween(optBtn, { BackgroundTransparency = 1 }, 0.1)
				end)

				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					selectedLabel.Text = tostring(opt)
					if o.Callback then o.Callback(opt) end
					open = false
					tween(list, { Size = UDim2.new(1, 0, 0, 0) }, 0.16)
					tween(chevron, { Rotation = 0 }, 0.16)
				end)
			end

			box.MouseButton1Click:Connect(function()
				open = not open
				local targetHeight = open and math.min(#options * 32, 160) or 0
				tween(list, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.18, Enum.EasingStyle.Quint)
				tween(chevron, { Rotation = open and 180 or 0 }, 0.18)
			end)

			return {
				Set = function(v)
					selected = v
					selectedLabel.Text = tostring(v)
				end,
				Get = function() return selected end,
			}
		end

		function Tab:CreateColorPicker(o)
			o = o or {}
			local color = o.Default or Color3.fromRGB(176, 32, 42)

			local row = sectionContainer()
			row.LayoutOrder = nextOrder()

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Color"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -50, 0, 20)
			label.Parent = row

			local swatch = Instance.new("TextButton")
			swatch.Text = ""
			swatch.AutoButtonColor = false
			swatch.AnchorPoint = Vector2.new(1, 0)
			swatch.Position = UDim2.new(1, 0, 0, 0)
			swatch.Size = UDim2.fromOffset(36, 20)
			swatch.BackgroundColor3 = color
			swatch.Parent = row
			newCorner(swatch, RedlineUI.Theme.CornerRadiusSm)
			newStroke(swatch, 1, RedlineUI.Theme.StrokeLight)

			local panel = Instance.new("Frame")
			panel.BackgroundTransparency = 1
			panel.Position = UDim2.fromOffset(0, 28)
			panel.Size = UDim2.new(1, 0, 0, 0)
			panel.ClipsDescendants = true
			panel.Parent = row

			local panelLayout = Instance.new("UIListLayout")
			panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
			panelLayout.Padding = UDim.new(0, 8)
			panelLayout.Parent = panel

			local function makeChannel(name, initial)
				local holder = Instance.new("Frame")
				holder.BackgroundTransparency = 1
				holder.Size = UDim2.new(1, 0, 0, 22)
				holder.Parent = panel

				local chLabel = Instance.new("TextLabel")
				chLabel.BackgroundTransparency = 1
				chLabel.Font = RedlineUI.Theme.Font
				chLabel.Text = name
				chLabel.TextColor3 = RedlineUI.Theme.TextDim
				chLabel.TextSize = 12
				chLabel.TextXAlignment = Enum.TextXAlignment.Left
				chLabel.Size = UDim2.fromOffset(16, 22)
				chLabel.Parent = holder

				local track = Instance.new("Frame")
				track.BackgroundColor3 = RedlineUI.Theme.Stroke
				track.Position = UDim2.fromOffset(24, 8)
				track.Size = UDim2.new(1, -24, 0, 6)
				track.Parent = holder
				newCorner(track, UDim.new(1, 0))

				local fill = Instance.new("Frame")
				fill.BackgroundColor3 = RedlineUI.Theme.Accent
				fill.Size = UDim2.new(initial / 255, 0, 1, 0)
				fill.Parent = track
				newCorner(fill, UDim.new(1, 0))

				local dragger = Instance.new("TextButton")
				dragger.Text = ""
				dragger.BackgroundTransparency = 1
				dragger.Size = UDim2.new(1, 0, 1, 0)
				dragger.Parent = track

				return track, fill, dragger
			end

			local r, g, b = color.R * 255, color.G * 255, color.B * 255
			local rTrack, rFill, rDrag = makeChannel("R", r)
			local gTrack, gFill, gDrag = makeChannel("G", g)
			local bTrack, bFill, bDrag = makeChannel("B", b)

			local function updateColor()
				color = Color3.fromRGB(math.floor(r), math.floor(g), math.floor(b))
				swatch.BackgroundColor3 = color
				if o.Callback then o.Callback(color) end
			end

			local function bindChannel(track, fill, dragger, getSet)
				local sliding = false
				dragger.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = true
						local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
						fill.Size = UDim2.new(alpha, 0, 1, 0)
						getSet(alpha * 255)
						updateColor()
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
						fill.Size = UDim2.new(alpha, 0, 1, 0)
						getSet(alpha * 255)
						updateColor()
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = false
					end
				end)
			end

			bindChannel(rTrack, rFill, rDrag, function(v) r = v end)
			bindChannel(gTrack, gFill, gDrag, function(v) g = v end)
			bindChannel(bTrack, bFill, bDrag, function(v) b = v end)

			local expanded = false
			swatch.MouseButton1Click:Connect(function()
				expanded = not expanded
				tween(panel, { Size = UDim2.new(1, 0, 0, expanded and 90 or 0) }, 0.18, Enum.EasingStyle.Quint)
			end)

			return {
				Set = function(c)
					color = c
					r, g, b = c.R * 255, c.G * 255, c.B * 255
					swatch.BackgroundColor3 = c
					rFill.Size = UDim2.new(r / 255, 0, 1, 0)
					gFill.Size = UDim2.new(g / 255, 0, 1, 0)
					bFill.Size = UDim2.new(b / 255, 0, 1, 0)
				end,
				Get = function() return color end,
			}
		end

		function Tab:CreateLabel(text)
			local row = sectionContainer()
			row.LayoutOrder = nextOrder()
			row.BackgroundTransparency = 1
			row:FindFirstChildOfClass("UIStroke"):Destroy()

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.Font
			label.Text = text
			label.TextColor3 = RedlineUI.Theme.TextDim
			label.TextSize = 13
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, 0, 0, 0)
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Parent = row

			return row
		end

		Window.Tabs[tabTitle] = Tab
		return Tab
	end

	-- entrance animation
	Main.Size = UDim2.fromOffset(0, 0)
	tween(Main, { Size = size }, 0.3, Enum.EasingStyle.Back)

	return Window
end

return RedlineUI
