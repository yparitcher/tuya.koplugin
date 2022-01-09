local Dispatcher = require("dispatcher")
local UIManager = require("ui/uimanager")
local Widget = require("ui/widget/widget")
local _ = require("gettext")

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
        sorting_hint = "more_tools",
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
