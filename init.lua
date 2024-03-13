--[[
        Basic Chat Window. 
        Customizable channels and colors.
        reads settings from MyChat_Settings.ini in the MQ\Config dir. 
        if the file is missing we use some defaults. 
        you can customize any event string you would like and create a channel for it that you can turn on of off at any time. 

        example MyChat_Settings.lua
        return {
            Channels = {
                Auction = {
                    eventString = "#*#auctions,#*#",
                    filterString = "auctions,",
                    echoEventString = "#*#You auction,#*#",
                    echoFilterString = "You auction,",
                    color = "dkgreen",
                    echoColor = "grey",
                    enabled = true
                },
                Tells = {
                    eventString = "#*#tells you,#*#",
                    filterString = "tells you,",
                    color = "magenta",
                    echoEventString = "#*#You told #1#,#*#",
                    echoFilterString = "^You", -- the ^You searches for You at the start of the line.
                    echoColor = "grey",
                    enabled = true
                },
            },
        }

            Layout:
            
            ChannelName is what shows in your menu to toggle on or off. anything you want to name it.
            EventString is the search pattern that will trigger the event to write to console.
            EchoEventString is the search patern for you talking in this channel
                alternativly you can use the Echo settings as 2ndary Events for the same channel
            FilterString further filter the chat line after channel is decided.
                This can be useful for auction channels where you only want to see the spam for certain items. set the item name you want to find in the filter.
            EchoFilterString is the same as above but for you talking.
            EchoColor is the color for echos on that channel.
            Color what color do you want that channels lines to be?
                valid colors 
                    green           dkgreen
                    red             dkred
                    teal            dkteal
                    orange          dkorange
                    magenta         dkmagenta
                    purple          dkpurple
                    yellow          dkyellow
                    blue            dkblue
                    white           grey
                                    black
]]

local mq = require('mq')
local ImGui = require('ImGui')
---@type ConsoleWidget
local console = nil
local resetPosition = false
local setFocus = false
local commandBuffer = ''

local ChatWin = {
    SHOW = true,
    openGUI = true,
    SettingsFile = string.format('%s/MyChat_Settings.lua', mq.configDir),
    -- Channels
    Channels = {},

    winFlags = bit32.bor(ImGuiWindowFlags.MenuBar)
}
local DefaultChannels = {
    ['Auction'] = {
        eventString = {"#*#auctions,#*#"},
        filterString = "auctions,",
        echoEventString = {"#*#You auction,#*#"},
        echoFilterString = "^You,",
        color = "dkgreen",
        echoColor = "grey",
        enabled = true
    },
    ['Tells'] = {
        eventString = {"#*#tells you,#*#"},
        filterString = "tells you,",
        color = "magenta",
        echoEventString = {"#*#You told #1#,#*#"},
        echoFilterString = "^You",
        echoColor = "grey",
        enabled = true
    },
    ['OOC'] = {
        eventString = {"#*#say#*# out of character,#*#"},
        filterString = "out of character,",
        color = "dkgreen",
        echoEventString = {"#*#You say out of character,#*#"},
        echoFilterString = "^You",
        echoColor = "grey",
        enabled = true
    },
    ['Raid'] = {
        eventString = {"#*#tells the raid#*#"},
        filterString = {"tells the raid,"},
        color = "dkteal",
        echoEventString = {"#You tell your raid,#*#"},
        echoFilterString = "^You",
        echoColor = "grey",
        enabled = true
    },
    ['Guild'] = {
        eventString = {"#*#tells the guild#*#"},
        filterString = "tells the guild,",
        color = "green",
        echoEventString = {"#*#You say to your guild, '#*#"},
        echoFilterString = "^You",
        echoColor = "grey",
        enabled = true
    },
    ['Group'] = {
        eventString = {"#*#tells the group#*#"},
        filterString = "tells the group,",
        color = "teal",
        echoEventString = {"#*#You tell your party, '#*#"},
        echoFilterString = "^You",
        echoColor = "grey",
        enabled = true
    },
    ['Say'] = {
        eventString = {"#*#says,#*#"},
        filterString = "says,",
        color = "white",
        echoEventString = {"#*#You say, '#*#"},
        echoFilterString = "^You",
        echoColor = "grey",
        enabled = true
    },
    ['Shout'] = {
        eventString = {"#*#shouts,#*#"},
        filterString = "shouts,",
        color = "red",
        echoEventString = {"#*#You shout, '#*#"},
        echoFilterString = "^You",
        echoColor = "grey",
        enabled = true
    },
}

