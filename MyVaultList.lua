---@diagnostic disable: deprecated
MyVaultListAddon = LibStub("AceAddon-3.0"):NewAddon("MyVaultList", "AceEvent-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("MyVaultList")

local addonName, MyVaultList = ...
MyVaultList = MyVaultList or {}

local function GetPlayerFullName()
	local name, realm = UnitFullName("player")
	return name .. "-" .. realm
 end

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")


function MyVaultList:Initialize()
    local minimapLDB = LDB:NewDataObject(addonName, {
        type = "data source",
        text = addonName,
        icon = "Interface\\AddOns\\MyVaultList\\MyVaultList",
		OnClick = function(clickedFrame, button)
			if button == "LeftButton" then
				if MyVaultListInfoFrame:IsShown() then
					MyVaultListInfoFrame:Hide()
				else
					MyVaultListInfoFrame:Show()
				end
			end
        end,
		
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(addonName ) 
            tooltip:AddLine("Click to toggle or type |cff00ffff/Vaut|r.", 1, 1, 1)
        end,
    })

    self.db = self.db or {
        profile = {
            minimap = { hide = false },
        },
    }

    LDBIcon:Register(addonName, minimapLDB, self.db.profile.minimap)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        MyVaultList:Initialize()
    end
end)




local PlayerName = GetPlayerFullName()

local sortConfig  = { 
	["class"] = "class",
	["character"] = "name",
	["iLevel"] = "averageItemLevel",
	["Raids"] = "averageItemLevel",
	["Activities"] = "averageItemLevel"
}

viewTypes = {
    ["raid"] = { "Raid1", "Raid2", "Raid3" },
    ["activities"] = { "Activities1", "Activities2", "Activities3" },
    ["pvp"] = { "pvp1", "pvp2", "pvp3" },
    ["Keys"] = { "Key1", "Key2", "Key3" }  -- Add this section
}


--frame options
local CONST_WINDOW_WIDTH = 0
local CONST_SCROLL_LINE_HEIGHT = 22	
local CONST_SCROLL_LINE_AMOUNT = 10
local CONST_WINDOW_HEIGHT = CONST_SCROLL_LINE_AMOUNT * CONST_SCROLL_LINE_HEIGHT + 70

local backdrop_color = {.1, .2, .1, 0.1}
local backdrop_color_on_enter = {.7, .7, .7, 0.4}
local backdrop_color_inparty = {.5, .5, .8, 0.2}


local DIFFICULTY_NAMES = {
	[DifficultyUtil.ID.DungeonNormal] = "nhc",
	[DifficultyUtil.ID.DungeonHeroic] = "HC",
	[DifficultyUtil.ID.Raid10Normal] = "nhc",
	[DifficultyUtil.ID.Raid25Normal] = "nhc",
	[DifficultyUtil.ID.Raid10Heroic] = "HC",
	[DifficultyUtil.ID.Raid25Heroic] = "HC",
	[DifficultyUtil.ID.RaidLFR] = "LFR",
	[DifficultyUtil.ID.DungeonChallenge] = PLAYER_DIFFICULTY_MYTHIC_PLUS,
	[DifficultyUtil.ID.Raid40] = LEGACY_RAID_DIFFICULTY,
	[DifficultyUtil.ID.PrimaryRaidNormal] = "nhc",
	[DifficultyUtil.ID.PrimaryRaidHeroic] = "HC",
	[DifficultyUtil.ID.PrimaryRaidMythic] = "MTH",
	[DifficultyUtil.ID.PrimaryRaidLFR] = "LFR",
	[DifficultyUtil.ID.DungeonMythic] = PLAYER_DIFFICULTY6,
	[DifficultyUtil.ID.DungeonTimewalker] = PLAYER_DIFFICULTY_TIMEWALKER,
	[DifficultyUtil.ID.RaidTimewalker] = PLAYER_DIFFICULTY_TIMEWALKER,
}


--namespaceS
MyVaultListAddon.ScrollFrame = {}

local default_global_data = {
	global = {
		MyVaultList_frame = {
			scale = 1,
			position = {}
		},
		characters = {},
		view = {
			raid = true,
			activities = true,
			pvp = true
		}
	}
}


