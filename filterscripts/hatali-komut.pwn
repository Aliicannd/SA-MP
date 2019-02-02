#include <a_samp>
 
enum enumsa
{
    names[25]
}
new Komutlar[115][enumsa] =
{
    {"/setlevel"},{"/setdj"},{"/setarmour"},{"/setheal"},{"/setscore"},
    {"/givecash"},{"/giveexp"},{"/ban"},{"/nban"},{"/giveweapon"},{"/kick"},
    {"/mute"},{"/unmute"},{"/sarki"},{"/clearchat"},{"/goto"},{"/get"},
    {"/setallweather"},{"/setalltime"},{"/mkapat"},{"/yayinac"},{"/pm"},{"/re"},
    {"/pmon"},{"/pmoff"},{"/l"},{"/jetpack"},{"/gopos"},{"/setcolor"},{"/aka"},
    {"/spec"},{"/specoff"},{"/rac"},{"/pmspec"},{"/pmspecoff"},{"/otorenk"},{"/yarisekle"},
    {"/yarisdurdur"},{"/myskin"},{"/saveskin"},{"/mytime"},{"/myweather"},{"/radio"},
    {"/dinle"},{"/gungamecik"},{"/dmcik"},{"/sos"},{"/yariscik"},{"/tdmcik"},{"/tdmler"},
    {"/tdmkatil"},{"/yarislar"},{"/yariskatil"},{"/gungame"},{"/duel"},{"/veh"},
    {"/vrenk"},{"/savepos"},{"/loadpos"},{"/stats"},{"/admins"},{"/adminlistesi"},
    {"/djs"},{"/djlistesi"},{"/nickdegis"},{"/sifredegis"},{"/tune"},{"/skinler"},
    {"/mycar"},{"/ojump"},{"/mycar"},{"/dmzone"},{"/mg1"},{"/mg2"},{"/mg3"},
    {"/deagle"},{"/rpg"},{"/knifedm"},{"/sniperdm"},{"/pb1"},{"/pb2"},{"/pb3"},
    {"/snipshot"},{"/dgshot"},{"/topskor"},{"/toppara"},{"/topkill"},{"/topdeath"},
    {"/toponline"},{"/credits"},{"/yapimcilar"},{"/drift1"},{"/drift2"},{"/drift3"},
    {"/drift4"},{"/drift5"},{"/drift6"},{"/drift7"},{"/drift8"},{"/drift9"},{"/drift10"},
    {"/drift11"},{"/drift12"},{"/drift13"},{"/drift14"},{"/drift15"},{"/lvap"},
    {"/sfap"},{"/olap"},{"/lsap"},{"/dag"},{"/djmekan"},{"/skilledinf"},{"/superstunt"},{"/cz"}
};
 
public OnPlayerCommandText(playerid, cmdtext[])
{
    return HataliKomut(playerid, cmdtext);
}
stock HataliKomut(playerid, komut[])
{
    new a[128],str[56], found = 0;
    for(new i = 0; i < sizeof(Komutlar); i++)
    {
        new namelen = strlen(Komutlar[i]);
        for(new pos = 0; pos <= namelen; pos++)
        {
            if(strfind(Komutlar[i],komut,true) == pos)
            {
                if(found == 3) break;
                found++;
                format(str,sizeof(str),"%s%s,\n", str, Komutlar[i][names]);
            }
        }
    }
    if(found == 0) return SendClientMessage(playerid, 0xFF0000FF, "Hata » {FFFFFF}Bilinmeyen komut.");
    else format(a, 128, "Hata » {FFFFFF}Bilinmeyen komut. Yakın komutlar %s", str);
    return SendClientMessage(playerid, 0xFF0000FF, a);
}
