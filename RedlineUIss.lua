--[[
	RedlineUI — Modernized
	Dark/Red theme, Lucide-style vector icons, smooth tweens.
	Fixes: Slider input, layout corrections, visual polish.
	New: Accent topbar stripe, section headers, glow knob, improved notifs.
]]

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")
local GuiService        = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local RedlineUI = {}
RedlineUI.__index = RedlineUI

----------------------------------------------------------------
-- THEME
----------------------------------------------------------------

RedlineUI.Theme = {
	Background      = Color3.fromRGB(6, 5, 6),
	Elevated        = Color3.fromRGB(13, 10, 11),
	ElevatedHover   = Color3.fromRGB(19, 14, 15),
	Sidebar         = Color3.fromRGB(5, 4, 5),
	Stroke          = Color3.fromRGB(28, 18, 19),
	StrokeLight     = Color3.fromRGB(45, 26, 28),

	-- Deep, near-black red accent (per reference style)
	Accent          = Color3.fromRGB(120, 18, 26),
	AccentHover     = Color3.fromRGB(145, 24, 33),
	AccentMuted     = Color3.fromRGB(45, 10, 14),
	AccentGlow      = Color3.fromRGB(180, 35, 45),
	AccentDim       = Color3.fromRGB(70, 14, 18),

	Text            = Color3.fromRGB(235, 228, 228),
	TextDim         = Color3.fromRGB(140, 124, 126),
	TextFaint       = Color3.fromRGB(85, 70, 72),

	Success         = Color3.fromRGB(60, 195, 115),
	Warning         = Color3.fromRGB(230, 165, 50),
	Error           = Color3.fromRGB(220, 65, 65),
	Info            = Color3.fromRGB(85, 145, 225),
	Locked          = Color3.fromRGB(100, 88, 90),

	Font            = Enum.Font.GothamMedium,
	FontBold        = Enum.Font.GothamBold,
	FontSemibold    = Enum.Font.GothamSemibold,

	CornerRadius    = UDim.new(0, 14),
	CornerRadiusSm  = UDim.new(0, 10),
}

----------------------------------------------------------------
-- ICON PRIMITIVES
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

local function iconCanvas(size)
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(size, size)
	f.BackgroundTransparency = 1
	return f
end

local function iconLine(parent, x1, y1, x2, y2, color, thickness)
	local dx, dy = x2 - x1, y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)
	local angle  = math.atan2(dy, dx)
	local line   = Instance.new("Frame")
	line.AnchorPoint    = Vector2.new(0, 0.5)
	line.Position       = UDim2.fromOffset(x1, y1)
	line.Size           = UDim2.fromOffset(length, thickness or 1.6)
	line.Rotation       = math.deg(angle)
	line.BackgroundColor3 = color or RedlineUI.Theme.Text
	line.BorderSizePixel  = 0
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
	if not filled then newStroke(circle, thickness or 1.6, color) end
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
	if not filled then newStroke(rect, thickness or 1.6, color) end
	rect.Parent = parent
	return rect
end

----------------------------------------------------------------
-- ICON DEFINITIONS
----------------------------------------------------------------

Icons.Definitions = {
	home = function(color)
		local c = iconCanvas(18)
		iconLine(c,2,9,9,2.5,color,1.6); iconLine(c,9,2.5,16,9,color,1.6)
		iconRect(c,4,9,10,7,color,1,false,1.6); iconRect(c,7.5,11.5,3,4.5,color,1,false,1.6)
		return c
	end,
	settings = function(color)
		local c = iconCanvas(18)
		iconCircle(c,9,9,2.6,color,false,1.6)
		for i=0,5 do
			local a=math.rad(i*60)
			iconLine(c,9+math.cos(a)*5.4,9+math.sin(a)*5.4,9+math.cos(a)*7.4,9+math.sin(a)*7.4,color,1.6)
		end
		return c
	end,
	user = function(color)
		local c = iconCanvas(18)
		iconCircle(c,9,6,3.2,color,false,1.6); iconRect(c,3,11,12,6,color,6,false,1.6)
		return c
	end,
	bell = function(color)
		local c = iconCanvas(18)
		iconRect(c,6.5,2.5,5,5,color,5,false,1.6)
		iconLine(c,4.5,6,4.5,11,color,1.6); iconLine(c,13.5,6,13.5,11,color,1.6)
		iconLine(c,4.5,11,13.5,11,color,1.6); iconLine(c,3,13.2,15,13.2,color,1.6)
		iconCircle(c,9,15.4,1.3,color,true)
		return c
	end,
	x = function(color)
		local c = iconCanvas(18)
		iconLine(c,4,4,14,14,color,1.8); iconLine(c,14,4,4,14,color,1.8)
		return c
	end,
	check = function(color)
		local c = iconCanvas(18)
		iconLine(c,3.5,9.5,7,13.5,color,1.8); iconLine(c,7,13.5,14.5,4.5,color,1.8)
		return c
	end,
	chevronDown = function(color)
		local c = iconCanvas(18)
		iconLine(c,4,6.5,9,12,color,1.7); iconLine(c,9,12,14,6.5,color,1.7)
		return c
	end,
	chevronUp = function(color)
		local c = iconCanvas(18)
		iconLine(c,4,11.5,9,6,color,1.7); iconLine(c,9,6,14,11.5,color,1.7)
		return c
	end,
	minus = function(color)
		local c = iconCanvas(18)
		iconLine(c,4,9,14,9,color,1.8)
		return c
	end,
	search = function(color)
		local c = iconCanvas(18)
		iconCircle(c,8,8,4.5,color,false,1.6); iconLine(c,11.3,11.3,15.5,15.5,color,1.8)
		return c
	end,
	sliders = function(color)
		local c = iconCanvas(18)
		iconLine(c,4,3,4,15,color,1.6); iconLine(c,9,3,9,15,color,1.6); iconLine(c,14,3,14,15,color,1.6)
		iconCircle(c,4,6,1.7,color,true); iconCircle(c,9,11,1.7,color,true); iconCircle(c,14,8,1.7,color,true)
		return c
	end,
	palette = function(color)
		local c = iconCanvas(18)
		iconCircle(c,9,9,6.5,color,false,1.6)
		iconCircle(c,6.2,7,1.1,color,true); iconCircle(c,9,5,1.1,color,true)
		iconCircle(c,12,7,1.1,color,true); iconCircle(c,11.4,11.6,1.1,color,true)
		return c
	end,
	keyboard = function(color)
		local c = iconCanvas(18)
		iconRect(c,2.5,5,13,8,color,2,false,1.6)
		iconRect(c,4.5,7.2,1.4,1.4,color,1,true); iconRect(c,7,7.2,1.4,1.4,color,1,true)
		iconRect(c,9.5,7.2,1.4,1.4,color,1,true); iconRect(c,12,7.2,1.4,1.4,color,1,true)
		iconRect(c,4.5,9.8,9,1.4,color,1,true)
		return c
	end,
	type = function(color)
		local c = iconCanvas(18)
		iconLine(c,4,4,14,4,color,1.6); iconLine(c,9,4,9,14,color,1.6); iconLine(c,6.5,14,11.5,14,color,1.6)
		return c
	end,
	info = function(color)
		local c = iconCanvas(18)
		iconCircle(c,9,9,7,color,false,1.6); iconCircle(c,9,5.6,0.9,color,true); iconLine(c,9,8,9,13,color,1.7)
		return c
	end,
	alertTriangle = function(color)
		local c = iconCanvas(18)
		iconLine(c,9,2.5,2,15,color,1.7); iconLine(c,9,2.5,16,15,color,1.7); iconLine(c,2,15,16,15,color,1.7)
		iconLine(c,9,6.5,9,10.5,color,1.6); iconCircle(c,9,12.8,0.8,color,true)
		return c
	end,
	checkCircle = function(color)
		local c = iconCanvas(18)
		iconCircle(c,9,9,7,color,false,1.6)
		iconLine(c,5.5,9.3,8,12,color,1.7); iconLine(c,8,12,13,6.5,color,1.7)
		return c
	end,
	xCircle = function(color)
		local c = iconCanvas(18)
		iconCircle(c,9,9,7,color,false,1.6)
		iconLine(c,6,6,12,12,color,1.6); iconLine(c,12,6,6,12,color,1.6)
		return c
	end,
	logOut = function(color)
		local c = iconCanvas(18)
		iconRect(c,3,3,7,12,color,2,false,1.6)
		iconLine(c,8,9,16,9,color,1.6); iconLine(c,12.5,5.5,16,9,color,1.6); iconLine(c,12.5,12.5,16,9,color,1.6)
		return c
	end,
	pin = function(color)
		local c = iconCanvas(18)
		iconCircle(c,9,7,4,color,false,1.6); iconLine(c,9,11,9,16,color,1.6)
		return c
	end,
	lock = function(color)
		local c = iconCanvas(18)
		-- shackle: two short posts plus a rounded cap to suggest an arch
		iconLine(c,6.5,7,6.5,5,color,1.6)
		iconLine(c,11.5,7,11.5,5,color,1.6)
		iconRect(c,6.5,3,5,4,color,4,false,1.6)
		-- body
		iconRect(c,4,8,10,8,color,2,false,1.6)
		iconCircle(c,9,11.2,1,color,true)
		iconLine(c,9,12.2,9,13.6,color,1.4)
		return c
	end,
}

