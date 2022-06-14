local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FFIUtil = require("ffi/util")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local JSON = require("rapidjson")
local LeftContainer = require("ui/widget/container/leftcontainer")
local NetworkMgr = require("ui/network/manager")
local OverlapGroup = require("ui/widget/overlapgroup")
local Size = require("ui/size")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local TitleBar = require("ui/widget/titlebar")
local Trapper = require("ui/trapper")
local UIManager = require("ui/uimanager")
local UnderlineContainer = require("ui/widget/container/underlinecontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Screen = Device.screen
local _ = require("gettext")
local T = FFIUtil.template

local pycommand

local function getSourceDir()
    local callerSource = debug.getinfo(2, "S").source
    if callerSource:find("^@") then
        return callerSource:gsub("^@(.*)/[^/]*", "%1")
    end
end

local ShortcutBox = InputContainer:new{
    filler = false,
    width = nil,
    height = nil,
    border = 0,
    is_offline = false,
    font_face = "xx_smallinfofont",
    font_size = nil,
    sc = nil,
    device = nil,
}

function ShortcutBox:init()
    self.dimen = Geom:new{w = self.width, h = self.height}
    if self.filler then
        return
    end
    if Device:isTouchDevice() then
        self.ges_events.Tap = {
            GestureRange:new{
                ges = "tap",
                range = self.dimen,
            }
        }
        self.ges_events.Hold = {
            GestureRange:new{
                ges = "hold",
                range = self.dimen,
            }
        }
    end

    local inner_w = self.width - 2*self.border
    local inner_h = self.height - 2*self.border

        local bv = TextWidget:new{
            text =  self.sc.bright and tostring(self.sc.bright) .. "%" or "",
            face = Font:getFace(self.font_face, self.font_size),
            fgcolor = self.is_offline and Blitbuffer.COLOR_GRAY or Blitbuffer.COLOR_BLACK,
        }
            local tv = TextWidget:new{
                text = self.sc.temp and tostring(self.sc.temp) .. "K" or "",
                face = Font:getFace(self.font_face, self.font_size),
                fgcolor = self.is_offline and Blitbuffer.COLOR_GRAY or Blitbuffer.COLOR_BLACK,
            }

        local vg = VerticalGroup:new{
            dimen = Geom:new{w = inner_w, h = inner_h},
            bv,
            tv,
        }

    local bright_temp_w = CenterContainer:new{
        dimen = Geom:new{w = inner_w, h = inner_h},
        vg,
    }
    self[1] = FrameContainer:new{
        padding = 0,
        color = self.is_offline and Blitbuffer.COLOR_GRAY or Blitbuffer.COLOR_BLACK,
        bordersize = self.border,
        width = self.width,
        height = self.height,
        bright_temp_w,
    }
end

local function tuyaCommand(args)
    local wait_msg = InfoMessage:new{
        text = _("Executing…"),
    }
    UIManager:show(wait_msg)
    local command =  pycommand .. args .. " 2>&1" -- ensure we get stderr and output something
    local completed, result = Trapper:dismissablePopen(command, wait_msg)
--require("logger").warn("@@@", command, completed, result)
    UIManager:close(wait_msg)
    if completed then
        return result
    end
end

local function updateState(dev, state)
    if type(state) == "table" then
        dev.bright = state.bright
        dev.temp = state.temp
    end
    local text = T("Bright: %1% Temp: %2K", dev.bright or "", dev.temp or "")
    local msg = InfoMessage:new{text = text}
    UIManager:show(msg)
end

function ShortcutBox:onTap()
    Trapper:wrap(function()
        local result= tuyaCommand(self.device.idx .. " " .. self.idx)
        if result then
            local parsed, err = JSON.decode(result)
            updateState(self.device, parsed or err)
        end
    end)
    return true
end

function ShortcutBox:onHold()
    return self:onTap()
end


local TuyaDevice = InputContainer:new{
    device = nil,
    width = nil,
    height = nil,
    sc_width = 0,
    sc_padding = 0,
    sc_border = 0,
    font_size = 0,
    font_face = "xx_smallinfofont",
    state = nil,
    is_offline = false,
}

function TuyaDevice:init()
    self.dimen = Geom:new{w = self.width, h = self.height}
    self.title = VerticalGroup:new{
        width = self.width,
        height = Size.item.height_default,
    }

    self.text_w = UnderlineContainer:new{
        color = Blitbuffer.COLOR_BLACK,
        padding = 0,
        TextWidget:new{
            text = self.device.name,
            max_width = self.width, --status width
            face = Font:getFace(self.font_face, self.font_size),
        },
    }
    table.insert(self.title, CenterContainer:new{
        dimen = { w = self.width },
        self.text_w,
        --self.close_button,
    })

    self.shortcut_container = HorizontalGroup:new{
        dimen = Geom:new{w = self.width, h = self.height - self.title.height}
    }

    --local manual =
    --table.insert(self.shortcut_container, manual)
    --table.insert(self.shortcut_container, HorizontalSpan:new{ width = self.sc_padding, })

    for num, v in ipairs(self.device.shortcuts) do
        local SB = ShortcutBox:new{
            width = self.sc_width,
            height = self.height - self.title.height,
            border = self.sc_border,
            is_offline = self.is_offline,
            font_face = self.fontface,
            font_size = self.fontsize,
            sc = v,
            device = self.device,
            idx = num-1, -- Python indexes from 0
        }
        table.insert(self.shortcut_container, SB)
        if num < #self.device.shortcuts then
            table.insert(self.shortcut_container, HorizontalSpan:new{ width = self.sc_padding, })
        end
    end

    local overlaps = VerticalGroup:new{
        self.title,
        VerticalSpan:new{ width = Size.span.vertical_default },
        self.shortcut_container,
    }

    self[1] = LeftContainer:new{
        dimen = self.dimen:copy(),
        overlaps,
    }
end

function TuyaDevice:update()
end

local TuyaView = InputContainer:new{
    devices = nil,
    nb_book_spans = 3,
    font_face = "xx_smallinfofont",
    title = "",
    width = nil,
    height = nil,
    turn_off_wifi = nil,
    covers_fullscreen = true, -- hint for UIManager:_repaint()
}

function TuyaView:init()
    local wDir = getSourceDir()
    local deviceJson = wDir .. "/tuya_devices.json"
    local parsed, err = JSON.load(deviceJson) -- luacheck: no unused
    if parsed then
        self.devices = parsed
    else
        return self:onClose()
    end
    pycommand = wDir .."/tu.py "

    if not NetworkMgr:isWifiOn() then
        self.turn_off_wifi = true
        NetworkMgr:turnOnWifi()
    end

    self.dimen = Geom:new{
        w = Screen:getWidth(),
        h = Screen:getHeight(),
    }

    if Device:hasKeys() then
        self.key_events = {
            Close = { {"Back"}, doc = "close page" },
        }
    end
    if Device:isTouchDevice() then
        self.ges_events.Swipe = {
            GestureRange:new{
                ges = "swipe",
                range = self.dimen,
            }
        }
    end

    self.outer_padding = Size.padding.large
    self.inner_padding = Size.padding.small

    -- 7 scs in a week
    self.sc_width = math.floor((self.dimen.w - 2*self.outer_padding - 6*self.inner_padding) / 7)
    -- Put back the possible 7px lost in rounding into outer_padding
    self.outer_padding = math.floor((self.dimen.w - 7*self.sc_width - 6*self.inner_padding) / 2)

    self.content_width = self.dimen.w - 2*self.outer_padding

    self.title_bar = TitleBar:new{
        fullscreen = self.covers_fullscreen,
        width = self.dimen.w,
        align = "center",
        title = "Tuya Devices",
        title_h_padding = self.outer_padding, -- have month name aligned with calendar left edge
        close_callback = function() self:onClose() end,
        show_parent = self,
    }

    -- week scs names header
    self.sc_names = HorizontalGroup:new{}

    -- At most 6 devices in a month
    local available_height = self.dimen.h - self.title_bar:getHeight()
                            - self.sc_names:getSize().h
    self.week_height = math.floor((available_height - 7*self.inner_padding) / 6)
    self.sc_border = Size.border.default

    -- sc num + nb_book_span: floor() to get some room for bottom padding
    self.span_height = math.floor((self.week_height - 2*self.sc_border) / (self.nb_book_spans+1))

    -- Limit font size to 1/3 of available height, and so that
    -- the sc number and the +nb-not-shown do not overlap
    local text_height = math.min(self.span_height, self.week_height/3)
    self.span_font_size = TextBoxWidget:getFontSizeToFitHeight(text_height, 1, 0.3)
    local sc_inner_width = self.sc_width - 2*self.sc_border -2*self.inner_padding
    while true do
        local test_w = TextWidget:new{
            text = " 30 + 99 ", -- we want this to be displayed in the available width
            face = Font:getFace(self.font_face, self.span_font_size),
            bold = true,
        }
        if test_w:getWidth() <= sc_inner_width then
            test_w:free()
            break
        end
        self.span_font_size = self.span_font_size - 1
        test_w:free()
    end

    self.main_content = VerticalGroup:new{}
    self:_populateItems()

    local content = OverlapGroup:new{
        dimen = Geom:new{
            w = self.dimen.w,
            h = self.dimen.h,
        },
        allow_mirroring = false,
        VerticalGroup:new{
            self.title_bar,
            self.sc_names,
            HorizontalGroup:new{
                HorizontalSpan:new{ width = self.outer_padding },
                self.main_content,
            },
        },
    }
    -- assemble page
    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        padding = self.outer_padding,
        padding_bottom = 0,
        margin = 0,
        bordersize = 0,
        background = Blitbuffer.COLOR_WHITE,
        content
    }
