/*
	Release:
	    	» Race System Filterscript

	Author:
	        » » RyDeR «
	        
	Last Update:
	        » 26/04/2010
	        
	ChangeLog:
	        » v0.1a:
				- Initial release
				
			» v0.2a:
			    - Major Bugs fixed!
			    - Racing in other worlds added (enable/disbable with uncomment/comment-ing the define)
			    - New Commands added:
			                        - /startautorace: You can enable that the script starts automaticly a race after the previous one is done.
			                        - /stopautorace: You can disable the command above.
			                        - /exitrace: To exit the race safely
       			- Best Race Times added (Top 5 best time laps; You will see a message when the record is broken).
       			- Crash while creating a race is fixed.
       			- Etc..
				
	Bugs:
	        » No bugs
	        
	Version:
			» v0.2a

	Functions:
			» IsPlayerInRace(playerid);    >> UseFull in stunt servers to disable speedhack, nitro etc. while racing.

	Credits:
			» Joker: He knows why ;)
			» Joe Torran C, ModrLicC: For testing.
			» DracoBlue: 'Dini' include.
	        » Y_Less: 'IsOdd' function.
	        » Seif_: 'function' function.
	        » ZeeX: 'zcmd' include.
			» Switch: InRace Position function.
*/

#include <a_samp>
#include <dini>
#include <zcmd>

#pragma unused \
	ret_memcpy

#define ForEach(%0,%1) \
	for(new %0 = 0; %0 != %1; %0++) if(IsPlayerConnected(%0) && !IsPlayerNPC(%0))

#define Loop(%0,%1) \
	for(new %0 = 0; %0 != %1; %0++)
	
#define IsOdd(%1) \
	((%1) & 1)
	
#define ConvertTime(%0,%1,%2,%3,%4) \
	new \
	    Float: %0 = floatdiv(%1, 60000) \
	;\
	%2 = floatround(%0, floatround_tozero); \
	%3 = floatround(floatmul(%0 - %2, 60), floatround_tozero); \
	%4 = floatround(floatmul(floatmul(%0 - %2, 60) - %3, 1000), floatround_tozero)
	
#define function%0(%1) \
	forward%0(%1); public%0(%1)
	
#define MAX_RACE_CHECKPOINTS_EACH_RACE \
 	120
	
#define MAX_RACES \
 	100

#define COUNT_DOWN_TILL_RACE_START \
	30 // seconds
	
#define MAX_RACE_TIME \
	300 // seconds
	
#define RACE_CHECKPOINT_SIZE \
	12.0

#define DEBUG_RACE \
	1
	
//#define RACE_IN_OTHER_WORLD // Uncomment to enable
	
#define GREY \
	0xAFAFAFAA
	
#define GREEN \
	0x9FFF00FF
	
#define RED \
	0xE60000FF
	
#define YELLOW \
	0xFFFF00AA
	
#define WHITE \
	0xFFFFFFAA
	
