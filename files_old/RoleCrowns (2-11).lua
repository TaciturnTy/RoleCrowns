-------------------------------------
--- RoleCrowns by TheWizardLizard ---
-------------------------------------

RoleCrowns = {}
local rc_obj = RoleCrowns
rc_obj.name = "RoleCrowns"
rc_obj.group_list = {}
rc_obj.group_size = 0

Example = {}
local crown_control, crown_texture
local ICON_PATH = "RoleCrowns/icons"

-- When we fetch roles, we store the role as a string
local DPS_ID  = "dps"
local HEAL_ID = "healer"
local TANK_ID = "tank"
local INVALID_ID = "invalid" -- String is assigned if a member is unable to have role fetched


function Initialize()
	d("Initializing Role Crowns")
		
	-- Fetch current group members and roles
	-- UpdateGroupData()
	AddItems()
	
	local loop_update = "update_loop"
	EVENT_MANAGER:RegisterForUpdate(loop_update, 5000, AddItems)
	
	local loop_log = "group_loop"
	EVENT_MANAGER:RegisterForUpdate(loop_log, 10000, LogGroupData)
	
	-- Set to draw crowns each frame
	-- DrawRoleCrownsUI() 
end


-- DELETE ME, for testing
function AddItems()
	d("added players")
	
	rc_obj.group_list = {} 

	
	local group_member1 = {}
	group_member1.name = "Tyler"
	group_member1.role = HEAL_ID

	local group_member2 = {}
	group_member2.name = "Hero"
	group_member2.role = DPS_ID

	rc_obj.group_list[1] = group_member1
	rc_obj.group_list[2] = group_member2
	
	rc_obj.group_size = 2

end


-- Fetch group size and roles. Fill group_list
function UpdateGroupData()
	d("Updating group data...")
	
	-- Clear group members from table
	rc_obj.group_list = {} 

	-- Fetch number of group members
	rc_obj.group_size = GetGroupSize()
	local size_string = "Group Size: " .. rc_obj.group_size
	d(size_string)

	-- Get data for each group member and store the data in an array
	if (rc_obj.group_size > 0) then		
		for i = 1, rc_obj.group_size do
			local group_member = {}
			group_member.unittag = GetGroupUnitTagByIndex(i)
			group_member.name = GetUnitName(unittag) -- get character name
			-- local name = GetUnitDisplayName(unittag) -- gets account name
			
			local is_dps, is_heal, is_tank = GetGroupMemberRoles(unittag)
			if is_dps then
				group_member.role = DPS_ID
			elseif is_heal then
				group_member.role = HEAL_ID
			elseif is_tank then
				group_member.role = TANK_ID
			else
				group_member.role = INVALID_ID
			end
			
			-- Add new member to group_list
			rc_obj.group_list[i] = group_member
		end
	end
end

-- If our group changes, update the member data
function OnGroupChanged(event, addon_name)
	if addon_name == rc_obj.name then
		UpdateGroupData()
	end
end

-- When an addon is loaded, if its name matches ours then initialize
function OnAddOnLoaded(event, addon_name)
	if addon_name == rc_obj.name then
		--EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_GROUP_UPDATE, OnGroupChanged)
		--EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_GROUP_MEMBER_LEFT, OnGroupChanged)
		--EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_GROUP_MEMBER_JOINED, OnGroupChanged)
		--EVENT_MANAGER:RegisterForEvent(rc_obj.name, EVENT_GROUP_MEMBER_ROLE_CHANGED, OnGroupChanged)
		Initialize()
	end
end


