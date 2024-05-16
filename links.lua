---@type Mq
local mq = require('mq')
local PackageMan = require('mq/PackageMan')
local sqlite3 = PackageMan.Require('lsqlite3')
local mergedDB = 'MQ2LinkDB.db'
local currDB = 'MQ2LinkDB.db'
local liveDb = 'MQ2LinkDB_Live.db'
local testDb = 'MQ2LinkDB_Test.db'
local emuDb = 'MQ2LinkDB_Emu.db'
local Build = mq.TLO.MacroQuest.BuildName()
local path = mq.TLO.MacroQuest.Path('resources')() .."/"
local db, pathDB
local GoodToGo = false
local sortedTable = {}
local msgOut = ''
local links = {
	running = false,
	ready = false,
	enabled = true,
	addOn = false,

	---@type ConsoleWidget
	Console = nil, -- this catches a console passed to it for writing to.
}
local nonLinks = require('link_subs')

local function printHelp()
	local msgOut = string.format("\ay[\aw%s\ay]\at -- LootLink -- \ax", mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\am A lua interface to MQ2LinkDB!!!\ax!",msgOut, mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\aw LootLink Commands!\ax!",msgOut, mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\ag /lootlink find [string]\at Will search for links in entire String supplied, and return it with the links inserted\ax!!",msgOut, mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\ag /lootlink refresh \at Refresh Local table from MQ2LinkDB\ax!!",msgOut, mq.TLO.Time())
	msgOut = string.format("%s\n\ay[\aw%s\ay]\ag /lootlink quit \at Exits!\ax!!",msgOut, mq.TLO.Time())
	return msgOut
end

---Check to see if the file we want to work on exists.
---@param name string -- Full Path to file
---@return boolean -- returns true if the file exists and false otherwise
local function File_Exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

--- SQL Stuff ---
local function tableHasData(dbCheck, tableName)

	local query = string.format("SELECT name FROM sqlite_master WHERE type='table' AND name='%s';", tableName)
	for row in dbCheck:nrows(query) do
		return true -- The table exists if we can fetch at least one row
	end
	return false -- No rows fetched means the table does not exist
end

