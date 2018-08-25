-- Config
local position_REF = 'TOPRIGHT'
local position_X = -46
local position_Y = -21
local position_Align = 'RIGHT'
local font = 'Fonts\\FRIZQT__.ttf'
-- /Config

local playerRealm = GetRealmName()
local playerFaction = select(1, UnitFactionGroup('player'))
local playerName = UnitName('player')
local playerClass = select(2, UnitClass('player'))

-- Funtion ----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
local KBJcurrencyEmblems_Format = function(currencyID)
    local _, amount, icon = GetCurrencyInfo(currencyID)

    if amount > 0 then
        local CURRENCY_TEXTURE = "%s\124T"..icon..":%d:%d:2:0\124t"
        return format(CURRENCY_TEXTURE.." ", BreakUpLargeNumbers(amount), 0, 0)
    else
        return ""
    end
end

local KBJcurrencyEmblems_Update = function()
    local name, currencyID
    local currencystr
    for i=1, MAX_WATCHED_TOKENS do
        name, _, _, currencyID = GetBackpackCurrencyInfo(i)
        if name then
            if currencystr then
                currencystr = currencystr..KBJcurrencyEmblems_Format(currencyID).." "
            else
                currencystr = KBJcurrencyEmblems_Format(currencyID).." "
            end
        end
    end
    return currencystr
end

function KBJcurrencyEmblems()
    local currencystr = KBJcurrencyEmblems_Update()

    if currencystr then
        currencystr = "|cFFFFFFFF"..currencystr
    else
        currencystr = ""
    end

    return currencystr
end

function KBJcurrencyMoney()
    return GetCoinTextureString(GetMoney(), 0)
end

function KBJcurrencySave()
    if KBJcurrencyDB == nil then KBJcurrencyDB = { } end
    if not KBJcurrencyDB[playerRealm.."-"..playerFaction] then KBJcurrencyDB[playerRealm.."-"..playerFaction] = { } end

    local currencyDB = KBJcurrencyDB[playerRealm.."-"..playerFaction]
    local foundPlayer = false

    if currencyDB[1] == nil then
        currencyDB[1] = { playerName, playerClass, GetMoney() }
    else
        for i = 1, #currencyDB do
            if currencyDB[i][1] == playerName then
                currencyDB[i] = { playerName, playerClass, GetMoney() }
                foundPlayer = true
            end
        end
        if not foundPlayer then
            currencyDB[#currencyDB+1] = { playerName, playerClass, GetMoney() }
        end
    end
end

function KBJcurrencyTooltip(self)
    local totalGold = 0

    GameTooltip:ClearLines()
    GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')

    -- Title
    GameTooltip:AddLine("KBJ Currency", 0.9, 0.7, 0.2)
    GameTooltip:AddLine(" ")

    -- AzeriteItem for BfA
    local azeriteItem = C_AzeriteItem.FindActiveAzeriteItem()
    if azeriteItem then
        local azeriteCur, azeriteMax = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItem)
        local azeriteLv = C_AzeriteItem.GetPowerLevel(azeriteItem)
        GameTooltip:AddLine("Azerite Lv : "..azeriteLv, 0.9, 0.7, 0.2)
        GameTooltip:AddLine("  "..math.floor(azeriteCur/azeriteMax*100+0.5).."% ("..azeriteCur.." / "..azeriteMax..")", 1, 1, 1)
        GameTooltip:AddLine("  Needed : "..azeriteMax-azeriteCur, 0.6, 0.6, 0.6)
    end

    -- Honor for BfA
    local honorCur, honorMax = UnitHonor("player"), UnitHonorMax("player")
    local honorLv = UnitHonorLevel("player")
    GameTooltip:AddLine("Honor Lv : "..honorLv, 0.9, 0.7, 0.2)
    GameTooltip:AddLine("  "..math.floor(honorCur/honorMax*100+0.5).."% ("..honorCur.." / "..honorMax..")", 1, 1, 1)
    GameTooltip:AddLine("  Needed : "..honorMax-honorCur, 0.6, 0.6, 0.6)

    -- Island Expeditions for BfA
    local ie_wqID = C_IslandsQueue.GetIslandsWeeklyQuestID()
    if ie_wqID and IsQuestFlaggedCompleted(ie_wqID) then
        GameTooltip:AddLine("Island Expeditions : Done", 0.9, 0.7, 0.2)
    elseif ie_wqID then
        local _, _, _, ieCur, ieMax = GetQuestObjectiveInfo(ie_wqID, 1, false)
        GameTooltip:AddLine("Island Expeditions", 0.9, 0.7, 0.2)
        GameTooltip:AddLine("  "..math.floor(ieCur/ieMax*100+0.5).."% ("..ieCur.." / "..ieMax..")", 1, 1, 1)
        GameTooltip:AddLine("  Needed : "..ieMax-ieCur, 0.6, 0.6, 0.6)
    end

    -- Reputation
    local repName, repStanding, _, repMax, repCur = GetWatchedFactionInfo()
    if repName then
        GameTooltip:AddLine("Reputation : "..repName, 0.9, 0.7, 0.2)
        GameTooltip:AddLine("  ".._G["FACTION_STANDING_LABEL"..repStanding], 1, 0.9, 0.4)
        GameTooltip:AddLine("  "..math.floor(repCur/repMax*100+0.5).."% ("..repCur.." / "..repMax..")", 1, 1, 1)
        GameTooltip:AddLine("  Needed : "..repMax-repCur, 0.6, 0.6, 0.6)
    end

    -- Total Gold
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Gold in "..GetRealmName(), 0.9, 0.7, 0.2)

    local currencyDB = KBJcurrencyDB[playerRealm.."-"..playerFaction]
    for i = 1, #currencyDB do
        local name, class, money = unpack(currencyDB[i])
        local color = RAID_CLASS_COLORS[class]

        GameTooltip:AddDoubleLine(name, GetCoinTextureString(money, 0).."  ", color.r, color.g, color.b, 1, 1, 1)
        totalGold = totalGold + money
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Total", GetCoinTextureString(totalGold, 0).."  ", 0.9, 0.7, 0.2, 1, 1, 1)

    -- Token
    local tokenPrice = C_WowTokenPublic.GetCurrentMarketPrice()
    if tokenPrice then
        GameTooltip:AddLine("Token Price : "..GetMoneyString(tokenPrice), 0.9, 0.7, 0.2)
    end

    GameTooltip:Show()
