-------------------------------------
--- RoleCrowns by TheWizardLizard ---
--- Main File - February, 2020 ------
-------------------------------------

-- Developer Notes
	-- ZOS has restricted the ability to draw 3D UI elements during dungeons and trials.
	-- https://www.reddit.com/r/elderscrollsonline/comments/8w2gd0/harvestmap_3d_pins_in_dungeons/
	-- The game prevents group member roles from being fetched during battlegrounds matches.
	-- Default in-game crowns can be disabled: Settings > Nameplates > Indicators > Group Members
	
-- TODO
-- update website
-- test when a player goes offline, their crown does not get hidden
-- is it possible to keep the crown size uniform as the group member moves farther away?
-- note that suggests disabling default crowns through in game settings

------------------------
-- Object Definitions --
------------------------

-- Stores group member positions and roles
RoleCrowns = {}
local RC = RoleCrowns
RC.name = "RoleCrowns"

RC.group_list = {}
RC.group_size = 0

-- Stores references to ui controls, textures, and fragments for each member
UICrowns = {}
local ui = UICrowns


---------------------
-- Constant Values --
---------------------

local ICON_PATH = "RoleCrowns/icons"

-- When we fetch roles, we store the role as a string
local DPS_ID  = "dps"
local HEAL_ID = "healer"
local TANK_ID = "tank"

-- Assigned when a group member is unable to have their role fetched
local NO_ROLE_ID = "no_role" 

-- How far the player's head is above their feet, used to offset crowns
local PLAYER_HEIGHT = 2  

DPS_ICONS = {
	ICON_PATH .. "/dps_simple.dds",
	ICON_PATH .. "/dps_ornate_light.dds",
	ICON_PATH .. "/dps_ornate_dark.dds",
}
HEALER_ICONS = {
	ICON_PATH .. "/healer_simple.dds",
	ICON_PATH .. "/healer_ornate_light.dds",
	ICON_PATH .. "/healer_ornate_dark.dds",
}
TANK_ICONS = {
	ICON_PATH .. "/tank_simple.dds",
	ICON_PATH .. "/tank_ornate_light.dds",
	ICON_PATH .. "/tank_ornate_dark.dds",
}
NO_ROLE_ICONS = {
	ICON_PATH .. "/no_role_simple.dds",
	ICON_PATH .. "/no_role_ornate_light.dds",
	ICON_PATH .. "/no_role_ornate_dark.dds",
}
ICON_CHOICES = {
	"Simple",
	"Ornate_Light",
	"Ornate_Dark",
}


--------------
-- Settings --
--------------

-- Stores user settings for the addon's features
RC.default_settings = {
	show_dps_crowns = true,
	show_healer_crowns = true,
	show_tank_crowns = true,
	show_no_role_crowns = true,
	
	show_player_crown = false,
	pulse_crowns = false,
	
	crown_size = 6,
	crown_y_offset = 16,
	
	dps_color = {1,0.2,0.2,0.5},
	healer_color = {1,1,0,0.5},
	tank_color = {0,1,1,0.5},
	no_role_color = {1,1,1,0.5},

	dps_icon = DPS_ICONS[1],
	healer_icon = HEALER_ICONS[1],
	tank_icon = TANK_ICONS[1],
	no_role_icon = NO_ROLE_ICONS[1],
}
RC.settings = {}


-----------------------------
-- Main Function & Events --
-----------------------------

function Initialize()	
	-- Fetch current group members and roles
	UpdateGroupData()

	-- Draw crowns
	UpdateCrownUI()
	
	-- local log_loop = "group_log_loop"
	-- EVENT_MANAGER:RegisterForUpdate(log_loop, 15000, LogGroupData)
end

-- If our group changes, update the member's data and update their crown
function OnGroupChanged(event, addon_name)
	
	-- Fetch updated data
	UpdateGroupData()
		
	-- Redraw crowns
	UpdateCrownUI()
end

