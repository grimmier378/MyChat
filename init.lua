local mq = require('mq')
local ImGui = require('ImGui')
local defaults =  require('default_settings')
local Icons = require('mq.ICONS')

local PackageMan = require('mq/PackageMan')
PackageMan.Require('lsqlite3')

local resetPosition = false
local setFocus = false
local commandBuffer = ''

-- local var's
local serverName = string.gsub(mq.TLO.EverQuest.Server(), ' ', '_') or ''
local myName = mq.TLO.Me.Name() or ''
local addChannel = false -- Are we adding a new channel or editing an old one
local tempSettings, eventNames = {}, {} -- tables for storing event details
local useTheme, timeStamps, newEvent, newFilter= false, true, false, false
local zBuffer = 1000 -- the buffer size for the Zoom chat buffer.
local editChanID, editEventID, lastID, lastChan  = 0, 0, 0, 0
local tempFilterStrings, tempEventStrings, tempChanColors, tempFiltColors, hString = {}, {}, {}, {}, {} -- Tables to store our strings and color values for editing
local ActTab, activeID = 'Main', 0 -- info about active tab channels
local theme = {} -- table to hold the themes file into.
local useThemeName = 'Default' -- Name of the theme we wish to apply
local ColorCountEdit,ColorCountConf, ColorCount, StyleCount, StyleCountEdit, StyleCountConf = 0, 0, 0, 0, 0, 0
local lastImport = 'none' -- file name of the last imported file, if we try and import the same file again we will abort.
local windowNum = 0 --unused will remove later.
local fromConf = false -- Did we open the edit channel window from the main config window? if we did we will go back to that window after closing.
local gIcon = Icons.MD_SETTINGS
local zoomMain = false
local firstPass, forceIndex, doLinks = true, false, false
local mainLastScrollPos = 0
local mainBottomPosition = 0
local doRefresh = false
local timeA = os.time()
local mainBuffer = {}
local importFile = 'MyChat_Server_CharName.lua'
local cleanImport = false
local Tokens = {} -- may use this later to hold the tokens and remove a long string of if elseif.
local enableSpam, LinksReady = false, false
local links = require('links')
if links ~= nil then links.addOn = true end
local running = false
local eChan = '/say'

local ChatWin = {
    SHOW = true,
    openGUI = true,
    openConfigGUI = false,
    refreshLinkDB = 10,
    mainEcho = '/say',
    doRefresh = false,
    SettingsFile = string.format('%s/MyChat_%s_%s.lua', mq.configDir, serverName, myName),
    ThemesFile = string.format('%s/MyThemeZ.lua', mq.configDir, serverName, myName),
    Settings = {
        -- Channels
        Channels = {},
    },
    ---@type ConsoleWidget
    console = nil,
    commandBuffer = '',
    timeStamps = true,
    doLinks = false,
    -- Consoles
    Consoles = {},
    -- Flags
    tabFlags = bit32.bor(ImGuiTabBarFlags.Reorderable, ImGuiTabBarFlags.TabListPopupButton),
    winFlags = bit32.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoScrollbar),
    PopOutFlags = bit32.bor(ImGuiWindowFlags.NoScrollbar),
}

local MyColorFlags = bit32.bor(
    ImGuiColorEditFlags.NoOptions,
    ImGuiColorEditFlags.NoInputs,
    ImGuiColorEditFlags.NoTooltip,
    ImGuiColorEditFlags.NoLabel
)



--- Helper Functions ---
local function ReLoadDB()
    if links ~= nil then
        ChatWin.console:AppendText("\ay[\aw%s\ay]\at Refreshing \aoLinksDB",mq.TLO.Time())
        printf("\ay[\aw%s\ay]\at Refreshing \aoLinksDB",mq.TLO.Time())
        links.initDB()
    end
end

---Converts ConColor String to ColorVec Table
---@param colorString string @string value for color 
---@return table @Table of R,G,B,A Color Values
local function GetColorVal(colorString)
    colorString = string.lower(colorString)
    if (colorString=='red') then return {0.9, 0.1, 0.1, 1} end
    if (colorString=='yellow') then return {1, 1, 0, 1} end
    if (colorString=='yellow2') then return { 0.7, 0.6, 0.1, 0.7} end
    if (colorString=='white') then return {1, 1, 1, 1} end
    if (colorString=='blue') then return {0, 0.5, 0.9, 1} end
    if (colorString=='light blue') then return {0, 1, 1, 1} end
    if (colorString=='green') then return {0, 1, 0, 1} end
    if (colorString=='grey') then return {0.6, 0.6, 0.6, 1} end
    -- return White as default if bad string
    return {1, 1, 1, 1}
end

---Check to see if the file we want to work on exists.
---@param name string -- Full Path to file
---@return boolean -- returns true if the file exists and false otherwise
local function File_Exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

---Checks for the last ID number in the table passed. returns the NextID
---@param table table -- the table we want to look up ID's in
---@return number -- returns the NextID that doesn't exist in the table yet.
local function getNextID(table)
    local maxChannelId = 0
    for channelId, _ in pairs(table) do
        local numericId = tonumber(channelId)
        if numericId < 9000 then
            if numericId and numericId > maxChannelId then
                maxChannelId = numericId
            end
        end
    end
    return maxChannelId + 1
end

---Build the consoles for each channel based on ChannelID
---@param channelID integer -- the channel ID number for the console we are setting up
local function SetUpConsoles(channelID)
    if ChatWin.Consoles[channelID].console == nil then
        ChatWin.Consoles[channelID].txtBuffer = {
            [1] = {
                color ={[1]=1,[2]=1,[3]=1,[4]=1},
                text = '',
            }
        }
        ChatWin.Consoles[channelID].CommandBuffer = ''
        ChatWin.Consoles[channelID].txtAutoScroll = true
        -- ChatWin.Consoles[channelID].enableLinks = ChatWin.Settings[channelID].enableLinks
        ChatWin.Consoles[channelID].console = ImGui.ConsoleWidget.new(channelID.."##Console")
    end
end

---Takes in a table and re-numbers the Indicies to be concurrent
---@param table any @Table to reindex
---@return table @ Returns the table with the Indicies in order with no gaps.
local function reindex(table)
    local newTable = {}
    local newIdx = 0
    for k, v in pairs(table) do
        if k == 0 or k == 9000 or k >= 9100 then
            newTable[k] = v
        else
            newIdx = newIdx + 1
            newTable[newIdx] = v
        end
    end
    return newTable
end

---Process ChatWin.Settings and reindex the Channel, Events, and Filter ID's 
---Runs each table through the reindex function and updates the settings file when done
---@param file any @ Full File path to config file
---@param table any @ Returns the table with the Indicies in order with no gaps.
local function reIndexSettings(file, table)
    table.Channels = reindex(table.Channels)
    local tmpTbl = table
    for cID, data in pairs (table.Channels) do
        for id, cData in pairs(data) do
            if id == "Events" then
                tmpTbl.Channels[cID][id] = reindex(cData)
                table = tmpTbl
                for eID, eData in pairs(table.Channels[cID].Events) do
                    for k,v in pairs(eData) do
                        if k == "Filters" then
                            tmpTbl.Channels[cID][id][eID].Filters = reindex(v)
                        end
                    end
                end
            end
        end
    end
    table = tmpTbl
    mq.pickle(file, table)
end

---Convert MQ event Strings from #*#blah #1# formats to a lua parsable pattern
local function convertEventString(oldFormat)

    -- local pattern = oldFormat:gsub("#", "")
    local pattern = oldFormat:gsub("#%*#", ".*")
    -- Convert * to Lua's wildcard .*
    -- pattern = pattern:gsub("#%*#", ".*")
    -- Convert n (where n is any number) to Lua's wildcard .*
    pattern = pattern:gsub("#%d#", ".*")

    -- Escape special characters that are not part of the wildcard transformation and should be literal
    -- Specifically targeting parentheses, plus, minus, and other special characters not typically part of text.
    pattern = pattern:gsub("([%^%[%$%(%)%.%]]%+%?])", "%%%1") -- Escaping special characters that might disrupt the pattern matching

    -- Do not escape brackets if they form part of the control structure of the pattern
    pattern = pattern:gsub("%[", "%%%[")
    pattern = pattern:gsub("%]", "%%%]") 
    -- print(pattern)
    return pattern
end


---Writes settings from the settings table passed to the setting file (full path required)
-- Uses mq.pickle to serialize the table and write to file
---@param file string -- File Name and path
---@param table table -- Table of settings to write
local function writeSettings(file, table)
    mq.pickle(file, table)
end

