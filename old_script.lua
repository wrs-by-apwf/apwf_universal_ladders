WorkingLadder					    = WorkingLadder or {};
local WorkingLadderClass		    = Class(WorkingLadder);

function WorkingLadder:load()
	local Supports    = RopewayManager.ropeways[self.name].supports;

	self.LadderSupportsByShaftId = self.LadderSupportsByShaftId or {};
	self.CurrentPlayerLadder = nil;
	self.CurrentPlayerLadderPos = nil;
	self.ClimbingSpeed = 0.25; -- in meters per second
	self.DistancePosVector = nil;
	self.DistancePos = 0;

	for k, v in pairs(Supports) do

		local Height = v.supportHeight
		local dataTable = v.shaftHeights[Height].Ladder;

		for i, j in pairs(dataTable) do

			local LadderSupport = {};

			if j.GroundIndex ~= nil or j.TopIndex ~= nil then
				local LowerPointId = getChild(v.shaftId, v.GroundIndex)
		        local HigherPointId = getChild(v.shaftId, v.TopIndex)

		        local xA, yA, zA = getWorldPosition(LowerPointId);
		        local xB, yB, zB = getWorldPosition(HigherPointId);

		        LadderSupport.ladderName = v.ladderName;

				if v.NextLadder ~= nil then 
					LadderSupport.NextLadder = v.NextLadder;
				end;

				if v.PreviousLadder ~= nil then 
					LadderSupport.PreviousLadder = v.PreviousLadder;
				end;

		    
		        LadderSupport.LowerPointPos = Vector3:new(xA, yA, zA);
		        LadderSupport.HigherPointPos = Vector3:new(xB, yB, zB);
		        LadderSupport.Distance = Vector3.distanceTo(LadderSupport.LowerPointPos, LadderSupport.HigherPointPos)
		        LadderSupport.UnboardLadderPos = v.UnboardLadderPos
			end;

			if j.RaycastCollider ~= nil then 
				LadderSupport.RaycastColliderId = getChild(v.shaftId, j.RaycastCollider);
			end;

			if j.LeaveIndex ~= nil then 
				local LeaveIndexId = getChild(v.shaftId, j.LeaveIndex);
				local xL, yL, zL = getWorldPosition(LeaveIndexId);
				LadderSupport.LeaveIndexPos = Vector3:new(xL, yL, zL);
			end;

			self.LadderSupportsByShaftId[v.shaftId][i] = LadderSupport;
		end;
	end;
end;

function WorkingLadder:update()

	if  InputMapper:getKeyDown(InputMapper.PomaEggLadderInteraction) and self.CurrentPlayerLadder ~= nil then
		return
	end;

	if self.CurrentPlayerLadder ~= nil then

		local Ladder = self.CurrentPlayerLadder
		local DistancePos = 0;

		if InputMapper:getKeyDown(InputMapper.Walk_Forward) then

			DistancePos = self.DistancePos + (0.1 * self.ClimbingSpeed);

		elseif InputMapper:getKeyDown(InputMapper.Walk_Down) then

			DistancePos = self.DistancePos - (0.1 * self.ClimbingSpeed);

	    end
		
		if (DistancePos > Ladder.Distance) and (Ladder.NextLadder == nil) then --- no further ladder, end of the climb
			
		    self:EndClimbing();
 
		elseif (DistancePos > Ladder.Distance) and (Ladder.NextLadder ~= nil) then

			self:NextLadder();

			-- decrement or leave

		elseif (DistancePos <= 0) and (Ladder.PreviousLadder ~= nil) then

			self:PreviousLadder();
			-- increment to next ladder or leave
		
		end;

		local DistancePos01 = (DistancePos / Ladder.Distance);
		self.DistancePosVector = Vector3.lerp(Ladder.LowerPointPos, Ladder.HigherPointPos, DistancePos01)

		local x, y, z = Vector3.unpack(self.DistancePosVector)
		g_scenario.player:moveToFeet(x,y,z);
		self.DistancePos = DistancePos;
	end;

	if InputMapper:getKeyDown(InputMapper.PomaEgg_LadderInteraction) then

		if self.CurrentPlayerLadder ~= nil then
			self:leaveLadder();
		else
		    local hit, id, point, distance = Utils.raycastScreenPoint(4500)
		    print("Ladder Raycast sent")

		    if hit and id ~= GameControl.getTerrainId() then
			    if self.LadderSupportsByColliderId[id] ~= nil then
				    self:EnterLadder(id)
			    end;
		    end;
	    end;
	end;

end;

function WorkingLadder:EnterLadder(ColliderId)
	print("Entering Ladder")

	local ladder = self.LadderSupportsByColliderId[ColliderId];

	g_GUI:addKeyHint(InputMapper.Walk_Forward,		"Go up");
	g_GUI:addKeyHint(InputMapper.Walk_Down,		"Go Down");
	g_GUI:addKeyHint(InputMapper.PomaEgg_LadderInteraction,	"Leave Ladder");

	self.CurrentPlayerLadder = ladder;
	self.CurrentPlayerLadderPos = 0;
end;

function WorkingLadder:NextLadder()
	for k, v in pairs(self.LadderSupportsByShaftId) do

		if v.ladderName == self.CurrentPlayerLadder.NextLadder then
			self.CurrentPlayerLadder = v;
			self.DistancePos = 0;
		else 
			print("can't find a ladder with the name : " .. v.ladderName)
		end;

	end;
end;

function WorkingLadder:PreviousLadder()
	for k, v in pairs(self.LadderSupportsByShaftId) do

		if v.ladderName == self.CurrentPlayerLadder.PreviousLadder then
			self.CurrentPlayerLadder = v;
			self.DistancePos = self.CurrentPlayerLadder.Distance;
		else 
			print("can't find a ladder with the name : " .. v.ladderName)
		end;

	end;
end;


function WorkingLadder:leaveLadder() -- Leave the ladder at the current Position 

	self.CurrentPlayerLadder = nil;


end;

function WorkingLadder:EndClimbing() -- Leave the ladder by teleporting the player to the location of the leave index

	local x, y, z = Vector3.unpack(CurrentPlayerLadder.LeaveIndexPos)

	g_scenario.player:moveToFeet(x, y, z);
	self.CurrentPlayerLadder = nil;
	self.CurrentPlayerLadderPos = nil;
	
end;