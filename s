-- ╔══════════════════════════════════════════════════════════════╗
--                    STALKER GUI MODULE
--                    Version: 4.1 — Close Anim + Spectate Fix
-- ╚══════════════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local PerformanceManager = {
	lastUpdate          = 0,
	updateInterval      = 0.5,
	behaviorUpdateInterval = 0.1,
}

local stalkGui           = nil
local stalkLoopActive    = false
local updateConnection   = nil
local behaviorConnection = nil
local behaviorTracker    = {}
local isSpectating       = false

-- ╔══════════════════════════════════════════════════════════════╗
--                         PALETTE
-- ╚══════════════════════════════════════════════════════════════╝

local C = {
	-- Backgrounds
	BG       = Color3.fromRGB(6,   6,   9),
	SURFACE  = Color3.fromRGB(11,  11,  15),
	CARD     = Color3.fromRGB(16,  16,  22),
	CARD2    = Color3.fromRGB(13,  13,  18),

	-- Accent — crimson
	RED      = Color3.fromRGB(220, 40,  55),
	RED_DARK = Color3.fromRGB(100, 18,  26),
	RED_DIM  = Color3.fromRGB(42,  10,  14),
	RED_GLOW = Color3.fromRGB(255, 90,  100),

	-- Text
	WHITE    = Color3.fromRGB(240, 240, 248),
	MUTED    = Color3.fromRGB(120, 120, 138),
	DIM      = Color3.fromRGB(55,  55,  68),

	-- Borders
	BORDER   = Color3.fromRGB(30,  30,  42),
	BORDER_LT= Color3.fromRGB(50,  50,  66),

	-- Status
	GREEN    = Color3.fromRGB(45,  210, 100),
	AMBER    = Color3.fromRGB(255, 190, 45),
	BLUE     = Color3.fromRGB(80,  160, 255),
}

-- ╔══════════════════════════════════════════════════════════════╗
--                        HELPERS
-- ╚══════════════════════════════════════════════════════════════╝

local function formatNumber(num)
	-- math.floor em todas as divisões: nunca arredonda pra cima
	if num >= 1e9 then
		local n = math.floor(num / 1e7) / 100  -- 2 casas, truncado
		return string.format("%.2fB", n)
	elseif num >= 1e6 then
		local n = math.floor(num / 1e4) / 100
		return string.format("%.2fM", n)
	elseif num >= 1e3 then
		local n = math.floor(num / 100) / 10   -- 1 casa, truncado
		return string.format("%.1fK", n)
	else
		return tostring(math.floor(num))
	end
end

local function formatTime(seconds)
	local h = math.floor(seconds/3600)
	local m = math.floor((seconds%3600)/60)
	local s = math.floor(seconds%60)
	if h > 0 then return string.format("%dh %dm %ds", h, m, s)
	elseif m > 0 then return string.format("%dm %ds", m, s)
	else return string.format("%ds", s) end
end

local function getDistance(target)
	local lp = Players.LocalPlayer
	if not lp.Character or not target.Character then return "N/A" end
	local r1 = lp.Character:FindFirstChild("HumanoidRootPart")
	local r2 = target.Character:FindFirstChild("HumanoidRootPart")
	if r1 and r2 then return string.format("%.0f studs", (r1.Position-r2.Position).Magnitude) end
	return "N/A"
end

local function getHealth(target)
	if not target.Character then return "0 / 0" end
	local h = target.Character:FindFirstChild("Humanoid")
	if h then return string.format("%.0f / %.0f", h.Health, h.MaxHealth) end
	return "0 / 0"
end

local function getGamepasses(target)
	local passes = {}
	local og = target:FindFirstChild("ownedGamepasses")
	if og then
		for _, name in ipairs({"x2 Durability","x2 Strength","x2 Rep Time","+2 Pet Slots"}) do
			local p = og:FindFirstChild(name)
			if p and p.Value then table.insert(passes, name) end
		end
	end
	return #passes > 0 and table.concat(passes, ", ") or "None"
end

local function getBadgeCount(target)
	local ob = target:FindFirstChild("ownedBadges")
	if not ob then return "0" end
	local count = 0
	for _, b in pairs(ob:GetChildren()) do
		if b:IsA("BoolValue") and b.Value then count += 1 end
	end
	return tostring(count)
end

