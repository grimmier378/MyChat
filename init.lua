local mq = require('mq')
local ImGui = require('ImGui')

---@type ConsoleWidget
local console = nil
local resetPosition = false
local setFocus = false
local commandBuffer = ''
-- local var's
local serverName = string.gsub(mq.TLO.EverQuest.Server(), ' ', '_') or ''
local myName = mq.TLO.Me.DisplayName() or ''
local addChannel = false
local tempSettings, eventNames = {}, {} -- tables for storing event details
local useTheme, timeStamps, newEvent, newFilter= false, true, false, false
local zBuffer = 1000 -- the buffer size for the Zoom chat buffer.
local editChanID, editEventID, lastID, lastChan = 0, 0, 0, 0
local tempFilterStrings, tempEventStrings, tempChanColors, tempFiltColors = {}, {}, {}, {} -- Tables to store our strings and color values for editing
local ActTab, activeID = 'Main', 0 -- info about active tab channels
local theme = {}
local useThemeName = 'Default'
local ColorCountEdit,ColorCountConf, ColorCount = 0, 0, 0
local ChatWin = {
    SHOW = true,
    openGUI = true,
    openConfigGUI = false,
    SettingsFile = string.format('%s/MyChat_%s_%s.lua', mq.configDir, serverName, myName),
    ThemesFile = string.format('%s/MyThemeZ.lua', mq.configDir, serverName, myName),
    Settings = {
        -- Channels
        Channels = {},
    },
    -- Consoles
    Consoles = {},
    -- Flags
    tabFlags = bit32.bor(ImGuiTabBarFlags.Reorderable, ImGuiTabBarFlags.TabListPopupButton),
    winFlags = bit32.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoScrollbar),
}

local MyColorFlags = bit32.bor(
    ImGuiColorEditFlags.NoOptions,
    ImGuiColorEditFlags.NoInputs,
    ImGuiColorEditFlags.NoTooltip,
    ImGuiColorEditFlags.NoLabel
)

--Helper Functioons

---comment Check to see if the file we want to work on exists.
---@param name string -- Full Path to file
---@return boolean -- returns true if the file exists and false otherwise
function File_Exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

---comment -- Checks for the last ID number in the table passed. returns the NextID
---@param table table -- the table we want to look up ID's in
---@return number -- returns the NextID that doesn't exist in the table yet.
local function getNextID(table)
    local maxChannelId = 0
    for channelId, _ in pairs(table) do
        local numericId = tonumber(channelId)
        if numericId and numericId > maxChannelId then
            maxChannelId = numericId
        end
    end
    return maxChannelId + 1
end

---comment Build the consoles for each channel based on ChannelID
---@param channelID integer -- the channel ID number for the console we are setting up
local function SetUpConsoles(channelID)
    if ChatWin.Consoles[channelID].console == nil then
        ChatWin.Consoles[channelID].txtBuffer = {
            [1] = {
                color ={[1]=1,[2]=1,[3]=1,[4]=1},
                text = '',
            }
        }
        ChatWin.Consoles[channelID].txtAutoScroll = true
        ChatWin.Consoles[channelID].console = ImGui.ConsoleWidget.new(channelID.."##Console")
    end
end

---comment Writes settings from the settings table passed to the setting file (full path required)
-- Uses mq.pickle to serialize the table and write to file
---@param file string -- File Name and path
---@param settings table -- Table of settings to write
local function writeSettings(file, settings)
    mq.pickle(file, settings)
end

local function loadSettings()
    if not File_Exists(ChatWin.SettingsFile) then
        local defaults = require('default_settings')
        ChatWin.Settings = defaults
        mq.pickle(ChatWin.SettingsFile, defaults)
        else
        -- Load settings from the Lua config file
        ChatWin.Settings = dofile(ChatWin.SettingsFile)
    end

    useThemeName = ChatWin.Settings.LoadTheme

    if not File_Exists(ChatWin.ThemesFile) then
        local defaultThemes = require('themes')
        theme = defaultThemes
        mq.pickle(ChatWin.ThemesFile, theme)
        else
        -- Load settings from the Lua config file
        theme = dofile(ChatWin.ThemesFile)
    end

    for channelID, channelData in pairs(ChatWin.Settings.Channels) do
        -- setup default Echo command channels.
        if not channelData.Echo then
            ChatWin.Settings.Channels[channelID].Echo = '/say'
        end
        -- Ensure each channel's console widget is initialized
        if not ChatWin.Consoles[channelID] then
            ChatWin.Consoles[channelID] = {}
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
                if not ChatWin.Settings.Channels[channelID]['Events'][eID]['Filters'][0] then
                    ChatWin.Settings.Channels[channelID]['Events'][eID]['Filters'][0] = {filterString = '', color = {}}
                end
                ChatWin.Settings.Channels[channelID]['Events'][eID]['Filters'][0].color = eData.color
                eData.color = nil
            end
        end

    end

    if not ChatWin.Settings.LoadTheme then
        ChatWin.Settings.LoadTheme = theme.LoadTheme
    end

    if useThemeName ~= 'Default' then
        useTheme = true
    end

    writeSettings(ChatWin.SettingsFile, ChatWin.Settings)

    tempSettings = ChatWin.Settings
