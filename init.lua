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
local tempSettings = {}
local color_header = {0,0,0,1}
local color_headHov = {0.05,0.05,0.05,0.9}
local color_headAct = {0.05,0.05,0.05,0.9}
local color_WinBg = {0,0,0,1}
local ChatWin = {
    SHOW = true,
    openGUI = true,
    openConfigGUI = false,
    SettingsFile = string.format('%s/MyChat_%s_%s.lua', mq.configDir, serverName, myName),
    Settings = {
        -- Channels
        Channels = {},
    },
    -- Consoles
    Consoles = {},
    -- Flags
    tabFlags = bit32.bor(ImGuiTabBarFlags.Reorderable, ImGuiTabBarFlags.TabListPopupButton),
    winFlags = bit32.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoScrollbar)
}
--Helper Functioons
function File_Exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end
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
    -- Ensure each channel's console widget is initialized
    for channelID, channelData in pairs(ChatWin.Settings.Channels) do
        if not ChatWin.Consoles[channelID] then
            ChatWin.Consoles[channelID] = {}
        end
        SetUpConsoles(channelID)
    end
    if ChatWin.Settings['Colors'] then
        color_header = ChatWin.Settings['Colors']['color_header']
        color_headHov = ChatWin.Settings['Colors']['color_headHov']
        color_headAct = ChatWin.Settings['Colors']['color_headAct']
        color_WinBg = ChatWin.Settings['Colors']['color_WinBg']
    else
        ChatWin.Settings['Colors'] = {}
        ChatWin.Settings['Colors']['color_WinBg']     =     color_header
        ChatWin.Settings['Colors']['color_header']    =     color_headHov
        ChatWin.Settings['Colors']['color_headHov']   =     color_headAct
        ChatWin.Settings['Colors']['color_headAct']   =     color_WinBg
        writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
    end
    tempSettings = ChatWin.Settings

end
local eventNames = {}
local function BuildEvents()
    eventNames = {}
    for channelID, channelData in pairs(ChatWin.Settings.Channels) do
        for eventId, eventDetails in pairs(channelData.Events) do
            if eventDetails.eventString then
                local eventName = string.format("event_%s_%d", channelID, eventId)
                mq.event(eventName, eventDetails.eventString, function(line) ChatWin.EventChat(channelID, eventName, line) end)
                -- Store event details for direct access, assuming we need it elsewhere
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
    --print(eventName)
        mq.unevent(eventName)
    end
    eventNames = {}

    loadSettings()
    BuildEvents()
