#define FILTERSCRIPT

#include <a_samp>
#include <zcmd>

#define DIALOG_RADIO 3131

new Radyolar[][] =
{
	{"http://7509.live.streamtheworld.com:80/METRO_FM2_SC", "Metro FM"},
	{"http://50.7.98.106:8398", "Bassdrive"},
	{"http://noisefm.ru:8000/play", "Noise FM"},
	{"http://stream.dubstep.fm:80/256mp3", "Dubstep FM"},
	{"http://185.33.21.112:11029", "Amsterdam Trance Radio"},
	{"http://206.190.131.100:9898", "RADIO LIVE"},
	{"http://radyo.dogannet.tv/hitplay", "Hitplay Radio"}
};

CMD:radio(playerid)
{
	new list[500];
	for(new i = 0; i <= sizeof(Radyolar); i++)
	{
		format(list, sizeof(list), "%s\n{00FFA2}%d. {FFFFFF}%s",list, i+1, Radyolar[i][1]);
	}
	ShowPlayerDialog(playerid, DIALOG_RADIO, DIALOG_STYLE_LIST, "Radio List", list, "Tamam", "İptal");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_RADIO)
	{
		if(response)
		{
			if(listitem == sizeof(Radyolar)) return cmd_radio(playerid);
			StopAudioStreamForPlayer(playerid), PlayAudioStreamForPlayer(playerid, Radyolar[listitem][0]);
			new string[128];
			format(string, 128, "%s Adlı yayini açtiniz.", Radyolar[listitem][1]);
			SendClientMessage(playerid, -1, string);
		}
	}
	return 1;
}