end

local function BuildEvents()
    eventNames = {}
    for channelID, channelData in pairs(ChatWin.Settings.Channels) do
        for eventId, eventDetails in pairs(channelData.Events) do
            if eventDetails.eventString then
                local eventName = string.format("event_%s_%d", channelID, eventId)
                mq.event(eventName, eventDetails.eventString, function(line) ChatWin.EventChat(channelID, eventName, line) end)
                -- Store event details for direct access
                eventNames[eventName] = eventDetails
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

--[[ Reads in the line, channelID and eventName of the triggered events. Parses the line against the Events and Filters for that channel.
    adjusts coloring for the line based on settings for the matching event / filter and writes to the corresponding console.
    if an event contains filters and the line doesn't match any of them we discard the line and return.
If there are no filters we use the event default coloring and write to the consoles. ]]
---@param channelID integer -- The ID number of the Channel the triggered event belongs to
---@param eventName string -- the name of the event that was triggered
---@param line string -- the line of text that triggred the event
function ChatWin.EventChat(channelID, eventName, line)
    local eventDetails = eventNames[eventName]
    if not eventDetails then return end
    if ChatWin.Consoles[channelID] then
        local txtBuffer = ChatWin.Consoles[channelID].txtBuffer
        local colorVec = eventDetails.Filters[0].color or {1,1,1,1}
        local fMatch = false
        
        if txtBuffer then
            local fCount = 0
            -- for eID, eData in pairs(eventDetails.Filters) do
            for fID, fData in pairs(eventDetails.Filters) do
                if fID > 0 and not fMatch then
                    fCount = fID
                    local fString = fData.filterString
                    if fString == 'ME' then
                        fString = mq.TLO.Me.DisplayName()
                        elseif fString == 'PET' then
                        fString = mq.TLO.Me.Pet.DisplayName() or 'NO PET'
                        elseif fString =='MA' then
                        fString = mq.TLO.Group.MainAssist.DisplayName() or 'NO MA'
                        elseif fString == 'TANK' then
                        fString = mq.TLO.Group.MainTank.DisplayName() or 'NO TANK'
                        elseif fString == 'RL' then
                        fString = mq.TLO.Raid.Leader.DisplayName() or 'NO RAID'
                        elseif fString == 'GROUP' then
                        for i = 1, (mq.TLO.Group.GroupSize() or 0) -1 do
                            fString = mq.TLO.Group.Member(i).DisplayName() or 'NO GROUP'
                            if string.find(line, fString) or string.find(line, string.lower(fString)) then
                                colorVec = fData.color
                                fMatch = true
                                break
                            end
                        end
                        elseif fString == 'G1' then
                        fString = mq.TLO.Group.Member(1).DisplayName() or 'NO GROUP'
                        elseif fString == 'G2' then
                        fString = mq.TLO.Group.Member(2).DisplayName() or 'NO GROUP'
                        elseif fString == 'G3' then
                        fString = mq.TLO.Group.Member(3).DisplayName() or 'NO GROUP'
                        elseif fString == 'G4' then
                        fString = mq.TLO.Group.Member(4).DisplayName() or 'NO GROUP'
                        elseif fString == 'G5' then
                        fString =  mq.TLO.Group.Member(5).DisplayName() or 'NO GROUP'
                        elseif fString == 'RL' then
                        fString = mq.TLO.Raid.Leader.DisplayName() or 'NO RAID'
                        elseif fString == 'HEALER' then
                        for i = 1, (mq.TLO.Group.GroupSize() or 0) -1 do
                            local class = mq.TLO.Group.Member(i).Class.ShortName() or 'NO GROUP'
                            if class == 'CLR' or class == 'DRU' or class == 'SHM' then
                                fString = mq.TLO.Group.Member(i).DisplayName()
                                if string.find(line, fString) then
                                    colorVec = fData.color
                                    fMatch = true
                                    break
                                end
                            end
                        end
                    end
                    if string.find(line, fString) and not fMatch then
                        colorVec = fData.color
                        fMatch = true
                    end
                    if fMatch then break end
                end
                if fMatch then break end
                -- end
            end
            --print(tostring(#eventDetails.Filters))
            if not fMatch and fCount > 0 then return end -- we had filters and didn't match so leave
            local i = getNextID(txtBuffer)
            if timeStamps then
                local tStamp = mq.TLO.Time.Time24()
                line = string.format("%s %s",tStamp,line)
            end
            local colorCode = ImVec4(colorVec[1], colorVec[2], colorVec[3], colorVec[4])
            -- write channel console
            if ChatWin.Consoles[channelID].console then
                ChatWin.Consoles[channelID].console:AppendText(colorCode, line)
            end
            -- write main console
            console:AppendText(colorCode,line)
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

function ChatWin.GUI()
    if not ChatWin.openGUI then return end
    ColorCount = 0
    local windowName = 'My Chat##'..myName
    ImGui.SetNextWindowSize(ImVec2(640, 480), ImGuiCond.FirstUseEver)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(1, 0));
    if useTheme then
        local themeName = tempSettings.LoadTheme
        for tID, tData in pairs(theme.Theme) do
            if tData.Name == themeName then
                for pID, cData in pairs(theme.Theme[tID].Color) do
                    ImGui.PushStyleColor(pID, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], cData.Color[4]))
                    ColorCount = ColorCount +1
                end
            end
        end
    end
    if ImGui.Begin(windowName, ChatWin.openGUI, ChatWin.winFlags) then
        -- Main menu bar
        if ImGui.BeginMenuBar() then
            if ImGui.BeginMenu('Options') then
                _, console.autoScroll = ImGui.MenuItem('Auto-scroll', nil, console.autoScroll)
                _, LocalEcho = ImGui.MenuItem('Local echo', nil, LocalEcho)
                _, timeStamps = ImGui.MenuItem('Time Stamps', nil, timeStamps)
                ImGui.Separator()
                if ImGui.BeginMenu('Channels') then
                    for channelID, settings in pairs(ChatWin.Settings.Channels) do
                        local enabled = ChatWin.Settings.Channels[channelID].enabled
                        local name = ChatWin.Settings.Channels[channelID].Name
                        if ImGui.MenuItem(name, '', enabled) then
                            ChatWin.Settings.Channels[channelID].enabled = not enabled
                            writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
                        end
                    end
                    ImGui.EndMenu()
                end
                if ImGui.MenuItem('Configure Events') then
                    ChatWin.openConfigGUI = true
                    ChatWin.Config_GUI(ChatWin.openConfigGUI)
                end
                ImGui.Separator()
                if ImGui.MenuItem('Reset Position') then
                    resetPosition = true
                end
                ImGui.Separator()
                if ImGui.MenuItem('Clear Main Console') then
                    console:Clear()
                end
                if ImGui.MenuItem('Exit') then
                    ChatWin.SHOW = false
                end
                ImGui.Spacing()
                ImGui.EndMenu()
            end
            ImGui.EndMenuBar()
        end
        -- End of menu bar
        -- Begin Tabs Bars
        if ImGui.BeginTabBar('Channels', ChatWin.tabFlags) then
            -- Begin Main tab
            if ImGui.BeginTabItem('Main') then
                ActTab = 'Main'
                activeID = 0
                local footerHeight = 30
                local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
                contentSizeY = contentSizeY - footerHeight
                if ImGui.BeginPopupContextWindow() then
                    if ImGui.Selectable('Clear') then
                        console:Clear()
                    end
                    ImGui.EndPopup()
                end
                console:Render(ImVec2(contentSizeX,contentSizeY))
                ImGui.EndTabItem()
            end
            -- End Main tab
            -- Begin other tabs
            for channelID, data in pairs(ChatWin.Settings.Channels) do
                if ChatWin.Settings.Channels[channelID].enabled then
                    local name = ChatWin.Settings.Channels[channelID].Name
                    local zoom = ChatWin.Consoles[channelID].zoom
                    local scale = ChatWin.Settings.Channels[channelID].Scale
                    if ImGui.BeginTabItem(name) then
                        ActTab = name
                        activeID = channelID
                        local footerHeight = 30
                        local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
                        contentSizeY = contentSizeY - footerHeight
                        if ImGui.BeginPopupContextWindow() then
                            if ImGui.Selectable('Clear') then
                                ChatWin.Consoles[channelID].console:Clear()
                                ChatWin.Consoles[channelID].txtBuffer = {}
                            end
                            if ImGui.Selectable('Zoom') then
                                zoom = not zoom
                                ChatWin.Consoles[channelID].zoom = zoom
                            end
                            ImGui.EndPopup()
                        end
                        if zoom and ChatWin.Consoles[channelID].txtBuffer ~= '' then
                            ImGui.BeginChild("ZoomScrollRegion", ImVec2(contentSizeX, contentSizeY), ImGuiWindowFlags.HorizontalScrollbar)
                            ImGui.BeginTable('##channelID', 1, bit32.bor(ImGuiTableFlags.NoBordersInBody, ImGuiTableFlags.RowBg))
                            ImGui.TableSetupColumn("##txt", ImGuiTableColumnFlags.NoHeaderLabel)
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
                                elseif scrollPos >= bottomPosition-10 then
                                ChatWin.Consoles[channelID].txtAutoScroll = true
                            end
                            lastScrollPos = scrollPos
                            ChatWin.Consoles[channelID].lastScrollPos = lastScrollPos
                            ImGui.EndTable()
                            ImGui.EndChild()
                            else
                            ChatWin.Consoles[channelID].console:Render(ImVec2(contentSizeX,contentSizeY))
                        end
                        ImGui.EndTabItem()
                    end
                end
            end
            -- End other tabs
            ImGui.EndTabBar()
        end
        -- End Tab Bar
        --Command Line
        ImGui.Separator()
        local textFlags = bit32.bor(0,
            ImGuiInputTextFlags.EnterReturnsTrue,
            -- not implemented yet
            ImGuiInputTextFlags.CallbackCompletion,
            ImGuiInputTextFlags.CallbackHistory
        )
        local contentSizeX, _ = ImGui.GetContentRegionAvail()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 6)
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 2)
        ImGui.PushItemWidth(contentSizeX)
        ImGui.PushStyleColor(ImGuiCol.FrameBg, ImVec4(0, 0, 0, 0))
        ImGui.PushFont(ImGui.ConsoleFont)
        local accept = false
        commandBuffer, accept = ImGui.InputText('##Input', commandBuffer, textFlags)
        ImGui.PopFont()
        ImGui.PopStyleColor()
        ImGui.PopItemWidth()
        if accept then
            ChatWin.ExecCommand(commandBuffer)
            commandBuffer = ''
            setFocus = true
        end
        ImGui.SetItemDefaultFocus()
        if setFocus then
            setFocus = false
            ImGui.SetKeyboardFocusHere(-1)
        end
    end
    if useTheme then ImGui.PopStyleColor(ColorCount) end
    ImGui.PopStyleVar()
    ImGui.End()
    
