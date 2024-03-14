local mq = require('mq')
local ImGui = require('ImGui')
---@type ConsoleWidget
local console = nil
local resetPosition = false
local setFocus = false
local commandBuffer = ''
local serverName = string.gsub(mq.TLO.EverQuest.Server(), ' ', '_') or ''
local myName = mq.TLO.Me.DisplayName() or ''
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
    winFlags = bit32.bor(ImGuiWindowFlags.MenuBar)
}
--Helper Functioons
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
    if not eventDetails then return end
    local colorVec = eventDetails.color
    -- Convert RGB vector to ImGui color code
    local colorCode = IM_COL32(colorVec[1] * 255, colorVec[2] * 255, colorVec[3] * 255, 255)
    if ChatWin.Consoles[channel] and ChatWin.Consoles[channel].console then
        ChatWin.Consoles[channel].console:AppendText(colorCode, line)
    end
    console:AppendText(colorCode, line)
end
function ChatWin.GUI()
    if not ChatWin.openGUI then return end
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
--- Configure Windows and Events GUI
local tempEventStrings = {}
local tempColors = {}
local tempSettings = ChatWin.Settings
-- Use deepcopy when initializing tempSettings
tempSettings = ChatWin.Settings
local function buildConfig()
    if ImGui.BeginTable("Channel Events", 3, bit32.bor(ImGuiTableFlags.SizingFixedFit, ImGuiTableFlags.Borders)) then
        ImGui.TableSetupColumn("Channel", ImGuiTableColumnFlags.WidthFixed, 100)
        ImGui.TableSetupColumn("EventString", ImGuiTableColumnFlags.WidthFixed, 300)
        ImGui.TableSetupColumn("Color", ImGuiTableColumnFlags.WidthFixed, 150)
        ImGui.TableHeadersRow()
        for channel, channelData in pairs(ChatWin.Settings.Channels) do
            if not tempEventStrings[channel] then tempEventStrings[channel] = {} end
            if not tempColors[channel] then tempColors[channel] = {} end
            for eventId, eventDetails in pairs(channelData.Events) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                ImGui.Text(channel)
                ImGui.TableSetColumnIndex(1)
                local bufferKey = channel .. "_" .. tostring(eventId)
                tempEventStrings[channel][eventId] = ImGui.InputText("##EventString" .. bufferKey, eventDetails.eventString, 256)
                ImGui.TableSetColumnIndex(2)
                if not tempColors[channel][eventId] then
                    tempColors[channel][eventId] = eventDetails.color or {1.0, 1.0, 1.0, 1.0} -- Default to white with full opacity
                end
                tempColors[channel][eventId] = ImGui.ColorEdit4("##Color" .. bufferKey, tempColors[channel][eventId])
            end
        end
        ImGui.EndTable()
    end
    if ImGui.Button("Save") then
        for channel, channelData in pairs(ChatWin.Settings.Channels) do
            if not tempSettings.Channels[channel] then
                tempSettings.Channels[channel] = {Events = {}}
            end
            tempSettings.Channels[channel].enabled = ChatWin.Settings.Channels[channel].enabled
            for eventId, eventString in pairs(tempEventStrings[channel] or {}) do
                if not tempSettings.Channels[channel].Events[eventId] then
                    tempSettings.Channels[channel].Events[eventId] = {}
                end
                tempSettings.Channels[channel].Events[eventId].eventString = eventString
            end
            for eventId, color in pairs(tempColors[channel] or {}) do
                if not tempSettings.Channels[channel].Events[eventId] then
                    tempSettings.Channels[channel].Events[eventId] = {}
                end
                tempSettings.Channels[channel].Events[eventId].color = color
            end
        end
        writeSettings(ChatWin.SettingsFile, tempSettings)
        ChatWin.Settings = tempSettings
        -- Unregister and reregister events to apply changes
        for eventName, _ in pairs(eventNames) do
            mq.unevent(eventName)
        end
        eventNames = {}
        BuildEvents()
        ChatWin.openConfigGUI = false
    end
end
function ChatWin.Config_GUI(open)
    if not ChatWin.openConfigGUI then return end
    open, ChatWin.openConfigGUI= ImGui.Begin("Event Configuration", open, bit32.bor(ImGuiWindowFlags.AlwaysAutoResize))
    if not ChatWin.openConfigGUI then
        ChatWin.openConfigGUI = false
        open = false
        ImGui.End()
        return open
    end
    buildConfig()
    -- Close Button
    if ImGui.Button('close') then
        ChatWin.openConfigGUI = false
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