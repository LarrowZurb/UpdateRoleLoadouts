
if ( isNil { getMissionConfigValue "LARs_roleData_monitor" } ) exitWith {};

//Broadcast mission name, used in exporting player saved loadouts
//on a per mission basis
if ( isServer ) then {
	 h = [] spawn {
	 	missionNamespace setVariable [ "LARs_roleData_MN", missionName, true ];
	};
};

//Only if we are a player client OR hosted server AND is MP
if ( isMultiplayer && hasInterface ) then {
	
	h = [] spawn {
		
		//Get missions respawn templates
		_respawnTemplates = getMissionConfigValue [ "respawnTemplates", [] ];
		
		//Get missions SIDE respawn templates
		_sideTemplates = getMissionConfigValue [ ("respawnTemplates" + str (side group player)), [] ];
		
		//If the mission is using a menuInventory template
		if (
			{ { "MenuInventory" == _x }count _x > 0 }count[ _respawnTemplates, _sideTemplates ] > 0
		) then {
			
			//When the player dies update the roles available
			player addEventHandler [ "Killed", {
				h = [ "ONKILLED" ] spawn LARs_fnc_roleData;
			}];
			
			//When the player exits a virtual arsenal update their role loadout
			[ missionNamespace, "ArsenalClosed", {
				[ "SAVE" ] call LARs_fnc_roleData
			}] call BIS_fnc_addScriptedEventHandler;		
			
		};
	};
};