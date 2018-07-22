-- Menubar utils --

local menuApp = hs.menubar.new()

local function updateMenuTimer(time)
    local str = string.format("%02d:%02d", math.floor(time / 60), time % 60)
    menuApp:setTitle(str)
end

-- Core timer functionality --

local wave = {
    reset = function(self)
        self.startTime = 0
        self.endTime = 0
        if self.timer then
            self.timer:stop()
        end
        menuApp:setTitle("🌊")
    end,
    start = function(self, duration)
        self.startTime = hs.timer.localTime()
        self.endTime = self.startTime + duration * 60

        self.timer =
            hs.timer.doUntil(
            function()
                if hs.timer.localTime() >= self.endTime then
                    self.reset()
                    return true
                else
                    return false
                end
            end,
            function()
                local remaining = self.endTime - hs.timer.localTime()
                updateMenuTimer(remaining)
            end,
            1
        )
    end
}

wave:reset()

--- Hotkeys ---

hs.hotkey.bind(
    {"ctrl"},
    "return",
    function()
        wave:start(15)
    end
)
