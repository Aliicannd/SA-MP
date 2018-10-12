#define FILTERSCRIPT
#include <a_samp>
#include <zcmd>

#define DIALOG_MYCAR 85

#define PVG->%0->%1[%2] GetPVar%0(%2,#%1)
#define PVS->%0->%1[%2]->%3; SetPVar%0(%2,#%1,%3);

CMD:mycar(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, 0xFF0000FF, "Hata » {FFFFFF}Araçta olmalısınız.");
	new mStr[1200];
	strcat(mStr,"{FFFFFF}Islem\t{FFFFFF}Açiklama\n");
	strcat(mStr,"{FF0000}Bos\t{C3C3C3}[Tusu islevsiz birakir]\n");
	strcat(mStr,"{FF0000}Hiz\t{C3C3C3}[Tusu bastiginizda araci hizlandirir]\n");
	strcat(mStr,"{FF0000}Zipla\t{C3C3C3}[Tusu bastiginizda araci ziplatir]\n");
	strcat(mStr,"{FF0000}Yon X\t{C3C3C3}[Tusu bastiginizda araci X ekseni etrafinda dondürür]\n");
	strcat(mStr,"{FF0000}Yon Y\t{C3C3C3}[Tusu bastiginizda araci Y ekseni etrafinda dondürür]\n");
	strcat(mStr,"{FF0000}Yon Z\t{C3C3C3}[Tusu bastiginizda araci Z ekseni etrafinda dondürür]\n");
	strcat(mStr,"{FF0000}Cevir\t{C3C3C3}[Tusu bastiginizda araci düzeltir]\n");
	strcat(mStr,"{FF0000}Renk\t{C3C3C3}[Tusu bastiginizda aracin rengi degisir]\n");
	strcat(mStr,"{FF0000}Fren\t{C3C3C3}[Tusu bastiginizda araci durdurur]\n");
	strcat(mStr,"{FF0000}Bagaj\t{C3C3C3}[Tusu bastiginizda aracin bagajini acar kapatir]\n");
	strcat(mStr,"{FF0000}Kaput\t{C3C3C3}[Tusu bastiginizda aracin kaputunu acar kapatir]\n");
	strcat(mStr,"{FF0000}Alarm\t{C3C3C3}[Tusu bastiginizda aracin alarmini acar kapatir]\n");
	strcat(mStr,"{FF0000}Far\t{C3C3C3}[Tusu bastiginizda aracin farlarini acar kapatir]\n");
	strcat(mStr,"{FF0000}Motor\t{C3C3C3}[Tusu bastiginizda aracin motorunu acar kapatir]\n");
	strcat(mStr,"{FF0000}Kilit\t{C3C3C3}[Tusu bastiginizda aracin kapilarini acar kapatir]\n");
	ShowPlayerDialog(playerid, DIALOG_MYCAR, DIALOG_STYLE_TABLIST_HEADERS, "{FF0000}LYNX DRIFT - {FFFFFF}MyCar",mStr,"Ates etme","H tusu");
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_MYCAR)
	{
		if(response)PVS->Int->firekey[playerid]->listitem;
		else PVS->Int->hkey[playerid]->listitem;
		switch(response)
		{
			case 0:
			{
				switch(listitem)
				{
					case 0: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu boş olarak ayarlandi!");
					case 1: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu hiz olarak ayarlandi!");
					case 2: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu ziplama olarak ayarlandi!");
					case 3: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu yon x olarak ayarlandi!");
					case 4: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu yon y olarak ayarlandi!");
					case 5: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu yon z olarak ayarlandi!");
					case 6: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu çevirme olarak ayarlandi!");
					case 7: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu renk olarak ayarlandi!");
					case 8: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu fren olarak ayarlandi!");
					case 9: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu bagaj olarak ayarlandi!");
					case 10: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu kaput olarak ayarlandi!");
					case 11: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu alarm olarak ayarlandi!");
					case 12: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu far olarak ayarlandi!");
					case 13: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu motor olarak ayarlandi!");
					case 14: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}H tuşu kilit olarak ayarlandi!");
				}
			}
			case 1:
			{
				switch(listitem)
				{
					case 0: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu boş olarak ayarlandi!");
					case 1: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu hiz olarak ayarlandi!");
					case 2: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu ziplama olarak ayarlandi!");
					case 3: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu yon x olarak ayarlandi!");
					case 4: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu yon y olarak ayarlandi!");
					case 5: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu yon z olarak ayarlandi!");
					case 6: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu çevirme olarak ayarlandi!");
					case 7: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu renk olarak ayarlandi!");
					case 8: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu fren olarak ayarlandi!");
					case 9: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu bagaj olarak ayarlandi!");
					case 10: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu kaput olarak ayarlandi!");
					case 11: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu alarm olarak ayarlandi!");
					case 12: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu far olarak ayarlandi!");
					case 13: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu motor olarak ayarlandi!");
					case 14: SendClientMessage(playerid,0xFF9900FF,"Mycar » {FFFFFF}Ateş etme tuşu kilit olarak ayarlandi!");
				}
			}
		}
	}
	return 1;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_FIRE && IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
    {
        MyCarPress(playerid, PVG->Int->firekey[playerid]);
        return 1;
    }
    if(newkeys & KEY_CROUCH && IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
    {
        MyCarPress(playerid, PVG->Int->hkey[playerid]);
        return 1;
    }
	return 1;
}
forward MyCarPress(playerid, key_f);
public MyCarPress(playerid, key_f)
{
	if(key_f == 0)return 1;
	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, 0xFF0000FF, "Hata » {FFFFFF}Bir aracin soforu olmaniz lazim!");
	new Float:T[4], motor, isiklar, alarm, kapilar, kaput, bagaj, objective, vehid = GetPlayerVehicleID(playerid);
	switch(key_f)
	{
		case 1:
		{
			GetVehicleZAngle(vehid, T[3]);
			GetVehicleVelocity(vehid, T[0], T[1], T[2]);
			SetVehicleVelocity(vehid,((floatadd(T[0],floatmul(1.01,floatsin(-T[3],degrees))/3.0))), ((floatadd(T[1],floatmul(1.01,floatcos(-T[3],degrees))/3.0))), T[2]);
		}
		case 2:
		{
			GetVehicleVelocity(vehid, T[0], T[1], T[2]);
			SetVehicleVelocity(vehid, T[0], T[1], (T[2]+0.4));
		}
		case 3:
		{
			GetVehicleZAngle(vehid, T[3]);
			SetVehicleAngularVelocity(vehid, ((floatadd(0,floatmul(1.01,floatcos(T[3],degrees))))*2)/5, ((floatadd(0,floatmul(1.01,floatsin(T[3],degrees))))*2)/5, 0.0);
		}
		case 4:
		{
			GetVehicleZAngle(vehid, T[3]);
			SetVehicleAngularVelocity(vehid, ((floatadd(0,floatmul(1.01,floatsin(-T[3],degrees))))*2)/5, ((floatadd(0,floatmul(1.01,floatcos(-T[3],degrees))))*2)/5, 0.0);
		}
		case 5: SetVehicleAngularVelocity(vehid, 0.0, 0.0, 0.3);
		case 6:
		{
			GetVehicleZAngle(vehid,T[3]);
			SetVehicleZAngle(vehid,T[3]);
		}
		case 7: ChangeVehicleColor(vehid,random(256),random(256));
		case 8: SetVehicleVelocity(vehid, 0, 0, 0);
		case 9:
		{
			GetVehicleParamsEx(vehid,motor,isiklar,alarm,kapilar,kaput,bagaj,objective);
			SetVehicleParamsEx(vehid,motor,isiklar,alarm,kapilar,kaput,(PVG->Int->bagaj[playerid] == 0) ? (VEHICLE_PARAMS_ON) : (VEHICLE_PARAMS_OFF),objective);
			PVS->Int->bagaj[playerid]->!PVG->Int->bagaj[playerid];
		}
		case 10:
		{
			GetVehicleParamsEx(vehid,motor,isiklar,alarm,kapilar,kaput,bagaj,objective);
			SetVehicleParamsEx(vehid,motor,isiklar,alarm,kapilar,(PVG->Int->kaput[playerid] == 0) ? (VEHICLE_PARAMS_ON) : (VEHICLE_PARAMS_OFF),bagaj,objective);
			PVS->Int->kaput[playerid]->!PVG->Int->kaput[playerid];
		}
		case 11:
		{
			GetVehicleParamsEx(vehid,motor,isiklar,alarm,kapilar,kaput,bagaj,objective);
			SetVehicleParamsEx(vehid,motor,isiklar,(PVG->Int->alarm[playerid] == 0) ? (VEHICLE_PARAMS_ON) : (VEHICLE_PARAMS_OFF),kapilar,kaput,bagaj,objective);
			PVS->Int->alarm[playerid]->!PVG->Int->alarm[playerid];
		}
		case 12:
		{
			GetVehicleParamsEx(vehid,motor,isiklar,alarm,kapilar,kaput,bagaj,objective);
			SetVehicleParamsEx(vehid,motor,(PVG->Int->isiklar[playerid] == 0) ? (VEHICLE_PARAMS_ON) : (VEHICLE_PARAMS_OFF),alarm,kapilar,kaput,bagaj,objective);
			PVS->Int->isiklar[playerid]->!PVG->Int->isiklar[playerid];
		}
		case 13:
		{
			GetVehicleParamsEx(vehid,motor,isiklar,alarm,kapilar,kaput,bagaj,objective);
			SetVehicleParamsEx(vehid,(PVG->Int->motor[playerid] == 0) ? (VEHICLE_PARAMS_ON) : (VEHICLE_PARAMS_OFF),isiklar,alarm,kapilar,kaput,bagaj,objective);
			PVS->Int->motor[playerid]->!PVG->Int->motor[playerid];
		}
		case 14:
		{
			GetVehicleParamsEx(vehid,motor,isiklar,alarm,kapilar,kaput,bagaj,objective);
			SetVehicleParamsEx(vehid,motor,isiklar,alarm,(PVG->Int->kapilar[playerid] == 0) ? (VEHICLE_PARAMS_ON) : (VEHICLE_PARAMS_OFF),kaput,bagaj,objective);
			PVS->Int->kapilar[playerid]->!PVG->Int->kapilar[playerid];
		}
	}
	return 1;
}
