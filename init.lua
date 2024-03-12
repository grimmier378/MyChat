--[[
        Basic Chat Window. 
        Customizable channels and colors.
        reads settings from MyChat_Settings.ini in the MQ\Config dir. 
        if the file is missing we use some defaults. 
        you can customize any event string you would like and create a channel for it that you can turn on of off at any time. 

        example MyChat_Settings ini.
            [Events_Channels]
            Ooc=#*#say#*# out of character,#*#=out of character=dkgreen
            Shout=#*#shout#*#,#*#=shout=red
            Auction=#*#auction#*#,#*#=auction=dkgreen
            XP=#*#gained#*#experience!#*#=experience!=dkyellow
            AA=#*#gained an ability point#*#=an ability point=orange
            Group=#*#tells the group#*#=group,=teal
            Guild=#*#tells the guild#*#=guild,=green
            Tells=#*#tells you,#*#=tells you,=magenta
            Say=#*#says,#*#=says,=white

            Layout:
            [ChannelName]=[EventString]=[FilterString]=[Color]
            ChannelName is what shows in your menu to toggle on or off. anything you want to name it.
            EventString is the search pattern that will trigger the event to write to console.
            FilterString is used in the lua parse to determine what channel the line belongs to. key search word to match to channel.
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
local localEcho = false
local resetPosition = false
local setFocus = false
local commandBuffer = ''

local ChatWin = {
    SHOW = true,
    openGUI = true,
    shouldDrawGUI = true,
    SettingsFile = string.format('%s/MyChat_Settings.ini', mq.configDir),
    -- Channels
    Channels = {},

    winFlags = bit32.bor(ImGuiWindowFlags.MenuBar)
}
local DefaultChannels = {
    Say = {
        eventString = "#*#says,#*#",
        filterString = "says,",
        color = "white",
        enabled = true
    },
    Shout = {
        eventString = "#*#shout#*#,#*#",
        filterString = "shouts,",
        color = "red",
        enabled = true
    },
    Tells = {
        eventString = "#*#tells you,#*#",
        filterString = "tells you,",
        color = "magenta",
        enabled = true
    },
    Group = {
        eventString = "#*#tells the group#*",
        filterString = "tells the group,",
        color = "teal",
        enabled = true
    },
    Guild = {
        eventString = "#*#tells the guild#*#",
        filterString = "tells the guild,",
        color = "green",
        enabled = true
    },
    OOC = {
        eventString = "#*#say#*# out of character,",
        filterString = "out of character,",
        color = "dkgreen",
        enabled = true
    },
    Auction = {
        eventString = "#*#auction#*#,#*#",
        filterString = "auctions,",
        color = "dkgreen",
        enabled = true
    }
}
local myName = mq.TLO.Me.DisplayName() or ''
--Helper Functioons
local function split(input, sep)
    if sep == nil then
        sep = "="
    end
    local t = {}
    local pos = 1
    while true do
        local s, e = string.find(input, sep, pos)
        if s == nil then
            table.insert(t, string.sub(input, pos))
            break
        end
        table.insert(t, string.sub(input, pos, s - 1))
        pos = e + 1
    end
    return t
end
function File_Exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end
local function loadSettings()
    if not File_Exists(ChatWin.SettingsFile) then
        -- Write default settings to the file
        for option, data in pairs(DefaultChannels) do
            local eventString = data.eventString
            local filterString = data.filterString
            local color = data.color
            mq.cmdf('/ini "%s" "%s" "%s=%s=%s" "%s"', ChatWin.SettingsFile, 'Events_Channels', option, eventString, filterString, color)
        end
    end
    -- Load settings from the INI file
    local iniSettings = mq.TLO.Ini.File(ChatWin.SettingsFile).Section('Events_Channels')
    local keyCount = iniSettings.Key.Count()
    for i = 1, keyCount do
        local key = iniSettings.Key.KeyAtIndex(i)()
        local value = iniSettings.Key(key).Value()
        if key ~= nil and value ~= nil then
            local parts = split(value)
            local eventString = parts[1]
            local filterString = parts[2]
            local color = parts[3]
            ChatWin.Channels[key] = {
                eventString = eventString,
                filterString = filterString,
                color = color,
                enabled = true
            }
        end
    end
end
local function BuildEvents()
    for channel, eventData in pairs(ChatWin.Channels) do
        local eventName = string.format("echo_%s_chat", channel)
        local eventString = eventData.eventString
        mq.event(eventName, eventString, ChatWin.EventChat)
    end
    mq.event('event_echo_tell_chat', '#*#You told #1#,#*#', ChatWin.EventChat)
    mq.event('event_echo_party_chat', '#*#You tell your party,#*#', ChatWin.EventChat)
    mq.event('event_echo_guild_chat', '#*#You say to your guild,#*#', ChatWin.EventChat)
    mq.event('event_echo_say_chat', '#*#You say,#*#' ,ChatWin.EventChat)
end
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
        end
    else
        color = '\aw'
    end
    return color
end
function ChatWin.EventChat(line)
    local function output(line)
        if console ~= nil then
            console:AppendText(line)
        end
    end
    local time = mq.TLO.Time()
    local pref = 'NULL'  -- Default prefix
        for channel, settings in pairs(ChatWin.Channels) do
            if settings.enabled and string.find(line, settings.filterString) then
                -- Update the prefix based on the matched channel's color
                pref = parseColor(settings.color)
                if (string.match(line, "^You") or string.match(line, "^"..myName)) and not string.find(line,'^You have gained') then pref = '\a-w' end
                break  -- Exit the loop after finding the first matching channel
            end
            if settings.enabled and (string.match(line, 'You tell your party,') and channel == 'Group') then pref = '\a-w' end
            if settings.enabled and (string.match(line, 'You tell your guild,') and channel == 'Guild') then pref = '\a-w' end
            if settings.enabled and (string.match(line, 'You told') and channel == 'Tells') then pref = '\a-w' end
            if settings.enabled and (string.match(line, 'You say,') and channel == 'Say') then pref = '\a-w' end
        end
    if pref == 'NULL' then return end
    -- Construct the formatted output line only if a matching channel is enabled
    line = string.format("%s[%s] %s", pref,time,line)
    output(line)
end
function ChatWin.GUI()
    if not ChatWin.openGUI then return end
    local windowName = 'My Chat##'..mq.TLO.Me.DisplayName()
    ImGui.SetNextWindowSize(ImVec2(640, 240), resetPosition and ImGuiCond.FirstUseEver or ImGuiCond.Once)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(1, 0));
    ChatWin.openGUI, ChatWin.shouldDrawGUI = ImGui.Begin(windowName, ChatWin.openGUI, ChatWin.winFlags)
    ImGui.PopStyleVar()
    if not ChatWin.openGUI then
        ImGui.End()
        ChatWin.shouldDrawGUI = false
        return
    end
    -- Main menu bar
    if ImGui.BeginMenuBar() then
        if ImGui.BeginMenu('Channels') then
            for channel, settings in pairs(ChatWin.Channels) do
                local enabled = ChatWin.Channels[channel].enabled
                if ImGui.MenuItem(channel, '', enabled) then
                    ChatWin.Channels[channel].enabled = not enabled
                end
            end
            ImGui.Separator()
            if ImGui.BeginMenu('Options') then
                _, console.autoScroll = ImGui.MenuItem('Auto-scroll', nil, console.autoScroll)
                _, LocalEcho = ImGui.MenuItem('Local echo', nil, LocalEcho)
                ImGui.Separator()
                if ImGui.MenuItem('Reset Position') then
                    resetPosition = true
                end
                ImGui.Separator()
                if ImGui.MenuItem('Clear Console') then
                    console:Clear()
                end
                if ImGui.MenuItem('Exit') then
                    ChatWin.SHOW = false
                end
                ImGui.Spacing()
                ImGui.EndMenu()
            end
            ImGui.EndMenu()
        end
        ImGui.EndMenuBar()
    end
    -- End of menu bar
    local footerHeight = ImGui.GetStyle().ItemSpacing.y + ImGui.GetFrameHeightWithSpacing()
    if ImGui.BeginPopupContextWindow() then
        if ImGui.Selectable('Clear') then
            console:Clear()
        end
        ImGui.EndPopup()
    end
    -- Reduce spacing so everything fits snugly together
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))
    local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
    contentSizeY = contentSizeY - footerHeight
    console:Render(ImVec2(contentSizeX,contentSizeY))
    -- Command line
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(2, 4))
    ImGui.Separator()
    local textFlags = bit32.bor(0,
        ImGuiInputTextFlags.EnterReturnsTrue
        -- not implemented yet
        -- ImGuiInputTextFlags.CallbackCompletion,
        -- ImGuiInputTextFlags.CallbackHistory
    )
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 6)
    ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 4)
    ImGui.PushItemWidth(ImGui.GetContentRegionAvailVec().x)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, ImVec4(0, 0, 0, 0))
    ImGui.PushFont(ImGui.ConsoleFont)
    local accept = false
    commandBuffer, accept = ImGui.InputText('##Input', commandBuffer, textFlags)
    ImGui.PopFont()
    ImGui.PopStyleColor()
    ImGui.PopStyleVar(2)
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
    --------------------
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
