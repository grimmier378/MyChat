---@type Mq
local mq = require('mq')
local PackageMan = require('mq/PackageMan')
local sqlite3 = PackageMan.Require('lsqlite3')
local dbname = 'MQ2LinkDB.db'
local liveDb = 'MQ2LinkDB.db'
local emuDb = 'MQ2LinkDB_Emu.db'
local Build = mq.TLO.MacroQuest.BuildName()
local path = mq.TLO.MacroQuest.Path('resources')() .."/"
local db, pathDB
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
local nonLinks = {
	['Shadow Knight'] 		= 'Shadow Knight',
	['Scourge Knight'] 		= 'Scourge Knight',
	['Stone Fist'] 			= 'Stone Fist',
}

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
	return str:gsub("Di`zok", "Di`Zok"):gsub("-", ""):gsub("'", ""):gsub("`", ""):gsub("#", "")
end

local function loadSortedItems()
	sortedTable = {}
	sortedTable = nonLinks

	local fetchQuery = [[
		SELECT 
			SUBSTR(link, 1, INSTR(SUBSTR(link, 2), x'12') + 1) AS link, 
			SUBSTR(link, 58, INSTR(SUBSTR(link, 58), x'12') - 1) AS name
		FROM 
			item_links
		ORDER BY 
			LENGTH(name) DESC, name;
	]]
	for row in db:nrows(fetchQuery) do
		local name =links.escapeSQL(row.name)
		-- printf("Name: %s", name)
		sortedTable[name] = links.escapeSQL(row.link)
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
	dbname = liveDb
	pathDB = path..liveDb
local GoodToGo = false
	if Build == 'Emu' then
		-- set path to Emu db
		pathDB = path..emuDb
		if not File_Exists(pathDB) then -- check for EMU Db
			-- emu db doesn't exist chedk for alive
			pathDB = path..liveDb
			-- check for live db EMU was missing
			if File_Exists(pathDB) then
				-- Live DB Exists
				Build = 'Live'			-- change local build var so we don't have to dbl check next cycle
				msgOut = string.format("\ay[\aw%s\ay]\atYou are using a \arLive server DB\aw on\ay EMU\at You may recieve false links!.",mq.TLO.Time())
				if links.Console then
					links.Console:AppendText(msgOut)
				else print(msgOut) end
				dbname = liveDb
				GoodToGo = true
			end
		else
			dbname = emuDb
			GoodToGo = true
		end
	
	elseif not File_Exists(pathDB) then
		msgOut = string.format("\ay[\aw%s\ay]\arNO DB's Found Links are Disabled, \atRun MQ2LindDB /link /import and try again.",mq.TLO.Time())
		links.enabled = false
		return (links.Console and links.Console:AppendText(msgOut) or print(msgOut))
	
	else
		GoodToGo = true
		links.enabled = true
	end

	if GoodToGo then
		db = sqlite3.open(pathDB, sqlite3.OPEN_READONLY)

		-- print(db)
		-- Check if the local table has Data
		if not tableHasData(db, "item_links")  then
			msgOut = string.format("\ay[\aw%s\ay]\at %s \arMissing \axrun \ao/link /update \agto create.",mq.TLO.Time(), dbname)
			if links.running  then
				return (links.Console and links.Console:AppendText(msgOut) or print(msgOut))
			else
				print(msgOut)
			end
		end

		msgOut = string.format("\ay[\aw%s\ay]\at Fetching \agItems\ax from \ao%s...",mq.TLO.Time(),dbname)
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