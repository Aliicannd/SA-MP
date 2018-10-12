#define 	FILTERSCRIPT
#include 	<a_samp>
#include    <a_mysql>
#include    <streamer>
#include    <sscanf2>
#include    <YSI\y_iterate>
#include    <zcmd>

#define		SQL_HOST			"sql host"
#define		SQL_USER			"sql username"
#define		SQL_PASSWORD		"sql password"
#define		SQL_DBNAME			"database name"

#define     MAX_BUSINESS        (100)
#define     MAX_BUSINESS_NAME	(32)    // maximum length of a business's name (default: 32)
#define     BUSINESS_INTERVAL   (30)    // give money to businesses every x minutes, also saves businesses (default: 30)
#define     BUSINESS_DAYS  		(7)     // if a business's owner doesn't visit their business after x days, it will get reset (default: 7)
#define     LIMIT_PER_PLAYER    (3)     // a player can buy up to x businesses - you can set this to 0 if you want it unlimited (default: 3)
#define     INVALID_BUSINESS    (-1)

enum    e_businessdialogs
{
	DIALOG_BUY_BUSINESS = 21500,
	DIALOG_BUY_BUSINESS_FROM_OWNER,
	DIALOG_MANAGE_BUSINESS,
	DIALOG_MANAGE_BUSINESS_NAME,
	DIALOG_MANAGE_BUSINESS_SAFE,
	DIALOG_MANAGE_DEPOSIT_TO_SAFE,
	DIALOG_MANAGE_TAKE_FROM_SAFE,
	DIALOG_MANAGE_SELL,
	DIALOG_MANAGE_SELL_TO_PLAYERS,
	DIALOG_MANAGE_PERMISSIONS,
	DIALOG_MANAGE_GIVE_PERM_NAME,
	DIALOG_MANAGE_GIVE_PERM_DEPOSIT,
    DIALOG_MANAGE_GIVE_PERM_TAKE,
    DIALOG_MANAGE_LIST_PERMS,
    DIALOG_MANAGE_EDIT_PERMS,
    DIALOG_MANAGE_SAFE_LOGS,
	DIALOG_ADMIN_BUSINESS_TYPE
}

enum    e_businessperms
{
 	PERM_CAN_USE_SAFE,
	PERM_CAN_DEPOSIT,
	PERM_CAN_TAKE
}

enum    e_business
{
	// saved
	Name[MAX_BUSINESS_NAME],
	Owner[MAX_PLAYER_NAME],
	Float: BusinessX,
	Float: BusinessY,
	Float: BusinessZ,
	Closed,
	Price,
	SalePrice,
	Earning,
	Money,
	Type,
	LastVisited,
	// not saved
	Text3D: BusinessLabel,
	BusinessPickup,
	bool: Save
}

enum    e_businessint
{
	InteriorName[32],
	Float: InteriorX,
	Float: InteriorY,
	Float: InteriorZ,
	InteriorID,
	ExitPickup,
	Text3D: ExitLabel
};

new
	MySQL:BusinessSQL,
	BusinessData[MAX_BUSINESS][e_business],
	Iterator: Business<MAX_BUSINESS>;

new
	InBusiness[MAX_PLAYERS] = {INVALID_BUSINESS, ...},
	ListPage[MAX_PLAYERS];

new
	BusinessStates[2][16] = {"{2ECC71}Open", "{E74C3C}Closed"},
	PermissionStates[2][16] = {"{E74C3C}No", "{2ECC71}Yes"};

new
	BusinessInteriors[][e_businessint] = {
		{"24/7 1", -25.884498, -185.868988, 1003.546875, 17},
		{"24/7 2", 6.091179, -29.271898, 1003.549438, 10},
		{"24/7 3", -30.946699, -89.609596, 1003.546875, 18},
		{"24/7 4", -25.132598, -139.066986, 1003.546875, 16},
		{"24/7 5", -27.312299, -29.277599, 1003.557250, 4},
		{"24/7 6", -26.691598, -55.714897, 1003.546875, 6},
		{"Ammunation 1", 286.148986, -40.644397, 1001.515625, 1},
		{"Ammunation 2", 286.800994, -82.547599, 1001.515625, 4},
		{"Ammunation 3", 296.919982, -108.071998, 1001.515625, 6},
		{"Ammunation 4", 314.820983, -141.431991, 999.601562, 7},
		{"Ammunation 5", 316.524993, -167.706985, 999.593750, 6},
		{"Sex Shop", -103.559165, -24.225606, 1000.718750, 3},
		{"Binco", 207.737991, -109.019996, 1005.132812, 15},
		{"Didier Sachs", 204.332992, -166.694992, 1000.523437, 14},
		{"ProLaps", 207.054992, -138.804992, 1003.507812, 3},
		{"Sub Urban", 203.777999, -48.492397, 1001.804687, 1},
		{"Victim", 226.293991, -7.431529, 1002.210937, 5},
		{"Zip", 161.391006, -93.159156, 1001.804687, 18},
		{"Alhambra", 493.390991, -22.722799, 1000.679687, 17},
		{"Bar", 501.980987, -69.150199, 998.757812, 11},
		{"Burger Shot", 375.962463, -65.816848, 1001.507812, 10},
		{"Cluckin' Bell", 369.579528, -4.487294, 1001.858886, 9},
		{"Well Stacked Pizza", 373.825653, -117.270904, 1001.499511, 5},
		{"Strip Club", 1204.809936, -11.586799, 1000.921875, 2},
		{"Pleasure Domes", -2640.762939, 1406.682006, 906.460937, 3},
		{"Barber 1", 411.625976, -21.433298, 1001.804687, 2},
		{"Barber 2", 418.652984, -82.639793, 1001.804687, 3},
		{"Barber 3", 412.021972, -52.649898, 1001.898437, 12},
		{"Tatoo Parlour", -204.439987, -26.453998, 1002.273437, 16}
	};

convertNumber(value)
{
	// http://forum.sa-mp.com/showthread.php?p=843781#post843781
    new string[24];
    format(string, sizeof(string), "%d", value);

    for(new i = (strlen(string) - 3); i > (value < 0 ? 1 : 0) ; i -= 3)
    {
        strins(string[i], ",", 0);
    }

    return string;
}

Business_Save(businessid)
{
	new query[256];
	mysql_format(BusinessSQL, query, sizeof(query), "UPDATE business SET Name='%e', Owner='%e', Closed='%d', Price='%d', SalePrice='%d', Earning='%d', Money='%d', Type='%d', LastVisited='%d' WHERE ID='%d'",
	BusinessData[businessid][Name], BusinessData[businessid][Owner], BusinessData[businessid][Closed], BusinessData[businessid][Price], BusinessData[businessid][SalePrice], BusinessData[businessid][Earning],
	BusinessData[businessid][Money], BusinessData[businessid][Type], BusinessData[businessid][LastVisited], businessid);
	mysql_tquery(BusinessSQL, query, "", "");

	BusinessData[businessid][Save] = false;
	return 1;
}

