--[[
    CriminalHub v2.2 - Lua UI Library
    Style: WindUI / Rayfield
    Usage:
        local Hub = loadstring(game:HttpGet("..."))()
        local Window = Hub:CreateWindow({ Title = "My Hub", Key = "Insert" })
        local Tab = Window:CreateTab({ Name = "Aimbot", Icon = "🎯" })
        local Section = Tab:CreateSection("Core")
        Section:CreateToggle({ Label = "Aimbot Enabled", Default = true, Callback = function(v) end })
        Section:CreateSlider({ Label = "FOV", Min = 1, Max = 360, Default = 90, Callback = function(v) end })
]]

local CriminalHub = {}
CriminalHub.__index = CriminalHub

-- ─────────────────────────────────────────────
-- Services
-- ─────────────────────────────────────────────
local Players      = game:GetService("Players")
local UserInputSvc = game:GetService("UserInputService")
local TweenSvc     = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")
local RunSvc       = game:GetService("RunService")

local LocalPlayer  = Players.LocalPlayer

-- ─────────────────────────────────────────────
-- Internal utilities
-- ─────────────────────────────────────────────
local function Tween(obj, info, props)
    TweenSvc:Create(obj, info, props):Play()
end

local function NewGui(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        pcall(function() inst[k] = v end)
    end
    return inst
end

local function MakeDraggable(frame, handle)
    local dragging, startPos, startFramePos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startFramePos = frame.Position
        end
    end)
    UserInputSvc.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - startPos
            frame.Position = UDim2.new(
                startFramePos.X.Scale,
                startFramePos.X.Offset + delta.X,
                startFramePos.Y.Scale,
                startFramePos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputSvc.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ─────────────────────────────────────────────
-- Theme (CriminalHub colors) — improved visibility
-- ─────────────────────────────────────────────
local Theme = {
    Background    = Color3.fromRGB(18,  6,  6),   -- slightly lighter for depth
    Surface       = Color3.fromRGB(24,  8,  8),
    Sidebar       = Color3.fromRGB(12,  2,  2),
    Border        = Color3.fromRGB(80, 12, 12),
    Accent        = Color3.fromRGB(200, 30, 30),   -- more vivid red
    AccentDim     = Color3.fromRGB(110, 14, 14),
    TextPrimary   = Color3.fromRGB(225, 225, 225),
    TextSecondary = Color3.fromRGB(145, 145, 145), -- brighter so it's readable
    TextAccent    = Color3.fromRGB(220, 55,  55),
    ToggleOn      = Color3.fromRGB(200, 30,  30),  -- vivid when active
    ToggleOff     = Color3.fromRGB(35,  35,  35),
    SliderFill    = Color3.fromRGB(200, 30,  30),
    InputBg       = Color3.fromRGB(12,  2,  2),
}

-- ─────────────────────────────────────────────
-- CriminalHub:CreateWindow(cfg)
-- cfg = { Title, Subtitle, Key, Size }
-- ─────────────────────────────────────────────
function CriminalHub:CreateWindow(cfg)
    cfg = cfg or {}
    local title     = cfg.Title    or "Criminal Hub"
    local subtitle  = cfg.Subtitle or "v2.2"
    local toggleKey = cfg.Key      or "Insert"
    local winSize   = cfg.Size     or UDim2.new(0, 720, 0, 520)

    -- Root ScreenGui
    local ScreenGui = NewGui("ScreenGui", {
        Name           = "CriminalHub",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Main window frame
    local MainFrame = NewGui("Frame", {
        Name             = "MainFrame",
        Size             = winSize,
        Position         = UDim2.new(0.5,-360,0.5,-260),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel  = 0,
        Parent           = ScreenGui,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,12), Parent = MainFrame })
    NewGui("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = MainFrame })

    -- Subtle vertical gradient on the main frame for depth
    NewGui("UIGradient", {
        Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 8, 8)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 2, 2)),
        },
        Rotation = 90,
        Parent   = MainFrame,
    })

    -- Drop shadow
    NewGui("ImageLabel", {
        Name                   = "Shadow",
        AnchorPoint            = Vector2.new(0.5,0.5),
        Size                   = UDim2.new(1,40,1,40),
        Position               = UDim2.new(0.5,0,0.5,4),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://6014054059",
        ImageColor3            = Color3.fromRGB(120,0,0),
        ImageTransparency      = 0.6,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(49,49,450,450),
        ZIndex                 = -1,
        Parent                 = MainFrame,
    })

    -- ── TITLEBAR ──
    local TitleBar = NewGui("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1,0,0,46),
        BackgroundColor3 = Theme.AccentDim,
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        Parent           = MainFrame,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,12), Parent = TitleBar })
    -- Bottom border line of titlebar
    NewGui("Frame", {
        Size             = UDim2.new(1,0,0,1),
        Position         = UDim2.new(0,0,1,-1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = TitleBar,
    })

    -- Logo badge "C" — slightly larger
    local LogoBadge = NewGui("Frame", {
        Size             = UDim2.new(0,28,0,28),
        Position         = UDim2.new(0,12,0.5,-14),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Parent           = TitleBar,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,7), Parent = LogoBadge })
    NewGui("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 30, 30)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100,  0,  0)),
        },
        Rotation = 135,
        Parent   = LogoBadge,
    })
    NewGui("TextLabel", {
        Size                   = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text                   = "C",
        TextColor3             = Color3.fromRGB(255,255,255),
        TextSize               = 15,
        Font                   = Enum.Font.GothamBold,
        Parent                 = LogoBadge,
    })

    -- Title text
    NewGui("TextLabel", {
        Size                   = UDim2.new(0,200,1,0),
        Position               = UDim2.new(0,50,0,0),
        BackgroundTransparency = 1,
        Text                   = title:upper(),
        TextColor3             = Theme.TextPrimary,
        TextSize               = 13,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = TitleBar,
    })

    -- Version badge — fixed text color so it's actually visible
    local VerBadge = NewGui("TextLabel", {
        Size             = UDim2.new(0,44,0,16),
        Position         = UDim2.new(0,186,0.5,-8),
        BackgroundColor3 = Theme.AccentDim,
        BorderSizePixel  = 0,
        Text             = subtitle,
        TextColor3       = Theme.TextAccent,   -- was AccentDim (invisible), now visible
        TextSize         = 9,
        Font             = Enum.Font.GothamBold,
        Parent           = TitleBar,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,4), Parent = VerBadge })

    -- Window buttons — Close
    local BtnClose = NewGui("TextButton", {
        Size             = UDim2.new(0,22,0,22),
        Position         = UDim2.new(1,-14,0.5,-11),
        AnchorPoint      = Vector2.new(1,0),
        BackgroundColor3 = Color3.fromRGB(90, 10, 10),
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        Text             = "✕",
        TextColor3       = Color3.fromRGB(230, 80, 80),
        TextSize         = 11,
        Font             = Enum.Font.GothamBold,
        Parent           = TitleBar,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,5), Parent = BtnClose })
    NewGui("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = BtnClose })

    -- Window buttons — Minimize
    local BtnMin = NewGui("TextButton", {
        Size             = UDim2.new(0,22,0,22),
        Position         = UDim2.new(1,-40,0.5,-11),
        AnchorPoint      = Vector2.new(1,0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel  = 0,
        Text             = "—",
        TextColor3       = Color3.fromRGB(150, 150, 150),
        TextSize         = 11,
        Font             = Enum.Font.GothamBold,
        Parent           = TitleBar,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,5), Parent = BtnMin })
    NewGui("UIStroke", { Color = Color3.fromRGB(55,55,55), Thickness = 1, Parent = BtnMin })

    -- Hover effects on window buttons
    BtnClose.MouseEnter:Connect(function()
        Tween(BtnClose, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(160,20,20), BackgroundTransparency = 0.2 })
    end)
    BtnClose.MouseLeave:Connect(function()
        Tween(BtnClose, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(90,10,10), BackgroundTransparency = 0.5 })
    end)
    BtnMin.MouseEnter:Connect(function()
        Tween(BtnMin, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(55,55,55) })
    end)
    BtnMin.MouseLeave:Connect(function()
        Tween(BtnMin, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(30,30,30) })
    end)

    -- Body (sidebar + content)
    local Body = NewGui("Frame", {
        Name                   = "Body",
        Size                   = UDim2.new(1,0,1,-46-30),
        Position               = UDim2.new(0,0,0,46),
        BackgroundTransparency = 1,
        Parent                 = MainFrame,
    })

    -- ── SIDEBAR ── (widened to 150px for breathing room)
    local Sidebar = NewGui("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0,150,1,0),
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = 0.3,
        BorderSizePixel  = 0,
        Parent           = Body,
    })
    -- Right border line of sidebar
    NewGui("Frame", {
        Size             = UDim2.new(0,1,1,0),
        Position         = UDim2.new(1,-1,0,0),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.6,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    })

    local SidebarList = NewGui("ScrollingFrame", {
        Size                   = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 0,
        CanvasSize             = UDim2.new(0,0,0,0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        Parent                 = Sidebar,
    })
    NewGui("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0,2),
        Parent    = SidebarList,
    })
    NewGui("UIPadding", {
        PaddingTop    = UDim.new(0,10),
        PaddingBottom = UDim.new(0,10),
        Parent        = SidebarList,
    })

    -- ── CONTENT AREA ──
    local ContentHolder = NewGui("Frame", {
        Name                   = "ContentHolder",
        Size                   = UDim2.new(1,-150,1,0),
        Position               = UDim2.new(0,150,0,0),
        BackgroundTransparency = 1,
        ClipsDescendants       = true,
        Parent                 = Body,
    })

    -- ── FOOTER ──
    local Footer = NewGui("Frame", {
        Name             = "Footer",
        Size             = UDim2.new(1,0,0,30),
        Position         = UDim2.new(0,0,1,-30),
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.65,
        BorderSizePixel  = 0,
        Parent           = MainFrame,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,12), Parent = Footer })
    NewGui("Frame", {   -- top border of footer
        Size             = UDim2.new(1,0,0,1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.8,
        BorderSizePixel  = 0,
        Parent           = Footer,
    })
    NewGui("TextLabel", {
        Size                   = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text                   = "INSERT TO OPEN  •  END TO CLOSE ALL",
        TextColor3             = Color3.fromRGB(55,55,55),
        TextSize               = 9,
        Font                   = Enum.Font.GothamBold,
        Parent                 = Footer,
    })

    -- Make titlebar draggable
    MakeDraggable(MainFrame, TitleBar)

    -- Window state
    local WindowObj = {
        _gui        = ScreenGui,
        _main       = MainFrame,
        _sidebar    = SidebarList,
        _content    = ContentHolder,
        _tabs       = {},
        _activeTab  = nil,
        _minimized  = false,
        _open       = true,
    }

    -- Minimize
    BtnMin.MouseButton1Click:Connect(function()
        WindowObj._minimized = not WindowObj._minimized
        local targetSize = WindowObj._minimized
            and UDim2.new(0,720,0,46)
            or  winSize
        Tween(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = targetSize })
        Body.Visible   = not WindowObj._minimized
        Footer.Visible = not WindowObj._minimized
    end)

    -- Close — smooth fade + shrink
    BtnClose.MouseButton1Click:Connect(function()
        WindowObj._open = false
        Tween(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0,720,0,20),
        })
        task.delay(0.22, function() ScreenGui:Destroy() end)
    end)

    -- Toggle with key
    UserInputSvc.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode.Name:lower() == toggleKey:lower() then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- ─────────────────────────────────────────
    -- Window:CreateTab(cfg)
    -- cfg = { Name, Icon }
    -- ─────────────────────────────────────────
    function WindowObj:CreateTab(cfg)
        cfg = cfg or {}
        local tabName = cfg.Name or "Tab"
        local tabIcon = cfg.Icon or ""

        -- Sidebar button
        local TabBtn = NewGui("TextButton", {
            Size                   = UDim2.new(1,-8,0,34),
            Position               = UDim2.new(0,4,0,0),
            BackgroundColor3       = Theme.ToggleOff,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Text                   = "",
            LayoutOrder            = #self._tabs + 1,
            Parent                 = self._sidebar,
        })
        NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = TabBtn })

        -- Hover effect on inactive tabs
        TabBtn.MouseEnter:Connect(function()
            if self._activeTab and self._activeTab._btn ~= TabBtn then
                Tween(TabBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.88 })
                TabBtn.BackgroundColor3 = Theme.AccentDim
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if self._activeTab and self._activeTab._btn ~= TabBtn then
                Tween(TabBtn, TweenInfo.new(0.1), { BackgroundTransparency = 1 })
            end
        end)

        -- Left active bar indicator
        local ActiveBar = NewGui("Frame", {
            Size             = UDim2.new(0,3,0.65,0),
            Position         = UDim2.new(0,0,0.175,0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
            Visible          = false,
            Parent           = TabBtn,
        })
        NewGui("UICorner", { CornerRadius = UDim.new(0,2), Parent = ActiveBar })

        local TabIcon = NewGui("TextLabel", {
            Size                   = UDim2.new(0,20,1,0),
            Position               = UDim2.new(0,14,0,0),
            BackgroundTransparency = 1,
            Text                   = tabIcon,
            TextSize               = 14,
            Font                   = Enum.Font.Gotham,
            TextColor3             = Theme.TextSecondary,
            Parent                 = TabBtn,
        })
        local TabLabel = NewGui("TextLabel", {
            Size                   = UDim2.new(1,-38,1,0),
            Position               = UDim2.new(0,38,0,0),
            BackgroundTransparency = 1,
            Text                   = tabName,
            TextSize               = 12,
            Font                   = Enum.Font.Gotham,
            TextColor3             = Theme.TextSecondary,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = TabBtn,
        })

        -- Tab content frame
        local TabPage = NewGui("ScrollingFrame", {
            Name                   = tabName,
            Size                   = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = Theme.AccentDim,
            CanvasSize             = UDim2.new(0,0,0,0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            Visible                = false,
            Parent                 = self._content,
        })
        NewGui("UIPadding", {
            PaddingTop    = UDim.new(0,10),
            PaddingLeft   = UDim.new(0,14),
            PaddingRight  = UDim.new(0,14),
            PaddingBottom = UDim.new(0,10),
            Parent        = TabPage,
        })
        NewGui("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0,4),
            Parent    = TabPage,
        })

        -- Tab header inside content
        local TabHeader = NewGui("Frame", {
            Size                   = UDim2.new(1,0,0,32),
            BackgroundTransparency = 1,
            LayoutOrder            = 0,
            Parent                 = TabPage,
        })
        NewGui("Frame", {   -- divider line
            Size             = UDim2.new(1,0,0,1),
            Position         = UDim2.new(0,0,1,-1),
            BackgroundColor3 = Theme.Border,
            BackgroundTransparency = 0.7,
            BorderSizePixel  = 0,
            Parent           = TabHeader,
        })
        NewGui("TextLabel", {
            Size                   = UDim2.new(1,0,1,-4),
            BackgroundTransparency = 1,
            Text                   = tabIcon .. "  " .. tabName:upper(),
            TextColor3             = Theme.TextAccent,
            TextSize               = 14,
            Font                   = Enum.Font.GothamBold,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = TabHeader,
        })

        local TabObj = {
            _btn    = TabBtn,
            _bar    = ActiveBar,
            _label  = TabLabel,
            _icon   = TabIcon,
            _page   = TabPage,
            _window = self,
            _order  = 0,
        }

        -- Activate tab
        local function ActivateTab()
            -- Deactivate all
            for _, t in pairs(self._tabs) do
                t._page.Visible = false
                t._bar.Visible  = false
                Tween(t._btn,   TweenInfo.new(0.14), { BackgroundTransparency = 1 })
                Tween(t._label, TweenInfo.new(0.14), { TextColor3 = Theme.TextSecondary })
                Tween(t._icon,  TweenInfo.new(0.14), { TextColor3 = Theme.TextSecondary })
            end
            -- Activate this one
            TabPage.Visible    = true
            ActiveBar.Visible  = true
            TabBtn.BackgroundColor3 = Theme.ToggleOn
            Tween(TabBtn,   TweenInfo.new(0.14), { BackgroundTransparency = 0.72 })
            Tween(TabLabel, TweenInfo.new(0.14), { TextColor3 = Color3.fromRGB(255, 90, 90) })
            Tween(TabIcon,  TweenInfo.new(0.14), { TextColor3 = Color3.fromRGB(255, 90, 90) })
            self._activeTab = TabObj
        end

        TabBtn.MouseButton1Click:Connect(ActivateTab)
        table.insert(self._tabs, TabObj)

        -- First tab activates automatically
        if #self._tabs == 1 then
            ActivateTab()
        end

        -- ─────────────────────────────────────
        -- Tab:CreateSection(name)
        -- ─────────────────────────────────────
        function TabObj:CreateSection(name)
            local SectionFrame = NewGui("Frame", {
                Size                   = UDim2.new(1,0,0,0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder            = self._order,
                Parent                 = self._page,
            })
            self._order = self._order + 1

            NewGui("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0,4),
                Parent    = SectionFrame,
            })

            -- Section header
            local SecHeader = NewGui("Frame", {
                Size                   = UDim2.new(1,0,0,24),
                BackgroundTransparency = 1,
                LayoutOrder            = 0,
                Parent                 = SectionFrame,
            })
            NewGui("Frame", {
                Size             = UDim2.new(1,0,0,1),
                Position         = UDim2.new(0,0,1,-1),
                BackgroundColor3 = Theme.AccentDim,
                BackgroundTransparency = 0.7,
                BorderSizePixel  = 0,
                Parent           = SecHeader,
            })
            NewGui("TextLabel", {
                Size                   = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text                   = name:upper(),
                TextColor3             = Theme.TextAccent,  -- was AccentDim, now readable
                TextSize               = 10,
                Font                   = Enum.Font.GothamBold,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = SecHeader,
            })

            local SectionObj = {
                _frame = SectionFrame,
                _order = 1,
                _tab   = self,
            }

            local function NextOrder()
                SectionObj._order = SectionObj._order + 1
                return SectionObj._order
            end

            -- Hover helper
            local function HoverEffect(btn, baseColor, hoverColor)
                btn.MouseEnter:Connect(function()
                    Tween(btn, TweenInfo.new(0.1), { BackgroundColor3 = hoverColor })
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, TweenInfo.new(0.1), { BackgroundColor3 = baseColor })
                end)
            end

            -- ─────────────────────────────
            -- Section:CreateToggle(cfg)
            -- cfg = { Label, Default, Callback }
            -- ─────────────────────────────
            function SectionObj:CreateToggle(cfg)
                cfg = cfg or {}
                local label    = cfg.Label    or "Toggle"
                local default  = cfg.Default ~= nil and cfg.Default or false
                local callback = cfg.Callback or function() end

                local on = default

                local Row = NewGui("TextButton", {
                    Size                   = UDim2.new(1,0,0,36),
                    BackgroundColor3       = on and Theme.ToggleOn or Color3.fromRGB(22,22,22),
                    BackgroundTransparency = on and 0.82 or 0.85,  -- more presence
                    BorderSizePixel        = 0,
                    Text                   = "",
                    LayoutOrder            = NextOrder(),
                    Parent                 = self._frame,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = Row })
                local RowStroke = NewGui("UIStroke", {
                    Color        = on and Theme.Border or Color3.fromRGB(60,60,60),
                    Transparency = on and 0.5 or 0.8,
                    Thickness    = 1,
                    Parent       = Row,
                })

                local LblText = NewGui("TextLabel", {
                    Size                   = UDim2.new(1,-52,1,0),
                    Position               = UDim2.new(0,10,0,0),
                    BackgroundTransparency = 1,
                    Text                   = label,
                    TextColor3             = on and Theme.TextPrimary or Theme.TextSecondary,
                    TextSize               = 12,
                    Font                   = Enum.Font.Gotham,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = Row,
                })

                -- Toggle track
                local Track = NewGui("Frame", {
                    Size             = UDim2.new(0,34,0,18),
                    Position         = UDim2.new(1,-44,0.5,-9),
                    BackgroundColor3 = on and Theme.ToggleOn or Theme.ToggleOff,
                    BorderSizePixel  = 0,
                    Parent           = Row,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,9), Parent = Track })
                local TrackStroke = NewGui("UIStroke", {
                    Color     = on and Theme.Accent or Color3.fromRGB(50,50,50),
                    Thickness = 1,
                    Parent    = Track,
                })

                -- Knob — bigger (12px) and easier to read
                local Knob = NewGui("Frame", {
                    Size             = UDim2.new(0,12,0,12),
                    Position         = UDim2.new(0, on and 17 or 2, 0.5,-6),
                    BackgroundColor3 = on and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(80,80,80),
                    BorderSizePixel  = 0,
                    Parent           = Track,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = Knob })
                -- Glow stroke on knob when active
                local KnobStroke = NewGui("UIStroke", {
                    Color        = on and Color3.fromRGB(255,80,80) or Color3.fromRGB(50,50,50),
                    Transparency = on and 0.4 or 1,
                    Thickness    = 2,
                    Parent       = Knob,
                })

                local function SetToggle(state)
                    on = state
                    Tween(Row, TweenInfo.new(0.15), {
                        BackgroundColor3       = on and Theme.ToggleOn or Color3.fromRGB(22,22,22),
                        BackgroundTransparency = on and 0.82 or 0.85,
                    })
                    Tween(RowStroke, TweenInfo.new(0.15), {
                        Color        = on and Theme.Border or Color3.fromRGB(60,60,60),
                        Transparency = on and 0.5 or 0.8,
                    })
                    Tween(LblText, TweenInfo.new(0.15), {
                        TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary,
                    })
                    Tween(Track, TweenInfo.new(0.15), {
                        BackgroundColor3 = on and Theme.ToggleOn or Theme.ToggleOff,
                    })
                    Tween(TrackStroke, TweenInfo.new(0.15), {
                        Color = on and Theme.Accent or Color3.fromRGB(50,50,50),
                    })
                    Tween(Knob, TweenInfo.new(0.15), {
                        Position         = UDim2.new(0, on and 17 or 2, 0.5,-6),
                        BackgroundColor3 = on and Color3.fromRGB(255,100,100) or Color3.fromRGB(80,80,80),
                    })
                    Tween(KnobStroke, TweenInfo.new(0.15), {
                        Color        = on and Color3.fromRGB(255,80,80) or Color3.fromRGB(50,50,50),
                        Transparency = on and 0.4 or 1,
                    })
                    pcall(callback, on)
                end

                Row.MouseButton1Click:Connect(function()
                    SetToggle(not on)
                end)

                return { Set = SetToggle, Get = function() return on end }
            end

            -- ─────────────────────────────
            -- Section:CreateSlider(cfg)
            -- cfg = { Label, Min, Max, Default, Callback }
            -- ─────────────────────────────
            function SectionObj:CreateSlider(cfg)
                cfg = cfg or {}
                local label    = cfg.Label    or "Slider"
                local min      = cfg.Min      or 0
                local max      = cfg.Max      or 100
                local default  = cfg.Default  or min
                local callback = cfg.Callback or function() end

                local val = math.clamp(default, min, max)

                local Wrap = NewGui("Frame", {
                    Size                   = UDim2.new(1,0,0,52),
                    BackgroundColor3       = Color3.fromRGB(22,22,22),
                    BackgroundTransparency = 0.85,   -- more visible
                    BorderSizePixel        = 0,
                    LayoutOrder            = NextOrder(),
                    Parent                 = self._frame,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = Wrap })
                NewGui("UIStroke", { Color = Color3.fromRGB(60,60,60), Transparency = 0.7, Thickness = 1, Parent = Wrap })
                NewGui("UIPadding", {
                    PaddingLeft   = UDim.new(0,10),
                    PaddingRight  = UDim.new(0,10),
                    PaddingTop    = UDim.new(0,8),
                    PaddingBottom = UDim.new(0,8),
                    Parent        = Wrap,
                })

                local TopRow = NewGui("Frame", {
                    Size                   = UDim2.new(1,0,0,14),
                    BackgroundTransparency = 1,
                    Parent                 = Wrap,
                })
                NewGui("TextLabel", {
                    Size                   = UDim2.new(0.7,0,1,0),
                    BackgroundTransparency = 1,
                    Text                   = label,
                    TextColor3             = Theme.TextSecondary,
                    TextSize               = 11,
                    Font                   = Enum.Font.Gotham,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = TopRow,
                })
                local ValLabel = NewGui("TextLabel", {
                    Size                   = UDim2.new(0.3,0,1,0),
                    Position               = UDim2.new(0.7,0,0,0),
                    BackgroundTransparency = 1,
                    Text                   = tostring(val),
                    TextColor3             = Theme.TextAccent,
                    TextSize               = 11,
                    Font                   = Enum.Font.GothamBold,
                    TextXAlignment         = Enum.TextXAlignment.Right,
                    Parent                 = TopRow,
                })

                -- Track — taller (6px) and easier to click
                local TrackBg = NewGui("Frame", {
                    Size             = UDim2.new(1,0,0,6),
                    Position         = UDim2.new(0,0,0,30),
                    BackgroundColor3 = Color3.fromRGB(38,38,38),
                    BorderSizePixel  = 0,
                    Parent           = Wrap,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,3), Parent = TrackBg })

                local pct = (val - min) / (max - min)
                local Fill = NewGui("Frame", {
                    Size             = UDim2.new(pct,0,1,0),
                    BackgroundColor3 = Theme.SliderFill,
                    BorderSizePixel  = 0,
                    Parent           = TrackBg,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,3), Parent = Fill })
                -- Fill gradient
                NewGui("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(220,50,50)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(150,10,10)),
                    },
                    Parent = Fill,
                })

                -- Knob — bigger (12px) for easier grabbing
                local SliderKnob = NewGui("Frame", {
                    Size             = UDim2.new(0,12,0,12),
                    Position         = UDim2.new(pct,-6,0.5,-6),
                    BackgroundColor3 = Color3.fromRGB(240,240,240),
                    BorderSizePixel  = 0,
                    Parent           = TrackBg,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = SliderKnob })
                NewGui("UIStroke", { Color = Theme.Accent, Thickness = 2, Parent = SliderKnob })

                local dragging = false
                TrackBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or
                       input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                    end
                end)
                UserInputSvc.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or
                       input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                UserInputSvc.InputChanged:Connect(function(input)
                    if dragging and (
                        input.UserInputType == Enum.UserInputType.MouseMovement or
                        input.UserInputType == Enum.UserInputType.Touch
                    ) then
                        local absPos  = TrackBg.AbsolutePosition.X
                        local absSize = TrackBg.AbsoluteSize.X
                        local mouseX  = input.Position.X
                        local newPct  = math.clamp((mouseX - absPos) / absSize, 0, 1)
                        local newVal  = math.floor(min + newPct * (max - min) + 0.5)
                        val = newVal
                        ValLabel.Text       = tostring(val)
                        Fill.Size           = UDim2.new(newPct, 0, 1, 0)
                        SliderKnob.Position = UDim2.new(newPct,-6,0.5,-6)
                        pcall(callback, val)
                    end
                end)

                local SliderObj = {
                    Set = function(_, v)
                        val = math.clamp(v, min, max)
                        local p = (val - min) / (max - min)
                        ValLabel.Text       = tostring(val)
                        Fill.Size           = UDim2.new(p,0,1,0)
                        SliderKnob.Position = UDim2.new(p,-6,0.5,-6)
                        pcall(callback, val)
                    end,
                    Get = function() return val end,
                }
                return SliderObj
            end

            -- ─────────────────────────────
            -- Section:CreateDropdown(cfg)
            -- cfg = { Label, Options, Default, Callback }
            -- ─────────────────────────────
            function SectionObj:CreateDropdown(cfg)
                cfg = cfg or {}
                local label    = cfg.Label    or "Dropdown"
                local options  = cfg.Options  or {}
                local default  = cfg.Default  or (options[1] or "")
                local callback = cfg.Callback or function() end

                local selected = default
                local open     = false

                local Wrap = NewGui("Frame", {
                    Size                   = UDim2.new(1,0,0,36),
                    BackgroundTransparency = 1,
                    LayoutOrder            = NextOrder(),
                    Parent                 = self._frame,
                })
                NewGui("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Wrap })

                local Header = NewGui("TextButton", {
                    Size                   = UDim2.new(1,0,0,36),
                    BackgroundColor3       = Color3.fromRGB(22,22,22),
                    BackgroundTransparency = 0.85,
                    BorderSizePixel        = 0,
                    Text                   = "",
                    LayoutOrder            = 0,
                    Parent                 = Wrap,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = Header })
                NewGui("UIStroke", { Color = Color3.fromRGB(60,60,60), Transparency = 0.7, Thickness = 1, Parent = Header })
                NewGui("TextLabel", {
                    Size                   = UDim2.new(0.5,0,1,0),
                    Position               = UDim2.new(0,10,0,0),
                    BackgroundTransparency = 1,
                    Text                   = label,
                    TextColor3             = Theme.TextSecondary,
                    TextSize               = 12,
                    Font                   = Enum.Font.Gotham,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = Header,
                })
                local SelLabel = NewGui("TextLabel", {
                    Size                   = UDim2.new(0.5,-20,1,0),
                    Position               = UDim2.new(0.5,0,0,0),
                    BackgroundTransparency = 1,
                    Text                   = selected,
                    TextColor3             = Theme.TextAccent,
                    TextSize               = 11,
                    Font                   = Enum.Font.GothamBold,
                    TextXAlignment         = Enum.TextXAlignment.Right,
                    Parent                 = Header,
                })
                NewGui("TextLabel", {   -- arrow
                    Size                   = UDim2.new(0,16,1,0),
                    Position               = UDim2.new(1,-18,0,0),
                    BackgroundTransparency = 1,
                    Text                   = "▾",
                    TextColor3             = Theme.TextSecondary,
                    TextSize               = 11,
                    Font                   = Enum.Font.GothamBold,
                    Parent                 = Header,
                })

                -- Options list
                local DropList = NewGui("Frame", {
                    Size                   = UDim2.new(1,0,0,0),
                    BackgroundColor3       = Color3.fromRGB(14,3,3),
                    BackgroundTransparency = 0.1,
                    BorderSizePixel        = 0,
                    ClipsDescendants       = true,
                    LayoutOrder            = 1,
                    Visible                = false,
                    Parent                 = Wrap,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = DropList })
                NewGui("UIStroke", { Color = Theme.Border, Transparency = 0.6, Thickness = 1, Parent = DropList })

                local OptionList = NewGui("Frame", {
                    Size                   = UDim2.new(1,0,0,0),
                    AutomaticSize          = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Parent                 = DropList,
                })
                NewGui("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,1), Parent = OptionList })
                NewGui("UIPadding", {
                    PaddingTop    = UDim.new(0,4),
                    PaddingBottom = UDim.new(0,4),
                    PaddingLeft   = UDim.new(0,4),
                    PaddingRight  = UDim.new(0,4),
                    Parent        = OptionList,
                })

                for _, opt in ipairs(options) do
                    local OptBtn = NewGui("TextButton", {
                        Size                   = UDim2.new(1,0,0,28),
                        BackgroundColor3       = Theme.Background,
                        BackgroundTransparency = 0.4,
                        BorderSizePixel        = 0,
                        Text                   = opt,
                        TextColor3             = Theme.TextSecondary,
                        TextSize               = 11,
                        Font                   = Enum.Font.Gotham,
                        Parent                 = OptionList,
                    })
                    NewGui("UICorner", { CornerRadius = UDim.new(0,4), Parent = OptBtn })
                    HoverEffect(OptBtn, Theme.Background, Theme.AccentDim)

                    OptBtn.MouseButton1Click:Connect(function()
                        selected      = opt
                        SelLabel.Text = opt
                        open = false
                        Tween(DropList, TweenInfo.new(0.15), { Size = UDim2.new(1,0,0,0) })
                        task.delay(0.15, function() DropList.Visible = false end)
                        Wrap.Size = UDim2.new(1,0,0,36)
                        pcall(callback, opt)
                    end)
                end

                Header.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        DropList.Visible = true
                        local h = #options * 29 + 8
                        Tween(DropList, TweenInfo.new(0.15), { Size = UDim2.new(1,0,0,h) })
                        Wrap.Size = UDim2.new(1,0,0,36 + h + 2)
                    else
                        Tween(DropList, TweenInfo.new(0.15), { Size = UDim2.new(1,0,0,0) })
                        task.delay(0.15, function() DropList.Visible = false end)
                        Wrap.Size = UDim2.new(1,0,0,36)
                    end
                end)

                return {
                    Set = function(_, v)
                        if table.find(options, v) then
                            selected      = v
                            SelLabel.Text = v
                            pcall(callback, v)
                        end
                    end,
                    Get = function() return selected end,
                }
            end

            -- ─────────────────────────────
            -- Section:CreateInput(cfg)
            -- cfg = { Label, Placeholder, Callback }
            -- ─────────────────────────────
            function SectionObj:CreateInput(cfg)
                cfg = cfg or {}
                local label       = cfg.Label       or "Input"
                local placeholder = cfg.Placeholder or ""
                local callback    = cfg.Callback    or function() end

                local Wrap = NewGui("Frame", {
                    Size                   = UDim2.new(1,0,0,52),
                    BackgroundTransparency = 1,
                    LayoutOrder            = NextOrder(),
                    Parent                 = self._frame,
                })
                NewGui("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,3), Parent = Wrap })
                NewGui("TextLabel", {
                    Size                   = UDim2.new(1,0,0,14),
                    BackgroundTransparency = 1,
                    Text                   = label:upper(),
                    TextColor3             = Theme.TextSecondary,
                    TextSize               = 9,
                    Font                   = Enum.Font.GothamBold,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = Wrap,
                })

                local Box = NewGui("TextBox", {
                    Size              = UDim2.new(1,0,0,32),
                    BackgroundColor3  = Theme.InputBg,
                    BorderSizePixel   = 0,
                    PlaceholderText   = placeholder,
                    PlaceholderColor3 = Color3.fromRGB(70,35,35),
                    Text              = "",
                    TextColor3        = Theme.TextPrimary,
                    TextSize          = 12,
                    Font              = Enum.Font.Gotham,
                    ClearTextOnFocus  = false,
                    Parent            = Wrap,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = Box })
                local Stroke = NewGui("UIStroke", {
                    Color     = Color3.fromRGB(50,12,12),
                    Thickness = 1,
                    Parent    = Box,
                })
                NewGui("UIPadding", {
                    PaddingLeft  = UDim.new(0,10),
                    PaddingRight = UDim.new(0,10),
                    Parent       = Box,
                })

                Box.Focused:Connect(function()
                    Tween(Stroke, TweenInfo.new(0.1), { Color = Theme.Accent })
                end)
                Box.FocusLost:Connect(function(enter)
                    Tween(Stroke, TweenInfo.new(0.1), { Color = Color3.fromRGB(50,12,12) })
                    if enter then pcall(callback, Box.Text) end
                end)

                return {
                    Set = function(_, v) Box.Text = tostring(v) end,
                    Get = function() return Box.Text end,
                }
            end

            -- ─────────────────────────────
            -- Section:CreateButton(cfg)
            -- cfg = { Label, Callback }
            -- ─────────────────────────────
            function SectionObj:CreateButton(cfg)
                cfg = cfg or {}
                local label    = cfg.Label    or "Button"
                local callback = cfg.Callback or function() end

                local Btn = NewGui("TextButton", {
                    Size                   = UDim2.new(1,0,0,34),
                    BackgroundColor3       = Theme.AccentDim,
                    BackgroundTransparency = 0.72,
                    BorderSizePixel        = 0,
                    Text                   = label,
                    TextColor3             = Color3.fromRGB(255, 95, 95),
                    TextSize               = 12,
                    Font                   = Enum.Font.GothamBold,
                    LayoutOrder            = NextOrder(),
                    Parent                 = self._frame,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = Btn })
                NewGui("UIStroke", { Color = Theme.Border, Transparency = 0.5, Thickness = 1, Parent = Btn })

                -- Hover effect
                Btn.MouseEnter:Connect(function()
                    Tween(Btn, TweenInfo.new(0.1), { BackgroundTransparency = 0.55, BackgroundColor3 = Theme.Accent })
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, TweenInfo.new(0.1), { BackgroundTransparency = 0.72, BackgroundColor3 = Theme.AccentDim })
                end)

                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn, TweenInfo.new(0.08), { BackgroundTransparency = 0.3 })
                    task.delay(0.1, function()
                        Tween(Btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.72 })
                    end)
                    pcall(callback)
                end)

                return Btn
            end

            -- ─────────────────────────────
            -- Section:CreateLabel(text)
            -- ─────────────────────────────
            function SectionObj:CreateLabel(text)
                local Lbl = NewGui("TextLabel", {
                    Size                   = UDim2.new(1,0,0,20),
                    BackgroundTransparency = 1,
                    Text                   = text or "",
                    TextColor3             = Theme.TextSecondary,
                    TextSize               = 11,
                    Font                   = Enum.Font.Gotham,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    TextWrapped            = true,
                    LayoutOrder            = NextOrder(),
                    Parent                 = self._frame,
                })
                return {
                    Set = function(_, v) Lbl.Text = tostring(v) end,
                    Get = function() return Lbl.Text end,
                }
            end

            -- ─────────────────────────────
            -- Section:CreateKeybind(cfg)
            -- cfg = { Label, Default, Callback }
            -- ─────────────────────────────
            function SectionObj:CreateKeybind(cfg)
                cfg = cfg or {}
                local label    = cfg.Label    or "Keybind"
                local default  = cfg.Default  or "None"
                local callback = cfg.Callback or function() end

                local binding   = default
                local listening = false

                local Row = NewGui("Frame", {
                    Size                   = UDim2.new(1,0,0,36),
                    BackgroundColor3       = Color3.fromRGB(22,22,22),
                    BackgroundTransparency = 0.85,
                    BorderSizePixel        = 0,
                    LayoutOrder            = NextOrder(),
                    Parent                 = self._frame,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,6), Parent = Row })
                NewGui("UIStroke", { Color = Color3.fromRGB(60,60,60), Transparency = 0.7, Thickness = 1, Parent = Row })
                NewGui("TextLabel", {
                    Size                   = UDim2.new(0.6,0,1,0),
                    Position               = UDim2.new(0,10,0,0),
                    BackgroundTransparency = 1,
                    Text                   = label,
                    TextColor3             = Theme.TextSecondary,
                    TextSize               = 12,
                    Font                   = Enum.Font.Gotham,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = Row,
                })

                local KeyBtn = NewGui("TextButton", {
                    Size                   = UDim2.new(0,72,0,22),
                    Position               = UDim2.new(1,-80,0.5,-11),
                    BackgroundColor3       = Theme.AccentDim,
                    BackgroundTransparency = 0.55,
                    BorderSizePixel        = 0,
                    Text                   = binding,
                    TextColor3             = Theme.TextAccent,
                    TextSize               = 10,
                    Font                   = Enum.Font.GothamBold,
                    Parent                 = Row,
                })
                NewGui("UICorner", { CornerRadius = UDim.new(0,5), Parent = KeyBtn })
                NewGui("UIStroke", { Color = Theme.Border, Transparency = 0.6, Thickness = 1, Parent = KeyBtn })

                KeyBtn.MouseButton1Click:Connect(function()
                    listening         = true
                    KeyBtn.Text       = "..."
                    KeyBtn.TextColor3 = Color3.fromRGB(255,200,50)
                end)
                UserInputSvc.InputBegan:Connect(function(input, gpe)
                    if listening then
                        listening         = false
                        local key         = input.KeyCode.Name
                        binding           = key
                        KeyBtn.Text       = key
                        KeyBtn.TextColor3 = Theme.TextAccent
                        pcall(callback, key)
                    end
                end)

                return { Get = function() return binding end }
            end

            return SectionObj
        end -- CreateSection

        return TabObj
    end -- CreateTab

    return WindowObj