end
function ChatWin.EventChat(channelID, eventName, line)
    local eventDetails = eventNames[eventName]
    if not eventDetails then return end
    local colorVec = eventDetails.color
    
    if ChatWin.Consoles[channelID] then
        local txtBuffer = ChatWin.Consoles[channelID].txtBuffer
        if txtBuffer then
            local i = getNextID(txtBuffer)
            -- Convert RGB vector to ImGui color code
            local colorCode = IM_COL32(colorVec[1] * 255, colorVec[2] * 255, colorVec[3] * 255, 255)
            -- write channel console
            if ChatWin.Consoles[channelID].console then
                ChatWin.Consoles[channelID].console:AppendText(colorCode, line)
            end
            -- write main console
            console:AppendText(colorCode,line)
            -- ZOOM Console hack
            if txtBuffer[i-1].text == '' then i = i-1 end
            -- Add the new line to the buffer
            txtBuffer[i] = {
                color = colorVec,
                text = line
            }
            -- cleanup zoom buffer
            -- Check if the buffer exceeds 1000 lines
            local bufferLength = #txtBuffer
            if bufferLength > 1000 then
                -- Remove excess lines
                for j = 1, bufferLength - 1000 do
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
-- Variable to track last scroll position
function ChatWin.GUI()


    if not ChatWin.openGUI then return end
    local windowName = 'My Chat##'..myName
    ImGui.SetNextWindowSize(ImVec2(640, 480), ImGuiCond.FirstUseEver)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(1, 0));
    ImGui.PushStyleColor(ImGuiCol.WindowBg,color_WinBg[1],color_WinBg[2],color_WinBg[3],color_WinBg[4])
    ImGui.PushStyleColor(ImGuiCol.Header, color_header[1],color_header[2],color_header[3],color_header[4])
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered,color_headHov[1],color_headHov[2],color_headHov[3],color_headHov[4])
    ImGui.PushStyleColor(ImGuiCol.HeaderActive,color_headAct[1],color_headAct[2],color_headAct[3],color_headAct[4])
    ImGui.PushStyleColor(ImGuiCol.TableRowBg, color_WinBg[1],color_WinBg[2],color_WinBg[3],color_WinBg[4])
    ImGui.PushStyleColor(ImGuiCol.TableRowBgAlt,color_WinBg[1],color_WinBg[2],color_WinBg[3],color_WinBg[4])
    if ImGui.Begin(windowName, ChatWin.openGUI, ChatWin.winFlags) then
        -- Main menu bar
        if ImGui.BeginMenuBar() then
            if ImGui.BeginMenu('Options') then
                _, console.autoScroll = ImGui.MenuItem('Auto-scroll', nil, console.autoScroll)
                _, LocalEcho = ImGui.MenuItem('Local echo', nil, LocalEcho)
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
                    if ImGui.BeginTabItem(name) then
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
                            ImGui.SetWindowFontScale(1.5)
                            for line, data in pairs(ChatWin.Consoles[channelID].txtBuffer) do
                                local color = ""
                                ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(data.color[1], data.color[2], data.color[3], data.color[4]))
                                if ImGui.Selectable("##selectable" .. line, false, ImGuiSelectableFlags.None) then
                                    -- ImGui.LogToClipboard()
                                    -- ImGui.LogText(data.text)
                                    -- ImGui.LogFinish()
                                end
                                ImGui.SameLine()
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
    ImGui.PopStyleColor(6)
    ImGui.End()
    ImGui.PopStyleVar()
