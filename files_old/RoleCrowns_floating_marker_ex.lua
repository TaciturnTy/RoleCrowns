-- Create a table to hold all our members
-- local lib3d = Lib3D("Lib3D-v3")

if RoleCrowns == nil then
	RoleCrowns = {}
	RoleCrowns.name = "RoleCrowns"
end

local loop_id = "update_player_pins_locations"

Example = {}
local light, frame, center
local PATH = "RoleCrowns/icons"


function RoleCrowns:Initialize()
	d("Initializing Role Crowns")
	
	-- EVENT_MANAGER:RegisterForUpdate(loop_id, 5000, UpdatePlayerPinLocations)
	
	
	
	--
	MageLight_TopLevel:Create3DRenderSpace()
	-- make sure the control is only shown, when the player can see the world
	-- i.e. the control is only shown during non-menu scenes
	local fragment = ZO_SimpleSceneFragment:New(MageLight_TopLevel)
	HUD_UI_SCENE:AddFragment(fragment)
	HUD_SCENE:AddFragment(fragment)
	LOOT_SCENE:AddFragment(fragment)
	
	-- register a callback, so we know when to start/stop displaying the mage light
	Lib3D:RegisterWorldChangeCallback("MageLight", function(identifier, zoneIndex, isValidZone, newZone)
		if not newZone then return end
		
		if isValidZone then
			Example.ShowMageLight()
		else
			Example.HideMageLight()
		end
	end)
	
	-- create the mage light
	-- we have one parent control (light) which we will move around the player
	-- and two child controls for the light's center and a periodically pulsing sphere
	light = WINDOW_MANAGER:CreateControl(nil, MageLight_TopLevel, CT_CONTROL)
	center = WINDOW_MANAGER:CreateControl(nil, light, CT_TEXTURE)
	frame = WINDOW_MANAGER:CreateControl(nil, light, CT_TEXTURE)
	
	-- make the control 3 dimensional
	light:Create3DRenderSpace()
	frame:Create3DRenderSpace()
	center:Create3DRenderSpace()
	
	-- set texture, size and enable the depth buffer so the mage light is hidden behind world objects
	center:SetTexture(PATH .. "/healer_crown_128x128.dds")
	center:Set3DLocalDimensions(1, 1)
	center:Set3DRenderSpaceUsesDepthBuffer(true)
	center:Set3DRenderSpaceOrigin(0,0,0.1)
	
	frame:SetTexture(PATH .. "/circle.dds")
	frame:Set3DLocalDimensions(0.5, 0.5)
	frame:Set3DRenderSpaceOrigin(0,0,0)
	frame:Set3DRenderSpaceUsesDepthBuffer(true)
	--
	
	
	
end

-- worldY is height
function UpdatePlayerPinLocations()
	local worldX, worldY, worldZ = Lib3D:ComputePlayerRenderSpacePosition()
	output_string = worldX .. " " .. worldY .. " " .. worldZ
	d(output_string)
end

-- If the loaded addon is ours, then...
function RoleCrowns.OnAddOnLoaded(event, addon_name)
	if addon_name == RoleCrowns.name then
		RoleCrowns:Initialize()
	end
end






function Example.ShowMageLight()
	light:SetHidden(false)
	frame:SetHidden(false)
	center:SetHidden(false)
	
	EVENT_MANAGER:UnregisterForUpdate("MageLight")
	-- perform the following every single frame
	EVENT_MANAGER:RegisterForUpdate("MageLight", 0, function(time)
		
		local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
		
		-- align our mage light with the camera's render space so the light is always facing the camera
		light:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
		light:Set3DRenderSpaceRight(rightX, rightY, rightZ)
		light:Set3DRenderSpaceUp(upX, upY, upZ)
		
		-- get the player position, so we can place the mage light nearby
		local worldX, worldY, worldZ = Lib3D:ComputePlayerRenderSpacePosition()
		if not worldX then return end
		-- this creates the circeling motion around the player
		local time = GetFrameTimeSeconds()
		worldX = worldX + math.sin(time)
		worldZ = worldZ + math.cos(time)
		worldY = worldY - 0.75 + 0.5 * math.sin(0.5 * time) + 3
		MageLight_TopLevel:Set3DRenderSpaceOrigin(worldX, worldY, worldZ)
		
		-- add a pulsing animation
		center:SetAlpha(math.sin(2 * time) * 0.25 + 0.75)
		frame:Set3DLocalDimensions(time % 1, time % 1)
		frame:SetAlpha(1 - (time % 1))
		
	end)
end

function Example.HideMageLight()
	-- remove the on update handler and hide the mage light
	EVENT_MANAGER:UnregisterForUpdate("MageLight")
	light:SetHidden(true)
	frame:SetHidden(true)
	center:SetHidden(true)
end

EVENT_MANAGER:RegisterForEvent("MageLight", EVENT_ADD_ON_LOADED, RoleCrowns.OnAddOnLoaded)




-- Event triggers whenever any addon loads
EVENT_MANAGER:RegisterForEvent(RoleCrowns.name, EVENT_ADD_ON_LOADED, RoleCrowns.OnAddOnLoaded)










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

-- EVENT_MANAGER:RegisterForEvent(RoleCrowns.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

-- Mod To Do and Features
-- Draw map pin over each player in group, based on role, get world position
-- on leader swap, icon is lost
-- player activated called once when player loads in, not on group change
-- icon size slider, saved as var, can change for each role
-- Toggle showing different role icons
-- pulses option

-- MAP_PIN_TYPE_GROUP
-- https://us.v-cdn.net/5020507/uploads/FileUpload/ba/8c30226aecb8e0f66948734f713b82.txt
-- SetFloatingMarkerInfo(markerType [MapDisplayPinType], size [float], primaryTexturePath [string], secondaryTexturePath [string], primaryPulses [bool], secondaryPulses [bool])
-- https://www.esoui.com/downloads/info1664-Lib3D.html

-- get group num https://www.esoui.com/forums/showthread.php?t=2287
-- functions list https://esoapi.uesp.net/100023/functions.html
-- group size https://esoapi.uesp.net/100023/data/g/e/t/GetGroupSize.html
-- group memeber roles https://esoapi.uesp.net/100023/data/g/e/t/GetGroupMemberRoles.html