function Icons.Create(name, color, size)
	local builder = Icons.Definitions[name] or Icons.Definitions.info
	local icon = builder(color or RedlineUI.Theme.Text)
	if size and size ~= 18 then
		local scale = size / 18
		icon.Size = UDim2.fromOffset(size, size)
		for _, child in ipairs(icon:GetChildren()) do
			if child:IsA("Frame") then
				child.Position = UDim2.fromOffset(child.Position.X.Offset * scale, child.Position.Y.Offset * scale)
				child.Size     = UDim2.fromOffset(child.Size.X.Offset * scale, child.Size.Y.Offset * scale)
			end
		end
	end
	return icon
end

----------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------

local function tween(obj, props, duration, style, direction)
	duration  = duration or 0.18
	style     = style or Enum.EasingStyle.Quint
	direction = direction or Enum.EasingDirection.Out
	local t = TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
	t:Play()
	return t
end

local function makeDraggable(handle, target)
	local dragging = false
	local dragInput, mousePos, framePos

	local function update(input)
		local delta  = input.Position - mousePos
		target.Position = UDim2.new(
			framePos.X.Scale, framePos.X.Offset + delta.X,
			framePos.Y.Scale, framePos.Y.Offset + delta.Y
		)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			mousePos  = input.Position
			framePos  = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
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
		if input == dragInput and dragging then update(input) end
	end)
end

local function getGui()
	local existing = CoreGui:FindFirstChild("RedlineUI_ScreenGui")
	if existing then existing:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "RedlineUI_ScreenGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999
	local ok = pcall(function() gui.Parent = CoreGui end)
	if not ok then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
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
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationLayout.Padding = UDim.new(0, 8)
NotificationLayout.Parent = NotificationHolder

local NOTIF_ICON = { success="checkCircle", error="xCircle", warning="alertTriangle", info="info" }
local NOTIF_COLOR = {
	success = RedlineUI.Theme.Success,
	error   = RedlineUI.Theme.Error,
	warning = RedlineUI.Theme.Warning,
	info    = RedlineUI.Theme.Info,
}