function links.escapeLuaPattern(s)
	return s:gsub("([%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
end

function links.escapeSQL(str)
	if not str then return " " end  -- Return an empty string if the input is nil
	return str:gsub("-", ""):gsub("'", ""):gsub("`", ""):gsub("#", "")
	:gsub("%(", ""):gsub("%)", ""):gsub("%]", ""):gsub("%[", ""):gsub("%.", "")--:gsub("Pg.", "Pg"):gsub("Di`zok", "Di`Zok")
end

local function loadSortedItems()
	sortedTable = {}
	sortedTable = nonLinks
	-- print(Build)
	-- Pull database and ignore the item ID 1048575 as that is the npc say link. which is only set once to the first npc line it sees
	local fetchQuery = ''
	if Build == 'Emu' then
		fetchQuery = [[
			SELECT 
				SUBSTR(link, 1, INSTR(SUBSTR(link, 2), x'12') + 1) AS link, 
				REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
					SUBSTR(link, 58, INSTR(SUBSTR(link, 58), x'12') - 1), 
					'.', ''), '`', ''), '''', ''), ',', ''), '(', ''), ')', ''), '#', '') AS name
			FROM 
				item_links
			WHERE
				item_id  != 1048575
			ORDER BY 
				LENGTH(name) DESC, name;
		]]
	elseif Build == 'Live' or Build == 'Merged' then
		fetchQuery = [[
			SELECT 
				SUBSTR(link, 1, INSTR(SUBSTR(link, 2), x'12') + 1) AS link, 
				REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
					SUBSTR(link, 93, INSTR(SUBSTR(link, 93), x'12') - 1), 
					'.', ''), '`', ''), '''', ''), ',', ''), '(', ''), ')', ''), '#', '') AS name
			FROM 
				item_links
			WHERE
				item_id  != 1048575
			ORDER BY 
				LENGTH(name) DESC, name;
		]]
	end
	if mq.TLO.MacroQuest.BuildName() == 'Emu' and Build == 'Merged' then
		fetchQuery = [[
			SELECT 
				SUBSTR(link, 1, 8) ||
				SUBSTR(link, 44, INSTR(SUBSTR(link, 44), x'12') + 1) ||
				SUBSTR(link, INSTR(SUBSTR(link, 44), x'12') + 44) AS link,
				REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
					SUBSTR(link, 93, INSTR(SUBSTR(link, 93), x'12') - 1), 
					'.', ''), '`', ''), '''', ''), ',', ''), '(', ''), ')', ''), '#', '') AS name
			FROM 
				item_links
			WHERE
				item_id != 1048575
			ORDER BY 
				LENGTH(name) DESC, name;
		]]
	end
	-- print(fetchQuery)
	for row in db:nrows(fetchQuery) do
		local name =row.name
		-- printf("Name: %s", name)
		sortedTable[name] = row.link
	end
	msgOut = string.format("\ay[\aw%s\ay]\at All Items \agloaded\ax, \ayScanning Chat for Items...",mq.TLO.Time())
	
	if links.running  then
		return (links.Console and links.Console:AppendText(msgOut) or print(msgOut))
	else
		print(msgOut)
	end
end

function links.initDB()
	links.ready = false
	-- dbname = liveDb
	pathDB = path..currDB
	if not GoodToGo then
		if Build == 'Emu' then
			-- set path to Emu db
			pathDB = path..emuDb
			if not File_Exists(pathDB) then -- check for EMU Db
				-- emu db doesn't exist chedk for alive
				pathDB = path..mergedDB
				-- check for live db EMU was missing
				if File_Exists(pathDB) then
					-- Live DB Exists
					Build = 'Merged'			-- change local build var so we don't have to dbl check next cycle
					msgOut = string.format("\ay[\aw%s\ay]\atYou are using a \arMerged server DB\aw on\ay EMU\at You may recieve false links!.",mq.TLO.Time())
					if links.Console then
						links.Console:AppendText(msgOut)
					else print(msgOut) end
					currDB = mergedDB
					GoodToGo = true
				end
			else
				currDB = emuDb
				GoodToGo = true
			end
		elseif Build == 'Test' then
			-- set path to Test db
			pathDB = path..testDb
			if not File_Exists(pathDB) then -- check for Test Db
				-- Test db doesn't exist chedk for alive
				pathDB = path..mergedDB
				-- check for live db Test was missing
				if File_Exists(pathDB) then
					-- Live DB Exists
					Build = 'Merged'			-- change local build var so we don't have to dbl check next cycle
					msgOut = string.format("\ay[\aw%s\ay]\atYou are using a \arMerged server DB\aw on\ay Test\at You may recieve false links!.",mq.TLO.Time())
					if links.Console then
						links.Console:AppendText(msgOut)
					else print(msgOut) end
					currDB = mergedDB
					GoodToGo = true
				end
			else
				currDB = testDb
				GoodToGo = true
			end
		elseif Build == 'Live' then
			-- set path to Test db
			pathDB = path..liveDb
			if not File_Exists(pathDB) then -- check for Test Db
				-- Test db doesn't exist chedk for alive
				pathDB = path..mergedDB
				-- check for live db Test was missing
				if File_Exists(pathDB) then
					-- Live DB Exists
					Build = 'Merged'			-- change local build var so we don't have to dbl check next cycle
					msgOut = string.format("\ay[\aw%s\ay]\atYou are using a \arMerged server DB\aw on\ay Live\at You may recieve false links!.",mq.TLO.Time())
					if links.Console then
						links.Console:AppendText(msgOut)
					else print(msgOut) end
					currDB = mergedDB
					GoodToGo = true
				end
			else
				currDB = liveDb
				GoodToGo = true
			end

		else
			pathDB = path..mergedDB
			if not File_Exists(pathDB) then
				msgOut = string.format("\ay[\aw%s\ay]\arNO DB's Found Links are Disabled, \atRun MQ2LindDB /link /import and try again.",mq.TLO.Time())
				links.enabled = false
				GoodToGo = false
				return (links.Console and links.Console:AppendText(msgOut) or print(msgOut))
			else
				Build = 'Merged'
				GoodToGo = true
				links.enabled = true
			end
		end
	end
	if GoodToGo then
		pathDB = path..currDB
		db = sqlite3.open(pathDB, sqlite3.OPEN_READONLY)

		-- print(db)
		-- Check if the local table has Data
		if not tableHasData(db, "item_links")  then
			msgOut = string.format("\ay[\aw%s\ay]\at %s \arMissing \axrun \ao/link /update \agto create.",mq.TLO.Time(), currDB)
			if links.running  then
				return (links.Console and links.Console:AppendText(msgOut) or print(msgOut))
			else
				print(msgOut)
			end
		end

		msgOut = string.format("\ay[\aw%s\ay]\at Fetching \agItems\ax from \ao%s...",mq.TLO.Time(),currDB)
		if links.running  then
			return (links.Console and links.Console:AppendText(msgOut) or print(msgOut))
		else
			print(msgOut)
		end

		loadSortedItems()
		links.ready = true
		db:close()
	end
end

--- Table Stuff ---
function links.collectItemLinks(line)
	local linksFound = {}
	local uniqueLinks = {}
	local matchedIndices = {}
	local replacements = {}
	local words = {}
	local text = line
	
	-- Check and strip trailing apostrophe
	if text:sub(-1) == "'" then
		text = text:sub(1, -2)
	end
	text = links.escapeSQL(text)  -- Prepare the text for matching
    -- text = links.escapeLuaPattern(text)
	for word in text:gmatch("[%w'`%:%'%-%,%.]+") do
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
	if #linksFound > 0 then
		return text
	else
		return line
	end
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
			msgOut = string.format("\ay[\aw%s\ay]\ax %s", mq.TLO.Time(), links.collectItemLinks(ItemToFind))
		else
			msgOut = string.format("\ay[\aw%s\ay]\ao No string supplied!! \atTry Again\ax!", mq.TLO.Time())
		end
	elseif string.lower(key) == 'refresh' then
		db = sqlite3.open(pathDB, sqlite3.OPEN_READONLY)
		links.initDB()	
	elseif string.lower(key) == 'quit' then
		links.running = false
	end
	if msgOut ~= '' then
		return (links.Console and links.Console:AppendText(msgOut) or print(msgOut))
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
	print(printHelp())
	links.initDB()
	loopDloop()
end

mq.bind('/lootlink', links.bind)

if links.running then
	init()
else
	print(printHelp())
	links.initDB()
end

return links