end

-------------------------------- Configure Windows and Events GUI ---------------------------

---comment Draws the Channel data for editing. Can be either an exisiting Channel or a New one.
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
                if not tempFiltColors[editChanID][eID][fID] then tempFiltColors[editChanID][eID][fID] = {} end
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
                ['Events'] = {
                    [1] = {
                        ['eventString'] = 'new',
                        ['Filters'] = {
                            [0] = {
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
        local channelEvents = tempSettings.Channels[editChanID].Events
        for eventId, eventData in pairs(tempEventStrings[editChanID]) do
            -- Skip 'Name' key used for the channel name
            if eventId ~= 'Name' then
                if eventData and eventData.eventString then
                    channelEvents[eventId] = channelEvents[eventId] or {color = {1.0, 1.0, 1.0, 1.0}, Filters = {}}
                    channelEvents[eventId].eventString = eventData.eventString
                    channelEvents[eventId].color = tempChanColors[editChanID][eventId] or channelEvents[eventId].color
                    channelEvents[eventId].Filters = {}
                    for filterID, filterData in pairs(tempFilterStrings[editChanID][eventId] or {}) do
                        channelEvents[eventId].Filters[filterID] = {
                            filterString = filterData,
                            color = tempFiltColors[editChanID][eventId][filterID] or {1.0, 1.0, 1.0, 1.0} -- Default to white with full opacity if color not found
                        }
                    end
                end
            end
        end
        ChatWin.Settings = tempSettings
        ResetEvents()
        ChatWin.openEditGUI = false
        ChatWin.openConfigGUI = true
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
        ChatWin.openConfigGUI = true
    end
    ImGui.SeparatorText('Events and Filters')
    ImGui.BeginChild("Details")
    ------------------------------ table -------------------------------------
    if not channelData[editChanID] then ImGui.EndChild() return end
    for eventID, eventDetails in pairs(channelData[editChanID].Events) do
        local collapsed, _ = ImGui.CollapsingHeader(channelData[editChanID].Name .. ' : ' ..eventDetails.eventString)
        -- Check if the header is collapsed
        if not collapsed then
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
                ImGui.TableSetColumnIndex(1)
                if not tempEventStrings[editChanID][eventID] then tempEventStrings[editChanID][eventID] = eventDetails end
                tmpString = tempEventStrings[editChanID][eventID].eventString
                local bufferKey = editChanID .. "_" .. tostring(eventID)
                tmpString = ImGui.InputText("Event String##EventString" .. bufferKey, tmpString, 256)
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

                --------------- Filters ----------------------
                for filterID, filterData in pairs(eventDetails.Filters) do
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0)
                    ImGui.SeparatorText('')
                    ImGui.TableSetColumnIndex(1)
                    ImGui.SeparatorText('Filters')
                    ImGui.TableSetColumnIndex(2)
                    ImGui.SeparatorText('')
                    ImGui.TableSetColumnIndex(3)
                    ImGui.SeparatorText('')

                    if filterID > 0 and filterData.filterString ~= '' then
                        ImGui.TableNextRow()
                        ImGui.TableSetColumnIndex(0)
                        ImGui.Text(string.format("fID: %s", tostring(filterID)))
                        ImGui.TableSetColumnIndex(1)
                        if not tempFilterStrings[editChanID][eventID] then
                            tempFilterStrings[editChanID][eventID] = {}
                        end
                        if not tempFilterStrings[editChanID][eventID][filterID] then
                            tempFilterStrings[editChanID][eventID][filterID] = filterData.filterString
                        end
                        tempFilter = tempFilterStrings[editChanID][eventID][filterID]
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
        end
        lastChan = 0
    end
    ImGui.EndChild()
end

local function buildConfig()
    lastID = 0
    ImGui.BeginChild("Channels##")
    for channelID, channelData in pairs(tempSettings.Channels) do
        if channelID ~= lastID then
            local collapsed, _ = ImGui.CollapsingHeader(channelData.Name)
            -- Check if the header is collapsed
            if not collapsed then
                -- Begin a table for events within this channel
                if ImGui.BeginTable("ChannelEvents_" .. channelData.Name, 4, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Borders, ImGui.GetWindowWidth() - 5)) then
                    -- Set up table columns once
                    ImGui.TableSetupColumn("", ImGuiTableColumnFlags.WidthFixed, 50)
                    ImGui.TableSetupColumn("Channel", ImGuiTableColumnFlags.WidthAlwaysAutoResize, 100)
                    ImGui.TableSetupColumn("EventString", ImGuiTableColumnFlags.WidthStretch, 150)
                    ImGui.TableSetupColumn("Color", ImGuiTableColumnFlags.WidthAlwaysAutoResize)
                    -- Iterate through each event in the channel
                    for eventId, eventDetails in pairs(channelData.Events) do
                        local bufferKey = channelID .. "_" .. tostring(eventId)
                        local name = channelData.Name
                        local bufferKey = channelID .. "_" .. tostring(eventId)
                        local channelKey = "##ChannelName" .. channelID
                        ImGui.TableNextRow()
                        ImGui.TableSetColumnIndex(0)
                        if ImGui.Button("Edit##" .. bufferKey) then
                            editChanID = channelID
                            addChannel = false
                            tempSettings = ChatWin.Settings
                            ChatWin.openEditGUI = true
                            ChatWin.openConfigGUI = false
                        end
                        ImGui.TableSetColumnIndex(1)
                        ImGui.Text(name)
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
            end
        end
        lastID = channelID
    end
    ImGui.EndChild()
end

function ChatWin.Config_GUI(open)
    if not ChatWin.openConfigGUI then return end
    ColorCountConf = 0
    local themeName = tempSettings.LoadTheme or 'notheme'
    if themeName ~= 'notheme' then useTheme = true end
    if useTheme then
        local themeName = tempSettings.LoadTheme
        for tID, tData in pairs(theme.Theme) do
            if tData.Name == themeName then
                for pID, cData in pairs(theme.Theme[tID].Color) do
                    ImGui.PushStyleColor(pID, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], cData.Color[4]))
                    ColorCountConf = ColorCountConf +1
                end
            end
        end
    end

    open, ChatWin.openConfigGUI = ImGui.Begin("Event Configuration", open, bit32.bor(ImGuiWindowFlags.None, ImGuiWindowFlags.NoCollapse))
    if not ChatWin.openConfigGUI then
        ChatWin.openConfigGUI = false
        open = false
        if useTheme then ImGui.PopStyleColor(ColorCountConf) end
        ImGui.End()
        return open
    end
    -- Add a button to add a new row
    if ImGui.Button("Add Channel") then
        editChanID =  getNextID(ChatWin.Settings.Channels)
        addChannel = true
        tempSettings = ChatWin.Settings
        ChatWin.openEditGUI = true
        ChatWin.openConfigGUI = false
    end
    ImGui.SameLine()
    -- Close Button
    if ImGui.Button('Close') then
        ChatWin.openConfigGUI = false
        editChanID = 0
        editEventID = 0
    end
    local themeName = tempSettings.LoadTheme
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
    ImGui.SeparatorText('Channels and Events Overview')
    buildConfig()

    if useTheme then ImGui.PopStyleColor(ColorCountConf) end

    ImGui.End()