end
-- --- Configure Windows and Events GUI
local lastID = 0
local editChanID = 0
local editEventID = 0
local tempEventStrings = {}
local tempColors = {}
local newEvent = false
local lastChan = 0
function ChatWin.AddChannel(editChanID, isNewChannel)
    if not tempEventStrings[editChanID] then tempEventStrings[editChanID] = {} end
    if not tempColors[editChanID] then tempColors[editChanID] = {} end
        if ImGui.BeginTable("Channel Events", 4, bit32.bor(ImGuiTableFlags.None, ImGuiTableFlags.Resizable, ImGuiTableFlags.NoHostExtendX,ImGui.GetContentRegionAvail())) then
        ImGui.TableSetupColumn("Channel", ImGuiTableColumnFlags.WidthAlwaysAutoResize, 100)
        ImGui.TableSetupColumn("EventString", ImGuiTableColumnFlags.WidthStretch, 150)
        ImGui.TableSetupColumn("Color", ImGuiTableColumnFlags.WidthAlwaysAutoResize)
        ImGui.TableSetupColumn("Delete##", ImGuiTableColumnFlags.WidthFixed, 30)
        ImGui.TableHeadersRow()
        local tmpName = 'NewChan'
        local tmpString = 'NewString'
        local channelData = {}
        if tempSettings.Channels[editChanID] then
            channelData = tempSettings.Channels
            -- print(channelData[editChanID].Name)
        elseif isNewChannel then
            channelData = {
                [editChanID] = {
                    ['enabled'] = false,
                    ['Name'] = 'new',
                    ['Events'] = {
                        [1] = {
                            ['color'] = {
                                [1] = 1,
                                [2] = 1,
                                [3] = 1,
                                [4] = 1,
                            },
                            ['eventString'] = 'new',
                        },
                        [2] = {
                            ['color'] = {
                                [1] = 1,
                                [2] = 1,
                                [3] = 1,
                                [4] = 1,
                            },
                            ['eventString'] = 'new',
                        },
                    }
                }
            }
            tempSettings.Channels[editChanID] = channelData[editChanID]
        end
        if newEvent then
            local maxEventId = getNextID(channelData[editChanID].Events)
            print(maxEventId)
            channelData[editChanID]['Events'][maxEventId] = {
                ['color'] = {
                    [1] = 1,
                    [2] = 1,
                    [3] = 1,
                    [4] = 1,
                },
                ['eventString'] = 'new',
            }
            newEvent = false
        end
        for eventId, eventDetails in pairs(channelData[editChanID].Events) do
            if not tempEventStrings[editChanID] then channelData[editChanID] = {} end
            if not tempEventStrings[editChanID][editEventID] then tempEventStrings[editChanID][editEventID] = {} end
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            if lastChan == 0 then
                --print(channelData.Name)
                if not tempEventStrings[editChanID].Name then
                    tempEventStrings[editChanID].Name = channelData[editChanID].Name
                end
                tmpName = tempEventStrings[editChanID].Name
                tmpName,_ = ImGui.InputText("##ChanName" .. editChanID, tmpName, 256)
                if tempEventStrings[editChanID].Name ~= tmpName then tempEventStrings[editChanID].Name = tmpName end
                lastChan = lastChan + 1
            else ImGui.Text('') end
            ImGui.TableSetColumnIndex(1)
            if not tempEventStrings[editChanID][eventId] then tempEventStrings[editChanID][eventId] = eventDetails end
            tmpString = tempEventStrings[editChanID][eventId].eventString
            local bufferKey = editChanID .. "_" .. tostring(eventId)
            tmpString = ImGui.InputText("##EventString" .. bufferKey, tmpString, 256)
            if tempEventStrings[editChanID][eventId].eventString ~= tmpString then tempEventStrings[editChanID][eventId].eventString = tmpString end
            --print(tempEventStrings[editChanID][eventId].eventString)
            ImGui.TableSetColumnIndex(2)
            if not tempColors[editChanID][eventId] then
                tempColors[editChanID][eventId] = eventDetails.color or {1.0, 1.0, 1.0, 1.0} -- Default to white with full opacity
            end
            tempColors[editChanID][eventId] = ImGui.ColorEdit4("##Color" .. bufferKey, tempColors[editChanID][eventId])
            ImGui.TableSetColumnIndex(3)
            if ImGui.Button("Delete##" .. bufferKey) then
                -- Delete the event
                tempSettings.Channels[editChanID].Events[eventId] = nil
                tempEventStrings[editChanID][eventId] = nil
                tempColors[editChanID][eventId] = nil
                ResetEvents()
            end
        end
        lastChan = 0
        ImGui.EndTable()
        if ImGui.Button('Add Event Line') then
            newEvent = true
        end
        ImGui.SameLine()
        if ImGui.Button("Delete Channel##" .. editChanID) then
            -- Delete the event
            tempSettings.Channels[editChanID] = nil
            tempEventStrings[editChanID] = nil
            tempColors[editChanID] = nil
            ChatWin.openEditGUI = false
            ChatWin.openConfigGUI = true
            ResetEvents()
        end
        if ImGui.Button('Save') then
            -- Initialize the channel in tempSettings if it doesn't exist
            tempSettings.Channels[editChanID] = tempSettings.Channels[editChanID] or {Events = {}, Name = "New Channel", enabled = true}
            -- Update channel name
            tempSettings.Channels[editChanID].Name = tempEventStrings[editChanID].Name or "New Channel"
            tempSettings.Channels[editChanID].enabled = true  -- Assuming you always want to enable it on save
            -- Prepare to update events
            local channelEvents = tempSettings.Channels[editChanID].Events
            for eventId, eventData in pairs(tempEventStrings[editChanID]) do
                -- Skip 'Name' key used for the channel name
                if eventId ~= 'Name' then
                    -- Ensure we're dealing with actual event data
                    if eventData and eventData.eventString then
                        -- Initialize event in channelEvents if necessary
                        channelEvents[eventId] = channelEvents[eventId] or {color = {1.0, 1.0, 1.0, 1.0}}
                        -- Update event string and color
                        channelEvents[eventId].eventString = eventData.eventString
                        channelEvents[eventId].color = tempColors[editChanID][eventId] or channelEvents[eventId].color
                    end
                end
            end
            ResetEvents()
            ChatWin.openEditGUI = false
            ChatWin.openConfigGUI = true
        end
    end