end

-- Core -------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
local mainFrame = CreateFrame('frame', 'KBJcurrency', UIParent)
mainFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
-- Emblems Event
mainFrame:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
-- Money Event
mainFrame:RegisterEvent('PLAYER_MONEY')
mainFrame:RegisterEvent('SEND_MAIL_MONEY_CHANGED')
mainFrame:RegisterEvent('SEND_MAIL_COD_CHANGED')
mainFrame:RegisterEvent('PLAYER_TRADE_MONEY')
mainFrame:RegisterEvent('TRADE_MONEY_CHANGED')
-- General
mainFrame:RegisterEvent('MERCHANT_CLOSED')

mainFrame:SetWidth(50)
mainFrame:SetHeight(15)
mainFrame:SetPoint(position_REF, UIParent, position_REF, position_X, position_Y)

local currencyFrame = mainFrame:CreateFontString(nil, 'OVERLAY')
currencyFrame:SetPoint(position_Align, mainFrame, position_Align, 0, 0)
currencyFrame:SetFont(font, 12, nil)
currencyFrame:SetShadowOffset(1, -1)
currencyFrame:SetTextColor(1, 1, 1)
--currencyFrame:SetPoint('CENTER')

function KBJcurrencyOnEvent(self, event, ...)
    local emblems = KBJcurrencyEmblems()
    local money = KBJcurrencyMoney()
    if event == 'PLAYER_ENTERING_WORLD' then
        C_WowTokenPublic.UpdateMarketPrice()
        currencyFrame:SetText(money.."  "..emblems)
        mainFrame:SetWidth(currencyFrame:GetStringWidth())
        KBJcurrencySave()
    elseif event == 'CURRENCY_DISPLAY_UPDATE' then
        emblems = KBJcurrencyEmblems()
        currencyFrame:SetText(money.."  "..emblems)
        mainFrame:SetWidth(currencyFrame:GetStringWidth())
    elseif event == 'PLAYER_MONEY'
    or event == 'SEND_MAIL_MONEY_CHANGED'
    or event == 'SEND_MAIL_COD_CHANGED'
    or event == 'PLAYER_TRADE_MONEY'
    or event == 'TRADE_MONEY_CHANGED' then
        money = KBJcurrencyMoney()
        currencyFrame:SetText(money.."  "..emblems)
        mainFrame:SetWidth(currencyFrame:GetStringWidth())
        KBJcurrencySave()
    end
end

mainFrame:SetScript('OnEvent', KBJcurrencyOnEvent)
mainFrame:SetScript('OnEnter', function() KBJcurrencyTooltip(mainFrame) end)
mainFrame:SetScript('OnLeave', function() GameTooltip:Hide() end)