local headerTable = {
	{key = "class", text = "", width = 40, canSort = true, dataType = "string", order = "DESC", offset = 0},
	{key = "character", text = L["Character"], width = 130, canSort = true, dataType = "string", order = "DESC", offset = -15},
	{key = "iLevel", text = L["iLevel"], width = 60, canSort = true, dataType = "number", order = "DESC", offset = 0},
}

local headerTableConfig  = { "class", "character", "iLevel" }


local headerOptions = {
	["raid"] = { text = L["Raids"], width = 70, canSort = false, dataType = "string", order = "DESC", offset = 15, align = "center"},
	["activities"] = { text = L["Keys"], width = 70, canSort = false, dataType = "string", order = "DESC", offset = 15, align = "center"},
	["pvp"] = { text = L["PvP"], width = 80, canSort = false, dataType = "string", order = "DESC", offset = 15, align = "center"}
}


local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
function MyVaultListAddon:buildColumns()

	for key, items in pairs(viewTypes) do
		for idx, col in ipairs(items) do
			if self.db.global.view[key] then 
				table.insert(headerTableConfig, col)
				local opt = shallowcopy(headerOptions[key])
				opt.key = col
				if idx > 1 then
					opt.text = ""
				end
				table.insert(headerTable, opt)
			end
		end
	end

	local windowWidth = 0
	for _, value in ipairs(headerTable) do
		windowWidth = windowWidth + value.width
	end

	--frame options
	CONST_WINDOW_WIDTH = windowWidth + 30

end


function MyVaultListAddon:OnInitialize()
    
	print("MyVaultList is active |cff00ffff/Vaut|r.")
	
--print("MyVaultList is now active!")
    self.db = LibStub("AceDB-3.0"):New("MyVaultListDB", default_global_data, true)
	self:buildColumns()

	C_AddOns.LoadAddOn("Blizzard_WeeklyRewards");
	WeeklyRewardExpirationWarningDialog:Hide()

	MyVaultListAddon:slashcommand() 
	MyVaultListAddon:createWindow()
end

function MyVaultListAddon:slashcommand() 
	SLASH_GV1 = "/Vault"
	SLASH_GV2 = "/MyVaultList"
	SlashCmdList["GV"] = function(msg)
        if MyVaultListInfoFrame:IsShown() then 
            MyVaultListInfoFrame:Hide()
        else
            MyVaultListInfoFrame:Show()
        end

		if msg == "raid" then 
			MyVaultListAddon.db.global.view.raid = not MyVaultListAddon.db.global.view.raid
			C_UI.Reload()
		elseif msg == "activities" then
			MyVaultListAddon.db.global.view.activities = not MyVaultListAddon.db.global.view.activities
			C_UI.Reload()
		elseif  msg == "pvp" then
			MyVaultListAddon.db.global.view.pvp = not MyVaultListAddon.db.global.view.pvp
			C_UI.Reload()
		end
	end 
end

function MyVaultListAddon:sortEntries(columnIndex, order)
    local data = MyVaultListAddon.ScrollFrame.ScollFrame:GetData()
	columnIndex = sortConfig[columnIndex]
	table.sort(data, function (k1, k2) 
		if order == "DESC" then
			return k1[columnIndex] < k2[columnIndex]
		else 
			return k1[columnIndex] > k2[columnIndex]
		end
	end)
	MyVaultListAddon.ScrollFrame.ScollFrame:SetData(data)
	MyVaultListAddon.ScrollFrame.ScollFrame:Refresh()
end 