new
	vNames[212][] =
	{
		{"Landstalker"},
		{"Bravura"},
		{"Buffalo"},
		{"Linerunner"},
		{"Perrenial"},
		{"Sentinel"},
		{"Dumper"},
		{"Firetruck"},
		{"Trashmaster"},
		{"Stretch"},
		{"Manana"},
		{"Infernus"},
		{"Voodoo"},
		{"Pony"},
		{"Mule"},
		{"Cheetah"},
		{"Ambulance"},
		{"Leviathan"},
		{"Moonbeam"},
		{"Esperanto"},
		{"Taxi"},
		{"Washington"},
		{"Bobcat"},
		{"Mr Whoopee"},
		{"BF Injection"},
		{"Hunter"},
		{"Premier"},
		{"Enforcer"},
		{"Securicar"},
		{"Banshee"},
		{"Predator"},
		{"Bus"},
		{"Rhino"},
		{"Barracks"},
		{"Hotknife"},
		{"Trailer 1"},
		{"Previon"},
		{"Coach"},
		{"Cabbie"},
		{"Stallion"},
		{"Rumpo"},
		{"RC Bandit"},
		{"Romero"},
		{"Packer"},
		{"Monster"},
		{"Admiral"},
		{"Squalo"},
		{"Seasparrow"},
		{"Pizzaboy"},
		{"Tram"},
		{"Trailer 2"},
		{"Turismo"},
		{"Speeder"},
		{"Reefer"},
		{"Tropic"},
		{"Flatbed"},
		{"Yankee"},
		{"Caddy"},
		{"Solair"},
		{"Berkley's RC Van"},
		{"Skimmer"},
		{"PCJ-600"},
		{"Faggio"},
		{"Freeway"},
		{"RC Baron"},
		{"RC Raider"},
		{"Glendale"},
		{"Oceanic"},
		{"Sanchez"},
		{"Sparrow"},
		{"Patriot"},
		{"Quad"},
		{"Coastguard"},
		{"Dinghy"},
		{"Hermes"},
		{"Sabre"},
		{"Rustler"},
		{"ZR-350"},
		{"Walton"},
		{"Regina"},
		{"Comet"},
		{"BMX"},
		{"Burrito"},
		{"Camper"},
		{"Marquis"},
		{"Baggage"},
		{"Dozer"},
		{"Maverick"},
		{"News Chopper"},
		{"Rancher"},
		{"FBI Rancher"},
		{"Virgo"},
		{"Greenwood"},
		{"Jetmax"},
		{"Hotring"},
		{"Sandking"},
		{"Blista Compact"},
		{"Police Maverick"},
		{"Boxville"},
		{"Benson"},
		{"Mesa"},
		{"RC Goblin"},
		{"Hotring Racer A"},
		{"Hotring Racer B"}, 
		{"Bloodring Banger"},
		{"Rancher"},
		{"Super GT"},
		{"Elegant"},
		{"Journey"},
		{"Bike"},
		{"Mountain Bike"},
		{"Beagle"},
		{"Cropdust"},
		{"Stunt"},
		{"Tanker"},
		{"Roadtrain"},
		{"Nebula"},
		{"Majestic"},
		{"Buccaneer"},
		{"Shamal"},
		{"Hydra"},
		{"FCR-900"},
		{"NRG-500"},
		{"HPV1000"},
		{"Cement Truck"},
		{"Tow Truck"},
		{"Fortune"},
		{"Cadrona"},
		{"FBI Truck"},
		{"Willard"},
		{"Forklift"},
		{"Tractor"},
		{"Combine"},
		{"Feltzer"},
		{"Remington"},
		{"Slamvan"},
		{"Blade"},
		{"Freight"},
		{"Streak"},
		{"Vortex"},
		{"Vincent"},
		{"Bullet"},
		{"Clover"},
		{"Sadler"},
		{"Firetruck LA"},
		{"Hustler"},
		{"Intruder"},
		{"Primo"},
		{"Cargobob"},
		{"Tampa"},
		{"Sunrise"},
		{"Merit"},
		{"Utility"},
		{"Nevada"},
		{"Yosemite"},
		{"Windsor"},
		{"Monster A"},
		{"Monster B"},
		{"Uranus"},
		{"Jester"},
		{"Sultan"},
		{"Stratum"},
		{"Elegy"},
		{"Raindance"},
		{"RC Tiger"},
		{"Flash"},
		{"Tahoma"},
		{"Savanna"},
		{"Bandito"},
		{"Freight Flat"}, 
		{"Streak Carriage"}, 
		{"Kart"},
		{"Mower"},
		{"Duneride"},
		{"Sweeper"},
		{"Broadway"},
		{"Tornado"},
		{"AT-400"},
		{"DFT-30"},
		{"Huntley"},
		{"Stafford"},
		{"BF-400"},
		{"Newsvan"},
		{"Tug"},
		{"Trailer 3"},
		{"Emperor"},
		{"Wayfarer"},
		{"Euros"},
		{"Hotdog"},
		{"Club"},
		{"Freight Carriage"}, 
		{"Trailer 3"},
		{"Andromada"},
		{"Dodo"},
		{"RC Cam"},
		{"Launch"},
		{"Police Car (LSPD)"},
		{"Police Car (SFPD)"},
		{"Police Car (LVPD)"},
		{"Police Ranger"},
		{"Picador"},
		{"S.W.A.T. Van"},
		{"Alpha"},
		{"Phoenix"},
		{"Glendale"},
		{"Sadler"},
		{"Luggage Trailer A"}, 
		{"Luggage Trailer B"},
		{"Stair Trailer"}, 
		{"Boxville"},
		{"Farm Plow"},
		{"Utility Trailer"}
	},
	BuildRace,
	BuildRaceType,
	BuildVehicle,
	BuildCreatedVehicle,
	BuildModeVID,
	BuildName[30],
	bool: BuildTakeVehPos,
	BuildVehPosCount,
	bool: BuildTakeCheckpoints,
	BuildCheckPointCount,
	RaceBusy = 0x00,
	RaceName[30],
	RaceVehicle,
	RaceType,
	TotalCP,
	Float: RaceVehCoords[2][4],
	Float: CPCoords[MAX_RACE_CHECKPOINTS_EACH_RACE][4],
	CreatedRaceVeh[MAX_PLAYERS],
	Index,
	PlayersCount[2],
	CountTimer,
	CountAmount,
	bool: Joined[MAX_PLAYERS],
	RaceTick,
	RaceStarted,
	CPProgess[MAX_PLAYERS],
	Position,
	FinishCount,
	JoinCount,
	rCounter,
	RaceTime,
	Text: RaceInfo[MAX_PLAYERS],
	InfoTimer[MAX_PLAYERS],
	RacePosition[MAX_PLAYERS],
	RaceNames[MAX_RACES][128],
 	TotalRaces,
 	bool: AutomaticRace,
 	TimeProgress
 	
;

public OnFilterScriptExit()
{
	BuildCreatedVehicle = (BuildCreatedVehicle == 0x01) ? (DestroyVehicle(BuildVehicle), BuildCreatedVehicle = 0x00) : (DestroyVehicle(BuildVehicle), BuildCreatedVehicle = 0x00);
	KillTimer(rCounter);
	KillTimer(CountTimer);
	Loop(i, MAX_PLAYERS)
	{
		DisablePlayerRaceCheckpoint(i);
		TextDrawDestroy(RaceInfo[i]);
		DestroyVehicle(CreatedRaceVeh[i]);
		Joined[i] = false;
		KillTimer(InfoTimer[i]);
	}
	JoinCount = 0;
	FinishCount = 0;
	TimeProgress = 0;
	AutomaticRace = false;
	return 1;
}

