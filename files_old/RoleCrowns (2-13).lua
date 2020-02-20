-------------------------------------
--- RoleCrowns by TheWizardLizard ---
-------------------------------------

-- ZOS has limited the ability to draw 3d ui elements during dungeons and trials.
-- https://www.reddit.com/r/elderscrollsonline/comments/8w2gd0/harvestmap_3d_pins_in_dungeons/

-- The function call to check roles fails during battlegrounds matches

RoleCrowns = {}
local rc_obj = RoleCrowns
rc_obj.name = "RoleCrowns"
rc_obj.group_list = {}
rc_obj.group_size = 0

TestCrown = {}
local test_control, test_texture

UICrowns = {}
local ui = UICrowns
local ICON_PATH = "RoleCrowns/icons"

-- When we fetch roles, we store the role as a string
local DPS_ID  = "dps"
local HEAL_ID = "healer"
local TANK_ID = "tank"
local INVALID_ID = "invalid" -- Assigned to any member that is unable to have role fetched

function Initialize()
	d("Initializing Role Crowns")
	
	-- Fetch current group members and roles
	UpdateGroupData()

	-- Create layer once
	RoleCrown_TopLevel:Create3DRenderSpace()
	RoleCrown_TopLevel:Set3DRenderSpaceOrigin(0,0,0)

	-- Set to draw crowns each frame
	-- Redraw crowns
	if (rc_obj.group_size > 0) then	
		for i = 1, rc_obj.group_size do
			DrawNewRoleCrown(i)
		end
		ShowCrownUI()
	else
		HideCrownUI()
	end
	
	local loop_log = "group_loop"
	EVENT_MANAGER:RegisterForUpdate(loop_log, 15000, LogGroupData)
end

function StartPositionPoll()
	EVENT_MANAGER:UnregisterForUpdate("PollPositions")
	EVENT_MANAGER:RegisterForUpdate("PollPositions", 0, function(time)
		
		if (rc_obj.group_size > 0) then		
			for i = 1, (rc_obj.group_size) do
				local mem_unittag = GetGroupUnitTagByIndex(i)
				local _, mem_worldX, mem_worldY, mem_worldZ = GetUnitWorldPosition(mem_unittag)
				local player_x, player_y, player_z = WorldPositionToGuiRender3DPosition(0,0,0)
				local worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(mem_worldX, mem_worldY, mem_worldZ)
			
				if not worldX then return end

				local player_height_offset = 2  -- How far the player's head is above their feet
				local height_above_head = 1.0     
				local adjusted_worldY = worldY + player_height_offset + height_above_head
				
				rc_obj.group_list[i].x = worldX
				rc_obj.group_list[i].y = adjusted_worldY
				rc_obj.group_list[i].z = worldZ
			end
		end
	end)	
end

function StopPositionPoll()
	EVENT_MANAGER:UnregisterForUpdate("PollPositions")
end

