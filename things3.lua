local function getNextTask()
    local thingsPath =
        "~/Library/Containers/com.culturedcode.ThingsMac/Data/Library/Application Support/Cultured Code/Things/Things.sqlite3"

    local db = hs.sqlite3.open(hs.fs.pathToAbsolute(thingsPath))

    local sm =
        db:prepare(
        [[
            SELECT `title` FROM `TMTask` WHERE `uuid` IN (
                SELECT `tasks` FROM `TMTaskTag` WHERE `tags` LIKE (
				    SELECT `uuid` FROM `TMTag`
				    WHERE `title` LIKE '👨🏻‍💻'
			    )
            ) AND `status` LIKE 0 AND `trashed` LIKE 0 ORDER BY `todayIndex`
        ]]
    )

    sm:step()

    local task = sm:get_value(0)

    sm:finalize()
    db:close()

    return task
end

return {
    getNextTask = getNextTask
}
