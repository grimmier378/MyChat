--[[
        Basic Chat Window. 
        Customizable channels and colors.
        reads settings from MyChat_Settings.ini in the MQ\Config dir. 
        if the file is missing we use some defaults. 
        you can customize any event string you would like and create a channel for it that you can turn on of off at any time. 

        example MyChat_Settings.lua
        return {
            ['Channels'] = {
                ['Say'] = {
                    ['echoFilterString'] = '^You',
                    ['color'] = 'white',
                    ['echoColor'] = 'grey',
                    ['enabled'] = true,
                    ['resetPosition'] = false,
                    ['setFocus'] = false,
                    ['commandBuffer'] = '',
                    ['eventString'] = {
                        [1] = '#*#says,#*#',
                    },
                    ['filterString'] = 'says,',
                    ['echoEventString'] = {
                        [1] = '#*#You say, \'#*#',
                    },
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
    Settings = {
    -- Channels
    Channels = {},
    },
    -- Consoles
    Consoles = {},
    -- Flags
    tabFlags = bit32.bor(ImGuiTabBarFlags.Reorderable, ImGuiTabBarFlags.TabListPopupButton),
    winFlags = bit32.bor(ImGuiWindowFlags.MenuBar)
}

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
    if ChatWin.Consoles[channel].console == nil then
        ChatWin.Consoles[channel].console = ImGui.ConsoleWidget.new(channel.."##Console")
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
    for channel, channelData in pairs(ChatWin.Settings.Channels) do
        if not ChatWin.Consoles[channel] then
            ChatWin.Consoles[channel] = {}
        end
        SetUpConsoles(channel)
    end
end
local eventNames = {}
local function BuildEvents()
    eventNames = {}
    for channel, channelData in pairs(ChatWin.Settings.Channels) do
        for eventId, eventDetails in pairs(channelData.Events) do
            if eventDetails.eventString then
                local eventName = string.format("event_%s_%d", channel, eventId)
                mq.event(eventName, eventDetails.eventString, function(line) ChatWin.EventChat(channel, eventName, line) end)
                -- Store event details for direct access, assuming we need it elsewhere
                eventNames[eventName] = eventDetails
            end
        end
    end
end
function ChatWin.EventChat(channel, eventName, line)
    local eventDetails = eventNames[eventName]
    if not eventDetails then return end  -- Exit if event details are not found

    local color = eventDetails.color  -- Retrieve color directly from event details
    local time = mq.TLO.Time()

    -- Format and output the line
    local formattedLine = string.format("%s[%s] %s", parseColor(color), time, line)
    if ChatWin.Consoles[channel] and ChatWin.Consoles[channel].console then
        ChatWin.Consoles[channel].console:AppendText(formattedLine)
    end
    if console ~= nil then console:AppendText(formattedLine) end
end

function ChatWin.GUI()
    if not ChatWin.openGUI then return end
    local myName = mq.TLO.Me.DisplayName() or ''
    local windowName = 'My Chat##'..myName
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
                    for channel, settings in pairs(ChatWin.Settings.Channels) do
                        local enabled = ChatWin.Settings.Channels[channel].enabled
                        if ImGui.MenuItem(channel, '', enabled) then
                            ChatWin.Settings.Channels[channel].enabled = not enabled
                            writeSettings(ChatWin.SettingsFile, ChatWin.Settings)
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
            for channel, data in pairs(ChatWin.Settings.Channels) do
                if ChatWin.Settings.Channels[channel].enabled then
                    if ImGui.BeginTabItem(channel) then
                        local footerHeight = 30
                        local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
                        contentSizeY = contentSizeY - footerHeight
                        if ImGui.BeginPopupContextWindow() then
                            if ImGui.Selectable('Clear') then
                                ChatWin.Consoles[channel].console:Clear()
                            end
                            ImGui.EndPopup()
                        end
                        ChatWin.Consoles[channel].console:Render(ImVec2(contentSizeX,contentSizeY))
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