end

function ChatWin.Edit_GUI(open)
    ColorCountEdit = 0
    if not ChatWin.openEditGUI then return end
    if useTheme then
        local themeName = ChatWin.Settings.LoadTheme
        for tID, tData in pairs(theme.Theme) do
            if tData.Name == themeName then
                for pID, cData in pairs(theme.Theme[tID].Color) do
                    ImGui.PushStyleColor(pID, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], cData.Color[4]))
                    ColorCountEdit = ColorCountEdit +1
                end
            end
        end
    end
    open, ChatWin.openEditGUI = ImGui.Begin("Channel Editor", open, bit32.bor(ImGuiWindowFlags.None, ImGuiWindowFlags.NoCollapse))
    if not ChatWin.openEditGUI then
        ChatWin.openEditGUI = false
        open = false
        if useTheme then ImGui.PopStyleColor(ColorCountEdit) end
        ImGui.End()
        return open
    end
    ChatWin.AddChannel(editChanID, addChannel)
    ImGui.SameLine()
    -- Close Button
    if ImGui.Button('Close') then
        ChatWin.openEditGUI = false
        addChannel = false
        editChanID = 0
        editEventID = 0
    end

    if useTheme then ImGui.PopStyleColor(ColorCountEdit) end
    ImGui.End()