CMD:buildrace(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, RED, "<!> You are not an administrator!");
	if(BuildRace != 0) return SendClientMessage(playerid, RED, "<!> There's already someone building a race!");
	if(RaceBusy == 0x01) return SendClientMessage(playerid, RED, "<!> Wait first till race ends!");
	if(IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, "<!> Please leave your vehicle first!");
	BuildRace = playerid+1;
	ShowDialog(playerid, 599);
	return 1;
}
CMD:startrace(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, RED, "<!> You are not an administrator!");
    if(AutomaticRace == true) return SendClientMessage(playerid, RED, "<!> Not possible. Automatic race is enabled!");
    if(BuildRace != 0) return SendClientMessage(playerid, RED, "<!> There's someone building a race!");
    if(RaceBusy == 0x01 || RaceStarted == 1) return SendClientMessage(playerid, RED, "<!> There's a race currently. Wait first till race ends!");
    if(isnull(params)) return SendClientMessage(playerid, RED, "<!> /startrace [racename]");
    LoadRace(playerid, params);
    return 1;
}
CMD:stoprace(playerid, params[])
{
   	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, RED, "<!> You are not an administrator!");
    if(RaceBusy == 0x00 || RaceStarted == 0) return SendClientMessage(playerid, RED, "<!> There's no race to stop!");
	SendClientMessageToAll(RED, ">> An admin stopped the current race!");
	return StopRace();
}
CMD:joinrace(playerid, params[])
{
	if(RaceStarted == 1) return SendClientMessage(playerid, RED, "<!> Race already started! Wait first till race ends!");
	if(RaceBusy == 0x00) return SendClientMessage(playerid, RED, "<!> There's no race to join!");
	if(Joined[playerid] == true) return SendClientMessage(playerid, RED, "<!> You already joined a race!");
	if(IsPlayerInAnyVehicle(playerid)) return SetTimerEx("SetupRaceForPlayer", 2500, 0, "e", playerid), RemovePlayerFromVehicle(playerid), Joined[playerid] = true;
	SetupRaceForPlayer(playerid);
	Joined[playerid] = true;
	return 1;
}
CMD:startautorace(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, RED, "<!> You are not an administrator!");
	if(RaceBusy == 0x01 || RaceStarted == 1) return SendClientMessage(playerid, RED, "<!> There's a race currently. Wait first till race ends!");
	if(AutomaticRace == true) return SendClientMessage(playerid, RED, "<!> It's already enabled!");
    LoadRaceNames();
	LoadAutoRace(RaceNames[random(TotalRaces)]);
	AutomaticRace = true;
	SendClientMessage(playerid, GREEN, ">> You stared auto race. The filterscript will start a random race everytime the previous race is over!");
	return 1;
}
CMD:stopautorace(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, RED, "<!> You are not an administrator!");
    if(AutomaticRace == false) return SendClientMessage(playerid, RED, "<!> It's already disabled!");
    AutomaticRace = false;
    return 1;
}
CMD:exitrace(playerid, params[])
{
    if(Joined[playerid] == true)
    {
		JoinCount--;
		Joined[playerid] = false;
		DestroyVehicle(CreatedRaceVeh[playerid]);
	    DisablePlayerRaceCheckpoint(playerid);
		TextDrawHideForPlayer(playerid, RaceInfo[playerid]);
		CPProgess[playerid] = 0;
		KillTimer(InfoTimer[playerid]);
		TogglePlayerControllable(playerid, true);
		SetCameraBehindPlayer(playerid);
		#if defined RACE_IN_OTHER_WORLD
		SetPlayerVirtualWorld(playerid, 0);
		#endif
	} else return SendClientMessage(playerid, RED, "<!> You are not in a race!");
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	if(CPProgess[playerid] == TotalCP -1)
	{
		new
		    TimeStamp,
		    TotalRaceTime,
		    string[256],
		    rFile[256],
		    pName[MAX_PLAYER_NAME],
			rTime[3],
			Prize[2],
			TempTotalTime,
			TempTime[3]
		;
		Position++;
		GetPlayerName(playerid, pName, sizeof(pName));
		TimeStamp = GetTickCount();
		TotalRaceTime = TimeStamp - RaceTick;
		ConvertTime(var, TotalRaceTime, rTime[0], rTime[1], rTime[2]);
		switch(Position)
		{
		    case 1: Prize[0] = (random(random(5000)) + 10000), Prize[1] = 10;
		    case 2: Prize[0] = (random(random(4500)) + 9000), Prize[1] = 9;
		    case 3: Prize[0] = (random(random(4000)) + 8000), Prize[1] = 8;
		    case 4: Prize[0] = (random(random(3500)) + 7000), Prize[1] = 7;
		    case 5: Prize[0] = (random(random(3000)) + 6000), Prize[1] = 6;
		    case 6: Prize[0] = (random(random(2500)) + 5000), Prize[1] = 5;
		    case 7: Prize[0] = (random(random(2000)) + 4000), Prize[1] = 4;
		    case 8: Prize[0] = (random(random(1500)) + 3000), Prize[1] = 3;
		    case 9: Prize[0] = (random(random(1000)) + 2000), Prize[1] = 2;
		    default: Prize[0] = random(random(1000)), Prize[1] = 1;
		}
		format(string, sizeof(string), ">> \"%s\" has finished the race in position \"%d\".", pName, Position);
		SendClientMessageToAll(WHITE, string);
		format(string, sizeof(string), "    - Time: \"%d:%d.%d\".", rTime[0], rTime[1], rTime[2]);
		SendClientMessageToAll(WHITE, string);
		format(string, sizeof(string), "    - Prize: \"$%d and +%d Score\".", Prize[0], Prize[1]);
		SendClientMessageToAll(WHITE, string);
		
		if(FinishCount <= 5)
		{
			format(rFile, sizeof(rFile), "/rRaceSystem/%s.RRACE", RaceName);
		    format(string, sizeof(string), "BestRacerTime_%d", TimeProgress);
		    TempTotalTime = dini_Int(rFile, string);
		    ConvertTime(var1, TempTotalTime, TempTime[0], TempTime[1], TempTime[2]);
		    if(TotalRaceTime <= dini_Int(rFile, string) || TempTotalTime == 0)
		    {
		        dini_IntSet(rFile, string, TotalRaceTime);
				format(string, sizeof(string), "BestRacer_%d", TimeProgress);
		        if(TempTotalTime != 0) format(string, sizeof(string), ">> \"%s\" has broken the record of \"%s\" with \"%d\" seconds faster on the \"%d\"'st/th place!", pName, dini_Get(rFile, string), -(rTime[1] - TempTime[1]), TimeProgress+1);
					else format(string, sizeof(string), ">> \"%s\" has broken a new record of on the \"%d\"'st/th place!", pName, TimeProgress+1);
                SendClientMessageToAll(GREEN, "  ");
				SendClientMessageToAll(GREEN, string);
				SendClientMessageToAll(GREEN, "  ");
				format(string, sizeof(string), "BestRacer_%d", TimeProgress);
				dini_Set(rFile, string, pName);
				TimeProgress++;
		    }
		}
		FinishCount++;
		GivePlayerMoney(playerid, Prize[0]);
		SetPlayerScore(playerid, GetPlayerScore(playerid) + Prize[1]);
		DisablePlayerRaceCheckpoint(playerid);
		CPProgess[playerid]++;
		if(FinishCount >= JoinCount) return StopRace();
    }
	else
	{
		CPProgess[playerid]++;
		CPCoords[CPProgess[playerid]][3]++;
		RacePosition[playerid] = floatround(CPCoords[CPProgess[playerid]][3], floatround_floor);
	    SetCP(playerid, CPProgess[playerid], CPProgess[playerid]+1, TotalCP, RaceType);
	    PlayerPlaySound(playerid, 1137, 0.0, 0.0, 0.0);
	}
    return 1;
}