Business_UpdateLabel(businessid)
{
	new label[256];
	if(strcmp(BusinessData[businessid][Owner], "-")) {
        if(BusinessData[businessid][SalePrice] > 0) {
            format(label, sizeof(label), "{2ECC71}%s's Business For Sale (ID: %d)\n\n{FFFFFF}%s\n{FFFFFF}Interior: {3498DB}%s\n{2ECC71}$%s\n{FFFFFF}Earns {2ECC71}$%s {FFFFFF}every {2ECC71}%d {FFFFFF}minutes.", BusinessData[businessid][Owner], businessid, BusinessData[businessid][Name], BusinessInteriors[ BusinessData[businessid][Type] ][InteriorName], convertNumber(BusinessData[businessid][SalePrice]), convertNumber(BusinessData[businessid][Earning]), BUSINESS_INTERVAL);
		}else{
		    format(label, sizeof(label), "{E67E22}%s's Business (ID: %d)\n\n{FFFFFF}%s\n{FFFFFF}Interior: {3498DB}%s\n%s", BusinessData[businessid][Owner], businessid, BusinessData[businessid][Name], BusinessInteriors[ BusinessData[businessid][Type] ][InteriorName], BusinessStates[ BusinessData[businessid][Closed] ]);
		}
	}else{
 		format(label, sizeof(label), "{2ECC71}Business For Sale (ID: %d)\n\n{FFFFFF}Interior: {3498DB}%s\n{2ECC71}$%s\n{FFFFFF}Earns {2ECC71}$%s {FFFFFF}every {2ECC71}%d {FFFFFF}minutes.", businessid, BusinessInteriors[ BusinessData[businessid][Type] ][InteriorName], convertNumber(BusinessData[businessid][Price]), convertNumber(BusinessData[businessid][Earning]), BUSINESS_INTERVAL);
    }

	UpdateDynamic3DTextLabelText(BusinessData[businessid][BusinessLabel], -1, label);
	return 1;
}

Business_GetOwnerID(businessid)
{
	foreach(new i : Player)
	{
		if(!strcmp(BusinessData[businessid][Owner], Player_GetName(i), true)) return i;
	}

	return INVALID_PLAYER_ID;
}

Business_KickEveryone(businessid)
{
	foreach(new i : Player)
	{
	    if(InBusiness[i] == businessid) Player_KickFromBusiness(i);
	}

	return 1;
}

Business_RemoveSafeLogs(businessid)
{
	new query[128];
	mysql_format(BusinessSQL, query, sizeof(query), "DELETE FROM business_safelogs WHERE BusinessID=%d", businessid);
	mysql_tquery(BusinessSQL, query, "", "");
	return 1;
}

Business_RemovePerms(businessid)
{
	new query[128];
	mysql_format(BusinessSQL, query, sizeof(query), "DELETE FROM business_perms WHERE BusinessID=%d", businessid);
	mysql_tquery(BusinessSQL, query, "", "");
	return 1;
}

Business_Reset(businessid)
{
	format(BusinessData[businessid][Name], MAX_BUSINESS_NAME, "Business");
	format(BusinessData[businessid][Owner], MAX_PLAYER_NAME, "-");
	BusinessData[businessid][Closed] = 0;
	BusinessData[businessid][SalePrice] = 0;
    BusinessData[businessid][Money] = 0;
	BusinessData[businessid][LastVisited] = 0;

	Business_KickEveryone(businessid);
    Business_RemoveSafeLogs(businessid);
	Business_RemovePerms(businessid);
	Business_UpdateLabel(businessid);
	Business_Save(businessid);
	return 1;
}

Player_GetName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}

Player_OwnsBusiness(playerid, businessid)
{
	if(!IsPlayerConnected(playerid)) return 0;
	if(!strcmp(BusinessData[businessid][Owner], Player_GetName(playerid), true)) return 1;
	return 0;
}

Player_BusinessCount(playerid)
{
	#if LIMIT_PER_PLAYER != 0
    new count;
	foreach(new i : Business)
	{
		if(Player_OwnsBusiness(playerid, i)) count++;
	}

	return count;
	#else
	return 0;
	#endif
}

Player_CheckAnyPermission(playerid, businessid)
{
	new query[144], Cache: perm_check;
	mysql_format(BusinessSQL, query, sizeof(query), "SELECT null FROM business_perms WHERE Name='%e' && BusinessID=%d LIMIT 1", Player_GetName(playerid), businessid);
	perm_check = mysql_query(BusinessSQL, query);
	new result = cache_num_rows();
	cache_delete(perm_check);
	return result;
}

Player_CheckPermission(playerid, businessid, permid)
{
    if(Player_OwnsBusiness(playerid, businessid)) return 1;
	new query[144], PermsList[3][32] = {"Can_Deposit=1 || Can_Take=1", "Can_Deposit=1", "Can_Take=1"}, Cache: perm_check;
	mysql_format(BusinessSQL, query, sizeof(query), "SELECT null FROM business_perms WHERE Name='%e' && BusinessID=%d && %e LIMIT 1", Player_GetName(playerid), businessid, PermsList[permid]);
	perm_check = mysql_query(BusinessSQL, query);
	new result = cache_num_rows();
	cache_delete(perm_check);
	return result;
}

Player_GoToBusiness(playerid, businessid)
{
    SetPVarInt(playerid, "BusinessPickup", gettime() + 8);
    InBusiness[playerid] = businessid;
	SetPlayerVirtualWorld(playerid, businessid);
	new type = BusinessData[businessid][Type];
 	SetPlayerInterior(playerid, BusinessInteriors[type][InteriorID]);
  	SetPlayerPos(playerid, BusinessInteriors[type][InteriorX], BusinessInteriors[type][InteriorY], BusinessInteriors[type][InteriorZ]);

	if(Player_OwnsBusiness(playerid, businessid))
	{
		BusinessData[businessid][LastVisited] = gettime();
		BusinessData[businessid][Save] = true;
	}

    SendClientMessage(playerid, -1, "Use {3498DB}/business {FFFFFF}to open the business menu.");
	return 1;
}

Player_ShowBusinessMenu(playerid)
{
	new id = InBusiness[playerid], is_owned = Player_OwnsBusiness(playerid, id), string[256];
	format(string, sizeof(string), "{%s}Business Name\t%s\n{%s}Status\t%s\n{%s}Permissions\n{%s}Business Safe\n{%s}Sell Business",
	(is_owned) ? ("FFFFFF") : ("E74C3C"), BusinessData[id][Name], // Business Name
	(is_owned) ? ("FFFFFF") : ("E74C3C"), BusinessStates[ BusinessData[id][Closed] ], // Business State
	(is_owned) ? ("FFFFFF") : ("E74C3C"), // Permissions
	(Player_CheckPermission(playerid, id, PERM_CAN_USE_SAFE)) ? ("FFFFFF") : ("E74C3C"), // Business Safe
	(is_owned) ? ("FFFFFF") : ("E74C3C")); // Sell Business
	ShowPlayerDialog(playerid, DIALOG_MANAGE_BUSINESS, DIALOG_STYLE_TABLIST, "Business Management", string, "Choose", "Cancel");
	return 1;
}

Player_ShowBusinessSafe(playerid)
{
	new id = InBusiness[playerid], is_owned = Player_OwnsBusiness(playerid, id), string[196];
    format(string, sizeof(string), "{%s}Deposit Money\t{2ECC71}$%s\n{%s}Take Money\t{2ECC71}$%s\n{%s}Safe Logs\n{%s}Clear Safe Logs",
	(Player_CheckPermission(playerid, id, PERM_CAN_DEPOSIT)) ? ("FFFFFF") : ("E74C3C"), convertNumber(GetPlayerMoney(playerid)), // Deposit Money
	(Player_CheckPermission(playerid, id, PERM_CAN_TAKE)) ? ("FFFFFF") : ("E74C3C"), convertNumber(BusinessData[id][Money]), // Take Money
	(is_owned) ? ("FFFFFF") : ("E74C3C"), // Safe Logs
	(is_owned) ? ("FFFFFF") : ("E74C3C")); // Clear Safe Logs
	ShowPlayerDialog(playerid, DIALOG_MANAGE_BUSINESS_SAFE, DIALOG_STYLE_TABLIST, "Business Management: Safe", string, "Choose", "Cancel");
	return 1;
}