-- When an addon is loaded, if its name matches our mod then initialize
function OnAddOnLoaded(event, addon_name)
	if addon_name == RC.name then
		
		RC.settings = ZO_SavedVars:NewAccountWide("RoleCrowns_SavedVariables", 1, nil, RC.default_settings)
		RC:CreateRCSettingsMenu()
		
		Initialize()
		
		EVENT_MANAGER:RegisterForEvent(RC.name, EVENT_GROUP_MEMBER_LEFT, OnGroupChanged)
		EVENT_MANAGER:RegisterForEvent(RC.name, EVENT_GROUP_MEMBER_JOINED, OnGroupChanged)
		EVENT_MANAGER:RegisterForEvent(RC.name, EVENT_GROUP_MEMBER_ROLE_CHANGED, OnGroupChanged)
		EVENT_MANAGER:RegisterForEvent(RC.name, EVENT_PLAYER_ACTIVATED, OnGroupChanged)
	end
end


------------------------
--- Helper Functions ---
------------------------

-- Fetch group size and roles. Fill group_list
function UpdateGroupData()
	
	-- Halt the loop that updates player positions until we rebuild the group data
	StopPositionPoll()
	
	-- Clear group members from table
	RC.group_list = {} 

	-- Fetch number of group members
	RC.group_size = GetGroupSize()

	-- Get data for each group member and store the data in an array
	if (RC.group_size > 0) then	
		for i = 1, RC.group_size do
			-- Add new group member
			RC.group_list[i] = {}
			
			-- Fill member details
			RC.group_list[i].unittag = GetGroupUnitTagByIndex(i)
			RC.group_list[i].name = GetUnitName(RC.group_list[i].unittag) -- character name

			local is_dps, is_heal, is_tank = GetGroupMemberRoles(RC.group_list[i].unittag)
			if is_dps then
				RC.group_list[i].role = DPS_ID
			elseif is_heal then
				RC.group_list[i].role = HEAL_ID
			elseif is_tank then
				RC.group_list[i].role = TANK_ID
			else
				RC.group_list[i].role = NO_ROLE_ID
			end
			
			RC.group_list[i].x = -1
			RC.group_list[i].y = -1
			RC.group_list[i].z = -1
		end
	end
	
	-- Resume the loop that updates player positions
	StartPositionPoll()
	
	-- RunDebug()	
end

function UpdateCrownUI()

	RoleCrown_TopLevel:Create3DRenderSpace()
	RoleCrown_TopLevel:Set3DRenderSpaceOrigin(0,0,0)

	-- Draw crowns and set to update positions each frame
	if (RC.group_size > 0) then
		for i = 1, RC.group_size do
			AddNewRoleCrown(i)
		end
		DrawCrowns()
	else
		HideCrownUI()
	end
end

-- Starts a loop that updates the player positions so we can draw the 
-- crown directly over their head each frame.
function StartPositionPoll()
	EVENT_MANAGER:UnregisterForUpdate("PollPositions")
	EVENT_MANAGER:RegisterForUpdate("PollPositions", 0, function(time)
		
		if (RC.group_size > 0) then		
			for i = 1, (RC.group_size) do
				local mem_unittag = GetGroupUnitTagByIndex(i)
				local _, mem_worldX, mem_worldY, mem_worldZ = GetUnitWorldPosition(mem_unittag)
				local player_x, player_y, player_z = WorldPositionToGuiRender3DPosition(0,0,0)
				local worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(mem_worldX, mem_worldY, mem_worldZ)
			
				if not worldX then return end

				local height_above_head = (RC.settings.crown_y_offset / 10.0)
				local adjusted_worldY = worldY + PLAYER_HEIGHT + height_above_head
				
				RC.group_list[i].x = worldX
				RC.group_list[i].y = adjusted_worldY
				RC.group_list[i].z = worldZ
			end
		end
	end)	
end

function StopPositionPoll()
	EVENT_MANAGER:UnregisterForUpdate("PollPositions")
end