public OnPlayerDisconnect(playerid)
{
	if(Joined[playerid] == true)
    {
		JoinCount--;
		Joined[playerid] = false;
		DestroyVehicle(CreatedRaceVeh[playerid]);
		DisablePlayerRaceCheckpoint(playerid);
		TextDrawHideForPlayer(playerid, RaceInfo[playerid]);
		CPProgess[playerid] = 0;
		KillTimer(InfoTimer[playerid]);
		#if defined RACE_IN_OTHER_WORLD
		SetPlayerVirtualWorld(playerid, 0);
		#endif
	}
	TextDrawDestroy(RaceInfo[playerid]);
	if(BuildRace == playerid+1) BuildRace = 0;
	return 1;
}

public OnPlayerConnect(playerid)
{
	RaceInfo[playerid] = TextDrawCreate(633.000000, 348.000000, " ");
	TextDrawAlignment(RaceInfo[playerid], 3);
	TextDrawBackgroundColor(RaceInfo[playerid], 255);
	TextDrawFont(RaceInfo[playerid], 1);
	TextDrawLetterSize(RaceInfo[playerid], 0.240000, 1.100000);
	TextDrawColor(RaceInfo[playerid], -687931137);
	TextDrawSetOutline(RaceInfo[playerid], 0);
	TextDrawSetProportional(RaceInfo[playerid], 1);
	TextDrawSetShadow(RaceInfo[playerid], 1);
	return 1;
}

public OnPlayerDeath(playerid)
{
    if(Joined[playerid] == true)
    {
		JoinCount--;
		Joined[playerid] = false;
		DestroyVehicle(CreatedRaceVeh[playerid]);
		DisablePlayerRaceCheckpoint(playerid);
		TextDrawHideForPlayer(playerid, RaceInfo[playerid]);
		CPProgess[playerid] = 0;
		KillTimer(InfoTimer[playerid]);
		#if defined RACE_IN_OTHER_WORLD
		SetPlayerVirtualWorld(playerid, 0);
		#endif
	}
	if(BuildRace == playerid+1) BuildRace = 0;
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case 599:
	    {
	        if(!response) return BuildRace = 0;
	        switch(listitem)
	        {
	        	case 0: BuildRaceType = 0;
	        	case 1: BuildRaceType = 3;
			}
			ShowDialog(playerid, 600);
	    }
	    case 600..601:
	    {
	        if(!response) return ShowDialog(playerid, 599);
	        if(!strlen(inputtext)) return ShowDialog(playerid, 601);
	        if(strlen(inputtext) < 1 || strlen(inputtext) > 20) return ShowDialog(playerid, 601);
	        strmid(BuildName, inputtext, 0, strlen(inputtext), sizeof(BuildName));
	        ShowDialog(playerid, 602);
	    }
	    case 602..603:
	    {
	        if(!response) return ShowDialog(playerid, 600);
	        if(!strlen(inputtext)) return ShowDialog(playerid, 603);
	        if(isNumeric(inputtext))
	        {

	            if(!IsValidVehicle(strval(inputtext))) return ShowDialog(playerid, 603);
				new
	                Float: pPos[4]
				;
				GetPlayerPos(playerid, pPos[0], pPos[1], pPos[2]);
				GetPlayerFacingAngle(playerid, pPos[3]);
				BuildModeVID = strval(inputtext);
				BuildCreatedVehicle = (BuildCreatedVehicle == 0x01) ? (DestroyVehicle(BuildVehicle), BuildCreatedVehicle = 0x00) : (DestroyVehicle(BuildVehicle), BuildCreatedVehicle = 0x00);
	            BuildVehicle = CreateVehicle(strval(inputtext), pPos[0], pPos[1], pPos[2], pPos[3], random(126), random(126), (60 * 60));
	            PutPlayerInVehicle(playerid, BuildVehicle, 0);
				BuildCreatedVehicle = 0x01;
				ShowDialog(playerid, 604);
			}
	        else
	        {
	            if(!IsValidVehicle(ReturnVehicleID(inputtext))) return ShowDialog(playerid, 603);
				new
	                Float: pPos[4]
				;
				GetPlayerPos(playerid, pPos[0], pPos[1], pPos[2]);
				GetPlayerFacingAngle(playerid, pPos[3]);
				BuildModeVID = ReturnVehicleID(inputtext);
				BuildCreatedVehicle = (BuildCreatedVehicle == 0x01) ? (DestroyVehicle(BuildVehicle), BuildCreatedVehicle = 0x00) : (DestroyVehicle(BuildVehicle), BuildCreatedVehicle = 0x00);
	            BuildVehicle = CreateVehicle(ReturnVehicleID(inputtext), pPos[0], pPos[1], pPos[2], pPos[3], random(126), random(126), (60 * 60));
	            PutPlayerInVehicle(playerid, BuildVehicle, 0);
				BuildCreatedVehicle = 0x01;
				ShowDialog(playerid, 604);
	        }
	    }
	    case 604:
	    {
	        if(!response) return ShowDialog(playerid, 602);
			SendClientMessage(playerid, GREEN, ">> Go to the start line on the left road and press 'KEY_FIRE' and do the same with the right road block.");
			SendClientMessage(playerid, GREEN, "   - When this is done, you will see a dialog to continue.");
			BuildVehPosCount = 0;
	        BuildTakeVehPos = true;
	    }
	    case 605:
	    {
	        if(!response) return ShowDialog(playerid, 604);
	        SendClientMessage(playerid, GREEN, ">> Start taking checkpoints now by clicking 'KEY_FIRE'.");
	        SendClientMessage(playerid, GREEN, "   - IMPORTANT: Press 'ENTER' when you're done with the checkpoints! If it doesn't react press again and again.");
	        BuildCheckPointCount = 0;
	        BuildTakeCheckpoints = true;
	    }
	    case 606:
	    {
	        if(!response) return ShowDialog(playerid, 606);
	        BuildRace = 0;
	        BuildCheckPointCount = 0;
	        BuildVehPosCount = 0;
	        BuildTakeCheckpoints = false;
	        BuildTakeVehPos = false;
	        BuildCreatedVehicle = (BuildCreatedVehicle == 0x01) ? (DestroyVehicle(BuildVehicle), BuildCreatedVehicle = 0x00) : (DestroyVehicle(BuildVehicle), BuildCreatedVehicle = 0x00);
	    }
	}
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	new
 		string[256],
 		rNameFile[256],
   		rFile[256],
     	Float: vPos[4]
	;
	if(newkeys & KEY_FIRE)
	{
	    if(BuildRace == playerid+1)
	    {
		    if(BuildTakeVehPos == true)
		    {
		    	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, ">> You need to be in a vehicle");
				format(rFile, sizeof(rFile), "/rRaceSystem/%s.RRACE", BuildName);
				GetVehiclePos(GetPlayerVehicleID(playerid), vPos[0], vPos[1], vPos[2]);
				GetVehicleZAngle(GetPlayerVehicleID(playerid), vPos[3]);
		        dini_Create(rFile);
				dini_IntSet(rFile, "vModel", BuildModeVID);
				dini_IntSet(rFile, "rType", BuildRaceType);
		        format(string, sizeof(string), "vPosX_%d", BuildVehPosCount), dini_FloatSet(rFile, string, vPos[0]);
		        format(string, sizeof(string), "vPosY_%d", BuildVehPosCount), dini_FloatSet(rFile, string, vPos[1]);
		        format(string, sizeof(string), "vPosZ_%d", BuildVehPosCount), dini_FloatSet(rFile, string, vPos[2]);
		        format(string, sizeof(string), "vAngle_%d", BuildVehPosCount), dini_FloatSet(rFile, string, vPos[3]);
		        format(string, sizeof(string), ">> Vehicle Pos '%d' has been taken.", BuildVehPosCount+1);
		        SendClientMessage(playerid, YELLOW, string);
				BuildVehPosCount++;
			}
   			if(BuildVehPosCount >= 2)
		    {
		        BuildVehPosCount = 0;
		        BuildTakeVehPos = false;
		        ShowDialog(playerid, 605);
		    }
			if(BuildTakeCheckpoints == true)
			{
			    if(BuildCheckPointCount > MAX_RACE_CHECKPOINTS_EACH_RACE) return SendClientMessage(playerid, RED, ">> You reached the maximum amount of checkpoints!");
			    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, ">> You need to be in a vehicle");
				format(rFile, sizeof(rFile), "/rRaceSystem/%s.RRACE", BuildName);
				GetVehiclePos(GetPlayerVehicleID(playerid), vPos[0], vPos[1], vPos[2]);
				format(string, sizeof(string), "CP_%d_PosX", BuildCheckPointCount), dini_FloatSet(rFile, string, vPos[0]);
				format(string, sizeof(string), "CP_%d_PosY", BuildCheckPointCount), dini_FloatSet(rFile, string, vPos[1]);
				format(string, sizeof(string), "CP_%d_PosZ", BuildCheckPointCount), dini_FloatSet(rFile, string, vPos[2]);
    			format(string, sizeof(string), ">> Checkpoint '%d' has been setted!", BuildCheckPointCount+1);
		        SendClientMessage(playerid, YELLOW, string);
				BuildCheckPointCount++;
			}
		}
	}
	if(newkeys & KEY_SECONDARY_ATTACK)
	{
	    if(BuildTakeCheckpoints == true)
	    {
	        ShowDialog(playerid, 606);
			format(rNameFile, sizeof(rNameFile), "/rRaceSystem/RaceNames/RaceNames.txt");
			TotalRaces = dini_Int(rNameFile, "TotalRaces");
			TotalRaces++;
			dini_IntSet(rNameFile, "TotalRaces", TotalRaces);
			format(string, sizeof(string), "Race_%d", TotalRaces-1);
			format(rFile, sizeof(rFile), "/rRaceSystem/%s.RRACE", BuildName);
			dini_Set(rNameFile, string, BuildName);
			dini_IntSet(rFile, "TotalCP", BuildCheckPointCount);
			Loop(x, 5)
			{
				format(string, sizeof(string), "BestRacerTime_%d", x);
				dini_Set(rFile, string, "0");
				format(string, sizeof(string), "BestRacer_%d", x);
				dini_Set(rFile, string, "noone");
			}
	    }
	}
	return 1;
}