-- Fetch group size and roles. Fill group_list
function UpdateGroupData()
	d("Updating group data...")
	
	StopPositionPoll()
	
	-- Clear group members from table
	rc_obj.group_list = {} 

	-- Fetch number of group members
	rc_obj.group_size = GetGroupSize()
	-- local size_string = "Group Size: " .. rc_obj.group_size
	-- d(size_string)

	-- Get data for each group member and store the data in an array
	if (rc_obj.group_size > 0) then	
		d("Running update log")
		for i = 1, rc_obj.group_size do
		
			-- Add new group member
			rc_obj.group_list[i] = {}
			
			-- Fill member details
			rc_obj.group_list[i].unittag = GetGroupUnitTagByIndex(i)
			rc_obj.group_list[i].name = GetUnitName(rc_obj.group_list[i].unittag) -- character name

			local is_dps, is_heal, is_tank = GetGroupMemberRoles(rc_obj.group_list[i].unittag)
			if is_dps then
				rc_obj.group_list[i].role = DPS_ID
			elseif is_heal then
				rc_obj.group_list[i].role = HEAL_ID
			elseif is_tank then
				rc_obj.group_list[i].role = TANK_ID
			else
				rc_obj.group_list[i].role = INVALID_ID
			end
			
			rc_obj.group_list[i].x = -1
			rc_obj.group_list[i].y = -1
			rc_obj.group_list[i].z = -1
		end
	end
	
	StartPositionPoll()
	
	
	
		-- TEST CODE --
	
	-- make sure the control is only shown, when the player can see the world
	-- i.e. the control is only shown during non-menu scenes
	test_fragment = ZO_HUDFadeSceneFragment:New(RoleCrown_TopLevel)
	HUD_UI_SCENE:AddFragment(test_fragment)
	HUD_SCENE:AddFragment(test_fragment)
	LOOT_SCENE:AddFragment(test_fragment)
	
	--[[
	-- register a callback, so we know when to start/stop displaying the mage light
	Lib3D:RegisterWorldChangeCallback("MageLight", function(identifier, zoneIndex, isValidZone, newZone)
		if not newZone then return end
		
		if isValidZone then
			Example.ShowMageLight()
		else
			Example.HideMageLight()
		end
	end)
	--]]
	
	-- create the mage light
	-- we have one parent control (light) which we will move around the player
	-- and two child controls for the light's center and a periodically pulsing sphere
	test_control = WINDOW_MANAGER:CreateControl(nil, RoleCrown_TopLevel, CT_CONTROL)
	test_texture = WINDOW_MANAGER:CreateControl(nil, test_control, CT_TEXTURE)
	
	-- make the control 3 dimensional
	test_control:Create3DRenderSpace()
	test_texture:Create3DRenderSpace()
	
	-- set texture, size and enable the depth buffer so the mage light is hidden behind world objects
	test_texture:SetTexture(ICON_PATH .. "/healer_simple.dds")
	test_texture:Set3DLocalDimensions(1, 1)
	test_texture:Set3DRenderSpaceUsesDepthBuffer(true)
	test_texture:Set3DRenderSpaceOrigin(0,0,0.1)
	
	test_texture:SetColor(1.0, 0.0, 0.0)  
	test_texture:SetAlpha(0.5)
	
	EVENT_MANAGER:UnregisterForUpdate("TestTick")
	
	-- Perform the following every single frame
	EVENT_MANAGER:RegisterForUpdate("TestTick", 0, function(time)
		
		local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
	
		-- Align our crown with the camera's render space so it always faces the camera
		test_control:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
		test_control:Set3DRenderSpaceRight(rightX, rightY, rightZ)
		test_control:Set3DRenderSpaceUp(upX, upY, upZ)
				
		-- local player_x, player_y, player_z = WorldPositionToGuiRender3DPosition(0,0,0)
		local player_x, player_y, player_z = Lib3D:ComputePlayerRenderSpacePosition()
		test_control:Set3DRenderSpaceOrigin(player_x + 1, player_y + 2, player_z)
		-- RoleCrown_TopLevel:Set3DRenderSpaceOrigin(player_x + 1, player_y + 2, player_z)
		--RoleCrown_TopLevel:Set3DRenderSpaceOrigin(x, y, z)


		-- Add a pulsing animation
		-- center:SetAlpha(math.sin(2 * time) * 0.25 + 0.75)
		-- frame:Set3DLocalDimensions(time % 1, time % 1)
		-- frame:SetAlpha(1 - (time % 1))
	end)
	
end

-- If our group changes, update the member data
function OnGroupChanged(event, addon_name)
	
	-- Fetch updated data
	UpdateGroupData()
		
	-- Redraw crowns
	if (rc_obj.group_size > 0) then	
		for i = 1, rc_obj.group_size do
			DrawNewRoleCrown(i)
		end
		ShowCrownUI()
	else
		HideCrownUI()
	end
	
end

-- When an addon is loaded, if its name matches ours then initialize
function OnAddOnLoaded(event, addon_name)
	if addon_name == rc_obj.name then
		
		Initialize()
		
		EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_GROUP_MEMBER_LEFT, OnGroupChanged)
		EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_GROUP_MEMBER_JOINED, OnGroupChanged)
		EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_GROUP_MEMBER_ROLE_CHANGED, OnGroupChanged)
		EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_ZONE_CHANGED, OnGroupChanged)
		
		-- register a callback, so we know when to start/stop displaying the mage light
		Lib3D:RegisterWorldChangeCallback("CrownUI", function(identifier, zoneIndex, isValidZone, newZone)
			if not newZone then return end
			
			if isValidZone then
				ShowCrownUI()
			else
				HideCrownUI()
			end
		end)
	end
end


