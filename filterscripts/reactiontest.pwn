#define FILTERSCRIPT
#include <a_samp>

enum Reaction
{
	rQuiz[128],
	rMoney,
	rScore,
	bool: rState,
	rTickCount
};
new ReactionTestInfo[Reaction];

public OnFilterScriptInit()
{
	SetTimer("ReactionTest", 1000*60*5, true);
	return 1;
}
public OnPlayerText(playerid, text[])
{
	if(ReactionTestInfo[rState] == true && !strcmp(ReactionTestInfo[rQuiz], text, false))
	{
		new str[128];
		format(str, sizeof(str), "Reaction » {FFFFFF}%s reaction testi kazandı {00D799}Odul $%d + %d skor (%d)", PlayerName(playerid), ReactionTestInfo[rMoney], ReactionTestInfo[rScore], ConvertTime(GetTickCount() - ReactionTestInfo[rTickCount]));
		SendClientMessageToAll(0x10869EFF, str);
		GivePlayerMoney(playerid, ReactionTestInfo[rMoney]);
		SetPlayerScore(playerid, GetPlayerScore(playerid)+ReactionTestInfo[rScore]);
		ReactionTestInfo[rState] = false;
	}
	return 0;
}
forward ReactionTest();
public ReactionTest()
{
	new str[256];
	new RandomLetter[][] =
	{
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
		"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
		"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
	};
	switch(random(17))
	{
		case 0..4:
		{
			format(ReactionTestInfo[rQuiz], 10, "%d%d%s%s%s%d%s%d%s%d",
			random(5), random(9), RandomLetter[random(sizeof(RandomLetter))], RandomLetter[random(sizeof(RandomLetter))], RandomLetter[random(sizeof(RandomLetter))], random(9) , RandomLetter[random(sizeof(RandomLetter))], random(9) , RandomLetter[random(sizeof(RandomLetter))], random(9));
			ReactionTestInfo[rMoney] = 7000, ReactionTestInfo[rScore] = 30;
        }
		case 5..8:
		{
			format(ReactionTestInfo[rQuiz], 10, "%d%d%d%d%s%d%s%d%d%d",
			random(5), random(9), random(9), random(9), RandomLetter[random(sizeof(RandomLetter))], random(9) , RandomLetter[random(sizeof(RandomLetter))], random(9) , random(9), random(9));
			ReactionTestInfo[rMoney] = 7000, ReactionTestInfo[rScore] = 30;
		}
		case 9..12:
		{
			format(ReactionTestInfo[rQuiz], 10, "%s%s%s%s%s%s%s%d%s%d",
			RandomLetter[random(sizeof(RandomLetter))], RandomLetter[random(sizeof(RandomLetter))], RandomLetter[random(sizeof(RandomLetter))], RandomLetter[random(sizeof(RandomLetter))], RandomLetter[random(sizeof(RandomLetter))], RandomLetter[random(sizeof(RandomLetter))] , RandomLetter[random(sizeof(RandomLetter))], random(9) , RandomLetter[random(sizeof(RandomLetter))], random(9));
			ReactionTestInfo[rMoney] = 7000, ReactionTestInfo[rScore] = 30;
		}
		case 13: format(ReactionTestInfo[rQuiz], 10, "<(-__-)>"), ReactionTestInfo[rMoney] = 5000, ReactionTestInfo[rScore] = 20;
		case 14: format(ReactionTestInfo[rQuiz], 45, "I <3 EXCISION"), ReactionTestInfo[rMoney] = 7000, ReactionTestInfo[rScore] = 50;
		case 15: format(ReactionTestInfo[rQuiz], 45, "I <3 LYNX"), ReactionTestInfo[rMoney] = 4000, ReactionTestInfo[rScore] = 40;
		case 16: format(ReactionTestInfo[rQuiz], 45, "I FUCK LEVI"), ReactionTestInfo[rMoney] = 7000, ReactionTestInfo[rScore] = 50;
	}
	ReactionTestInfo[rState] = true;
	format(str, sizeof(str), "Reaction » {FFFFFF}İlk önce kim {00D799}%s {FFFFFF}yazarsa reaction testi kazanır!", ReactionTestInfo[rQuiz]);
	SendClientMessageToAll(0x10869EFF, str);
	ReactionTestInfo[rTickCount] = GetTickCount();
	return 1;
}
stock ConvertTime(time)
{
	new verilenSure = time / 1000;
	return floatround(verilenSure);
}
stock PlayerName(playerid)
{
	new oName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, oName, sizeof oName);
	return oName;
}