function RedlineUI:Notify(opts)
	opts = opts or {}
	local kind     = opts.Type or "info"
	local title    = opts.Title or "Notification"
	local content  = opts.Content or ""
	local duration = opts.Duration or 4
	local accentColor = NOTIF_COLOR[kind] or RedlineUI.Theme.Accent

	local card = Instance.new("Frame")
	card.Name = "Notification"
	card.BackgroundColor3 = RedlineUI.Theme.Elevated
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ClipsDescendants = false
	card.LayoutOrder = -os.clock() * 1000
	card.Parent = NotificationHolder
	newCorner(card, RedlineUI.Theme.CornerRadius)
	local cardStroke = newStroke(card, 1, RedlineUI.Theme.Stroke)

	-- left accent bar
	local accentBar = Instance.new("Frame")
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Size = UDim2.new(0, 3, 1, -20)
	accentBar.AnchorPoint = Vector2.new(0, 0.5)
	accentBar.Position = UDim2.new(0, 0, 0.5, 0)
	accentBar.Parent = card
	newCorner(accentBar, UDim.new(1, 0))

	-- progress bar at bottom
	local progressBg = Instance.new("Frame")
	progressBg.BackgroundColor3 = RedlineUI.Theme.Stroke
	progressBg.BorderSizePixel = 0
	progressBg.AnchorPoint = Vector2.new(0, 1)
	progressBg.Position = UDim2.new(0, 0, 1, 0)
	progressBg.Size = UDim2.new(1, 0, 0, 2)
	progressBg.Parent = card
	newCorner(progressBg, UDim.new(1, 0))

	local progressFill = Instance.new("Frame")
	progressFill.BackgroundColor3 = accentColor
	progressFill.BorderSizePixel = 0
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.Parent = progressBg
	newCorner(progressFill, UDim.new(1, 0))

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 20)
	pad.PaddingRight  = UDim.new(0, 16)
	pad.PaddingTop    = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.Parent = card

	local iconWrap = Instance.new("Frame")
	iconWrap.BackgroundColor3 = Color3.new(accentColor.R * 0.25, accentColor.G * 0.25, accentColor.B * 0.25)
	iconWrap.Size = UDim2.fromOffset(30, 30)
	iconWrap.Position = UDim2.fromOffset(0, 0)
	iconWrap.Parent = card
	newCorner(iconWrap, UDim.new(0, 10))

	local icon = Icons.Create(NOTIF_ICON[kind] or "info", accentColor, 16)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Parent = iconWrap

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = RedlineUI.Theme.FontBold
	titleLabel.Text = title
	titleLabel.TextColor3 = RedlineUI.Theme.Text
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Position = UDim2.fromOffset(40, 0)
	titleLabel.Size = UDim2.new(1, -40, 0, 18)
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
	contentLabel.Position = UDim2.fromOffset(40, 22)
	contentLabel.Size = UDim2.new(1, -40, 0, 0)
	contentLabel.AutomaticSize = Enum.AutomaticSize.Y
	contentLabel.Parent = card

	-- entrance
	card.Position = UDim2.fromOffset(40, 0)
	card.BackgroundTransparency = 1
	cardStroke.Transparency = 1
	tween(card, { BackgroundTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.22, Enum.EasingStyle.Back)
	tween(cardStroke, { Transparency = 0 }, 0.22)

	-- progress drain
	tween(progressFill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		if not card or not card.Parent then return end
		local fade = tween(card, { BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 0) }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(cardStroke, { Transparency = 1 }, 0.2)
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("TextLabel") then tween(d, { TextTransparency = 1 }, 0.2) end
		end
		fade.Completed:Wait()
		card:Destroy()
	end)

	return card
end

----------------------------------------------------------------
-- CONFIRM MODAL
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
	local title       = opts.Title or "Are you sure?"
	local message     = opts.Message or "This action cannot be undone."
	local confirmText = opts.ConfirmText or "Yes"
	local cancelText  = opts.CancelText or "No"
	local onConfirm   = opts.OnConfirm
	local onCancel    = opts.OnCancel
	local danger      = opts.Danger ~= false

	ModalLayer.Visible = true
	for _, c in ipairs(ModalLayer:GetChildren()) do c:Destroy() end

	local backdrop = Instance.new("Frame")
	backdrop.BackgroundColor3 = Color3.new(0,0,0)
	backdrop.BackgroundTransparency = 1
	backdrop.Size = UDim2.fromScale(1,1)
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

	-- top accent line
	local topLine = Instance.new("Frame")
	topLine.BackgroundColor3 = danger and RedlineUI.Theme.Accent or RedlineUI.Theme.Info
	topLine.BorderSizePixel = 0
	topLine.Size = UDim2.new(0.4, 0, 0, 2)
	topLine.AnchorPoint = Vector2.new(0.5, 0)
	topLine.Position = UDim2.new(0.5, 0, 0, 0)
	topLine.ZIndex = 1002
	topLine.Parent = box
	newCorner(topLine, UDim.new(1, 0))

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, 22)
	pad.PaddingBottom = UDim.new(0, 18)
	pad.PaddingLeft   = UDim.new(0, 22)
	pad.PaddingRight  = UDim.new(0, 22)
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
	if not danger then newStroke(iconBg, 1, RedlineUI.Theme.Stroke) end

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
		task.delay(0.2, function() ModalLayer.Visible = false end)
	end

	local function makeButton(text, isPrimary)
		local btn = Instance.new("TextButton")
		btn.AutoButtonColor = false
		btn.Font = RedlineUI.Theme.FontSemibold
		btn.Text = text
		btn.TextSize = 14
		btn.TextColor3 = isPrimary and Color3.new(1,1,1) or RedlineUI.Theme.Text
		btn.BackgroundColor3 = isPrimary and RedlineUI.Theme.Accent or RedlineUI.Theme.Elevated
		btn.Size = UDim2.fromOffset(90, 36)
		btn.Parent = btnRow
		newCorner(btn, RedlineUI.Theme.CornerRadiusSm)
		if not isPrimary then newStroke(btn, 1, RedlineUI.Theme.Stroke) end
		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundColor3 = isPrimary and RedlineUI.Theme.AccentHover or RedlineUI.Theme.ElevatedHover }, 0.12)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundColor3 = isPrimary and RedlineUI.Theme.Accent or RedlineUI.Theme.Elevated }, 0.12)
		end)
		return btn
	end

	local cancelBtn  = makeButton(cancelText, false)
	local confirmBtn = makeButton(confirmText, true)

	confirmBtn.MouseButton1Click:Connect(function() closeModal(); if onConfirm then onConfirm() end end)
	cancelBtn.MouseButton1Click:Connect(function()  closeModal(); if onCancel  then onCancel()  end end)

	backdrop.BackgroundTransparency = 1
	box.BackgroundTransparency = 1
	boxStroke.Transparency = 1
	box.Position = UDim2.fromScale(0.5, 0.47)
	for _, d in ipairs(box:GetDescendants()) do
		if d:IsA("TextLabel") then d.TextTransparency = 1 end
	end

	tween(backdrop,  { BackgroundTransparency = 0.5 }, 0.2)
	tween(box,       { BackgroundTransparency = 0, Position = UDim2.fromScale(0.5, 0.45) }, 0.22, Enum.EasingStyle.Back)
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
	local title    = opts.Title or "Redline"
	local subtitle = opts.Subtitle or ""
	local size     = opts.Size or (isMobile() and UDim2.fromOffset(360, 480) or UDim2.fromOffset(630, 430))

	local Window = {}
	Window.Tabs = {}
	Window._tabButtons = {}

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

	-- drop shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.new(0,0,0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10,10,118,118)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.fromScale(0.5, 0.53)
	shadow.Size = UDim2.new(1, 70, 1, 70)
	shadow.BackgroundTransparency = 1
	shadow.ZIndex = -1
	shadow.Parent = Main

	

	----------------------------------------------------------------
	-- TOP BAR
	----------------------------------------------------------------
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.BackgroundColor3 = RedlineUI.Theme.Sidebar
	TopBar.Size = UDim2.new(1, 0, 0, 54)
	TopBar.Parent = Main
	newCorner(TopBar, RedlineUI.Theme.CornerRadius)

	local topBarMask = Instance.new("Frame")
	topBarMask.BackgroundColor3 = RedlineUI.Theme.Sidebar
	topBarMask.BorderSizePixel = 0
	topBarMask.Position = UDim2.new(0, 0, 1, -10)
	topBarMask.Size = UDim2.new(1, 0, 0, 10)
	topBarMask.Parent = TopBar

	local topBarBorder = Instance.new("Frame")
	topBarBorder.BackgroundColor3 = RedlineUI.Theme.Stroke
	topBarBorder.BorderSizePixel = 0
	topBarBorder.AnchorPoint = Vector2.new(0, 1)
	topBarBorder.Position = UDim2.new(0, 0, 1, 0)
	topBarBorder.Size = UDim2.new(1, 0, 0, 1)
	topBarBorder.Parent = TopBar

	-- animated accent dot
	local accentDot = Instance.new("Frame")
	accentDot.AnchorPoint = Vector2.new(0, 0.5)
	accentDot.Position = UDim2.fromOffset(18, 27)
	accentDot.Size = UDim2.fromOffset(8, 8)
	accentDot.BackgroundColor3 = RedlineUI.Theme.Accent
	accentDot.Parent = TopBar
	newCorner(accentDot, UDim.new(1, 0))
	local dotGlow = newStroke(accentDot, 4, RedlineUI.Theme.AccentMuted)
	dotGlow.Transparency = 0.2

	-- pulse the dot glow
	task.spawn(function()
		while TopBar.Parent do
			tween(dotGlow, { Transparency = 0.6 }, 0.9, Enum.EasingStyle.Sine)
			task.wait(0.9)
			tween(dotGlow, { Transparency = 0.1 }, 0.9, Enum.EasingStyle.Sine)
			task.wait(0.9)
		end
	end)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = RedlineUI.Theme.FontBold
	TitleLabel.Text = title
	TitleLabel.TextColor3 = RedlineUI.Theme.Text
	TitleLabel.TextSize = 15
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
	TitleLabel.Position = UDim2.fromOffset(36, 27)
	TitleLabel.Size = UDim2.fromOffset(220, 20)
	TitleLabel.Parent = TopBar

	if subtitle ~= "" then
		local SubLabel = Instance.new("TextLabel")
		SubLabel.BackgroundTransparency = 1
		SubLabel.Font = RedlineUI.Theme.Font
		SubLabel.Text = subtitle
		SubLabel.TextColor3 = RedlineUI.Theme.TextFaint
		SubLabel.TextSize = 11
		SubLabel.TextXAlignment = Enum.TextXAlignment.Left
		SubLabel.AnchorPoint = Vector2.new(0, 0.5)
		SubLabel.Position = UDim2.fromOffset(36 + TitleLabel.TextBounds.X + 10, 27)
		SubLabel.Size = UDim2.fromOffset(160, 14)
		SubLabel.Parent = TopBar
	end

	-- Optional live clock, top-right (Aim Hub style)
	if opts.ShowClock then
		local function nowText()
			local d = DateTime.now():ToLocalTime()
			return string.format("%02d:%02d:%02d", d.Hour, d.Minute, d.Second)
		end

		local ClockLabel = Instance.new("TextLabel")
		ClockLabel.BackgroundTransparency = 1
		ClockLabel.Font = RedlineUI.Theme.FontSemibold
		ClockLabel.Text = nowText()
		ClockLabel.TextColor3 = RedlineUI.Theme.AccentGlow
		ClockLabel.TextSize = 13
		ClockLabel.TextXAlignment = Enum.TextXAlignment.Right
		ClockLabel.AnchorPoint = Vector2.new(1, 0.5)
		ClockLabel.Position = UDim2.new(1, -98, 0.5, 0)
		ClockLabel.Size = UDim2.fromOffset(80, 18)
		ClockLabel.Parent = TopBar

		task.spawn(function()
			while ClockLabel.Parent do
				ClockLabel.Text = nowText()
				task.wait(1)
			end
		end)
	end

	local function makeTopBarButton(iconName, posFromRight, bgColor, hoverColor, iconColor)
    local btn = Instance.new("TextButton")
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0.75
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -posFromRight, 0.5, 0)
    btn.Size = UDim2.fromOffset(30, 30)
    btn.Parent = TopBar
    newCorner(btn, UDim.new(0, 10))

    -- Draw icon inline (avoids rendering bugs with Icons.Create in topbar)
    local canvas = Instance.new("Frame")
    canvas.Size = UDim2.fromOffset(14, 14)
    canvas.AnchorPoint = Vector2.new(0.5, 0.5)
    canvas.Position = UDim2.fromScale(0.5, 0.5)
    canvas.BackgroundTransparency = 1
    canvas.Parent = btn

    if iconName == "x" then
        iconLine(canvas, 1, 1, 13, 13, iconColor, 2)
        iconLine(canvas, 13, 1, 1, 13, iconColor, 2)
    elseif iconName == "minus" then
        iconLine(canvas, 1, 7, 13, 7, iconColor, 2)
    end

    btn.MouseEnter:Connect(function()
        tween(btn, { BackgroundTransparency = 0.25, BackgroundColor3 = hoverColor }, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, { BackgroundTransparency = 0.75, BackgroundColor3 = bgColor }, 0.12)
    end)
    return btn
