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
local useTheme, timeStamps = false, true
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
        if not ChatWin.Settings.Channels[channelID]['Scale'] then ChatWin.Settings.Channels[channelID]['Scale'] = 1.0 end
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
    writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
    if ChatWin.Settings['Colors'] then
        color_header = ChatWin.Settings['Colors']['color_header']
        color_headHov = ChatWin.Settings['Colors']['color_headHov']
        color_headAct = ChatWin.Settings['Colors']['color_headAct']
        color_WinBg = ChatWin.Settings['Colors']['color_WinBg']
        useTheme = true
        else
        useTheme = false
        -- ChatWin.Settings['Colors'] = {}
        -- ChatWin.Settings['Colors']['color_WinBg']     =     color_header
        -- ChatWin.Settings['Colors']['color_header']    =     color_headHov
        -- ChatWin.Settings['Colors']['color_headHov']   =     color_headAct
        -- ChatWin.Settings['Colors']['color_headAct']   =     color_WinBg
        -- writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
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
    if ChatWin.Consoles[channelID] then
        local txtBuffer = ChatWin.Consoles[channelID].txtBuffer
        local colorVec = eventDetails.Filters[0].color or {1,1,1,1}
        if timeStamps then
            local tStamp = mq.TLO.Time.Time24()
            line = string.format("%s %s",tStamp,line)
        end
        if txtBuffer then
            -- for eID, eData in pairs(eventDetails.Filters) do
            for fID, fData in pairs(eventDetails.Filters) do
                if fID > 0 then
                    local fString = fData.filterString
                    if string.find(line, fString) then
                        colorVec = fData.color
                    end
                end
                -- end
            end
            if timestamps then
                local tStamp = mq.TLO.Time.Time24()
                line = string.format("%s %s",tStamp,line)
            end
            local i = getNextID(txtBuffer)
            -- Convert RGB vector to ImGui color code
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
function ChatWin.GUI()
    if not ChatWin.openGUI then return end
    local windowName = 'My Chat##'..myName
    ImGui.SetNextWindowSize(ImVec2(640, 480), ImGuiCond.FirstUseEver)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(1, 0));
    if useTheme then
        ImGui.PushStyleColor(ImGuiCol.WindowBg,color_WinBg[1],color_WinBg[2],color_WinBg[3],color_WinBg[4])
        ImGui.PushStyleColor(ImGuiCol.Header, color_header[1],color_header[2],color_header[3],color_header[4])
        ImGui.PushStyleColor(ImGuiCol.HeaderHovered,color_headHov[1],color_headHov[2],color_headHov[3],color_headHov[4])
        ImGui.PushStyleColor(ImGuiCol.HeaderActive,color_headAct[1],color_headAct[2],color_headAct[3],color_headAct[4])
        ImGui.PushStyleColor(ImGuiCol.TableRowBg, color_WinBg[1],color_WinBg[2],color_WinBg[3],color_WinBg[4])
        ImGui.PushStyleColor(ImGuiCol.TableRowBgAlt,color_WinBg[1],color_WinBg[2],color_WinBg[3],color_WinBg[4])
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
    if useTheme then ImGui.PopStyleColor(6) end
    ImGui.End()
    ImGui.PopStyleVar()
end
-------------------------------- Configure Windows and Events GUI ---------------------------
local editChanID, editEventID, lastID, lastChan = 0, 0, 0, 0
local tempFilterStrings, tempEventStrings, tempChanColors, tempFiltColors = {}, {}, {}, {}
local newEvent, newFilter = false, false
function ChatWin.AddChannel(editChanID, isNewChannel)
    local tmpName = 'NewChan'
    local tmpString = 'NewString'
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
        elseif isNewChannel then
        channelData = {
            [editChanID] = {
                ['enabled'] = false,
                ['Name'] = 'new',
                ['Scale'] = 1.0,
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
        tmpName = tempEventStrings[editChanID].Name
        tmpName,_ = ImGui.InputText("Channel Name##ChanName" .. editChanID, tmpName, 256)
        if tempEventStrings[editChanID].Name ~= tmpName then tempEventStrings[editChanID].Name = tmpName end
        lastChan = lastChan + 1
    else ImGui.Text('') end
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
    ImGui.BeginChild("Details")
    ------------------------------ table -------------------------------------
    if not channelData[editChanID] then ImGui.EndChild() return end
    for eventID, eventDetails in pairs(channelData[editChanID].Events) do
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
            tempChanColors[editChanID][eventID] = ImGui.ColorEdit4("##Color" .. bufferKey, tempChanColors[editChanID][eventID])
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
                    filterData['color'] = ImGui.ColorEdit4("##Color_" .. filterID, tmpColor)
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
                        ImGui.ColorEdit4("##Color" .. bufferKey, eventDetails.Filters[0].color)
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
    open, ChatWin.openConfigGUI = ImGui.Begin("Event Configuration", open, bit32.bor(ImGuiWindowFlags.None, ImGuiWindowFlags.NoCollapse))
    if not ChatWin.openConfigGUI then
        ChatWin.openConfigGUI = false
        open = false
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
    buildConfig()
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
        addChannel = false
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