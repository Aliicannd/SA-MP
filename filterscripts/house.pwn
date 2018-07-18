/*
	Yet Another House System by rootcause

	Current Version: 1.3 for MySQL Plugin R40
	Topic: http://forum.sa-mp.com/showthread.php?p=3409290

	Changelog (v1.3):
	- Added house selling, you can put your houses for sale. When your house is bought by an another player, you'll receive your money.
	- Added a house buying limiter, a player can't buy more than LIMIT_PER_PLAYER houses. Set LIMIT_PER_PLAYER to 0 if you want no limits.
	- Internal changes like replacing GetPlayerName with Player_GetName or replacing the DIALOG_HOUSE+x format with e_dialogids enum.
*/

#define 	FILTERSCRIPT
#include 	<a_samp>
#include    <a_mysql>
#include    <streamer>
#include    <sscanf2>
#include    <YSI\y_iterate>
#include    <zcmd>

#define     MAX_HOUSES          (100)
#define     MAX_HOUSE_NAME      (48)
#define     MAX_HOUSE_PASSWORD  (16)
#define     MAX_HOUSE_ADDRESS   (48)
#define     MAX_INT_NAME        (32)
#define     INVALID_HOUSE_ID    (-1)
#define     HOUSE_COOLDOWN      (6)
#define     LIMIT_PER_PLAYER    (3)

#define		SQL_HOST			"127.0.0.1"
#define		SQL_USER			"root"
#define		SQL_PASSWORD		""
#define		SQL_DBNAME			"housedb"

enum    _:e_lockmodes
{
	LOCK_MODE_NOLOCK,
	LOCK_MODE_PASSWORD,
	LOCK_MODE_KEYS,
	LOCK_MODE_OWNER
}

enum    _:e_selectmodes
{
	SELECT_MODE_NONE,
	SELECT_MODE_EDIT,
	SELECT_MODE_SELL
}

enum	_:e_dialogids
{
	DIALOG_BUY_HOUSE = 7500,
	DIALOG_HOUSE_PASSWORD,
	DIALOG_HOUSE_MENU,
	DIALOG_HOUSE_NAME,
	DIALOG_HOUSE_NEW_PASSWORD,
	DIALOG_HOUSE_LOCK,
	DIALOG_SAFE_MENU,
	DIALOG_SAFE_TAKE,
	DIALOG_SAFE_PUT,
	DIALOG_GUNS_MENU,
	DIALOG_GUNS_TAKE,
	DIALOG_FURNITURE_MENU,
	DIALOG_FURNITURE_BUY,
	DIALOG_FURNITURE_SELL,
	DIALOG_VISITORS_MENU,
	DIALOG_VISITORS,
	DIALOG_KEYS_MENU,
	DIALOG_KEYS,
	DIALOG_SAFE_HISTORY,
	DIALOG_MY_KEYS,
	DIALOG_BUY_HOUSE_FROM_OWNER,
	DIALOG_SELL_HOUSE,
	DIALOG_SELLING_PRICE
}

enum    e_house
{
	Name[MAX_HOUSE_NAME],
	Owner[MAX_PLAYER_NAME],
	Password[MAX_HOUSE_PASSWORD],
	Address[MAX_HOUSE_ADDRESS],
	Float: houseX,
	Float: houseY,
	Float: houseZ,
	Price,
	SalePrice,
	Interior,
	LockMode,
	SafeMoney,
	LastEntered,
	Text3D: HouseLabel,
	HousePickup,
	HouseIcon,
	bool: Save
};

enum    e_interior
{
	IntName[MAX_INT_NAME],
	Float: intX,
	Float: intY,
	Float: intZ,
	intID,
	Text3D: intLabel,
	intPickup
};

enum    e_furnituredata
{
	ModelID,
	Name[32],
	Price
};

enum    e_furniture
{
	SQLID,
	HouseID,
	ArrayID,
	Float: furnitureX,
	Float: furnitureY,
	Float: furnitureZ,
	Float: furnitureRX,
	Float: furnitureRY,
	Float: furnitureRZ
};

enum    e_sazone
{
    SAZONE_NAME[28],
    Float: SAZONE_AREA[6]
};

new
	MySQL: SQLHandle,
	HouseTimer = -1,
 	HouseData[MAX_HOUSES][e_house],
	Iterator: Houses<MAX_HOUSES>,
	Iterator: HouseKeys[MAX_PLAYERS]<MAX_HOUSES>,
	InHouse[MAX_PLAYERS] = {INVALID_HOUSE_ID, ...},
	SelectMode[MAX_PLAYERS] = {SELECT_MODE_NONE, ...},
	LastVisitedHouse[MAX_PLAYERS] = {INVALID_HOUSE_ID, ...},
	ListPage[MAX_PLAYERS] = {0, ...},
	bool: EditingFurniture[MAX_PLAYERS] = {false, ...};

new
    HouseInteriors[][e_interior] = {
    // int name, x, y, z, intid
		{"Interior 1", 2233.4900, -1114.4435, 1050.8828, 5},
		{"Interior 2", 2196.3943, -1204.1359, 1049.0234, 6},
		{"Interior 3", 2318.1616, -1026.3762, 1050.2109, 9},
		{"Interior 4", 421.8333, 2536.9814, 10.0000, 10},
		{"Interior 5", 225.5707, 1240.0643, 1082.1406, 2},
		{"Interior 6", 2496.2087, -1692.3149, 1014.7422, 3},
		{"Interior 7", 226.7545, 1114.4180, 1080.9952, 5},
		{"Interior 8", 2269.9636, -1210.3275, 1047.5625, 10}
    };

new
	HouseFurnitures[][e_furnituredata] = {
	// modelid, furniture name, price
	    {3111, "Building Plan", 500},
	    {2894, "Book", 20},
	    {2277, "Cat Picture", 100},
	    {1753, "Leather Couch", 150},
	    {1703, "Black Couch", 200},
	    {1255, "Lounger", 75},
	    {19581, "Frying Pan", 10},
	    {19584, "Sauce Pan", 12},
	    {19590, "Woozie's Sword", 1000},
	    {19525, "Wedding Cake", 50},
	    {1742, "Bookshelf", 80},
	    {1518, "TV 1", 130},
	    {19609, "Drum Kit", 500},
		{19787, "Small LCD TV", 2000},
		{19786, "Big LCD TV", 4000},
		{2627, "Treadmill", 130}
	};