function LoadRaceNames()
{
	new
	    rNameFile[64],
	    string[64]
	;
	format(rNameFile, sizeof(rNameFile), "/rRaceSystem/RaceNames/RaceNames.txt");
	TotalRaces = dini_Int(rNameFile, "TotalRaces");
	Loop(x, TotalRaces)
	{
	    format(string, sizeof(string), "Race_%d", x), strmid(RaceNames[x], dini_Get(rNameFile, string), 0, 20, sizeof(RaceNames));
	    printf(">> Loaded Races: %s", RaceNames[x]);
	}
	return 1;
}

function LoadAutoRace(rName[])
{
	new
		rFile[256],
		string[256]
	;
	format(rFile, sizeof(rFile), "/rRaceSystem/%s.RRACE", rName);
	if(!dini_Exists(rFile)) return printf("Race \"%s\" doesn't exist!", rName);
	strmid(RaceName, rName, 0, strlen(rName), sizeof(RaceName));
	RaceVehicle = dini_Int(rFile, "vModel");
	RaceType = dini_Int(rFile, "rType");
	TotalCP = dini_Int(rFile, "TotalCP");

	#if DEBUG_RACE == 1
	printf("VehicleModel: %d", RaceVehicle);
	printf("RaceType: %d", RaceType);
	printf("TotalCheckpoints: %d", TotalCP);
	#endif

	Loop(x, 2)
	{
		format(string, sizeof(string), "vPosX_%d", x), RaceVehCoords[x][0] = dini_Float(rFile, string);
		format(string, sizeof(string), "vPosY_%d", x), RaceVehCoords[x][1] = dini_Float(rFile, string);
		format(string, sizeof(string), "vPosZ_%d", x), RaceVehCoords[x][2] = dini_Float(rFile, string);
		format(string, sizeof(string), "vAngle_%d", x), RaceVehCoords[x][3] = dini_Float(rFile, string);
		#if DEBUG_RACE == 1
		printf("VehiclePos %d: %f, %f, %f, %f", x, RaceVehCoords[x][0], RaceVehCoords[x][1], RaceVehCoords[x][2], RaceVehCoords[x][3]);
		#endif
	}
	Loop(x, TotalCP)
	{
 		format(string, sizeof(string), "CP_%d_PosX", x), CPCoords[x][0] = dini_Float(rFile, string);
 		format(string, sizeof(string), "CP_%d_PosY", x), CPCoords[x][1] = dini_Float(rFile, string);
 		format(string, sizeof(string), "CP_%d_PosZ", x), CPCoords[x][2] = dini_Float(rFile, string);
 		#if DEBUG_RACE == 1
 		printf("RaceCheckPoint %d: %f, %f, %f", x, CPCoords[x][0], CPCoords[x][1], CPCoords[x][2]);
 		#endif
	}
	Position = 0;
	FinishCount = 0;
	JoinCount = 0;
	Loop(x, 2) PlayersCount[x] = 0;
	CountAmount = COUNT_DOWN_TILL_RACE_START;
	RaceTime = MAX_RACE_TIME;
	RaceBusy = 0x01;
	CountTimer = SetTimer("CountTillRace", 999, 1);
	TimeProgress = 0;
	return 1;
}