local myName = mq.TLO.Me.DisplayName() or ''
--Helper Functioons
local function parseColor(color)
    if color then
        color = string.lower(color)
        if color == 'green' then color = '\ag'
            elseif color == 'red' then color = '\ar'
            elseif color == 'teal' then color = '\at'
            elseif color == 'orange' then color = '\ao'
            elseif color == 'magenta' then color = '\am'
            elseif color == 'purple' then color = '\ap'
            elseif color == 'yellow' then color = '\ay'
            elseif color == 'blue' then color = '\au'
            elseif color == 'white' then color = '\aw'
            elseif color == 'black' then color = '\ab'
            elseif color == 'dkgreen' then color = '\a-g'
            elseif color == 'dkred' then color = '\a-r'
            elseif color == 'dkteal' then color = '\a-t'
            elseif color == 'dkorange' then color = '\a-o'
            elseif color == 'dkmagenta' then color = '\a-m'
            elseif color == 'dkpurple' then color = '\a-p'
            elseif color == 'dkyellow' then color = '\a-y'
            elseif color == 'dkblue' then color = '\a-u'
            elseif color == 'grey' then color = '\a-w'
        else
            color = '\aw'
        end
    else
        color = '\aw'
    end
    return color
end
function File_Exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

local function SetUpConsoles(channel)
    if ChatWin.Channels[channel].console == nil then
        ChatWin.Channels[channel].console = ImGui.ConsoleWidget.new(channel.."##Console")
    end
end

local function writeStringArray(file, key, array)
    file:write(string.format("\t\t\t%s = {", key))
    for i, value in ipairs(array) do
        file:write(string.format("\"%s\"", value))
        if i ~= #array then
            file:write(", ")
        end
    end
    file:write("},\n")
end

local function writeSettings(file, settings)
    mq.pickle(file, settings)
end

local function loadSettings()
    -- if not File_Exists(ChatWin.SettingsFile) then
    --     local file = io.open(ChatWin.SettingsFile, "w")
    --     if file then
    --         file:write("return {\n")
    --         file:write("\tChannels = {\n")
    --         for option, data in pairs(DefaultChannels) do
    --             file:write(string.format("\t\t['%s'] = {\n", option))
    --             writeStringArray(file, "eventString", data.eventString)
    --             file:write(string.format("\t\t\tfilterString = \"%s\",\n", data.filterString))
    --             file:write(string.format("\t\t\tcolor = \"%s\",\n", data.color))
    --             writeStringArray(file, "echoEventString", data.echoEventString)
    --             file:write(string.format("\t\t\techoFilterString = \"%s\",\n", data.echoFilterString))
    --             file:write(string.format("\t\t\techoColor = \"%s\",\n", data.echoColor))
    --             file:write("\t\t\tenabled = true\n")
    --             file:write("\t\t},\n")
    --         end
    --         file:write("\t}\n")
    --         file:write("}\n")
    --         file:close()
    --     end
    -- end
    if not File_Exists(ChatWin.SettingsFile) then
        mq.pickle(ChatWin.SettingsFile, {Channels = DefaultChannels})
    end

    -- Load settings from the Lua config file
    local settings = dofile(ChatWin.SettingsFile)
    for option, data in pairs(settings.Channels) do
        ChatWin.Channels[option] = {
            eventString = data.eventString or 'NULL',
            filterString = data.filterString or 'NULL',
            color = data.color,
            echoEventString = data.echoEventString or 'NULL',
            echoFilterString = data.echoFilterString or 'NULL',
            echoColor = data.echoColor or 'NULL',
            enabled = data.enabled or true,
            ---@type ConsoleWidget
            console = nil,
            resetPosition = false,
            setFocus = false,
            commandBuffer = ''
        }
    -- Enable the consoles for each channel.
    SetUpConsoles(option)
    end