new
	SAZones[][e_sazone] = {
		{"The Big Ear",	                {-410.00,1403.30,-3.00,-137.90,1681.20,200.00}},
		{"Aldea Malvada",               {-1372.10,2498.50,0.00,-1277.50,2615.30,200.00}},
		{"Angel Pine",                  {-2324.90,-2584.20,-6.10,-1964.20,-2212.10,200.00}},
		{"Arco del Oeste",              {-901.10,2221.80,0.00,-592.00,2571.90,200.00}},
		{"Avispa Country Club",         {-2646.40,-355.40,0.00,-2270.00,-222.50,200.00}},
		{"Avispa Country Club",         {-2831.80,-430.20,-6.10,-2646.40,-222.50,200.00}},
		{"Avispa Country Club",         {-2361.50,-417.10,0.00,-2270.00,-355.40,200.00}},
		{"Avispa Country Club",         {-2667.80,-302.10,-28.80,-2646.40,-262.30,71.10}},
		{"Avispa Country Club",         {-2470.00,-355.40,0.00,-2270.00,-318.40,46.10}},
		{"Avispa Country Club",         {-2550.00,-355.40,0.00,-2470.00,-318.40,39.70}},
		{"Back o Beyond",               {-1166.90,-2641.10,0.00,-321.70,-1856.00,200.00}},
		{"Battery Point",               {-2741.00,1268.40,-4.50,-2533.00,1490.40,200.00}},
		{"Bayside",                     {-2741.00,2175.10,0.00,-2353.10,2722.70,200.00}},
		{"Bayside Marina",              {-2353.10,2275.70,0.00,-2153.10,2475.70,200.00}},
		{"Beacon Hill",                 {-399.60,-1075.50,-1.40,-319.00,-977.50,198.50}},
		{"Blackfield",                  {964.30,1203.20,-89.00,1197.30,1403.20,110.90}},
		{"Blackfield",                  {964.30,1403.20,-89.00,1197.30,1726.20,110.90}},
		{"Blackfield Chapel",           {1375.60,596.30,-89.00,1558.00,823.20,110.90}},
		{"Blackfield Chapel",           {1325.60,596.30,-89.00,1375.60,795.00,110.90}},
		{"Blackfield Intersection",     {1197.30,1044.60,-89.00,1277.00,1163.30,110.90}},
		{"Blackfield Intersection",     {1166.50,795.00,-89.00,1375.60,1044.60,110.90}},
		{"Blackfield Intersection",     {1277.00,1044.60,-89.00,1315.30,1087.60,110.90}},
		{"Blackfield Intersection",     {1375.60,823.20,-89.00,1457.30,919.40,110.90}},
		{"Blueberry",                   {104.50,-220.10,2.30,349.60,152.20,200.00}},
		{"Blueberry",                   {19.60,-404.10,3.80,349.60,-220.10,200.00}},
		{"Blueberry Acres",             {-319.60,-220.10,0.00,104.50,293.30,200.00}},
		{"Caligula's Palace",           {2087.30,1543.20,-89.00,2437.30,1703.20,110.90}},
		{"Caligula's Palace",           {2137.40,1703.20,-89.00,2437.30,1783.20,110.90}},
		{"Calton Heights",              {-2274.10,744.10,-6.10,-1982.30,1358.90,200.00}},
		{"Chinatown",                   {-2274.10,578.30,-7.60,-2078.60,744.10,200.00}},
		{"City Hall",                   {-2867.80,277.40,-9.10,-2593.40,458.40,200.00}},
		{"Come-A-Lot",                  {2087.30,943.20,-89.00,2623.10,1203.20,110.90}},
		{"Commerce",                    {1323.90,-1842.20,-89.00,1701.90,-1722.20,110.90}},
		{"Commerce",                    {1323.90,-1722.20,-89.00,1440.90,-1577.50,110.90}},
		{"Commerce",                    {1370.80,-1577.50,-89.00,1463.90,-1384.90,110.90}},
		{"Commerce",                    {1463.90,-1577.50,-89.00,1667.90,-1430.80,110.90}},
		{"Commerce",                    {1583.50,-1722.20,-89.00,1758.90,-1577.50,110.90}},
		{"Commerce",                    {1667.90,-1577.50,-89.00,1812.60,-1430.80,110.90}},
		{"Conference Center",           {1046.10,-1804.20,-89.00,1323.90,-1722.20,110.90}},
		{"Conference Center",           {1073.20,-1842.20,-89.00,1323.90,-1804.20,110.90}},
		{"Cranberry Station",           {-2007.80,56.30,0.00,-1922.00,224.70,100.00}},
		{"Creek",                       {2749.90,1937.20,-89.00,2921.60,2669.70,110.90}},
		{"Dillimore",                   {580.70,-674.80,-9.50,861.00,-404.70,200.00}},
		{"Doherty",                     {-2270.00,-324.10,-0.00,-1794.90,-222.50,200.00}},
		{"Doherty",                     {-2173.00,-222.50,-0.00,-1794.90,265.20,200.00}},
		{"Downtown",                    {-1982.30,744.10,-6.10,-1871.70,1274.20,200.00}},
		{"Downtown",                    {-1871.70,1176.40,-4.50,-1620.30,1274.20,200.00}},
		{"Downtown",                    {-1700.00,744.20,-6.10,-1580.00,1176.50,200.00}},
		{"Downtown",                    {-1580.00,744.20,-6.10,-1499.80,1025.90,200.00}},
		{"Downtown",                    {-2078.60,578.30,-7.60,-1499.80,744.20,200.00}},
		{"Downtown",                    {-1993.20,265.20,-9.10,-1794.90,578.30,200.00}},
		{"Downtown Los Santos",         {1463.90,-1430.80,-89.00,1724.70,-1290.80,110.90}},
		{"Downtown Los Santos",         {1724.70,-1430.80,-89.00,1812.60,-1250.90,110.90}},
		{"Downtown Los Santos",         {1463.90,-1290.80,-89.00,1724.70,-1150.80,110.90}},
		{"Downtown Los Santos",         {1370.80,-1384.90,-89.00,1463.90,-1170.80,110.90}},
		{"Downtown Los Santos",         {1724.70,-1250.90,-89.00,1812.60,-1150.80,110.90}},
		{"Downtown Los Santos",         {1370.80,-1170.80,-89.00,1463.90,-1130.80,110.90}},
		{"Downtown Los Santos",         {1378.30,-1130.80,-89.00,1463.90,-1026.30,110.90}},
		{"Downtown Los Santos",         {1391.00,-1026.30,-89.00,1463.90,-926.90,110.90}},
		{"Downtown Los Santos",         {1507.50,-1385.20,110.90,1582.50,-1325.30,335.90}},
		{"East Beach",                  {2632.80,-1852.80,-89.00,2959.30,-1668.10,110.90}},
		{"East Beach",                  {2632.80,-1668.10,-89.00,2747.70,-1393.40,110.90}},
		{"East Beach",                  {2747.70,-1668.10,-89.00,2959.30,-1498.60,110.90}},
		{"East Beach",                  {2747.70,-1498.60,-89.00,2959.30,-1120.00,110.90}},
		{"East Los Santos",             {2421.00,-1628.50,-89.00,2632.80,-1454.30,110.90}},
		{"East Los Santos",             {2222.50,-1628.50,-89.00,2421.00,-1494.00,110.90}},
		{"East Los Santos",             {2266.20,-1494.00,-89.00,2381.60,-1372.00,110.90}},
		{"East Los Santos",             {2381.60,-1494.00,-89.00,2421.00,-1454.30,110.90}},
		{"East Los Santos",             {2281.40,-1372.00,-89.00,2381.60,-1135.00,110.90}},
		{"East Los Santos",             {2381.60,-1454.30,-89.00,2462.10,-1135.00,110.90}},
		{"East Los Santos",             {2462.10,-1454.30,-89.00,2581.70,-1135.00,110.90}},
		{"Easter Basin",                {-1794.90,249.90,-9.10,-1242.90,578.30,200.00}},
		{"Easter Basin",                {-1794.90,-50.00,-0.00,-1499.80,249.90,200.00}},
		{"Easter Bay Airport",          {-1499.80,-50.00,-0.00,-1242.90,249.90,200.00}},
		{"Easter Bay Airport",          {-1794.90,-730.10,-3.00,-1213.90,-50.00,200.00}},
		{"Easter Bay Airport",          {-1213.90,-730.10,0.00,-1132.80,-50.00,200.00}},
		{"Easter Bay Airport",          {-1242.90,-50.00,0.00,-1213.90,578.30,200.00}},
		{"Easter Bay Airport",          {-1213.90,-50.00,-4.50,-947.90,578.30,200.00}},
		{"Easter Bay Airport",          {-1315.40,-405.30,15.40,-1264.40,-209.50,25.40}},
		{"Easter Bay Airport",          {-1354.30,-287.30,15.40,-1315.40,-209.50,25.40}},
		{"Easter Bay Airport",          {-1490.30,-209.50,15.40,-1264.40,-148.30,25.40}},
		{"Easter Bay Chemicals",        {-1132.80,-768.00,0.00,-956.40,-578.10,200.00}},
		{"Easter Bay Chemicals",        {-1132.80,-787.30,0.00,-956.40,-768.00,200.00}},
		{"El Castillo del Diablo",      {-464.50,2217.60,0.00,-208.50,2580.30,200.00}},
		{"El Castillo del Diablo",      {-208.50,2123.00,-7.60,114.00,2337.10,200.00}},
		{"El Castillo del Diablo",      {-208.50,2337.10,0.00,8.40,2487.10,200.00}},
		{"El Corona",                   {1812.60,-2179.20,-89.00,1970.60,-1852.80,110.90}},
		{"El Corona",                   {1692.60,-2179.20,-89.00,1812.60,-1842.20,110.90}},
		{"El Quebrados",                {-1645.20,2498.50,0.00,-1372.10,2777.80,200.00}},
		{"Esplanade East",              {-1620.30,1176.50,-4.50,-1580.00,1274.20,200.00}},
		{"Esplanade East",              {-1580.00,1025.90,-6.10,-1499.80,1274.20,200.00}},
		{"Esplanade East",              {-1499.80,578.30,-79.60,-1339.80,1274.20,20.30}},
		{"Esplanade North",             {-2533.00,1358.90,-4.50,-1996.60,1501.20,200.00}},
		{"Esplanade North",             {-1996.60,1358.90,-4.50,-1524.20,1592.50,200.00}},
		{"Esplanade North",             {-1982.30,1274.20,-4.50,-1524.20,1358.90,200.00}},
		{"Fallen Tree",                 {-792.20,-698.50,-5.30,-452.40,-380.00,200.00}},
		{"Fallow Bridge",               {434.30,366.50,0.00,603.00,555.60,200.00}},
		{"Fern Ridge",                  {508.10,-139.20,0.00,1306.60,119.50,200.00}},
		{"Financial",                   {-1871.70,744.10,-6.10,-1701.30,1176.40,300.00}},
		{"Fisher's Lagoon",             {1916.90,-233.30,-100.00,2131.70,13.80,200.00}},
		{"Flint Intersection",          {-187.70,-1596.70,-89.00,17.00,-1276.60,110.90}},
		{"Flint Range",                 {-594.10,-1648.50,0.00,-187.70,-1276.60,200.00}},
		{"Fort Carson",                 {-376.20,826.30,-3.00,123.70,1220.40,200.00}},
		{"Foster Valley",               {-2270.00,-430.20,-0.00,-2178.60,-324.10,200.00}},
		{"Foster Valley",               {-2178.60,-599.80,-0.00,-1794.90,-324.10,200.00}},
		{"Foster Valley",               {-2178.60,-1115.50,0.00,-1794.90,-599.80,200.00}},
		{"Foster Valley",               {-2178.60,-1250.90,0.00,-1794.90,-1115.50,200.00}},
		{"Frederick Bridge",            {2759.20,296.50,0.00,2774.20,594.70,200.00}},
		{"Gant Bridge",                 {-2741.40,1659.60,-6.10,-2616.40,2175.10,200.00}},
		{"Gant Bridge",                 {-2741.00,1490.40,-6.10,-2616.40,1659.60,200.00}},
		{"Ganton",                      {2222.50,-1852.80,-89.00,2632.80,-1722.30,110.90}},
		{"Ganton",                      {2222.50,-1722.30,-89.00,2632.80,-1628.50,110.90}},
		{"Garcia",                      {-2411.20,-222.50,-0.00,-2173.00,265.20,200.00}},
		{"Garcia",                      {-2395.10,-222.50,-5.30,-2354.00,-204.70,200.00}},
		{"Garver Bridge",               {-1339.80,828.10,-89.00,-1213.90,1057.00,110.90}},
		{"Garver Bridge",               {-1213.90,950.00,-89.00,-1087.90,1178.90,110.90}},
		{"Garver Bridge",               {-1499.80,696.40,-179.60,-1339.80,925.30,20.30}},
		{"Glen Park",                   {1812.60,-1449.60,-89.00,1996.90,-1350.70,110.90}},
		{"Glen Park",                   {1812.60,-1100.80,-89.00,1994.30,-973.30,110.90}},
		{"Glen Park",                   {1812.60,-1350.70,-89.00,2056.80,-1100.80,110.90}},
		{"Green Palms",                 {176.50,1305.40,-3.00,338.60,1520.70,200.00}},
		{"Greenglass College",          {964.30,1044.60,-89.00,1197.30,1203.20,110.90}},
		{"Greenglass College",          {964.30,930.80,-89.00,1166.50,1044.60,110.90}},
		{"Hampton Barns",               {603.00,264.30,0.00,761.90,366.50,200.00}},
		{"Hankypanky Point",            {2576.90,62.10,0.00,2759.20,385.50,200.00}},
		{"Harry Gold Parkway",          {1777.30,863.20,-89.00,1817.30,2342.80,110.90}},
		{"Hashbury",                    {-2593.40,-222.50,-0.00,-2411.20,54.70,200.00}},
		{"Hilltop Farm",                {967.30,-450.30,-3.00,1176.70,-217.90,200.00}},
		{"Hunter Quarry",               {337.20,710.80,-115.20,860.50,1031.70,203.70}},
		{"Idlewood",                    {1812.60,-1852.80,-89.00,1971.60,-1742.30,110.90}},
		{"Idlewood",                    {1812.60,-1742.30,-89.00,1951.60,-1602.30,110.90}},
		{"Idlewood",                    {1951.60,-1742.30,-89.00,2124.60,-1602.30,110.90}},
		{"Idlewood",                    {1812.60,-1602.30,-89.00,2124.60,-1449.60,110.90}},
		{"Idlewood",                    {2124.60,-1742.30,-89.00,2222.50,-1494.00,110.90}},
		{"Idlewood",                    {1971.60,-1852.80,-89.00,2222.50,-1742.30,110.90}},
		{"Jefferson",                   {1996.90,-1449.60,-89.00,2056.80,-1350.70,110.90}},
		{"Jefferson",                   {2124.60,-1494.00,-89.00,2266.20,-1449.60,110.90}},
		{"Jefferson",                   {2056.80,-1372.00,-89.00,2281.40,-1210.70,110.90}},
		{"Jefferson",                   {2056.80,-1210.70,-89.00,2185.30,-1126.30,110.90}},
		{"Jefferson",                   {2185.30,-1210.70,-89.00,2281.40,-1154.50,110.90}},
		{"Jefferson",                   {2056.80,-1449.60,-89.00,2266.20,-1372.00,110.90}},
		{"Julius Thruway East",         {2623.10,943.20,-89.00,2749.90,1055.90,110.90}},
		{"Julius Thruway East",         {2685.10,1055.90,-89.00,2749.90,2626.50,110.90}},
		{"Julius Thruway East",         {2536.40,2442.50,-89.00,2685.10,2542.50,110.90}},
		{"Julius Thruway East",         {2625.10,2202.70,-89.00,2685.10,2442.50,110.90}},
		{"Julius Thruway North",        {2498.20,2542.50,-89.00,2685.10,2626.50,110.90}},
		{"Julius Thruway North",        {2237.40,2542.50,-89.00,2498.20,2663.10,110.90}},
		{"Julius Thruway North",        {2121.40,2508.20,-89.00,2237.40,2663.10,110.90}},
		{"Julius Thruway North",        {1938.80,2508.20,-89.00,2121.40,2624.20,110.90}},
		{"Julius Thruway North",        {1534.50,2433.20,-89.00,1848.40,2583.20,110.90}},
		{"Julius Thruway North",        {1848.40,2478.40,-89.00,1938.80,2553.40,110.90}},
		{"Julius Thruway North",        {1704.50,2342.80,-89.00,1848.40,2433.20,110.90}},
		{"Julius Thruway North",        {1377.30,2433.20,-89.00,1534.50,2507.20,110.90}},
		{"Julius Thruway South",        {1457.30,823.20,-89.00,2377.30,863.20,110.90}},
		{"Julius Thruway South",        {2377.30,788.80,-89.00,2537.30,897.90,110.90}},
		{"Julius Thruway West",         {1197.30,1163.30,-89.00,1236.60,2243.20,110.90}},
		{"Julius Thruway West",         {1236.60,2142.80,-89.00,1297.40,2243.20,110.90}},
		{"Juniper Hill",                {-2533.00,578.30,-7.60,-2274.10,968.30,200.00}},
		{"Juniper Hollow",              {-2533.00,968.30,-6.10,-2274.10,1358.90,200.00}},
		{"K.A.C.C. Military Fuels",     {2498.20,2626.50,-89.00,2749.90,2861.50,110.90}},
		{"Kincaid Bridge",              {-1339.80,599.20,-89.00,-1213.90,828.10,110.90}},
		{"Kincaid Bridge",              {-1213.90,721.10,-89.00,-1087.90,950.00,110.90}},
		{"Kincaid Bridge",              {-1087.90,855.30,-89.00,-961.90,986.20,110.90}},
		{"King's",                      {-2329.30,458.40,-7.60,-1993.20,578.30,200.00}},
		{"King's",                      {-2411.20,265.20,-9.10,-1993.20,373.50,200.00}},
		{"King's",                      {-2253.50,373.50,-9.10,-1993.20,458.40,200.00}},
		{"LVA Freight Depot",           {1457.30,863.20,-89.00,1777.40,1143.20,110.90}},
		{"LVA Freight Depot",           {1375.60,919.40,-89.00,1457.30,1203.20,110.90}},
		{"LVA Freight Depot",           {1277.00,1087.60,-89.00,1375.60,1203.20,110.90}},
		{"LVA Freight Depot",           {1315.30,1044.60,-89.00,1375.60,1087.60,110.90}},
		{"LVA Freight Depot",           {1236.60,1163.40,-89.00,1277.00,1203.20,110.90}},
		{"Las Barrancas",               {-926.10,1398.70,-3.00,-719.20,1634.60,200.00}},
		{"Las Brujas",                  {-365.10,2123.00,-3.00,-208.50,2217.60,200.00}},
		{"Las Colinas",                 {1994.30,-1100.80,-89.00,2056.80,-920.80,110.90}},
		{"Las Colinas",                 {2056.80,-1126.30,-89.00,2126.80,-920.80,110.90}},
		{"Las Colinas",                 {2185.30,-1154.50,-89.00,2281.40,-934.40,110.90}},
		{"Las Colinas",                 {2126.80,-1126.30,-89.00,2185.30,-934.40,110.90}},
		{"Las Colinas",                 {2747.70,-1120.00,-89.00,2959.30,-945.00,110.90}},
		{"Las Colinas",                 {2632.70,-1135.00,-89.00,2747.70,-945.00,110.90}},
		{"Las Colinas",                 {2281.40,-1135.00,-89.00,2632.70,-945.00,110.90}},
		{"Las Payasadas",               {-354.30,2580.30,2.00,-133.60,2816.80,200.00}},
		{"Las Venturas Airport",        {1236.60,1203.20,-89.00,1457.30,1883.10,110.90}},
		{"Las Venturas Airport",        {1457.30,1203.20,-89.00,1777.30,1883.10,110.90}},
		{"Las Venturas Airport",        {1457.30,1143.20,-89.00,1777.40,1203.20,110.90}},
		{"Las Venturas Airport",        {1515.80,1586.40,-12.50,1729.90,1714.50,87.50}},
		{"Last Dime Motel",             {1823.00,596.30,-89.00,1997.20,823.20,110.90}},
		{"Leafy Hollow",                {-1166.90,-1856.00,0.00,-815.60,-1602.00,200.00}},
		{"Liberty City",                {-1000.00,400.00,1300.00,-700.00,600.00,1400.00}},
		{"Lil' Probe Inn",              {-90.20,1286.80,-3.00,153.80,1554.10,200.00}},
		{"Linden Side",                 {2749.90,943.20,-89.00,2923.30,1198.90,110.90}},
		{"Linden Station",              {2749.90,1198.90,-89.00,2923.30,1548.90,110.90}},
		{"Linden Station",              {2811.20,1229.50,-39.50,2861.20,1407.50,60.40}},
		{"Little Mexico",               {1701.90,-1842.20,-89.00,1812.60,-1722.20,110.90}},
		{"Little Mexico",               {1758.90,-1722.20,-89.00,1812.60,-1577.50,110.90}},
		{"Los Flores",                  {2581.70,-1454.30,-89.00,2632.80,-1393.40,110.90}},
		{"Los Flores",                  {2581.70,-1393.40,-89.00,2747.70,-1135.00,110.90}},
		{"Los Santos International",    {1249.60,-2394.30,-89.00,1852.00,-2179.20,110.90}},
		{"Los Santos International",    {1852.00,-2394.30,-89.00,2089.00,-2179.20,110.90}},
		{"Los Santos International",    {1382.70,-2730.80,-89.00,2201.80,-2394.30,110.90}},
		{"Los Santos International",    {1974.60,-2394.30,-39.00,2089.00,-2256.50,60.90}},
		{"Los Santos International",    {1400.90,-2669.20,-39.00,2189.80,-2597.20,60.90}},
		{"Los Santos International",    {2051.60,-2597.20,-39.00,2152.40,-2394.30,60.90}},
		{"Marina",                      {647.70,-1804.20,-89.00,851.40,-1577.50,110.90}},
		{"Marina",                      {647.70,-1577.50,-89.00,807.90,-1416.20,110.90}},
		{"Marina",                      {807.90,-1577.50,-89.00,926.90,-1416.20,110.90}},
		{"Market",                      {787.40,-1416.20,-89.00,1072.60,-1310.20,110.90}},
		{"Market",                      {952.60,-1310.20,-89.00,1072.60,-1130.80,110.90}},
		{"Market",                      {1072.60,-1416.20,-89.00,1370.80,-1130.80,110.90}},
		{"Market",                      {926.90,-1577.50,-89.00,1370.80,-1416.20,110.90}},
		{"Market Station",              {787.40,-1410.90,-34.10,866.00,-1310.20,65.80}},
		{"Martin Bridge",               {-222.10,293.30,0.00,-122.10,476.40,200.00}},
		{"Missionary Hill",             {-2994.40,-811.20,0.00,-2178.60,-430.20,200.00}},
		{"Montgomery",                  {1119.50,119.50,-3.00,1451.40,493.30,200.00}},
		{"Montgomery",                  {1451.40,347.40,-6.10,1582.40,420.80,200.00}},
		{"Montgomery Intersection",     {1546.60,208.10,0.00,1745.80,347.40,200.00}},
		{"Montgomery Intersection",     {1582.40,347.40,0.00,1664.60,401.70,200.00}},
		{"Mulholland",                  {1414.00,-768.00,-89.00,1667.60,-452.40,110.90}},
		{"Mulholland",                  {1281.10,-452.40,-89.00,1641.10,-290.90,110.90}},
		{"Mulholland",                  {1269.10,-768.00,-89.00,1414.00,-452.40,110.90}},
		{"Mulholland",                  {1357.00,-926.90,-89.00,1463.90,-768.00,110.90}},
		{"Mulholland",                  {1318.10,-910.10,-89.00,1357.00,-768.00,110.90}},
		{"Mulholland",                  {1169.10,-910.10,-89.00,1318.10,-768.00,110.90}},
		{"Mulholland",                  {768.60,-954.60,-89.00,952.60,-860.60,110.90}},
		{"Mulholland",                  {687.80,-860.60,-89.00,911.80,-768.00,110.90}},
		{"Mulholland",                  {737.50,-768.00,-89.00,1142.20,-674.80,110.90}},
		{"Mulholland",                  {1096.40,-910.10,-89.00,1169.10,-768.00,110.90}},
		{"Mulholland",                  {952.60,-937.10,-89.00,1096.40,-860.60,110.90}},
		{"Mulholland",                  {911.80,-860.60,-89.00,1096.40,-768.00,110.90}},
		{"Mulholland",                  {861.00,-674.80,-89.00,1156.50,-600.80,110.90}},
		{"Mulholland Intersection",     {1463.90,-1150.80,-89.00,1812.60,-768.00,110.90}},
		{"North Rock",                  {2285.30,-768.00,0.00,2770.50,-269.70,200.00}},
		{"Ocean Docks",                 {2373.70,-2697.00,-89.00,2809.20,-2330.40,110.90}},
		{"Ocean Docks",                 {2201.80,-2418.30,-89.00,2324.00,-2095.00,110.90}},
		{"Ocean Docks",                 {2324.00,-2302.30,-89.00,2703.50,-2145.10,110.90}},
		{"Ocean Docks",                 {2089.00,-2394.30,-89.00,2201.80,-2235.80,110.90}},
		{"Ocean Docks",                 {2201.80,-2730.80,-89.00,2324.00,-2418.30,110.90}},
		{"Ocean Docks",                 {2703.50,-2302.30,-89.00,2959.30,-2126.90,110.90}},
		{"Ocean Docks",                 {2324.00,-2145.10,-89.00,2703.50,-2059.20,110.90}},
		{"Ocean Flats",                 {-2994.40,277.40,-9.10,-2867.80,458.40,200.00}},
		{"Ocean Flats",                 {-2994.40,-222.50,-0.00,-2593.40,277.40,200.00}},
		{"Ocean Flats",                 {-2994.40,-430.20,-0.00,-2831.80,-222.50,200.00}},
		{"Octane Springs",              {338.60,1228.50,0.00,664.30,1655.00,200.00}},
		{"Old Venturas Strip",          {2162.30,2012.10,-89.00,2685.10,2202.70,110.90}},
		{"Palisades",                   {-2994.40,458.40,-6.10,-2741.00,1339.60,200.00}},
		{"Palomino Creek",              {2160.20,-149.00,0.00,2576.90,228.30,200.00}},
		{"Paradiso",                    {-2741.00,793.40,-6.10,-2533.00,1268.40,200.00}},
		{"Pershing Square",             {1440.90,-1722.20,-89.00,1583.50,-1577.50,110.90}},
		{"Pilgrim",                     {2437.30,1383.20,-89.00,2624.40,1783.20,110.90}},
		{"Pilgrim",                     {2624.40,1383.20,-89.00,2685.10,1783.20,110.90}},
		{"Pilson Intersection",         {1098.30,2243.20,-89.00,1377.30,2507.20,110.90}},
		{"Pirates in Men's Pants",      {1817.30,1469.20,-89.00,2027.40,1703.20,110.90}},
		{"Playa del Seville",           {2703.50,-2126.90,-89.00,2959.30,-1852.80,110.90}},
		{"Prickle Pine",                {1534.50,2583.20,-89.00,1848.40,2863.20,110.90}},
		{"Prickle Pine",                {1117.40,2507.20,-89.00,1534.50,2723.20,110.90}},
		{"Prickle Pine",                {1848.40,2553.40,-89.00,1938.80,2863.20,110.90}},
		{"Prickle Pine",                {1938.80,2624.20,-89.00,2121.40,2861.50,110.90}},
		{"Queens",                      {-2533.00,458.40,0.00,-2329.30,578.30,200.00}},
		{"Queens",                      {-2593.40,54.70,0.00,-2411.20,458.40,200.00}},
		{"Queens",                      {-2411.20,373.50,0.00,-2253.50,458.40,200.00}},
		{"Randolph Industrial Estate",  {1558.00,596.30,-89.00,1823.00,823.20,110.90}},
		{"Redsands East",               {1817.30,2011.80,-89.00,2106.70,2202.70,110.90}},
		{"Redsands East",               {1817.30,2202.70,-89.00,2011.90,2342.80,110.90}},
		{"Redsands East",               {1848.40,2342.80,-89.00,2011.90,2478.40,110.90}},
		{"Redsands West",               {1236.60,1883.10,-89.00,1777.30,2142.80,110.90}},
		{"Redsands West",               {1297.40,2142.80,-89.00,1777.30,2243.20,110.90}},
		{"Redsands West",               {1377.30,2243.20,-89.00,1704.50,2433.20,110.90}},
		{"Redsands West",               {1704.50,2243.20,-89.00,1777.30,2342.80,110.90}},
		{"Regular Tom",                 {-405.70,1712.80,-3.00,-276.70,1892.70,200.00}},
		{"Richman",                     {647.50,-1118.20,-89.00,787.40,-954.60,110.90}},
		{"Richman",                     {647.50,-954.60,-89.00,768.60,-860.60,110.90}},
		{"Richman",                     {225.10,-1369.60,-89.00,334.50,-1292.00,110.90}},
		{"Richman",                     {225.10,-1292.00,-89.00,466.20,-1235.00,110.90}},
		{"Richman",                     {72.60,-1404.90,-89.00,225.10,-1235.00,110.90}},
		{"Richman",                     {72.60,-1235.00,-89.00,321.30,-1008.10,110.90}},
		{"Richman",                     {321.30,-1235.00,-89.00,647.50,-1044.00,110.90}},
		{"Richman",                     {321.30,-1044.00,-89.00,647.50,-860.60,110.90}},
		{"Richman",                     {321.30,-860.60,-89.00,687.80,-768.00,110.90}},
		{"Richman",                     {321.30,-768.00,-89.00,700.70,-674.80,110.90}},
		{"Robada Intersection",         {-1119.00,1178.90,-89.00,-862.00,1351.40,110.90}},
		{"Roca Escalante",              {2237.40,2202.70,-89.00,2536.40,2542.50,110.90}},
		{"Roca Escalante",              {2536.40,2202.70,-89.00,2625.10,2442.50,110.90}},
		{"Rockshore East",              {2537.30,676.50,-89.00,2902.30,943.20,110.90}},
		{"Rockshore West",              {1997.20,596.30,-89.00,2377.30,823.20,110.90}},
		{"Rockshore West",              {2377.30,596.30,-89.00,2537.30,788.80,110.90}},
		{"Rodeo",                       {72.60,-1684.60,-89.00,225.10,-1544.10,110.90}},
		{"Rodeo",                       {72.60,-1544.10,-89.00,225.10,-1404.90,110.90}},
		{"Rodeo",                       {225.10,-1684.60,-89.00,312.80,-1501.90,110.90}},
		{"Rodeo",                       {225.10,-1501.90,-89.00,334.50,-1369.60,110.90}},
		{"Rodeo",                       {334.50,-1501.90,-89.00,422.60,-1406.00,110.90}},
		{"Rodeo",                       {312.80,-1684.60,-89.00,422.60,-1501.90,110.90}},
		{"Rodeo",                       {422.60,-1684.60,-89.00,558.00,-1570.20,110.90}},
		{"Rodeo",                       {558.00,-1684.60,-89.00,647.50,-1384.90,110.90}},
		{"Rodeo",                       {466.20,-1570.20,-89.00,558.00,-1385.00,110.90}},
		{"Rodeo",                       {422.60,-1570.20,-89.00,466.20,-1406.00,110.90}},
		{"Rodeo",                       {466.20,-1385.00,-89.00,647.50,-1235.00,110.90}},
		{"Rodeo",                       {334.50,-1406.00,-89.00,466.20,-1292.00,110.90}},
		{"Royal Casino",                {2087.30,1383.20,-89.00,2437.30,1543.20,110.90}},
		{"San Andreas Sound",           {2450.30,385.50,-100.00,2759.20,562.30,200.00}},
		{"Santa Flora",                 {-2741.00,458.40,-7.60,-2533.00,793.40,200.00}},
		{"Santa Maria Beach",           {342.60,-2173.20,-89.00,647.70,-1684.60,110.90}},
		{"Santa Maria Beach",           {72.60,-2173.20,-89.00,342.60,-1684.60,110.90}},
		{"Shady Cabin",                 {-1632.80,-2263.40,-3.00,-1601.30,-2231.70,200.00}},
		{"Shady Creeks",                {-1820.60,-2643.60,-8.00,-1226.70,-1771.60,200.00}},
		{"Shady Creeks",                {-2030.10,-2174.80,-6.10,-1820.60,-1771.60,200.00}},
		{"Sobell Rail Yards",           {2749.90,1548.90,-89.00,2923.30,1937.20,110.90}},
		{"Spinybed",                    {2121.40,2663.10,-89.00,2498.20,2861.50,110.90}},
		{"Starfish Casino",             {2437.30,1783.20,-89.00,2685.10,2012.10,110.90}},
		{"Starfish Casino",             {2437.30,1858.10,-39.00,2495.00,1970.80,60.90}},
		{"Starfish Casino",             {2162.30,1883.20,-89.00,2437.30,2012.10,110.90}},
		{"Temple",                      {1252.30,-1130.80,-89.00,1378.30,-1026.30,110.90}},
		{"Temple",                      {1252.30,-1026.30,-89.00,1391.00,-926.90,110.90}},
		{"Temple",                      {1252.30,-926.90,-89.00,1357.00,-910.10,110.90}},
		{"Temple",                      {952.60,-1130.80,-89.00,1096.40,-937.10,110.90}},
		{"Temple",                      {1096.40,-1130.80,-89.00,1252.30,-1026.30,110.90}},
		{"Temple",                      {1096.40,-1026.30,-89.00,1252.30,-910.10,110.90}},
		{"The Camel's Toe",             {2087.30,1203.20,-89.00,2640.40,1383.20,110.90}},
		{"The Clown's Pocket",          {2162.30,1783.20,-89.00,2437.30,1883.20,110.90}},
		{"The Emerald Isle",            {2011.90,2202.70,-89.00,2237.40,2508.20,110.90}},
		{"The Farm",                    {-1209.60,-1317.10,114.90,-908.10,-787.30,251.90}},
		{"The Four Dragons Casino",     {1817.30,863.20,-89.00,2027.30,1083.20,110.90}},
		{"The High Roller",             {1817.30,1283.20,-89.00,2027.30,1469.20,110.90}},
		{"The Mako Span",               {1664.60,401.70,0.00,1785.10,567.20,200.00}},
		{"The Panopticon",              {-947.90,-304.30,-1.10,-319.60,327.00,200.00}},
		{"The Pink Swan",               {1817.30,1083.20,-89.00,2027.30,1283.20,110.90}},
		{"The Sherman Dam",             {-968.70,1929.40,-3.00,-481.10,2155.20,200.00}},
		{"The Strip",                   {2027.40,863.20,-89.00,2087.30,1703.20,110.90}},
		{"The Strip",                   {2106.70,1863.20,-89.00,2162.30,2202.70,110.90}},
		{"The Strip",                   {2027.40,1783.20,-89.00,2162.30,1863.20,110.90}},
		{"The Strip",                   {2027.40,1703.20,-89.00,2137.40,1783.20,110.90}},
		{"The Visage",                  {1817.30,1863.20,-89.00,2106.70,2011.80,110.90}},
		{"The Visage",                  {1817.30,1703.20,-89.00,2027.40,1863.20,110.90}},
		{"Unity Station",               {1692.60,-1971.80,-20.40,1812.60,-1932.80,79.50}},
		{"Valle Ocultado",              {-936.60,2611.40,2.00,-715.90,2847.90,200.00}},
		{"Verdant Bluffs",              {930.20,-2488.40,-89.00,1249.60,-2006.70,110.90}},
		{"Verdant Bluffs",              {1073.20,-2006.70,-89.00,1249.60,-1842.20,110.90}},
		{"Verdant Bluffs",              {1249.60,-2179.20,-89.00,1692.60,-1842.20,110.90}},
		{"Verdant Meadows",             {37.00,2337.10,-3.00,435.90,2677.90,200.00}},
		{"Verona Beach",                {647.70,-2173.20,-89.00,930.20,-1804.20,110.90}},
		{"Verona Beach",                {930.20,-2006.70,-89.00,1073.20,-1804.20,110.90}},
		{"Verona Beach",                {851.40,-1804.20,-89.00,1046.10,-1577.50,110.90}},
		{"Verona Beach",                {1161.50,-1722.20,-89.00,1323.90,-1577.50,110.90}},
		{"Verona Beach",                {1046.10,-1722.20,-89.00,1161.50,-1577.50,110.90}},
		{"Vinewood",                    {787.40,-1310.20,-89.00,952.60,-1130.80,110.90}},
		{"Vinewood",                    {787.40,-1130.80,-89.00,952.60,-954.60,110.90}},
		{"Vinewood",                    {647.50,-1227.20,-89.00,787.40,-1118.20,110.90}},
		{"Vinewood",                    {647.70,-1416.20,-89.00,787.40,-1227.20,110.90}},
		{"Whitewood Estates",           {883.30,1726.20,-89.00,1098.30,2507.20,110.90}},
		{"Whitewood Estates",           {1098.30,1726.20,-89.00,1197.30,2243.20,110.90}},
		{"Willowfield",                 {1970.60,-2179.20,-89.00,2089.00,-1852.80,110.90}},
		{"Willowfield",                 {2089.00,-2235.80,-89.00,2201.80,-1989.90,110.90}},
		{"Willowfield",                 {2089.00,-1989.90,-89.00,2324.00,-1852.80,110.90}},
		{"Willowfield",                 {2201.80,-2095.00,-89.00,2324.00,-1989.90,110.90}},
		{"Willowfield",                 {2541.70,-1941.40,-89.00,2703.50,-1852.80,110.90}},
		{"Willowfield",                 {2324.00,-2059.20,-89.00,2541.70,-1852.80,110.90}},
		{"Willowfield",                 {2541.70,-2059.20,-89.00,2703.50,-1941.40,110.90}},
		{"Yellow Bell Station",         {1377.40,2600.40,-21.90,1492.40,2687.30,78.00}},
		{"Los Santos",                  {44.60,-2892.90,-242.90,2997.00,-768.00,900.00}},
		{"Las Venturas",                {869.40,596.30,-242.90,2997.00,2993.80,900.00}},
		{"Bone County",                 {-480.50,596.30,-242.90,869.40,2993.80,900.00}},
		{"Tierra Robada",               {-2997.40,1659.60,-242.90,-480.50,2993.80,900.00}},
		{"Tierra Robada",               {-1213.90,596.30,-242.90,-480.50,1659.60,900.00}},
		{"San Fierro",                  {-2997.40,-1115.50,-242.90,-1213.90,1659.60,900.00}},
		{"Red County",                  {-1213.90,-768.00,-242.90,2997.00,596.30,900.00}},
		{"Flint County",                {-1213.90,-2892.90,-242.90,44.60,-768.00,900.00}},
		{"Whetstone",                   {-2997.40,-2892.90,-242.90,-1213.90,-1115.50,900.00}}
	};

