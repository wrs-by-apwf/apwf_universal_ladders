LaddersManager					    = LaddersManager or {}
local LaddersManagerClass		    = Class(LaddersManager)

InputMapper:addKey("Ladders", "LadderInteraction", "E")


function LaddersManager:load()
	print("------------ Airborne | Universal Ladders ------------")
	print("The script is now running")
	self.ClimbingSpeed = 1 -- in meters per second

	self.LocalPlayerLadder = nil
	self.LocalPlayerPortion = nil
	self.LocalPlayerInt = 1
	self.LocalPlayerPos = 0
	self.LocalPlayerDirection = 1
	

	self.MetalWalkSound = Utils.loadBundleGameObject(g_LaddersBundleId, "Audio_Ladder_metalStepUp")
	setParent(self.MetalWalkSound, g_scenario.player.transformId)
	self.isPlayingSound = false
end

function LaddersManager:update(dt)

	if self.LocalPlayerLadder ~= nil and self.LocalPlayerPortion ~= nil then

		local Portion = self.LocalPlayerPortion
		local IncrementPos = 0

		if InputMapper:getKey(InputMapper.Walk_Forward) and not g_GUI:getAnyGuiActive() then

			if not self.isPlayingSound then
				AudioSource.play(self.MetalWalkSound)
				self.isPlayingSound = true
			end

			IncrementPos = (self.ClimbingSpeed * dt)

		elseif InputMapper:getKey(InputMapper.Walk_Backward) and not g_GUI:getAnyGuiActive() then

			if not self.isPlayingSound then
				AudioSource.play(self.MetalWalkSound)
				self.isPlayingSound = true
			end

			IncrementPos = -(self.ClimbingSpeed * dt)

	    end

		if (not InputMapper:getKey(InputMapper.Walk_Forward) and (not InputMapper:getKey(InputMapper.Walk_Backward))) then
			if self.isPlayingSound then
				self.isPlayingSound = false
				AudioSource.stop(self.MetalWalkSound)
			end
		end

		local DistancePos = self.LocalPlayerPos + IncrementPos
		
		if DistancePos > Portion.Distance then
			local NextPortion = self:NextPortion(DistancePos - Portion.Distance)
			if not NextPortion then
                self:leave(Vector3.lerp(Portion.BottomPos, Portion.TopPos, 1))
				return
            elseif NextPortion then 
				return
			end
		elseif DistancePos < 0 then
			local PreviousPortion = self:PreviousPortion(DistancePos)
			if not PreviousPortion then
                self:leave(Vector3.lerp(Portion.BottomPos, Portion.TopPos, 0))
				return
            elseif PreviousPortion then 
				return
			end
		end
		

		local DistancePos01 = (DistancePos / Portion.Distance)
		self.DistancePosVector = Vector3.lerp(Portion.BottomPos, Portion.TopPos, DistancePos01)
		self.LocalPlayerPos = DistancePos

		if InputMapper:getKeyDown(InputMapper.LadderInteraction) and not g_GUI:getAnyGuiActive() then
			self:leave(self.DistancePosVector)
			return
		end

		g_scenario.player:moveToFeet(Vector3.unpack(self.DistancePosVector))

	elseif InputMapper:getKeyDown(InputMapper.LadderInteraction) and not g_GUI:getAnyGuiActive() then

		-- sending a raycast 
		local hit, id, point, distance = Utils.raycastScreenPoint(4500)
		if hit and id ~= GameControl.getTerrainId() then

			-- getting basic values 
			local ColliderName = getName(id)
			local LadderId = getParent(id)
			local LadderName = getName(LadderId)

			-- construct the ladder for the script 
			if (LadderName:find("_LadderScript") ~= nil) then
				local Ladder = {}

				for num, Pid  in getChildren(LadderId) do
					local Portion = {}

					local PortionName = getName(Pid)


					local PortionTop = nil
					local PortionDown = nil

					if (PortionName:find("_portion") ~= nil) then
						PortionTop = getChild(Pid, "top")
					    PortionDown = getChild(Pid, "bottom")

						if (PortionTop ~= (Pid or nil)) and (PortionDown ~= (Pid or nil)) then
							Portion.TopPos = Vector3:new(getWorldPosition(PortionTop))
							Portion.BottomPos = Vector3:new(getWorldPosition(PortionDown))
							Portion.Distance = Vector3.distanceTo(Portion.TopPos, Portion.BottomPos)
	
							table.insert(Ladder, Portion)
						end
					end
				end

				-- avoid to enter empty ladder
				if #Ladder < 1 then return end
				
				-- if we hit the bottom collider then we can enter first portion
				if (ColliderName == "collider") then 
					self:EnterLadder(Ladder, 1, 1)
				end

				-- if we hit the top collider then we can enter last portion at the last position
				if (ColliderName == "TopCollider") then
					self:EnterLadder(Ladder, #Ladder, -1)
				end
			end
		end
	end
end

function LaddersManager:EnterLadder(Ladder, portion, direction)
	self.LocalPlayerLadder = Ladder
	self.LocalPlayerPortion = Ladder[portion]
	self.LocalPlayerInt = portion

	if direction == 1 then
		self.LocalPlayerPos = 0
	else
		self.LocalPlayerPos = self.LocalPlayerPortion.Distance
	end
	self.LocalPlayerDirection = direction
end

function LaddersManager:NextPortion(PosCorrecter)

	self.LocalPlayerInt = self.LocalPlayerInt + 1
	self.LocalPlayerPortion = self.LocalPlayerLadder[self.LocalPlayerInt]

	if self.LocalPlayerPortion ~= nil then -- we have another portion
		self.LocalPlayerPos = 0  + PosCorrecter
		return true
	end
	return false
end

function LaddersManager:PreviousPortion(PosCorrecter)

	self.LocalPlayerInt = self.LocalPlayerInt - 1
	self.LocalPlayerPortion = self.LocalPlayerLadder[self.LocalPlayerInt]

	if self.LocalPlayerPortion ~= nil then -- we have another portion
		self.LocalPlayerPos = self.LocalPlayerPortion.Distance + PosCorrecter
		return true
	end
	return false

end

function LaddersManager:leave(LeaveVector) -- Leave the ladder by teleporting the player to the location of the leave index
	local x, y, z = Vector3.unpack(LeaveVector)

	AudioSource.stop(self.MetalWalkSound)
	g_scenario.player:moveToFeet(x, y, z)
	self.LocalPlayerLadder = nil
	self.LocalPlayerPos = 0
	self.LocalPlayerInt = 0
	self.LocalPlayerPortion = nil
end