local function loadSettings()
    if not File_Exists(ChatWin.SettingsFile) then
        -- ChatWin.Settings = defaults
        mq.pickle(ChatWin.SettingsFile, defaults)
        loadSettings()
        else
        -- ChatWin.Settings = defaults
        -- Load settings from the Lua config file
        ChatWin.Settings = dofile(ChatWin.SettingsFile)
        if firstPass then
            local date = os.date("%m_%d_%Y_%H_%M")
            local backup = string.format('%s/MyChat/Backups/%s/%s_BAK_%s.lua', mq.configDir, serverName, myName, date)
            if not File_Exists(backup) then mq.pickle(backup, ChatWin.Settings) end
            reIndexSettings(ChatWin.SettingsFile, ChatWin.Settings)
            firstPass = false
        end
    end

    if ChatWin.Settings.Channels[0] == nil then
        ChatWin.Settings.Channels[0] = {}
        ChatWin.Settings.Channels[0] = defaults['Channels'][0]
    end
    if ChatWin.Settings.Channels[9000] == nil then
        ChatWin.Settings.Channels[9000] = {}
        ChatWin.Settings.Channels[9000] = defaults['Channels'][9000]
    end
    if ChatWin.Settings.Channels[9100] == nil then
        ChatWin.Settings.Channels[9100] = {}
        ChatWin.Settings.Channels[9100] = defaults['Channels'][9100]
    end
    ChatWin.Settings.Channels[9000].enabled = enableSpam
    
    if ChatWin.Settings.refreshLinkDB == nil then
        ChatWin.Settings.refreshLinkDB = defaults.refreshLinkDB
    end
    doRefresh = ChatWin.Settings.refreshLinkDB >= 5 or false
    if ChatWin.Settings.doRefresh == nil then
        ChatWin.Settings.doRefresh = doRefresh
    end
    local i = 1
    for channelID, channelData in pairs(ChatWin.Settings.Channels) do
        -- setup default Echo command channels.
        if not channelData.Echo then
            ChatWin.Settings.Channels[channelID].Echo = '/say'
        end
        -- Ensure each channel's console widget is initialized
        if not ChatWin.Consoles[channelID] then
            ChatWin.Consoles[channelID] = {}
        end
        
        if ChatWin.Settings.Channels[channelID].MainEnable == nil then
            ChatWin.Settings.Channels[channelID].MainEnable = true
        end
        if ChatWin.Settings.Channels[channelID].enableLinks == nil then
            ChatWin.Settings.Channels[channelID].enableLinks = false
        end
        if ChatWin.Settings.Channels[channelID].PopOut == nil then
            ChatWin.Settings.Channels[channelID].PopOut = false
        end
        if ChatWin.Settings.Channels[channelID].locked == nil then
            ChatWin.Settings.Channels[channelID].locked = false
        end
        
        if ChatWin.Settings.Scale == nil then
            ChatWin.Settings.Scale = 1.0
        end
        
        if ChatWin.Settings.Channels[channelID].TabOrder == nil then 
            ChatWin.Settings.Channels[channelID].TabOrder = i
        end
        if ChatWin.Settings.locked == nil then
            ChatWin.Settings.locked = false
        end
        
        if ChatWin.Settings.timeStamps == nil then
            ChatWin.Settings.timeStamps = timeStamps 
        end
        timeStamps =ChatWin.Settings.timeStamps
        if forceIndex then
            ChatWin.Consoles[channelID].console = nil
        end

        SetUpConsoles(channelID)
        if not ChatWin.Settings.Channels[channelID]['Scale'] then
            ChatWin.Settings.Channels[channelID]['Scale'] = 1.0
        end
        
        for eID, eData in pairs(channelData['Events']) do
            if eData.color then
                if not ChatWin.Settings.Channels[channelID]['Events'][eID]['Filters'] then
                    ChatWin.Settings.Channels[channelID]['Events'][eID]['Filters'] = {}
                end
                if ChatWin.Settings.Channels[channelID]['Events'][eID].enabled == nil then
                    ChatWin.Settings.Channels[channelID]['Events'][eID].enabled = true
                end
                if not ChatWin.Settings.Channels[channelID]['Events'][eID]['Filters'][0] then
                    ChatWin.Settings.Channels[channelID]['Events'][eID]['Filters'][0] = {filterString = '', color = {}}
                end
                ChatWin.Settings.Channels[channelID]['Events'][eID]['Filters'][0].color = eData.color
                eData.color = nil
            end
            for fID, fData in pairs(eData.Filters) do
                if fData.filterString == 'TANK' then
                    ChatWin.Settings.Channels[channelID].Events[eID].Filters[fID].filterString = 'TK1'
                    elseif fData.filterString == 'PET' then
                    ChatWin.Settings.Channels[channelID].Events[eID].Filters[fID].filterString = 'PT1'
                    elseif fData.filterString == 'P1' then
                    ChatWin.Settings.Channels[channelID].Events[eID].Filters[fID].filterString = 'PT1'
                    elseif fData.filterString == 'MA' then
                    ChatWin.Settings.Channels[channelID].Events[eID].Filters[fID].filterString = 'M1'
                    elseif fData.filterString == 'HEALER' then
                    ChatWin.Settings.Channels[channelID].Events[eID].Filters[fID].filterString = 'H1'
                    elseif fData.filterString == 'GROUP' then
                    ChatWin.Settings.Channels[channelID].Events[eID].Filters[fID].filterString = 'GP1'
                    elseif fData.filterString == 'ME' then
                    ChatWin.Settings.Channels[channelID].Events[eID].Filters[fID].filterString = 'M3'
                end
            end
        end
        i = i + 1
    end

    useThemeName = ChatWin.Settings.LoadTheme
    if not File_Exists(ChatWin.ThemesFile) then
        local defaultThemes = require('themes')
        theme = defaultThemes
        else
        -- Load settings from the Lua config file
        theme = dofile(ChatWin.ThemesFile)
    end
    
    if not ChatWin.Settings.LoadTheme then
        ChatWin.Settings.LoadTheme = theme.LoadTheme
    end

    if useThemeName ~= 'Default' then
        useTheme = true
    end

    if ChatWin.Settings.doLinks == nil then
        ChatWin.Settings.doLinks = true
    end
    if ChatWin.Settings.mainEcho == nil then
        ChatWin.Settings.mainEcho = '/say'
    end
    eChan = ChatWin.Settings.mainEcho
    ChatWin.Settings.doLinks = true
    links.enabled = ChatWin.Settings.doLinks
    forceIndex = false

    writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
    
    tempSettings = ChatWin.Settings
end

local function BuildEvents()
    eventNames = {}
    for channelID, channelData in pairs(ChatWin.Settings.Channels) do
        for eventId, eventDetails in pairs(channelData.Events) do
            if eventDetails.enabled then
                if eventDetails.eventString then
                    local eventName = string.format("event_%s_%d", channelID, eventId)
                    if channelID ~= 9000 then
                        mq.event(eventName, eventDetails.eventString, function(line) ChatWin.EventChat(channelID, eventName, line, false) end)
                    elseif channelID == 9000 and enableSpam then
                        mq.event(eventName, eventDetails.eventString, function(line) ChatWin.EventChatSpam(channelID, line) end)
                    end
                    -- Store event details for direct access
                    eventNames[eventName] = eventDetails
                end
            end
        end
    end
end

local function ResetEvents()
    ChatWin.Settings = tempSettings
    writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
    -- Unregister and reregister events to apply changes
    for eventName, _ in pairs(eventNames) do
        mq.unevent(eventName)
    end
    eventNames = {}
    loadSettings()
    BuildEvents()
end

---@param string string @ the filter string we are parsing
---@param line string @ the line captured by the event
---@param type string @ the type either 'healer' or 'group' for tokens H1 and GP1 respectivly.
---@return string string @ new value for the filter string if found else return the original
local function CheckGroup(string, line, type)
    local gSize = mq.TLO.Me.GroupSize()
    gSize = gSize -1
    local tString = string
        for i = 1, gSize do
            local class = mq.TLO.Group.Member(i).Class.ShortName() or 'NO GROUP'
            local name = mq.TLO.Group.Member(i).Name() or 'NO GROUP'
            if type == 'healer' then
                class = mq.TLO.Group.Member(i).Class.ShortName() or 'NO GROUP'
                if (class == 'CLR') or (class == 'DRU') or (class == 'SHM') then
                    name = mq.TLO.Group.Member(i).CleanName() or 'NO GROUP'
                    tString = string.gsub(string,'H1', name)
                end
            end
            if type == 'group' then
                tString = string.gsub(string, 'GP1', name)
            end
            if string.find(line,tString) then
                string = tString
                return string
            end
        end
        return string
end

---@param line string @ the string we are parsing
---@return boolean @ Was the originator an NPC?
---@return string @ the NPC name if found
local function CheckNPC(line)
    local name = ''
    if string.find(line, "tells you,") then 
        name = string.sub(line,1,string.find(line, "tells you") -2)
    elseif string.find(line, "says") then
        name = string.sub(line,1,string.find(line, "says") -2)
    elseif string.find(line, "whispers,") then
        name = string.sub(line,1,string.find(line, "whispers") -2) 
    elseif string.find(line, "shouts,") then
        name = string.sub(line,1,string.find(line, "shouts") -2)
    elseif string.find(line, "slashes") then
        name = string.sub(line,1,string.find(line, "slashes") -1) 
    elseif string.find(line, "pierces") then
        name = string.sub(line,1,string.find(line, "pierces") -1)
    elseif string.find(line, "kicks") then
        name = string.sub(line,1,string.find(line, "kicks") -1) 
    elseif string.find(line, "crushes") then
        name = string.sub(line,1,string.find(line, "crushes") -1)
    elseif string.find(line, "bashes") then
        name = string.sub(line,1,string.find(line, "bashes") -1) 
    elseif string.find(line, "hits") then
        name = string.sub(line,1,string.find(line, "hits") -1)
    elseif string.find(line, "tries") then
        name = string.sub(line,1,string.find(line, "tries") -1) 
    elseif string.find(line, "backstabs") then
        name = string.sub(line,1,string.find(line, "backstabs") -1)
    elseif string.find(line, "bites") then
        name = string.sub(line,1,string.find(line, "bites") -1)
    else return false, name end
    -- print(check)
    name = name:gsub(" $", "")
    local check = string.format("npc =%s",name)
    if mq.TLO.SpawnCount(check)() ~= nil then
        -- printf("Count: %s Check: %s",mq.TLO.SpawnCount(check)(),check)
        if mq.TLO.SpawnCount(check)() ~= 0 then
            return true, name
        else return false, name end
    end
        return false, name
end

-- Function to append colored text segments
local function appendColoredTimestamp(console, timestamp, text, textColor)

    if timeStamps then
        -- Define TimeStamp colors
        local yellowColor = ImVec4(1, 1, 0, 1)
        local whiteColor = ImVec4(1, 1, 1, 1)
        console:AppendTextUnformatted(yellowColor, "[")
        console:AppendTextUnformatted(whiteColor, timestamp)
        console:AppendTextUnformatted(yellowColor, "] ")
    end
    console:AppendTextUnformatted(textColor, text)
    console:AppendText("") -- Move to the next line after the entry
end

--[[ Reads in the line, channelID and eventName of the triggered events. Parses the line against the Events and Filters for that channel.
    adjusts coloring for the line based on settings for the matching event / filter and writes to the corresponding console.
    if an event contains filters and the line doesn't match any of them we discard the line and return.
    If there are no filters we use the event default coloring and write to the consoles. ]]