end

function ChatWin.StringTrim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end

---comments
---@param text string -- the incomming line of text from the command prompt
function ChatWin.ExecCommand(text)
    if LocalEcho then
        console:AppendText(IM_COL32(128, 128, 128), "> %s", text)
    end
    
    local eChan = '/say'
    -- todo: implement history
    if string.len(text) > 0 then
        text = ChatWin.StringTrim(text)
        if text == 'clear' then
            console:Clear()
            elseif string.sub(text, 1, 1) ~= '/' then
            if activeID > 0 then
                eChan = ChatWin.Settings.Channels[activeID].Echo or '/say'
            end
            text = string.format("%s %s",eChan, text)
        end
        if string.sub(text, 1, 1) == '/' then
            mq.cmdf("%s", text)
            else
            console:AppendText(IM_COL32(255, 0, 0), "Unknown command: '%s'", text)
        end
    end
end

local function init()
    mq.imgui.init('MyChatGUI', ChatWin.GUI)
    mq.imgui.init('ChatConfigGUI', ChatWin.Config_GUI)
    mq.imgui.init('EditGUI', ChatWin.Edit_GUI)
    -- initialize the console
    if console == nil then
        console = ImGui.ConsoleWidget.new("Chat##Console")
    end
end

local function loop()
    while ChatWin.SHOW do
        mq.delay(1)
        mq.doevents()
    end
end

loadSettings()
BuildEvents()
init()
loop()