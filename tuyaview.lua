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
local NetworkMgr = require("ui/network/manager")
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

local wDir

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
    if self.filler then
        return
    end
    if Device:isTouchDevice() then
        self.ges_events.Tap = {
            GestureRange:new{
                ges = "tap",
                range = function() return self.dimen end,
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

local function tuyaCommand(device, text, args)
    local wait_msg = InfoMessage:new{
        text = text,
    }
    UIManager:show(wait_msg)
    local command_string =  wDir .. "/tu.py " .. args .. " 2>&1" -- ensure we get stderr and output something
    local completed, result = Trapper:dismissablePopen(command_string, wait_msg)
    UIManager:close(wait_msg)
    if completed and result then
        local parsed = JSON.decode(result)
        if type(parsed) == "table" then
            device.state = parsed
        end
        device.title:update()
    end
end

function ShortcutBox:onTap()
    Trapper:wrap(function()
        tuyaCommand(self.parent, _("Executing…"), self.device.idx .. " " .. self.idx)
    end)
    return true
end

local TuyaDeviceTitle = InputContainer:new{
    parent = nil,
}

function TuyaDeviceTitle:init()
    if Device:isTouchDevice() then
        self.ges_events.Tap = {
            GestureRange:new{
                ges = "tap",
                range = function() return self.dimen end,
            }
        }
    end
    self.titleTextW = TextWidget:new{
        text = self.parent.device.name,
        face = Font:getFace(self.parent.font_face, self.parent.font_size),
    }

    self.text_w = UnderlineContainer:new{
        color = Blitbuffer.COLOR_BLACK,
        padding = 0,
        self.titleTextW,
    }
    self[1] = CenterContainer:new{
        dimen = Geom:new{ w = self.parent.width, h = self.parent.title_hight },
        self.text_w,
    }

end

function TuyaDeviceTitle:onTap()
    Trapper:wrap(function()
        tuyaCommand(self.parent, _("Getting status…"), self.parent.device.idx)
    end)
    return true
end

function TuyaDeviceTitle:update()
    local text = self.parent.device.name
    if self.parent.state and next(self.parent.state) ~= nil then
        text = T("%1 (☼%2|💡%3)", text, self.parent.state.bright, self.parent.state.temp)
    end
    self.titleTextW:setText(text)
    UIManager:setDirty(self.show_parent, "ui", self.dimen)
end

local TuyaDevice = InputContainer:new{
    device = nil,
    width = nil,
    height = nil,
    title_hight = Size.item.height_default,
    sc_width = 0,
    sc_padding = 0,
    sc_border = 0,
    font_size = 0,
    font_face = "xx_smallinfofont",
    state = {},
    is_offline = false,
}

function TuyaDevice:init()
    self.title = TuyaDeviceTitle:new{parent=self}

    self.shortcut_container = HorizontalGroup:new{
        dimen = Geom:new{w = self.width, h = self.height - self.title_hight}
    }

    --local manual =
    --table.insert(self.shortcut_container, manual)
    --table.insert(self.shortcut_container, HorizontalSpan:new{ width = self.sc_padding, })

    for num, v in ipairs(self.device.shortcuts) do
        local SB = ShortcutBox:new{
            width = self.sc_width,
            height = self.height - self.title_hight,
            border = self.sc_border,
            is_offline = self.is_offline,
            font_face = self.fontface,
            font_size = self.fontsize,
            sc = v,
            device = self.device,
            idx = num-1, -- Python indexes from 0
            parent = self,
        }
        table.insert(self.shortcut_container, SB)
        table.insert(self.shortcut_container, HorizontalSpan:new{ width = self.sc_padding, })
    end

    local overlaps = VerticalGroup:new{
        self.title,
        VerticalSpan:new{ width = Size.span.vertical_default },
        self.shortcut_container,
    }

    self[1] = overlaps
end

local TuyaView = InputContainer:new{
    devices = nil,
    nb_book_spans = 3,
    font_face = "xx_smallinfofont",
    title = "",
    turn_off_wifi = nil,
    covers_fullscreen = true, -- hint for UIManager:_repaint()
}

function TuyaView:init()
    wDir = getSourceDir()
    local deviceJson = wDir .. "/tuya_devices.json"
    local parsed, err = JSON.load(deviceJson) -- luacheck: no unused
    if parsed then
        self.devices = parsed
    else
        return self:onClose()
    end

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

    self.inner_padding = Size.padding.small

    -- 7 scs in a week
    self.sc_width = math.floor((self.dimen.w - (8*self.inner_padding)) / 7)

    self.content_width = self.dimen.w

    self.title_bar = TitleBar:new{
        fullscreen = self.covers_fullscreen,
        align = "center",
        title = "Tuya Devices",
        close_callback = function() self:onClose() end,
        show_parent = self,
    }

    -- At most 6 devices in a month
    local available_height = self.dimen.h - self.title_bar:getHeight()
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

    local content = VerticalGroup:new{
        self.title_bar,
        self.main_content,
    }

    -- assemble page
    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        padding = 0,
        margin = 0,
        bordersize = 0,
        background = Blitbuffer.COLOR_WHITE,
        content
    }
end

function TuyaView:_populateItems()
    --self.main_content:clear()

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