---@param channelID integer @ The ID number of the Channel the triggered event belongs to
---@param eventName string @ the name of the event that was triggered
---@param line string @ the line of text that triggred the event
---@param spam boolean @ are we parsing this from the spam channel?
---@return boolean
function ChatWin.EventChat(channelID, eventName, line, spam)
    local conLine = line
    -- if spam then print('Called from Spam') end
    local eventDetails = eventNames[eventName]
    if not eventDetails then return false end

    if ChatWin.Consoles[channelID] then
        local txtBuffer = ChatWin.Consoles[channelID].txtBuffer -- Text buffer for the channel ID we are working with.
        local colorVec = eventDetails.Filters[0].color or {1,1,1,1} -- Color Code to change line to, default is white
        local fMatch = false
        local conColorStr = 'white'
        local gSize = mq.TLO.Me.GroupSize() -- size of the group including yourself
        gSize = gSize -1
        if txtBuffer then
            local haveFilters = false
            for fID, fData in pairs(eventDetails.Filters) do
                if fID > 0 and not fMatch then
                    haveFilters = true
                    local fString = fData.filterString -- String value we are filtering for
                    if string.find(fString, 'M3') then
                        fString = string.gsub(fString,'M3', myName)
                    elseif string.find(fString, 'PT1') then
                        fString = string.gsub(fString,'PT1', mq.TLO.Me.Pet.DisplayName() or 'NO PET')
                    elseif string.find(fString, 'PT3') then
                        local npc, npcName = CheckNPC(line)
                        local tagged = false
                        -- print(npcName)
                            if gSize > 0 then
                                for g =1 , gSize do
                                    if mq.TLO.Spawn(string.format("%s",npcName)).Master() == mq.TLO.Group.Member(g).Name() then
                                        fString = string.gsub(fString,'PT3', npcName)
                                        -- print(npcName)
                                        tagged = true
                                    end
                                end
                            end
                            if not tagged then
                                fString = string.gsub(fString,'PT3', mq.TLO.Me.Pet.DisplayName() or 'NO PET')
                                tagged = true
                            end
                    elseif string.find(fString, 'M1') then
                        fString = string.gsub(fString,'M1', mq.TLO.Group.MainAssist.Name() or 'NO MA')
                    elseif string.find(fString, 'TK1') then
                        fString = string.gsub(fString,'TK1', mq.TLO.Group.MainTank.Name() or 'NO TANK')
                    elseif string.find(fString, 'P3') then
                        local npc, pcName = CheckNPC(line)
                        if not npc and not (mq.TLO.Me.Pet.DisplayName() or 'NO PET') then
                            fString = string.gsub(fString,'P3', pcName or 'None')
                        end
                    elseif string.find(fString, 'N3') then
                        local npc, npcName = CheckNPC(line)
                        -- print(npcName)
                        if npc then
                            fString = string.gsub(fString,'N3', npcName or 'None')
                        end
                    elseif string.find(fString, 'RL') then
                        fString = string.gsub(fString,'RL', mq.TLO.Raid.Leader.Name() or 'NO RAID')
                    elseif string.find(fString, 'G1') then
                        fString = string.gsub(fString,'G1', mq.TLO.Group.Member(1).Name() or 'NO GROUP')
                    elseif string.find(fString, 'G2') then
                        fString = string.gsub(fString,'G2', mq.TLO.Group.Member(2).Name() or 'NO GROUP')
                    elseif string.find(fString, 'G3') then
                        fString = string.gsub(fString,'G3', mq.TLO.Group.Member(3).Name() or 'NO GROUP')
                    elseif string.find(fString, 'G4') then
                        fString = string.gsub(fString,'G4', mq.TLO.Group.Member(4).Name() or 'NO GROUP')
                    elseif string.find(fString, 'G5') then
                        fString = string.gsub(fString,'G5', mq.TLO.Group.Member(5).Name() or 'NO GROUP')
                    elseif string.find(fString, 'RL') then
                        fString = string.gsub(fString,'RL', mq.TLO.Raid.Leader.Name() or 'NO RAID')
                    elseif string.find(fString, 'H1') then
                        fString = CheckGroup(fString, line, 'healer')
                    elseif string.find(fString, 'GP1') then
                        fString = CheckGroup(fString, line, 'group')
                    end
                    
                    if string.find(line, fString) then
                        colorVec = fData.color
                        fMatch = true
                    end
                    if fMatch then break end
                end
                if fMatch then break end
                -- end
            end
            --print(tostring(#eventDetails.Filters))
            if not fMatch and haveFilters then return fMatch end -- we had filters and didn't match so leave
            if not spam then
                
                -- printf("Spam Value %s",tostring(spam))
                

                if string.lower(ChatWin.Settings.Channels[channelID].Name) == 'consider' then
                    local conTarg = mq.TLO.Target
                    if conTarg ~= nil then
                        conColorStr = string.lower(conTarg.ConColor() or 'white')
                        colorVec = GetColorVal(conColorStr)
                    end
                end
                -----------------------------------------
                if ChatWin.Settings.Channels[channelID].enableLinks and links ~= nil then
                    if links.ready then conLine = links.collectItemLinks(line) end
                end
                local tStamp = mq.TLO.Time.Time24() -- Get the current timestamp
                local colorCode = ImVec4(colorVec[1], colorVec[2], colorVec[3], colorVec[4])

                if ChatWin.Consoles[channelID].console then
                    appendColoredTimestamp(ChatWin.Consoles[channelID].console, tStamp, conLine, colorCode)
                end
                
                -- -- write channel console
                if timeStamps then
                    tStamp = mq.TLO.Time.Time24()
                    line = string.format("[%s] %s",tStamp,line) -- fake zome use drawn text
                end
                local i = getNextID(txtBuffer)
                -- write main console
                if tempSettings.Channels[channelID].MainEnable then
                    appendColoredTimestamp(ChatWin.console, tStamp, conLine, colorCode)
                    -- ChatWin.console:AppendText(colorCode,conLine)
                    local z = getNextID(mainBuffer)
                    
                    if z > 1 then
                        if mainBuffer[z-1].text == '' then z = z-1 end
                    end
                    mainBuffer[z] = {
                        color = colorVec,
                        text = line
                    }
                    local bufferLength = #mainBuffer
                    if bufferLength > zBuffer then
                        -- Remove excess lines
                        for j = 1, bufferLength - zBuffer do
                            table.remove(mainBuffer, 1)
                        end
                    end
                end

                -- ZOOM Console hack
                if i > 1 then
                    if txtBuffer[i-1].text == '' then i = i-1 end
                end

                -- Add the new line to the buffer
                txtBuffer[i] = {
                    color = colorVec,
                    text = line
                }
                -- cleanup zoom buffer
                -- Check if the buffer exceeds 1000 lines
                local bufferLength = #txtBuffer
                if bufferLength > zBuffer then
                    -- Remove excess lines
                    for j = 1, bufferLength - zBuffer do
                        table.remove(txtBuffer, 1)
                    end
                end
            end
            return fMatch

        else

            print("Error: txtBuffer is nil for channelID " .. channelID)
            return fMatch

        end
        else
        print("Error: ChatWin.Consoles[channelID] is nil for channelID " .. channelID)
        return false
    end
end

---Reads in the line and channelID of the triggered events. Parses the line against the Events and Filters for that channel.
---@param channelID integer @ The ID number of the Channel the triggered event belongs to
function ChatWin.EventChatSpam(channelID,line)
    local eventDetails = eventNames
    local conLine = line
    if not eventDetails then return end
    if ChatWin.Consoles[channelID] then
        local txtBuffer = ChatWin.Consoles[channelID].txtBuffer -- Text buffer for the channel ID we are working with.
        local colorVec = {1,1,1,1} -- Color Code to change line to, default is white
        local fMatch = false
        local gSize = mq.TLO.Me.GroupSize() -- size of the group including yourself
        gSize = gSize -1
        if txtBuffer then
            for cID, cData in pairs(ChatWin.Settings.Channels) do
                if cID ~= channelID then
                    for eID, eData in pairs(cData.Events) do
                        local tmpEname = string.format("event_%d_%d", cID, eID)
                        for name, data in pairs(eventNames) do
                            if name ~= 'event_9000_1' and name == tmpEname then
                                local eventPattern = convertEventString(data.eventString)
                                if string.match(line, eventPattern) then
                                    fMatch = ChatWin.EventChat(cID, name, line, true)
                                    -- print(tostring(fMatch))
                                end
                                -- we found a match lets exit this loop.
                                if fMatch == true then break end
                            end
                        end
                        if fMatch == true then break end
                    end
                end
                if fMatch == true then break end
            end

            if fMatch then return end -- we have an event for this already
            local tStamp = mq.TLO.Time.Time24()
            local i = getNextID(txtBuffer)

            local colorCode = ImVec4(colorVec[1], colorVec[2], colorVec[3], colorVec[4])
            if ChatWin.Settings.Channels[channelID].enableLinks and links ~= nil then
                if links.ready then conLine = links.collectItemLinks(line) end
            end
            if timeStamps then
                line = string.format("%s %s",tStamp,line)
            end
            -- write channel console
            if ChatWin.Consoles[channelID].console then
                appendColoredTimestamp(ChatWin.Consoles[channelID].console, tStamp, conLine, colorCode)

                -- ChatWin.Consoles[channelID].console:AppendText(colorCode, conLine)
            end

            -- ZOOM Console hack
            if i > 1 then
                if txtBuffer[i-1].text == '' then i = i-1 end
            end
            -- Add the new line to the buffer
            txtBuffer[i] = {
                color = colorVec,
                text = line
            }
            -- cleanup zoom buffer
            -- Check if the buffer exceeds 1000 lines
            local bufferLength = #txtBuffer
            if bufferLength > zBuffer then
                -- Remove excess lines
                for j = 1, bufferLength - zBuffer do
                    table.remove(txtBuffer, 1)
                end
            end

            else
            print("Error: txtBuffer is nil for channelID " .. channelID)
        end

        else
        print("Error: ChatWin.Consoles[channelID] is nil for channelID " .. channelID)
    end
end
------------------------------------------ GUI's --------------------------------------------

---comment
---@param tName string -- name of the theme to load form table
---@return integer, integer -- returns the new counter values 
local function DrawTheme(tName)
    local StyleCounter = 0
    local ColorCounter = 0
    for tID, tData in pairs(theme.Theme) do
        if tData.Name == tName then
            for pID, cData in pairs(theme.Theme[tID].Color) do
                ImGui.PushStyleColor(pID, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], cData.Color[4]))
                ColorCounter = ColorCounter + 1
            end
            if tData['Style'] ~= nil then
                if next(tData['Style']) ~= nil then
                    
                    for sID, sData in pairs (theme.Theme[tID].Style) do
                        if sData.Size ~= nil then
                            ImGui.PushStyleVar(sID, sData.Size)
                            StyleCounter = StyleCounter + 1
                            elseif sData.X ~= nil then
                            ImGui.PushStyleVar(sID, sData.X, sData.Y)
                            StyleCounter = StyleCounter + 1
                        end
                    end
                end
            end
        end
    end
    return ColorCounter, StyleCounter
end

