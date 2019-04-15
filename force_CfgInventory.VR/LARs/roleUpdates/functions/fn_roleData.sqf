
params[ "_mode", "_this" ];


switch ( toUpper _mode ) do {
	
	//Update data for available roles available
	//called during the respawn screen when BIs role meta data changes
	case "DATA" : {
		params[ "_roleData" ];
		
		//If there is no current data
		if ( isNil "LARs_roleData" ) then {
			
			//Init data arrray
			LARs_roleData = [];
			
			//For each role
			{
				//Get the role name
				_role = ( _x select 0 ) select 0;
				//Get the roles available loadouts
				_loadouts = _x select 1;
				//Add role to data
				_index = LARs_roleData pushBack [ _role, [] ];
				//Get roles loadout array
				_loadoutArray = LARs_roleData select _index select 1;
				//for each loadout
				{
					//Get its name
					_name = _x select 1;
					//Add an array of loadout name and empty string to hold
					//saved players loadout name
					_nul = _loadoutArray pushBack [ _name, "" ];
				}forEach _loadouts;
			}forEach _roleData;
			
			//LARs_roleData was empty so this must be the player respawning
			//for the first time, import any previous role data for this mission
			[ "IMPORT" ] spawn LARs_fnc_roleData;
			
		}else{
			//If the data already exist
			//for each role
			{
				//Get roles name
				_role = ( _x select 0 ) select 0;
				//Get roles available loadouts
				_loadouts = _x select 1;
				//See if role already exist in data
				private _roleIndex = {
					if ( _x select 0 == _role ) exitWith {
						_forEachIndex;
					};
				}forEach LARs_roleData;
				//If its does
				if ( !isNil "_roleIndex" ) then {
					//Get the saved loadouts
					_loadoutsData = ( LARs_roleData select _roleIndex ) select 1;
					//For each roles loadouts
					{
						//Get its name
						_name = _x select 1;
						//See if we already have data for this loadout
						private _found = {
							if ( _x select 0 == _name ) exitWith {
								true
							};
						}forEach _loadoutsData;
						//If we dont
						if ( isNil "_found" ) then {
							//Add an array of loadout name and empty string to hold
							//saved players loadout name
							_nul = _loadoutsData pushBack [ _name, "" ];
						};
					}forEach _loadouts;
				}else{
					_roleIndex = LARs_roleData pushBack [ _role, [] ];
					//Get roles loadout array
					_loadoutArray = LARs_roleData select _roleIndex select 1;
					//for each loadout
					{
						//Get its name
						_name = _x select 1;
						//Add an array of loadout name and empty string to hold
						//saved players loadout name
						_nul = _loadoutArray pushBack [ _name, "" ];
					}forEach _loadouts;
				};
			}forEach _roleData;
			
		};
				
	};
	
	//Apply a saved roles loadout when respawning
	case "APPLY" : {
		if !( canSuspend ) exitWith {
			[ "APPLY" ] spawn LARs_fnc_roleData;
		};
		
		//Get current role
		( [ "GET" ] call LARs_fnc_roleData ) params[ "_roleIndex", "_loadoutIndex" ];
		
		//If there is no roleIndex exit
		if ( isNil "_roleIndex" ) exitWith {};
		
		_sortedRoleData = [ "SORT" ] call LARs_fnc_roleData;
		
		//Get saved loadout
		//TODO: Check if this is correct? Does an added class actually go to the back of BIs data
		//LARs data does push it ot the back,  do they match????
		_loadout = ((( _sortedRoleData select _roleIndex ) select 1 ) select _loadoutIndex ) select 1;
		
		//If there is a saved loadout apply it
		if !( _loadout == "" ) then {
			//Small pause to make sure BIs system has applied selected roles loadout
			sleep 0.1;
			[ player, [ missionNamespace, _loadout ] ] call BIS_fnc_loadInventory;
		};
	};
	
	//Save a loadout for role
	//called when a VA closes
	case "SAVE" : {
		//Get current role
		( [ "GET" ] call LARs_fnc_roleData ) params[ "_roleIndex", "_loadoutIndex" ];
		
		//If there is no roleIndex exit
		if ( isNil "_roleIndex" ) exitWith {};
		
		_sortedRoleData = [ "SORT" ] call LARs_fnc_roleData;
		
		//TODO: Check if this is correct? Does an added class actually go to the back of BIs data
		//LARs data does push it to the back,  do they match????
		_roleName = ( _sortedRoleData select _roleIndex ) select 0;
		_loadoutName = ((( _sortedRoleData select _roleIndex ) select 1 ) select _loadoutIndex ) select 0;
		
		_savedInventoryName = format[ "%1_%2", _roleName, _loadoutName ];
		
		[ player, [ missionNamespace, _savedInventoryName ] ] call BIS_fnc_saveInventory;
		
		//Save loadout reference
		((((( LARs_roleData select { _x select 0 == _roleName } ) select 0 ) select 1 ) select { _x select 0 == _loadoutName } ) select 0 ) set [ 1, _savedInventoryName ];
		
		[ "EXPORT" ] spawn LARs_fnc_roleData;
	};
	
	//Reset a monitored loadout
	case "RESET" : {
		//Get current role
		( [ "GET" ] call LARs_fnc_roleData ) params[ "_roleIndex", "_loadoutIndex" ];
		
		//If there is no roleIndex exit
		if ( isNil "_roleIndex" ) exitWith {};
		
		_sortedRoleData = [ "SORT" ] call LARs_fnc_roleData;
		
		//TODO: Check if this is correct? Does an added class actually go to the back of BIs data
		//LARs data does push it to the back,  do they match????
		_roleName = ( _sortedRoleData select _roleIndex ) select 0;
		_loadoutName = ((( _sortedRoleData select _roleIndex ) select 1 ) select _loadoutIndex ) select 0;
		
		//Reset data to ""
		//Next time respawn menu is shown BIs meta data will take over
		((((( LARs_roleData select { _x select 0 == _roleName } ) select 0 ) select 1 ) select { _x select 0 == _loadoutName } ) select 0 ) set [ 1, "" ];
		
	};
	
	//Sort LARs_roleData by roleName and each loadout by its name
	//So we can get the right index for "BIS_RscRespawnControls_selected"
	//as respawnMenu list boxes are sorted alphabetically
	case "SORT" : {
		
		_data = +LARs_roleData;
		_data sort true;
		{
			_loadouts = _x select 1;
			_loadouts sort true;
		}forEach _data;
		
		_data
	};
	
	//Get players current role and loadout index
	case "GET" : {
		private[ "_isMonitored" ];
		
		//Get role and loadout indexes for BIs respawn screen
		_lastRoleInfo = uiNamespace getVariable [ "BIS_RscRespawnControls_selected", [] ];
		( _lastRoleInfo select [ 1, 2 ] ) params[ "_roleIndex", "_loadoutIndex" ];
		
		//Sort data in alphabetic order
		_sortedRoleData = [ "SORT" ] call LARs_fnc_roleData;
		
		//TODO: Check if this is correct? Does an added class actually go to the back of BIs data
		//LARs data does push it ot the back,  do they match????
		_roleName = ( _sortedRoleData select _roleIndex ) select 0;
		_loadoutName = ((( _sortedRoleData select _roleIndex ) select 1 ) select _loadoutIndex ) select 0;
		
		//Is this a monitored role loadout
		_isMonitored = [ "MONITORED", [ _roleName, _loadoutName ] ] call LARs_fnc_roleData;
		
		//If there is no indexes OR its an unmonitored role loadout
		if ( _lastRoleInfo isEqualTo [] || { !_isMonitored } ) exitWith {
			[]
		};
		
		//Else return role and loadout indexes
		_lastRoleInfo select [ 1, 2 ]
	};
	
	//This funtion has two uses
	//ONE: Update combo loadout in respawn menu
	//TWO: Make sure LARs_roleData is in sync with BIs role data
	case "ONKILLED" : {
		if !( canSuspend ) exitWith {
			[ "ONKILLED" ] spawn LARs_fnc_roleData;
		};

		//Get BIs meta data for role loadouts
		_rolesMetaData = { uiNamespace getVariable "BIS_RscRespawnControls_invMetadata" };
		
		//Make sure it exists
		waitUntil{ !isNil { call _rolesMetaData } };

		//Function to inject saved role loadouts into BIs role meta data
		_fnc_updateCombo = {
			while{ !alive player } do {
				
				_inventoryRolesData = uiNamespace getVariable [ "BIS_RscRespawnControls_invMetadata", [] ];
				{
					_roleIndex = _forEachIndex;
					_roleName = _x select 0 select 0;
					_roleLoadouts = _x select 1;
					
					{
						_loadoutIndex = _forEachIndex;
						_loadoutData = _x select 1;
						_savedLoadoutName = ((( LARs_roleData select _roleIndex ) select 1 ) select _loadoutIndex ) select 1;
						
						//If the saved data is not empty & BIs meta has not been upadted
						if ( !( _savedLoadoutName == "" ) && { !( _loadoutData isEqualType [] ) } ) then {
							//Inject data into BIs role meta data
							((( _inventoryRolesData select _roleIndex ) select 1 ) select _loadoutIndex ) set[ 2, [ missionNamespace, _savedLoadoutName ] ];
							uiNamespace setVariable [ "BIS_RscRespawnControls_invMetadata", _inventoryRolesData ];
						};					
					}forEach _roleLoadouts;
				}forEach _inventoryRolesData;
			};
		};
		
		_roleData = call _rolesMetaData;
		
		if ( isNil "LARs_roleData" ) then {
			//Init saved data
			[ "DATA", [ _roleData ] ] call LARs_fnc_roleData;
		};
		
		//Update combo loadouts
		_nul = [] spawn _fnc_updateCombo;
		
		//While we are still looking at the respawn menu
		while{ !alive player } do {
			//If our copy is out of date
			if !( _roleData isEqualTo call _rolesMetaData ) then {
				//And the metadata has not been cleared
				if !( isNil _rolesMetaData  ) then {
					//update our copy
					_roleData = call _rolesMetaData;
					//Update saved data
					[ "DATA", [ _roleData ] ] call LARs_fnc_roleData;
				};
			};
		};
		
		//We have just respawned, apply users saved loadout
		[ "APPLY" ] call LARs_fnc_roleData;
	};
	
	//Save role loadout info to users profileNamespace
	//Structure is LARs_roleInfo [ [ missionName, _roleData ], [ missionName, _roleData ] ]
	case "EXPORT" : {
		
		//If the mission has not been flagged to save player roleData then exit
		if ( getMissionConfigValue [ "LARs_roleData_save", 0 ] isEqualTo 0 ) exitWith {};
		
		//Get a copy of the current roleData
		_roleData = +LARs_roleData;
		//For each role data replace each role loadouts data name with actual data
		{
			//Get the role name
			_roleName = _x select 0;
			//Get the role index
			_roleIndex = _forEachIndex;
			//Get the roles loadouts
			_loadouts = _x select 1;
			//For each loadout
			{
				//Get the loadouts index
				_loadoutIndex = _forEachIndex;
				//Get loadouts name
				_loadoutName = _x select 0;
				//Get the name of the BIs savedInventory
				_loadoutDataName = _x select 1;
				//If this loadout has a saved inventory
				if !( _loadoutDataName == "" ) then {
					//Is this a monitored role loadout
					if ( [ "MONITORED", [ _roleName, _loadoutName ] ] call LARs_fnc_roleData ) then {
						//Get the index in BIs data
						_index = BIS_fnc_saveInventory_data find _loadoutDataName;
						//Get BIs data for this loadout
						_inventoryData = BIS_fnc_saveInventory_data select ( _index + 1 );
						//Update the roleData copy with the actual inventory data instead of the name
						_roleData select _roleIndex select 1 select _loadoutIndex set[ 1, _inventoryData ];
					};
				};
			}forEach _loadouts;
		}forEach _roleData;
		
		//Get saved profile info
		_savedRoleData = profileNamespace getVariable [ "LARs_roleInfo", [] ];
		//Does info for this mission exist
		_missionIndex = {
			if ( _x select 0 == LARs_roleData_MN ) exitWith {
				_forEachIndex
			};
		}forEach _savedRoleData;
		
		//If we already have info for this mission
		if !( isNil "_missionIndex" ) then {
			//Over write with new info
			_savedRoleData select _missionIndex set[ 1, _roleData ];
		}else{
			//Otherwise save new array of [ missionName, roleData ]
			_nul = _savedRoleData pushBack [ LARs_roleData_MN, _roleData ];
		};
		
		//Update the saved data
		profileNamespace setVariable [ "LARs_roleInfo", _savedRoleData ];
		
		//Save to users profile
		saveProfileNamespace;
		
	};
	
	//Import saved role data from user profileNamespace for a mission
	case "IMPORT" : {
		
		//If the mission has not been flagged to save player roleData then exit
		if ( getMissionConfigValue [ "LARs_roleData_save", 0 ] isEqualTo 0 ) exitWith {};
		
		if !( canSuspend ) exitWith {
			[ "IMPORT" ] spawn LARs_fnc_roleData;
		};
		
		//Wait for the server to transmit mission name
		waitUntil{ !isNil "LARs_roleData_MN" };
		
		//Get saved role info
		_savedRoleData = profileNamespace getVariable "LARs_roleInfo";
		
		//If we have saved role data
		if !( isNil "_savedRoleData" ) then {
			
			//Find role info for this mission
			_missionIndex = {
				if ( _x select 0 == LARs_roleData_MN ) exitWith {
					_forEachIndex
				};
			}forEach _savedRoleData;
			
			//If we have data for this mission
			if !( isNil "_missionIndex" ) then {
				
				_roleData = +( _savedRoleData select _missionIndex select 1 );
				
				{
					_roleIndex = _forEachIndex;
					_roleName = _x select 0;
					_loadouts = _x select 1;
					{
						_loadoutIndex = _forEachIndex;
						_loadoutName = _x select 0;
						_loadoutData = _x select 1;
						if !( _loadoutData isEqualType "" ) then {
							//Is this a monitored role loadout
							if ( [ "MONITORED", [ _roleName, _loadoutName ] ] call LARs_fnc_roleData ) then {
								_BIS_data = missionNamespace getVariable [ "BIS_fnc_saveInventory_data", [] ];
								_loadoutDataName = format[ "%1_%2", _roleName, _loadoutName ];
								_nul = _BIS_data pushBack _loadoutDataName;
								_nul = _BIS_data pushBack _loadoutData;
								missionNamespace setVariable[ "BIS_fnc_saveInventory_data", _BIS_data ];
								LARs_roleData select _roleIndex select 1 select _loadoutIndex set[ 1, _loadoutDataName ];
							};
						};
					}forEach _loadouts;
				}forEach _roleData;
			};			
		};		
		
	};
	
	//Check if a role is monitored
	case "MONITORED" : {
		params[ "_roleName", "_loadoutName" ];
		
		//Get monitored roles
		_monitoredRoles = getMissionConfigValue "LARs_roleData_monitor";
		_addedRoles = missionNamespace getVariable "LARs_roleData_monitor";
		
		_isMonitored = if ( isNil "_monitoredRoles" && isNil "_addedRoles" ) then {
			false
		}else{
			_monitoredRoles = ( getMissionConfigValue [ "LARs_roleData_monitor", [] ] ) + ( missionNamespace getVariable [ "LARs_roleData_monitor", [] ] );
			
			//If its a blank array then all roles are monitored
			if ( _monitoredRoles isEqualTo [] ) then {
				true
			}else{
				
				//Turn all roles to lower case
				{
					_index = _forEachIndex;
					{
						_monitoredRoles select _index set[ _forEachIndex, toLower _x ];
					}forEach _x;
				}forEach _monitoredRoles;
				
				//Check if the role loadout is monitored
				if ( [ toLower _roleName, toLower _loadoutName ] in _monitoredRoles ) then {
					true
				}else{
					false
				};
				
			};
		};
		
		_isMonitored
	};
	
};