function MyVaultListAddon:createWindow() 

	local f = DetailsFramework:CreateSimplePanel(UIParent, CONST_WINDOW_WIDTH, CONST_WINDOW_HEIGHT, "MyVaultList", "MyVaultListInfoFrame")
	f:SetPoint("center", UIParent, "center", 0, 0)

	f:SetScript("OnMouseDown", nil)
	f:SetScript("OnMouseUp", nil)

	local LibWindow = LibStub("LibWindow-1.1")
	LibWindow.RegisterConfig(f, MyVaultListAddon.db.global.MyVaultList_frame.position)
	LibWindow.MakeDraggable(f)
	LibWindow.RestorePosition(f)

	local scaleBar = DetailsFramework:CreateScaleBar(f, MyVaultListAddon.db.global.MyVaultList_frame)
	f:SetScale(MyVaultListAddon.db.global.MyVaultList_frame.scale)

	local statusBar = DetailsFramework:CreateStatusBar(f)
	statusBar.text = statusBar:CreateFontString(nil, "overlay", "GameFontNormalLarge")
	statusBar.text:SetPoint("left", statusBar, "left", 5, 0)
	statusBar.text:SetText("|cffff0000Version1.3|r |cff00ffffby Släggish|r")
	DetailsFramework:SetFontSize(statusBar.text, 12) 
	--DetailsFramework:SetFontColor(statusBar.text, "blueviolet")

-- Function to show the Discord link frame
local function ShowDiscordLinkFrame()
    if not MyVaultListAddon.DiscordLinkFrame then
        -- Creating the main frame that will hold the EditBox
        local frame = CreateFrame("Frame", "MyVaultListAddonDiscordLinkFrame", UIParent, "BackdropTemplate")
        frame:SetSize(360, 100) -- Width, Height
        frame:SetPoint("CENTER") -- Center on screen
        frame:SetFrameStrata("TOOLTIP") -- Use the highest frame strata to ensure it's on top
        frame:SetFrameLevel(100) -- Use a high frame level to ensure it's above other frames in the same strata
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        frame:SetBackdropColor(0,0,0,1)
        frame:SetMovable(true) -- Allows the frame to be moved
        frame:EnableMouse(true) -- Enables mouse interaction for the frame
        frame:RegisterForDrag("LeftButton") -- Registers the frame to respond to drag events
        frame:SetScript("OnDragStart", frame.StartMoving) -- Starts moving the frame on drag start
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing) -- Stops moving the frame on drag stop
        
        -- Adding a title to the frame
        local title = frame:CreateFontString(nil, "overlay", "GameFontHighlight")
        title:SetPoint("TOP", frame, "TOP", 0, -10)
        title:SetText("Discord Link")
        
        -- Creating the EditBox for the Discord URL
        local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        editBox:SetAutoFocus(false)
        editBox:SetSize(320, 20)
        editBox:SetPoint("TOP", title, "BOTTOM", 0, -10)
        editBox:SetMaxLetters(256)
        editBox:SetText("https://discord.gg/8Qudu4eF")
        editBox:SetCursorPosition(0)
        editBox:HighlightText()
        editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        
        -- Adding text instruction below the EditBox
        local instructionText = frame:CreateFontString(nil, "overlay", "GameFontNormalLarge")
        instructionText:SetPoint("TOP", editBox, "BOTTOM", 0, -10)
        instructionText:SetText("Press Ctrl+C to copy")

        -- Close button for the frame
        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

        MyVaultListAddon.DiscordLinkFrame = frame
    else
        MyVaultListAddon.DiscordLinkFrame:SetFrameStrata("TOOLTIP")
        MyVaultListAddon.DiscordLinkFrame:SetFrameLevel(100) -- Reassert frame level
        MyVaultListAddon.DiscordLinkFrame:Show()
    end
end


-- Creating the Discord button
local discordButton = DetailsFramework:CreateButton(f, ShowDiscordLinkFrame, 22, 22, "")
discordButton:SetPoint("RIGHT", statusBar, "RIGHT", -5, 0)
discordButton:SetNormalTexture("Interface\\AddOns\\MythicDungeonTools\\Textures\\icons")
discordButton:GetNormalTexture():SetTexCoord(0.5, .75, 0.75, 1)

-- Ensure MyVaultListAddon.ScrollFrame.create(f) is correctly positioned after these additions
MyVaultListAddon.ScrollFrame.create(f)

end

