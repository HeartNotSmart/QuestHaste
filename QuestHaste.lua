QuestHaste_EventHandler = CreateFrame("FRAME")
QuestHaste_EventHandler:RegisterEvent("ADDON_LOADED")

local QuestHaste_EventList = {
    "QUEST_PROGRESS",
    "QUEST_COMPLETE",
    "QUEST_DETAIL",
    "GOSSIP_SHOW",
    "GOSSIP_CLOSED",
    "PLAYER_TARGET_CHANGED",
    "QUEST_GREETING",
    "QUEST_FINISHED",
    "UI_ERROR_MESSAGE"
}

local QuestHaste_Usage = [[
|cffffff00## QuestHaste Usage:

* Quest (active and available) opening/progress
    * complete/accept
* Gossip opening modifiers
    * No Modifier   auto complete/accept quest in gossip
        (priority: completed, available, active)
* Command line options (/qhaste, /questhaste):
    * usage   display usage instructions
    * pause   disable QuestHaste
    * resume   activate QuestHaste
    * complete   complete/accept current quest|r
]]

function QuestHaste_RegisterEvents()
    for _,e in QuestHaste_EventList do
        QuestHaste_EventHandler:RegisterEvent(e)
    end
end

function QuestHaste_UnregisterEvents()
    for _,e in QuestHaste_EventList do
        QuestHaste_EventHandler:UnregisterEvent(e)
    end
end

local function filterEvens(t)
    local r = {}
    for k,v in t do
        if math.mod(k,2) ~= 0 then
            r[(k+1)/2] = v
        end
    end
    return r
end

local function resetAttempts()
    QuestHaste.attempted = {}
    QuestHaste.suspended = false
    QuestHaste.suspendedAt = nil
    QuestHaste.currentQuest = ""
end

local function closeInteraction()
    QuestHaste.currentQuest = ""
    QuestHaste.suspended = true
    QuestHaste.suspendedAt = GetTime()

    if CloseQuest then CloseQuest() end
    if CloseGossip then CloseGossip() end
    if HideUIPanel and QuestFrame and QuestFrame:IsShown() then HideUIPanel(QuestFrame) end
    if HideUIPanel and GossipFrame and GossipFrame:IsShown() then HideUIPanel(GossipFrame) end
end

local function allowRetryAfterSuspension()
    if not QuestHaste.suspended then
        return true
    end

    if QuestHaste.suspendedAt and GetTime() - QuestHaste.suspendedAt > 1 then
        resetAttempts()
        return true
    end

    return false
end

local function resetAttemptsIfClosed()
    if QuestHaste.suspended then
        QuestHaste.currentQuest = ""
        return
    end

    if not GossipFrame:IsShown() and not QuestFrame:IsShown() then
        resetAttempts()
        QuestHaste.currentQuest = ""
    end
end

local function alreadyTried(action, title)
    if title == nil or title == "" then
        return true
    end
    if QuestHaste.attempted == nil then
        resetAttempts()
    end

    local key = action..":"..title
    if QuestHaste.attempted[key] then
        return true
    end

    QuestHaste.attempted[key] = true
    return false
end

local function menuHandler(available, active, name, accept, complete)
    local function SetupBackground(b)
        b:SetAllPoints(b:GetParent()) b:SetDrawLayer("BACKGROUND",-1) b:SetTexture(1,1,1) b:SetGradientAlpha("HORIZONTAL", 0.5, 1, 0, 0.5, 1, 1, 0, 0)
    end
    
    for i = 1,32 do
        local f = getglobal(name..i)
        
        if f.QHaste == nil then
            f.QHaste = {background = f:CreateTexture(), oldScript = f:GetScript("OnClick")}
            SetupBackground(f.QHaste.background)
            local function OnClick(...)
                f.QHaste.oldScript(unpack(arg))
            end
            f:SetScript("OnClick",OnClick)
        end
        f.QHaste.background:Hide()
    end
    local logCompleted = {}
    for k = 1,GetNumQuestLogEntries() do
        local title, _, _, _, _, completed = GetQuestLogTitle(k)
        if completed then
            logCompleted[title] = true
        end
    end
    for k,v in active do
        if logCompleted[v] and not alreadyTried("complete-menu", v) then
            QuestHaste.currentQuest = v
            complete(k)
            return
        end
    end

    local triedAny = false
    for k,v in available do
        triedAny = true
        if not alreadyTried("accept-menu", v) then
            QuestHaste.currentQuest = v
            accept(k)
            return
        end
    end
    for k,v in active do
        triedAny = true
        if not alreadyTried("complete-menu", v) then
            QuestHaste.currentQuest = v
            complete(k)
            return
        end
    end
    if triedAny then
        closeInteraction()
    end
end
    
function QuestHaste_EventHandler.GOSSIP_SHOW()
    if not allowRetryAfterSuspension() then return end
    if not GossipFrame:IsShown() then return end
    local available = filterEvens({GetGossipAvailableQuests()})
    local active = filterEvens({GetGossipActiveQuests()})
    local name = "GossipTitleButton"
    menuHandler(available, active, name, SelectGossipAvailableQuest, SelectGossipActiveQuest)
