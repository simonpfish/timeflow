local things = require("timeflow.things3")

-- Menubar utils --

local menuApp = hs.menubar.new()

local function updateMenuTimer(time, task)
    local str = string.format("%02d:%02d", math.floor(time / 60), time % 60)
    if task then
        menuApp:setTitle(task .. " 🌊 " .. str)
    else
        menuApp:setTitle(str)
    end
end

-- Core timer functionality --

local wave = {
    -- configurable variables:
    defaultDuration = 15 * 60
}

function wave:reset()
    self.startTime = 0
    self.endTime = 0
    self.task = nil
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
    menuApp:setTitle("🌊")
end

function wave:start(duration)
    self.task = things.getNextTask()
    self.startTime = hs.timer.localTime()
    self.endTime = self.startTime + duration

    self.timer =
        hs.timer.doUntil(
        function()
            if hs.timer.localTime() >= self.endTime then
                self:finish()
                return true
            else
                return false
            end
        end,
        function()
            local remaining = self.endTime - hs.timer.localTime()
            updateMenuTimer(remaining, self.task)
        end,
        1
    )
end

function wave:finish()
    hs.alert("Done 🌊")
    self:reset()
end

wave:reset()

--- Hotkeys ---

hs.hotkey.bind(
    {"ctrl"},
    "return",
    function()
        wave:start(wave.defaultDuration)
    end
)
