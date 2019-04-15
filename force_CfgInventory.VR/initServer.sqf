
//********
//Nothing in here other than some normal calls to apply respawnLoadouts and positions
//********
//Initialize assault loadouts
[west,["Rifleman",5]] call BIS_fnc_addRespawnInventory;
[east,["Rifleman",5]] call BIS_fnc_addRespawnInventory;

//Initialize support loadouts
[west,["MG",8]] call BIS_fnc_addRespawnInventory;
[east,["MG",8]] call BIS_fnc_addRespawnInventory;

//Initialize recon loadouts
[west,["Sniper",2]] call BIS_fnc_addRespawnInventory;
[east,["Sniper",2]] call BIS_fnc_addRespawnInventory;

[west,["ABCD",2]] call BIS_fnc_addRespawnInventory;
[east,["ABCD",2]] call BIS_fnc_addRespawnInventory;

[ missionNamespace, [ worldSize / 2, worldSize / 2, 0 ] ] call BIS_fnc_addRespawnPosition;