-- Initialize a new role crown for a group member
function AddNewRoleCrown(index)
	if IsUnitOnline(RC.group_list[index].unittag) then
		if ui[index] == nil then
			ui[index] = {}
		end

		-- We only draw a crown if one is not yet created (equal to nil), otherwise we would spawn 
		-- a new crown in the world every time a setting is changed. 

		if ui[index].fragment == nil then
			-- Set the control to only show when the player does not have menus open
			ui[index].fragment = ZO_SimpleSceneFragment:New(RoleCrown_TopLevel)
			
			-- Set crown to appear only during the following scenes
			HUD_UI_SCENE:AddFragment(ui[index].fragment)
			HUD_SCENE:AddFragment(ui[index].fragment)
			LOOT_SCENE:AddFragment(ui[index].fragment)
		end
			
		if ui[index].crown_control == nil then
			-- Create the player's crown
			ui[index].crown_control = WINDOW_MANAGER:CreateControl(nil, RoleCrown_TopLevel, CT_CONTROL)
			ui[index].crown_control:Create3DRenderSpace()
		end
		
		if ui[index].crown_texture == nil then
			-- Make the control 3 dimensional
			ui[index].crown_texture = WINDOW_MANAGER:CreateControl(nil, ui[index].crown_control, CT_TEXTURE)
			ui[index].crown_texture:Create3DRenderSpace()
		end
		
		-- Set texture and color based on the group member's role.
		-- SetColor() sets RGB between 0 and 1 (4th parameter sets alpha)
		if (RC.group_list[index].role == DPS_ID) and (RC.settings.show_dps_crowns == true) then
			ui[index].crown_texture:SetHidden(false)
			ui[index].crown_texture:SetTexture(RC.settings.dps_icon)
			ui[index].crown_texture:SetColor(RC.settings.dps_color[1],RC.settings.dps_color[2],RC.settings.dps_color[3],RC.settings.dps_color[4])  
		elseif (RC.group_list[index].role == HEAL_ID) and (RC.settings.show_healer_crowns == true) then
			ui[index].crown_texture:SetHidden(false)
		 	ui[index].crown_texture:SetTexture(RC.settings.healer_icon)
			ui[index].crown_texture:SetColor(RC.settings.healer_color[1],RC.settings.healer_color[2],RC.settings.healer_color[3],RC.settings.healer_color[4])  
		elseif (RC.group_list[index].role == TANK_ID) and (RC.settings.show_tank_crowns == true) then
			ui[index].crown_texture:SetHidden(false)
			ui[index].crown_texture:SetTexture(RC.settings.tank_icon)
			ui[index].crown_texture:SetColor(RC.settings.tank_color[1],RC.settings.tank_color[2],RC.settings.tank_color[3],RC.settings.tank_color[4])  
		elseif (RC.group_list[index].role == NO_ROLE_ID) and (RC.settings.show_no_role_crowns == true) then
			ui[index].crown_texture:SetHidden(false)
			ui[index].crown_texture:SetTexture(RC.settings.no_role_icon)
			ui[index].crown_texture:SetColor(RC.settings.no_role_color[1],RC.settings.no_role_color[2],RC.settings.no_role_color[3],RC.settings.no_role_color[4]) 
		else 
			-- Hide the crown if that specific role is set to hidden
			ui[index].crown_texture:SetHidden(true)
		end
		
		-- Hide crown if player crown is disabled
		if (AreUnitsEqual(RC.group_list[index].unittag, "player")) and (RC.settings.show_player_crown == false) then
			ui[index].crown_texture:SetHidden(true)
		end

		-- Set size of the crown
		local crown_scale = (RC.settings.crown_size / 10)
		ui[index].crown_texture:Set3DLocalDimensions(crown_scale, crown_scale)
		
		-- Disable depth buffer so the crown is not hidden behind world objects
		ui[index].crown_texture:Set3DRenderSpaceUsesDepthBuffer(false)
		ui[index].crown_texture:Set3DRenderSpaceOrigin(0,0,0)
	elseif ui[index] ~= nil then
		ui[index].crown_texture:SetHidden(true)
	end
end

