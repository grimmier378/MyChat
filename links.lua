---@type Mq
local mq = require('mq')
local PackageMan = require('mq/PackageMan')
local sqlite3 = PackageMan.Require('lsqlite3')
local dbname = 'MQ2LinkDB'
dbname = string.format("%s%s.db", dbname, mq.TLO.MacroQuest.BuildName() == 'Emu' and '_Emu' or '')
local pathDB = mq.TLO.MacroQuest.Path('resources')() .."/"..dbname 
local db = sqlite3.open(pathDB, sqlite3.OPEN_READONLY)  -- Open in read-only mode for fetching data
local sortedTable = {}
local msgOut = ''
local links = {
	running = false,
	enabled = true,
	addOn = false,
	---@type ConsoleWidget
	Console = nil, -- this catches a console passed to it for writing to.
}

local function printHelp()
	local msgOut = string.format("\ay[\aw%s\ay]\at -- LootLink -- \ax", mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\am A lua interface to MQ2LinkDB!!!\ax!",msgOut, mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\aw LootLink Commands!\ax!",msgOut, mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\ag /lootlink find [item name]\at Will search for item name supplied, or item on cursor\ax!!",msgOut, mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\ag /lootlink refresh \at Refresh Local table from MQ2LinkDB\ax!!",msgOut, mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\ag /lootlink quit \at Exits!\ax!!",msgOut, mq.TLO.Time())
	return msgOut
end

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
	return str:gsub("Di`zok", "Di`Zok"):gsub("-", ""):gsub("'", ""):gsub("`", ""):gsub("#", "")
end

local function loadSortedItems(db)
	msgOut = string.format("\ay[\aw%s\ay]\ao This may take few minutes...",mq.TLO.Time())
	if links.Console ~= nil then
		links.Console:AppendText(msgOut)
	else
		print(msgOut)
	end

	sortedTable = {}
	local fetchQuery = [[
		SELECT a.name, a.id, b.link
		FROM raw_item_data_315 AS a
		JOIN item_links AS b ON a.id = b.item_id
		ORDER BY LENGTH(a.name) DESC, a.name
	]]
	for row in db:nrows(fetchQuery) do
		local name = links.escapeSQL(row.name)
		sortedTable[name] = links.escapeSQL(row.link)
	end
	msgOut = string.format("\ay[\aw%s\ay]\at All Items \agloaded\ax, \ayScanning Chat for Items...",mq.TLO.Time())
	if links.Console ~= nil then
		links.Console:AppendText(msgOut)
	else
		print(msgOut)
	end
end

function links.initDB()
	
	msgOut = string.format("\ay[\aw%s\ay]\ar Links are Disabled, \atEnable and try again.",mq.TLO.Time())
	if not links.enabled then
		if links.Console ~= nil then
			return links.Console:AppendText(msgOut)
		else
			return print(msgOut)
		end
	end

	-- Check if the local table exists
	if not tableExists(db, "raw_item_data_315") or not tableExists(db, "item_links")  then
		msgOut = string.format("\ay[\aw%s\ay]\at %s \arMissing \axrun \ao/link /update \agto create.",mq.TLO.Time(), dbname)
		if links.Console ~= nil then
			return links.Console:AppendText(msgOut)
		else
			return print(msgOut)
		end
	end

	msgOut = string.format("\ay[\aw%s\ay]\at Fetching \agItems\ax from \ao%s...",mq.TLO.Time(),dbname)
	if links.Console ~= nil then
		links.Console:AppendText(msgOut)
	else
		print(msgOut)
	end

	loadSortedItems(db)

	db:close()
end

-- local function addItem()
-- 	local newName = links.escapeSQL(mq.TLO.Cursor.Name()) or ''
-- 	local newLink = links.escapeSQL(mq.TLO.Cursor.ItemLink('CLICKABLE')()) or ''
-- 	local newID = mq.TLO.Cursor.ID() or 0
    
-- 	-- open DB
-- 	db = sqlite3.open(pathDB)
-- 	db:exec("BEGIN TRANSACTION;")

-- 	local function executeStatement(stmt)
-- 		if db:exec(stmt) ~= sqlite3.OK then
-- 			print("Failed to execute statement: ", db:errmsg())
-- 			db:exec("ROLLBACK;") -- Roll back on error
-- 			return false
-- 		end
-- 		return true
-- 	end

-- 	-- Prepare and execute SQL statements using the escapeSQL function
-- 	if not executeStatement(string.format("REPLACE INTO raw_item_data_315 (id, name) VALUES (%d, '%s')", newID, newName)) or
-- 	   not executeStatement(string.format("REPLACE INTO item_links (link, item_id) VALUES ('%s', %d)", newLink, newID)) then
-- 		print("Transaction failed")
-- 		db:close()
-- 		return
-- 	end

-- 	db:exec("COMMIT;")
-- 	db:close()

-- 	sortedTable[newName] = newLink

-- 	local msgOut = string.format("\ay[\aw%s\ay]\at %s \agADDED\ax, \ay!", mq.TLO.Time(), newName)
-- 	if links.Console ~= nil then
-- 		links.Console:AppendText(msgOut)
-- 	else
-- 		print(msgOut)
-- 	end
-- end

--- Table Stuff ---
function links.collectItemLinks(text)
	local linksFound = {}
	local uniqueLinks = {}
	local matchedIndices = {}
	local replacements = {}
	local words = {}

	-- Check and strip trailing apostrophe
	if text:sub(-1) == "'" then
		text = text:sub(1, -2)
	end
	text = links.escapeSQL(text)  -- Prepare the text for matching
    
	for word in text:gmatch("[%w'`%`%:%'%-]+") do
		table.insert(words, word)
	end

	-- print("Debug: Words extracted ->", table.concat(words, ", "))
	local maxWords = 18
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
	return text
end

function links.bind(...)
	local args = {...}
	local key = args[1] or nil
	local value = nil
	local msgOut = ''
	-- local curItem = mq.TLO.Cursor() or nil
	if #args > 1 then
		value = table.concat(args, " ", 2)
	end
	if key == nil or key == 'help' then
		msgOut = printHelp()
	elseif string.lower(key) == 'find' then
		-- printf("Key: %s", key)
		if value ~= nil then
			-- printf("Value: %s", value)
			ItemToFind = value
			msgOut = links.collectItemLinks(ItemToFind)
		else
			msgOut = string.format("\ay[\aw%s\ay]\ao No string supplied!! \atTry Again\ax!", mq.TLO.Time())
		end
	-- elseif string.lower(key) == 'add' then
	-- 	if curItem ~= nil then
	-- 		addItem()
	-- 	else
	-- 		msgOut = string.format("\ay[\aw%s\ay]\ao Nothing on Cursor!! \atTry Again\ax!", mq.TLO.Time())
	-- 	end
	elseif string.lower(key) == 'refresh' then
		db = sqlite3.open(pathDB, sqlite3.OPEN_READONLY)
		links.initDB()	
	elseif string.lower(key) == 'quit' then
		links.running = false
	end
	if msgOut ~= '' then
		if links.Console ~= nil then
			links.Console:AppendText(msgOut)
		else
			print(msgOut)
		end
	end
end

local function loopDloop()
	while links.running do
		mq.delay(1)
	end
	mq.unbind('/lootlink')
end

local args = {...}
local function checkArgs(args)
	if args[1] == nil then
		links.running = true
	else
		return
	end
end
checkArgs(args)

local function init()
	if not links.addOn then
		links.running = true
		print(printHelp())
		links.initDB()
		loopDloop()
	end
end

mq.bind('/lootlink', links.bind)

if links.running then
	init()
end

return links