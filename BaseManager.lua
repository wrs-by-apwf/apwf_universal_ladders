BaseLaddersManager = {}

local mod, BundleId = ModLoader.getModByName("abm_ladders");
g_LaddersBundleId = BundleId;

function PrintTable(Table)
	print("--------------------- TABLE PRINT -----------------------------")
	print(SavegameUtil.tableToString(Table))
	print("--------------------- TABLE PRINT -----------------------------")
end;


addModListener(BaseLaddersManager);

function BaseLaddersManager:load()
	if not InputMapper["LadderInteraction"] then InputMapper:addKey("Ladders", "LadderInteraction", "E") end
    LaddersManager:load()
end;

function BaseLaddersManager:update(dt)
    LaddersManager:update(dt)
end;