-- Register an event that updates the role crowns each frame
function DrawCrowns()
	EVENT_MANAGER:UnregisterForUpdate("DrawCrownUI")
	
	-- Perform the following every single frame
	EVENT_MANAGER:RegisterForUpdate("DrawCrownUI", 0, function(time)
		
		local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
		
		if (RC.group_size > 0) then	
			for i = 1, RC.group_size do
				if IsUnitOnline(RC.group_list[i].unittag) then
					if ui[i] ~= nil then
						-- Align our crown with the camera's render space so it always faces the camera
						ui[i].crown_control:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
						ui[i].crown_control:Set3DRenderSpaceRight(rightX, rightY, rightZ)
						ui[i].crown_control:Set3DRenderSpaceUp(upX, upY, upZ)
						
						-- Set position above player's head
						ui[i].crown_control:Set3DRenderSpaceOrigin(RC.group_list[i].x, RC.group_list[i].y, RC.group_list[i].z)

						-- Add a pulsing animation
						if RC.settings.pulse_crowns and (ui[i].crown_texture:IsHidden() ~= true) then
							local time = GetFrameTimeSeconds()
							ui[i].crown_texture:SetAlpha(math.sin(2 * time) * 0.25 + 0.75)
						end
					end
				end
			end
		end
	end)
end

-- Remove the update event and hide the crown UI, called when the group is disbanded
function HideCrownUI()
	EVENT_MANAGER:UnregisterForUpdate("DrawCrownUI")
	
	if (RC.group_size > 0) then	
		for i = 1, RC.group_size do
			if ui[i].crown_control ~= nil then
				ui[i].crown_control:SetHidden(true)
			end
			if ui[i].crown_texture ~= nil then
				ui[i].crown_texture:SetHidden(true)
			end
		end
	end
end

-- Log group data
function LogGroupData()		
	if (RC.group_size > 0) then
		for i = 1, (RC.group_size) do
			local log_str = i .. " // " .. RC.group_list[i].name .. " // " .. RC.group_list[i].role .. " // " ..
			"(" .. RC.group_list[i].x .. ", ".. RC.group_list[i].y .. ", " .. RC.group_list[i].z .. ")"
			d(log_str)
		end
	end
end

function bool_to_int(my_bool)
	return my_bool and 1 or 0
end

-- Used to draw a crown and test script even when not grouped
function RunDebug()

	local debug_control, debug_texture

	-- make sure the control is only shown, when the player can see the world
	-- i.e. the control is only shown during non-menu scenes
	debug_fragment = ZO_HUDFadeSceneFragment:New(RoleCrown_TopLevel)
	HUD_UI_SCENE:AddFragment(debug_fragment)
	HUD_SCENE:AddFragment(debug_fragment)
	LOOT_SCENE:AddFragment(debug_fragment)

	debug_control = WINDOW_MANAGER:CreateControl(nil, RoleCrown_TopLevel, CT_CONTROL)
	debug_texture = WINDOW_MANAGER:CreateControl(nil, debug_control, CT_TEXTURE)
	
	-- make the control 3 dimensional
	debug_control:Create3DRenderSpace()
	debug_texture:Create3DRenderSpace()
	
	-- set texture, size and enable the depth buffer so the mage light is hidden behind world objects
	debug_texture:SetTexture(RC.settings.no_role_icon)
	local crown_scale = (RC.settings.crown_size / 10.0)
	debug_texture:Set3DLocalDimensions(crown_scale, crown_scale)
	debug_texture:Set3DRenderSpaceUsesDepthBuffer(false)
	debug_texture:Set3DRenderSpaceOrigin(0,0,0)				
	
	debug_texture:SetColor(RC.settings.no_role_color[1],RC.settings.no_role_color[2],RC.settings.no_role_color[3],RC.settings.no_role_color[4])  
	
	EVENT_MANAGER:UnregisterForUpdate("DebugTick")
	
	-- Perform the following every single frame
	EVENT_MANAGER:RegisterForUpdate("DebugTick", 0, function(time)
		
		local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
	
		-- Align our crown with the camera's render space so it always faces the camera
		debug_control:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
		debug_control:Set3DRenderSpaceRight(rightX, rightY, rightZ)
		debug_control:Set3DRenderSpaceUp(upX, upY, upZ)
				
		local player_x, player_y, player_z = Lib3D:ComputePlayerRenderSpacePosition()
		adjusted_y = player_y + PLAYER_HEIGHT + (RC.settings.crown_y_offset / 10.0)
		debug_control:Set3DRenderSpaceOrigin(player_x, adjusted_y, player_z)
	end)
