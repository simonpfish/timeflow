local things = require("timeflow.things3")

-- Menubar utils --

local indicator_a = {"  ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}
local indicator_b = {"⠀", "⡀", "⣀", "⣄", "⣤", "⣦", "⣶", "⣷", "⣿"}

local menuApp = hs.menubar.new()
local flashIndicator = true

local function getProgressIndicator(time, shouldFlash)
    local fullBins = math.floor(time / (60 * 10))
    local lastBinProgress = math.floor((time % (60 * 10)) / (60 * 10) * 8) + 2

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

local function updateMenuTimer(time, task)
    local progress = getProgressIndicator(time, true)
    menuApp:setTitle(progress .. "   " .. task)
end

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
                local query = timeChooser:query()
                if query == "" then
                    self:triggerTimer(self.defaultDuration)
                else
                    self:triggerTimer(tonumber(timeChooser:query()) * 60)
                end
                timeChooser:cancel()
                listener:stop()
                return true
            elseif event:getKeyCode() == hs.keycodes.map["escape"] then
                listener:stop()
            end
        end
    ):start()

    timeChooser:rows(0)
    timeChooser:show()
    self.isRunning = true
end

function wave:triggerTimer(duration)
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
            updateMenuTimer(self.remaining, self.task)
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

wave:reset()

--- Hotkeys ---

local progressAlert
hs.hotkey.bind(
    {"ctrl"},
    "return",
    function()
        if wave.isRunning and not progressAlert then
            progressAlert = hs.alert.show(getProgressIndicator(wave.remaining) .. "   " .. wave.task, 30)
        end
    end,
    function()
        if progressAlert then
            hs.alert.closeSpecific(progressAlert)
            progressAlert = nil
        else
            wave:start(wave.defaultDuration)
        end
    end
)