local function DrawConsole(channelID)
    local name = ChatWin.Settings.Channels[channelID].Name..'##'..channelID
    local zoom = ChatWin.Consoles[channelID].zoom
    local scale = ChatWin.Settings.Channels[channelID].Scale
    local PopOut = ChatWin.Settings.Channels[channelID].PopOut
    if zoom and ChatWin.Consoles[channelID].txtBuffer ~= '' then
        local footerHeight = 30
        local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
        contentSizeY = contentSizeY - footerHeight
        
        ImGui.BeginChild("ZoomScrollRegion##"..channelID, contentSizeX, contentSizeY, ImGuiWindowFlags.HorizontalScrollbar)
        ImGui.BeginTable('##channelID_'..channelID, 1, bit32.bor(ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.RowBg))
        ImGui.TableSetupColumn("##txt"..channelID, ImGuiTableColumnFlags.NoHeaderLabel)
        --- draw rows ---
        
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        ImGui.SetWindowFontScale(scale)
        
        for line, data in pairs(ChatWin.Consoles[channelID].txtBuffer) do
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(data.color[1], data.color[2], data.color[3], data.color[4]))
            if ImGui.Selectable("##selectable" .. line, false, ImGuiSelectableFlags.None) then end
            ImGui.SameLine()
            ImGui.TextWrapped(data.text)
            if ImGui.IsItemHovered() and ImGui.IsKeyDown(ImGuiMod.Ctrl) and ImGui.IsKeyDown(ImGuiKey.C) then
                ImGui.LogToClipboard()
                ImGui.LogText(data.text)
                ImGui.LogFinish()
            end
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            ImGui.PopStyleColor()
        end
        
        ImGui.SetWindowFontScale(1)
        
        --Scroll to the bottom if autoScroll is enabled
        local autoScroll = ChatWin.Consoles[channelID].txtAutoScroll
        if autoScroll then
            ImGui.SetScrollHereY()
            ChatWin.Consoles[channelID].bottomPosition = ImGui.GetCursorPosY()
        end
        
        local bottomPosition = ChatWin.Consoles[channelID].bottomPosition or 0
        -- Detect manual scroll
        local lastScrollPos = ChatWin.Consoles[channelID].lastScrollPos or 0
        local scrollPos = ImGui.GetScrollY()
        
        if scrollPos < lastScrollPos then
            ChatWin.Consoles[channelID].txtAutoScroll = false  -- Turn off autoscroll if scrolled up manually
            elseif scrollPos >= bottomPosition-(30 * scale) then
            ChatWin.Consoles[channelID].txtAutoScroll = true
        end
        
        lastScrollPos = scrollPos
        ChatWin.Consoles[channelID].lastScrollPos = lastScrollPos
        
        ImGui.EndTable()
        
        ImGui.EndChild()
        
        else
        local footerHeight = 30
        local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
        contentSizeY = contentSizeY - footerHeight
        ChatWin.Consoles[channelID].console:Render(ImVec2(contentSizeX,contentSizeY))
    end
    --Command Line
    ImGui.Separator()
    local textFlags = bit32.bor(0,
        ImGuiInputTextFlags.EnterReturnsTrue
        -- not implemented yet
        -- ImGuiInputTextFlags.CallbackCompletion,
        -- ImGuiInputTextFlags.CallbackHistory
    )
    local contentSizeX, _ = ImGui.GetContentRegionAvail()
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 2)
    ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 2)
    ImGui.PushItemWidth(contentSizeX)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, ImVec4(0, 0, 0, 0))
    ImGui.PushFont(ImGui.ConsoleFont)
    local accept = false
    local cmdBuffer = ChatWin.Settings.Channels[channelID].commandBuffer
    cmdBuffer, accept = ImGui.InputText('##Input##'..name, cmdBuffer, textFlags)
    ImGui.PopFont()
    ImGui.PopStyleColor()
    ImGui.PopItemWidth()
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(ChatWin.Settings.Channels[channelID].Echo)
        if PopOut then
            ImGui.Text(ChatWin.Settings.Channels[channelID].Name)
            local sizeBuff = string.format("Buffer Size: %s lines.",tostring(getNextID(ChatWin.Consoles[channelID].txtBuffer)-1))
            ImGui.Text(sizeBuff)
        end
        ImGui.EndTooltip()
    end
    if accept then
        ChatWin.ChannelExecCommand(cmdBuffer, channelID)
        cmdBuffer = ''
        ChatWin.Settings.Channels[channelID].commandBuffer = cmdBuffer
        setFocus = true
    end
    ImGui.SetItemDefaultFocus()
    if setFocus then
        setFocus = false
        ImGui.SetKeyboardFocusHere(-1)
    end
end

