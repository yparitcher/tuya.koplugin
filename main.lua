local BD = require("ui/bidi")
local BookStatusWidget = require("ui/widget/bookstatuswidget")
local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local Device = require("device")
local Dispatcher = require("dispatcher")
local DocSettings = require("docsettings")
local FFIUtil = require("ffi/util")
local InfoMessage = require("ui/widget/infomessage")
local KeyValuePage = require("ui/widget/keyvaluepage")
local Math = require("optmath")
local ReaderFooter = require("apps/reader/modules/readerfooter")
local ReaderProgress = require("readerprogress")
local ReadHistory = require("readhistory")
local Screensaver = require("ui/screensaver")
local SQ3 = require("lua-ljsqlite3/init")
local UIManager = require("ui/uimanager")
local Widget = require("ui/widget/widget")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local util = require("util")
local _ = require("gettext")
local N_ = _.ngettext
local T = FFIUtil.template

local Tuya = Widget:extend{
    name = "tuya",
}

function Tuya:onDispatcherRegisterActions()
    Dispatcher:registerAction("tuya", {category="none", event="ShowTuyaView", title=_("Tuya Devices"), general=true, separator=true})
end

function Tuya:init()
    self.ui.menu:registerToMainMenu(self)
    self:onDispatcherRegisterActions()
end

function Tuya:addToMainMenu(menu_items)
    menu_items.tuya = {
        text = _("Tuya"),
        callback = function() UIManager:show(self:getTuyaView()) end,
    }
end

-- in case when screensaver starts
function Tuya:onSuspend()
end

-- screensaver off
function Tuya:onResume()
end

function Tuya:getTuyaView()
    local TuyaView = require("tuyaview")
    return TuyaView:new{}
end

function Tuya:onShowTuyaView()
     UIManager:show(self:getTuyaView())
end

return Tuya