------------------------
--- Helper Functions ---
------------------------
function DrawRoleCrownsUI()

	RoleCrown_TopLevel:Create3DRenderSpace()
	
	-- Set the control to only show when the player does not have menus open
	local fragment = ZO_SimpleSceneFragment:New(RoleCrown_TopLevel)
	HUD_UI_SCENE:AddFragment(fragment)
	HUD_SCENE:AddFragment(fragment)
	LOOT_SCENE:AddFragment(fragment)
	
	-- register a callback, so we know when to start/stop displaying the mage light
	Lib3D:RegisterWorldChangeCallback("CrownUI", function(identifier, zoneIndex, isValidZone, newZone)
		if not newZone then return end
		
		if isValidZone then
			Example.ShowCrownUI()
		else
			Example.HideCrownUI()
		end
	end)
	
	-- Create the player's crown
	crown_control = WINDOW_MANAGER:CreateControl(nil, RoleCrown_TopLevel, CT_CONTROL)
	crown_texture = WINDOW_MANAGER:CreateControl(nil, crown_control, CT_TEXTURE)
	
	-- Make the control 3 dimensional
	crown_control:Create3DRenderSpace()
	crown_texture:Create3DRenderSpace()

	-- Set texture, size, and enable the depth buffer so the crown is hidden behind world objects
	crown_texture:SetTexture(ICON_PATH .. "/dps_simple.dds")
	crown_texture:Set3DLocalDimensions(.65, .65)
	crown_texture:Set3DRenderSpaceUsesDepthBuffer(true)
	crown_texture:Set3DRenderSpaceOrigin(0,0,0.0)
	
	
	-- Set RGB between 0 and 1 (overrides alpha value to 1)
	-- Can set alpha with its 4th parameter
	crown_texture:SetColor(1.0, 0.0, 0.0)  
	
	-- Set alpha between 0 and 1
	crown_texture:SetAlpha(0.5)

end

-- Unhide Crown UI and set it to update each frame
function Example.ShowCrownUI()
	crown_control:SetHidden(false)
	crown_texture:SetHidden(false)
	
	EVENT_MANAGER:UnregisterForUpdate("CrownUI")
	
	-- perform the following every single frame
	EVENT_MANAGER:RegisterForUpdate("CrownUI", 0, function(time)
		
		local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
		
		-- Align our crown with the camera's render space so it always faces the camera
		crown_control:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
		crown_control:Set3DRenderSpaceRight(rightX, rightY, rightZ)
		crown_control:Set3DRenderSpaceUp(upX, upY, upZ)
		
		-- TEMP CODE
		if (rc_obj.group_size > 0) then		
			for i = 1, (rc_obj.group_size) do
				local mem_unittag = GetGroupUnitTagByIndex(i)
				local _, mem_worldX, mem_worldY, mem_worldZ = GetUnitWorldPosition(mem_unittag)
				local worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(mem_worldX, mem_worldY, mem_worldZ)
			
				if not worldX then return end

				local player_height_offset = 2  -- How far the player's head is above their feet
				local height_above_head = 1.0     
				local adjusted_worldY = worldY + player_height_offset + height_above_head
				
				rc_obj.group_list[i].x = worldX
				rc_obj.group_list[i].y = adjusted_worldY
				rc_obj.group_list[i].z = worldZ
			end
			-- RoleCrown_TopLevel:Set3DRenderSpaceOrigin(worldX, adjusted_worldY, worldZ)
		else
		-- END TEMP CODE
			-- Get the player's position (of their feet), so we can place the crown nearby
			-- local worldX, worldY, worldZ = Lib3D:ComputePlayerRenderSpacePosition()
			-- if not worldX then return end
					
			-- local player_height_offset = 2  -- How far the player's head is above their feet
			-- local height_above_head = 0.65     
			-- local adjusted_worldY = worldY + player_height_offset + height_above_head
	
			-- RoleCrown_TopLevel:Set3DRenderSpaceOrigin(worldX, adjusted_worldY, worldZ)
		end
		
		-- Add a pulsing animation
		-- center:SetAlpha(math.sin(2 * time) * 0.25 + 0.75)
		-- frame:Set3DLocalDimensions(time % 1, time % 1)
		-- frame:SetAlpha(1 - (time % 1))
	end)
end

-- Remove the update handler and hide the Crown UI
function Example.HideCrownUI()
	EVENT_MANAGER:UnregisterForUpdate("CrownUI")
	light:SetHidden(true)
	crown:SetHidden(true)
end

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

-- Log group data
function LogGroupData()	

	-- d("Size = " .. RoleCrowns.group_size)
	
	if (rc_obj.group_size > 0) then
		for i = 1, (rc_obj.group_size) do
			log_str = i .. " - " .. rc_obj.group_list[i].name .. " - " .. rc_obj.group_list[i].role -- .. " - " ..
			-- "(" .. rc_obj.group_list[i].x .. ",".. rc_obj.group_list[i].y .. "," .. rc_obj.group_list[i].z .. ")"
			d(log_str)
		end
	end
	
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