local function DrawChatWindow()
    -- Main menu bar
    if ImGui.BeginMenuBar() then
        if ChatWin.Settings.Scale > 1.5 then ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 4,7) end
        local lockedIcon = ChatWin.Settings.locked and Icons.FA_LOCK .. '##lockTabButton_MyChat' or
        Icons.FA_UNLOCK .. '##lockTablButton_MyChat'
        if ImGui.Button(lockedIcon) then
            --ImGuiWindowFlags.NoMove
            ChatWin.Settings.locked = not ChatWin.Settings.locked
            tempSettings.locked = ChatWin.Settings.locked
            ResetEvents()
        end
        if ImGui.IsItemHovered() then
            ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
            ImGui.BeginTooltip()
            ImGui.Text("Lock Window")
            ImGui.EndTooltip()
            ImGui.SetWindowFontScale(1)
        end
        if ImGui.MenuItem(gIcon..'##'..windowNum) then
            ChatWin.openConfigGUI = not ChatWin.openConfigGUI
        end
        if ImGui.IsItemHovered() then
            ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
            ImGui.BeginTooltip()
            ImGui.Text("Open Main Config")
            ImGui.EndTooltip()
            ImGui.SetWindowFontScale(1)
        end
        if ImGui.BeginMenu('Options##'..windowNum) then
            local spamOn, linksOn
            ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
            _,  ChatWin.console.autoScroll = ImGui.MenuItem('Auto-scroll##'..windowNum, nil,  ChatWin.console.autoScroll)
            _, LocalEcho = ImGui.MenuItem('Local echo##'..windowNum, nil, LocalEcho)
            _, timeStamps = ImGui.MenuItem('Time Stamps##'..windowNum, nil, timeStamps)
            spamOn, enableSpam = ImGui.MenuItem('Enable Spam##'..windowNum, nil, enableSpam)
            if ImGui.MenuItem('Re-Index Settings##'..windowNum) then
                forceIndex = true
                ResetEvents()
            end
            if ImGui.IsItemHovered() then
                ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
                ImGui.BeginTooltip()
                ImGui.PushStyleColor(ImGuiCol.Text,ImVec4(1,0,0,1))
                ImGui.Text("!!! WARNING !!!")
                ImGui.Text("This will re-Index the ID's in your settings file!!")
                ImGui.Text("Doing this outside of the initial loading of MyChat may CLEAR your chat windows!!")
                ImGui.Text("!!! YOU HAVE BEEN WARNED !!!")
                ImGui.PopStyleColor()
                ImGui.EndTooltip()
                ImGui.SetWindowFontScale(1)
            end
            ImGui.Separator()
            
            local menName = doRefresh and "Disable Refresh" or "Enable Refresh"
            if ImGui.MenuItem(menName..'##Options_Refresh_Links'..windowNum) then
                doRefresh = not doRefresh
            end

            if ImGui.MenuItem('Refresh LinksDB##Options_Links'..windowNum) then
                ReLoadDB()
            end

            ImGui.Separator()
            if ImGui.MenuItem('Reset Position##'..windowNum) then
                resetPosition = true
            end
            if ImGui.MenuItem('Clear Main Console##'..windowNum) then
                ChatWin.console:Clear()
            end
            if ImGui.MenuItem('Exit##'..windowNum) then
                -- ChatWin.SHOW = false
                -- ChatWin.openGUI = false
                running = false
            end
            if spamOn then
                if not enableSpam then
                    ChatWin.Consoles[9000].console = nil
                end
                ResetEvents()
            end
            ImGui.Spacing()
            ImGui.SetWindowFontScale(1)
            ImGui.EndMenu()
        end
        if ImGui.BeginMenu('Channels##'..windowNum) then
            ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
            for channelID, settings in pairs(ChatWin.Settings.Channels) do
                local enabled = ChatWin.Settings.Channels[channelID].enabled
                local name = ChatWin.Settings.Channels[channelID].Name
                if channelID ~= 9000 or enableSpam then 
                    if ImGui.MenuItem(name, '', enabled) then
                        ChatWin.Settings.Channels[channelID].enabled = not enabled
                        writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
                    end
                end
            end
            ImGui.EndMenu()
            ImGui.SetWindowFontScale(1)
        end
        if ImGui.BeginMenu('Zoom##'..windowNum) then
            ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
            if ImGui.MenuItem('Main##MyChat', '', zoomMain) then
                zoomMain = not zoomMain
            end
            for channelID, settings in pairs(ChatWin.Settings.Channels) do
                if channelID ~= 9000 or enableSpam then 
                    local zoom = ChatWin.Consoles[channelID].zoom
                    local name = ChatWin.Settings.Channels[channelID].Name
                    if ImGui.MenuItem(name, '', zoom) then
                        ChatWin.Consoles[channelID].zoom = not zoom
                    end
                end
            end
            ImGui.SetWindowFontScale(1)
            ImGui.EndMenu()
        end
        if ImGui.BeginMenu('Links##'..windowNum) then
            ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
            for channelID, _ in pairs(ChatWin.Settings.Channels) do
                local enableLinks = ChatWin.Settings.Channels[channelID].enableLinks
                local name = ChatWin.Settings.Channels[channelID].Name
                if channelID ~= 9000 then 
                    if ImGui.MenuItem(name, '', enableLinks) then
                        ChatWin.Settings.Channels[channelID].enableLinks = not enableLinks
                        writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
                    end
                end
            end
            ImGui.Separator()
            if ImGui.MenuItem('RefreshDB##Links'..windowNum) then
                ReLoadDB()
            end
            ImGui.EndMenu()
            ImGui.SetWindowFontScale(1)
        end
        if ImGui.BeginMenu('PopOut##'..windowNum) then
            ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
            for channelID, settings in pairs(ChatWin.Settings.Channels) do
                if channelID ~= 9000 or enableSpam then 
                    local PopOut = ChatWin.Settings.Channels[channelID].PopOut
                    local name = ChatWin.Settings.Channels[channelID].Name
                    if ImGui.MenuItem(name, '', PopOut) then
                        PopOut = not PopOut
                        ChatWin.Settings.Channels[channelID].PopOut = PopOut
                        tempSettings.Channels[channelID].PopOut = PopOut
                        writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
                    end
                end
            end
            ImGui.SetWindowFontScale(1)
            ImGui.EndMenu()
        end
        -- ImGui.SetCursorPosX(ImGui.GetWindowContentRegionWidth() - 10)
        -- if ImGui.MenuItem('X##Close'..windowNum) then
        --     running = false
        -- end
        ImGui.EndMenuBar()
    end
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 4,3)
    ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
    -- End of menu bar
    -- Begin Tabs Bars
    if ImGui.BeginTabBar('Channels##'..windowNum, ChatWin.tabFlags) then
        -- Begin Main tab
        if ImGui.BeginTabItem('Main##'..windowNum) then
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text('Main')
                local sizeBuff = string.format("Buffer Size: %s lines.",tostring(getNextID(mainBuffer)-1))
                ImGui.Text(sizeBuff)
                ImGui.EndTooltip()
            end
            ActTab = 'Main'
            activeID = 0
            local footerHeight = 30
            local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
            contentSizeY = contentSizeY - footerHeight
            if ImGui.BeginPopupContextWindow() then
                ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
                if ImGui.Selectable('Clear##'..windowNum) then
                    ChatWin.console:Clear()
                    mainBuffer = {}
                end
                ImGui.Separator()
                if ImGui.Selectable('Zoom##Main'..windowNum) then
                    zoomMain = not zoomMain
                    
                end
                ImGui.SetWindowFontScale(1)
                ImGui.EndPopup()
            end
            if not zoomMain then
                ChatWin.console:Render(ImVec2(contentSizeX,contentSizeY))
                --Command Line
                ImGui.Separator()
                local textFlags = bit32.bor(0,
                    ImGuiInputTextFlags.EnterReturnsTrue
                    -- not implemented yet
                    -- ImGuiInputTextFlags.CallbackCompletion,
                    -- ImGuiInputTextFlags.CallbackHistory
                )
                else
                local footerHeight = 30
                local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
                contentSizeY = contentSizeY - footerHeight
                
                ImGui.BeginChild("ZoomScrollRegion##"..windowNum,contentSizeX, contentSizeY, ImGuiWindowFlags.HorizontalScrollbar)
                ImGui.BeginTable('##channelID_'..windowNum, 1, bit32.bor(ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.RowBg))
                ImGui.TableSetupColumn("##txt"..windowNum, ImGuiTableColumnFlags.NoHeaderLabel)
                --- draw rows ---
                
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
                
                for line, data in pairs(mainBuffer) do
                    ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(data.color[1], data.color[2], data.color[3], data.color[4]))
                    if ImGui.Selectable("##selectable" .. line, false, ImGuiSelectableFlags.None) then end
                    ImGui.SameLine()
                    ImGui.TextWrapped(data.text)
                    if ImGui.IsItemHovered() and ImGui.IsKeyDown(ImGuiMod.Ctrl) and ImGui.IsKeyDown(ImGuiKey.C) then
                        ImGui.LogToClipboard()
                        ImGui.LogText(data.text)
                        ImGui.LogFinish()
                    end
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0)
                    ImGui.PopStyleColor()
                end
                
                ImGui.SetWindowFontScale(1)
                
                --Scroll to the bottom if autoScroll is enabled
                local autoScroll = AutoScroll
                if autoScroll then
                    ImGui.SetScrollHereY()
                    mainBottomPosition = ImGui.GetCursorPosY()
                end
                
                local bottomPosition = mainBottomPosition or 0
                -- Detect manual scroll
                local lastScrollPos = mainLastScrollPos or 0
                local scrollPos = ImGui.GetScrollY()
                
                if scrollPos < lastScrollPos then
                    AutoScroll = false  -- Turn off autoscroll if scrolled up manually
                    elseif scrollPos >= bottomPosition - (30 * ChatWin.Settings.Scale) then
                    AutoScroll = true
                end
                
                lastScrollPos = scrollPos
                mainLastScrollPos = lastScrollPos
                
                ImGui.EndTable()
                
                ImGui.EndChild()
            end
            local textFlags = bit32.bor(0,
                ImGuiInputTextFlags.EnterReturnsTrue
                -- not implemented yet
                -- ImGuiInputTextFlags.CallbackCompletion,
                -- ImGuiInputTextFlags.CallbackHistory
            )
            local contentSizeX, _ = ImGui.GetContentRegionAvail()
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 2)
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 2)
            ImGui.PushItemWidth(contentSizeX)
            ImGui.PushStyleColor(ImGuiCol.FrameBg, ImVec4(0, 0, 0, 0))
            ImGui.PushFont(ImGui.ConsoleFont)
            local accept = false
            ChatWin.commandBuffer, accept = ImGui.InputText('##Input##'..windowNum, ChatWin.commandBuffer, textFlags)
            ImGui.PopFont()
            ImGui.PopStyleColor()
            ImGui.PopItemWidth()
            if accept then
                ChatWin.ExecCommand(ChatWin.commandBuffer)
                ChatWin.commandBuffer = ''
                setFocus = true
            end
            ImGui.SetItemDefaultFocus()
            if setFocus then
                setFocus = false
                ImGui.SetKeyboardFocusHere(-1)
            end
            ImGui.EndTabItem()
        end
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text('Main')
            local sizeBuff = string.format("Buffer Size: %s lines.",tostring(getNextID(mainBuffer)-1))
            ImGui.Text(sizeBuff)
            ImGui.EndTooltip()
        end
        -- End Main tab
        -- Begin other tabs
        -- for tabNum = 1 , #ChatWin.Settings.Channels do
            for channelID, data in pairs(ChatWin.Settings.Channels) do
                -- if ChatWin.Settings.Channels[channelID].TabOrder == tabNum then
                    if ChatWin.Settings.Channels[channelID].enabled then
                        local name = ChatWin.Settings.Channels[channelID].Name..'##'..windowNum
                        local zoom = ChatWin.Consoles[channelID].zoom
                        local scale = ChatWin.Settings.Channels[channelID].Scale
                        local links =  ChatWin.Settings.Channels[channelID].enableLinks
                        local enableMain = ChatWin.Settings.Channels[channelID].MainEnable
                        local PopOut = ChatWin.Settings.Channels[channelID].PopOut
                        local tNameZ = zoom and 'Disable Zoom' or 'Enable Zoom'
                        local tNameP = PopOut and 'Disable PopOut' or 'Enable PopOut'
                        local tNameM = enableMain and 'Disable Main' or 'Enable Main'
                        local tNameL = links and 'Disable Links' or 'Enable Links'
                        local function tabToolTip()
                            ImGui.BeginTooltip()
                            ImGui.Text(ChatWin.Settings.Channels[channelID].Name)
                            local sizeBuff = string.format("Buffer Size: %s lines.",tostring(getNextID(ChatWin.Consoles[channelID].txtBuffer)-1))
                            ImGui.Text(sizeBuff)
                            ImGui.EndTooltip()
                        end

                        if not PopOut then
                            if ImGui.BeginTabItem(name) then
                                ActTab = name
                                activeID = channelID
                                if ImGui.IsItemHovered() then
                                    tabToolTip()
                                end
                                if ImGui.BeginPopupContextWindow() then
                                    ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
                                    if ImGui.Selectable('Configure##'..windowNum) then
                                        editChanID =  channelID
                                        addChannel = false
                                        fromConf = false
                                        tempSettings = ChatWin.Settings
                                        ChatWin.openEditGUI = true
                                        ChatWin.openConfigGUI = false
                                    end

                                    ImGui.Separator()
                                    if ImGui.Selectable(tNameZ..'##'..windowNum) then
                                        zoom = not zoom
                                        ChatWin.Consoles[channelID].zoom = zoom
                                    end
                                if ImGui.Selectable(tNameP..'##'..windowNum) then
                                        PopOut = not PopOut
                                        ChatWin.Settings.Channels[channelID].PopOut = PopOut
                                        tempSettings.Channels[channelID].PopOut = PopOut
                                        writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
                                    end

                                    if ImGui.Selectable( tNameM..'##'..windowNum) then
                                        enableMain = not enableMain
                                        ChatWin.Settings.Channels[channelID].MainEnable = enableMain
                                        tempSettings.Channels[channelID].MainEnable = enableMain
                                        writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
                                    end
                                    -- tempSettings.Channels[editChanID].MainEnable
                                    if channelID < 9000 then
                                        if ImGui.Selectable(tNameL..'##'..windowNum) then
                                            links = not links
                                            ChatWin.Settings.Channels[channelID].enableLinks = links
                                            tempSettings.Channels[channelID].enableLinks = links
                                            -- ChatWin.Consoles[channelID].enableLinks = links
                                            writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
                                        end
                                    else
                                        if ImGui.Selectable('Spam Off##'..windowNum) then
                                            enableSpam = false
                                            ChatWin.Consoles[9000].console = nil
                                            ResetEvents()
                                        end
                                    end
                                    ImGui.Separator()
                                    if ImGui.Selectable('Clear##'..windowNum) then
                                        ChatWin.Consoles[channelID].console:Clear()
                                        ChatWin.Consoles[channelID].txtBuffer = {}
                                    end
                                    ImGui.SetWindowFontScale(1)
                                    ImGui.EndPopup()
                                end
                                
                                DrawConsole(channelID)
                                
                                ImGui.EndTabItem()
                            end
                            if ImGui.IsItemHovered() then
                                tabToolTip()
                            end
                        end
                    end
                -- end
            end
        -- end
        -- End other tabs
        ImGui.EndTabBar()
    end
    -- End Tab Bar
    
end