end -- CreateWindow

-- ─────────────────────────────────────────────
-- Floating notification
-- CriminalHub:Notify(cfg)
-- cfg = { Title, Message, Duration }
-- ─────────────────────────────────────────────
function CriminalHub:Notify(cfg)
    cfg = cfg or {}
    local title    = cfg.Title   or "Criminal Hub"
    local message  = cfg.Message or ""
    local duration = cfg.Duration or 4

    -- Reuse existing ScreenGui or create a new one
    local gui = CoreGui:FindFirstChild("CriminalHub_Notify")
    if not gui then
        gui = NewGui("ScreenGui", {
            Name           = "CriminalHub_Notify",
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent         = CoreGui,
        })
    end

    local Notif = NewGui("Frame", {
        Size             = UDim2.new(0,270,0,65),
        Position         = UDim2.new(1,10,1,-90),
        AnchorPoint      = Vector2.new(1,1),
        BackgroundColor3 = Color3.fromRGB(18,5,5),
        BorderSizePixel  = 0,
        Parent           = gui,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,8), Parent = Notif })
    NewGui("UIStroke", { Color = Theme.Border, Transparency = 0.4, Thickness = 1, Parent = Notif })

    -- Left accent bar
    local AccentBar = NewGui("Frame", {
        Size             = UDim2.new(0,3,1,0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Parent           = Notif,
    })
    NewGui("UICorner", { CornerRadius = UDim.new(0,3), Parent = AccentBar })
    NewGui("UIGradient", {
        Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(220,40,40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(120,5,5)),
        },
        Rotation = 90,
        Parent   = AccentBar,
    })

    NewGui("TextLabel", {
        Size                   = UDim2.new(1,-18,0,18),
        Position               = UDim2.new(0,14,0,10),
        BackgroundTransparency = 1,
        Text                   = title,
        TextColor3             = Theme.TextPrimary,
        TextSize               = 12,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = Notif,
    })
    NewGui("TextLabel", {
        Size                   = UDim2.new(1,-18,0,26),
        Position               = UDim2.new(0,14,0,30),
        BackgroundTransparency = 1,
        Text                   = message,
        TextColor3             = Theme.TextSecondary,
        TextSize               = 10,
        Font                   = Enum.Font.Gotham,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        Parent                 = Notif,
    })

    -- Slide in
    Notif.Position = UDim2.new(1,10,1,-90)
    Tween(Notif, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1,-16,1,-90),
    })

    task.delay(duration, function()
        Tween(Notif, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
            Position               = UDim2.new(1,10,1,-90),
            BackgroundTransparency = 1,
        })
        task.delay(0.25, function() Notif:Destroy() end)
    end)
end

return CriminalHub