Player_ShowBusinessSale(playerid)
{
	new id = InBusiness[playerid], string[128];
    format(string, sizeof(string), "Sell Instantly\t{2ECC71}$%s\n%s", convertNumber(floatround(BusinessData[id][Price] * 0.85)), (BusinessData[id][SalePrice] > 0) ? ("Remove From Sale") : ("Put On Sale"));
	ShowPlayerDialog(playerid, DIALOG_MANAGE_SELL, DIALOG_STYLE_TABLIST, "Business Management: Sell", string, "Choose", "Cancel");
	return 1;
}

Player_ShowPermissionMenu(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_MANAGE_PERMISSIONS, DIALOG_STYLE_LIST, "Business Management: Permissions", "Give Permissions\nPlayers With Permissions\nRemove All Permissions", "Choose", "Cancel");
	return 1;
}

Player_KickFromBusiness(playerid)
{
	new id = InBusiness[playerid];
    SetPVarInt(playerid, "BusinessCooldown", gettime() + 8);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    SetPlayerPos(playerid, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ]);
    InBusiness[playerid] = INVALID_BUSINESS;
    return 1;
}

Player_GetID(name[])
{
	foreach(new i : Player)
	{
	    if(!strcmp(Player_GetName(i), name, true)) return i;
	}

	return INVALID_PLAYER_ID;
}

Player_ShowPermissionEditing(playerid)
{
    new permid = GetPVarInt(playerid, "EditingPerm"), query[128], Cache: perm_data;
    mysql_format(BusinessSQL, query, sizeof(query), "SELECT Name, Can_Deposit, Can_Take FROM business_perms WHERE ID=%d LIMIT 1", permid);
	perm_data = mysql_query(BusinessSQL, query);
	if(cache_num_rows() > 0) {
	    new string[128], name[MAX_PLAYER_NAME], depo, take;
		cache_get_value_name(0, "Name", name, MAX_PLAYER_NAME);
		cache_get_value_name_int(0, "Can_Deposit", depo);
		cache_get_value_name_int(0, "Can_Take", take);
	    format(string, sizeof(string), "Permission Owner:\t%s\nCan Deposit Money:\t%s\nCan Take Money:\t%s\nRemove", name, PermissionStates[depo], PermissionStates[take]);
		ShowPlayerDialog(playerid, DIALOG_MANAGE_EDIT_PERMS, DIALOG_STYLE_TABLIST, "Business Management: Edit Permissions", string, "Choose", "Cancel");
	}else{
		SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid permission.");
	}

	cache_delete(perm_data);
	return 1;
}

Player_ResetPermissionSettings(playerid, msg = 0)
{
	DeletePVar(playerid, "Perm_GivingTo");
	DeletePVar(playerid, "Perm_Deposit");
	if(msg) SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't give permissions to offline players.");
	return 1;
}

Player_ShowSafeLogs(playerid)
{
    new query[256], Cache: safe_logs;
	mysql_format(BusinessSQL, query, sizeof(query), "SELECT Name, Amount, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i:%%s') as ActionDate FROM business_safelogs WHERE BusinessID=%d ORDER BY Date DESC LIMIT %d, 15", InBusiness[playerid], ListPage[playerid] * 1);
	safe_logs = mysql_query(BusinessSQL, query);
	new rows = cache_num_rows();
	if(rows) {
		new list[1096], name[MAX_PLAYER_NAME], date[24], amount;
    	format(list, sizeof(list), "By\tAmount\tDate\n");
	    for(new i; i < rows; ++i)
	    {
	        cache_get_value_name(i, "Name", name, MAX_PLAYER_NAME);
        	cache_get_value_name(i, "ActionDate", date, 24);
			cache_get_value_name_int(i, "Amount", amount);
	        format(list, sizeof(list), "%s%s\t{%s}$%s\t%s\n", list, name, (amount < 0) ? ("E74C3C") : ("2ECC71"), convertNumber(amount), date);
	    }

        new title[48];
		format(title, sizeof(title), "Business Management: Safe Log (Page %d)", ListPage[playerid]+1);
		ShowPlayerDialog(playerid, DIALOG_MANAGE_SAFE_LOGS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
	}else{
		SendClientMessage(playerid, -1, "Can't find any more safe history.");
	}

	cache_delete(safe_logs);
	return 1;
}

forward BusinessTimer();
forward LoadBusinesses();
forward OnBusinessCreated(businessid);
forward BusinessSaleMoney(playerid);
forward OnPermChange(playerid);
forward OnPermRemoved(playerid);

public BusinessTimer()
{
	foreach(new i : Business)
	{
	    if((gettime() - BusinessData[i][LastVisited]) > BUSINESS_DAYS * 86400)
	    {
			Business_Reset(i);
	        continue;
	    }

	    if(!BusinessData[i][Closed] && BusinessData[i][SalePrice] == 0 && strcmp(BusinessData[i][Owner], "-"))
	    {
		    BusinessData[i][Money] += BusinessData[i][Earning];
	     	BusinessData[i][Save] = true;
		}

     	if(BusinessData[i][Save]) Business_Save(i);
	}

	return 1;
}

public LoadBusinesses()
{
    new rows = cache_num_rows();
 	if(rows)
  	{
   		new id, label[256];
		for(new i; i < rows; i++)
		{
			cache_get_value_name_int(i, "ID", id);
	    	cache_get_value_name(i, "Name", BusinessData[id][Name], MAX_BUSINESS_NAME);
		    cache_get_value_name(i, "Owner", BusinessData[id][Owner], MAX_PLAYER_NAME);
			cache_get_value_name_float(i, "BusinessX", BusinessData[id][BusinessX]);
			cache_get_value_name_float(i, "BusinessY", BusinessData[id][BusinessY]);
			cache_get_value_name_float(i, "BusinessZ", BusinessData[id][BusinessZ]);
			cache_get_value_name_int(i, "Closed", BusinessData[id][Closed]);
			cache_get_value_name_int(i, "Price", BusinessData[id][Price]);
			cache_get_value_name_int(i, "SalePrice", BusinessData[id][SalePrice]);
			cache_get_value_name_int(i, "Earning", BusinessData[id][Earning]);
			cache_get_value_name_int(i, "Money", BusinessData[id][Money]);
			cache_get_value_name_int(i, "Type", BusinessData[id][Type]);
			cache_get_value_name_int(i, "LastVisited", BusinessData[id][LastVisited]);

	        if(strcmp(BusinessData[id][Owner], "-")) {
				if(BusinessData[id][SalePrice] > 0) {
					format(label, sizeof(label), "{2ECC71}%s's Business For Sale (ID: %d)\n\n{FFFFFF}%s\n{FFFFFF}Interior: {3498DB}%s\n{2ECC71}$%s\n{FFFFFF}Earns {2ECC71}$%s {FFFFFF}every {2ECC71}%d {FFFFFF}minutes.", BusinessData[id][Owner], id, BusinessData[id][Name], BusinessInteriors[ BusinessData[id][Type] ][InteriorName], convertNumber(BusinessData[id][SalePrice]), convertNumber(BusinessData[id][Earning]), BUSINESS_INTERVAL);
				}else{
					format(label, sizeof(label), "{E67E22}%s's Business (ID: %d)\n\n{FFFFFF}%s\n{FFFFFF}Interior: {3498DB}%s\n%s", BusinessData[id][Owner], id, BusinessData[id][Name], BusinessInteriors[ BusinessData[id][Type] ][InteriorName], BusinessStates[ BusinessData[id][Closed] ]);
				}
			}else{
				format(label, sizeof(label), "{2ECC71}Business For Sale (ID: %d)\n\n{FFFFFF}Interior: {3498DB}%s\n{2ECC71}$%s\n{FFFFFF}Earns {2ECC71}$%s {FFFFFF}every {2ECC71}%d {FFFFFF}minutes.", id, BusinessInteriors[ BusinessData[id][Type] ][InteriorName], convertNumber(BusinessData[id][Price]), convertNumber(BusinessData[id][Earning]), BUSINESS_INTERVAL);
			}

			BusinessData[id][BusinessPickup] = CreateDynamicPickup(1272, 1, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ]);
			BusinessData[id][BusinessLabel] = CreateDynamic3DTextLabel(label, -1, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ]+0.35, 15.0, .testlos = 1);
			Iter_Add(Business, id);
	    }

	    printf("  [Business System] Loaded %d businesses.", rows);
	}
}