function ChatWin.GUI()
    if not running then return end

    local windowName = 'My Chat - Main##'..myName..'_'..windowNum
    ImGui.SetWindowPos(windowName,ImVec2(20, 20), ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowSize(ImVec2(640, 480), ImGuiCond.FirstUseEver)
    if useTheme then
        local themeName = tempSettings.LoadTheme
        ColorCount, StyleCount = DrawTheme(themeName)
    end
    local winFlags = ChatWin.winFlags
    if ChatWin.Settings.locked then
        winFlags = bit32.bor(ImGuiWindowFlags.MenuBar,ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoScrollbar)
    end
    
    openMain,ChatWin.SHOW  = ImGui.Begin(windowName, openMain, winFlags)
    
    if not ChatWin.SHOW then
        if StyleCount > 0 then ImGui.PopStyleVar(StyleCount) end
        if ColorCount > 0 then ImGui.PopStyleColor(ColorCount) end
        ImGui.End()
    else

        DrawChatWindow()

        if StyleCount > 0 then ImGui.PopStyleVar(StyleCount) end
        if ColorCount > 0 then ImGui.PopStyleColor(ColorCount) end
        ImGui.End()
    end
    for channelID, data in pairs(ChatWin.Settings.Channels) do
        if ChatWin.Settings.Channels[channelID].enabled then
            local name = ChatWin.Settings.Channels[channelID].Name..'##'..windowNum
            local PopOut = ChatWin.Settings.Channels[channelID].PopOut
            local ShowPop = ChatWin.Settings.Channels[channelID].PopOut
            if ChatWin.Settings.Channels[channelID].locked then
                ChatWin.PopOutFlags = bit32.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoMove)
                else
                ChatWin.PopOutFlags = bit32.bor(ImGuiWindowFlags.NoScrollbar)
            end
            if PopOut then

                ImGui.SetNextWindowSize(ImVec2(640, 480), ImGuiCond.FirstUseEver)

                local themeName = tempSettings.LoadTheme
                local PopoutColorCount,PopoutStyleCount = DrawTheme(themeName)
                local show
                PopOut, show = ImGui.Begin(name.."##"..channelID..name, PopOut, ChatWin.PopOutFlags)
                if show then

                    local lockedIcon = ChatWin.Settings.Channels[channelID].locked and Icons.FA_LOCK .. '##lockTabButton'..channelID or
                    Icons.FA_UNLOCK .. '##lockTablButton'..channelID
                    if ImGui.Button(lockedIcon) then
                        --ImGuiWindowFlags.NoMove
                        ChatWin.Settings.Channels[channelID].locked = not ChatWin.Settings.Channels[channelID].locked
                        tempSettings.Channels[channelID].locked = ChatWin.Settings.Channels[channelID].locked
                        ResetEvents()
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
                        ImGui.BeginTooltip()
                        ImGui.Text("Lock Window")
                        ImGui.EndTooltip()
                        ImGui.SetWindowFontScale(1)
                    end
                    if PopOut ~= ChatWin.Settings.Channels[channelID].PopOut then
                        ChatWin.Settings.Channels[channelID].PopOut = PopOut
                        tempSettings.Channels[channelID].PopOut = PopOut
                        ResetEvents()
                    end
                    ImGui.SameLine()
                    if ImGui.Button(Icons.MD_SETTINGS.."##"..channelID) then
                        editChanID =  channelID
                        addChannel = false
                        fromConf = false
                        tempSettings = ChatWin.Settings
                        ChatWin.openEditGUI = not ChatWin.openEditGUI
                        ChatWin.openConfigGUI = false
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
                        ImGui.BeginTooltip()
                        ImGui.Text("Opens the Edit window for this channel")
                        ImGui.EndTooltip()
                        ImGui.SetWindowFontScale(1)
                    end

                    DrawConsole(channelID)

                else
                    if not ShowPop then
                        ChatWin.Settings.Channels[channelID].PopOut = ShowPop
                        tempSettings.Channels[channelID].PopOut = ShowPop
                        ResetEvents()
                        if PopoutStyleCount > 0  then ImGui.PopStyleVar(PopoutStyleCount) end
                        if PopoutColorCount > 0  then ImGui.PopStyleColor(PopoutColorCount) end
                        ImGui.End()
                    end
                end

                if PopoutStyleCount > 0  then ImGui.PopStyleVar(PopoutStyleCount) end
                if PopoutColorCount > 0  then ImGui.PopStyleColor(PopoutColorCount) end
                ImGui.End()
            end
        end
    end
    if ChatWin.openEditGUI then ChatWin.Edit_GUI() end
    if ChatWin.openConfigGUI then ChatWin.Config_GUI() end

    if not openMain then running = false end
    
end

-------------------------------- Configure Windows and Events GUI ---------------------------