function LoadRace(playerid, rName[])
{
	new
		rFile[256],
		string[256]
	;
	format(rFile, sizeof(rFile), "/rRaceSystem/%s.RRACE", rName);
	if(!dini_Exists(rFile)) return SendClientMessage(playerid, RED, "<!> Race doesn't exist!"), printf("Race \"%s\" doesn't exist!", rName);
	strmid(RaceName, rName, 0, strlen(rName), sizeof(RaceName));
	RaceVehicle = dini_Int(rFile, "vModel");
	RaceType = dini_Int(rFile, "rType"); 
	TotalCP = dini_Int(rFile, "TotalCP");
	
	#if DEBUG_RACE == 1
	printf("VehicleModel: %d", RaceVehicle);
	printf("RaceType: %d", RaceType);
	printf("TotalCheckpoints: %d", TotalCP);
	#endif
	
	Loop(x, 2)
	{
		format(string, sizeof(string), "vPosX_%d", x), RaceVehCoords[x][0] = dini_Float(rFile, string);
		format(string, sizeof(string), "vPosY_%d", x), RaceVehCoords[x][1] = dini_Float(rFile, string);
		format(string, sizeof(string), "vPosZ_%d", x), RaceVehCoords[x][2] = dini_Float(rFile, string);
		format(string, sizeof(string), "vAngle_%d", x), RaceVehCoords[x][3] = dini_Float(rFile, string);
		#if DEBUG_RACE == 1
		printf("VehiclePos %d: %f, %f, %f, %f", x, RaceVehCoords[x][0], RaceVehCoords[x][1], RaceVehCoords[x][2], RaceVehCoords[x][3]);
		#endif
	}
	Loop(x, TotalCP)
	{
 		format(string, sizeof(string), "CP_%d_PosX", x), CPCoords[x][0] = dini_Float(rFile, string);
 		format(string, sizeof(string), "CP_%d_PosY", x), CPCoords[x][1] = dini_Float(rFile, string);
 		format(string, sizeof(string), "CP_%d_PosZ", x), CPCoords[x][2] = dini_Float(rFile, string);
 		#if DEBUG_RACE == 1
 		printf("RaceCheckPoint %d: %f, %f, %f", x, CPCoords[x][0], CPCoords[x][1], CPCoords[x][2]);
 		#endif
	}
	Position = 0;
	FinishCount = 0;
	JoinCount = 0;
	Loop(x, 2) PlayersCount[x] = 0;
	Joined[playerid] = true;
	CountAmount = COUNT_DOWN_TILL_RACE_START;
	RaceTime = MAX_RACE_TIME;
	RaceBusy = 0x01;
	TimeProgress = 0;
	SetupRaceForPlayer(playerid);
	CountTimer = SetTimer("CountTillRace", 999, 1);
	return 1;
}

function SetCP(playerid, PrevCP, NextCP, MaxCP, Type)
{
	if(Type == 0)
	{
		if(NextCP == MaxCP) SetPlayerRaceCheckpoint(playerid, 1, CPCoords[PrevCP][0], CPCoords[PrevCP][1], CPCoords[PrevCP][2], CPCoords[NextCP][0], CPCoords[NextCP][1], CPCoords[NextCP][2], RACE_CHECKPOINT_SIZE);
			else SetPlayerRaceCheckpoint(playerid, 0, CPCoords[PrevCP][0], CPCoords[PrevCP][1], CPCoords[PrevCP][2], CPCoords[NextCP][0], CPCoords[NextCP][1], CPCoords[NextCP][2], RACE_CHECKPOINT_SIZE);
	}
	else if(Type == 3)
	{
		if(NextCP == MaxCP) SetPlayerRaceCheckpoint(playerid, 4, CPCoords[PrevCP][0], CPCoords[PrevCP][1], CPCoords[PrevCP][2], CPCoords[NextCP][0], CPCoords[NextCP][1], CPCoords[NextCP][2], RACE_CHECKPOINT_SIZE);
			else SetPlayerRaceCheckpoint(playerid, 3, CPCoords[PrevCP][0], CPCoords[PrevCP][1], CPCoords[PrevCP][2], CPCoords[NextCP][0], CPCoords[NextCP][1], CPCoords[NextCP][2], RACE_CHECKPOINT_SIZE);
	}
	return 1;
}