end


----------------------
--- Event Triggers ---
----------------------

-- Event triggers should be the last calls in the script
-- This Event triggers whenever any addon loads
EVENT_MANAGER:RegisterForEvent(RC.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)


----------------------------
---------- NOTES -----------
----------------------------
-- Ui Scene notes: https://www.esoui.com/forums/showthread.php?t=5002
-- LUA array indexing starts at 1
-- Event Registering tut: https://wiki.esoui.com/Events#Event_Filtering
-- Mod To Do and Features
-- Draw map pin over each player in group, based on role, get world position
-- on leader swap, icon is lost
-- player activated called once when player loads in, not on group change
-- icon size slider, saved as var, can change for each role
-- Toggle showing different role icons
-- pulses option
-- only show during dungeon/trial option?
-- LibAddonMenu notes: https://github.com/sirinsidiator/ESO-LibAddonMenu/blob/master/LibAddonMenu-2.0/exampleoptions.lua
-- https://us.v-cdn.net/5020507/uploads/FileUpload/ba/8c30226aecb8e0f66948734f713b82.txt
-- https://www.esoui.com/downloads/info1664-Lib3D.html
-- get group num https://www.esoui.com/forums/showthread.php?t=2287
-- functions list https://esoapi.uesp.net/100023/functions.html
-- group size https://esoapi.uesp.net/100023/data/g/e/t/GetGroupSize.html
-- group function examples: https://esoapi.uesp.net/100023/src/ingame/group/zo_grouplist_manager.lua.html#83
-- group memeber roles https://esoapi.uesp.net/100023/data/g/e/t/GetGroupMemberRoles.html
-- get player roles: https://esoapi.uesp.net/100016/src/ingame/lfg/preferredroles.lua.html#27
-- Format: SetFloatingMarkerInfo(markerType [MapDisplayPinType], size [float], primaryTexturePath [string], secondaryTexturePath [string], primaryPulses [bool], secondaryPulses [bool])
-- Get position of a player: https://esoui.com/forums/showthread.php?p=34505

----------------------------
------- Unused Code --------
----------------------------
--local player_x, player_y, player_z = Lib3D:ComputePlayerRenderSpacePosition()
--RoleCrown_TopLevel:Set3DRenderSpaceOrigin(player_x, player_y + 2, player_z)