local function getImportantBadges(target)
	local badges = {}
	local ob = target:FindFirstChild("ownedBadges")
	if ob then
		for _, name in ipairs({"Eternal Gym","Frost Gym","Legends Gym","Mythical Gym","1,000,000 Strength","20 Rebirths"}) do
			local b = ob:FindFirstChild(name)
			if b and b.Value then table.insert(badges, name) end
		end
	end
	return #badges > 0 and table.concat(badges, ", ") or "None"
end

-- ╔══════════════════════════════════════════════════════════════╗
--                    BEHAVIOR TRACKING
-- ╚══════════════════════════════════════════════════════════════╝

local function initBehaviorTracker(target)
	behaviorTracker[target.UserId] = {
		lastPosition=nil, lastMoveTime=tick(), lastUpdateTime=tick(),
		afkTime=0, trainingTime=0, idleTime=0,
		deathCount=0, jumpCount=0, lastJumpTime=0,
		isJumping=false, isDead=false, startTime=tick()
	}
end

local function updateBehavior(target)
	local tr = behaviorTracker[target.UserId]
	if not tr then return end
	local char = target.Character
	if not char then return end
	local hum  = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if hum and root then
		local pos = root.Position
		local now = tick()
		local dt  = now - (tr.lastUpdateTime or now)
		tr.lastUpdateTime = now
		if tr.lastPosition then
			if (pos - tr.lastPosition).Magnitude > 0.5 then
				tr.lastMoveTime = now; tr.afkTime = 0
			else
				tr.afkTime  = now - tr.lastMoveTime
				tr.idleTime += dt
			end
		end
		tr.lastPosition = pos
		local m = target:FindFirstChild("machineInUse")
		if m and m.Value then tr.trainingTime += dt end
		if hum:GetState() == Enum.HumanoidStateType.Jumping then
			if not tr.isJumping then tr.isJumping=true; tr.jumpCount+=1; tr.lastJumpTime=now end
		else tr.isJumping=false end
		if hum.Health <= 0 and not tr.isDead then tr.deathCount+=1; tr.isDead=true
		elseif hum.Health > 0 then tr.isDead=false end
	end
end

-- ╔══════════════════════════════════════════════════════════════╗
--                         DRAG
-- ╚══════════════════════════════════════════════════════════════╝

local function makeDraggable(frame, handle)
	local h = handle or frame
	local dragging, dragStart, startPos
	h.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = i.Position
			startPos  = frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	h.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
		or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

-- ╔══════════════════════════════════════════════════════════════╗
--                       UI PRIMITIVES
-- ╚══════════════════════════════════════════════════════════════╝

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
end