new
	LockNames[4][32] = {"{2ECC71}Not Locked", "{E74C3C}Password Locked", "{E74C3C}Requires Keys", "{E74C3C}Owner Only"},
	TransactionNames[2][16] = {"{E74C3C}Taken", "{2ECC71}Added"};

stock LoadHouseKeys(playerid)
{
    Iter_Clear(HouseKeys[playerid]);

    new query[72];
    mysql_format(SQLHandle, query, sizeof(query), "SELECT * FROM housekeys WHERE Player='%e'", Player_GetName(playerid));
	mysql_tquery(SQLHandle, query, "GiveHouseKeys", "i", playerid);
	return 1;
}

stock GetZoneName(Float: x, Float: y, Float: z)
{
	new zone[28];
 	for(new i = 0; i < sizeof(SAZones); i++)
 	{
		if(x >= SAZones[i][SAZONE_AREA][0] && x <= SAZones[i][SAZONE_AREA][3] && y >= SAZones[i][SAZONE_AREA][1] && y <= SAZones[i][SAZONE_AREA][4] && z >= SAZones[i][SAZONE_AREA][2] && z <= SAZones[i][SAZONE_AREA][5])
		{
		    strcat(zone, SAZones[i][SAZONE_NAME]);
		    return zone;
		}
	}

	strcat(zone, "Unknown");
	return zone;
}