function MyVaultListAddon.ScrollFrame.create(f) 
	MyVaultListAddon.ScrollFrame.setHeader(f)
	local scrollFrame = DetailsFramework:CreateScrollBox(f, "$parentScroll", MyVaultListAddon.ScrollFrame.RefreshScroll, MyVaultListAddon.db.global.characters, CONST_WINDOW_WIDTH, CONST_WINDOW_HEIGHT-70, CONST_SCROLL_LINE_AMOUNT, CONST_SCROLL_LINE_HEIGHT)
	DetailsFramework:ReskinSlider(scrollFrame)
	scrollFrame:CreateLines(MyVaultListAddon.ScrollFrame.CreateScrollLine, CONST_SCROLL_LINE_AMOUNT)
	scrollFrame:SetPoint("topleft", f.Header, "bottomleft", -1, -1)
	scrollFrame:SetPoint("topright", f.Header, "bottomright", 0, -1)
    scrollFrame:Refresh()
	MyVaultListAddon.ScrollFrame.ScollFrame = scrollFrame;
end

function MyVaultListAddon.ScrollFrame.setHeader(f)

	local headerOptions = {
		padding = 0,
		header_backdrop_color = {.4, .4, .4, .8},
		header_backdrop_color_selected = {.5, .5, .5, .8},
		use_line_separators = false,
		line_separator_color = {.5, .5, .5, .8},
		line_separator_width = -1,
		line_separator_height = CONST_WINDOW_HEIGHT-20,
		line_separator_gap_align = false,
		header_click_callback = function(headerFrame, columnHeader)
			MyVaultListAddon:sortEntries(columnHeader.key, columnHeader.order)
		end,
	}

	f.Header = DetailsFramework:CreateHeader(f, headerTable, headerOptions, "MyVaultListInfoFrameHeader")
	f.Header:SetPoint("topleft", f, "topleft", 3, -25)
    f.Header.columnSelected = 2
end

function MyVaultListAddon.ScrollFrame.RefreshScroll(self, data, offset, totalLines) 
	for i = 1, totalLines do
		local index = i + offset
		local data = data[index]
		if(data) then 
			local line = self:GetLine(i)
            if (data.name == PlayerName) then
                line:SetBackdropColor(unpack(backdrop_color_inparty))
            else
                line:SetBackdropColor(unpack(backdrop_color))
            end

			local L, R, T, B = unpack(CLASS_ICON_TCOORDS[data.class])
			line.icon:SetTexCoord(L+0.02, R-0.02, T+0.02, B-0.02)

			line.character.text = data.name
			line.iLevel.text  = string.format("%.2f", data.averageItemLevel)

			for key, items in pairs(viewTypes) do
				for idx, col in ipairs(items) do
					if MyVaultListAddon.db.global.view[key] then 
						line[col].text = MyVaultListAddon:GetVault(data[key][idx], data.lastUpdated)
					end
				end
			end

		end
	end
end

function MyVaultListAddon.ScrollFrame.CreateScrollLine(self, lineId)
	local line = CreateFrame("frame", "$parentLine" .. lineId, self, "BackdropTemplate")
	line.lineId = lineId

    line:SetPoint("TOPLEFT", self, "TOPLEFT", 2, (CONST_SCROLL_LINE_HEIGHT * (lineId - 1) * -1) - 2)
    line:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, (CONST_SCROLL_LINE_HEIGHT * (lineId - 1) * -1) - 2)
    line:SetHeight(CONST_SCROLL_LINE_HEIGHT)

    line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
    line:SetBackdropColor(unpack(backdrop_color))

	DetailsFramework:Mixin(line, DetailsFramework.HeaderFunctions)

    line:SetScript("OnEnter", function(self)
		if not (self.text == PlayerName) then
			self:SetBackdropColor(unpack(backdrop_color_on_enter))
		end
	end)
	

	line:SetScript("OnLeave", function(self)
        if not (self.character.text == PlayerName) then
            self:SetBackdropColor(unpack(backdrop_color))
        end
    end)

	local header = self:GetParent().Header

	for _, value in pairs(headerTableConfig) do
		if value == "class" then 
			local icon = line:CreateTexture("$parentClassIcon", "overlay")
			icon:SetSize(CONST_SCROLL_LINE_HEIGHT - 2, CONST_SCROLL_LINE_HEIGHT - 2)
			icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
			line.icon = icon
			line:AddFrameToHeaderAlignment(icon)
		else
			local obj = DetailsFramework:CreateLabel(line)
			line[value] = obj
			line:AddFrameToHeaderAlignment(obj)
		end
	end

	line:AlignWithHeader(header, "left")
	return line
