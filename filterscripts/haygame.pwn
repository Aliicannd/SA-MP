#define FILTERSCRIPT

#include <a_samp>
#include <foreach>
#include <zcmd>

#define ConvertTime(%0,%1,%2,%3,%4) \
	new \
	    Float: %0 = floatdiv(%1, 60000) \
	;\
	%2 = floatround(%0, floatround_tozero); \
	%3 = floatround(floatmul(%0 - %2, 60), floatround_tozero); \
	%4 = floatround(floatmul(floatmul(%0 - %2, 60) - %3, 1000), floatround_tozero)

#define ORANGE 		0xDB881AAA
#define HAY_X		4
#define HAY_Y		4
#define HAY_Z		30
#define HAY_B		146
#define HAY_R		4
#define SPEED_FACTOR	3000.0
#define ID_HAY_OBJECT	3374

new bool: JoinedHay[MAX_PLAYERS] = false;
new HayGameLevel[MAX_PLAYERS] = -1, HayGameTime[MAX_PLAYERS], PlayerText:HAYTD[MAX_PLAYERS];

new Speed_xy, Speed_z, Center_x, Center_y;
new Matrix[HAY_X][HAY_Y][HAY_Z];
new Hays[HAY_B];

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Hay Minigame By ScRaT");
	print("--------------------------------------\n");
	RestartEveryThing();
	return 1;
}
public OnPlayerConnect(playerid)
{
    HayGameLevel[playerid] = 0;
    JoinedHay[playerid] = false;
    
	HAYTD[playerid] = CreatePlayerTextDraw(playerid, 549.000000,397.000000," ");
	PlayerTextDrawFont(playerid, HAYTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, HAYTD[playerid], 1);
	PlayerTextDrawSetOutline(playerid, HAYTD[playerid], 0);
	PlayerTextDrawColor(playerid, HAYTD[playerid], -65281);
	PlayerTextDrawLetterSize(playerid, HAYTD[playerid], 0.310000,1.400000);
	PlayerTextDrawTextSize(playerid, HAYTD[playerid], 640.000000,0.000000);
	PlayerTextDrawAlignment(playerid, HAYTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, HAYTD[playerid], 0);
	PlayerTextDrawUseBox(playerid, HAYTD[playerid], 1);
	PlayerTextDrawBoxColor(playerid, HAYTD[playerid], 255);
	PlayerTextDrawBackgroundColor(playerid, HAYTD[playerid], 255);
	return 1;
}