stock GetCityName(Float: x, Float: y, Float: z)
{
	new city[28];
	for(new i = 356; i < sizeof(SAZones); i++)
	{
		if(x >= SAZones[i][SAZONE_AREA][0] && x <= SAZones[i][SAZONE_AREA][3] && y >= SAZones[i][SAZONE_AREA][1] && y <= SAZones[i][SAZONE_AREA][4] && z >= SAZones[i][SAZONE_AREA][2] && z <= SAZones[i][SAZONE_AREA][5])
		{
		    strcat(city, SAZones[i][SAZONE_NAME]);
		    return city;
		}
	}

	strcat(city, "San Andreas");
	return city;
}

stock convertNumber(value)
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

stock RemovePlayerWeapon(playerid, weapon)
{
    new weapons[13], ammo[13];
    for(new i; i < 13; i++) GetPlayerWeaponData(playerid, i, weapons[i], ammo[i]);
    ResetPlayerWeapons(playerid);
    for(new i; i < 13; i++)
    {
        if(weapons[i] == weapon) continue;
        GivePlayerWeapon(playerid, weapons[i], ammo[i]);
    }

    return 1;
}

stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
	new Float: a;
	GetPlayerPos(playerid, x, y, a);
	GetPlayerFacingAngle(playerid, a);
	if (GetPlayerVehicleID(playerid)) GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

stock Player_GetName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}

stock SendToHouse(playerid, id)
{
    if(!Iter_Contains(Houses, id)) return 0;
    SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
    InHouse[playerid] = id;
	SetPlayerVirtualWorld(playerid, id);
 	SetPlayerInterior(playerid, HouseInteriors[ HouseData[id][Interior] ][intID]);
  	SetPlayerPos(playerid, HouseInteriors[ HouseData[id][Interior] ][intX], HouseInteriors[ HouseData[id][Interior] ][intY], HouseInteriors[ HouseData[id][Interior] ][intZ]);

	new string[128];
	format(string, sizeof(string), "Welcome to %s's house, %s{FFFFFF}!", HouseData[id][Owner], HouseData[id][Name]);
	SendClientMessage(playerid, 0xFFFFFFFF, string);

	if(!strcmp(HouseData[id][Owner], Player_GetName(playerid)))
	{
		HouseData[id][LastEntered] = gettime();
		HouseData[id][Save] = true;
		SendClientMessage(playerid, 0xFFFFFFFF, "Use {3498DB}/house {FFFFFF}to open the house menu.");
	}

	if(HouseData[id][LockMode] == LOCK_MODE_NOLOCK && LastVisitedHouse[playerid] != id)
	{
	    new query[128];
	    mysql_format(SQLHandle, query, sizeof(query), "INSERT INTO housevisitors SET HouseID=%d, Visitor='%e', Date=UNIX_TIMESTAMP()", id, Player_GetName(playerid));
		mysql_tquery(SQLHandle, query, "", "");
		LastVisitedHouse[playerid] = id;
	}

	return 1;
}

stock ShowHouseMenu(playerid)
{
	if(strcmp(HouseData[ InHouse[playerid] ][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");

	new string[256], id = InHouse[playerid];
	format(string, sizeof(string), "House Name: %s\nPassword: %s\nLock: %s\nHouse Safe {2ECC71}($%s)\nFurnitures\nGuns\nVisitors\nKeys\nKick Everybody\nSell House", HouseData[id][Name], HouseData[id][Password], LockNames[ HouseData[id][LockMode] ], convertNumber(HouseData[id][SafeMoney]));
	ShowPlayerDialog(playerid, DIALOG_HOUSE_MENU, DIALOG_STYLE_LIST, HouseData[id][Name], string, "Select", "Close");
	return 1;
}

stock ResetHouse(id)
{
    if(!Iter_Contains(Houses, id)) return 0;
	format(HouseData[id][Name], MAX_HOUSE_NAME, "House For Sale");
	format(HouseData[id][Owner], MAX_PLAYER_NAME, "-");
	format(HouseData[id][Password], MAX_HOUSE_PASSWORD, "-");
	HouseData[id][LockMode] = LOCK_MODE_NOLOCK;
	HouseData[id][SalePrice] = HouseData[id][SafeMoney] = HouseData[id][LastEntered] = 0;
    HouseData[id][Save] = true;

    new label[200];
    format(label, sizeof(label), "{2ECC71}House For Sale (ID: %d)\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", id, HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][Price]));
	UpdateDynamic3DTextLabelText(HouseData[id][HouseLabel], 0xFFFFFFFF, label);
	Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 1273);
	Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 31);

    foreach(new i : Player)
    {
        if(InHouse[i] == id)
        {
            SetPVarInt(i, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
        	SetPlayerVirtualWorld(i, 0);
	        SetPlayerInterior(i, 0);
	        SetPlayerPos(i, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
	        InHouse[i] = INVALID_HOUSE_ID;
        }

        if(Iter_Contains(HouseKeys[i], id)) Iter_Remove(HouseKeys[i], id);
   	}

    new query[64], data[e_furniture];
    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM houseguns WHERE HouseID=%d", id);
    mysql_tquery(SQLHandle, query, "", "");

    for(new i, maxval = Streamer_GetUpperBound(STREAMER_TYPE_OBJECT); i <= maxval; ++i)
    {
        if(!IsValidDynamicObject(i)) continue;
		Streamer_GetArrayData(STREAMER_TYPE_OBJECT, i, E_STREAMER_EXTRA_ID, data);
		if(data[SQLID] > 0 && data[HouseID] == id) DestroyDynamicObject(i);
    }

    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housefurnitures WHERE HouseID=%d", id);
    mysql_tquery(SQLHandle, query, "", "");

    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housevisitors WHERE HouseID=%d", id);
    mysql_tquery(SQLHandle, query, "", "");

    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housekeys WHERE HouseID=%d", id);
    mysql_tquery(SQLHandle, query, "", "");

    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housesafelogs WHERE HouseID=%d", id);
    mysql_tquery(SQLHandle, query, "", "");
	return 1;
}

stock SaveHouse(id)
{
    if(!Iter_Contains(Houses, id)) return 0;
	new query[256];
	mysql_format(SQLHandle, query, sizeof(query), "UPDATE houses SET HouseName='%e', HouseOwner='%e', HousePassword='%e', HouseSalePrice=%d, HouseLock=%d, HouseMoney=%d, LastEntered=%d WHERE ID=%d",
	HouseData[id][Name], HouseData[id][Owner], HouseData[id][Password], HouseData[id][SalePrice], HouseData[id][LockMode], HouseData[id][SafeMoney], HouseData[id][LastEntered], id);
	mysql_tquery(SQLHandle, query, "", "");
	HouseData[id][Save] = false;
	return 1;
}

stock UpdateHouseLabel(id)
{
	if(!Iter_Contains(Houses, id)) return 0;
	new label[256];
	if(!strcmp(HouseData[id][Owner], "-")) {
		format(label, sizeof(label), "{2ECC71}House For Sale (ID: %d)\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", id, HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][Price]));
	}else{
		if(HouseData[id][SalePrice] > 0) {
		    format(label, sizeof(label), "{E67E22}%s's House For Sale (ID: %d)\n{FFFFFF}%s\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", HouseData[id][Owner], id, HouseData[id][Name], HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][SalePrice]));
		}else{
			format(label, sizeof(label), "{E67E22}%s's House (ID: %d)\n{FFFFFF}%s\n{FFFFFF}%s\n%s\n{FFFFFF}%s", HouseData[id][Owner], id, HouseData[id][Name], HouseInteriors[ HouseData[id][Interior] ][IntName], LockNames[ HouseData[id][LockMode] ], HouseData[id][Address]);
		}
	}

	UpdateDynamic3DTextLabelText(HouseData[id][HouseLabel], 0xFFFFFFFF, label);
	return 1;
}

stock House_PlayerInit(playerid)
{
    InHouse[playerid] = LastVisitedHouse[playerid] = INVALID_HOUSE_ID;
    ListPage[playerid] = SelectMode[playerid] = SELECT_MODE_NONE;
    EditingFurniture[playerid] = false;
    LoadHouseKeys(playerid);
	return 1;
}

stock OwnedHouses(playerid)
{
	#if LIMIT_PER_PLAYER != 0
    new count;

	foreach(new i : Houses) if(!strcmp(HouseData[i][Owner], Player_GetName(playerid), true)) count++;
	return count;
	#else
	return 0;
	#endif
}

forward ResetAndSaveHouses();
forward LoadHouses();
forward LoadFurnitures();
forward GiveHouseKeys(playerid);
forward HouseSaleMoney(playerid);

public ResetAndSaveHouses()
{
	foreach(new i : Houses)
	{
	    if(HouseData[i][LastEntered] > 0 && gettime()-HouseData[i][LastEntered] > 604800) ResetHouse(i);
	    if(HouseData[i][Save]) SaveHouse(i);
	}

	return 1;
}

public LoadHouses()
{
	new rows = cache_num_rows();
 	if(rows)
  	{
   		new id, loaded, for_sale, label[256];
		while(loaded < rows)
		{
  			cache_get_value_name_int(loaded, "ID", id);
	    	cache_get_value_name(loaded, "HouseName", HouseData[id][Name], MAX_HOUSE_NAME);
		    cache_get_value_name(loaded, "HouseOwner", HouseData[id][Owner], MAX_PLAYER_NAME);
		    cache_get_value_name(loaded, "HousePassword", HouseData[id][Password], MAX_HOUSE_PASSWORD);
		    cache_get_value_name_float(loaded, "HouseX", HouseData[id][houseX]);
		    cache_get_value_name_float(loaded, "HouseY", HouseData[id][houseY]);
		    cache_get_value_name_float(loaded, "HouseZ", HouseData[id][houseZ]);
		    cache_get_value_name_int(loaded, "HousePrice", HouseData[id][Price]);
	     	cache_get_value_name_int(loaded, "HouseSalePrice", HouseData[id][SalePrice]);
		    cache_get_value_name_int(loaded, "HouseInterior", HouseData[id][Interior]);
		    cache_get_value_name_int(loaded, "HouseLock", HouseData[id][LockMode]);
		    cache_get_value_name_int(loaded, "HouseMoney", HouseData[id][SafeMoney]);
		    cache_get_value_name_int(loaded, "LastEntered", HouseData[id][LastEntered]);
			format(HouseData[id][Address], MAX_HOUSE_ADDRESS, "%d, %s, %s", id, GetZoneName(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]), GetCityName(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]));

	        if(strcmp(HouseData[id][Owner], "-")) {
	            if(HouseData[id][SalePrice] > 0) {
	                for_sale = 1;
				    format(label, sizeof(label), "{E67E22}%s's House For Sale (ID: %d)\n{FFFFFF}%s\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", HouseData[id][Owner], id, HouseData[id][Name], HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][SalePrice]));
				}else{
				    for_sale = 0;
					format(label, sizeof(label), "{E67E22}%s's House (ID: %d)\n{FFFFFF}%s\n{FFFFFF}%s\n%s\n{FFFFFF}%s", HouseData[id][Owner], id, HouseData[id][Name], HouseInteriors[ HouseData[id][Interior] ][IntName], LockNames[ HouseData[id][LockMode] ], HouseData[id][Address]);
				}
			}else{
			    for_sale = 1;
         		format(label, sizeof(label), "{2ECC71}House For Sale (ID: %d)\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", id, HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][Price]));
	        }

			HouseData[id][HousePickup] = CreateDynamicPickup((!for_sale) ? 19522 : 1273, 1, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
			HouseData[id][HouseIcon] = CreateDynamicMapIcon(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], (!for_sale) ? 32 : 31, 0);
			HouseData[id][HouseLabel] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]+0.35, 15.0, .testlos = 1);
			Iter_Add(Houses, id);
		    loaded++;
	    }

	    printf(" [House System] Loaded %d houses.", loaded);
	}

	return 1;
}