end

function QuestHaste_EventHandler.QUEST_GREETING()
    if not allowRetryAfterSuspension() then return end
    if not QuestFrame:IsShown() then return end
    local available = {}
    local active = {}
    for k = 1, GetNumAvailableQuests() do
        table.insert(available, GetAvailableTitle(k))
    end
    for k = 1, GetNumActiveQuests() do
        table.insert(active, GetActiveTitle(k))
    end
    local name = "QuestTitleButton"
    menuHandler(available, active, name, SelectAvailableQuest, SelectActiveQuest)
end
    

function QuestHaste_EventHandler.QUEST_PROGRESS()
    if QuestHaste.suspended then return end
    if not QuestFrame:IsShown() then return end

    local title = GetTitleText()
    if IsQuestCompletable() and not alreadyTried("progress", title) then
        QuestHaste.currentQuest = title
        CompleteQuest()
    else
        closeInteraction()
    end
end

function QuestHaste_EventHandler.QUEST_COMPLETE()
    if QuestHaste.suspended then return end
    if not QuestFrame:IsShown() then return end

    local title = GetTitleText()
    if GetNumQuestChoices() > 0 then
        QuestHaste.currentQuest = ""
        return
    end

    if not alreadyTried("reward", title) then
        GetQuestReward()
    else
        closeInteraction()
    end
    QuestHaste.currentQuest = ""
end

function QuestHaste_EventHandler.QUEST_DETAIL()
    if QuestHaste.suspended then return end
    if not QuestFrame:IsShown() then return end

    local title = GetTitleText()
    if not alreadyTried("detail", title) then
        AcceptQuest()
    else
        closeInteraction()
    end
end

function QuestHaste_EventHandler.GOSSIP_CLOSED()
    resetAttemptsIfClosed()
end

function QuestHaste_EventHandler.QUEST_FINISHED()
    resetAttemptsIfClosed()
end

function QuestHaste_EventHandler.PLAYER_TARGET_CHANGED()
    resetAttempts()
    QuestHaste.currentQuest = ""
end

function QuestHaste_EventHandler.UI_ERROR_MESSAGE()
    if (QuestHaste.currentQuest ~= nil and QuestHaste.currentQuest ~= "") or QuestFrame:IsShown() or GossipFrame:IsShown() then
        closeInteraction()
    end
end

function QuestHaste_EventHandler.ADDON_LOADED()
    if arg1 == "QuestHaste" then
        QuestHaste = QuestHaste or {}
        resetAttempts()
        QuestHaste_RegisterEvents()
        QuestHaste_EventHandler:UnregisterEvent("ADDON_LOADED")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88QuestHaste|r loaded. See /qhaste usage")
    end
end

QuestHaste_EventHandler:SetScript("OnEvent",
    function ()
        if QuestHaste_EventHandler[event]
        then QuestHaste_EventHandler[event]()
        end
    end
)

function QuestHaste_Proceed()
    if QuestHaste.suspended then return end

    if GossipFrame:IsShown() then
        local title = GetGossipActiveQuests()
        if not alreadyTried("complete-menu", title) then
            QuestHaste.currentQuest = title
            SelectGossipActiveQuest(1)
        else
            closeInteraction()
        end
    elseif QuestFrame:IsShown() then
        local title = GetTitleText()
        if QuestFrameAcceptButton:IsShown() and not alreadyTried("detail", title) then
            AcceptQuest()
        elseif QuestFrameCompleteButton:IsShown() and IsQuestCompletable() and not alreadyTried("progress", title) then
            QuestHaste.currentQuest = title
            CompleteQuest()
        elseif QuestFrameCompleteQuestButton:IsShown() and IsQuestCompletable() and not alreadyTried("reward", title) then
            GetQuestReward()
        else
            closeInteraction()
        end
    end
end

local function CommandParser(msg, editbox)
    local _,_,command, rest = string.find(msg,"^(%S*)%s*(.-)$")
    if command == "usage" then
        DEFAULT_CHAT_FRAME:AddMessage(QuestHaste_Usage)
    elseif command == "pause" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88QuestHaste|r: |cffff0000paused|r.")
        QuestHaste_UnregisterEvents()
    elseif command == "resume" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88QuestHaste|r: |cff00ff00active|r.")
        resetAttempts()
        QuestHaste_RegisterEvents()
    elseif command == "complete" then
        QuestHaste_Proceed()
    else
        DEFAULT_CHAT_FRAME:AddMessage("Syntax:\n/qhaste usage\n/qhaste complete\n/qhaste pause\n/qhaste resume");
    end
end
SLASH_QUESTHASTE1 = "/questhaste"
SLASH_QUESTHASTE2 = "/qhaste"
SlashCmdList["QUESTHASTE"] = CommandParser