---Draws the Channel data for editing. Can be either an exisiting Channel or a New one.
---@param editChanID integer -- the channelID we are working with
---@param isNewChannel boolean -- is this a new channel or are we editing an old one.
function ChatWin.AddChannel(editChanID, isNewChannel)
    local tmpName = 'NewChan'
    local tmpString = 'NewString'
    local tmpEcho = '/say'
    local tmpFilter = 'NewFilter'
    local channelData = {}
    
    if not tempEventStrings[editChanID] then tempEventStrings[editChanID] = {} end
    if not tempChanColors then tempChanColors = {} end
    if not tempFiltColors[editChanID] then tempFiltColors[editChanID] = {} end
    if not tempChanColors[editChanID] then tempChanColors[editChanID] = {} end
    if not tempFilterStrings[editChanID] then tempFilterStrings[editChanID] = {} end
    if not tempEventStrings[editChanID] then channelData[editChanID] = {} end
    if not tempEventStrings[editChanID][editEventID] then tempEventStrings[editChanID][editEventID] = {} end
    
    if not isNewChannel then
        for eID, eData in pairs(tempSettings.Channels[editChanID].Events)do
            if not tempFiltColors[editChanID][eID] then tempFiltColors[editChanID][eID] = {} end
            for fID, fData in pairs(eData.Filters) do
                if not tempFiltColors[editChanID][eID][fID] then tempFiltColors[editChanID][eID][fID] = {} end
                -- if not tempFiltColors[editChanID][eID][fID] then tempFiltColors[editChanID][eID][fID] = {} end
                tempFiltColors[editChanID][eID][fID] = fData.color or {1,1,1,1}
            end
        end
    end
    
    if tempSettings.Channels[editChanID] then
        channelData = tempSettings.Channels
        elseif
        isNewChannel then
        channelData = {
            [editChanID] = {
                ['enabled'] = false,
                ['Name'] = 'new',
                ['Scale'] = 1.0,
                ['Echo'] = '/say',
                ['MainEnable'] = true,
                ['Events'] = {
                    [1] = {
                        ['enabled'] = true,
                        ['eventString'] = 'new',
                        ['Filters'] = {
                            [0] = {
                                ['filter_enabled'] = true,
                                ['filterString'] = '',
                                ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                            },
                        },
                    },
                }
            }
        }
        tempSettings.Channels[editChanID] = channelData[editChanID]
    end
    
    if newEvent then
        local maxEventId = getNextID(channelData[editChanID].Events)
        -- print(maxEventId)
        channelData[editChanID]['Events'][maxEventId] = {
            ['enabled'] = true,
            ['eventString'] = 'new',
            ['Filters'] = {
                [0] = {
                    ['filterString'] = '',
                    ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                },
            },
        }
        newEvent = false
    end
    ---------------- Buttons Sliders and Channel Name ------------------------
    ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
    if lastChan == 0 then
        --print(channelData.Name)
        if not tempEventStrings[editChanID].Name then
            tempEventStrings[editChanID].Name = channelData[editChanID].Name
        end
        if not tempSettings.Channels[editChanID].Echo then
            tempSettings.Channels[editChanID].Echo = '/say'
        end
        tmpEcho = tempSettings.Channels[editChanID].Echo or '/say'
        tmpName = tempEventStrings[editChanID].Name
        tmpName,_ = ImGui.InputText("Channel Name##ChanName" .. editChanID, tmpName, 256)
        tmpEcho,_ = ImGui.InputText("Echo Channel##Echo_ChanName" .. editChanID, tmpEcho, 256)
        if tempSettings.Channels[editChanID].Echo ~= tmpEcho then
            tempSettings.Channels[editChanID].Echo = tmpEcho
        end
        if tempEventStrings[editChanID].Name ~= tmpName then
            tempEventStrings[editChanID].Name = tmpName
        end
        lastChan = lastChan + 1
        else
        ImGui.Text('')
    end
    -- Slider for adjusting zoom level
    if tempSettings.Channels[editChanID] then
        tempSettings.Channels[editChanID].Scale = ImGui.SliderFloat("Zoom Level", tempSettings.Channels[editChanID].Scale, 0.5, 2.0)
    end
    if ImGui.Button('Add New Event') then
        newEvent = true
    end
    ImGui.SameLine()
    if ImGui.Button('Save Settings') then
        tempSettings.Channels[editChanID] = tempSettings.Channels[editChanID] or {Events = {}, Name = "New Channel", enabled = true}
        tempSettings.Channels[editChanID].Name = tempEventStrings[editChanID].Name or "New Channel"
        tempSettings.Channels[editChanID].enabled = true
        tempSettings.Channels[editChanID].MainEnable = tempSettings.Channels[editChanID].MainEnable
        local channelEvents = tempSettings.Channels[editChanID].Events
        for eventId, eventData in pairs(tempEventStrings[editChanID]) do
            -- Skip 'Name' key used for the channel name
            if eventId ~= 'Name' then
                if eventData and eventData.eventString then
                    local tempEString = eventData.eventString or 'New'
                    if tempEString == '' then tempEString = 'New' end
                    channelEvents[eventId] = channelEvents[eventId] or {color = {1.0, 1.0, 1.0, 1.0}, Filters = {}}
                    channelEvents[eventId].eventString = tempEString --eventData.eventString
                    channelEvents[eventId].color = tempChanColors[editChanID][eventId] or channelEvents[eventId].color
                    channelEvents[eventId].Filters = {}
                    for filterID, filterData in pairs(tempFilterStrings[editChanID][eventId] or {}) do
                        local tempFString = filterData or 'New'
                        --print(filterData.." : "..tempFString)
                        if tempFString == '' or tempFString == nil then tempFString = 'New' end
                        channelEvents[eventId].Filters[filterID] = {
                            filterString = tempFString,
                            color = tempFiltColors[editChanID][eventId][filterID] or {1.0, 1.0, 1.0, 1.0} -- Default to white with full opacity if color not found
                        }
                    end
                end
            end
        end
        tempSettings.Channels[editChanID].Events = channelEvents
        ChatWin.Settings = tempSettings
        ResetEvents()
        ChatWin.openEditGUI = false
        tempFilterStrings, tempEventStrings, tempChanColors, tempFiltColors, hString, channelData = {}, {}, {}, {}, {}, {}
        if fromConf then ChatWin.openConfigGUI = true end
    end
    ImGui.SameLine()
    if ImGui.Button("DELETE Channel##" .. editChanID) then
        -- Delete the event
        tempSettings.Channels[editChanID] = nil
        tempEventStrings[editChanID] = nil
        tempChanColors[editChanID] = nil
        tempFiltColors[editChanID] = nil
        tempFilterStrings[editChanID] = nil
        ChatWin.openEditGUI = false
        ChatWin.openConfigGUI = false
        isNewChannel = true
        ResetEvents()
    end
    ImGui.SameLine()
    if ImGui.Button(' Close ##_close') then
        ChatWin.openEditGUI = false
        if fromConf then ChatWin.openConfigGUI = true end
    end
    ImGui.SameLine()
    if tempSettings.Channels[editChanID] then
        tempSettings.Channels[editChanID].MainEnable = ImGui.Checkbox('Show on Main Tab##Main', tempSettings.Channels[editChanID].MainEnable)
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text('Do you want this channel to display on the Main Tab?')
            ImGui.EndTooltip()
        end
    end
    
    ----------------------------- Events and Filters ----------------------------
    ImGui.SeparatorText('Events and Filters')
    ImGui.BeginChild("Details")

    ------------------------------ table -------------------------------------
    if not channelData[editChanID] then ImGui.EndChild() return end
    for eventID, eventDetails in pairs(channelData[editChanID].Events) do
        if hString[eventID] == nil then hString[eventID] = string.format(channelData[editChanID].Name .. ' : ' ..eventDetails.eventString) end
        if ImGui.CollapsingHeader(hString[eventID]) then
            local contentSizeX = ImGui.GetWindowContentRegionWidth()
            ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
            ImGui.BeginChild('Events##'..eventID, contentSizeX,0.0,bit32.bor(ImGuiChildFlags.Border, ImGuiChildFlags.AutoResizeY))
            if ImGui.BeginTable("Channel Events##"..editChanID, 4, bit32.bor(ImGuiTableFlags.NoHostExtendX)) then
                ImGui.TableSetupColumn("ID's##_", ImGuiTableColumnFlags.WidthAlwaysAutoResize, 100)
                ImGui.TableSetupColumn("Strings", ImGuiTableColumnFlags.WidthStretch, 150)
                ImGui.TableSetupColumn("Color", ImGuiTableColumnFlags.WidthFixed, 50)
                ImGui.TableSetupColumn("##Delete", ImGuiTableColumnFlags.WidthAlwaysAutoResize, 50)
                ImGui.TableHeadersRow()
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                if ImGui.Button('Add Filter') then
                    newFilter = true
                    if newFilter then
                        --printf("eID: %s", eventID )
                        if not channelData[editChanID].Events[eventID].Filters then
                            channelData[editChanID].Events[eventID].Filters = {}
                        end
                        local maxFilterId = getNextID(channelData[editChanID].Events[eventID]['Filters'])
                        --printf("fID: %s",maxFilterId)
                        channelData[editChanID]['Events'][eventID].Filters[maxFilterId] = {
                            ['filterString'] = 'new',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        }
                        newFilter = false
                    end
                end
                if ImGui.IsItemHovered() then
                    ImGui.BeginTooltip()
                    ImGui.Text('You can add TOKENs to your filters in place for character names.\n')
                    ImGui.Text('LIST OF TOKENS')
                    ImGui.Text('M3\t = Your Name')
                    ImGui.Text('M1\t = Main Assist Name')
                    ImGui.Text('PT1\t = Your Pet Name')
                    ImGui.Text('PT3\t = Any Members Pet Name')
                    ImGui.Text('GP1\t = Party Members Name')
                    ImGui.Text('TK1\t = Main Tank Name')
                    ImGui.Text('RL\t = Raid Leader Name')
                    ImGui.Text('H1\t = Group Healer (DRU, CLR, or SHM)')
                    ImGui.Text('G1 - G5\t = Party Members Name in Group Slot 1-5')
                    ImGui.Text('N3\t = NPC Name')
                    ImGui.Text('P3\t = PC Name')
                    ImGui.EndTooltip()
                end
                ImGui.TableSetColumnIndex(1)
                if not tempEventStrings[editChanID][eventID] then tempEventStrings[editChanID][eventID] = eventDetails end
                tmpString = tempEventStrings[editChanID][eventID].eventString
                local bufferKey = editChanID .. "_" .. tostring(eventID)
                tmpString = ImGui.InputText("Event String##EventString" .. bufferKey, tmpString, 256)
                hString[eventID] = hString[eventID]
                if tempEventStrings[editChanID][eventID].eventString ~= tmpString then tempEventStrings[editChanID][eventID].eventString = tmpString end
                ImGui.TableSetColumnIndex(2)
                if not tempChanColors[editChanID][eventID] then
                    tempChanColors[editChanID][eventID] = eventDetails.Filters[0].color or {1.0, 1.0, 1.0, 1.0} -- Default to white with full opacity
                end
                
                tempChanColors[editChanID][eventID] = ImGui.ColorEdit4("##Color" .. bufferKey, tempChanColors[editChanID][eventID], MyColorFlags)
                ImGui.TableSetColumnIndex(3)
                if ImGui.Button("Delete##" .. bufferKey) then
                    -- Delete the event
                    tempSettings.Channels[editChanID].Events[eventID] = nil
                    tempEventStrings[editChanID][eventID] = nil
                    tempChanColors[editChanID][eventID] = nil
                    tempFiltColors[editChanID][eventID] = nil
                    tempFilterStrings[editChanID][eventID] = nil
                    ResetEvents()
                end
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                ImGui.SeparatorText('')
                ImGui.TableSetColumnIndex(1)
                ImGui.SeparatorText('Filters')
                ImGui.TableSetColumnIndex(2)
                ImGui.SeparatorText('')
                ImGui.TableSetColumnIndex(3)
                ImGui.SeparatorText('')
                --------------- Filters ----------------------
                for filterID, filterData in pairs(eventDetails.Filters) do
                    
                    if filterID > 0  then--and filterData.filterString ~= '' then
                        ImGui.TableNextRow()
                        ImGui.TableSetColumnIndex(0)
                        ImGui.Text("fID: %s", tostring(filterID))
                        ImGui.TableSetColumnIndex(1)
                        if not tempFilterStrings[editChanID][eventID] then
                            tempFilterStrings[editChanID][eventID] = {}
                        end
                        if not tempFilterStrings[editChanID][eventID][filterID] then
                            tempFilterStrings[editChanID][eventID][filterID] = filterData.filterString
                        end
                        local tempFilter = tempFilterStrings[editChanID][eventID][filterID]
                        -- Display the filter string input field
                        local tmpKey = string.format("%s_%s", eventID, filterID)
                        tempFilter, _ = ImGui.InputText("Filter String##_"..tmpKey, tempFilter)
                        -- Update the filter string in tempFilterStrings
                        if tempFilterStrings[editChanID][eventID][filterID] ~= tempFilter then
                            tempFilterStrings[editChanID][eventID][filterID] = tempFilter
                        end
                        ImGui.TableSetColumnIndex(2)
                        if not tempFiltColors[editChanID][eventID] then tempFiltColors[editChanID][eventID] = {} end
                        if not tempFiltColors[editChanID][eventID][filterID] then tempFiltColors[editChanID][eventID][filterID] = filterData.color or {} end
                        local tmpColor = {}
                        tmpColor = filterData['color']
                        -- Display the color picker for the filter
                        filterData['color'] = ImGui.ColorEdit4("##Color_" .. filterID, tmpColor, MyColorFlags)
                        if tempFiltColors[editChanID][eventID][filterID] ~= tmpColor then tempFiltColors[editChanID][eventID][filterID] = tmpColor end
                        ImGui.TableSetColumnIndex(3)
                        if ImGui.Button("Delete##_" .. filterID) then
                            -- Delete the Filter
                            tempSettings.Channels[editChanID].Events[eventID].Filters[filterID] = nil
                            --printf("chanID: %s, eID: %s, fID: %s",editChanID,eventID,filterID)
                            tempFilterStrings[editChanID][eventID][filterID] = nil
                            tempChanColors[editChanID][eventID][filterID] = nil
                            tempFiltColors[editChanID][eventID][filterID] = nil
                            ResetEvents()
                        end
                    end
                end
                ImGui.EndTable()
            end
            ImGui.EndChild()
        else
            hString[eventID] = string.format(channelData[editChanID].Name .. ' : ' ..eventDetails.eventString)
        end
        lastChan = 0
    end
    ImGui.EndChild()
    ImGui.SetWindowFontScale(1)
end

local function buildConfig()
    lastID = 0
    ImGui.BeginChild("Channels##")
    for channelID, channelData in pairs(tempSettings.Channels) do
        if channelID ~= lastID then
            -- Check if the header is collapsed
            if ImGui.CollapsingHeader(channelData.Name) then
                local contentSizeX = ImGui.GetWindowContentRegionWidth()
                ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
                ImGui.BeginChild('Channels##'..channelID,contentSizeX,0.0,bit32.bor(ImGuiChildFlags.Border, ImGuiChildFlags.AutoResizeY, ImGuiChildFlags.AlwaysAutoResize))
                -- Begin a table for events within this channel
                if ImGui.BeginTable("ChannelEvents_" .. channelData.Name, 4, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Borders, ImGui.GetWindowWidth() - 5)) then
                    -- Set up table columns once
                    ImGui.TableSetupColumn("", ImGuiTableColumnFlags.WidthFixed, 50)
                    ImGui.TableSetupColumn("Channel", ImGuiTableColumnFlags.WidthAlwaysAutoResize, 100)
                    ImGui.TableSetupColumn("EventString", ImGuiTableColumnFlags.WidthStretch, 150)
                    ImGui.TableSetupColumn("Color", ImGuiTableColumnFlags.WidthAlwaysAutoResize)
                    -- Iterate through each event in the channel
                    local once = true
                    for eventId, eventDetails in pairs(channelData.Events) do
                        local bufferKey = channelID .. "_" .. tostring(eventId)
                        local name = channelData.Name
                        local bufferKey = channelID .. "_" .. tostring(eventId)
                        local channelKey = "##ChannelName" .. channelID
                        ImGui.TableNextRow()
                        ImGui.TableSetColumnIndex(0)
                        if once then
                            if ImGui.Button("Edit Channel##" .. bufferKey) then
                                editChanID = channelID
                                addChannel = false
                                tempSettings = ChatWin.Settings
                                ChatWin.openEditGUI = true
                                ChatWin.openConfigGUI = false
                            end
                            once = false
                            else
                            ImGui.Dummy(1,1)
                        end
                        ImGui.TableSetColumnIndex(1)
                        tempSettings.Channels[channelID].Events[eventId].enabled = ImGui.Checkbox('Enabled##'..eventId, tempSettings.Channels[channelID].Events[eventId].enabled)
                        ImGui.TableSetColumnIndex(2)
                        ImGui.Text(eventDetails.eventString)
                        ImGui.TableSetColumnIndex(3)
                        if not eventDetails.Filters[0].color then
                            eventDetails.Filters[0].color = {1.0, 1.0, 1.0, 1.0} -- Default to white with full opacity
                        end
                        ImGui.ColorEdit4("##Color" .. bufferKey, eventDetails.Filters[0].color, bit32.bor(ImGuiColorEditFlags.NoOptions,ImGuiColorEditFlags.NoPicker, ImGuiColorEditFlags.NoInputs, ImGuiColorEditFlags.NoTooltip, ImGuiColorEditFlags.NoLabel))
                    end
                    -- End the table for this channel
                    ImGui.EndTable()
                end
                ImGui.EndChild()
                ImGui.SetWindowFontScale(1)
            end
        end
        lastID = channelID
    end
    ImGui.EndChild()