end
local function BuildEvents()
    for channel, eventData in pairs(ChatWin.Channels) do
        local Strings = eventData.eventString
        local echoStrings = eventData.echoEventString
        for i, string in pairs(Strings) do
            if string ~= 'NULL' then
                local eventName = string.format("%s_chat%s", channel,i)
                mq.event(eventName, string, function(line) ChatWin.EventChat(channel, line) end)
            end
        end
        for i, eString in pairs(echoStrings) do
            if eString ~= 'NULL' then
                local eventName = string.format("%s_chat%s", channel,i)
                mq.event(eventName, eString, function(line) ChatWin.EventChat(channel, line) end)
            end
        end
    end
end

function ChatWin.EventChat(channel, line)
    local function output(line, channel)
        if channel then
            if ChatWin.Channels[channel].console ~= nil then
                ChatWin.Channels[channel].console:AppendText(line)
            end
        end
        if console ~= nil then
            console:AppendText(line)
        end
    end
    local time = mq.TLO.Time()
    local pref = 'NULL'  -- Default prefix
    local settings = ChatWin.Channels[channel]
    if string.find(line, settings.echoFilterString) then
        pref = parseColor(settings.echoColor)
        --printf("Channel: %s Filter: %s", channel, settings.echoFilterString)
    elseif string.find(line, settings.filterString) then
        pref = parseColor(settings.color)
        --printf("Channel: %s Filter: %s", channel, settings.filterString)
    end
    if pref == 'NULL' then return end
    -- Construct the formatted output line only if a matching channel is enabled
    line = string.format("%s[%s] %s", pref, time, line)
    output(line, channel)
end

function ChatWin.GUI()
    if not ChatWin.openGUI then return end

    local windowName = 'My Chat##'..mq.TLO.Me.DisplayName()
    ImGui.SetNextWindowSize(ImVec2(640, 480), ImGuiCond.FirstUseEver)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(1, 0));

    if ImGui.Begin(windowName, ChatWin.openGUI, ChatWin.winFlags) then
        -- Main menu bar
        if ImGui.BeginMenuBar() then
            if ImGui.BeginMenu('Options') then
                _, console.autoScroll = ImGui.MenuItem('Auto-scroll', nil, console.autoScroll)
                _, LocalEcho = ImGui.MenuItem('Local echo', nil, LocalEcho)
                ImGui.Separator()
                if ImGui.BeginMenu('Channels') then
                    for channel, settings in pairs(ChatWin.Channels) do
                        local enabled = ChatWin.Channels[channel].enabled
                        if ImGui.MenuItem(channel, '', enabled) then
                            ChatWin.Channels[channel].enabled = not enabled
                        end
                    end

                    ImGui.EndMenu()
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
        if ImGui.BeginTabBar('Channels') then
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
            for channel, data in pairs(ChatWin.Channels) do
                if ChatWin.Channels[channel].enabled then
                    if ImGui.BeginTabItem(channel) then
                        local footerHeight = 30
                        local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
                        contentSizeY = contentSizeY - footerHeight
                        if ImGui.BeginPopupContextWindow() then
                            if ImGui.Selectable('Clear') then
                                ChatWin.Channels[channel].console:Clear()
                            end
                            ImGui.EndPopup()
                        end
                        ChatWin.Channels[channel].console:Render(ImVec2(contentSizeX,contentSizeY))
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
            ImGuiInputTextFlags.EnterReturnsTrue
            -- not implemented yet
            -- ImGuiInputTextFlags.CallbackCompletion,
            -- ImGuiInputTextFlags.CallbackHistory
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
    ImGui.End()
    ImGui.PopStyleVar()
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
        ChatWin.Channels[channel].console:AppendText(IM_COL32(128, 128, 128), "> %s", text)
    end
    -- todo: implement history
    if string.len(text) > 0 then
        text = ChatWin.StringTrim(text)
        if text == 'clear' then
            ChatWin.Channels[channel].console:Clear()
            elseif string.sub(text, 1, 1) == '/' then
            mq.cmdf("%s", text)
            else
            ChatWin.Channels[channel].console:AppendText(IM_COL32(255, 0, 0), "Unknown command: '%s'", text)
        end
    end
end
function ChatWin.EventFunc(text)
    if console ~= nil then
        console:AppendText(text)
    end
end
local function init()
    mq.imgui.init('lootItemsGUI', ChatWin.GUI)
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