-- local loop_id = "update_player_pins_locations"
-- EVENT_MANAGER:RegisterForUpdate(loop_id, 5000, UpdatePlayerPinLocations)
-- EVENT_MANAGER:RegisterForEvent(RoleCrowns.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
-- EVENT_MANAGER:RegisterForEvent("MageLight", EVENT_ADD_ON_LOADED, RoleCrowns.OnAddOnLoaded)
-- local PULSES = true
-- local xLoc, yLoc = GetMapPlayerPosition("player")
-- tracker.headerPool = ZO_ControlPool:New("ZO_TrackedHeader", "", "TrackedHeader")
-- SetFloatingMarkerInfo(MAP_PIN_TYPE_GROUP_LEADER, 48, "RoleCrowns/icons/dps_crown_128x128.dds", "", PULSES)
-- SetFloatingMarkerInfo(MAP_PIN_TYPE_GROUP, 48, "RoleCrowns/icons/healer_crown_128x128.dds", "", PULSES)

--[[
function OnPlayerActivated()
	d("Player activated triggered")
	SetFloatingMarkerInfo(MAP_PIN_TYPE_GROUP_LEADER, 64, "RoleCrowns/icons/tank_crown_128x128.dds")
end
--]]

--[[
-- Log the player's world location
function UpdatePlayerPinLocations()
	-- worldY is height
	local worldX, worldY, worldZ = Lib3D:ComputePlayerRenderSpacePosition()
	output_string = worldX .. " " .. worldY .. " " .. worldZ
	d(output_string)
end

	
-- Fetchs location data for each group member, should be called each frame when drawing crowns
function UpdateGroupLocations()
	local group_size = GetGroupSize()
end
--]]

--[[
function StartSizePoll()
	EVENT_MANAGER:UnregisterForUpdate("PollGroupSize")
	EVENT_MANAGER:RegisterForUpdate("PollGroupSize", 0, function(time)
		
		if RC.group_size ~= GetGroupSize() then
			d("SIZE DIDN'T MATCH! UPDATE!")
			UpdateGroupData()
		end
	end)	
end
--]]


--[[

--log_str = i .. " - " .. name .. " - " .. " dps:" .. bool_to_int(is_dps) .. " heal:" .. bool_to_int(is_heal) .. " tank:" .. bool_to_int(is_tank)
--d(log_str)

-- Roles
-- local is_dps, is_healer, is_tank = GetGroupMemberRoles("player")
local is_dps, is_healer, is_tank = GetPlayerRoles()
local role_string = "DPS: " .. bool_to_int(is_dps) .. " | Healer: " .. 
					bool_to_int(is_healer) .. " | Tank: " .. bool_to_int(is_tank)
					
-- Positions
local player_x, player_y, player_z = Lib3D:ComputePlayerRenderSpacePosition()
local player_loc_string = "Render Space: " .. player_x .. " " .. player_y .. " " .. player_z


local _, worldX, worldY, worldZ = GetUnitWorldPosition("player")
local player_world_string = "World: " .. worldX .. " " .. worldY .. " " .. worldZ

-- Convert a player's world location to RenderSpace position
new_worldX, new_worldY, new_worldZ = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)
local adjusted_world_string = "New World: " .. new_worldX .. " " .. new_worldY .. " " .. new_worldZ

d(player_loc_string)
-- d(player_world_string)
d(adjusted_world_string)

-- Look in Lib3D for getting a group member's position
-- function lib:ComputePlayerRenderSpacePosition()
-- local _, worldX, worldY, worldZ = GetUnitWorldPosition("player")
-- worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)
-- return worldX, worldY, worldZ
-- end

if (group_size > 0) then
	local mem_unittag = GetGroupUnitTagByIndex(2)
	if mem_unittag then
		local mem_dps, mem_heal, mem_tank = GetGroupMemberRoles(mem_unittag)
		local mem_role_string = "Mem DPS: " .. bool_to_int(is_dps) .. " | Healer: " .. 
					bool_to_int(is_healer) .. " | Tank: " .. bool_to_int(is_tank)
		d(mem_role_string)
		
		local _, mem_worldX, mem_worldY, mem_worldZ = GetUnitWorldPosition(mem_unittag)
		newmem_worldX, newmem_worldY, newmem_worldZ = WorldPositionToGuiRender3DPosition(mem_worldX, mem_worldY, mem_worldZ)
		local new_world_string = "New Mem World: " .. newmem_worldX .. " " .. newmem_worldY .. " " .. newmem_worldZ
		d(new_world_string)
	end
end
--]]

-- Register a callback, so we know when to start/stop displaying the crown ui
-- Called whenever the zone changes
--Lib3D:RegisterWorldChangeCallback("WorldChange", function(identifier, zoneIndex, isValidZone, newZone)
--	d("WORLD CHANGE!")

--	if not newZone then return end
	
--	if isValidZone then
--		Initialize()
		-- UpdateCrownUI()
	-- else
		-- HideCrownUI()
--	end
--end)

--[[
if (RC.group_size > 0) then	
	for i = 1, RC.group_size do
		-- We only draw a crown if a member is online, this would be nil if they are off since we never make a crown
		if IsUnitOnline(RC.group_list[i].unittag) then
			if ui[i].crown_control ~= nil then
				ui[i].crown_control:SetHidden(false)
			end
			if ui[i].crown_texture ~= nil then
				ui[i].crown_texture:SetHidden(false)
			end
		end
	end
end
--]]
