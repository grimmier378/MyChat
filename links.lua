---@type Mq
local mq = require('mq')
local PackageMan = require('mq/PackageMan')
local sqlite3 = PackageMan.Require('lsqlite3')
local pathDB = mq.TLO.MacroQuest.Path('resources')() .."/MQ2LinkDB.db"
-- local localDBPath = mq.configDir..'/ItemsDB/ItemsDB.db'
local db = sqlite3.open(pathDB, sqlite3.OPEN_READONLY)  -- Open in read-only mode
-- local itemsInfo = {}
local sortedTable = {}
-- local searchExact = false
-- local newDB = false
-- local db = sqlite3.open(localDBPath)  -- Open the local database
local msgOut = ''
local links = {
	enabled = true,
	---@type ConsoleWidget
	Console = nil, -- this catches a console passed to it for writing to.
}

--- SQL Stuff ---
local function tableExists(db, tableName)
	local query = string.format("SELECT name FROM sqlite_master WHERE type='table' AND name='%s';", tableName)
	for row in db:nrows(query) do
		return true -- The table exists if we can fetch at least one row
	end
	return false -- No rows fetched means the table does not exist
end

function links.escapeLuaPattern(s)
	return s:gsub("([%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
end

function links.escapeSQL(str)
	if not str then return " " end  -- Return an empty string if the input is nil
	return str:gsub("Di`zok", "Di`Zok"):gsub("-", ""):gsub("'", ""):gsub("`", "")--:gsub(":", "_")  -- Escape backticks and -
	-- return str
end
function links.escapeBack(str)
	if not str then return " " end  -- Return an empty string if the input is nil
	return str:gsub("Di`zok", "Di`Zok"):gsub("-", ""):gsub(":", ""):gsub("'", ""):gsub("`", "")   -- Escape backticks and -
	-- return str
end

local function loadSortedItems(db)
	-- local tmpDB = {}
	sortedTable = {}
	local fetchQuery = [[
		SELECT a.name, a.id, b.link
		FROM raw_item_data_315 AS a
		JOIN item_links AS b ON a.id = b.item_id
		ORDER BY LENGTH(a.name) DESC, a.name
	]]
	for row in db:nrows(fetchQuery) do
		-- table.insert(sortedTable,  {item_name = escapeSQL(row.item_name), item_id = row.item_id, item_link = escapeSQL(row.item_link)})
		-- sortedTable[escapeLuaPattern(row.item_name)] = row.item_link
		local name = links.escapeSQL(row.name)
		sortedTable[name] = row.link

	end
	msgOut = string.format("\ay[\aw%s\ay]\at All Items \agloaded\ax, \ayScanning Chat for Items...",mq.TLO.Time())
	if links.Console ~= nil then
		links.Console:AppendText(msgOut)
	else
		print(msgOut)
	end
end

function links.initDB()

	-- -- Attach the source MQ2LinkDB database to the local database connection
	-- local attachQuery = string.format("ATTACH DATABASE '%s' AS sourceDB", sqlItemsDB)
	-- if dbLocal:exec(attachQuery) ~= sqlite3.OK then
	-- 	print("Failed to attach database:", dbLocal:errmsg())
	-- 	return
	-- end
	msgOut = string.format("\ay[\aw%s\ay]\ar Links are Disabled, \atEnable and try again.",mq.TLO.Time())
	if not links.enabled then
		if links.Console ~= nil then
			links.Console:AppendText(msgOut)
		else
			print(msgOut)
		end
		return
	end

	-- Check if the local table exists, create if not
	if not tableExists(pathDB, "raw_item_data_315") or not tableExists(pathDB, "item_links")  then

		msgOut = string.format("\ay[\aw%s\ay]\at MQ2LinkDB Missing run \ao/link /update \agto create.",mq.TLO.Time())

		if links.Console ~= nil then
			links.Console:AppendText(msgOut)
		else
			print(msgOut)
		end
		return
	end

	-- Perform a direct insert from the attached source table
	
	msgOut = string.format("\ay[\aw%s\ay]\at Fetching \agItems\ax from \aoMQ2LinkDB...",mq.TLO.Time())
	if links.Console ~= nil then
		links.Console:AppendText(msgOut)
	else
		print(msgOut)
	end
	
	-- if dbLocal:exec(migrationQuery) ~= sqlite3.OK then
	-- 	msgOut = string.format("\ay[\aw%s\ay]\arMigration failed:",mq.TLO.Time(),dbLocal:errmsg())
	-- else
	-- 	msgOut = string.format("\ay[\aw%s\ay]\at Migration Successfull! \agLoading Items...",mq.TLO.Time())
	-- end
	-- if links.Console ~= nil then
	-- 	links.Console:AppendText(msgOut)
	-- else
	-- 	print(msgOut)
	-- end
	loadSortedItems(db)
	-- Detach the source database
	-- dbLocal:exec("DETACH DATABASE sourceDB")

	db:close()
end

--- Table Stuff ---
function links.collectItemLinks(text)
	-- links.Console:AppendText("%s'", text)
	local linksFound = {}
	local uniqueLinks = {}
	local matchedIndices = {}
	local replacements = {}
	local orig = text
	-- Check and strip trailing apostrophe
	if text:sub(-1) == "'" then
		text = text:sub(1, -2)
	end
	text = links.escapeSQL(text)  -- Prepare the text for matching
	local words = {}
	for word in text:gmatch("[%w'`%`%:%'%-]+") do
		table.insert(words, word)
	end

	-- links.Console:AppendText("\ay[\aw%s\ay]\agStarting Item Lookup...", mq.TLO.Time())
	-- print("Debug: Words extracted ->", table.concat(words, ", "))
	local maxWords = 13
	for numWords = maxWords, 1, -1 do
		for start = 1, #words - numWords + 1 do
			if not matchedIndices[start] then
				local phrase = table.concat(words, ' ', start, start + numWords - 1)
				-- print("Debug: Testing phrase ->", phrase)
				if (sortedTable[links.escapeSQL(phrase)]  or sortedTable[phrase] )and
				(not uniqueLinks[phrase] or not uniqueLinks[links.escapeSQL(phrase)]) then
					for i = start, start + numWords - 1 do
						matchedIndices[i] = true  -- Mark these indices as matched
					end
					table.insert(linksFound, sortedTable[links.escapeSQL(phrase)])
					replacements[links.escapeSQL(phrase)] = sortedTable[links.escapeSQL(phrase)]
					linksFound[phrase] = true
					-- print("Debug: Match found for ->", phrase)
				end
			end
		end
	end
	for k, v in pairs(replacements) do
		text = text:gsub(k,v)
	end
	-- links.Console:AppendText("%s'", text)
	return text --string.format("Output String: %s", text) --"Links Found: " .. table.concat(linksFound, ", ")
end

return links
