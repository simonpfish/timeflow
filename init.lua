local sqlite3 = require("lsqlite3complete")

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

--- Things3 utils ---

local function getNextTask()
    local thingsPath =
        "~/Library/Containers/com.culturedcode.ThingsMac/Data/Library/Application Support/Cultured Code/Things/Things.sqlite3"

    local db = sqlite3.open(hs.fs.pathToAbsolute(thingsPath))

    local sm =
        db:prepare(
        [[
            SELECT `title` FROM `TMTask` WHERE `uuid` IN (
            SELECT `tasks` FROM `TMTaskTag` WHERE `tags` LIKE '%CD67BB58-A8C4-4EB2-8FD8-29A6E0C6437A%'
            ) AND `status` LIKE 0 AND `trashed` LIKE 0 ORDER BY `todayIndex`
        ]]
    )

    sm:step()

    local task = sm:get_value(0)

    sm:finalize()
    db:close()

    return task
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
    self.task = getNextTask()
    self.startTime = hs.timer.localTime()
    self.endTime = self.startTime + duration

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
            updateMenuTimer(remaining, self.task)
        end,
        1
    )
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