end

function TuyaView:_populateItems()
    self.main_content:clear()
    for k, v in ipairs(self.devices) do
        -- Python indexes from 0
        v.idx = k-1, -- luacheck: ignore 531
        table.insert(self.main_content, VerticalSpan:new{ width = Size.span.vertical_default })
        local device = TuyaDevice:new{
            device = v,
            height = self.week_height,
            width = self.content_width,
            sc_width = self.sc_width,
            sc_padding = self.inner_padding,
            sc_border = self.sc_border,
            font_face = self.font_face,
            font_size = self.span_font_size,
            show_parent = self,
        }
        table.insert(self.main_content, device)
    end

    UIManager:setDirty(self, function()
        return "ui", self.dimen
    end)
end

function TuyaView:onSwipe(arg, ges_ev)
    local direction = BD.flipDirectionIfMirroredUILayout(ges_ev.direction)
    if direction == "west" or direction == "east" then
        return true
    elseif direction == "south" then
        -- Allow easier closing with swipe down
        self:onClose()
    elseif direction == "north" then
        -- no use for now
        do end -- luacheck: ignore 541
    else -- diagonal swipe
        -- trigger full refresh
        UIManager:setDirty(nil, "full")
        -- a long diagonal swipe may also be used for taking a screenshot,
        -- so let it propagate
        return false
    end
end

function TuyaView:onClose()
    UIManager:close(self)
    if self.turn_off_wifi then
        NetworkMgr:turnOffWifi()
    end
    return true
end

return TuyaView