end

function ChatWin.Config_GUI(open)
    
    local themeName = tempSettings.LoadTheme or 'notheme'
    if themeName ~= 'notheme' then useTheme = true end
    -- Push Theme Colors
    if useTheme then
        local themeName = tempSettings.LoadTheme
        ColorCountConf, StyleCountConf = DrawTheme(themeName)
    end
    
    open, show = ImGui.Begin("Event Configuration", open, bit32.bor(ImGuiWindowFlags.None))
    
    if not show then
        if ColorCountConf > 0 then ImGui.PopStyleColor(ColorCountConf) end
        if StyleCountConf > 0 then ImGui.PopStyleVar(StyleCountConf) end
        ImGui.End()
        if not open then ChatWin.openConfigGUI = false end
    else
        ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
        -- Add a button to add a new row
        if ImGui.Button("Add Channel") then
            editChanID =  getNextID(ChatWin.Settings.Channels)
            addChannel = true
            fromConf = true
            tempSettings = ChatWin.Settings
            ChatWin.openEditGUI = true
            ChatWin.openConfigGUI = false
        end
        
        ImGui.SameLine()
        if ImGui.Button("Reload Theme File") then
            loadSettings()
        end
        
        ImGui.SameLine()
        -- Close Button
        if ImGui.Button('Close') then
            ChatWin.openConfigGUI = false
            editChanID = 0
            editEventID = 0
            ChatWin.Settings = tempSettings
            ResetEvents()
        end
        
        ImGui.SeparatorText('Import Settings')
        importFile = ImGui.InputTextWithHint('Import##FileName', importFile,importFile, 256)
        ImGui.SameLine()
        cleanImport = ImGui.Checkbox('Clean Import##clean', cleanImport)
        
        if ImGui.Button('Import Channels') then
            local tmp = mq.configDir..'/'..importFile
            if not File_Exists(tmp) then
                mq.cmd("/msgbox 'No File Found!")
                else
                -- Load settings from the Lua config file
                local date = os.date("%m_%d_%Y_%H_%M")
                
                -- print(date)
                local backup = string.format('%s/MyChat/Backups/%s/%s_BAK_%s.lua', mq.configDir, serverName, myName, date)
                mq.pickle(backup, ChatWin.Settings)
                local newSettings = {}
                local newID = getNextID(tempSettings.Channels)
                
                newSettings = dofile(tmp)
                -- print(tostring(cleanImport))
                if not cleanImport and lastImport ~= tmp then
                    for cID, cData in pairs(newSettings.Channels) do
                        for existingCID, existingCData in pairs(tempSettings.Channels) do
                            if existingCData.Name == cData.Name then
                                local newName = cData.Name.. '_NEW'
                                cData.Name = newName
                            end
                        end
                        tempSettings.Channels[newID] = cData
                        newID = newID + 1
                    end
                    else
                    tempSettings = {}
                    tempSettings = newSettings
                end
                lastImport = tmp
                ResetEvents()
            end
        end
        if ImGui.CollapsingHeader("Theme Settings##Header") then
        -- if vis then
            ImGui.SeparatorText('Theme')
            ImGui.Text("Cur Theme: %s", themeName)
            -- Combo Box Load Theme
            if ImGui.BeginCombo("Load Theme", themeName) then
                for k, data in pairs(theme.Theme) do
                    local isSelected = data['Name'] == themeName
                    if ImGui.Selectable(data['Name'], isSelected) then
                        tempSettings['LoadTheme'] = data['Name']
                        themeName = tempSettings['LoadTheme']
                        ChatWin.Settings = tempSettings
                        writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
                    end
                end
                ImGui.EndCombo()
            end
        end
        ImGui.SeparatorText('Main Tab Zoom')
        -- Slider for adjusting zoom level
        local tmpZoom = ChatWin.Settings.Scale
        if ChatWin.Settings.Scale then
            tmpZoom = ImGui.SliderFloat("Zoom Level##MyBuffs", tmpZoom, 0.5, 2.0)
        end

        if ChatWin.Settings.Scale ~= tmpZoom then
            ChatWin.Settings.Scale = tmpZoom
            tempSettings.Scale = tmpZoom
        end

        local tmpRefLink = (doRefresh and ChatWin.Settings.refreshLinkDB >=5) and ChatWin.Settings.refreshLinkDB or 0
        tmpRefLink = ImGui.InputInt("Refresh Delay##LinkRefresh",tmpRefLink, 5, 5)
        if tmpRefLink < 0 then tmpRefLink = 0 end
        if tmpRefLink ~= ChatWin.Settings.refreshLinkDB then
            -- ChatWin.Settings.refreshLinkDB = tmpRefLink
            tempSettings.refreshLinkDB = tmpRefLink
            doRefresh = tmpRefLink >= 5 or false
        end
        ImGui.SameLine()
        local txtOnOff = doRefresh and 'ON' or 'OFF'
        ImGui.Text(txtOnOff)
        eChan = ImGui.InputText("Main Channel Echo##Echo", eChan, 256)
        if eChan ~= ChatWin.Settings.mainEcho then
            ChatWin.Settings.mainEcho = eChan
            tempSettings.mainEcho = eChan
            writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
        end
        ImGui.SeparatorText('Channels and Events Overview')
        buildConfig()
        if ColorCountConf > 0 then ImGui.PopStyleColor(ColorCountConf) end
        if StyleCountConf > 0 then ImGui.PopStyleVar(StyleCountConf) end
        ImGui.SetWindowFontScale(1)
        ImGui.End()
    end
    
end

function ChatWin.Edit_GUI(open)

    if not ChatWin.openEditGUI then return end
    
    if useTheme then
        local themeName = ChatWin.Settings.LoadTheme
        ColorCountEdit, StyleCountEdit = DrawTheme(themeName)
    end
    
    open, showEdit = ImGui.Begin("Channel Editor", open, bit32.bor(ImGuiWindowFlags.None))
    if not showEdit then
        if ColorCountEdit > 0 then ImGui.PopStyleColor(ColorCountEdit) end
        if StyleCountEdit > 0 then ImGui.PopStyleVar(StyleCountEdit) end
        ImGui.End()
    else
        ImGui.SetWindowFontScale(ChatWin.Settings.Scale)
        ChatWin.AddChannel(editChanID, addChannel)
        ImGui.SameLine()
        -- Close Button
        if ImGui.Button('Close') then
            ChatWin.openEditGUI = false
            addChannel = false
            editChanID = 0
            editEventID = 0
        end
        ImGui.SetWindowFontScale(1)
        if ColorCountEdit > 0 then ImGui.PopStyleColor(ColorCountEdit) end
        if StyleCountEdit > 0 then ImGui.PopStyleVar(StyleCountEdit) end
        ImGui.End()
    end
    if not open then ChatWin.openEditGUI = false end
end

function ChatWin.StringTrim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end

---comments
---@param text string -- the incomming line of text from the command prompt
function ChatWin.ExecCommand(text)
    if LocalEcho then
        ChatWin.console:AppendText(IM_COL32(128, 128, 128), "> %s", text)
    end
    
    
    -- todo: implement history
    if string.len(text) > 0 then
        text = ChatWin.StringTrim(text)
        if text == 'clear' then
            ChatWin.console:Clear()
            elseif string.sub(text, 1, 1) ~= '/' then
            if activeID > 0 then
                eChan = ChatWin.Settings.Channels[activeID].Echo or '/say'
            end
            if string.find(eChan, '_') then
                eChan = string.gsub(eChan,'_','')
                text = string.format("%s%s",eChan, text)
                else
                text = string.format("%s %s",eChan, text)
            end
        end
        if string.sub(text, 1, 1) == '/' then
            mq.cmdf("%s", text)
            else
                ChatWin.console:AppendText(IM_COL32(255, 0, 0), "Unknown command: '%s'", text)
        end
    end
end

---comments
---@param text string -- the incomming line of text from the command prompt
function ChatWin.ChannelExecCommand(text, channelID)
    if LocalEcho then
        ChatWin.console:AppendText(IM_COL32(128, 128, 128), "> %s", text)
    end
    
    local eChan = '/say'
    -- todo: implement history
    if string.len(text) > 0 then
        text = ChatWin.StringTrim(text)
        if text == 'clear' then
            ChatWin.console:Clear()
            elseif string.sub(text, 1, 1) ~= '/' then
            if channelID > 0 then
                eChan = ChatWin.Settings.Channels[channelID].Echo or '/say'
            end
            if string.find(eChan, '_') then
                eChan = string.gsub(eChan,'_','')
                text = string.format("%s%s",eChan, text)
                else
                text = string.format("%s %s",eChan, text)
            end
        end
        if string.sub(text, 1, 1) == '/' then
            mq.cmdf("%s", text)
            else
            ChatWin.console:AppendText(IM_COL32(255, 0, 0), "Unknown command: '%s'", text)
        end
    end
end

local function init()
    running = true
    mq.imgui.init('MyChatGUI', ChatWin.GUI)
    -- initialize the console
    if ChatWin.console == nil then
        ChatWin.console = ImGui.ConsoleWidget.new("Chat##Console")
        mainBuffer = {
            [1] = {
                color ={[1]=1,[2]=1,[3]=1,[4]=1},
                text = '',
            }
        }
        
    end
    ChatWin.console:AppendText("\ay[\aw%s\ay]\at Welcome to \agMyChat!",mq.TLO.Time())
    mq.delay(500)
    if links ~= nil then
        links.Console = ChatWin.console
        -- links.setupDB()
    end
end

local function loop()
    while running do
        if mq.TLO.Window('CharacterListWnd').Open() then running = false end
        if ChatWin.Settings.refreshLinkDB > 0 and doRefresh then
            local timeB = os.time()
            if timeB - timeA >= ChatWin.Settings.refreshLinkDB * 60 then
                if links ~= nil then
                    ReLoadDB()
                end
                timeA = timeB
            end
        end
        mq.doevents()
        mq.delay(100)
    end
    mq.exit()
end

loadSettings()
BuildEvents()
init()
loop()
