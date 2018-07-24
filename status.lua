local drawing = require "hs.drawing"
local screen = require "hs.screen"
local styledtext = require "hs.styledtext"

local status = {}

function status:setText(text)
    local frame = screen.primaryScreen():frame()

    local styledText =
        styledtext.new(
        text,
        {
            font = {name = "Menlo", size = 24}
        }
    )

    local textSize = drawing.getTextDrawingSize(styledText)
    local textRect = {
        x = frame.w / 2 - textSize.w / 2,
        y = frame.h / 2 - textSize.h / 2,
        w = textSize.w + 40,
        h = textSize.h + 40
    }

    if self.background then
        self.background:delete()
    end
    if self.text then
        self.text:delete()
    end

    self.text = drawing.text(textRect, styledText):setAlpha(0.7)

    self.background =
        drawing.rectangle(
        {
            x = frame.w / 2 - textSize.w / 2 - 5,
            y = frame.h / 2 - textSize.h / 2 - 3,
            w = textSize.w + 15,
            h = textSize.h + 6
        }
    )
    self.background:setRoundedRectRadii(10, 10)
    self.background:setFillColor({red = 0, green = 0, blue = 0, alpha = 0.6})
end

function status:show(wave)
    if wave.isRunning then
        self:setText(wave:getProgressIndicator() .. " " .. wave.task)
    else
        self:setText(wave.task .. " 🌊")
    end
    self.background:show()
    self.text:show()
end

function status:chooseDuration(wave)
    local timeStr = ""
    local listener
    listener =
        hs.eventtap.new(
        {hs.eventtap.event.types.keyDown},
        function(event)
            if event:getKeyCode() == hs.keycodes.map["return"] then
                if timeStr == "" then
                    wave:triggerTimer(wave.defaultDuration)
                else
                    wave:triggerTimer(tonumber(timeStr) * 60)
                end

                self:hide()
                listener:stop()
            elseif event:getKeyCode() == hs.keycodes.map["escape"] then
                self:hide()
                listener:stop()
            elseif event:getKeyCode() == hs.keycodes.map["delete"] then
                self:setText(wave.task .. " 🌊")
                self.background:show()
                self.text:show()
                timeStr = ""
            else
                timeStr = timeStr .. event:getCharacters()
                wave.remaining = tonumber(timeStr) * 60 - 1 -- TODO: fix this, not a nice access
                self:setText(wave:getProgressIndicator() .. " " .. wave.task .. " 🌊")
                self.background:show()
                self.text:show()
            end
            return true
        end
    ):start()
end

function status:hide()
    self.background:hide()
    self.text:hide()
end

return status