local function stroke(p, col, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color        = col   or C.BORDER
	s.Thickness    = thick or 1
	s.Transparency = trans or 0
	s.Parent       = p
	return s
end

local function lbl(p, txt, col, font, sz, size, pos, zi, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel        = 0
	l.Text                   = txt
	l.TextColor3             = col   or C.WHITE
	l.Font                   = font  or Enum.Font.GothamMedium
	l.TextSize               = sz    or 13
	l.Size                   = size  or UDim2.new(1,0,0,20)
	l.Position               = pos   or UDim2.new(0,0,0,0)
	l.ZIndex                 = zi    or 5
	l.TextXAlignment         = align or Enum.TextXAlignment.Left
	l.TextWrapped            = true
	l.Parent                 = p
	return l
end

local function tween(obj, info, props)
	TweenService:Create(obj, info, props):Play()
end

-- ╔══════════════════════════════════════════════════════════════╗
--                        MAIN GUI
-- ╚══════════════════════════════════════════════════════════════╝

local function createStalkerGUI(target)
	if not target or not target.Parent then warn("❌ Invalid target"); return end

	if stalkGui        then stalkGui:Destroy()               end
	if updateConnection   then updateConnection:Disconnect()   end
	if behaviorConnection then behaviorConnection:Disconnect() end

	stalkLoopActive = true
	if not behaviorTracker[target.UserId] then initBehaviorTracker(target) end

	local VP = workspace.CurrentCamera.ViewportSize

	-- Responsive sizing
	local W, H
	if isMobile then
		W = math.clamp(math.floor(VP.X * 0.78), 260, 310)
		H = math.clamp(math.floor(VP.Y * 0.68), 360, 480)
	else
		W = 400
		H = 700
	end

	-- ── ROOT GUI ────────────────────────────────────────────────
	local gui = Instance.new("ScreenGui")
	gui.Name           = "StalkGui_Premium"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	gui.Parent         = CoreGui
	stalkGui = gui

	-- No background vignette
	local vignette = Instance.new("Frame")  -- stub kept for compatibility
	vignette.BackgroundTransparency = 1
	vignette.Size = UDim2.new(0,0,0,0)
	vignette.Parent = gui

	-- ── MAIN WINDOW ─────────────────────────────────────────────
	local win = Instance.new("Frame")
	win.Size            = UDim2.new(0, W, 0, H)
	win.Position        = UDim2.new(0.5, 0, 0.5, 0)
	win.AnchorPoint     = Vector2.new(0.5, 0.5)
	win.BackgroundColor3= C.BG
	win.BorderSizePixel = 0
	win.ZIndex          = 10
	win.Active          = true
	win.Parent          = gui
	corner(win, 16)

	-- Subtle outer border
	local winStroke = stroke(win, C.BORDER_LT, 1, 0)

	-- Accent glow line at top
	local glowBar = Instance.new("Frame")
	glowBar.Size             = UDim2.new(0.6, 0, 0, 1)
	glowBar.Position         = UDim2.new(0.2, 0, 0, 0)
	glowBar.BackgroundColor3 = C.RED
	glowBar.BorderSizePixel  = 0
	glowBar.ZIndex           = 15
	glowBar.Parent           = win
	corner(glowBar, 1)

	-- Entrance animation
	win.BackgroundTransparency = 1
	tween(win, TweenInfo.new(0.28, Enum.EasingStyle.Quint), {BackgroundTransparency=0})

	makeDraggable(win)

	-- ── HEADER ──────────────────────────────────────────────────
	local HDR_H = isMobile and 52 or 92

	local hdr = Instance.new("Frame")
	hdr.Size             = UDim2.new(1,0,0,HDR_H)
	hdr.BackgroundColor3 = C.SURFACE
	hdr.BorderSizePixel  = 0
	hdr.ZIndex           = 11
	hdr.Parent           = win
	corner(hdr, 16)

	-- patch rounded bottom corners of header
	local hpatch = Instance.new("Frame")
	hpatch.Size             = UDim2.new(1,0,0,16)
	hpatch.Position         = UDim2.new(0,0,1,-16)
	hpatch.BackgroundColor3 = C.SURFACE
	hpatch.BorderSizePixel  = 0
	hpatch.ZIndex           = 11
	hpatch.Parent           = hdr

	-- thin red accent stripe at top
	local topStripe = Instance.new("Frame")
	topStripe.Size             = UDim2.new(1,0,0,2)
	topStripe.BackgroundColor3 = C.RED
	topStripe.BorderSizePixel  = 0
	topStripe.ZIndex           = 12
	topStripe.Parent           = hdr
	corner(topStripe, 16)

	-- Divider line at bottom of header
	local divider = Instance.new("Frame")
	divider.Size             = UDim2.new(1, -24, 0, 1)
	divider.Position         = UDim2.new(0, 12, 1, -1)
	divider.BackgroundColor3 = C.BORDER_LT
	divider.BorderSizePixel  = 0
	divider.ZIndex           = 12
	divider.Parent           = hdr

	-- Avatar
	local AV = isMobile and 32 or 56
	local avBg = Instance.new("Frame")
	avBg.Size             = UDim2.new(0, AV+4, 0, AV+4)
	avBg.Position         = UDim2.new(0, 14, 0.5, -((AV+4)/2))
	avBg.BackgroundColor3 = C.RED_DIM
	avBg.BorderSizePixel  = 0
	avBg.ZIndex           = 12
	avBg.Parent           = hdr
	corner(avBg, (AV+4)/2)
	stroke(avBg, C.RED, 1.5, 0.25)

	local avatar = Instance.new("ImageLabel")
	avatar.Size                   = UDim2.new(0, AV, 0, AV)
	avatar.Position               = UDim2.new(0.5, 0, 0.5, 0)
	avatar.AnchorPoint            = Vector2.new(0.5, 0.5)
	avatar.BackgroundTransparency = 1
	avatar.BorderSizePixel        = 0
	avatar.ZIndex                 = 13
	avatar.Parent                 = avBg
	corner(avatar, AV/2)
	pcall(function()
		avatar.Image = Players:GetUserThumbnailAsync(
			target.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)

	-- Live status dot
	local dot = Instance.new("Frame")
	dot.Size             = UDim2.new(0, 9, 0, 9)
	dot.Position         = UDim2.new(1, -2, 1, -2)
	dot.BackgroundColor3 = C.GREEN
	dot.BorderSizePixel  = 0
	dot.ZIndex           = 14
	dot.Parent           = avBg
	corner(dot, 5)
	stroke(dot, C.BG, 1.5, 0)

	-- Name & sub-info
	local TX = AV + 24
	lbl(hdr,
		target.Name,
		C.WHITE, Enum.Font.GothamBold,
		isMobile and 15 or 19,
		UDim2.new(1,-(TX+50),0,isMobile and 16 or 26),
		UDim2.new(0,TX,0,isMobile and 10 or 18),
		12)

	lbl(hdr,
		"@"..target.Name.."  ·  "..target.AccountAge.."d old",
		C.MUTED, Enum.Font.Gotham,
		isMobile and 10 or 11,
		UDim2.new(1,-(TX+50),0,16),
		UDim2.new(0,TX,0,isMobile and 26 or 48),
		12)

	-- Target tag pill
	local pillW = isMobile and 52 or 72
	local pill = Instance.new("Frame")
	pill.Size             = UDim2.new(0, pillW, 0, isMobile and 14 or 19)
	pill.Position         = UDim2.new(0, TX, 0, isMobile and 38 or 70)
	pill.BackgroundColor3 = C.RED_DIM
	pill.BorderSizePixel  = 0
	pill.ZIndex           = 12
	pill.Parent           = hdr
	corner(pill, 4)
	stroke(pill, C.RED, 1, 0.5)
	lbl(pill, "● TRACKING", C.RED_GLOW, Enum.Font.GothamBold,
		isMobile and 8 or 9,
		UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), 13,
		Enum.TextXAlignment.Center)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size             = UDim2.new(0, 28, 0, 28)
	closeBtn.Position         = UDim2.new(1,-36,0,isMobile and 13 or 18)
	closeBtn.BackgroundColor3 = C.RED_DIM
	closeBtn.Text             = "X"
	closeBtn.TextColor3       = C.RED_GLOW
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextSize         = isMobile and 13 or 14
	closeBtn.TextScaled       = false
	closeBtn.BorderSizePixel  = 0
	closeBtn.ZIndex           = 13
	closeBtn.Parent           = hdr
	corner(closeBtn, 8)
	stroke(closeBtn, C.RED, 1, 0.45)

	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, TweenInfo.new(0.15), {BackgroundColor3=C.RED})
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, TweenInfo.new(0.15), {BackgroundColor3=C.RED_DIM})
	end)
	closeBtn.MouseButton1Click:Connect(function()
		stalkLoopActive = false
		if updateConnection   then updateConnection:Disconnect()   end
		if behaviorConnection then behaviorConnection:Disconnect() end
		if isSpectating then
			local lp = Players.LocalPlayer
			if lp.Character then
				local lh = lp.Character:FindFirstChild("Humanoid")
				if lh then workspace.CurrentCamera.CameraSubject = lh end
			end
			isSpectating = false
		end
		-- Slide down + fade out the window
		local exitInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		local curPos = win.Position
		tween(win, exitInfo, {
			Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset + 20),
			BackgroundTransparency = 1,
		})
		for _, child in ipairs(win:GetDescendants()) do
			if child:IsA("Frame") or child:IsA("ScrollingFrame") then
				pcall(function() tween(child, exitInfo, {BackgroundTransparency = 1}) end)
			end
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				pcall(function()
					tween(child, exitInfo, {BackgroundTransparency = 1, TextTransparency = 1})
				end)
			end
			if child:IsA("ImageLabel") then
				pcall(function()
					tween(child, exitInfo, {BackgroundTransparency = 1, ImageTransparency = 1})
				end)
			end
			if child:IsA("UIStroke") then
				pcall(function() tween(child, exitInfo, {Transparency = 1}) end)
			end
		end

		task.delay(0.32, function()
			stalkGui:Destroy()
		end)
	end)

	-- ── SCROLL AREA ─────────────────────────────────────────────
	local FOOTER_H = isMobile and 46 or 64

	local scr = Instance.new("ScrollingFrame")
	scr.Size                   = UDim2.new(1,-12,1,-(HDR_H+FOOTER_H+16))
	scr.Position               = UDim2.new(0,6,0,HDR_H+6)
	scr.BackgroundTransparency = 1
	scr.BorderSizePixel        = 0
	scr.ScrollBarThickness     = isMobile and 2 or 3
	scr.ScrollBarImageColor3   = C.RED
	scr.CanvasSize             = UDim2.new(0,0,0,0)
	scr.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	scr.ClipsDescendants       = true
	scr.ZIndex                 = 10
	scr.Parent                 = win

	local scrList = Instance.new("UIListLayout")
	scrList.Padding               = UDim.new(0, 4)
	scrList.SortOrder             = Enum.SortOrder.LayoutOrder
	scrList.HorizontalAlignment   = Enum.HorizontalAlignment.Center
	scrList.Parent                = scr

	local scrPad = Instance.new("UIPadding")
	scrPad.PaddingTop    = UDim.new(0, 8)
	scrPad.PaddingBottom = UDim.new(0, 8)
	scrPad.PaddingLeft   = UDim.new(0, 2)
	scrPad.PaddingRight  = UDim.new(0, 2)
	scrPad.Parent        = scr

	-- ── SECTION BUILDER ─────────────────────────────────────────
	local layoutOrder = 0
	local function nextOrder() layoutOrder += 1; return layoutOrder end

	local function makeSection(title)
		local f = Instance.new("Frame")
		f.Size                = UDim2.new(1,0,0,isMobile and 16 or 24)
		f.BackgroundTransparency = 1
		f.LayoutOrder         = nextOrder()
		f.ZIndex              = 11
		f.Parent              = scr

		-- lines
		local ll = Instance.new("Frame")
		ll.Size             = UDim2.new(0.14,0,0,1)
		ll.Position         = UDim2.new(0,0,0.5,0)
		ll.BackgroundColor3 = C.DIM
		ll.BorderSizePixel  = 0; ll.ZIndex=12; ll.Parent=f

		local lr = Instance.new("Frame")
		lr.Size             = UDim2.new(0.14,0,0,1)
		lr.Position         = UDim2.new(0.86,0,0.5,0)
		lr.BackgroundColor3 = C.DIM
		lr.BorderSizePixel  = 0; lr.ZIndex=12; lr.Parent=f

		lbl(f, title,
			C.MUTED, Enum.Font.GothamBold,
			isMobile and 8 or 10,
			UDim2.new(0.72,0,1,0),
			UDim2.new(0.14,0,0,0),
			12, Enum.TextXAlignment.Center)
	end

	-- ── STAT CARD BUILDER ────────────────────────────────────────
	local CARD_H  = isMobile and 34 or 56
	local ICON_SZ = isMobile and 22 or 36
	local LBL_TS  = isMobile and 8  or 11
	local VAL_TS  = isMobile and 11 or 16
	local LBL_H   = isMobile and 11 or 17
	local VAL_H   = isMobile and 14 or 22

	local function makeStatCard(icon, labelTxt, initVal, accent)
		local card = Instance.new("Frame")
		card.Size             = UDim2.new(1,0,0,CARD_H)
		card.BackgroundColor3 = C.CARD2
		card.BorderSizePixel  = 0
		card.LayoutOrder      = nextOrder()
		card.ZIndex           = 11
		card.Parent           = scr
		corner(card, 10)
		stroke(card, C.BORDER, 1, 0)

		-- left accent stripe
		local bar = Instance.new("Frame")
		bar.Size             = UDim2.new(0, 2, 0.65, 0)
		bar.Position         = UDim2.new(0, 0, 0.5, 0)
		bar.AnchorPoint      = Vector2.new(0, 0.5)
		bar.BackgroundColor3 = accent or C.RED
		bar.BorderSizePixel  = 0
		bar.ZIndex           = 12
		bar.Parent           = card
		corner(bar, 2)

		-- icon container
		local iconBg = Instance.new("Frame")
		iconBg.Size             = UDim2.new(0, ICON_SZ, 0, ICON_SZ)
		iconBg.Position         = UDim2.new(0, 12, 0.5, -(ICON_SZ/2))
		iconBg.BackgroundColor3 = C.CARD
		iconBg.BorderSizePixel  = 0
		iconBg.ZIndex           = 12
		iconBg.Parent           = card
		corner(iconBg, 7)
		stroke(iconBg, C.BORDER, 1, 0.3)

		lbl(iconBg, icon,
			C.WHITE, Enum.Font.GothamBold,
			isMobile and 13 or 16,
			UDim2.new(1,0,1,0),
			UDim2.new(0,0,0,0),
			13, Enum.TextXAlignment.Center)

		-- text layout
		local OX     = 12 + ICON_SZ + 10
		local innerW = -(OX + 10)
		local topY   = math.floor((CARD_H - LBL_H - VAL_H - 2) / 2)

		lbl(card, labelTxt,
			C.MUTED, Enum.Font.GothamMedium, LBL_TS,
			UDim2.new(1,innerW,0,LBL_H),
			UDim2.new(0,OX,0,topY), 12)

		local valLabel = lbl(card, initVal,
			C.WHITE, Enum.Font.GothamBold, VAL_TS,
			UDim2.new(1,innerW,0,VAL_H),
			UDim2.new(0,OX,0,topY+LBL_H+2), 12)
		valLabel.TextColor3 = accent or C.WHITE

		return valLabel
	end

	-- ── SECTIONS & CARDS ────────────────────────────────────────

	makeSection("BASIC INFO")
	local healthLabel   = makeStatCard("❤️",  "Health",   "—", Color3.fromRGB(220,60,60))
	local distanceLabel = makeStatCard("📍",  "Distance", "—", Color3.fromRGB(200,80,80))
	local teamLabel     = makeStatCard("👥",  "Team",     "—", Color3.fromRGB(160,120,120))

	makeSection("BEHAVIOR")
	local deathCountLabel = makeStatCard("💀", "Deaths (Session)",  "—", Color3.fromRGB(220,80,80))
	local jumpCountLabel  = makeStatCard("🦘", "Jump Count",        "—", Color3.fromRGB(200,180,100))
	local jumpSpamLabel   = makeStatCard("⚠️", "Jump Spam",         "—", C.AMBER)

	makeSection("GAME STATS")
	local brawlsLabel     = makeStatCard("👊", "Brawls",     "—", Color3.fromRGB(220,140,80))
	local killsLabel      = makeStatCard("⚔️", "Kills",      "—", Color3.fromRGB(200,60,60))
	local strengthLabel   = makeStatCard("💪", "Strength",   "—", Color3.fromRGB(180,200,150))
	local durabilityLabel = makeStatCard("🛡️", "Durability", "—", Color3.fromRGB(150,180,200))
	local agilityLabel    = makeStatCard("⚡", "Agility",    "—", Color3.fromRGB(220,220,120))
	local rebirthsLabel   = makeStatCard("✨", "Rebirths",   "—", Color3.fromRGB(180,220,220))

	makeSection("RESOURCES")
	local gemsLabel      = makeStatCard("💎", "Gems",       "—", Color3.fromRGB(150,200,220))
	local tokensLabel    = makeStatCard("🎫", "Tokens",     "—", Color3.fromRGB(220,200,100))
	local karmaGoodLabel = makeStatCard("😇", "Good Karma", "—", Color3.fromRGB(150,220,180))
	local karmaEvilLabel = makeStatCard("😈", "Evil Karma", "—", Color3.fromRGB(220,100,100))

	makeSection("GAMEPASSES & BADGES")
	local gamepassLabel        = makeStatCard("🎟️", "Gamepasses",       "—", Color3.fromRGB(220,150,80))
	local badgeCountLabel      = makeStatCard("🏆", "Total Badges",     "—", Color3.fromRGB(220,180,80))
	local importantBadgesLabel = makeStatCard("⭐", "Important Badges", "—", Color3.fromRGB(220,220,120))

	makeSection("CURRENT STATUS")
	local tradingLabel     = makeStatCard("🤝", "Trading",       "—", Color3.fromRGB(180,200,220))
	local machineLabel     = makeStatCard("🏋️", "Using Machine", "—", Color3.fromRGB(200,150,200))
	local autoLiftLabel    = makeStatCard("🤖", "Auto Lift",     "—", Color3.fromRGB(150,220,200))
	local customSpeedLabel = makeStatCard("🏃", "Custom Speed",  "—", Color3.fromRGB(220,200,150))
	local customSizeLabel  = makeStatCard("📏", "Custom Size",   "—", Color3.fromRGB(200,180,200))
	local mapLabel         = makeStatCard("🗺️", "Current Map",   "—", Color3.fromRGB(180,220,180))

	makeSection("EXTRAS")
	local petSlotsLabel    = makeStatCard("🐾", "Pet Slots",      "—", Color3.fromRGB(220,180,200))
	local rebirthMultLabel = makeStatCard("✖️", "Rebirth Multi",  "—", Color3.fromRGB(200,200,220))
	local groupLabel       = makeStatCard("👑", "In Group",       "—", Color3.fromRGB(220,200,150))

	-- ── FOOTER ──────────────────────────────────────────────────
	local footer = Instance.new("Frame")
	footer.Size             = UDim2.new(1,-14,0,FOOTER_H)
	footer.Position         = UDim2.new(0,7,1,-(FOOTER_H+6))
	footer.BackgroundColor3 = C.SURFACE
	footer.BorderSizePixel  = 0
	footer.ZIndex           = 11
	footer.Parent           = win
	corner(footer, 12)
	stroke(footer, C.BORDER_LT, 1, 0)

	-- Divider above footer
	local footDiv = Instance.new("Frame")
	footDiv.Size             = UDim2.new(1,-24,0,1)
	footDiv.Position         = UDim2.new(0,12,0,0)
	footDiv.BackgroundColor3 = C.BORDER
	footDiv.BorderSizePixel  = 0
	footDiv.ZIndex           = 12
	footDiv.Parent           = footer

	local BTN_H = isMobile and 30 or 40
	local BTN_Y = math.floor((FOOTER_H - BTN_H) / 2)

	-- Teleport button
	local tpBtn = Instance.new("TextButton")
	tpBtn.Size             = UDim2.new(0.47, -6, 0, BTN_H)
	tpBtn.Position         = UDim2.new(0, 8, 0, BTN_Y)
	tpBtn.BackgroundColor3 = C.RED_DARK
	tpBtn.Text             = "🚀  Teleport"
	tpBtn.TextColor3       = C.WHITE
	tpBtn.Font             = Enum.Font.GothamBold
	tpBtn.TextSize         = isMobile and 12 or 13
	tpBtn.BorderSizePixel  = 0
	tpBtn.ZIndex           = 12
	tpBtn.Parent           = footer
	corner(tpBtn, 9)
	stroke(tpBtn, C.RED, 1.5, 0.35)

	tpBtn.MouseEnter:Connect(function()
		tween(tpBtn, TweenInfo.new(0.12), {BackgroundColor3=C.RED})
	end)
	tpBtn.MouseLeave:Connect(function()
		tween(tpBtn, TweenInfo.new(0.12), {BackgroundColor3=C.RED_DARK})
	end)
	tpBtn.MouseButton1Click:Connect(function()
		local lp = Players.LocalPlayer
		if lp.Character and target.Character then
			local r1 = lp.Character:FindFirstChild("HumanoidRootPart")
			local r2 = target.Character:FindFirstChild("HumanoidRootPart")
			if r1 and r2 then r1.CFrame = r2.CFrame * CFrame.new(0,0,3) end
		end
	end)

	-- Spectate button
	local specBtn = Instance.new("TextButton")
	specBtn.Size             = UDim2.new(0.47, -6, 0, BTN_H)
	specBtn.Position         = UDim2.new(0.53, -2, 0, BTN_Y)
	specBtn.BackgroundColor3 = C.CARD
	specBtn.Text             = "👁️  Spectate"
	specBtn.TextColor3       = C.MUTED
	specBtn.Font             = Enum.Font.GothamBold
	specBtn.TextSize         = isMobile and 12 or 13
	specBtn.BorderSizePixel  = 0
	specBtn.ZIndex           = 12
	specBtn.Parent           = footer
	corner(specBtn, 9)
	stroke(specBtn, C.BORDER_LT, 1.5, 0.2)

	specBtn.MouseEnter:Connect(function()
		if not isSpectating then
			tween(specBtn, TweenInfo.new(0.12), {BackgroundColor3=C.BORDER_LT, TextColor3=C.WHITE})
		end
	end)
	specBtn.MouseLeave:Connect(function()
		if not isSpectating then
			tween(specBtn, TweenInfo.new(0.12), {BackgroundColor3=C.CARD, TextColor3=C.MUTED})
		end
	end)
	specBtn.MouseButton1Click:Connect(function()
		local lp = Players.LocalPlayer
		local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
		if isSpectating then
			if lp.Character then
				local lh = lp.Character:FindFirstChild("Humanoid")
				if lh then workspace.CurrentCamera.CameraSubject = lh end
			end
			specBtn.Text = "👁️  Spectate"
			tween(specBtn, TweenInfo.new(0.15), {BackgroundColor3=C.CARD, TextColor3=C.MUTED})
			stroke(specBtn, C.BORDER_LT, 1.5, 0.2)
			isSpectating = false

		else
			if target.Character then
				local th = target.Character:FindFirstChild("Humanoid")
				if th then
					workspace.CurrentCamera.CameraSubject = th
					specBtn.Text = "⏹  Stop"
					tween(specBtn, TweenInfo.new(0.15), {BackgroundColor3=C.RED_DIM, TextColor3=C.RED_GLOW})
					stroke(specBtn, C.RED, 1.5, 0.3)
					isSpectating = true

				end
			end
		end
	end)

	-- ── UPDATE LOOPS ─────────────────────────────────────────────

	local lastBehaviorUpdate = 0
	behaviorConnection = RunService.Heartbeat:Connect(function()
		if not stalkLoopActive or not target.Parent then return end
		local now = tick()
		if now - lastBehaviorUpdate < PerformanceManager.behaviorUpdateInterval then return end
		lastBehaviorUpdate = now
		updateBehavior(target)
	end)

	updateConnection = RunService.Heartbeat:Connect(function()
		if not stalkLoopActive or not target.Parent then
			if updateConnection   then updateConnection:Disconnect()   end
			if behaviorConnection then behaviorConnection:Disconnect() end
			return
		end
		local now = tick()
		if now - PerformanceManager.lastUpdate < PerformanceManager.updateInterval then return end
		PerformanceManager.lastUpdate = now

		local tr = behaviorTracker[target.UserId]

		local function getVal(name)
			local ls = target:FindFirstChild("leaderstats")
			local s  = ls and ls:FindFirstChild(name)
			return s and tonumber(s.Value) or 0
		end

		local function getPVal(name)
			local v = target:FindFirstChild(name)
			if not v then return "N/A" end
			if v:IsA("BoolValue") then return v.Value and "Yes" or "No"
			elseif v:IsA("StringValue") then return v.Value ~= "" and v.Value or "None"
			elseif v:IsA("IntValue") or v:IsA("NumberValue") then return formatNumber(v.Value) end
			return "N/A"
		end

		-- Basic Info
		healthLabel.Text   = getHealth(target)
		distanceLabel.Text = getDistance(target)
		teamLabel.Text     = target.Team and target.Team.Name or "None"

		-- Behavior
		if tr then
			deathCountLabel.Text = tostring(tr.deathCount)
			jumpCountLabel.Text  = tostring(tr.jumpCount)

			local sessionTime = now - tr.startTime
			local jpm = sessionTime > 0 and (tr.jumpCount / sessionTime) * 60 or 0
			if jpm > 10 then
				jumpSpamLabel.Text       = "YES — Spam Detected"
				jumpSpamLabel.TextColor3 = Color3.fromRGB(255,55,55)
			else
				jumpSpamLabel.Text       = "Normal"
				jumpSpamLabel.TextColor3 = C.GREEN
			end
		end

		-- Game Stats
		brawlsLabel.Text     = formatNumber(getVal("Brawls"))
		killsLabel.Text      = formatNumber(getVal("Kills"))
		strengthLabel.Text   = formatNumber(getVal("Strength"))
		durabilityLabel.Text = getPVal("Durability")
		agilityLabel.Text    = getPVal("Agility")
		rebirthsLabel.Text   = formatNumber(getVal("Rebirths"))

		-- Resources
		gemsLabel.Text      = getPVal("Gems")
		tokensLabel.Text    = getPVal("Tokens")
		karmaGoodLabel.Text = getPVal("goodKarma")
		karmaEvilLabel.Text = getPVal("evilKarma")

		-- Gamepasses & Badges
		gamepassLabel.Text        = getGamepasses(target)
		badgeCountLabel.Text      = getBadgeCount(target)
		importantBadgesLabel.Text = getImportantBadges(target)

		-- Current Status
		tradingLabel.Text     = getPVal("tradingOn")
		machineLabel.Text     = getPVal("machineInUse")
		autoLiftLabel.Text    = getPVal("autoLiftEnabled")
		customSpeedLabel.Text = getPVal("usingCustomSpeed")
		customSizeLabel.Text  = getPVal("usingCustomSize")
		mapLabel.Text         = getPVal("currentMap")

		-- Extras
		petSlotsLabel.Text    = getPVal("maxPetCapacity")
		rebirthMultLabel.Text = getPVal("rebirthMultiplier")
		groupLabel.Text       = getPVal("playerJoinedGroup")
	end)

	print("✅ Stalker GUI [Premium v4.0] loaded for " .. target.Name)
end

return createStalkerGUI