function SetupRaceForPlayer(playerid)
{
	CPProgess[playerid] = 0;
	TogglePlayerControllable(playerid, false);
	CPCoords[playerid][3] = 0;
	SetCP(playerid, CPProgess[playerid], CPProgess[playerid]+1, TotalCP, RaceType);
	if(IsOdd(playerid)) Index = 1;
	    else Index = 0;

	switch(Index)
	{
		case 0:
		{
		    if(PlayersCount[0] == 1)
		    {
				RaceVehCoords[0][0] -= (6 * floatsin(-RaceVehCoords[0][3], degrees));
		 		RaceVehCoords[0][1] -= (6 * floatcos(-RaceVehCoords[0][3], degrees));
		   		CreatedRaceVeh[playerid] = CreateVehicle(RaceVehicle, RaceVehCoords[0][0], RaceVehCoords[0][1], RaceVehCoords[0][2]+2, RaceVehCoords[0][3], random(126), random(126), (60 * 60));
				SetPlayerPos(playerid, RaceVehCoords[0][0], RaceVehCoords[0][1], RaceVehCoords[0][2]+2);
				SetPlayerFacingAngle(playerid, RaceVehCoords[0][3]);
				PutPlayerInVehicle(playerid, CreatedRaceVeh[playerid], 0);
				Camera(playerid, RaceVehCoords[0][0], RaceVehCoords[0][1], RaceVehCoords[0][2], RaceVehCoords[0][3], 20);
			}
		}
		case 1:
 		{
 		    if(PlayersCount[1] == 1)
 		    {
				RaceVehCoords[1][0] -= (6 * floatsin(-RaceVehCoords[1][3], degrees));
		 		RaceVehCoords[1][1] -= (6 * floatcos(-RaceVehCoords[1][3], degrees));
		   		CreatedRaceVeh[playerid] = CreateVehicle(RaceVehicle, RaceVehCoords[1][0], RaceVehCoords[1][1], RaceVehCoords[1][2]+2, RaceVehCoords[1][3], random(126), random(126), (60 * 60));
				SetPlayerPos(playerid, RaceVehCoords[1][0], RaceVehCoords[1][1], RaceVehCoords[1][2]+2);
				SetPlayerFacingAngle(playerid, RaceVehCoords[1][3]);
				PutPlayerInVehicle(playerid, CreatedRaceVeh[playerid], 0);
				Camera(playerid, RaceVehCoords[1][0], RaceVehCoords[1][1], RaceVehCoords[1][2], RaceVehCoords[1][3], 20);
    		}
 		}
	}
	switch(Index)
	{
	    case 0:
		{
			if(PlayersCount[0] != 1)
			{
		   		CreatedRaceVeh[playerid] = CreateVehicle(RaceVehicle, RaceVehCoords[0][0], RaceVehCoords[0][1], RaceVehCoords[0][2]+2, RaceVehCoords[0][3], random(126), random(126), (60 * 60));
				SetPlayerPos(playerid, RaceVehCoords[0][0], RaceVehCoords[0][1], RaceVehCoords[0][2]+2);
				SetPlayerFacingAngle(playerid, RaceVehCoords[0][3]);
				PutPlayerInVehicle(playerid, CreatedRaceVeh[playerid], 0);
				Camera(playerid, RaceVehCoords[0][0], RaceVehCoords[0][1], RaceVehCoords[0][2], RaceVehCoords[0][3], 20);
			    PlayersCount[0] = 1;
		    }
	    }
	    case 1:
	    {
			if(PlayersCount[1] != 1)
			{
		   		CreatedRaceVeh[playerid] = CreateVehicle(RaceVehicle, RaceVehCoords[1][0], RaceVehCoords[1][1], RaceVehCoords[1][2]+2, RaceVehCoords[1][3], random(126), random(126), (60 * 60));
				SetPlayerPos(playerid, RaceVehCoords[1][0], RaceVehCoords[1][1], RaceVehCoords[1][2]+2);
				SetPlayerFacingAngle(playerid, RaceVehCoords[1][3]);
				PutPlayerInVehicle(playerid, CreatedRaceVeh[playerid], 0);
				Camera(playerid, RaceVehCoords[1][0], RaceVehCoords[1][1], RaceVehCoords[1][2], RaceVehCoords[1][3], 20);
				PlayersCount[1] = 1;
		    }
   		}
	}
	new
	    string[128]
	;
	#if defined RACE_IN_OTHER_WORLD
	SetPlayerVirtualWorld(playerid, 10);
	#endif
	InfoTimer[playerid] = SetTimerEx("TextInfo", 500, 1, "e", playerid);
	if(JoinCount == 1) format(string, sizeof(string), "RaceName: ~w~%s~n~~p~~h~Checkpoint: ~w~%d/%d~n~~b~~h~RaceTime: ~w~%s~n~~y~RacePosition: ~w~1/1~n~ ", RaceName, CPProgess[playerid], TotalCP, TimeConvert(RaceTime));
		else format(string, sizeof(string), "RaceName: ~w~%s~n~~p~~h~Checkpoint: ~w~%d/%d~n~~b~~h~RaceTime: ~w~%s~n~~y~RacePosition: ~w~%d/%d~n~ ", RaceName, CPProgess[playerid], TotalCP, TimeConvert(RaceTime), RacePosition[playerid], JoinCount);
	TextDrawSetString(RaceInfo[playerid], string);
	TextDrawShowForPlayer(playerid, RaceInfo[playerid]);
	JoinCount++;
	return 1;
}

function CountTillRace()
{
	switch(CountAmount)
	{
 		case 0:
	    {
			ForEach(i, MAX_PLAYERS)
			{
			    if(Joined[i] == false)
			    {
			        new
			            string[128]
					;
					format(string, sizeof(string), ">> You can't join to \"%s\" named race anymore. Join time is over!", RaceName);
					SendClientMessage(i, RED, string);
				}
			}
			StartRace();
	    }
	    case 1..5:
	    {
	        new
	            string[10]
			;
			format(string, sizeof(string), "~b~%d", CountAmount);
			ForEach(i, MAX_PLAYERS)
			{
			    if(Joined[i] == true)
			    {
			    	GameTextForPlayer(i, string, 999, 5);
			    	PlayerPlaySound(i, 1056, 0.0, 0.0, 0.0);
			    }
			}
	    }
	    case 60, 50, 40, 30, 20, 10:
	    {
	        new
	            string[128]
			;
			format(string, sizeof(string), ">> \"%d\" seconds till \"%s\" named race starts! Type \"/joinrace\" to join the race.", CountAmount, RaceName);
			SendClientMessageToAll(GREEN, string);
	    }
	}
	return CountAmount--;
}

function StartRace()
{
	ForEach(i, MAX_PLAYERS)
	{
	    if(Joined[i] == true)
	    {
	        TogglePlayerControllable(i, true);
	        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
  			GameTextForPlayer(i, "~g~GO GO GO", 2000, 5);
			SetCameraBehindPlayer(i);
	    }
	}
	rCounter = SetTimer("RaceCounter", 900, 1);
	RaceTick = GetTickCount();
	RaceStarted = 1;
	KillTimer(CountTimer);
	return 1;
}