public LoadFurnitures()
{
	new rows = cache_num_rows();
 	if(rows)
  	{
   		new id, loaded, vw, interior, data[e_furniture];
     	while(loaded < rows)
      	{
       		cache_get_value_name_int(loaded, "ID", data[SQLID]);
         	cache_get_value_name_int(loaded, "HouseID", data[HouseID]);
         	cache_get_value_name_int(loaded, "FurnitureID", data[ArrayID]);
          	cache_get_value_name_float(loaded, "FurnitureX", data[furnitureX]);
           	cache_get_value_name_float(loaded, "FurnitureY", data[furnitureY]);
            cache_get_value_name_float(loaded, "FurnitureZ", data[furnitureZ]);
            cache_get_value_name_float(loaded, "FurnitureRX", data[furnitureRX]);
            cache_get_value_name_float(loaded, "FurnitureRY", data[furnitureRY]);
            cache_get_value_name_float(loaded, "FurnitureRZ", data[furnitureRZ]);
            cache_get_value_name_int(loaded, "FurnitureVW", vw);
            cache_get_value_name_int(loaded, "FurnitureInt", interior);

			id = CreateDynamicObject(
   				HouseFurnitures[ data[ArrayID] ][ModelID],
       			data[furnitureX], data[furnitureY], data[furnitureZ],
          		data[furnitureRX], data[furnitureRY], data[furnitureRZ],
				vw, interior
			);

			Streamer_SetArrayData(STREAMER_TYPE_OBJECT, id, E_STREAMER_EXTRA_ID, data);
   			loaded++;
 		}

 		printf(" [House System] Loaded %d furnitures.", loaded);
   	}

	return 1;
}

public GiveHouseKeys(playerid)
{
	if(!IsPlayerConnected(playerid)) return 1;
	new rows = cache_num_rows();
 	if(rows)
  	{
   		new loaded, house_id;
     	while(loaded < rows)
      	{
      	    cache_get_value_name_int(loaded, "HouseID", house_id);
       		Iter_Add(HouseKeys[playerid], house_id);
   			loaded++;
 		}
   	}

	return 1;
}

public HouseSaleMoney(playerid)
{
    new rows = cache_num_rows();
 	if(rows)
  	{
   		new new_owner[MAX_PLAYER_NAME], price, tnid, string[128];
		for(new i; i < rows; i++)
		{
	    	cache_get_value_name(i, "NewOwner", new_owner);
		    cache_get_value_name_int(i, "Price", price);
            cache_get_value_name_int(i, "ID", tnid);

			format(string, sizeof(string), "You sold a house to %s for $%s. (Transaction ID: #%d)", new_owner, convertNumber(price), tnid);
			SendClientMessage(playerid, -1, string);
			GivePlayerMoney(playerid, price);
	    }

		new query[128];
	    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housesales WHERE OldOwner='%e'", Player_GetName(playerid));
	    mysql_tquery(SQLHandle, query, "", "");
	}

	return 1;
}

public OnFilterScriptInit()
{
	for(new i; i < MAX_HOUSES; ++i)
	{
		HouseData[i][HouseLabel] = Text3D: INVALID_3DTEXT_ID;
		HouseData[i][HousePickup] = -1;
		HouseData[i][HouseIcon] = -1;
		HouseData[i][Save] = false;
	}

	for(new i; i < sizeof(HouseInteriors); ++i)
	{
	    HouseInteriors[i][intLabel] = CreateDynamic3DTextLabel("Leave House", 0xE67E22FF, HouseInteriors[i][intX], HouseInteriors[i][intY], HouseInteriors[i][intZ]+0.35, 10.0, .testlos = 1, .interiorid = HouseInteriors[i][intID]);
		HouseInteriors[i][intPickup] = CreateDynamicPickup(1318, 1, HouseInteriors[i][intX], HouseInteriors[i][intY], HouseInteriors[i][intZ], .interiorid = HouseInteriors[i][intID]);
	}

	Iter_Init(HouseKeys);
	DisableInteriorEnterExits();
	SQLHandle = mysql_connect(SQL_HOST, SQL_USER, SQL_PASSWORD, SQL_DBNAME);
	mysql_log(ERROR | WARNING);
	if(mysql_errno() != 0) return print(" [House System] Can't connect to MySQL.");

	/* Create Tables */
	new query[1024];
	strcat(query, "CREATE TABLE IF NOT EXISTS `houses` (\
	  `ID` int(11) NOT NULL,\
	  `HouseName` varchar(48) NOT NULL default 'House For Sale',\
	  `HouseOwner` varchar(24) NOT NULL default '-',\
	  `HousePassword` varchar(16) NOT NULL default '-',\
	  `HouseX` float NOT NULL,\
	  `HouseY` float NOT NULL,\
	  `HouseZ` float NOT NULL,\
	  `HousePrice` int(11) NOT NULL,\
	  `HouseInterior` tinyint(4) NOT NULL default '0',\
	  `HouseLock` tinyint(4) NOT NULL default '0',\
	  `HouseMoney` int(11) NOT NULL default '0',"
 	);

 	strcat(query, "`LastEntered` int(11) NOT NULL,\
		  PRIMARY KEY  (`ID`),\
		  UNIQUE KEY `ID_2` (`ID`),\
		  KEY `ID` (`ID`)\
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
	);

	mysql_tquery(SQLHandle, query, "", "");

	mysql_tquery(SQLHandle, "CREATE TABLE IF NOT EXISTS `housefurnitures` (\
	  `ID` int(11) NOT NULL auto_increment,\
	  `HouseID` int(11) NOT NULL,\
	  `FurnitureID` tinyint(11) NOT NULL,\
	  `FurnitureX` float NOT NULL,\
	  `FurnitureY` float NOT NULL,\
	  `FurnitureZ` float NOT NULL,\
	  `FurnitureRX` float NOT NULL,\
	  `FurnitureRY` float NOT NULL,\
	  `FurnitureRZ` float NOT NULL,\
	  `FurnitureVW` int(11) NOT NULL,\
	  `FurnitureInt` int(11) NOT NULL,\
	  PRIMARY KEY  (`ID`)\
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;", "", "");

	mysql_tquery(SQLHandle, "CREATE TABLE IF NOT EXISTS `houseguns` (\
	  `HouseID` int(11) NOT NULL,\
	  `WeaponID` tinyint(4) NOT NULL,\
	  `Ammo` int(11) NOT NULL,\
	  UNIQUE KEY `HouseID_2` (`HouseID`,`WeaponID`),\
	  KEY `HouseID` (`HouseID`),\
	  CONSTRAINT `houseguns_ibfk_1` FOREIGN KEY (`HouseID`) REFERENCES `houses` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE\
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;", "", "");

	mysql_tquery(SQLHandle, "CREATE TABLE IF NOT EXISTS `housevisitors` (\
	  `HouseID` int(11) NOT NULL,\
	  `Visitor` varchar(24) NOT NULL,\
	  `Date` int(11) NOT NULL\
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;", "", "");

	mysql_tquery(SQLHandle, "CREATE TABLE IF NOT EXISTS `housekeys` (\
	  `HouseID` int(11) NOT NULL,\
	  `Player` varchar(24) NOT NULL,\
	  `Date` int(11) NOT NULL\
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;", "", "");

	mysql_tquery(SQLHandle, "CREATE TABLE IF NOT EXISTS `housesafelogs` (\
	  `HouseID` int(11) NOT NULL,\
	  `Type` int(11) NOT NULL,\
	  `Amount` int(11) NOT NULL,\
	  `Date` int(11) NOT NULL\
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;", "", "");

	mysql_tquery(SQLHandle, "CREATE TABLE IF NOT EXISTS `housesales` (\
	  `ID` int(11) NOT NULL AUTO_INCREMENT,\
	  `OldOwner` varchar(24) NOT NULL,\
	  `NewOwner` varchar(24) NOT NULL,\
	  `Price` int(11) NOT NULL,\
	  PRIMARY KEY (`ID`)\
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;", "", "");

	// 1.3 update, add HouseSalePrice to the houses table
	if(!fexist("house_updated.txt"))
	{
		mysql_tquery(SQLHandle, "ALTER TABLE houses ADD HouseSalePrice INT(11) NOT NULL AFTER HousePrice");

		new File: updateFile = fopen("house_updated.txt", io_append);
		if(updateFile)
		{
		    fwrite(updateFile, "Don't remove this file.");
			fclose(updateFile);
		}
	}

	/* Loading & Stuff */
	mysql_tquery(SQLHandle, "SELECT * FROM houses", "LoadHouses", "");
	mysql_tquery(SQLHandle, "SELECT * FROM housefurnitures", "LoadFurnitures", "");
	foreach(new i : Player) House_PlayerInit(i);

	HouseTimer = SetTimer("ResetAndSaveHouses", 10 * 60000, true);
	return 1;
}

public OnFilterScriptExit()
{
	foreach(new i : Houses) if(HouseData[i][Save]) SaveHouse(i);
	KillTimer(HouseTimer);
	return 1;
}