end

	local closeBtn    = makeTopBarButton("x",     14, Color3.fromRGB(185,28,40), Color3.fromRGB(220,50,65), Color3.fromRGB(255,255,255))
	local minimizeBtn = makeTopBarButton("minus", 52, Color3.fromRGB(40,35,38),  Color3.fromRGB(65,55,58),  Color3.fromRGB(200,200,200))
	----------------------------------------------------------------
	-- BODY
	----------------------------------------------------------------
	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.BackgroundTransparency = 1
	Body.Position = UDim2.fromOffset(0, 54)
	Body.Size = UDim2.new(1, 0, 1, -54)
	Body.Parent = Main

	local sidebarWidth = isMobile() and 60 or 170

	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.BackgroundColor3 = RedlineUI.Theme.Sidebar
	Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
	Sidebar.Parent = Body

	local sidebarBorder = Instance.new("Frame")
	sidebarBorder.BackgroundColor3 = RedlineUI.Theme.Accent
	sidebarBorder.BackgroundTransparency = 0.1
	sidebarBorder.BorderSizePixel = 0
	sidebarBorder.AnchorPoint = Vector2.new(1, 0)
	sidebarBorder.Position = UDim2.new(1, 0, 0, 0)
	sidebarBorder.Size = UDim2.new(0, 2, 1, 0)
	sidebarBorder.Parent = Sidebar

	local TabList = Instance.new("ScrollingFrame")
	TabList.Name = "TabList"
	TabList.BackgroundTransparency = 1
	TabList.BorderSizePixel = 0
	TabList.Position = UDim2.fromOffset(0, 10)
	TabList.Size = UDim2.new(1, 0, 1, -82)
	TabList.ScrollBarThickness = 2
	TabList.ScrollBarImageColor3 = RedlineUI.Theme.Accent
	TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	TabList.Parent = Sidebar

	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 3)
	TabListLayout.Parent = TabList

	local TabListPad = Instance.new("UIPadding")
	TabListPad.PaddingLeft  = UDim.new(0, 7)
	TabListPad.PaddingRight = UDim.new(0, 7)
	TabListPad.PaddingTop   = UDim.new(0, 2)
	TabListPad.Parent = TabList

	-- Player card (bottom sidebar)
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
	Avatar.BackgroundColor3 = RedlineUI.Theme.AccentMuted
	Avatar.AnchorPoint = Vector2.new(0, 0.5)
	Avatar.Position = UDim2.fromOffset(8, 28)
	Avatar.Size = UDim2.fromOffset(38, 38)
	Avatar.Parent = PlayerCard
	newCorner(Avatar, UDim.new(1, 0))
	newStroke(Avatar, 1.5, RedlineUI.Theme.Accent)

	pcall(function()
		local content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
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
	NameLabel.Position = UDim2.fromOffset(54, 10)
	NameLabel.Size = UDim2.new(1, -62, 0, 16)
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
	HandleLabel.Position = UDim2.fromOffset(54, 28)
	HandleLabel.Size = UDim2.new(1, -62, 0, 14)
	HandleLabel.Visible = not isMobile()
	HandleLabel.Parent = PlayerCard

	local statusDot = Instance.new("Frame")
	statusDot.AnchorPoint = Vector2.new(1, 1)
	statusDot.Position = UDim2.new(1, 5, 1, 5)
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
	ContentPad.PaddingTop    = UDim.new(0, 16)
	ContentPad.PaddingLeft   = UDim.new(0, 18)
	ContentPad.PaddingRight  = UDim.new(0, 18)
	ContentPad.PaddingBottom = UDim.new(0, 16)
	ContentPad.Parent = Content

	----------------------------------------------------------------
	-- DRAG
	----------------------------------------------------------------
	makeDraggable(TopBar, Main)

	----------------------------------------------------------------
	-- MINIMIZE ORB
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
	newStroke(Orb, 1.5, RedlineUI.Theme.Accent)

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
				tween(orbPulse, { Size = UDim2.fromScale(1.4, 1.4) }, 1.1, Enum.EasingStyle.Sine)
				tween(orbPulseStroke, { Transparency = 1 }, 1.1, Enum.EasingStyle.Sine)
			end
			task.wait(1.2)
		end
	end)

	do
		local dragging, moved = false, false
		local dragInput, mousePos, framePos

		Orb.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; moved = false
				mousePos = input.Position; framePos = Orb.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End and dragging then
						dragging = false
						if not moved then Window:Restore() end
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
				Orb.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
			end
		end)
	end

	function Window:Minimize()
		tween(Main, { Size = UDim2.fromOffset(0, 0) }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		local ms = Main:FindFirstChildOfClass("UIStroke")
		if ms then tween(ms, { Transparency = 1 }, 0.18) end
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

	minimizeBtn.MouseButton1Click:Connect(function() Window:Minimize() end)

	function Window:Close()
		tween(Main, { Size = UDim2.fromOffset(Main.Size.X.Offset, 0), BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.22, function() Main:Destroy(); Orb:Destroy() end)
	end

	closeBtn.MouseButton1Click:Connect(function()
		RedlineUI:Confirm({
			Title = "Close the UI?",
			Message = "This will fully unload the interface. You'll need to re-execute the script to bring it back.",
			ConfirmText = "Yes", CancelText = "No", Danger = true,
			OnConfirm = function() Window:Close() end,
		})
	end)

	----------------------------------------------------------------
	-- TABS
	----------------------------------------------------------------
	function Window:CreateTab(tabOpts)
		tabOpts = tabOpts or {}
		local tabTitle = tabOpts.Title or "Tab"
		local tabIcon  = tabOpts.Icon  or "home"

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

		-- Rows flow vertically; each row can hold 1 or 2 cards side-by-side
		-- (kittylol-style 2-col grid), while automatically sizing to content height.
		local PageLayout = Instance.new("UIListLayout")
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 10)
		PageLayout.Parent = Page

		local TabBtn = Instance.new("TextButton")
		TabBtn.Text = ""
		TabBtn.AutoButtonColor = false
		TabBtn.BackgroundColor3 = RedlineUI.Theme.Elevated
		TabBtn.BackgroundTransparency = 1
		TabBtn.Size = UDim2.new(1, 0, 0, 40)
		TabBtn.Parent = TabList
		newCorner(TabBtn, RedlineUI.Theme.CornerRadiusSm)

		-- Minimal, discreet icon (small, low-emphasis — text carries the row)
		local TabIcon = Icons.Create(tabIcon, RedlineUI.Theme.TextFaint, 13)
		TabIcon.AnchorPoint = Vector2.new(0, 0.5)
		TabIcon.Position = isMobile() and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 14, 0.5, 0)
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
			TabLabel.Position = UDim2.new(0, 34, 0.5, 0)
			TabLabel.Size = UDim2.new(1, -42, 0, 18)
			TabLabel.Parent = TabBtn
		end

		local activeBar = Instance.new("Frame")
		activeBar.AnchorPoint = Vector2.new(0, 0.5)
		activeBar.Position = UDim2.new(0, 2, 0.5, 0)
		activeBar.Size = UDim2.new(0, 3, 0, 0)
		activeBar.BackgroundColor3 = RedlineUI.Theme.Accent
		activeBar.Parent = TabBtn
		newCorner(activeBar, UDim.new(1, 0))

		local function setActive(active)
			Page.Visible = active
			tween(TabBtn, { BackgroundTransparency = active and 0.85 or 1,
				BackgroundColor3 = active and RedlineUI.Theme.Accent or RedlineUI.Theme.Elevated }, 0.15)
			tween(activeBar, { Size = UDim2.new(0, 3, 0, active and 22 or 0) }, 0.18, Enum.EasingStyle.Back)
			if TabLabel then
				tween(TabLabel, { TextColor3 = active and RedlineUI.Theme.Text or RedlineUI.Theme.TextDim }, 0.15)
			end
			for _, child in ipairs(TabIcon:GetDescendants()) do
				if child:IsA("Frame") then
					tween(child, { BackgroundColor3 = active and RedlineUI.Theme.AccentGlow or RedlineUI.Theme.TextFaint }, 0.15)
				end
				if child:IsA("UIStroke") then
					tween(child, { Color = active and RedlineUI.Theme.AccentGlow or RedlineUI.Theme.TextFaint }, 0.15)
				end
			end
		end

		TabBtn.MouseButton1Click:Connect(function()
			for _, t in ipairs(Window._tabButtons) do t.setActive(false) end
			setActive(true)
		end)

		TabBtn.MouseEnter:Connect(function()
			if not Page.Visible then tween(TabBtn, { BackgroundTransparency = 0.65 }, 0.12) end
		end)
		TabBtn.MouseLeave:Connect(function()
			if not Page.Visible then tween(TabBtn, { BackgroundTransparency = 1 }, 0.12) end
		end)

		table.insert(Window._tabButtons, { setActive = setActive })
		if #Window._tabButtons == 1 then setActive(true) end

		----------------------------------------------------------------
		-- TAB COMPONENTS
		----------------------------------------------------------------

		local rowCount = 0
		local function nextOrder() rowCount += 1; return rowCount end

		-- Auto-pairing 2-column grid: cards are placed into rows of up to 2,
		-- unless a card requests FullWidth. Mirrors the kittylol card-grid look
		-- while keeping each card's height automatic.
		local currentRow, slotsUsed = nil, 0
		local function getRow(fullWidth)
			if fullWidth or isMobile() then
				currentRow, slotsUsed = nil, 0
				local row = Instance.new("Frame")
				row.BackgroundTransparency = 1
				row.Size = UDim2.new(1, 0, 0, 0)
				row.AutomaticSize = Enum.AutomaticSize.Y
				row.LayoutOrder = nextOrder()
				row.Parent = Page
				return row
			end
			if not currentRow or slotsUsed >= 2 then
				currentRow = Instance.new("Frame")
				currentRow.BackgroundTransparency = 1
				currentRow.Size = UDim2.new(1, 0, 0, 0)
				currentRow.AutomaticSize = Enum.AutomaticSize.Y
				currentRow.LayoutOrder = nextOrder()
				currentRow.Parent = Page
				local rowLayout = Instance.new("UIListLayout")
				rowLayout.FillDirection = Enum.FillDirection.Horizontal
				rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
				rowLayout.Padding = UDim.new(0, 10)
				rowLayout.Parent = currentRow
				slotsUsed = 0
			end
			slotsUsed += 1
			return currentRow
		end

		local function sectionContainer(opts)
			opts = opts or {}
			local fullWidth = opts.FullWidth
			local row = getRow(fullWidth)

			local section = Instance.new("Frame")
			section.BackgroundColor3 = RedlineUI.Theme.Elevated
			if fullWidth or isMobile() then
				section.Size = UDim2.new(1, 0, 0, 0)
			else
				section.Size = UDim2.new(0.5, -5, 0, 0)
			end
			section.AutomaticSize = Enum.AutomaticSize.Y
			section.Parent = row
			newCorner(section, RedlineUI.Theme.CornerRadius)
			newStroke(section, 1, RedlineUI.Theme.Stroke)

			local pad = Instance.new("UIPadding")
			pad.PaddingTop    = UDim.new(0, 14)
			pad.PaddingBottom = UDim.new(0, 14)
			pad.PaddingLeft   = UDim.new(0, 14)
			pad.PaddingRight  = UDim.new(0, 14)
			pad.Parent = section

			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 12)
			layout.Parent = section

			-- Small discreet "sliders" glyph, top-left of the card (kittylol style)
			if opts.Glyph ~= false then
				local glyphRow = Instance.new("Frame")
				glyphRow.BackgroundTransparency = 1
				glyphRow.Size = UDim2.new(1, 0, 0, 14)
				glyphRow.LayoutOrder = -10
				glyphRow.Parent = section

				local glyph = Icons.Create("sliders", RedlineUI.Theme.TextFaint, 13)
				glyph.Position = UDim2.fromOffset(0, 0)
				glyph.Parent = glyphRow

				-- Lock icon, top-right, shown when the card is gated/locked (Aim Hub style)
				if opts.Locked then
					local lock = Icons.Create("lock", RedlineUI.Theme.Locked, 13)
					lock.AnchorPoint = Vector2.new(1, 0)
					lock.Position = UDim2.new(1, 0, 0, 0)
					lock.Parent = glyphRow
				end
			elseif opts.Locked then
				local lock = Icons.Create("lock", RedlineUI.Theme.Locked, 13)
				lock.AnchorPoint = Vector2.new(1, 0)
				lock.Position = UDim2.new(1, 0, 0, 0)
				lock.ZIndex = 3
				lock.Parent = section
			end

			if opts.Locked then
				local lockStroke = section:FindFirstChildOfClass("UIStroke")
				if lockStroke then lockStroke.Color = RedlineUI.Theme.Stroke end
			end

			return section
		end

		-- NEW: Section Header divider
		function Tab:CreateSection(title)
			currentRow, slotsUsed = nil, 0 -- force next card onto a fresh grid row
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 22)
			row.LayoutOrder = nextOrder()
			row.Parent = Page

			local line = Instance.new("Frame")
			line.BackgroundColor3 = RedlineUI.Theme.Stroke
			line.BorderSizePixel = 0
			line.AnchorPoint = Vector2.new(0, 0.5)
			line.Position = UDim2.new(0, 0, 0.5, 0)
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Parent = row

			local bg = Instance.new("Frame")
			bg.BackgroundColor3 = RedlineUI.Theme.Background
			bg.BorderSizePixel = 0
			bg.AnchorPoint = Vector2.new(0, 0.5)
			bg.Position = UDim2.new(0, 0, 0.5, 0)
			bg.Size = UDim2.fromOffset(0, 18)
			bg.AutomaticSize = Enum.AutomaticSize.X
			bg.Parent = row

			local bgPad = Instance.new("UIPadding")
			bgPad.PaddingLeft  = UDim.new(0, 0)
			bgPad.PaddingRight = UDim.new(0, 8)
			bgPad.Parent = bg

			local dot = Instance.new("Frame")
			dot.BackgroundColor3 = RedlineUI.Theme.Accent
			dot.BorderSizePixel = 0
			dot.AnchorPoint = Vector2.new(0, 0.5)
			dot.Position = UDim2.fromOffset(0, 9)
			dot.Size = UDim2.fromOffset(5, 5)
			dot.Parent = bg
			newCorner(dot, UDim.new(1, 0))

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Font = RedlineUI.Theme.FontBold
			lbl.Text = (title or "Section"):upper()
			lbl.TextColor3 = RedlineUI.Theme.TextFaint
			lbl.TextSize = 10
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.AnchorPoint = Vector2.new(0, 0.5)
			lbl.Position = UDim2.fromOffset(12, 9)
			lbl.Size = UDim2.fromOffset(200, 14)
			lbl.Parent = bg

			return row
		end

		function Tab:CreateButton(o)
			o = o or {}
			local row = sectionContainer({ Locked = o.Locked, FullWidth = o.FullWidth })
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

			if o.Description then
				local desc = Instance.new("TextLabel")
				desc.BackgroundTransparency = 1
				desc.Font = RedlineUI.Theme.Font
				desc.Text = o.Description
				desc.TextColor3 = RedlineUI.Theme.TextDim
				desc.TextSize = 12
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.Size = UDim2.new(1, -28, 0, 14)
				desc.Position = UDim2.fromOffset(0, 20)
				desc.Parent = btn
				btn.Size = UDim2.new(1, 0, 0, 36)
			end

			local arrow = Icons.Create("chevronDown", RedlineUI.Theme.Accent, 16)
			arrow.Rotation = -90
			arrow.AnchorPoint = Vector2.new(1, 0.5)
			arrow.Position = UDim2.new(1, 0, 0.5, 0)
			arrow.Parent = btn

			btn.MouseEnter:Connect(function()
				tween(row, { BackgroundColor3 = RedlineUI.Theme.ElevatedHover }, 0.12)
				tween(arrow, { Rotation = -80 }, 0.15)
			end)
			btn.MouseLeave:Connect(function()
				tween(row, { BackgroundColor3 = RedlineUI.Theme.Elevated }, 0.12)
				tween(arrow, { Rotation = -90 }, 0.15)
			end)
			btn.MouseButton1Click:Connect(function()
				tween(row, { BackgroundColor3 = RedlineUI.Theme.AccentMuted }, 0.08)
				task.delay(0.08, function() tween(row, { BackgroundColor3 = RedlineUI.Theme.Elevated }, 0.2) end)
				if o.Callback then o.Callback() end
			end)

			return row
		end

		function Tab:CreateToggle(o)
			o = o or {}
			local state = o.Default or false
			local row   = sectionContainer({ Locked = o.Locked, FullWidth = o.FullWidth })
			row.LayoutOrder = nextOrder()

			local holder = Instance.new("Frame")
			holder.BackgroundTransparency = 1
			holder.Size = UDim2.new(1, 0, 0, 22)
			holder.Parent = row

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Toggle"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -52, 1, 0)
			label.Parent = holder

			if o.Description then
				local desc = Instance.new("TextLabel")
				desc.BackgroundTransparency = 1
				desc.Font = RedlineUI.Theme.Font
				desc.Text = o.Description
				desc.TextColor3 = RedlineUI.Theme.TextDim
				desc.TextSize = 12
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.Size = UDim2.new(1, -52, 0, 14)
				desc.Position = UDim2.fromOffset(0, 22)
				desc.Parent = holder
				holder.Size = UDim2.new(1, 0, 0, 36)
			end

			local switch = Instance.new("TextButton")
			switch.Text = ""
			switch.AutoButtonColor = false
			switch.AnchorPoint = Vector2.new(1, 0.5)
			switch.Position = UDim2.new(1, 0, 0.5, 0)
			switch.Size = UDim2.fromOffset(42, 24)
			switch.BackgroundColor3 = (o.Locked and RedlineUI.Theme.Stroke) or (state and RedlineUI.Theme.Accent or RedlineUI.Theme.Stroke)
			switch.Active = not o.Locked
			switch.Parent = holder
			newCorner(switch, UDim.new(1, 0))

			if o.Locked then
				label.TextColor3 = RedlineUI.Theme.TextDim
			end

			-- inner track line for depth
			local switchInner = Instance.new("Frame")
			switchInner.BackgroundTransparency = 0.85
			switchInner.BackgroundColor3 = Color3.new(0, 0, 0)
			switchInner.Size = UDim2.new(1, -4, 1, -4)
			switchInner.AnchorPoint = Vector2.new(0.5, 0.5)
			switchInner.Position = UDim2.fromScale(0.5, 0.5)
			switchInner.Parent = switch
			newCorner(switchInner, UDim.new(1, 0))

			local knob = Instance.new("Frame")
			knob.Size = UDim2.fromOffset(18, 18)
			knob.AnchorPoint = Vector2.new(0, 0.5)
			knob.Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			knob.BackgroundColor3 = Color3.new(1, 1, 1)
			knob.ZIndex = 2
			knob.Parent = switch
			newCorner(knob, UDim.new(1, 0))

			local function setState(v, fireCallback)
				state = v
				tween(switch, { BackgroundColor3 = state and RedlineUI.Theme.Accent or RedlineUI.Theme.Stroke }, 0.15)
				tween(knob, { Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.15, Enum.EasingStyle.Back)
				if fireCallback ~= false and o.Callback then o.Callback(state) end
			end

			switch.MouseButton1Click:Connect(function()
				if o.Locked then return end
				setState(not state)
			end)
			if state and o.Callback then o.Callback(state) end

			return { Set = function(v) setState(v, false) end, Get = function() return state end }
		end

		-- FIXED SLIDER
		function Tab:CreateSlider(o)
			o = o or {}
			local min      = o.Min or 0
			local max      = o.Max or 100
			local value    = math.clamp(o.Default or min, min, max)
			local decimals = o.Decimals or 0

			local row = sectionContainer({ Locked = o.Locked, FullWidth = o.FullWidth })
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
			label.Size = UDim2.new(1, -62, 1, 0)
			label.Parent = topRow

			local valueLabel = Instance.new("TextLabel")
			valueLabel.BackgroundTransparency = 1
			valueLabel.Font = RedlineUI.Theme.FontSemibold
			valueLabel.Text = tostring(value) .. (o.Suffix and (" " .. o.Suffix) or "")
			valueLabel.TextColor3 = RedlineUI.Theme.Accent
			valueLabel.TextSize = 13
			valueLabel.TextXAlignment = Enum.TextXAlignment.Right
			valueLabel.AnchorPoint = Vector2.new(1, 0)
			valueLabel.Position = UDim2.new(1, 0, 0, 0)
			valueLabel.Size = UDim2.fromOffset(56, 18)
			valueLabel.Parent = topRow

			-- track wrapper (holds track + invisible dragger)
			local trackWrap = Instance.new("Frame")
			trackWrap.BackgroundTransparency = 1
			trackWrap.Size = UDim2.new(1, 0, 0, 20)
			trackWrap.Parent = row

			local track = Instance.new("Frame")
			track.BackgroundColor3 = RedlineUI.Theme.Stroke
			track.AnchorPoint = Vector2.new(0, 0.5)
			track.Position = UDim2.new(0, 0, 0.5, 0)
			track.Size = UDim2.new(1, 0, 0, 6)
			track.Parent = trackWrap
			newCorner(track, UDim.new(1, 0))

			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = RedlineUI.Theme.Accent
			fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			fill.Parent = track
			newCorner(fill, UDim.new(1, 0))

			-- glow on fill
			local fillGlow = newStroke(fill, 3, RedlineUI.Theme.AccentDim)
			fillGlow.Transparency = 0.5

			local knob = Instance.new("Frame")
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
			knob.Size = UDim2.fromOffset(16, 16)
			knob.BackgroundColor3 = Color3.new(1, 1, 1)
			knob.ZIndex = 3
			knob.Parent = track
			newCorner(knob, UDim.new(1, 0))
			newStroke(knob, 2, RedlineUI.Theme.Accent)

			-- FIX: dragger covers the entire trackWrap (not just the track)
			-- and uses track's absolute position for alpha calculation
			local dragger = Instance.new("TextButton")
			dragger.Text = ""
			dragger.BackgroundTransparency = 1
			dragger.Size = UDim2.new(1, 0, 1, 0)
			dragger.ZIndex = 4
			dragger.Parent = trackWrap

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
					-- use track's absolute position for proper alpha
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(alpha)
					tween(knob, { Size = UDim2.fromOffset(18, 18) }, 0.1)
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
					if sliding then
						sliding = false
						tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.1)
					end
				end
			end)

			return {
				Set = function(v) setFromAlpha((v - min) / (max - min)) end,
				Get = function() return value end,
			}
		end

		function Tab:CreateInput(o)
			o = o or {}
			local row = sectionContainer({ Locked = o.Locked, FullWidth = o.FullWidth })
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
			box.Size = UDim2.new(1, 0, 0, 36)
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
			textBox.Position = UDim2.fromOffset(12, 0)
			textBox.Parent = box

			textBox.Focused:Connect(function()
				tween(boxStroke, { Color = RedlineUI.Theme.Accent, Thickness = 1.5 }, 0.15)
			end)
			textBox.FocusLost:Connect(function(enter)
				tween(boxStroke, { Color = RedlineUI.Theme.Stroke, Thickness = 1 }, 0.15)
				if o.Callback then o.Callback(textBox.Text, enter) end
			end)

			return { Set = function(v) textBox.Text = v end, Get = function() return textBox.Text end }
		end

		function Tab:CreateKeybind(o)
			o = o or {}
			local currentKey = o.Default or Enum.KeyCode.RightShift
			local listening  = false

			local row = sectionContainer({ Locked = o.Locked, FullWidth = o.FullWidth })
			row.LayoutOrder = nextOrder()

			local holder = Instance.new("Frame")
			holder.BackgroundTransparency = 1
			holder.Size = UDim2.new(1, 0, 0, 20)
			holder.Parent = row

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Keybind"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -110, 1, 0)
			label.Parent = holder

			local keyBtn = Instance.new("TextButton")
			keyBtn.AutoButtonColor = false
			keyBtn.Font = RedlineUI.Theme.FontSemibold
			keyBtn.Text = currentKey.Name
			keyBtn.TextColor3 = RedlineUI.Theme.Accent
			keyBtn.TextSize = 12
			keyBtn.BackgroundColor3 = RedlineUI.Theme.Background
			keyBtn.AnchorPoint = Vector2.new(1, 0.5)
			keyBtn.Position = UDim2.new(1, 0, 0.5, 0)
			keyBtn.Size = UDim2.fromOffset(100, 30)
			keyBtn.Parent = holder
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
					if input.KeyCode == currentKey and o.OnPress then o.OnPress() end
				end
			end)

			return { Set = function(k) currentKey = k; keyBtn.Text = k.Name end, Get = function() return currentKey end }
		end

		function Tab:CreateDropdown(o)
			o = o or {}
			local options  = o.Options or {}
			local selected = o.Default or options[1]
			local open     = false

			local row = sectionContainer({ Locked = o.Locked, FullWidth = o.FullWidth, Glyph = false })
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
			box.Size = UDim2.new(1, 0, 0, 36)
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
			selectedLabel.Position = UDim2.fromOffset(12, 0)
			selectedLabel.Size = UDim2.new(1, -40, 1, 0)
			selectedLabel.ZIndex = 5
			selectedLabel.Parent = box

			-- Inline chevron (avoids Icons.Create rendering bugs)
			local chevronCanvas = Instance.new("Frame")
			chevronCanvas.Size = UDim2.fromOffset(14, 14)
			chevronCanvas.AnchorPoint = Vector2.new(1, 0.5)
			chevronCanvas.Position = UDim2.new(1, -12, 0.5, 0)
			chevronCanvas.BackgroundTransparency = 1
			chevronCanvas.ZIndex = 5
			chevronCanvas.Parent = box
			local chLine1 = iconLine(chevronCanvas, 1, 4, 7, 10, RedlineUI.Theme.TextDim, 1.6)
			local chLine2 = iconLine(chevronCanvas, 7, 10, 13, 4, RedlineUI.Theme.TextDim, 1.6)
			chLine1.ZIndex = 5; chLine2.ZIndex = 5

			-- Dropdown list parented to ScreenGui so it's NEVER clipped by parents
			local list = Instance.new("Frame")
			list.BackgroundColor3 = RedlineUI.Theme.Elevated
			list.Size = UDim2.fromOffset(0, 0)
			list.ClipsDescendants = true
			list.ZIndex = 200
			list.Visible = false
			list.Parent = ScreenGui
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
				optBtn.Size = UDim2.new(1, 0, 0, 36)
				optBtn.ZIndex = 201
				optBtn.Parent = list

				local optLabel = Instance.new("TextLabel")
				optLabel.BackgroundTransparency = 1
				optLabel.Font = RedlineUI.Theme.Font
				optLabel.Text = tostring(opt)
				optLabel.TextColor3 = RedlineUI.Theme.TextDim
				optLabel.TextSize = 13
				optLabel.TextXAlignment = Enum.TextXAlignment.Left
				optLabel.Position = UDim2.fromOffset(14, 0)
				optLabel.Size = UDim2.new(1, -18, 1, 0)
				optLabel.ZIndex = 201
				optLabel.Parent = optBtn

				optBtn.MouseEnter:Connect(function()
					tween(optBtn, { BackgroundTransparency = 0.78 }, 0.1)
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
					list.Visible = false
					tween(boxStroke, { Color = RedlineUI.Theme.Stroke }, 0.15)
					-- animate chevron back
					tween(chevronCanvas, { Rotation = 0 }, 0.16)
				end)
			end

			-- Reposition the floating list to align with the box each time it opens
			local function repositionList()
				local absPos  = box.AbsolutePosition
				local absSize = box.AbsoluteSize
				local itemH   = 36
				local totalH  = math.min(#options * itemH, 170)
				list.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
				list.Size     = UDim2.fromOffset(absSize.X, totalH)
			end

			box.MouseButton1Click:Connect(function()
				open = not open
				if open then
					repositionList()
					list.Visible = true
					list.Size = UDim2.fromOffset(list.Size.X.Offset, 0)
					tween(list, { Size = UDim2.fromOffset(list.Size.X.Offset, math.min(#options * 36, 170)) }, 0.18, Enum.EasingStyle.Quint)
					tween(boxStroke, { Color = RedlineUI.Theme.Accent }, 0.15)
					tween(chevronCanvas, { Rotation = 180 }, 0.18)
				else
					list.Visible = false
					tween(boxStroke, { Color = RedlineUI.Theme.Stroke }, 0.15)
					tween(chevronCanvas, { Rotation = 0 }, 0.16)
				end
			end)

			-- Close when clicking elsewhere
			UserInputService.InputBegan:Connect(function(input)
				if open and input.UserInputType == Enum.UserInputType.MouseButton1 then
					-- small delay so optBtn clicks register first
					task.delay(0.05, function()
						if open then
							open = false
							list.Visible = false
							tween(boxStroke, { Color = RedlineUI.Theme.Stroke }, 0.15)
							tween(chevronCanvas, { Rotation = 0 }, 0.16)
						end
					end)
				end
			end)

			return {
				Set = function(v) selected = v; selectedLabel.Text = tostring(v) end,
				Get = function() return selected end,
			}
		end

		function Tab:CreateColorPicker(o)
			o = o or {}
			local color = o.Default or Color3.fromRGB(120, 18, 26)

			local row = sectionContainer({ Locked = o.Locked, FullWidth = o.FullWidth })
			row.LayoutOrder = nextOrder()

			local topRow = Instance.new("Frame")
			topRow.BackgroundTransparency = 1
			topRow.Size = UDim2.new(1, 0, 0, 22)
			topRow.Parent = row

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = RedlineUI.Theme.FontSemibold
			label.Text = o.Title or "Color"
			label.TextColor3 = RedlineUI.Theme.Text
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -52, 1, 0)
			label.Parent = topRow

			local swatch = Instance.new("TextButton")
			swatch.Text = ""
			swatch.AutoButtonColor = false
			swatch.AnchorPoint = Vector2.new(1, 0.5)
			swatch.Position = UDim2.new(1, 0, 0.5, 0)
			swatch.Size = UDim2.fromOffset(40, 22)
			swatch.BackgroundColor3 = color
			swatch.Parent = topRow
			newCorner(swatch, RedlineUI.Theme.CornerRadiusSm)
			newStroke(swatch, 1, RedlineUI.Theme.StrokeLight)

			local panel = Instance.new("Frame")
			panel.BackgroundTransparency = 1
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
				chLabel.Font = RedlineUI.Theme.FontBold
				chLabel.Text = name
				chLabel.TextColor3 = RedlineUI.Theme.Accent
				chLabel.TextSize = 11
				chLabel.TextXAlignment = Enum.TextXAlignment.Left
				chLabel.Size = UDim2.fromOffset(14, 22)
				chLabel.Parent = holder

				local trackWrap = Instance.new("Frame")
				trackWrap.BackgroundTransparency = 1
				trackWrap.Position = UDim2.fromOffset(22, 0)
				trackWrap.Size = UDim2.new(1, -22, 1, 0)
				trackWrap.Parent = holder

				local track = Instance.new("Frame")
				track.BackgroundColor3 = RedlineUI.Theme.Stroke
				track.AnchorPoint = Vector2.new(0, 0.5)
				track.Position = UDim2.new(0, 0, 0.5, 0)
				track.Size = UDim2.new(1, 0, 0, 6)
				track.Parent = trackWrap
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
				dragger.ZIndex = 2
				dragger.Parent = trackWrap

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

			local function bindChannel(track, fill, dragger, setter)
				local sliding = false
				dragger.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = true
						local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
						fill.Size = UDim2.new(alpha, 0, 1, 0); setter(alpha * 255); updateColor()
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
						fill.Size = UDim2.new(alpha, 0, 1, 0); setter(alpha * 255); updateColor()
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
				tween(panel, { Size = UDim2.new(1, 0, 0, expanded and 96 or 0) }, 0.2, Enum.EasingStyle.Quint)
			end)

			return {
				Set = function(c)
					color = c
					r, g, b = c.R * 255, c.G * 255, c.B * 255
					swatch.BackgroundColor3 = c
					rFill.Size = UDim2.new(r/255, 0, 1, 0)
					gFill.Size = UDim2.new(g/255, 0, 1, 0)
					bFill.Size = UDim2.new(b/255, 0, 1, 0)
				end,
				Get = function() return color end,
			}
		end

		function Tab:CreateLabel(text)
			local row = sectionContainer({ FullWidth = true, Glyph = false })
			row.LayoutOrder = nextOrder()
			row.BackgroundTransparency = 1
			local s = row:FindFirstChildOfClass("UIStroke")
			if s then s:Destroy() end

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Font = RedlineUI.Theme.Font
			lbl.Text = text
			lbl.TextColor3 = RedlineUI.Theme.TextDim
			lbl.TextSize = 13
			lbl.TextWrapped = true
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Size = UDim2.new(1, 0, 0, 0)
			lbl.AutomaticSize = Enum.AutomaticSize.Y
			lbl.Parent = row

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