function StopRace()
{
	KillTimer(rCounter);
	RaceStarted = 0;
	RaceTick = 0;
	RaceBusy = 0x00;
	JoinCount = 0;
	FinishCount = 0;
    TimeProgress = 0;
    
	ForEach(i, MAX_PLAYERS)
	{
	    if(Joined[i] == true)
	    {
	    	DisablePlayerRaceCheckpoint(i);
	    	DestroyVehicle(CreatedRaceVeh[i]);
	    	Joined[i] = false;
			TextDrawHideForPlayer(i, RaceInfo[i]);
			CPProgess[i] = 0;
			KillTimer(InfoTimer[i]);
		}
	}
	SendClientMessageToAll(YELLOW, ">> Race time is over!");
	if(AutomaticRace == true) LoadRaceNames(), LoadAutoRace(RaceNames[random(TotalRaces)]);
	return 1;
}

function RaceCounter()
{
	if(RaceStarted == 1)
	{
		RaceTime--;
		if(JoinCount <= 0)
		{
			StopRace();
			SendClientMessageToAll(RED, ">> Race ended.. No one left in the race!");
		}
	}
	if(RaceTime <= 0)
	{
	    StopRace();
	}
	return 1;
}

function TextInfo(playerid)
{
	new
	    string[128]
	;
	if(JoinCount == 1) format(string, sizeof(string), "RaceName: ~w~%s~n~~p~~h~Checkpoint: ~w~%d/%d~n~~b~~h~RaceTime: ~w~%s~n~~y~RacePosition: ~w~1/1~n~", RaceName, CPProgess[playerid], TotalCP, TimeConvert(RaceTime));
		else format(string, sizeof(string), "RaceName: ~w~%s~n~~p~~h~Checkpoint: ~w~%d/%d~n~~b~~h~RaceTime: ~w~%s~n~~y~RacePosition: ~w~%d/%d~n~", RaceName, CPProgess[playerid], TotalCP, TimeConvert(RaceTime), RacePosition[playerid], JoinCount);
	TextDrawSetString(RaceInfo[playerid], string);
	TextDrawShowForPlayer(playerid, RaceInfo[playerid]);
}

function Camera(playerid, Float:X, Float:Y, Float:Z, Float:A, Mul)
{
	SetPlayerCameraLookAt(playerid, X, Y, Z);
	SetPlayerCameraPos(playerid, X + (Mul * floatsin(-A, degrees)), Y + (Mul * floatcos(-A, degrees)), Z+6);
}

function IsPlayerInRace(playerid)
{
	if(Joined[playerid] == true) return true;
	    else return false;
}

function ShowDialog(playerid, dialogid)
{
	switch(dialogid)
	{
		case 599: ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_LIST, CreateCaption("Build New Race"), "\
		Normal Race\n\
		Air Race", "Next", "Exit");

	    case 600: ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_INPUT, CreateCaption("Build New Race (Step 1/4)"), "\
		Step 1:\n\
		********\n\
 		Welcome to wizard 'Build New Race'.\n\
		Before getting started, I need to know the name (e.g. SFRace) of the to save it under.\n\n\
		>> Give the NAME below and press 'Next' to continue.", "Next", "Back");

	    case 601: ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_INPUT, CreateCaption("Build New Race (Step 1/4)"), "\
	    ERROR: Name too short or too long! (min. 1 - max. 20)\n\n\n\
		Step 1:\n\
		********\n\
 		Welcome to wizard 'Build New Race'.\n\
		Before getting started, I need to know the name (e.g. SFRace) of the to save it under.\n\n\
		>> Give the NAME below and press 'Next' to continue.", "Next", "Back");

		case 602: ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_INPUT, CreateCaption("Build New Race (Step 2/4)"), "\
		Step 2:\n\
		********\n\
		Please give the ID or NAME of the vehicle that's going to be used in the race you are creating now.\n\n\
		>> Give the ID or NAME of the vehicle below and press 'Next' to continue. 'Back' to change something.", "Next", "Back");

		case 603: ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_INPUT, CreateCaption("Build New Race (Step 2/4)"), "\
		ERROR: Invalid Vehilce ID/Name\n\n\n\
		Step 2:\n\
		********\n\
		Please give the ID or NAME of the vehicle that's going to be used in the race you are creating now.\n\n\
		>> Give the ID or NAME of the vehicle below and press 'Next' to continue. 'Back' to change something.", "Next", "Back");

		case 604: ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_MSGBOX, CreateCaption("Build New Race (Step 3/4)"),
		"\
		Step 3:\n\
		********\n\
		We are almost done! Now go to the start line where the first and second car should stand.\n\
		Note: When you click 'OK' you will be free. Use 'KEY_FIRE' to set the first position and second position.\n\
		Note: After you got these positions you will automaticly see a dialog to continue the wizard.\n\n\
		>> Press 'OK' to do the things above. 'Back' to change something.", "OK", "Back");

		case 605: ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_MSGBOX, CreateCaption("Build New Race (Step 4/4)"),
		"\
		Step 4:\n\
		********\n\
		Welcome to the last stap. In this stap you have to set the checkpoints; so if you click 'OK' you can set the checkpoints.\n\
		You can set the checkpoints with 'KEY_FIRE'. Each checkpoint you set will save.\n\
		You have to press 'ENTER' button when you're done with everything. You race is aviable then!\n\n\
		>> Press 'OK' to do the things above. 'Back' to change something.", "OK", "Back");
		
		case 606: ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_MSGBOX, CreateCaption("Build New Race (Done)"),
		"\
		You have created your race and it's ready to use now.\n\n\
		>> Press 'Finish' to finish. 'Exit' - Has no effect.", "Finish", "Exit");
	}
	return 1;
}

CreateCaption(arguments[])
{
	new
	    string[128 char]
	;
	format(string, sizeof(string), "RyDeR's Race System - %s", arguments);
	return string;
}

stock IsValidVehicle(vehicleid)
{
	if(vehicleid < 400 || vehicleid > 611) return false;
	    else return true;
}

ReturnVehicleID(vName[])
{
	Loop(x, 211)
	{
	    if(strfind(vNames[x], vName, true) != -1)
		return x + 400;
	}
	return -1;
}

TimeConvert(seconds)
{
	new tmp[16];
 	new minutes = floatround(seconds/60);
  	seconds -= minutes*60;
   	format(tmp, sizeof(tmp), "%d:%02d", minutes, seconds);
   	return tmp;
}
