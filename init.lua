local things = require("timeflow.things3")

-- Menubar utils --

local indicator_a = {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}
local indicator_b = {"⡀", "⣀", "⣄", "⣤", "⣦", "⣶", "⣷", "⣿"}

local menuApp = hs.menubar.new()
local flashIndicator = true

local function updateMenuTimer(time, task)
    local fullBins = math.floor(time / (60 * 10))
    local lastBinProgress = math.floor((time % (60 * 10)) / (60 * 10) * 8) + 1

    if flashIndicator then
        lastBinProgress = lastBinProgress - 1
        flashIndicator = false
    else
        flashIndicator = true
    end

    local progress = string.rep(indicator_b[8], fullBins) .. indicator_b[lastBinProgress]

    menuApp:setTitle(progress .. "  " .. task)
end

-- Core timer functionality --

local wave = {
    -- configurable variables:
    defaultDuration = 10
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

function wave:start()
    self.task = things.getNextTask()

    local timeChooser =
        hs.chooser.new(
        function(choice)
        end
    )

    local listener
    listener =
        hs.eventtap.new(
        {hs.eventtap.event.types.keyDown},
        function(event)
            if event:getKeyCode() == hs.keycodes.map["return"] then
                self:triggerTimer(tonumber(timeChooser:query()) * 60)
                timeChooser:cancel()
                listener:stop()
                return true
            end
        end
    ):start()

    timeChooser:rows(0)
    timeChooser:show()
end

function wave:triggerTimer(duration)
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
