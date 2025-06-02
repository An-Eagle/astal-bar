local astal = require("astal")
local Variable = require("astal.variable")
local exec = astal.exec
local Debug = require("lua.lib.debug")
local GLib = astal.require("GLib")

local Theme = {}

function Theme:New()
    local instance = {
        is_dark = Variable.new(false),
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function Theme:update_theme_state()
    local current_theme = self:get_current_theme_mode()
    self.is_dark:set(current_theme == "dark")
end

function Theme:get_current_theme_mode()
    local out, err = exec("dconf read /org/gnome/desktop/interface/color-scheme")
    if err then
        Debug.error("Theme", "Failed to read dconf theme setting: %s", err)
        return "light"
    end
    return out:match("prefer%-dark") and "dark" or "light"
end

function Theme:toggle_theme()
    local current_state = self.is_dark:get()
    local new_state = not current_state

    -- Here, we use systemd-inhibit to toggle idle inhibition instead of switching themes
    local command
    if new_state then
        command = "bash -c 'nohup systemd-inhibit --what=idle --mode=block --who=DisplayControlWindow sleep infinity >/dev/null 2>&1 &'"

    else
        command = "pkill -f 'systemd-inhibit.*DisplayControlWindow'"
    end

    -- Execute the command to toggle idle inhibition
    local _, err = exec(command)
    if err then
        Debug.error("Theme", "Failed to toggle idle inhibition: %s", err)
        return
    end

    -- Update the state variable to reflect the change
    self.is_dark:set(new_state)
end

function Theme:cleanup()
    if self.is_dark then
        self.is_dark:drop()
    end
end

local instance = nil
function Theme.get_default()
    if not instance then
        instance = Theme:New()
    end
    return instance
end

function Theme.cleanup_singleton()
    if instance then
        instance:cleanup()
        instance = nil
    end
end

return Theme