end



local function GetWeeklyQuestResetTime()
	local now = time()
	local region = GetCurrentRegion()
	local regionDayOffset = {{ 2, 1, 0, 6, 5, 4, 3 }, { 4, 3, 2, 1, 0, 6, 5 }, { 3, 2, 1, 0, 6, 5, 4 }, { 4, 3, 2, 1, 0, 6, 5 }, { 4, 3, 2, 1, 0, 6, 5 } }
	local nextDailyReset = GetQuestResetTime()
	local utc = date("!*t", now + nextDailyReset)
	local reset = regionDayOffset[region][utc.wday] * 86400 + now + nextDailyReset
	return reset
end

function GetDifficultyName(difficultyID)
	return DIFFICULTY_NAMES[difficultyID];
end

function MyVaultListAddon:GetVault(activity, lastUpdated)
	if not lastUpdated then
		lastUpdated = time()
	end

	local status
	local activityThisWeek = lastUpdated > GetWeeklyQuestResetTime() - 604800
	local difficulty

	if activity.progress >= activity.threshold and activityThisWeek then
		if activity.type == Enum.WeeklyRewardChestThresholdType.Activities then
			difficulty = " +" .. activity.level .. " "
		elseif activity.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			difficulty = PVPUtil.GetTierName(activity.level)
		elseif activity.type == Enum.WeeklyRewardChestThresholdType.Raid then
			difficulty = GetDifficultyName(activity.level)
		end

		status = GREEN_FONT_COLOR_CODE .. difficulty .. FONT_COLOR_CODE_CLOSE
	else
		local progress = 0
		if activityThisWeek then
			progress = activity.progress
		end
		local spacer = " "
		if activity.type == Enum.WeeklyRewardChestThresholdType.Activities then
			spacer = " "
		end

		status = GRAY_FONT_COLOR_CODE .. spacer .. progress .. '/' .. activity.threshold .. spacer ..  FONT_COLOR_CODE_CLOSE
	end

    return status
end

function MyVaultListAddon:SaveCharacterInfo(info)
	if UnitLevel("player") < 70 then
		return
	end

	local characterInfo = info or self:GetCharacterInfo()
	local characterName = GetPlayerFullName()

	local found = false
    for _, value in ipairs(self.db.global.characters) do
        if value.name == characterName  then
			found = true
			value = characterInfo
        end
    end

	if not found then 
		table.insert(self.db.global.characters, characterInfo)
	end
end

function MyVaultListAddon:GetCharacterInfo()
	local name = GetPlayerFullName()
	local characterInfo = {}
	for _, value in ipairs(self.db.global.characters) do
        if value.name == name  then
			characterInfo = value
        end
    end

	local _, className = UnitClass("player")
	characterInfo.name = name
	characterInfo.lastUpdate = time()
	characterInfo.class = className
	characterInfo.realm = GetRealmName()
	characterInfo.level = UnitLevel("player")
	characterInfo.averageItemLevel = GetAverageItemLevel();

	characterInfo.raid = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Raid)
	characterInfo.activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
	characterInfo.pvp = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.RankedPvP)

	return characterInfo
end

local function UpdateStatus()
	MyVaultListAddon:SaveCharacterInfo()
	MyVaultListAddon:sortEntries("iLevel", "ASC")
end




function MyVaultListAddon:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
	if isLogin or isReload then
		C_Timer.After(3, UpdateStatus)
	end
end

function MyVaultListAddon:WEEKLY_REWARDS_UPDATE(event)
	UpdateStatus()
end

function MyVaultListAddon:WEEKLY_REWARDS_ITEM_CHANGED(event)
	UpdateStatus()
end


function MyVaultListAddon:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("WEEKLY_REWARDS_UPDATE")
	self:RegisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
end

function MyVaultListAddon:OnDisable()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("WEEKLY_REWARDS_UPDATE")
	self:UnregisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
end


function MyVaultListAddon_OnAddonCompartmentClick() 
	if MyVaultListInfoFrame:IsShown() then 
		MyVaultListInfoFrame:Hide()
	else
		MyVaultListInfoFrame:Show()
	end
end