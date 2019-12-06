#define FILTERSCRIPT
#include <a_samp>
#include <weapon-config>

new FakeKill[MAX_PLAYERS] = {INVALID_PLAYER_ID, ...};

public OnPlayerConnect(playerid)
{
	FakeKill[playerid] = INVALID_PLAYER_ID;
	return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
	if(killerid != INVALID_PLAYER_ID && FakeKill[playerid] != killerid) return BanEx(playerid, "Fake Kill");
	return 1;
}
public OnPlayerDamage(&playerid, &Float:amount, &issuerid, &weapon, &bodypart)
{
	if(issuerid != INVALID_PLAYER_ID)
	{
		FakeKill[playerid] = issuerid;
	}
	return 1;
}