public OnBusinessCreated(businessid)
{
	Business_Save(businessid);
	return 1;
}

public BusinessSaleMoney(playerid)
{
    new rows = cache_num_rows();
 	if(rows)
  	{
   		new new_owner[MAX_PLAYER_NAME], amount, string[128], idd;
		for(new i; i < rows; i++)
		{
	    	cache_get_value_name(i, "NewOwner", new_owner, MAX_PLAYER_NAME);
			cache_get_value_name_int(i, "Amount", amount);
            cache_get_value_name_int(i, "ID", idd);
			format(string, sizeof(string), "You sold a business to %s for $%s. (Transaction ID: #%d)", new_owner, convertNumber(amount), idd);
			SendClientMessage(playerid, -1, string);
			GivePlayerMoney(playerid, amount);
	    }

		new query[128];
	    mysql_format(BusinessSQL, query, sizeof(query), "DELETE FROM business_transactions WHERE OldOwner='%e'", Player_GetName(playerid));
	    mysql_tquery(BusinessSQL, query, "", "");
	}

	return 1;
}

public OnPermChange(playerid)
{
    Player_ShowPermissionEditing(playerid);
	return 1;
}

public OnPermRemoved(playerid)
{
	SendClientMessage(playerid, -1, "Permission removed.");
    Player_ShowPermissionMenu(playerid);
	return 1;
}