public OnPlayerConnect(playerid)
{
    House_PlayerInit(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	InHouse[playerid] = INVALID_HOUSE_ID;

	new query[128];
	mysql_format(SQLHandle, query, sizeof(query), "SELECT * FROM housesales WHERE OldOwner='%e'", Player_GetName(playerid));
	mysql_tquery(SQLHandle, query, "HouseSaleMoney", "i", playerid);
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	if(GetPVarInt(playerid, "HousePickupCooldown") < gettime())
	{
	    if(InHouse[playerid] == INVALID_HOUSE_ID) {
			foreach(new i : Houses)
			{
			    if(pickupid == HouseData[i][HousePickup])
			    {
			        SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
			        SetPVarInt(playerid, "PickupHouseID", i);

					if(!strcmp(HouseData[i][Owner], "-")) {
						new string[64];
						format(string, sizeof(string), "This house is for sale!\n\nPrice: {2ECC71}$%s", convertNumber(HouseData[i][Price]));
						ShowPlayerDialog(playerid, DIALOG_BUY_HOUSE, DIALOG_STYLE_MSGBOX, "House For Sale", string, "Buy", "Close");
					}else{
					    if(HouseData[i][SalePrice] > 0 && strcmp(HouseData[i][Owner], Player_GetName(playerid)))
					    {
                            new string[64];
							format(string, sizeof(string), "This house is for sale!\n\nPrice: {2ECC71}$%s", convertNumber(HouseData[i][SalePrice]));
							ShowPlayerDialog(playerid, DIALOG_BUY_HOUSE_FROM_OWNER, DIALOG_STYLE_MSGBOX, "House For Sale", string, "Buy", "Close");
							return 1;
					    }

					    switch(HouseData[i][LockMode])
					    {
					        case LOCK_MODE_NOLOCK: SendToHouse(playerid, i);
					        case LOCK_MODE_PASSWORD: ShowPlayerDialog(playerid, DIALOG_HOUSE_PASSWORD, DIALOG_STYLE_INPUT, "House Password", "This house is password protected.\n\nEnter house password:", "Done", "Close");
							case LOCK_MODE_KEYS:
							{
							    new gotkeys = Iter_Contains(HouseKeys[playerid], i);
							    if(!gotkeys) if(!strcmp(HouseData[i][Owner], Player_GetName(playerid))) gotkeys = 1;

								if(gotkeys) {
									SendToHouse(playerid, i);
								}else{
								    SendClientMessage(playerid, 0xE74C3CFF, "You don't have keys for this house, you can't enter.");
								}
							}

					        case LOCK_MODE_OWNER:
					        {
								if(!strcmp(HouseData[i][Owner], Player_GetName(playerid))) {
								    SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
						            SendToHouse(playerid, i);
								}else{
								    SendClientMessage(playerid, 0xE74C3CFF, "Sorry, only the owner can enter this house.");
								}
					        }
					    }
					}

			        return 1;
			    }
			}
		}else{
			for(new i; i < sizeof(HouseInteriors); ++i)
			{
			    if(pickupid == HouseInteriors[i][intPickup])
			    {
			        SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
			        SetPlayerVirtualWorld(playerid, 0);
			        SetPlayerInterior(playerid, 0);
			        SetPlayerPos(playerid, HouseData[ InHouse[playerid] ][houseX], HouseData[ InHouse[playerid] ][houseY], HouseData[ InHouse[playerid] ][houseZ]);
			        InHouse[playerid] = INVALID_HOUSE_ID;
			        return 1;
			    }
			}
		}
	}

	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_BUY_HOUSE)
	{
		if(!response) return 1;
		new id = GetPVarInt(playerid, "PickupHouseID");
		if(!IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ])) return SendClientMessage(playerid, 0xE74C3CFF, "You're not near any house.");
        #if LIMIT_PER_PLAYER > 0
		if(OwnedHouses(playerid) + 1 > LIMIT_PER_PLAYER) return SendClientMessage(playerid, 0xE74C3CFF, "You can't buy any more houses.");
		#endif
		if(HouseData[id][Price] > GetPlayerMoney(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't afford this house.");
		if(strcmp(HouseData[id][Owner], "-")) return SendClientMessage(playerid, 0xE74C3CFF, "Someone already owns this house.");
		GivePlayerMoney(playerid, -HouseData[id][Price]);
		GetPlayerName(playerid, HouseData[id][Owner], MAX_PLAYER_NAME);
		HouseData[id][LastEntered] = gettime();
		HouseData[id][Save] = true;

		UpdateHouseLabel(id);
		Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 19522);
		Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 32);
		SendToHouse(playerid, id);
		return 1;
	}

	if(dialogid == DIALOG_HOUSE_PASSWORD)
	{
	    if(!response) return 1;
	    new id = GetPVarInt(playerid, "PickupHouseID");
		if(!IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ])) return SendClientMessage(playerid, 0xE74C3CFF, "You're not near any house.");
		if(!(1 <= strlen(inputtext) <= MAX_HOUSE_PASSWORD)) return ShowPlayerDialog(playerid, DIALOG_HOUSE_PASSWORD, DIALOG_STYLE_INPUT, "House Password", "This house is password protected.\n\nEnter house password:\n\n{E74C3C}The password you entered is either too short or too long.", "Try Again", "Close");
		if(strcmp(HouseData[id][Password], inputtext)) return ShowPlayerDialog(playerid, DIALOG_HOUSE_PASSWORD, DIALOG_STYLE_INPUT, "House Password", "This house is password protected.\n\nEnter house password:\n\n{E74C3C}Wrong password.", "Try Again", "Close");
		SendToHouse(playerid, id);
		return 1;
	}

	if(dialogid == DIALOG_HOUSE_MENU)
	{
	    if(!response) return 1;
	    new id = InHouse[playerid];
	    if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");

		if(listitem == 0) ShowPlayerDialog(playerid, DIALOG_HOUSE_NAME, DIALOG_STYLE_INPUT, "House Name", "Write a new name for this house:", "Change", "Back");
		if(listitem == 1) ShowPlayerDialog(playerid, DIALOG_HOUSE_NEW_PASSWORD, DIALOG_STYLE_INPUT, "House Password", "Write a new password for this house:", "Change", "Back");
		if(listitem == 2) ShowPlayerDialog(playerid, DIALOG_HOUSE_LOCK, DIALOG_STYLE_LIST, "House Lock", "Not Locked\nPassword Lock\nKeys\nOwner Only", "Change", "Back");
		if(listitem == 3)
		{
		    if(HouseData[id][SalePrice] > 0)
			{
				SendClientMessage(playerid, 0xE74C3CFF, "You can't use this feature while the house is for sale.");
				return ShowHouseMenu(playerid);
			}

		    new string[144];
		    format(string, sizeof(string), "Take Money From Safe {2ECC71}($%s)\nPut Money To Safe {2ECC71}($%s)\nView Safe History\nClear Safe History", convertNumber(HouseData[id][SafeMoney]), convertNumber(GetPlayerMoney(playerid)));
			ShowPlayerDialog(playerid, DIALOG_SAFE_MENU, DIALOG_STYLE_LIST, "House Safe", string, "Choose", "Back");
		}

		if(listitem == 4)
		{
		    if(HouseData[id][SalePrice] > 0)
			{
				SendClientMessage(playerid, 0xE74C3CFF, "You can't use this feature while the house is for sale.");
				return ShowHouseMenu(playerid);
			}

			ShowPlayerDialog(playerid, DIALOG_FURNITURE_MENU, DIALOG_STYLE_LIST, "Furnitures", "Buy Furniture\nEdit Furniture\nSell Furniture\nSell All Furnitures", "Choose", "Back");
		}

		if(listitem == 5) ShowPlayerDialog(playerid, DIALOG_GUNS_MENU, DIALOG_STYLE_LIST, "Guns", "Put Gun\nTake Gun", "Choose", "Back");
        if(listitem == 6)
		{
		    ListPage[playerid] = 0;
			ShowPlayerDialog(playerid, DIALOG_VISITORS_MENU, DIALOG_STYLE_LIST, "Visitors", "Look Visitor History\nClear Visitor History", "Choose", "Back");
		}

		if(listitem == 7)
		{
		    ListPage[playerid] = 0;
			ShowPlayerDialog(playerid, DIALOG_KEYS_MENU, DIALOG_STYLE_LIST, "Keys", "View Key Owners\nChange Locks", "Choose", "Back");
		}

		if(listitem == 8)
		{
		    new string[128];
		    format(string, sizeof(string), "House owner %s kicked everybody from the house.", HouseData[id][Owner]);

			foreach(new i : Player)
			{
			    if(i == playerid) continue;
			    if(InHouse[i] == id)
			    {
		            SetPVarInt(i, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
		        	SetPlayerVirtualWorld(i, 0);
			        SetPlayerInterior(i, 0);
			        SetPlayerPos(i, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
			        InHouse[i] = INVALID_HOUSE_ID;
			        SendClientMessage(i, -1, string);
			    }
			}

			SendClientMessage(playerid, -1, "You kicked everybody from your house.");
		}

		if(listitem == 9)
		{
		    new string[128];
		    format(string, sizeof(string), "Sell Instantly\t{2ECC71}$%s\n%s", convertNumber(floatround(HouseData[id][Price]*0.85)), (HouseData[id][SalePrice] > 0) ? ("Remove From Sale") : ("Put For Sale"));
			ShowPlayerDialog(playerid, DIALOG_SELL_HOUSE, DIALOG_STYLE_TABLIST, "Sell House", string, "Choose", "Back");
		}

		return 1;
	}

	if(dialogid == DIALOG_HOUSE_NAME)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(!(1 <= strlen(inputtext) <= MAX_HOUSE_NAME)) return ShowPlayerDialog(playerid, DIALOG_HOUSE_NAME, DIALOG_STYLE_INPUT, "House Name", "Write a new name for this house:\n\n{E74C3C}The name you entered is either too short or too long.", "Change", "Back");
        format(HouseData[id][Name], MAX_HOUSE_NAME, "%s", inputtext);
        HouseData[id][Save] = true;

        UpdateHouseLabel(id);
        ShowHouseMenu(playerid);
	    return 1;
	}

	if(dialogid == DIALOG_HOUSE_NEW_PASSWORD)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(!(1 <= strlen(inputtext) <= MAX_HOUSE_PASSWORD)) return ShowPlayerDialog(playerid, DIALOG_HOUSE_NEW_PASSWORD, DIALOG_STYLE_INPUT, "House Password", "Write a new password for this house:\n\n{E74C3C}The pasword you entered is either too short or too long.", "Change", "Back");
        format(HouseData[id][Password], MAX_HOUSE_PASSWORD, "%s", inputtext);
        HouseData[id][Save] = true;
        ShowHouseMenu(playerid);
	    return 1;
	}

	if(dialogid == DIALOG_HOUSE_LOCK)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		HouseData[id][LockMode] = listitem;
		HouseData[id][Save] = true;

		UpdateHouseLabel(id);
        ShowHouseMenu(playerid);
	    return 1;
	}

	if(dialogid == DIALOG_SAFE_MENU)
	{
	    if(!response) return ShowHouseMenu(playerid);
	    new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this feature while the house is for sale.");
		if(listitem == 0) ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "Safe: Take Money", "Write the amount you want to take from safe:", "Take", "Back");
		if(listitem == 1) ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "Safe: Put Money", "Write the amount you want to put to safe:", "Put", "Back");
        if(listitem == 2)
        {
			ListPage[playerid] = 0;

            new query[200], Cache: safelog;
		    mysql_format(SQLHandle, query, sizeof(query), "SELECT Type, Amount, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as TransactionDate FROM housesafelogs WHERE HouseID=%d ORDER BY Date DESC LIMIT 0, 15", id);
			safelog = mysql_query(SQLHandle, query);
			new rows = cache_num_rows();
			if(rows) {
			    new list[1024], type, amount, date[20];
			    format(list, sizeof(list), "Action\tDate\n");
			    for(new i; i < rows; ++i)
			    {
			        cache_get_value_name_int(i, "Type", type);
		        	cache_get_value_name_int(i, "Amount", amount);
		        	cache_get_value_name(i, "TransactionDate", date);

			        format(list, sizeof(list), "%s%s $%s\t{FFFFFF}%s\n", list, TransactionNames[type], convertNumber(amount), date);
			    }

			    ShowPlayerDialog(playerid, DIALOG_SAFE_HISTORY, DIALOG_STYLE_TABLIST_HEADERS, "Safe History (Page 1)", list, "Next", "Previous");
			}else{
				SendClientMessage(playerid, 0xE74C3CFF, "Can't find any safe history.");
			}

		    cache_delete(safelog);
        }

        if(listitem == 3)
		{
		    new query[64];
		    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housesafelogs WHERE HouseID=%d", id);
    		mysql_tquery(SQLHandle, query, "", "");
    		ShowHouseMenu(playerid);
		}

		return 1;
	}

	if(dialogid == DIALOG_SAFE_TAKE)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this feature while the house is for sale.");
        new amount = strval(inputtext);
		if(!(1 <= amount <= 10000000)) return ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "Safe: Take Money", "Write the amount you want to take from safe:\n\n{E74C3C}Invalid amount. You can take between $1 - $10,000,000 at a time.", "Take", "Back");
		if(amount > HouseData[id][SafeMoney]) return ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "Safe: Take Money", "Write the amount you want to take from safe:\n\n{E74C3C}You don't have that much money in your safe.", "Take", "Back");
        new query[128];
		mysql_format(SQLHandle, query, sizeof(query), "INSERT INTO housesafelogs SET HouseID=%d, Type=0, Amount=%d, Date=UNIX_TIMESTAMP()", id, amount);
		mysql_tquery(SQLHandle, query, "", "");

		GivePlayerMoney(playerid, amount);
		HouseData[id][SafeMoney] -= amount;
		HouseData[id][Save] = true;
		ShowHouseMenu(playerid);
	    return 1;
	}

	if(dialogid == DIALOG_SAFE_PUT)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
        new amount = strval(inputtext);
		if(!(1 <= amount <= 10000000)) return ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "Safe: Put Money", "Write the amount you want to put to safe:\n\n{E74C3C}Invalid amount. You can put between $1 - $10,000,000 at a time.", "Put", "Back");
		if(amount > GetPlayerMoney(playerid)) return ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "Safe: Put Money", "Write the amount you want to put to safe:\n\n{E74C3C}You don't have that much money on you.", "Put", "Back");
        new query[128];
		mysql_format(SQLHandle, query, sizeof(query), "INSERT INTO housesafelogs SET HouseID=%d, Type=1, Amount=%d, Date=UNIX_TIMESTAMP()", id, amount);
		mysql_tquery(SQLHandle, query, "", "");

		GivePlayerMoney(playerid, -amount);
		HouseData[id][SafeMoney] += amount;
		HouseData[id][Save] = true;
		ShowHouseMenu(playerid);
	    return 1;
	}

	if(dialogid == DIALOG_GUNS_MENU)
	{
		if(!response) return ShowHouseMenu(playerid);
		new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(listitem == 0)
		{
			if(GetPlayerWeapon(playerid) == 0) return SendClientMessage(playerid, 0xE74C3CFF, "You can't put your fists in your house.");
			new query[128], weapon = GetPlayerWeapon(playerid), ammo = GetPlayerAmmo(playerid);
            RemovePlayerWeapon(playerid, weapon);
			mysql_format(SQLHandle, query, sizeof(query), "INSERT INTO houseguns VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE Ammo=Ammo+%d", id, weapon, ammo, ammo);
			mysql_tquery(SQLHandle, query, "", "");
			ShowHouseMenu(playerid);
		}

		if(listitem == 1)
		{
		    new query[80], Cache: weapons;
		    mysql_format(SQLHandle, query, sizeof(query), "SELECT WeaponID, Ammo FROM houseguns WHERE HouseID=%d ORDER BY WeaponID ASC", id);
			weapons = mysql_query(SQLHandle, query);
			new rows = cache_num_rows();
			if(rows) {
			    new list[512], weapname[32], weapon_id, weapon_ammo;
			    format(list, sizeof(list), "#\tWeapon Name\tAmmo\n");
			    for(new i; i < rows; ++i)
			    {
			        cache_get_value_name_int(i, "WeaponID", weapon_id);
			        cache_get_value_name_int(i, "Ammo", weapon_ammo);

			        GetWeaponName(weapon_id, weapname, sizeof(weapname));
			        format(list, sizeof(list), "%s%d\t%s\t%s\n", list, i+1, weapname, convertNumber(weapon_ammo));
			    }

			    ShowPlayerDialog(playerid, DIALOG_GUNS_TAKE, DIALOG_STYLE_TABLIST_HEADERS, "House Guns", list, "Take", "Back");
			}else{
				SendClientMessage(playerid, 0xE74C3CFF, "You don't have any guns in your house.");
			}

		    cache_delete(weapons);
		}

		return 1;
	}

	if(dialogid == DIALOG_GUNS_TAKE)
	{
		if(!response) return ShowHouseMenu(playerid);
		new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
  		new query[96], Cache: weapon;
    	mysql_format(SQLHandle, query, sizeof(query), "SELECT WeaponID, Ammo FROM houseguns WHERE HouseID=%d ORDER BY WeaponID ASC LIMIT %d, 1", id, listitem);
		weapon = mysql_query(SQLHandle, query);
		new rows = cache_num_rows();
		if(rows) {
  			new string[64], weapname[32], weaponid, ammo;
  			cache_get_value_name_int(0, "WeaponID", weaponid);
  			cache_get_value_name_int(0, "Ammo", ammo);

  			GetWeaponName(weaponid, weapname, sizeof(weapname));
  			GivePlayerWeapon(playerid, weaponid, ammo);
			format(string, sizeof(string), "You've taken a %s from your house.", weapname);
			SendClientMessage(playerid, 0xFFFFFFFF, string);
			mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM houseguns WHERE HouseID=%d AND WeaponID=%d", id, weaponid);
			mysql_tquery(SQLHandle, query, "", "");
		}else{
			SendClientMessage(playerid, 0xE74C3CFF, "Can't find that weapon.");
		}

		cache_delete(weapon);
		return 1;
	}

    if(dialogid == DIALOG_FURNITURE_MENU)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this feature while the house is for sale.");

		if(listitem == 0)
		{
		    new list[512];
		    format(list, sizeof(list), "#\tFurniture Name\tPrice\n");
		    for(new i; i < sizeof(HouseFurnitures); ++i)
		    {
		        format(list, sizeof(list), "%s%d\t%s\t$%s\n", list, i+1, HouseFurnitures[i][Name], convertNumber(HouseFurnitures[i][Price]));
		    }

		    ShowPlayerDialog(playerid, DIALOG_FURNITURE_BUY, DIALOG_STYLE_TABLIST_HEADERS, "Buy Furniture", list, "Buy", "Back");
		}

		if(listitem == 1)
		{
			SelectMode[playerid] = SELECT_MODE_EDIT;
		    SelectObject(playerid);
		    SendClientMessage(playerid, 0xFFFFFFFF, "Click on the furniture you want to edit.");
		}

		if(listitem == 2)
		{
		    SelectMode[playerid] = SELECT_MODE_SELL;
		    SelectObject(playerid);
		    SendClientMessage(playerid, 0xFFFFFFFF, "Click on the furniture you want to sell.");
		}

		if(listitem == 3)
		{
		    new money, sold, data[e_furniture], query[64];
		    for(new i; i < Streamer_GetUpperBound(STREAMER_TYPE_OBJECT); ++i)
		    {
		        if(!IsValidDynamicObject(i)) continue;
				Streamer_GetArrayData(STREAMER_TYPE_OBJECT, i, E_STREAMER_EXTRA_ID, data);
				if(data[SQLID] > 0 && data[HouseID] == id)
				{
				    sold++;
				    money += HouseFurnitures[ data[ArrayID] ][Price];
					DestroyDynamicObject(i);
				}
		    }

		    new string[64];
		    format(string, sizeof(string), "Sold %d furnitures for $%s.", sold, convertNumber(money));
		    SendClientMessage(playerid, -1, string);
		    GivePlayerMoney(playerid, money);

		    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housefurnitures WHERE HouseID=%d", id);
		    mysql_tquery(SQLHandle, query, "", "");
		}

	    return 1;
	}

	if(dialogid == DIALOG_FURNITURE_BUY)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this feature while the house is for sale.");
		if(HouseFurnitures[listitem][Price] > GetPlayerMoney(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't afford this furniture.");
		GivePlayerMoney(playerid, -HouseFurnitures[listitem][Price]);
		new Float: x, Float: y, Float: z;
		GetPlayerPos(playerid, x, y, z);
        GetXYInFrontOfPlayer(playerid, x, y, 3.0);
        new objectid = CreateDynamicObject(HouseFurnitures[listitem][ModelID], x, y, z, 0.0, 0.0, 0.0, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid)), query[256];
		mysql_format(SQLHandle, query, sizeof(query), "INSERT INTO housefurnitures SET HouseID=%d, FurnitureID=%d, FurnitureX=%f, FurnitureY=%f, FurnitureZ=%f, FurnitureVW=%d, FurnitureInt=%d", id, listitem, x, y, z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
        new Cache: add = mysql_query(SQLHandle, query), data[e_furniture];
        data[SQLID] = cache_insert_id();
		data[HouseID] = id;
        data[ArrayID] = listitem;
		data[furnitureX] = x;
		data[furnitureY] = y;
		data[furnitureZ] = z;
		data[furnitureRX] = 0.0;
		data[furnitureRY] = 0.0;
		data[furnitureRZ] = 0.0;
		cache_delete(add);
		Streamer_SetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);

		EditingFurniture[playerid] = true;
		EditDynamicObject(playerid, objectid);
		return 1;
	}

	if(dialogid == DIALOG_FURNITURE_SELL)
	{
	    if(!response) return 1;
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this feature while the house is for sale.");
		new objectid = GetPVarInt(playerid, "SelectedFurniture"), query[64], data[e_furniture];
		Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
		GivePlayerMoney(playerid, HouseFurnitures[ data[ArrayID] ][Price]);
		mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housefurnitures WHERE ID=%d", data[SQLID]);
		mysql_tquery(SQLHandle, query, "", "");
		DestroyDynamicObject(objectid);
		DeletePVar(playerid, "SelectedFurniture");
		return 1;
	}

	if(dialogid == DIALOG_VISITORS_MENU)
	{
		if(!response) return ShowHouseMenu(playerid);
		new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(listitem == 0)
		{
		    new query[200], Cache: visitors;
		    mysql_format(SQLHandle, query, sizeof(query), "SELECT Visitor, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as VisitDate FROM housevisitors WHERE HouseID=%d ORDER BY Date DESC LIMIT 0, 15", id);
			visitors = mysql_query(SQLHandle, query);
			new rows = cache_num_rows();
			if(rows) {
			    new list[1024], visitor_name[MAX_PLAYER_NAME], visit_date[20];
			    format(list, sizeof(list), "Visitor Name\tDate\n");
			    for(new i; i < rows; ++i)
			    {
			        cache_get_value_name(i, "Visitor", visitor_name);
			        cache_get_value_name(i, "VisitDate", visit_date);
			        format(list, sizeof(list), "%s%s\t%s\n", list, visitor_name, visit_date);
			    }

			    ShowPlayerDialog(playerid, DIALOG_VISITORS, DIALOG_STYLE_TABLIST_HEADERS, "House Visitors (Page 1)", list, "Next", "Previous");
			}else{
				SendClientMessage(playerid, 0xE74C3CFF, "You didn't had any visitors.");
			}

		    cache_delete(visitors);
		}

		if(listitem == 1)
		{
		    new query[64];
		    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housevisitors WHERE HouseID=%d", id);
    		mysql_tquery(SQLHandle, query, "", "");
    		ShowHouseMenu(playerid);
		}

		return 1;
	}

	if(dialogid == DIALOG_VISITORS)
	{
		if(!response) {
			ListPage[playerid]--;
			if(ListPage[playerid] < 0)
			{
			    ListPage[playerid] = 0;
			    ShowHouseMenu(playerid);
			    return 1;
			}
		}else{
		    ListPage[playerid]++;
		}

		new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
  		new query[200], Cache: visitors;
    	mysql_format(SQLHandle, query, sizeof(query), "SELECT Visitor, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as VisitDate FROM housevisitors WHERE HouseID=%d ORDER BY Date DESC LIMIT %d, 15", id, ListPage[playerid]*15);
		visitors = mysql_query(SQLHandle, query);
		new rows = cache_num_rows();
		if(rows) {
  			new list[1024], visitor_name[MAX_PLAYER_NAME], visit_date[20];
	    	format(list, sizeof(list), "Visitor Name\tDate\n");
		    for(new i; i < rows; ++i)
		    {
      			cache_get_value_name(i, "Visitor", visitor_name);
	        	cache_get_value_name(i, "VisitDate", visit_date);
		        format(list, sizeof(list), "%s%s\t%s\n", list, visitor_name, visit_date);
		    }

			new title[32];
			format(title, sizeof(title), "House Visitors (Page %d)", ListPage[playerid]+1);
			ShowPlayerDialog(playerid, DIALOG_VISITORS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
		}else{
			SendClientMessage(playerid, 0xE74C3CFF, "Can't find any more visitors.");
			ListPage[playerid] = 0;
   			ShowHouseMenu(playerid);
		}

		cache_delete(visitors);
		return 1;
	}

	if(dialogid == DIALOG_KEYS_MENU)
	{
		if(!response) return ShowHouseMenu(playerid);
		new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(listitem == 0)
		{
		    new query[200], Cache: keyowners;
		    mysql_format(SQLHandle, query, sizeof(query), "SELECT Player, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as KeyDate FROM housekeys WHERE HouseID=%d ORDER BY Date DESC LIMIT %d, 15", id, ListPage[playerid]*15);
			keyowners = mysql_query(SQLHandle, query);
			new rows = cache_num_rows();
			if(rows) {
			    new list[1024], key_name[MAX_PLAYER_NAME], key_date[20];
			    format(list, sizeof(list), "Key Owner\tKey Given On\n");
			    for(new i; i < rows; ++i)
			    {
			        cache_get_value_name(i, "Player", key_name);
			        cache_get_value_name(i, "KeyDate", key_date);
			        format(list, sizeof(list), "%s%s\t%s\n", list, key_name, key_date);
			    }

			    ShowPlayerDialog(playerid, DIALOG_KEYS, DIALOG_STYLE_TABLIST_HEADERS, "Key Owners (Page 1)", list, "Next", "Previous");
			}else{
				SendClientMessage(playerid, 0xE74C3CFF, "Can't find any key owners.");
			}

		    cache_delete(keyowners);
		}

		if(listitem == 1)
		{
		    foreach(new i : Player)
		    {
		        if(Iter_Contains(HouseKeys[i], id)) Iter_Remove(HouseKeys[i], id);
		    }

		    new query[64];
		    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housekeys WHERE HouseID=%d", id);
    		mysql_tquery(SQLHandle, query, "", "");
    		ShowHouseMenu(playerid);
		}

		return 1;
	}

	if(dialogid == DIALOG_KEYS)
	{
	    if(!response) {
			ListPage[playerid]--;
			if(ListPage[playerid] < 0)
			{
			    ListPage[playerid] = 0;
			    ShowHouseMenu(playerid);
			    return 1;
			}
		}else{
		    ListPage[playerid]++;
		}

		new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
        new query[200], Cache: keyowners;
  		mysql_format(SQLHandle, query, sizeof(query), "SELECT Player, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as KeyDate FROM housekeys WHERE HouseID=%d ORDER BY Date DESC LIMIT %d, 15", id, ListPage[playerid]*15);
		keyowners = mysql_query(SQLHandle, query);
		new rows = cache_num_rows();
		if(rows) {
  			new list[1024], key_name[MAX_PLAYER_NAME], key_date[20];
	    	format(list, sizeof(list), "Key Owner\tKey Given On\n");
		    for(new i; i < rows; ++i)
		    {
      			cache_get_value_name(i, "Player", key_name);
	        	cache_get_value_name(i, "KeyDate", key_date);
		        format(list, sizeof(list), "%s%s\t%s\n", list, key_name, key_date);
		    }

            new title[32];
			format(title, sizeof(title), "Key Owners (Page %d)", ListPage[playerid]+1);
			ShowPlayerDialog(playerid, DIALOG_KEYS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
		}else{
		    ListPage[playerid] = 0;
   			ShowHouseMenu(playerid);
			SendClientMessage(playerid, 0xE74C3CFF, "Can't find any more key owners.");
		}

		cache_delete(keyowners);
	    return 1;
	}

	if(dialogid == DIALOG_SAFE_HISTORY)
	{
	    if(!response) {
			ListPage[playerid]--;
			if(ListPage[playerid] < 0)
			{
			    ListPage[playerid] = 0;
			    ShowHouseMenu(playerid);
			    return 1;
			}
		}else{
		    ListPage[playerid]++;
		}

		new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
        new query[200], Cache: safelog;
  		mysql_format(SQLHandle, query, sizeof(query), "SELECT Type, Amount, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as TransactionDate FROM housesafelogs WHERE HouseID=%d ORDER BY Date DESC LIMIT %d, 15", id, ListPage[playerid]*15);
		safelog = mysql_query(SQLHandle, query);
		new rows = cache_num_rows();
		if(rows) {
  			new list[1024], type, amount, date[20];
	    	format(list, sizeof(list), "Action\tDate\n");
		    for(new i; i < rows; ++i)
		    {
		        cache_get_value_name_int(i, "Type", type);
		        cache_get_value_name_int(i, "Amount", amount);
	        	cache_get_value_name(i, "TransactionDate", date);

		        format(list, sizeof(list), "%s%s $%s\t{FFFFFF}%s\n", list, TransactionNames[type], convertNumber(amount), date);
		    }

            new title[32];
			format(title, sizeof(title), "Safe History (Page %d)", ListPage[playerid]+1);
			ShowPlayerDialog(playerid, DIALOG_SAFE_HISTORY, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
		}else{
			SendClientMessage(playerid, 0xE74C3CFF, "Can't find any more safe history.");
		}

		cache_delete(safelog);
	    return 1;
	}

	if(dialogid == DIALOG_MY_KEYS)
	{
	    if(!response) {
			ListPage[playerid]--;
			if(ListPage[playerid] < 0)
			{
			    ListPage[playerid] = 0;
			    return 1;
			}
		}else{
		    ListPage[playerid]++;
		}

        new query[200], Cache: mykeys;
	    mysql_format(SQLHandle, query, sizeof(query), "SELECT HouseID, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as KeyDate FROM housekeys WHERE Player='%e' ORDER BY Date DESC LIMIT %d, 15", Player_GetName(playerid), ListPage[playerid]*15);
		mykeys = mysql_query(SQLHandle, query);

		new rows = cache_num_rows();
		if(rows) {
  			new list[1024], id, key_date[20];
	   		format(list, sizeof(list), "House Info\tKey Given On\n");
		    for(new i; i < rows; ++i)
		    {
		        cache_get_value_name_int(i, "HouseID", id);
	       		cache_get_value_name(i, "KeyDate", key_date);
		        format(list, sizeof(list), "%s%s's %s\t%s\n", list, HouseData[id][Owner], HouseData[id][Name], key_date);
		    }

            new title[32];
			format(title, sizeof(title), "My Keys (Page %d)", ListPage[playerid]+1);
			ShowPlayerDialog(playerid, DIALOG_MY_KEYS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
		}else{
		    ListPage[playerid] = 0;
			SendClientMessage(playerid, 0xE74C3CFF, "Can't find any more keys.");
		}

		cache_delete(mykeys);
	    return 1;
	}

	if(dialogid == DIALOG_BUY_HOUSE_FROM_OWNER)
	{
		if(!response) return 1;
		new id = GetPVarInt(playerid, "PickupHouseID");
		if(!IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ])) return SendClientMessage(playerid, 0xE74C3CFF, "You're not near any house.");
        #if LIMIT_PER_PLAYER > 0
		if(OwnedHouses(playerid) + 1 > LIMIT_PER_PLAYER) return SendClientMessage(playerid, 0xE74C3CFF, "You can't buy any more houses.");
		#endif
		if(HouseData[id][SalePrice] > GetPlayerMoney(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't afford this house.");
		if(HouseData[id][SalePrice] < 1) return SendClientMessage(playerid, 0xE74C3CFF, "Someone already owns this house.");
  		new old_owner[MAX_PLAYER_NAME], price = HouseData[id][SalePrice], owner_id = INVALID_PLAYER_ID;
  		format(old_owner, MAX_PLAYER_NAME, "%s", HouseData[id][Owner]);

		foreach(new i : Player)
		{
			if(!strcmp(HouseData[id][Owner], Player_GetName(i)))
			{
				owner_id = i;
				break;
			}
		}

		GivePlayerMoney(playerid, -HouseData[id][SalePrice]);
		GetPlayerName(playerid, HouseData[id][Owner], MAX_PLAYER_NAME);
  		HouseData[id][LastEntered] = gettime();
  		HouseData[id][SalePrice] = 0;
		HouseData[id][Save] = true;

		UpdateHouseLabel(id);
		Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 19522);
		Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 32);
		SendToHouse(playerid, id);

		foreach(new i : Player)
	    {
	        if(i == playerid) continue;
	        if(InHouse[i] == id)
	        {
	            SetPVarInt(i, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
	        	SetPlayerVirtualWorld(i, 0);
		        SetPlayerInterior(i, 0);
		        SetPlayerPos(i, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
		        InHouse[i] = INVALID_HOUSE_ID;
	        }

	        if(Iter_Contains(HouseKeys[i], id)) Iter_Remove(HouseKeys[i], id);
	   	}

	    new query[128];
	    if(IsPlayerConnected(owner_id)) {
	        GivePlayerMoney(owner_id, price);

			new string[128];
			format(string, sizeof(string), "%s(%d) has bought your house for $%s.", HouseData[id][Owner], playerid, convertNumber(price));
			SendClientMessage(owner_id, -1, string);
	    }else{
	        mysql_format(SQLHandle, query, sizeof(query), "INSERT INTO housesales SET OldOwner='%e', NewOwner='%e', Price=%d", old_owner, HouseData[id][Owner], price);
	    	mysql_tquery(SQLHandle, query, "", "");
	    }

	    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housevisitors WHERE HouseID=%d", id);
	    mysql_tquery(SQLHandle, query, "", "");

	    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housekeys WHERE HouseID=%d", id);
	    mysql_tquery(SQLHandle, query, "", "");

	    mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housesafelogs WHERE HouseID=%d", id);
	    mysql_tquery(SQLHandle, query, "", "");
		return 1;
	}

	if(dialogid == DIALOG_SELL_HOUSE)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
		if(listitem == 0)
		{
		    new money = floatround(HouseData[id][Price] * 0.85) + HouseData[id][SafeMoney];
		    GivePlayerMoney(playerid, money);
			ResetHouse(id);
		}

		if(listitem == 1)
		{
		    if(HouseData[id][SalePrice] > 0) {
			    HouseData[id][SalePrice] = 0;
			    HouseData[id][Save] = true;

			    UpdateHouseLabel(id);
				Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 19522);
				Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 32);
			    SendClientMessage(playerid, -1, "Your house is no longer for sale.");
			}else{
				if(HouseData[id][SafeMoney] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "You can't put your house for sale if there's money in the safe.");
				ShowPlayerDialog(playerid, DIALOG_SELLING_PRICE, DIALOG_STYLE_INPUT, "Sell House", "How much do you want for your house?", "Put For Sale", "Cancel");
			}
		}

	    return 1;
	}

	if(dialogid == DIALOG_SELLING_PRICE)
	{
	    if(!response) return ShowHouseMenu(playerid);
        new id = InHouse[playerid];
        if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
		if(strcmp(HouseData[id][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
        new amount = strval(inputtext);
		if(!(1 <= amount <= 10000000)) return ShowPlayerDialog(playerid, DIALOG_SELLING_PRICE, DIALOG_STYLE_INPUT, "Sell House", "{E74C3C}You can't put your house for sale for less than $1 or more than $100,000,000.\n\n{FFFFFF}How much do you want for your house?", "Put For Sale", "Cancel");
		HouseData[id][SalePrice] = amount;
		HouseData[id][Save] = true;

		UpdateHouseLabel(id);
		Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 1273);
		Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 31);

		new string[128];
		format(string, sizeof(string), "You put your house for sale for $%s.", convertNumber(amount));
		SendClientMessage(playerid, -1, string);
	    return 1;
	}

	return 0;
}

public OnPlayerSelectDynamicObject(playerid, objectid, modelid, Float: x, Float: y, Float: z)
{
	switch(SelectMode[playerid])
	{
	    case SELECT_MODE_EDIT:
		{
			EditingFurniture[playerid] = true;
			EditDynamicObject(playerid, objectid);
		}

	    case SELECT_MODE_SELL:
	    {
	        CancelEdit(playerid);

			new data[e_furniture], string[128];
			SetPVarInt(playerid, "SelectedFurniture", objectid);
			Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
			format(string, sizeof(string), "Do you want to sell your %s?\nYou'll get {2ECC71}$%s.", HouseFurnitures[ data[ArrayID] ][Name], convertNumber(HouseFurnitures[ data[ArrayID] ][Price]));
			ShowPlayerDialog(playerid, DIALOG_FURNITURE_SELL, DIALOG_STYLE_MSGBOX, "Confirm Sale", string, "Sell", "Close");
		}
	}

    SelectMode[playerid] = SELECT_MODE_NONE;
	return 1;
}

public OnPlayerEditDynamicObject(playerid, objectid, response, Float: x, Float: y, Float: z, Float: rx, Float: ry, Float: rz)
{
	if(EditingFurniture[playerid])
	{
		switch(response)
		{
		    case EDIT_RESPONSE_CANCEL:
		    {
		        new data[e_furniture];
		        Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
		        SetDynamicObjectPos(objectid, data[furnitureX], data[furnitureY], data[furnitureZ]);
		        SetDynamicObjectRot(objectid, data[furnitureRX], data[furnitureRY], data[furnitureRZ]);

		        EditingFurniture[playerid] = false;
		    }

			case EDIT_RESPONSE_FINAL:
			{
			    new data[e_furniture], query[256];
			    Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
			    data[furnitureX] = x;
			    data[furnitureY] = y;
			    data[furnitureZ] = z;
	            data[furnitureRX] = rx;
	            data[furnitureRY] = ry;
	            data[furnitureRZ] = rz;
	            SetDynamicObjectPos(objectid, data[furnitureX], data[furnitureY], data[furnitureZ]);
		        SetDynamicObjectRot(objectid, data[furnitureRX], data[furnitureRY], data[furnitureRZ]);
		        Streamer_SetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);

		        mysql_format(SQLHandle, query, sizeof(query), "UPDATE housefurnitures SET FurnitureX=%f, FurnitureY=%f, FurnitureZ=%f, FurnitureRX=%f, FurnitureRY=%f, FurnitureRZ=%f WHERE ID=%d", data[furnitureX], data[furnitureY], data[furnitureZ], data[furnitureRX], data[furnitureRY], data[furnitureRZ], data[SQLID]);
		        mysql_tquery(SQLHandle, query, "", "");

		        EditingFurniture[playerid] = false;
			}
		}
	}

	return 1;
}