public OnPlayerSpawn(playerid)
{
    JoinedHay[playerid] = false;
  	SetPlayerWorldBounds(playerid, 20000.0000, -20000.0000, 20000.0000, -20000.0000);
  	PlayerTextDrawHide(playerid, HAYTD[playerid]);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    PlayerTextDrawHide(playerid, HAYTD[playerid]);
    JoinedHay[playerid] = false;
	return 1;
}
CMD:hay(playerid)
{
	switch(JoinedHay[playerid])
	{
	    case false:
	    {
			JoinedHay[playerid] = true;
			SetPlayerWorldBounds(playerid, 116.7788, -70.06725, 105.1009, -116.7788);
	 		HayGameTime[playerid] = GetTickCount();
			SetPlayerPos(playerid, 0, 6.5, 3.2);
			SetPlayerFacingAngle( playerid, 135 );
			SetPlayerVirtualWorld(playerid, 50);
			ResetPlayerWeapons(playerid);
			PlayerTextDrawShow(playerid, HAYTD[playerid]);
	    }
	    case true:
	    {
	        JoinedHay[playerid] = false;
	        SetPlayerWorldBounds(playerid, 20000.0000, -20000.0000, 20000.0000, -20000.0000);
	        PlayerTextDrawHide(playerid,HAYTD[playerid]);
	        SpawnPlayer(playerid);
		}
	}
	return 1;
}
RestartEveryThing()
{
	new xq, yq, zq, Number;

	Speed_xy = 2000 / (HAY_Z + 1);
	Speed_z = 1500 / (HAY_Z + 1);
	foreach(new i: Player)
	{
		HayGameLevel[i] = 0;
	}
	for(xq = 0; xq < HAY_X; xq++)
	{
		for(yq = 0; yq < HAY_Y; yq++)
		{
			for(zq = 0; zq < HAY_Z; zq++)
			{
				Matrix[xq][yq][zq] = 0;
			}
		}
	}
	for(Number = 0; Number < HAY_B; Number++)
	{
		do
		{
			xq = random(HAY_X);
			yq = random(HAY_Y);
			zq = random(HAY_Z);
  		}
		while(Matrix[xq][yq][zq] != 0);
		Matrix[xq][yq][zq] = 1;
		Hays[Number] = CreateObject(ID_HAY_OBJECT, xq*(-4), yq*(-4), (zq+1)*3, 0.0, 0.0, random(2)*180,50);
	}
	Center_x = (HAY_X + 1) * -2;
	Center_y = (HAY_Y + 1) * -2;
	CreateObject(ID_HAY_OBJECT, Center_x, Center_y, HAY_Z*3 + 3, 0, 0, 0,50);
	SetTimer("TimerMove", 100, 0);
	SetTimer("TDScore", 1000, 1);
}
forward TimerMove();
public TimerMove()
{
	new rand, Hay, xq, yq, zq, Float:x2, Float:y2, Float:z2, Timez, Float:Speed;
	new Move = -1;

	rand = random (HAY_B);
	Hay = Hays[rand];
	if(IsObjectMoving(Hay))
	{
		SetTimer ("TimerMove", 200, 0);
		return 1;
	}
	Move = random (6);
	GetObjectPos(Hay, x2, y2, z2);
	xq = floatround(x2/-4.0);
	yq = floatround(y2/-4.0);
	zq = floatround(z2/3.0)-1;
	if((Move == 0)  && (xq != 0) && (Matrix[xq-1][yq][zq] == 0))
	{
		Timez = 4000 - Speed_xy * zq;
		Speed = SPEED_FACTOR / float(Timez);
		SetTimerEx("FinishTimer", Timez, 0, "iiii", rand, xq, yq, zq);
		xq = xq - 1;
		Matrix[xq][yq][zq] = 1;
		MoveObject(Hay, x2+4.0, y2, z2, Speed);
	}
	else if((Move == 1) && (xq != HAY_X-1) && (Matrix[xq+1][yq][zq] == 0))
	{
		Timez = 4000 - Speed_xy * zq;
		Speed = SPEED_FACTOR / float(Timez);
		SetTimerEx("FinishTimer", Timez, 0, "iiii", rand, xq, yq, zq);
		xq = xq + 1;
		Matrix[xq][yq][zq] = 1;
		MoveObject(Hay, x2-4.0, y2, z2, Speed);
	}
	else if((Move == 2) && (yq != 0) && (Matrix[xq][yq-1][zq] == 0))
	{
		Timez = 4000 - Speed_xy * zq;
		Speed = SPEED_FACTOR / float(Timez);
		SetTimerEx("FinishTimer", Timez, 0, "iiii", rand, xq, yq, zq);
		yq = yq - 1;
		Matrix[xq][yq][zq] = 1;
		MoveObject(Hay, x2, y2+4.0, z2, Speed);
	}
	else if ((Move == 3) && (yq != HAY_Y-1) && (Matrix[xq][yq+1][zq] == 0))
	{
		Timez = 4000 - Speed_xy * zq;
		Speed = SPEED_FACTOR / float (Timez);
		SetTimerEx ("FinishTimer", Timez, 0, "iiii", rand, xq, yq, zq);
		yq = yq + 1;
		Matrix[xq][yq][zq] = 1;
		MoveObject (Hay, x2, y2-4.0, z2, Speed);
	}
	else if ((Move == 4) && (zq != 0) && (Matrix[xq][yq][zq-1] == 0))
	{
		Timez = 3000 - Speed_z * zq;
		Speed = SPEED_FACTOR / float (Timez);
		SetTimerEx ("FinishTimer", Timez, 0, "iiii", rand, xq, yq, zq);
		zq = zq - 1;
		Matrix[xq][yq][zq] = 1;
		MoveObject (Hay, x2, y2, z2-3.0, Speed);
	}
	else if ((Move == 5) && (zq != HAY_Z-1) && (Matrix[xq][yq][zq+1] == 0))
	{
		Timez = 3000 - Speed_z * zq;
		Speed = SPEED_FACTOR / float (Timez);
		SetTimerEx ("FinishTimer", Timez, 0, "iiii", rand, xq, yq, zq);
		zq = zq + 1;
		Matrix[xq][yq][zq] = 1;
		MoveObject (Hay, x2, y2, z2+3.0, Speed);
	}
	else if ((Move == 6) && (zq != HAY_Z-1) && (Matrix[xq][yq][zq+1] == 0))
	{
		Timez = 3000 - Speed_z * zq;
		Speed = SPEED_FACTOR / float (Timez);
		SetTimerEx ("FinishTimer", Timez, 0, "iiii", rand, xq, yq, zq);
		zq = zq + 1;
		Matrix[xq][yq][zq] = 1;
		MoveObject (Hay, x2, y2, z2+3.0, Speed);
	}
	SetTimer ("TimerMove", 200, 0);
	return 1;
}
forward FinishTimer(id, xq, yq, zq);
public FinishTimer(id, xq, yq, zq)
{
	Matrix[xq][yq][zq] = 0;
	return 1;
}

forward TimerScore();
public TimerScore ()
{
	new Float:xq, Float:yq, Float:zq;
	foreach(new i: Player)
	{
		GetPlayerPos (i, xq, yq, zq);
		if(xq<=2.0 && xq>=-15.0 && yq<=2.0 && yq>=-15.0)
		{
			new Level = (floatround (zq)/3) - 1;
			HayGameLevel[i] = Level;
		}else
		{
			HayGameLevel[i] = 0;
		}
	}
	return 1;
}
forward TDScore();
public TDScore()
{
    TimerScore();
	new Level,string[256],PlayerN[MAX_PLAYER_NAME];
	foreach(new i: Player)
	{
		if(JoinedHay[i] == true)
		{
			new tH,tM,tS, TimeStamp = GetTickCount(), TotalRaceTime = TimeStamp - HayGameTime[i];
			ConvertTime(var, TotalRaceTime, tH, tM, tS);
			Level = HayGameLevel[i];
			format(string,sizeof(string),"~h~~y~Hay Minigame~n~~r~Level: ~w~%d/31 ~n~~r~Time: ~w~%02d:%02d", Level, tH, tM, tS);
			PlayerTextDrawSetString(i, HAYTD[i], string);
			if(HayGameLevel[i] == 31)
			{
				GetPlayerName(i, PlayerN, sizeof(PlayerN));
				format(string, sizeof(string),"[HAY] %s Finished The Hay Minigame In %02d Min %02d Sec", PlayerN, tH, tM, tS);
				SendClientMessageToAll(ORANGE,string);
				PlayerTextDrawHide(i, HAYTD[i]);
				SetPlayerPos(i,0,0,0);
				SpawnPlayer(i);
			}
		}
	}
	return 1;
}
