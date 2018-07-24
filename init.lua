local things = require("timeflow.things3")
local status = require("timeflow.status")

local menuApp = hs.menubar.new()

-- Core timer functionality --

local wave = {
    -- configurable variables:
    defaultDuration = 25 * 60
}

function wave:reset()
    self.isRunning = false
    self.startTime = 0
    self.endTime = 0
    self.duration = 0
    self.notifiedHalf = false
    self.task = nil
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
    menuApp:setTitle("🌊")
end

function wave:start()
    self.task = things.getNextTask()
    status:show(self)
    status:chooseDuration(self)
end

function wave:triggerTimer(duration)
    self.isRunning = true
    self.duration = duration
    self.remaining = duration
    self.endTime = hs.timer.localTime() + duration
    if self.timer then
        self.timer:stop()
    end
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
            self.remaining = self.endTime - hs.timer.localTime()
            wave:notifyProgress()
            wave:updateOnMenu()
        end,
        1
    )
end

function wave:notifyProgress()
    if (self.remaining / self.duration) <= 0.5 and not self.notifiedHalf then
        hs.alert.show("Halfway there 🌊")
        self.notifiedHalf = true
    end
end

function wave:finish()
    hs.alert("Done 🌊")
    hs.task.new(
        "/usr/local/bin/fortune",
        function(exitCode, stdOut, stdErr)
            hs.alert.show(stdOut, 10)
        end
    ):start()
    self:reset()
end

local indicator_a = {"  ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}
local indicator_b = {"⠀", "⡀", "⣀", "⣄", "⣤", "⣦", "⣶", "⣷", "⣿"}
local flashIndicator = true

function wave:getProgressIndicator(shouldFlash)
    local fullBins = math.floor(self.remaining / (60 * 10))
    local lastBinProgress = math.floor((self.remaining % (60 * 10)) / (60 * 10) * 8) + 2

    if shouldFlash then
        if flashIndicator then
            lastBinProgress = lastBinProgress - 1
            flashIndicator = false
        else
            flashIndicator = true
        end
    end

    return string.rep(indicator_b[9], fullBins) .. indicator_b[lastBinProgress]
end

function wave:updateOnMenu()
    local progress = wave:getProgressIndicator(true)
    menuApp:setTitle(progress .. "   " .. self.task)
end

wave:reset()

--- Interaction ---

hs.hotkey.bind(
    {"ctrl"},
    "return",
    function()
        if wave.isRunning then
            status:show(wave)
        end
    end,
    function()
        if wave.isRunning then
            status:hide()
        else
            wave:start(wave.defaultDuration)
        end
    end
)

menuApp:setClickCallback(
    function()
        if wave.isRunning then
            wave:reset()
        else
            wave:start()
        end
    end
)