public OnFilterScriptInit()
{
	DisableInteriorEnterExits();

	BusinessSQL = mysql_connect(SQL_HOST, SQL_USER, SQL_PASSWORD, SQL_DBNAME);
	mysql_log(ALL);
	if(mysql_errno()) return printf("  [Business System] Can't connect to MySQL. (Error #%d)", mysql_errno());

	// create tables if they don't exist
	new query[1024];
	format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `business` (\
	  `ID` int(11) NOT NULL default '0',\
	  `Name` varchar(%d) default NULL,\
	  `Owner` varchar(24) default '-',\
	  `BusinessX` float default NULL,\
	  `BusinessY` float default NULL,\
	  `BusinessZ` float default NULL,\
	  `Closed` tinyint(1) default NULL,\
	  `Price` int(11) default NULL,\
	  `SalePrice` int(11) default NULL,\
      `Earning` int(11) default NULL,", MAX_BUSINESS_NAME);

	format(query, sizeof(query), "%s\
	  `Money` int(11) default NULL,\
	  `Type` int(11) default NULL,\
	  `LastVisited` int(11) default NULL,\
	  PRIMARY KEY  (`ID`),\
	  UNIQUE KEY `ID` (`ID`)\
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;", query);

	mysql_tquery(BusinessSQL, query, "", "");

	mysql_tquery(BusinessSQL, "CREATE TABLE IF NOT EXISTS `business_perms` (\
	  `ID` int(11) NOT NULL auto_increment,\
	  `Name` varchar(24) default NULL,\
	  `BusinessID` int(11) default NULL,\
	  `Can_Deposit` tinyint(1) default NULL,\
	  `Can_Take` tinyint(1) default NULL,\
	  PRIMARY KEY  (`ID`),\
	  KEY `BusinessID` (`BusinessID`),\
	  CONSTRAINT `business_perms_ibfk_1` FOREIGN KEY (`BusinessID`) REFERENCES `business` (`ID`) ON DELETE CASCADE\
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;", "", "");

	mysql_tquery(BusinessSQL, "CREATE TABLE IF NOT EXISTS `business_safelogs` (\
	  `ID` int(11) NOT NULL auto_increment,\
	  `Name` varchar(24) default NULL,\
	  `BusinessID` int(11) default NULL,\
	  `Amount` int(11) default NULL,\
	  `Date` int(11) default NULL,\
	  PRIMARY KEY  (`ID`),\
	  KEY `BusinessID` (`BusinessID`),\
	  CONSTRAINT `business_safelogs_ibfk_1` FOREIGN KEY (`BusinessID`) REFERENCES `business` (`ID`) ON DELETE CASCADE\
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;", "", "");

	mysql_tquery(BusinessSQL, "CREATE TABLE IF NOT EXISTS `business_transactions` (\
	  `ID` int(11) NOT NULL auto_increment,\
	  `OldOwner` varchar(24) default NULL,\
	  `NewOwner` varchar(24) default NULL,\
	  `Amount` int(11) default NULL,\
	  PRIMARY KEY  (`ID`)\
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;", "", "");

	for(new i; i < MAX_BUSINESS; ++i)
	{
	    format(BusinessData[i][Name], MAX_PLAYER_NAME, "Business");
	    format(BusinessData[i][Owner], MAX_PLAYER_NAME, "-");
		BusinessData[i][BusinessLabel] = Text3D: INVALID_3DTEXT_ID;
		BusinessData[i][BusinessPickup] = -1;
	}

	for(new i; i < sizeof(BusinessInteriors); i++)
	{
		BusinessInteriors[i][ExitPickup] = CreateDynamicPickup(19197, 1, BusinessInteriors[i][InteriorX], BusinessInteriors[i][InteriorY], BusinessInteriors[i][InteriorZ] + 0.25, .interiorid = BusinessInteriors[i][InteriorID]);
    	BusinessInteriors[i][ExitLabel] = CreateDynamic3DTextLabel("Leave Business", 0xE67E22FF, BusinessInteriors[i][InteriorX], BusinessInteriors[i][InteriorY], BusinessInteriors[i][InteriorZ] + 0.45, 10.0, .testlos = 1, .interiorid = BusinessInteriors[i][InteriorID]);
    }

	mysql_tquery(BusinessSQL, "SELECT * FROM business", "LoadBusinesses", "");
	SetTimer("BusinessTimer", BUSINESS_INTERVAL * 60000, true);
	return 1;
}

public OnFilterScriptExit()
{
	foreach(new i : Business)
	{
	    if(BusinessData[i][Save]) Business_Save(i);
	}

	mysql_close(BusinessSQL);
	return 1;
}

public OnPlayerConnect(playerid)
{
	InBusiness[playerid] = INVALID_BUSINESS;
	ListPage[playerid] = 0;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	InBusiness[playerid] = INVALID_BUSINESS;

	new query[128];
	mysql_format(BusinessSQL, query, sizeof(query), "SELECT * FROM business_transactions WHERE OldOwner='%e'", Player_GetName(playerid));
	mysql_tquery(BusinessSQL, query, "BusinessSaleMoney", "i", playerid);
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	if(GetPVarInt(playerid, "BusinessCooldown") < gettime())
	{
	    if(InBusiness[playerid] == INVALID_BUSINESS) {
		    foreach(new i : Business)
		    {
				if(pickupid == BusinessData[i][BusinessPickup])
				{
				    SetPVarInt(playerid, "BusinessCooldown", gettime() + 8);
			        SetPVarInt(playerid, "PickupBusinessID", i);
	                if(Player_OwnsBusiness(playerid, i)) return Player_GoToBusiness(playerid, i);

			        if(!strcmp(BusinessData[i][Owner], "-") || BusinessData[i][SalePrice] > 0) {
			            new string[128];
			            if(BusinessData[i][SalePrice] > 0) {
			                format(string, sizeof(string), "This business is for sale. You can buy it if the owner is online.\nPrice: {2ECC71}$%s", convertNumber(BusinessData[i][SalePrice]));
							ShowPlayerDialog(playerid, DIALOG_BUY_BUSINESS_FROM_OWNER, DIALOG_STYLE_MSGBOX, "Business For Sale", string, "Buy", "Cancel");
						}else{
			                format(string, sizeof(string), "This business is for sale.\nPrice: {2ECC71}$%s", convertNumber(BusinessData[i][Price]));
							ShowPlayerDialog(playerid, DIALOG_BUY_BUSINESS, DIALOG_STYLE_MSGBOX, "Business For Sale", string, "Buy", "Cancel");
			            }
			        }else{
				        if(!BusinessData[i][Closed]) {
				            Player_GoToBusiness(playerid, i);
						}else{
						    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't enter this business right now.");
						}
			        }

			        return 1;
				}
		    }
	    }else{
	        for(new i; i < sizeof(BusinessInteriors); i++)
	        {
		        if(pickupid == BusinessInteriors[i][ExitPickup])
		        {
		            Player_KickFromBusiness(playerid);
			        return 1;
		        }
	        }
	    }
	}

	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case DIALOG_BUY_BUSINESS:
	    {
	        if(!response) return 1;
			new id = GetPVarInt(playerid, "PickupBusinessID");
			if(!IsPlayerInRangeOfPoint(playerid, 2.0, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near a business.");
			if(BusinessData[id][Price] > GetPlayerMoney(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't afford this business.");
			#if LIMIT_PER_PLAYER > 0
			if(Player_BusinessCount(playerid) + 1 > LIMIT_PER_PLAYER) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't buy any more businesses.");
			#endif
			if(strcmp(BusinessData[id][Owner], "-")) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Someone already owns this business.");
			GivePlayerMoney(playerid, -BusinessData[id][Price]);
			GetPlayerName(playerid, BusinessData[id][Owner], MAX_PLAYER_NAME);
			BusinessData[id][LastVisited] = gettime();
			BusinessData[id][Save] = true;

			Business_UpdateLabel(id);
			Business_RemoveSafeLogs(id);
			Business_RemovePerms(id);
			Player_GoToBusiness(playerid, id);
			return 1;
		}

		case DIALOG_BUY_BUSINESS_FROM_OWNER:
	    {
	        if(!response) return 1;
			new id = GetPVarInt(playerid, "PickupBusinessID");
			if(!IsPlayerInRangeOfPoint(playerid, 2.0, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near a business.");
			if(BusinessData[id][SalePrice] > GetPlayerMoney(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't afford this business.");
			#if LIMIT_PER_PLAYER > 0
			if(Player_BusinessCount(playerid) + 1 > LIMIT_PER_PLAYER) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't buy any more businesses.");
			#endif
            if(!strcmp(BusinessData[id][Owner], "-")) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}This business doesn't have an owner.");
   			new ownerid = Business_GetOwnerID(id);

			if(IsPlayerConnected(ownerid)) {
   				GivePlayerMoney(ownerid, BusinessData[id][SalePrice]);

				new string[128];
   				format(string, sizeof(string), "%s(%d) has bought your business for $%s.", Player_GetName(playerid), playerid, convertNumber(BusinessData[id][SalePrice]));
				SendClientMessage(ownerid, -1, string);
			}else{
			    new query[128];
			    mysql_format(BusinessSQL, query, sizeof(query), "INSERT INTO business_transactions SET OldOwner='%e', NewOwner='%e', Amount=%d", BusinessData[id][Owner], Player_GetName(playerid), BusinessData[id][SalePrice]);
			    mysql_tquery(BusinessSQL, query, "", "");
			}

			GivePlayerMoney(playerid, -BusinessData[id][SalePrice]);
            GetPlayerName(playerid, BusinessData[id][Owner], MAX_PLAYER_NAME);
			BusinessData[id][LastVisited] = gettime();
			BusinessData[id][SalePrice] = 0;
			BusinessData[id][Closed] = 0;
			BusinessData[id][Save] = true;

            Business_UpdateLabel(id);
			Business_RemoveSafeLogs(id);
            Business_RemovePerms(id);
			Player_GoToBusiness(playerid, id);
			return 1;
		}

		case DIALOG_MANAGE_BUSINESS:
		{
		    if(!response) return 1;
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    new string[128], id = InBusiness[playerid];
		    if(listitem == 0)
		    {
		        // Business Name
		        if(!Player_OwnsBusiness(playerid, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		        format(string, sizeof(string), "Current Business Name: %s\n\n{FFFFFF}Write your new business name:", BusinessData[ InBusiness[playerid] ][Name]);
		        ShowPlayerDialog(playerid, DIALOG_MANAGE_BUSINESS_NAME, DIALOG_STYLE_INPUT, "Business Management: Name", string, "Change", "Cancel");
		    }

		    if(listitem == 1)
		    {
		        // Business Status
		        if(!Player_OwnsBusiness(playerid, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		        BusinessData[id][Closed] = !BusinessData[id][Closed];
				BusinessData[id][Save] = true;
		        Business_UpdateLabel(id);
		        Player_ShowBusinessMenu(playerid);
		    }

		    if(listitem == 2)
			{
                if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
				Player_ShowPermissionMenu(playerid);
			}

		    if(listitem == 3)
			{
			    if(BusinessData[id][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't use the safe while the business is on sale.");
			    if(!Player_CheckPermission(playerid, id, PERM_CAN_USE_SAFE)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't have enough permissions.");
				Player_ShowBusinessSafe(playerid);
			}

			if(listitem == 4)
			{
			    if(!Player_OwnsBusiness(playerid, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
				Player_ShowBusinessSale(playerid);
			}

		    return 1;
		}

		case DIALOG_MANAGE_BUSINESS_NAME:
		{
		    if(!response) return Player_ShowBusinessMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		    if(!(1 <= strlen(inputtext) <= MAX_BUSINESS_NAME)) return ShowPlayerDialog(playerid, DIALOG_MANAGE_BUSINESS_NAME, DIALOG_STYLE_INPUT, "Business Management: Name", "{E74C3C}ERROR: {FFFFFF}The business name you entered is either too short or too long.", "Change", "Cancel");
			new id = InBusiness[playerid];
			format(BusinessData[id][Name], MAX_BUSINESS_NAME, "%s", inputtext);
        	BusinessData[id][Save] = true;

        	Business_UpdateLabel(id);
			Player_ShowBusinessMenu(playerid);
		    return 1;
		}

        case DIALOG_MANAGE_BUSINESS_SAFE:
		{
		    if(!response) return Player_ShowBusinessMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(BusinessData[ InBusiness[playerid] ][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't use the safe while the business is on sale.");
		    if(!Player_CheckPermission(playerid, InBusiness[playerid], PERM_CAN_USE_SAFE)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't have enough permissions.");
		    new string[128], id = InBusiness[playerid];
			if(listitem == 0)
			{
			    if(!Player_CheckPermission(playerid, InBusiness[playerid], PERM_CAN_DEPOSIT)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't deposit money to this business.");
				format(string, sizeof(string), "Your Money: {2ECC71}$%s\n\n{FFFFFF}Write the amount you want to deposit:", convertNumber(GetPlayerMoney(playerid)));
				ShowPlayerDialog(playerid, DIALOG_MANAGE_DEPOSIT_TO_SAFE, DIALOG_STYLE_INPUT, "Business Safe: Deposit", string, "Deposit", "Cancel");
			}

			if(listitem == 1)
			{
			    if(!Player_CheckPermission(playerid, InBusiness[playerid], PERM_CAN_TAKE)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't take money from this business.");
			    format(string, sizeof(string), "Business's Money: {2ECC71}$%s\n\n{FFFFFF}Write the amount you want to take:", convertNumber(BusinessData[id][Money]));
				ShowPlayerDialog(playerid, DIALOG_MANAGE_TAKE_FROM_SAFE, DIALOG_STYLE_INPUT, "Business Safe: Take", string, "Take", "Cancel");
			}

			if(listitem == 2)
			{
			    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
			    ListPage[playerid] = 0;
				Player_ShowSafeLogs(playerid);
			}

			if(listitem == 3)
			{
			    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
				Business_RemoveSafeLogs(id);
				Player_ShowBusinessSafe(playerid);
			}

		    return 1;
		}

		case DIALOG_MANAGE_DEPOSIT_TO_SAFE:
		{
      		if(!response) return Player_ShowBusinessSafe(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(BusinessData[ InBusiness[playerid] ][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't use the safe while the business is on sale.");
		    if(!Player_CheckPermission(playerid, InBusiness[playerid], PERM_CAN_DEPOSIT)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't deposit money to this business.");
      		if(!(1 <= strval(inputtext) <= 100000000)) return ShowPlayerDialog(playerid, DIALOG_MANAGE_DEPOSIT_TO_SAFE, DIALOG_STYLE_INPUT, "Business Safe: Deposit", "{E74C3C}ERROR: {FFFFFF}You can't deposit less than $1 or more than $100.000.000 at once.", "Deposit", "Cancel");
			if(strval(inputtext) > GetPlayerMoney(playerid)) return ShowPlayerDialog(playerid, DIALOG_MANAGE_DEPOSIT_TO_SAFE, DIALOG_STYLE_INPUT, "Business Safe: Deposit", "{E74C3C}ERROR: {FFFFFF}You don't have that much money on you.", "Deposit", "Cancel");
			new id = InBusiness[playerid], amount = strval(inputtext);
			GivePlayerMoney(playerid, -amount);
			BusinessData[id][Money] += amount;
        	BusinessData[id][Save] = true;

            new query[144];
			mysql_format(BusinessSQL, query, sizeof(query), "INSERT INTO business_safelogs SET Name='%e', BusinessID=%d, Amount='%d', Date=UNIX_TIMESTAMP()", Player_GetName(playerid), id, amount);
			mysql_tquery(BusinessSQL, query, "", "");
			Player_ShowBusinessSafe(playerid);
		    return 1;
		}

		case DIALOG_MANAGE_TAKE_FROM_SAFE:
		{
      		if(!response) return Player_ShowBusinessSafe(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(BusinessData[ InBusiness[playerid] ][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't use the safe while the business is on sale.");
		    if(!Player_CheckPermission(playerid, InBusiness[playerid], PERM_CAN_TAKE)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't take money from this business.");
      		if(!(1 <= strval(inputtext) <= 100000000)) return ShowPlayerDialog(playerid, DIALOG_MANAGE_TAKE_FROM_SAFE, DIALOG_STYLE_INPUT, "Business Safe: Take", "{E74C3C}ERROR: {FFFFFF}You can't take less than $1 or more than $100.000.000 at once.", "Take", "Cancel");
			if(strval(inputtext) > BusinessData[ InBusiness[playerid] ][Money]) return ShowPlayerDialog(playerid, DIALOG_MANAGE_TAKE_FROM_SAFE, DIALOG_STYLE_INPUT, "Business Safe: Take", "{E74C3C}ERROR: {FFFFFF}This business don't have that much money.", "Take", "Cancel");
			new id = InBusiness[playerid], amount = strval(inputtext);
			GivePlayerMoney(playerid, amount);
			BusinessData[id][Money] -= amount;
        	BusinessData[id][Save] = true;

			new query[144];
			mysql_format(BusinessSQL, query, sizeof(query), "INSERT INTO business_safelogs SET Name='%e', BusinessID=%d, Amount='%d', Date=UNIX_TIMESTAMP()", Player_GetName(playerid), id, -amount);
			mysql_tquery(BusinessSQL, query, "", "");
			Player_ShowBusinessSafe(playerid);
		    return 1;
		}

		case DIALOG_MANAGE_SELL:
		{
			if(!response) return Player_ShowBusinessMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		    new id = InBusiness[playerid];
			if(listitem == 0)
			{
			    new price = floatround(BusinessData[id][Price] * 0.85), string[128];
			    format(string, sizeof(string), "You sold your business for $%s. You also got the $%s in the safe.", convertNumber(price), convertNumber(BusinessData[id][Money]));
			    SendClientMessage(playerid, -1, string);

			    GivePlayerMoney(playerid, price + BusinessData[id][Money]);
			    Business_Reset(id);
			}

			if(listitem == 1)
			{
				if(BusinessData[id][SalePrice] > 0) {
				    BusinessData[id][SalePrice] = 0;
				    BusinessData[id][Save] = true;

				    Business_UpdateLabel(id);
				    SendClientMessage(playerid, -1, "Your business is no longer for sale.");
				}else{
					if(BusinessData[id][Money] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't put your business on sale if there's money in the business safe.");
					ShowPlayerDialog(playerid, DIALOG_MANAGE_SELL_TO_PLAYERS, DIALOG_STYLE_INPUT, "Business Management: Sell", "How much do you want for your business?", "Put On Sale", "Cancel");
				}
			}

			return 1;
		}

		case DIALOG_MANAGE_SELL_TO_PLAYERS:
		{
      		if(!response) return Player_ShowBusinessSale(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		    if(!(1 <= strval(inputtext) <= 100000000)) return ShowPlayerDialog(playerid, DIALOG_MANAGE_SELL_TO_PLAYERS, DIALOG_STYLE_INPUT, "Business Management: Sell", "{E74C3C}ERROR: {FFFFFF}You can't put your business on sale for less than $1 or more than $100.000.000.", "Put On Sale", "Cancel");
			new id = InBusiness[playerid], string[128];
			BusinessData[id][SalePrice] = strval(inputtext);
        	BusinessData[id][Save] = true;

			Business_UpdateLabel(id);
			format(string, sizeof(string), "You put your business on sale for $%s.", convertNumber(strval(inputtext)));
			SendClientMessage(playerid, -1, string);
		    return 1;
		}

		case DIALOG_MANAGE_PERMISSIONS:
		{
			if(!response) return Player_ShowBusinessMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
			new id = InBusiness[playerid];
			if(listitem == 0) ShowPlayerDialog(playerid, DIALOG_MANAGE_GIVE_PERM_NAME, DIALOG_STYLE_INPUT, "Business Management: Give Permission", "Write the player's name:", "Continue", "Cancel");
			if(listitem == 1)
			{
			    new string[1256], query[128], name[MAX_PLAYER_NAME], Cache: find_perms, depo, take, idd;
			    format(string, sizeof(string), "ID\tName\tCan Deposit\tCan Take\n");
				mysql_format(BusinessSQL, query, sizeof(query), "SELECT * FROM business_perms WHERE BusinessID=%d ORDER BY Name ASC", id);
				find_perms = mysql_query(BusinessSQL, query);
				new rows = cache_num_rows();
				if(rows > 0) {
					for(new i; i < rows; i++)
					{
					    cache_get_value_name(i, "Name", name, MAX_PLAYER_NAME);
					    cache_get_value_name_int(i, "Can_Deposit", depo);
					    cache_get_value_name_int(i, "Can_Take", take);
					    cache_get_value_name_int(i, "ID", idd);
						format(string, sizeof(string), "%s%d\t%s\t%s\t%s\n", string, idd, name, PermissionStates[depo], PermissionStates[take]);
					}

					ShowPlayerDialog(playerid, DIALOG_MANAGE_LIST_PERMS, DIALOG_STYLE_TABLIST_HEADERS, "Business Management: Permissions", string, "Edit", "Cancel");
				}else{
				    SendClientMessage(playerid, -1, "This business has no players with permissions.");
				}

				cache_delete(find_perms);
			}

			if(listitem == 2)
			{
			    Business_RemovePerms(id);
				SendClientMessage(playerid, -1, "All permissions removed.");
			}

			return 1;
		}

		case DIALOG_MANAGE_GIVE_PERM_NAME:
		{
      		if(!response) return Player_ShowPermissionMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		    if(!(1 <= strlen(inputtext) <= MAX_PLAYER_NAME)) return ShowPlayerDialog(playerid, DIALOG_MANAGE_GIVE_PERM_NAME, DIALOG_STYLE_INPUT, "Business Management: Give Permission", "{E74C3C}ERROR: {FFFFFF}The player name you entered is either too short or too long.", "Continue", "Cancel");
			new permid = Player_GetID(inputtext);
			if(!IsPlayerConnected(permid)) return ShowPlayerDialog(playerid, DIALOG_MANAGE_GIVE_PERM_NAME, DIALOG_STYLE_INPUT, "Business Management: Give Permission", "{E74C3C}ERROR: {FFFFFF}You can't give permissions to offline players.", "Continue", "Cancel");
			if(playerid == permid) return ShowPlayerDialog(playerid, DIALOG_MANAGE_GIVE_PERM_NAME, DIALOG_STYLE_INPUT, "Business Management: Give Permission", "{E74C3C}ERROR: {FFFFFF}You can't give permissions to yourself.", "Continue", "Cancel");
			if(Player_CheckAnyPermission(playerid, InBusiness[playerid])) return ShowPlayerDialog(playerid, DIALOG_MANAGE_GIVE_PERM_NAME, DIALOG_STYLE_INPUT, "Business Management: Give Permission", "{E74C3C}ERROR: {FFFFFF}This player already has permissions, please use the \"Players With Permissions\" menu.", "Continue", "Cancel");
			SetPVarString(playerid, "Perm_GivingTo", inputtext);
			ShowPlayerDialog(playerid, DIALOG_MANAGE_GIVE_PERM_DEPOSIT, DIALOG_STYLE_TABLIST_HEADERS, "Business Management: Give Permission", "Can this player deposit money in the business safe?\nNo\nYes", "Continue", "Cancel");
		    return 1;
		}

		case DIALOG_MANAGE_GIVE_PERM_DEPOSIT:
		{
      		if(!response) return Player_ShowPermissionMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
			new name[MAX_PLAYER_NAME];
			GetPVarString(playerid, "Perm_GivingTo", name, MAX_PLAYER_NAME);
			new permid = Player_GetID(name);
			if(!IsPlayerConnected(permid)) return Player_ResetPermissionSettings(playerid, 1);
			SetPVarInt(playerid, "Perm_Deposit", listitem);
			ShowPlayerDialog(playerid, DIALOG_MANAGE_GIVE_PERM_TAKE, DIALOG_STYLE_TABLIST_HEADERS, "Business Management: Give Permission", "Can this player take money from the business safe?\nNo\nYes", "Finish", "Cancel");
		    return 1;
		}

		case DIALOG_MANAGE_GIVE_PERM_TAKE:
		{
      		if(!response) return Player_ShowPermissionMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
			new name[MAX_PLAYER_NAME];
			GetPVarString(playerid, "Perm_GivingTo", name, MAX_PLAYER_NAME);
			new permid = Player_GetID(name);
			if(!IsPlayerConnected(permid)) return Player_ResetPermissionSettings(playerid, 1);
			new query[144];
			mysql_format(BusinessSQL, query, sizeof(query), "INSERT INTO business_perms SET Name='%e', BusinessID=%d, Can_Take=%d, Can_Deposit=%d", name, InBusiness[playerid], listitem, GetPVarInt(playerid, "Perm_Deposit"));
			mysql_tquery(BusinessSQL, query, "", "");

			format(query, sizeof(query), "Gave permissions to %s.", name);
			SendClientMessage(playerid, -1, query);
			format(query, sizeof(query), "%s can deposit money: %s.", name, PermissionStates[ GetPVarInt(playerid, "Perm_Deposit") ]);
			SendClientMessage(playerid, -1, query);
			format(query, sizeof(query), "%s can take money: %s.", name, PermissionStates[listitem]);
			SendClientMessage(playerid, -1, query);
			Player_ResetPermissionSettings(playerid);
			return 1;
		}

		case DIALOG_MANAGE_LIST_PERMS:
		{
		    if(!response) return Player_ShowPermissionMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		    new permid = strval(inputtext);
		    SetPVarInt(playerid, "EditingPerm", permid);
			Player_ShowPermissionEditing(playerid);
		    return 1;
		}

		case DIALOG_MANAGE_EDIT_PERMS:
		{
		    if(!response) return Player_ShowPermissionMenu(playerid);
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		    if(listitem == 0) Player_ShowPermissionEditing(playerid);
		    if(listitem == 1)
		    {
		        new query[128];
				mysql_format(BusinessSQL, query, sizeof(query), "UPDATE business_perms SET Can_Deposit = NOT Can_Deposit WHERE ID=%d", GetPVarInt(playerid, "EditingPerm"));
				mysql_tquery(BusinessSQL, query, "OnPermChange", "i", playerid);
		    }

		    if(listitem == 2)
		    {
		        new query[128];
				mysql_format(BusinessSQL, query, sizeof(query), "UPDATE business_perms SET Can_Take = NOT Can_Take WHERE ID=%d", GetPVarInt(playerid, "EditingPerm"));
				mysql_tquery(BusinessSQL, query, "OnPermChange", "i", playerid);
		    }

		    if(listitem == 3)
		    {
		        new query[64];
		        mysql_format(BusinessSQL, query, sizeof(query), "DELETE FROM business_perms WHERE ID=%d", GetPVarInt(playerid, "EditingPerm"));
				mysql_tquery(BusinessSQL, query, "OnPermRemoved", "i", playerid);
		    }

		    return 1;
		}

		case DIALOG_MANAGE_SAFE_LOGS:
		{
		    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
		    if(!Player_OwnsBusiness(playerid, InBusiness[playerid])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't own this business.");
		    if(!response) {
		        ListPage[playerid]--;
		        if(ListPage[playerid] < 0)
		        {
		            ListPage[playerid] = 0;
					Player_ShowBusinessSafe(playerid);
					return 1;
		        }
			}else{
			    ListPage[playerid]++;
			}

		    Player_ShowSafeLogs(playerid);
		    return 1;
		}

		case DIALOG_ADMIN_BUSINESS_TYPE:
		{
		    if(!response) return 1;
		    if(!IsPlayerAdmin(playerid)) return 1;
		    new id = GetPVarInt(playerid, "EditingBusinessType");
            BusinessData[id][Type] = listitem;
		    Business_UpdateLabel(id);
		    Business_Save(id);

		    new string[128];
		    format(string, sizeof(string), "Business's type set to %s.", BusinessInteriors[listitem][InteriorName]);
		    SendClientMessage(playerid, -1, string);
		    return 1;
		}
	}

	return 0;
}

CMD:business(playerid, params[])
{
    if(InBusiness[playerid] == INVALID_BUSINESS) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not in a business.");
	Player_ShowBusinessMenu(playerid);
	return 1;
}

CMD:createbusiness(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id = Iter_Free(Business);
	if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't create any more businesses.");
	new price, earning, type;
	if(sscanf(params, "iii", price, earning, type)) return SendClientMessage(playerid, 0xE88732FF, "USAGE: {FFFFFF}/createbusiness [price] [earning] [type]");
	if(!(0 <= type <= sizeof(BusinessInteriors)-1)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid business type.");
	SetPVarInt(playerid, "BusinessCooldown", gettime() + 8);
    format(BusinessData[id][Name], MAX_BUSINESS_NAME, "Business");
	format(BusinessData[id][Owner], MAX_PLAYER_NAME, "-");
	GetPlayerPos(playerid, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ]);
	BusinessData[id][Closed] = 0;
	BusinessData[id][Price] = price;
	BusinessData[id][SalePrice] = 0;
	BusinessData[id][Earning] = earning;
	BusinessData[id][Money] = 0;
	BusinessData[id][Type] = type;
	BusinessData[id][LastVisited] = 0;
	BusinessData[id][BusinessPickup] = CreateDynamicPickup(1272, 1, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ]);
	BusinessData[id][BusinessLabel] = CreateDynamic3DTextLabel("Business", -1, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ]+0.35, 15.0, .testlos = 1);
    Business_UpdateLabel(id);
	Iter_Add(Business, id);

	new query[128];
	mysql_format(BusinessSQL, query, sizeof(query), "INSERT INTO business SET ID=%d, BusinessX=%f, BusinessY=%f, BusinessZ=%f, Price=%d, Type=%d", id, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ], price, type);
	mysql_tquery(BusinessSQL, query, "OnBusinessCreated", "i", id);
	return 1;
}

CMD:gotobusiness(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "USAGE: {FFFFFF}/gotobusiness [business id]");
	if(!Iter_Contains(Business, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}The business you specified ID of doesn't exist.");
    SetPVarInt(playerid, "BusinessCooldown", gettime() + 8);
    SetPlayerPos(playerid, BusinessData[id][BusinessX], BusinessData[id][BusinessY], BusinessData[id][BusinessZ]);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    InBusiness[playerid] = INVALID_BUSINESS;
	return 1;
}

CMD:setbusinessprice(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id, price;
	if(sscanf(params, "ii", id, price)) return SendClientMessage(playerid, 0xE88732FF, "USAGE: {FFFFFF}/setbusinessprice [business id] [new price]");
	if(!Iter_Contains(Business, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}The business you specified ID of doesn't exist.");
    BusinessData[id][Price] = price;
    Business_UpdateLabel(id);
    Business_Save(id);

    new string[128];
    format(string, sizeof(string), "Business's price set to $%s.", convertNumber(price));
    SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setbusinessearning(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id, earning;
	if(sscanf(params, "ii", id, earning)) return SendClientMessage(playerid, 0xE88732FF, "USAGE: {FFFFFF}/setbusinessearning [business id] [new earning]");
	if(!Iter_Contains(Business, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}The business you specified ID of doesn't exist.");
    BusinessData[id][Earning] = earning;
    Business_UpdateLabel(id);
    Business_Save(id);

    new string[128];
    format(string, sizeof(string), "Business's earning set to $%s every %d minutes.", convertNumber(earning), BUSINESS_INTERVAL);
    SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setbusinesstype(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id, type = -1;
	if(sscanf(params, "iI(-1)", id, type)) return SendClientMessage(playerid, 0xE88732FF, "USAGE: {FFFFFF}/setbusinesstype [business id] [type (optional)]");
	if(!Iter_Contains(Business, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}The business you specified ID of doesn't exist.");
	if(type == -1) {
	    SetPVarInt(playerid, "EditingBusinessType", id);

	    new string[1024];
	    format(string, sizeof(string), "Type\tName\n");
	    for(new i; i < sizeof(BusinessInteriors); i++) format(string, sizeof(string), "%s%d\t%s\n", string, i, BusinessInteriors[i][InteriorName]);
		ShowPlayerDialog(playerid, DIALOG_ADMIN_BUSINESS_TYPE, DIALOG_STYLE_TABLIST_HEADERS, "Business Types", string, "Set", "Cancel");
	}else{
	    if(!(0 <= type <= sizeof(BusinessInteriors)-1)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid business type.");
	    BusinessData[id][Type] = type;
	    Business_UpdateLabel(id);
	    Business_Save(id);

	    new string[128];
	    format(string, sizeof(string), "Business's type set to %s.", BusinessInteriors[type][InteriorName]);
	    SendClientMessage(playerid, -1, string);
	}

	return 1;
}

CMD:resetbusiness(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "USAGE: {FFFFFF}/resetbusiness [business id]");
	if(!Iter_Contains(Business, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}The business you specified ID of doesn't exist.");
    Business_Reset(id);
    SendClientMessage(playerid, -1, "Business reset.");
	return 1;
}

CMD:deletebusiness(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "USAGE: {FFFFFF}/deletebusiness [business id]");
	if(!Iter_Contains(Business, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}The business you specified ID of doesn't exist.");
	DestroyDynamic3DTextLabel(BusinessData[id][BusinessLabel]);
	DestroyDynamicPickup(BusinessData[id][BusinessPickup]);
    format(BusinessData[id][Name], MAX_BUSINESS_NAME, "Business");
	format(BusinessData[id][Owner], MAX_PLAYER_NAME, "-");
	BusinessData[id][Closed] = 0;
	BusinessData[id][SalePrice] = 0;
    BusinessData[id][Money] = 0;
	BusinessData[id][LastVisited] = 0;
	BusinessData[id][BusinessLabel] = Text3D: INVALID_3DTEXT_ID;
	BusinessData[id][BusinessPickup] = -1;
	BusinessData[id][Save] = false;
	Business_KickEveryone(id);
	Iter_Remove(Business, id);

	new query[64];
	mysql_format(BusinessSQL, query, sizeof(query), "DELETE FROM business WHERE ID=%d", id);
	mysql_tquery(BusinessSQL, query, "", "");
    SendClientMessage(playerid, -1, "Business deleted.");
	return 1;
}