/* ============ Player Commands ============ */
CMD:house(playerid, params[])
{
	if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
	ShowHouseMenu(playerid);
	return 1;
}

CMD:myhousekeys(playerid, params[])
{
    new query[200], Cache: mykeys;
    mysql_format(SQLHandle, query, sizeof(query), "SELECT HouseID, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as KeyDate FROM housekeys WHERE Player='%e' ORDER BY Date DESC LIMIT 0, 15", Player_GetName(playerid));
	mykeys = mysql_query(SQLHandle, query);
	ListPage[playerid] = 0;

	new rows = cache_num_rows();
	if(rows) {
 		new list[1024], id, key_date[20];
   		format(list, sizeof(list), "House Info\tKey Given On\n");
	    for(new i; i < rows; ++i)
	    {
	        cache_get_value_name_int(i, "HouseID", id);
       		cache_get_value_name(i, "KeyDate", key_date);
	        format(list, sizeof(list), "%s%s's %s\t%s\n", list, HouseData[id][Owner], HouseData[id][Name], key_date);
	    }

		ShowPlayerDialog(playerid, DIALOG_MY_KEYS, DIALOG_STYLE_TABLIST_HEADERS, "My Keys (Page 1)", list, "Next", "Close");
	}else{
		SendClientMessage(playerid, 0xE74C3CFF, "You don't have any keys for any houses.");
	}

	cache_delete(mykeys);
	return 1;
}

