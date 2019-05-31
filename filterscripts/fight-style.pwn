#include <a_samp>
#include <zcmd>

#define DIALOG_FIGHT_STYLE 31

enum FightStyleData
{
	FightStyleName[16],
	FightStyleID
}
new FightStyle[6][FightStyleData] =
{
	{"Normal", FIGHT_STYLE_NORMAL},
	{"Boxing", FIGHT_STYLE_BOXING},
	{"KungFu", FIGHT_STYLE_KUNGFU},
	{"Knee-head", FIGHT_STYLE_KNEEHEAD},
	{"Grab-kick", FIGHT_STYLE_GRABKICK},
	{"Elbow-kick", FIGHT_STYLE_ELBOW}
};

CMD:dovusstili(playerid)
{
	new iString[128];
	for(new i = 0; i < 6; i++)
	{
		format(iString, sizeof(iString), "%s{FFFFFF}%s\n", iString, FightStyle[i][FightStyleName]);
	}
	ShowPlayerDialog(playerid, DIALOG_FIGHT_STYLE, DIALOG_STYLE_LIST, "Dövüş Stilleri", iString, "Tamam", "İptal");
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_FIGHT_STYLE)
	{
		if(!response) return 1;
 		new iString[128];
		format(iString, sizeof(iString), "Dövüş stilinizi %s olarak değiştirdiniz.", FightStyle[listitem][FightStyleName]);
		SendClientMessage(playerid, -1, iString);
		SetPlayerFightingStyle(playerid, FightStyle[listitem][FightStyleID]);
		return 1;
	}
	return 1;
}
