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
local KBJCurrencyEmblems_Format = function(currencyID)
	local _, amount, icon = GetCurrencyInfo(currencyID)
	
	if amount > 0 then
		local CURRENCY_TEXTURE = "%s\124T"..icon..":%d:%d:2:0\124t"
		return format(CURRENCY_TEXTURE.." ", BreakUpLargeNumbers(amount), 0, 0)
	else
		return ""
	end
end

local KBJCurrencyEmblems_Update = function()
	local name, currencyID
	local currencystr
	for i=1, MAX_WATCHED_TOKENS do
		name, _, _, currencyID = GetBackpackCurrencyInfo(i)
		if name then
			if currencystr then
				currencystr = currencystr..KBJCurrencyEmblems_Format(currencyID).." "
			else
				currencystr = KBJCurrencyEmblems_Format(currencyID).." "
			end
		end
	end
	return currencystr
end

function KBJCurrencyEmblems()
	local currencystr = KBJCurrencyEmblems_Update()

	if currencystr then 
		currencystr = "|cFFFFFFFF"..currencystr
	else
		currencystr = ""
	end

	return currencystr
end

function KBJCurrencyMoney()
	return GetCoinTextureString(GetMoney(), 0)
end

function KBJCurrencySave()
	if KBJCurrencyDB == nil then KBJCurrencyDB = { } end
	if not KBJCurrencyDB[playerRealm.."-"..playerFaction] then KBJCurrencyDB[playerRealm.."-"..playerFaction] = { } end

	local currencyDB = KBJCurrencyDB[playerRealm.."-"..playerFaction]
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

function KBJCurrencyTooltip(self)
	local totalGold = 0
	local tokenPrice = C_WowTokenPublic.GetCurrentMarketPrice()

	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
	GameTooltip:AddLine("Gold in "..GetRealmName(), .9, .7, .2)

	local currencyDB = KBJCurrencyDB[playerRealm.."-"..playerFaction]
	for i = 1, #currencyDB do
		local name, class, money = unpack(currencyDB[i])
		local color = RAID_CLASS_COLORS[class]

		GameTooltip:AddDoubleLine(name, GetCoinTextureString(money, 0).."  ", color.r, color.g, color.b, 1, 1, 1)
		totalGold = totalGold + money
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Total", GetCoinTextureString(totalGold, 0).."  ", .9, .7, .2, 1, 1, 1)
	if tokenPrice then
		GameTooltip:AddLine("Token Price : "..GetMoneyString(tokenPrice), .9, .7, .2)
	end
	GameTooltip:Show()
end

-- Core -------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
local mainFrame = CreateFrame('frame', 'KBJCurrency', UIParent)
mainFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
-- Emblems Event
mainFrame:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
-- Money Event
mainFrame:RegisterEvent('PLAYER_MONEY')
mainFrame:RegisterEvent('SEND_MAIL_MONEY_CHANGED')
mainFrame:RegisterEvent('SEND_MAIL_COD_CHANGED')
mainFrame:RegisterEvent('PLAYER_TRADE_MONEY')
mainFrame:RegisterEvent('TRADE_MONEY_CHANGED')

mainFrame:SetWidth(50)
mainFrame:SetHeight(15)
mainFrame:SetPoint(position_REF, UIParent, position_REF, position_X, position_Y)

local currencyFrame = mainFrame:CreateFontString(nil, 'OVERLAY')
currencyFrame:SetPoint(position_Align, mainFrame, position_Align, 0, 0)
currencyFrame:SetFont(font, 12, nil)
currencyFrame:SetShadowOffset(1, -1)
currencyFrame:SetTextColor(1, 1, 1)
--currencyFrame:SetPoint('CENTER')

function KBJCurrencyOnEvent(self, event, ...)
	local emblems = KBJCurrencyEmblems()
	local money = KBJCurrencyMoney()
	if event == 'PLAYER_ENTERING_WORLD' then
		C_WowTokenPublic.UpdateMarketPrice()
		currencyFrame:SetText(money.."  "..emblems)	
		mainFrame:SetWidth(currencyFrame:GetStringWidth())
		KBJCurrencySave()
	elseif event == 'CURRENCY_DISPLAY_UPDATE' then
		emblems = KBJCurrencyEmblems()
		currencyFrame:SetText(money.."  "..emblems)	
		mainFrame:SetWidth(currencyFrame:GetStringWidth())
	elseif event == 'PLAYER_MONEY'
	or event == 'SEND_MAIL_MONEY_CHANGED'
	or event == 'SEND_MAIL_COD_CHANGED'
	or event == 'PLAYER_TRADE_MONEY'
	or event == 'TRADE_MONEY_CHANGED' then
		money = KBJCurrencyMoney()
		currencyFrame:SetText(money.."  "..emblems)	
		mainFrame:SetWidth(currencyFrame:GetStringWidth())
		KBJCurrencySave()
	end
end

mainFrame:SetScript('OnEvent', KBJCurrencyOnEvent)
mainFrame:SetScript('OnEnter', function() KBJCurrencyTooltip(mainFrame) end)
mainFrame:SetScript('OnLeave', function() GameTooltip:Hide() end)