CMD:givehousekeys(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
    new id, houseid = InHouse[playerid];
	if(strcmp(HouseData[houseid][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /givehousekeys [player id]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, 0xE74C3CFF, "Invalid player ID.");
	if(id == playerid) return SendClientMessage(playerid, 0xE74C3CFF, "You're the owner, you don't need keys.");
	if(Iter_Contains(HouseKeys[id], houseid)) return SendClientMessage(playerid, 0xE74C3CFF, "That player has keys for this house.");
	Iter_Add(HouseKeys[id], houseid);

	new query[128];
	mysql_format(SQLHandle, query, sizeof(query), "INSERT INTO housekeys SET HouseID=%d, Player='%e', Date=UNIX_TIMESTAMP()", houseid, Player_GetName(id));
	mysql_tquery(SQLHandle, query, "", "");

	format(query, sizeof(query), "You've given keys to %s for this house.", Player_GetName(id));
	SendClientMessage(playerid, -1, query);
	format(query, sizeof(query), "Now you have keys for %s's house, %s.", HouseData[houseid][Owner], HouseData[houseid][Name]);
	SendClientMessage(id, -1, query);
	return 1;
}

CMD:takehousekeys(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
    new id, houseid = InHouse[playerid];
	if(strcmp(HouseData[houseid][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /takehousekeys [player id]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, 0xE74C3CFF, "Invalid player ID.");
	if(id == playerid) return SendClientMessage(playerid, 0xE74C3CFF, "You're the owner, you can't take your keys.");
	if(!Iter_Contains(HouseKeys[id], houseid)) return SendClientMessage(playerid, 0xE74C3CFF, "That player doesn't have keys for this house.");
	Iter_Remove(HouseKeys[id], houseid);

	new query[128];
	mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM housekeys WHERE HouseID=%d AND Player='%e'", houseid, Player_GetName(id));
	mysql_tquery(SQLHandle, query, "", "");

	format(query, sizeof(query), "You've taken keys from %s for this house.", Player_GetName(id));
	SendClientMessage(playerid, -1, query);
	format(query, sizeof(query), "House owner %s has taken your keys for their house %s.", HouseData[houseid][Owner], HouseData[houseid][Name]);
	SendClientMessage(id, -1, query);
	return 1;
}

CMD:kickfromhouse(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, 0xE74C3CFF, "You're not in a house.");
    new id, houseid = InHouse[playerid];
	if(strcmp(HouseData[houseid][Owner], Player_GetName(playerid))) return SendClientMessage(playerid, 0xE74C3CFF, "You're not the owner of this house.");
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /kickfromhouse [player id]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, 0xE74C3CFF, "Invalid player ID.");
	if(id == playerid) return SendClientMessage(playerid, 0xE74C3CFF, "You can't kick yourself from your house.");
	if(InHouse[id] != houseid) return SendClientMessage(playerid, 0xE74C3CFF, "That player isn't in your house.");
    SendClientMessage(playerid, -1, "Player kicked.");
	SendClientMessage(id, -1, "You got kicked by the house owner.");
	SetPVarInt(id, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
	SetPlayerVirtualWorld(id, 0);
 	SetPlayerInterior(id, 0);
 	SetPlayerPos(id, HouseData[houseid][houseX], HouseData[houseid][houseY], HouseData[houseid][houseZ]);
 	InHouse[id] = INVALID_HOUSE_ID;
	return 1;
}

/* ============ Admin Commands ============ */
CMD:createhouse(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this command.");
	new interior, price;
	if(sscanf(params, "ii", price, interior)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /createhouse [price] [interior id]");
    if(!(0 <= interior <= sizeof(HouseInteriors)-1)) return SendClientMessage(playerid, 0xE74C3CFF, "Interior ID you entered does not exist.");
	new id = Iter_Free(Houses);
	if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "You can't create more houses.");
	SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
	format(HouseData[id][Name], MAX_HOUSE_NAME, "House For Sale");
	format(HouseData[id][Owner], MAX_PLAYER_NAME, "-");
	format(HouseData[id][Password], MAX_HOUSE_PASSWORD, "-");
	GetPlayerPos(playerid, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
	HouseData[id][Price] = price;
	HouseData[id][Interior] = interior;
	HouseData[id][LockMode] = LOCK_MODE_NOLOCK;
	HouseData[id][SalePrice] = HouseData[id][SafeMoney] = HouseData[id][LastEntered] = 0;
	format(HouseData[id][Address], MAX_HOUSE_ADDRESS, "%d, %s, %s", id, GetZoneName(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]), GetCityName(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]));
    HouseData[id][Save] = true;

    new label[200];
    format(label, sizeof(label), "{2ECC71}House For Sale (ID: %d)\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", id, HouseInteriors[interior][IntName], convertNumber(price));
	HouseData[id][HouseLabel] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]+0.35, 15.0, .testlos = 1);
	HouseData[id][HousePickup] = CreateDynamicPickup(1273, 1, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
	HouseData[id][HouseIcon] = CreateDynamicMapIcon(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], 31, 0);

	new query[256];
	mysql_format(SQLHandle, query, sizeof(query), "INSERT INTO houses SET ID=%d, HouseX=%f, HouseY=%f, HouseZ=%f, HousePrice=%d, HouseInterior=%d", id, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], price, interior);
	mysql_tquery(SQLHandle, query, "", "");
	Iter_Add(Houses, id);
	return 1;
}

CMD:gotohouse(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this command.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /gotohouse [house id]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, 0xE74C3CFF, "House ID you entered does not exist.");
	SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
	SetPlayerPos(playerid, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

CMD:hsetinterior(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this command.");
	new id, interior;
	if(sscanf(params, "ii", id, interior)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /hsetinterior [house id] [interior id]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, 0xE74C3CFF, "House ID you entered does not exist.");
	if(!(0 <= interior <= sizeof(HouseInteriors)-1)) return SendClientMessage(playerid, 0xE74C3CFF, "Interior ID you entered does not exist.");
	HouseData[id][Interior] = interior;

	new query[64];
	mysql_format(SQLHandle, query, sizeof(query), "UPDATE houses SET HouseInterior=%d WHERE ID=%d", interior, id);
	mysql_tquery(SQLHandle, query, "", "");

	UpdateHouseLabel(id);
	SendClientMessage(playerid, -1, "Interior updated.");
	return 1;
}

CMD:hsetprice(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this command.");
	new id, price;
	if(sscanf(params, "ii", id, price)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /hsetprice [house id] [price]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, 0xE74C3CFF, "House ID you entered does not exist.");
	HouseData[id][Price] = price;

	new query[64];
	mysql_format(SQLHandle, query, sizeof(query), "UPDATE houses SET HousePrice=%d WHERE ID=%d", price, id);
	mysql_tquery(SQLHandle, query, "", "");

	UpdateHouseLabel(id);
	SendClientMessage(playerid, -1, "Price updated.");
	return 1;
}

CMD:resethouse(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this command.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /resethouse [house id]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, 0xE74C3CFF, "House ID you entered does not exist.");
	ResetHouse(id);
	SendClientMessage(playerid, -1, "House reset.");
	return 1;
}

CMD:deletehouse(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "You can't use this command.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE74C3CFF, "USAGE: /deletehouse [house id]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, 0xE74C3CFF, "House ID you entered does not exist.");
	ResetHouse(id);
	DestroyDynamic3DTextLabel(HouseData[id][HouseLabel]);
	DestroyDynamicPickup(HouseData[id][HousePickup]);
	DestroyDynamicMapIcon(HouseData[id][HouseIcon]);
	Iter_Remove(Houses, id);
	HouseData[id][HouseLabel] = Text3D: INVALID_3DTEXT_ID;
	HouseData[id][HousePickup] = HouseData[id][HouseIcon] = -1;
	HouseData[id][Save] = false;

	new query[64];
	mysql_format(SQLHandle, query, sizeof(query), "DELETE FROM houses WHERE ID=%d", id);
	mysql_tquery(SQLHandle, query, "", "");
	SendClientMessage(playerid, -1, "House deleted.");
	return 1;
}