------------------------
--- Helper Functions ---
------------------------
function DrawNewRoleCrown(index)
	
	if IsUnitOnline(rc_obj.group_list[index].unittag) then
		if ui[index] == nil then
			d("make object")
			ui[index] = {}
		end

		if ui[index].fragment == nil then
			d("make fragment")
			-- Set the control to only show when the player does not have menus open
			ui[index].fragment = ZO_SimpleSceneFragment:New(RoleCrown_TopLevel)
			-- We set it to appear only during the following scenes
			HUD_UI_SCENE:AddFragment(ui[index].fragment)
			HUD_SCENE:AddFragment(ui[index].fragment)
			LOOT_SCENE:AddFragment(ui[index].fragment)
			WORLD_MAP_SCENE:AddFragment(ui[index].fragment)
			STATS_SCENE:AddFragment(ui[index].fragment)
			--INVENTORY_SCENE:AddFragment(ui[index].fragment)
			FRIENDS_LIST_SCENE:AddFragment(ui[index].fragment)
		end
			
		if ui[index].crown_control == nil then
			d("make control")
			-- Create the player's crown
			ui[index].crown_control = WINDOW_MANAGER:CreateControl(nil, RoleCrown_TopLevel, CT_CONTROL)
			ui[index].crown_control:Create3DRenderSpace()
		end
		
		if ui[index].crown_texture == nil then
			d("make texture")
			-- Make the control 3 dimensional
			ui[index].crown_texture = WINDOW_MANAGER:CreateControl(nil, ui[index].crown_control, CT_TEXTURE)
			ui[index].crown_texture:Create3DRenderSpace()
		end
		
		-- Set texture, size, and enable the depth buffer so the crown is hidden behind world objects
		--if rc_obj.group_list[index].role == DPS_ID then
		--	ui[index].crown_texture:SetTexture(ICON_PATH .. "/dps_simple.dds")
		--elseif rc_obj.group_list[index].role == HEAL_ID then
		-- 	ui[index].crown_texture:SetTexture(ICON_PATH .. "/heal_simple.dds")
		--elseif rc_obj.group_list[index].role == TANK_ID then
			ui[index].crown_texture:SetTexture(ICON_PATH .. "/tank_simple.dds")
		--else 
		--	ui[index].crown_texture:SetTexture(ICON_PATH .. "/dps_simple.dds")
		--end
		
		ui[index].crown_texture:Set3DLocalDimensions(.65, .65)
		ui[index].crown_texture:Set3DRenderSpaceUsesDepthBuffer(true)
		ui[index].crown_texture:Set3DRenderSpaceOrigin(0,0,0.0)
		
		-- Set RGB between 0 and 1 (overrides alpha value to 1)
		-- Can set alpha with its 4th parameter
		ui[index].crown_texture:SetColor(1.0, 0.0, 0.0)  

		-- Set alpha between 0 and 1
		ui[index].crown_texture:SetAlpha(0.5)
	end
end

-- Unhide Crown UI and set it to update each frame
function ShowCrownUI()
	
	if (rc_obj.group_size > 0) then	
		for i = 1, rc_obj.group_size do
			-- We only draw a crown if they are on, this would be nil if they are off since we never make a crown
			if IsUnitOnline(rc_obj.group_list[i].unittag) then
				if ui[i].crown_control ~= nil then
					ui[i].crown_control:SetHidden(false)
				end
				if ui[i].crown_texture ~= nil then
					ui[i].crown_texture:SetHidden(false)
				end
			end
		end
	end
	
	EVENT_MANAGER:UnregisterForUpdate("CrownUI")
	
	-- Perform the following every single frame
	EVENT_MANAGER:RegisterForUpdate("CrownUI", 0, function(time)
		
		local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
		
		if (rc_obj.group_size > 0) then	
			for i = 1, rc_obj.group_size do
				if IsUnitOnline(rc_obj.group_list[i].unittag) then
					-- Align our crown with the camera's render space so it always faces the camera
					ui[i].crown_control:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
					ui[i].crown_control:Set3DRenderSpaceRight(rightX, rightY, rightZ)
					ui[i].crown_control:Set3DRenderSpaceUp(upX, upY, upZ)
					
					-- Set position above player's head
					ui[i].crown_control:Set3DRenderSpaceOrigin(rc_obj.group_list[i].x, rc_obj.group_list[i].y, rc_obj.group_list[i].z)
				end
			end
		end
		
		--local player_x, player_y, player_z = Lib3D:ComputePlayerRenderSpacePosition()
		--RoleCrown_TopLevel:Set3DRenderSpaceOrigin(player_x, player_y + 2, player_z)
		

		-- Add a pulsing animation
		-- center:SetAlpha(math.sin(2 * time) * 0.25 + 0.75)
		-- frame:Set3DLocalDimensions(time % 1, time % 1)
		-- frame:SetAlpha(1 - (time % 1))
	end)
end

-- Remove the update handler and hide the Crown UI
function HideCrownUI()
	EVENT_MANAGER:UnregisterForUpdate("CrownUI")
	
	if (rc_obj.group_size > 0) then	
		for i = 1, rc_obj.group_size do
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
	if (rc_obj.group_size > 0) then
		for i = 1, (rc_obj.group_size) do
			local log_str = i .. " // " .. rc_obj.group_list[i].name .. " // " .. rc_obj.group_list[i].role .. " // " ..
			"(" .. rc_obj.group_list[i].x .. ", ".. rc_obj.group_list[i].y .. ", " .. rc_obj.group_list[i].z .. ")"
			d(log_str)
		end
	end
end

function bool_to_int(my_bool)
	return my_bool and 1 or 0
end

----------------------
--- Event Triggers ---
----------------------

-- Event triggers should be the last calls in the script
-- This Event triggers whenever any addon loads
EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)


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
		
		if rc_obj.group_size ~= GetGroupSize() then
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