end
local function buildConfig()
    -- Add a flag to track if a row is marked for deletion
    local markedForDeletion = {}

    if ImGui.BeginTable("Channel Events", 1, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.RowBg, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn("", ImGuiTableColumnFlags.WidthStretch, bit32.bor(ImGui.GetContentRegionAvail(), ImGuiTableColumnFlags.NoHeaderLabel))
        ImGui.TableHeadersRow()
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
                            if not eventDetails.color then
                                eventDetails.color = {1.0, 1.0, 1.0, 1.0} -- Default to white with full opacity
                            end
                            ImGui.ColorEdit4("##Color" .. bufferKey, eventDetails.color)
                        end
                        -- End the table for this channel
                        ImGui.EndTable()
                    end
                end
            end
            -- Update lastID
            lastID = channelID
        end
        ImGui.EndTable()  -- End the main table
    end
end
function ChatWin.Config_GUI(open)
    if not ChatWin.openConfigGUI then return end
    open, ChatWin.openConfigGUI = ImGui.Begin("Event Configuration", open, bit32.bor(ImGuiWindowFlags.None, ImGuiWindowFlags.NoCollapse))
    if not ChatWin.openConfigGUI then
        ChatWin.openConfigGUI = false
        open = false
        ImGui.End()
        return open
    end
    buildConfig()
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
    ImGui.End()
end
function ChatWin.Edit_GUI(open)
    if not ChatWin.openEditGUI then return end
    open, ChatWin.openEditGUI = ImGui.Begin("Channel Editor", open, bit32.bor(ImGuiWindowFlags.None, ImGuiWindowFlags.NoCollapse))
    if not ChatWin.openEditGUI then
        ChatWin.openEditGUI = false
        open = false
        ImGui.End()
        return open
    end
    ChatWin.AddChannel(editChanID, addChannel)
    ImGui.SameLine()
    -- Close Button
    if ImGui.Button('Close') then
        ChatWin.openEditGUI = false
        editChanID = 0
        editEventID = 0
    end
    ImGui.End()
end
function ChatWin.StringTrim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end
function ChatWin.ExecCommand(text)
    if LocalEcho then
        console:AppendText(IM_COL32(128, 128, 128), "> %s", text)
    end
    -- todo: implement history
    if string.len(text) > 0 then
        text = ChatWin.StringTrim(text)
        if text == 'clear' then
            console:Clear()
            elseif string.sub(text, 1, 1) == '/' then
            mq.cmdf("%s", text)
            else
            console:AppendText(IM_COL32(255, 0, 0), "Unknown command: '%s'", text)
        end
    end
end
function ChatWin.ChannelExecCommand(text,channel)
    if LocalEcho then
        ChatWin.Consoles[channel].console:AppendText(IM_COL32(128, 128, 128), "> %s", text)
    end
    -- todo: implement history
    if string.len(text) > 0 then
        text = ChatWin.StringTrim(text)
        if text == 'clear' then
            ChatWin.Consoles[channel].console:Clear()
            elseif string.sub(text, 1, 1) == '/' then
            mq.cmdf("%s", text)
            else
            ChatWin.Consoles[channel].console:AppendText(IM_COL32(255, 0, 0), "Unknown command: '%s'", text)
        end
    end
end
function ChatWin.EventFunc(text)
    if console ~= nil then
        console:AppendText(text)
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