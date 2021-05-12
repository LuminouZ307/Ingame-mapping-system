/* Ingame Mapping System by LuminouZ */

/*
	V2 Changelog:
	
> Added Material Text Creator

	V3 Changelog:
	
> Changed Saving system to MySQL R41

Commands :
> '/creatematext [text]'
> '/editmatext [matextid] [color/size/bold/position]'
> '/destroymatext [matextid]'

> Able for Changing Object Model on '/editobject'


*/

#include <a_samp>
#include <a_mysql>//R41
#include <sscanf2>
#include <streamer>
#include <zcmd>

#define DATABASE_ADDRESS "localhost"
#define DATABASE_USERNAME "root"
#define DATABASE_PASSWORD ""
#define DATABASE_NAME "object"

#define MAX_COBJECT 100
#define MAX_MT      100

/* Please Change the Dialog ID */

#define DIALOG_EDIT 		100
#define DIALOG_COORD        101
#define DIALOG_X            102
#define DIALOG_Y            103
#define DIALOG_Z            104
#define DIALOG_RX           105
#define DIALOG_RY           106
#define DIALOG_RZ           107
#define DIALOG_MTC          108
#define DIALOG_MTEDIT       109
#define DIALOG_MTX          110
#define DIALOG_MTY          111
#define DIALOG_MTZ          112
#define DIALOG_MTRX         113
#define DIALOG_MTRY         114
#define DIALOG_MTRZ         115

#define COLOR_SERVER 	  (0xC6E2FFFF)

new MySQL:sqldata;
new EditingObject[MAX_PLAYERS];
new EditingMatext[MAX_PLAYERS];

enum mtData
{
	mtID,
	mtExists,
	Float:mtPos[6],
	mtText[128],
	mtCreate,
	mtInterior,
	mtVW,
	mtSize,
	mtColor,
	mtBold
	
};
new MatextData[MAX_MT][mtData];

enum objData
{
	objID,
	objModel,
	objExists,
	Float:objPos[6],
	objVW,
	objInterior,
	objCreate
}
new ObjectData[MAX_COBJECT][objData];

main()
{
	print("\n----------------------------------");
	print(" In-Game Mapping System Loaded!");
	print("----------------------------------\n");
}

MYSQL_Connect()
{
	sqldata = mysql_connect(DATABASE_ADDRESS,DATABASE_USERNAME,DATABASE_PASSWORD,DATABASE_NAME);

	if(mysql_errno(sqldata) != 0)
	{
	    print("[SQL] - Connection Failed!");
	}
	else
	{
		print("[SQL] - Connection Estabilished!");
	}
}

public OnGameModeInit()
{
    MYSQL_Connect();
    mysql_tquery(sqldata, "SELECT * FROM `object`", "Object_Load", "");
    mysql_tquery(sqldata, "SELECT * FROM `matext`", "Matext_Load", "");
	return 1;
}

public OnPlayerConnect(playerid)
{
	EditingObject[playerid] = -1;
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

stock SendClientMessageEx(playerid, color, const text[], {Float, _}:...)
{
	static
	    args,
	    str[144];

	if ((args = numargs()) == 3)
	{
	    SendClientMessage(playerid, color, text);
	}
	else
	{
		while (--args >= 3)
		{
			#emit LCTRL 5
			#emit LOAD.alt args
			#emit SHL.C.alt 2
			#emit ADD.C 12
			#emit ADD
			#emit LOAD.I
			#emit PUSH.pri
		}
		#emit PUSH.S text
		#emit PUSH.C 144
		#emit PUSH.C str
		#emit PUSH.S 8
		#emit SYSREQ.C format
		#emit LCTRL 5
		#emit SCTRL 4

		SendClientMessage(playerid, color, str);

		#emit RETN
	}
	return 1;
}

stock Matext_Create(playerid, text[])
{
    new
	    Float:x,
	    Float:y,
	    Float:z,
	    Float:angle;

	if (GetPlayerPos(playerid, x, y, z) && GetPlayerFacingAngle(playerid, angle))
	{
		for (new i = 0; i < MAX_MT; i ++) if (!MatextData[i][mtExists])
		{
		    MatextData[i][mtExists] = true;

		    x += 1.0 * floatsin(-angle, degrees);
			y += 1.0 * floatcos(-angle, degrees);

            format(MatextData[i][mtText], 128, "%s", text);
            
            MatextData[i][mtPos][0] = x;
            MatextData[i][mtPos][1] = y;
            MatextData[i][mtPos][2] = z;
			MatextData[i][mtPos][3] = 0.0;
			MatextData[i][mtPos][4] = 0.0;
            MatextData[i][mtPos][5] = angle;
            MatextData[i][mtSize] = 30; //Default Size adalah 30
            MatextData[i][mtColor] = 1;
            MatextData[i][mtBold] = 0;

            MatextData[i][mtInterior] = GetPlayerInterior(playerid);
            MatextData[i][mtVW] = GetPlayerVirtualWorld(playerid);

			Matext_Refresh(i);
			mysql_tquery(sqldata, "INSERT INTO `matext` (`mtInterior`) VALUES(0)", "OnMatextCreated", "d", i);

			return i;
		}
	}
	return -1;
}

stock Object_Create(playerid, modelid)
{
    new
	    Float:x,
	    Float:y,
	    Float:z,
	    Float:angle;

	if (GetPlayerPos(playerid, x, y, z) && GetPlayerFacingAngle(playerid, angle))
	{
		for (new i = 0; i < MAX_COBJECT; i ++) if (!ObjectData[i][objExists])
		{
		    ObjectData[i][objExists] = true;

		    x += 1.0 * floatsin(-angle, degrees);
			y += 1.0 * floatcos(-angle, degrees);

            ObjectData[i][objPos][0] = x;
            ObjectData[i][objPos][1] = y;
            ObjectData[i][objPos][2] = z;
			ObjectData[i][objPos][3] = 0.0;
			ObjectData[i][objPos][4] = 0.0;
            ObjectData[i][objPos][5] = angle;
            ObjectData[i][objModel] = modelid;

            ObjectData[i][objInterior] = GetPlayerInterior(playerid);
            ObjectData[i][objVW] = GetPlayerVirtualWorld(playerid);

			Object_Refresh(i);
			mysql_tquery(sqldata, "INSERT INTO `object` (`objectInterior`) VALUES(0)", "OnObjectCreated", "d", i);

			return i;
		}
	}
	return -1;
}

stock Object_Save(objid)
{
	new
	    query[512];

	format(query, sizeof(query), "UPDATE `object` SET `objectModel` = '%d', `objectX` = '%.4f', `objectY` = '%.4f', `objectZ` = '%.4f', `objectRX` = '%.4f', `objectRY` = '%.4f', `objectRZ` = '%.4f', `objectInterior` = '%d', `objectWorld` = '%d' WHERE `objid` = '%d'",
		ObjectData[objid][objModel],
		ObjectData[objid][objPos][0],
	    ObjectData[objid][objPos][1],
	    ObjectData[objid][objPos][2],
	    ObjectData[objid][objPos][3],
	    ObjectData[objid][objPos][4],
	    ObjectData[objid][objPos][5],
	    ObjectData[objid][objInterior],
	    ObjectData[objid][objVW],
	    ObjectData[objid][objID]
	);
	return mysql_tquery(sqldata, query);
}

stock Matext_Save(mtid)
{
	new
	    query[512];

	format(query, sizeof(query), "UPDATE `matext` SET `mtText` = '%s', `mtX` = '%.4f', `mtY` = '%.4f', `mtZ` = '%.4f', `mtRX` = '%.4f', `mtRY` = '%.4f', `mtRZ` = '%.4f', `mtInterior` = '%d', `mtWorld` = '%d', `mtBold` = '%d', `mtColor` = '%d', `mtSize` = '%d' WHERE `mtID` = '%d'",
		MatextData[mtid][mtText],
		MatextData[mtid][mtPos][0],
	    MatextData[mtid][mtPos][1],
	    MatextData[mtid][mtPos][2],
	    MatextData[mtid][mtPos][3],
	    MatextData[mtid][mtPos][4],
	    MatextData[mtid][mtPos][5],
	    MatextData[mtid][mtInterior],
	    MatextData[mtid][mtVW],
	    MatextData[mtid][mtBold],
	    MatextData[mtid][mtColor],
	    MatextData[mtid][mtSize],
	    MatextData[mtid][mtID]
	);
	return mysql_tquery(sqldata, query);
}

stock Object_Refresh(objid)
{
	if (objid != -1 && ObjectData[objid][objExists])
	{
	    if (IsValidDynamicObject(ObjectData[objid][objCreate]))
	        DestroyDynamicObject(ObjectData[objid][objCreate]);

	 	ObjectData[objid][objCreate] = CreateDynamicObject(ObjectData[objid][objModel], ObjectData[objid][objPos][0], ObjectData[objid][objPos][1], ObjectData[objid][objPos][2] - 0.0, ObjectData[objid][objPos][3], ObjectData[objid][objPos][4],ObjectData[objid][objPos][5], ObjectData[objid][objVW], ObjectData[objid][objInterior]);
		return 1;
	}
	return 0;
}

stock Matext_Refresh(mtid)
{
	static
	    color;
	    
	if (mtid != -1 && MatextData[mtid][mtExists])
	{
	    if (IsValidDynamicObject(MatextData[mtid][mtCreate]))
	        DestroyDynamicObject(MatextData[mtid][mtCreate]);

		switch (MatextData[mtid][mtColor])
		{
		    case 1: color = 0xFFFFFFFF;//Putih
		    case 2: color = 0xFF6347FF;//Biru
		    case 3: color = 0xFFFF6347;//Merah
		    case 4: color = 0xFFFFFF00;//Kuning
		}
	 	MatextData[mtid][mtCreate] = CreateDynamicObject(19482, MatextData[mtid][mtPos][0], MatextData[mtid][mtPos][1], MatextData[mtid][mtPos][2] - 0.0, MatextData[mtid][mtPos][3], MatextData[mtid][mtPos][4],MatextData[mtid][mtPos][5], MatextData[mtid][mtVW], MatextData[mtid][mtInterior]);
		SetDynamicObjectMaterial(MatextData[mtid][mtCreate], 0, 10101, "2notherbuildsfe", "Bow_Abpave_Gen", 0x00000000);
        SetDynamicObjectMaterialText(MatextData[mtid][mtCreate], 0, MatextData[mtid][mtText], 130, "Arial", MatextData[mtid][mtSize], MatextData[mtid][mtBold], color, 0x00000000, 0);
		return 1;
	}
	return 0;
}

//	SetDynamicObjectMaterialText(MatextData[mtid][mtCreate], 0, MatextData[mtid][mtText], 130, "Ariel", 40, 0, 0xFF6347FF, 0x00000000, 1);

forward OnMatextCreated(mtid);
public OnMatextCreated(mtid)
{
    if (mtid == -1 || !MatextData[mtid][mtExists])
		return 0;

	MatextData[mtid][mtID] = cache_insert_id();
 	Matext_Save(mtid);

	return 1;
}

forward OnObjectCreated(objid);
public OnObjectCreated(objid)
{
    if (objid == -1 || !ObjectData[objid][objExists])
		return 0;

	ObjectData[objid][objID] = cache_insert_id();
 	Object_Save(objid);

	return 1;
}

forward Object_Load();
public Object_Load()
{
	new rows = cache_num_rows();
 	if(rows)
  	{
		for(new i; i < rows; i++)
		{
		    ObjectData[i][objExists] = true;
		    cache_get_value_name_int(0, "objectID", ObjectData[i][objID]);
		    cache_get_value_name_int(0, "objectModel", ObjectData[i][objModel]);
		    cache_get_value_name_float(0, "objectX", ObjectData[i][objPos][0]);
		    cache_get_value_name_float(0, "objectY", ObjectData[i][objPos][1]);
		    cache_get_value_name_float(0, "objectZ", ObjectData[i][objPos][2]);
		    cache_get_value_name_float(0, "objectRX", ObjectData[i][objPos][3]);
		    cache_get_value_name_float(0, "objectRY", ObjectData[i][objPos][4]);
		    cache_get_value_name_float(0, "objectRZ", ObjectData[i][objPos][5]);
            cache_get_value_name_int(0, "objectInterior", ObjectData[i][objInterior]);
            cache_get_value_name_int(0, "objectWorld", ObjectData[i][objVW]);

			Object_Refresh(i);
		}
	}
	return 1;
}

forward Matext_Load();
public Matext_Load()
{
	new rows = cache_num_rows();
	new mt[128];
 	if(rows)
  	{
		for(new i; i < rows; i++)
		{
		    MatextData[i][mtExists] = true;
		    
            cache_get_value_name(0, "mtText", mt);
            format(MatextData[i][mtText], 128, mt);
            
            cache_get_value_name_int(0, "mtID", MatextData[i][mtID]);
		    cache_get_value_name_float(0, "mtX", MatextData[i][mtPos][0]);
		    cache_get_value_name_float(0, "mtY", MatextData[i][mtPos][1]);
		    cache_get_value_name_float(0, "mtZ", MatextData[i][mtPos][2]);
		    
		    cache_get_value_name_float(0, "mtRX", MatextData[i][mtPos][3]);
		    cache_get_value_name_float(0, "mtRY", MatextData[i][mtPos][4]);
		    cache_get_value_name_float(0, "mtRZ", MatextData[i][mtPos][5]);

            cache_get_value_name_int(0, "mtInterior", MatextData[i][mtInterior]);
            cache_get_value_name_int(0, "mtVW", MatextData[i][mtVW]);
            cache_get_value_name_int(0, "mtBold", MatextData[i][mtBold]);
            cache_get_value_name_int(0, "mtColor", MatextData[i][mtColor]);
            cache_get_value_name_int(0, "mtSize", MatextData[i][mtSize]);

			Matext_Refresh(i);
		}
	}
	return 1;
}


stock Matext_Delete(mtid)
{
	if (mtid != -1 && MatextData[mtid][mtExists])
	{
	    new
	        string[64];

		format(string, sizeof(string), "DELETE FROM `matext` WHERE `mtID` = '%d'", MatextData[mtid][mtID]);
		mysql_tquery(sqldata, string);

        if (IsValidDynamicObject(MatextData[mtid][mtCreate]))
	        DestroyDynamicObject(MatextData[mtid][mtCreate]);

	    MatextData[mtid][mtExists] = false;
	   	MatextData[mtid][mtID] = 0;
	}
	return 1;
}

stock Object_Delete(objid)
{
	if (objid != -1 && ObjectData[objid][objExists])
	{
	    new
	        string[64];

		format(string, sizeof(string), "DELETE FROM `object` WHERE `objid` = '%d'", ObjectData[objid][objID]);
		mysql_tquery(sqldata, string);

        if (IsValidDynamicObject(ObjectData[objid][objCreate]))
	        DestroyDynamicObject(ObjectData[objid][objCreate]);

	    ObjectData[objid][objExists] = false;
	   	ObjectData[objid][objID] = 0;
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_COORD)
	{
	    if(response)
		{
			switch(listitem)
			{
			    case 0: ShowPlayerDialog(playerid, DIALOG_X, DIALOG_STYLE_INPUT, "Object Edit", "Input an X Offset from -100 to 100", "Confirm", "Cancel");
				case 1: ShowPlayerDialog(playerid, DIALOG_Y, DIALOG_STYLE_INPUT, "Object Edit", "Input a Y Offset from -100 to 100", "Confirm", "Cancel");
			    case 2: ShowPlayerDialog(playerid, DIALOG_Z, DIALOG_STYLE_INPUT, "Object Edit", "Input a Z Offset from -100 to 100", "Confirm", "Cancel");
			    case 3: ShowPlayerDialog(playerid, DIALOG_RX, DIALOG_STYLE_INPUT, "Object Edit", "Input an X Rotation from 0 to 360", "Confirm", "Cancel");
				case 4: ShowPlayerDialog(playerid, DIALOG_RY, DIALOG_STYLE_INPUT, "Object Edit", "Input a Y Rotation from 0 to 360", "Confirm", "Cancel");
				case 5: ShowPlayerDialog(playerid, DIALOG_RZ, DIALOG_STYLE_INPUT, "Object Edit", "Input a Z Rotation from 0 to 360", "Confirm", "Cancel");
			}
		}
	}
	if(dialogid == DIALOG_MTC)
	{
	    if(response)
		{
			switch(listitem)
			{
			    case 0: ShowPlayerDialog(playerid, DIALOG_MTX, DIALOG_STYLE_INPUT, "Material Text Edit", "Input an X Offset from -100 to 100", "Confirm", "Cancel");
				case 1: ShowPlayerDialog(playerid, DIALOG_MTY, DIALOG_STYLE_INPUT, "Material Text Edit", "Input a Y Offset from -100 to 100", "Confirm", "Cancel");
			    case 2: ShowPlayerDialog(playerid, DIALOG_MTZ, DIALOG_STYLE_INPUT, "Material Text Edit", "Input a Z Offset from -100 to 100", "Confirm", "Cancel");
			    case 3: ShowPlayerDialog(playerid, DIALOG_MTRX, DIALOG_STYLE_INPUT, "Material Text Edit", "Input an X Rotation from 0 to 360", "Confirm", "Cancel");
				case 4: ShowPlayerDialog(playerid, DIALOG_MTRY, DIALOG_STYLE_INPUT, "Material Text Edit", "Input a Y Rotation from 0 to 360", "Confirm", "Cancel");
				case 5: ShowPlayerDialog(playerid, DIALOG_MTRZ, DIALOG_STYLE_INPUT, "Material Text Edit", "Input a Z Rotation from 0 to 360", "Confirm", "Cancel");
			}
		}
	}
	if(dialogid == DIALOG_MTX)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = MatextData[EditingMatext[playerid]][mtPos][0];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
         	MatextData[EditingMatext[playerid]][mtPos][0] = obj + offset;

	        Matext_Refresh(EditingMatext[playerid]);
	        Matext_Save(EditingMatext[playerid]);

	        EditingMatext[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_MTY)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = MatextData[EditingMatext[playerid]][mtPos][1];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        MatextData[EditingMatext[playerid]][mtPos][1] = obj + offset;

	        Matext_Refresh(EditingMatext[playerid]);
	        Matext_Save(EditingMatext[playerid]);

	        EditingMatext[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_MTZ)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = MatextData[EditingMatext[playerid]][mtPos][2];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        MatextData[EditingMatext[playerid]][mtPos][2] = obj + offset;

	        Matext_Refresh(EditingMatext[playerid]);
	        Matext_Save(EditingMatext[playerid]);

	        EditingMatext[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_MTRX)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = MatextData[EditingMatext[playerid]][mtPos][3];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        MatextData[EditingMatext[playerid]][mtPos][3] = obj + offset;

	        Matext_Refresh(EditingMatext[playerid]);
	        Matext_Save(EditingMatext[playerid]);

	        EditingMatext[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_MTRY)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = MatextData[EditingMatext[playerid]][mtPos][4];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        MatextData[EditingMatext[playerid]][mtPos][4] = obj + offset;

	        Matext_Refresh(EditingMatext[playerid]);
	        Matext_Save(EditingMatext[playerid]);

	        EditingMatext[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_MTRZ)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = MatextData[EditingMatext[playerid]][mtPos][5];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        MatextData[EditingMatext[playerid]][mtPos][5] = obj + offset;

	        Matext_Refresh(EditingMatext[playerid]);
	        Matext_Save(EditingMatext[playerid]);

	        EditingMatext[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_X)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = ObjectData[EditingObject[playerid]][objPos][0];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
         	ObjectData[EditingObject[playerid]][objPos][0] = obj + offset;

	        Object_Refresh(EditingObject[playerid]);
	        Object_Save(EditingObject[playerid]);

	        EditingObject[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_Y)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = ObjectData[EditingObject[playerid]][objPos][1];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        ObjectData[EditingObject[playerid]][objPos][1] = obj + offset;

	        Object_Refresh(EditingObject[playerid]);
	        Object_Save(EditingObject[playerid]);

	        EditingObject[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_Z)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = ObjectData[EditingObject[playerid]][objPos][2];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        ObjectData[EditingObject[playerid]][objPos][2] = obj + offset;

	        Object_Refresh(EditingObject[playerid]);
	        Object_Save(EditingObject[playerid]);

	        EditingObject[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_RX)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = ObjectData[EditingObject[playerid]][objPos][3];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        ObjectData[EditingObject[playerid]][objPos][3] = obj + offset;

	        Object_Refresh(EditingObject[playerid]);
	        Object_Save(EditingObject[playerid]);

	        EditingObject[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_RY)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = ObjectData[EditingObject[playerid]][objPos][4];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        ObjectData[EditingObject[playerid]][objPos][4] = obj + offset;

	        Object_Refresh(EditingObject[playerid]);
	        Object_Save(EditingObject[playerid]);

	        EditingObject[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_RZ)
	{
	    if(response)
	    {
	        new Float:offset = floatstr(inputtext);
	        new Float:obj = ObjectData[EditingObject[playerid]][objPos][5];
	        if(offset < -100) offset = 0;
			else if(offset > 100) offset = 100;
	        offset = offset/100;
	        ObjectData[EditingObject[playerid]][objPos][5] = obj + offset;

	        Object_Refresh(EditingObject[playerid]);
	        Object_Save(EditingObject[playerid]);

	        EditingObject[playerid] = -1;
		}
	}
	if(dialogid == DIALOG_MTEDIT)
	{
	    if(response)
	    {
	        switch(listitem)
	        {
		        case 0:
		        {
		            EditDynamicObject(playerid, MatextData[EditingMatext[playerid]][mtCreate]);
		            SendClientMessageEx(playerid, COLOR_SERVER, "MATEXT: {FFFFFF}You're Editing Material Text ID %d with Move Object", EditingMatext[playerid]);
				}
				case 1:
				{
					new stringg[512];
					format(stringg, sizeof(stringg), "Offset X (%f)\nOffset Y (%f)\nOffset Z (%f)\nRotation X (%f)\nRotation Y (%f)\nRotation Z (%f)",
	   				MatextData[EditingMatext[playerid]][mtPos][0],
				    MatextData[EditingMatext[playerid]][mtPos][1],
				    MatextData[EditingMatext[playerid]][mtPos][2],
	   				MatextData[EditingMatext[playerid]][mtPos][3],
				    MatextData[EditingMatext[playerid]][mtPos][4],
				    MatextData[EditingMatext[playerid]][mtPos][5]
					);
					ShowPlayerDialog(playerid, DIALOG_MTC, DIALOG_STYLE_LIST, "Editing Material Text", stringg, "Select", "Cancel");
				}
			}
		}
	}
	if(dialogid == DIALOG_EDIT)
	{
	    if(response)
	    {
	        switch(listitem)
	        {
		        case 0:
		        {
		            EditDynamicObject(playerid, ObjectData[EditingObject[playerid]][objCreate]);
		            SendClientMessageEx(playerid, COLOR_SERVER, "OBJECT: {FFFFFF}You're Editing Created object %d with Move Object", EditingObject[playerid]);
				}
				case 1:
				{
					new stringg[512];
					format(stringg, sizeof(stringg), "Offset X (%f)\nOffset Y (%f)\nOffset Z (%f)\nRotation X (%f)\nRotation Y (%f)\nRotation Z (%f)",
	   				ObjectData[EditingObject[playerid]][objPos][0],
				    ObjectData[EditingObject[playerid]][objPos][1],
				    ObjectData[EditingObject[playerid]][objPos][2],
	   				ObjectData[EditingObject[playerid]][objPos][3],
				    ObjectData[EditingObject[playerid]][objPos][4],
				    ObjectData[EditingObject[playerid]][objPos][5]
					);
					ShowPlayerDialog(playerid, DIALOG_COORD, DIALOG_STYLE_LIST, "Editing Object", stringg, "Select", "Cancel");
				}
			}
		}
	}
	return 1;
}
CMD:creatematext(playerid, params[])
{
	static
	    id,
		text[128];

	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You don't have permission to use this Command!");

	if (sscanf(params, "s[128]", text))
	    return SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/creatematext [text]");

	id = Matext_Create(playerid, text);

	if (id == -1)
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}The server has reached the limit for Material Text");

	SendClientMessageEx(playerid, COLOR_SERVER, "OBJECT: {FFFFFF}You have successfully Creating Material Text ID: %d.", id);
	EditDynamicObject(playerid, MatextData[id][mtCreate]);

	EditingMatext[playerid] = id;
	return 1;
}
CMD:createobject(playerid, params[])
{
	static
	    id,
		modelid;

	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You don't have permission to use this Command!");

	if (sscanf(params, "d", modelid))
	    return SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/createobject [modelid]");

	id = Object_Create(playerid, modelid);

	if (id == -1)
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}The server has reached the limit for Created Object's");

	SendClientMessageEx(playerid, COLOR_SERVER, "OBJECT: {FFFFFF}You have successfully created Object ID: %d.", id);
	EditDynamicObject(playerid, ObjectData[id][objCreate]);

	EditingObject[playerid] = id;
	return 1;
}

CMD:editobject(playerid, params[])
{
	static
	    id,
	    type[24],
		string[128];

	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You don't have permission to use this Command!");

	if (sscanf(params, "ds[24]S()[128]", id, type, string))
 	{
	 	SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/editobject [id] [option]");
	    SendClientMessage(playerid, COLOR_SERVER, "OPTION:{FFFFFF} position, model");
		return 1;
	}
	
	if ((id < 0 || id >= MAX_COBJECT) || !ObjectData[id][objExists])
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF} You have specified an invalid Created Object ID.");

	if (!strcmp(type, "position", true))
	{
		EditingObject[playerid] = id;
		ShowPlayerDialog(playerid, DIALOG_EDIT, DIALOG_STYLE_LIST, "Object Editing", "Edit with Move Object\nWith Coordinate", "Select", "Cancel");
	}
	else if(!strcmp(type, "model", true))
	{
	    new
	        mod;

	    if (sscanf(string, "d", mod))
	        return SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/editobject [id] [model] [modelid]");
	        
		ObjectData[id][objModel] = mod;
		SendClientMessageEx(playerid, COLOR_SERVER, "OBJECT: {FFFFFF}Successfully Changed Model of Created Object ID %d", id);

		Object_Refresh(id);
		
		Object_Save(id);
	}
	return 1;
}

CMD:editmatext(playerid, params[])
{
	static
	    id,
	    type[24],
		string[128];

	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You don't have permission to use this Command!");
	    
	if (sscanf(params, "ds[24]S()[128]", id, type, string))
 	{
	 	SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/editmatext [id] [OPTION]");
	    SendClientMessage(playerid, COLOR_SERVER, "OPTION:{FFFFFF} bold, color, position, size");
		return 1;
	}
	if ((id < 0 || id >= MAX_MT) || !MatextData[id][mtExists])
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You have specified an invalid Material Text ID.");

	if (!strcmp(type, "size", true))
	{
	    new
	        ukuran;
	        
	    if (sscanf(string, "d", ukuran))
	        return SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/editmatext [id] [size] [text size]");
	        
		MatextData[id][mtSize] = ukuran;
		
		Matext_Refresh(id);
		Matext_Save(id);
		SendClientMessageEx(playerid, COLOR_SERVER, "MATEXT: {FFFFFF}Font Size changed to %d", ukuran);
	}
	else if (!strcmp(type, "color", true))
	{
	    new
	        col;

	    if (sscanf(string, "d", col))
	    {
			SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/editmatext [id] [color] [option]");
			SendClientMessage(playerid, COLOR_SERVER, "OPTION: {FFFFFF}1: White | 2: Blue | 3: Red | 4: Yellow");
		}
		
		if (col < 1 || col > 4)
		    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You have specified an invalid Color Option!");
	    
		MatextData[id][mtColor] = col;

		Matext_Refresh(id);
		Matext_Save(id);
		SendClientMessageEx(playerid, COLOR_SERVER, "MATEXT: {FFFFFF}Material Text Color changed to Option %d", col);
	}
	else if (!strcmp(type, "position", true))
	{
	    EditingMatext[playerid] = id;

		ShowPlayerDialog(playerid, DIALOG_MTEDIT, DIALOG_STYLE_LIST, "Material Text", "With Move Object\nWith Coordinate", "Select", "Cancel");
	}
	else if (!strcmp(type, "bold", true))
	{
	    new
	        bold;

	    if (sscanf(string, "d", bold))
	    {
			SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/editmatext [id] [bold] [option]");
			SendClientMessage(playerid, COLOR_SERVER, "OPTION: {FFFFFF}0: No | 1: Yes");
		}

		if (bold < 1 || bold > 4)
		    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You have specified an invalid Bold Option!");
		    
		MatextData[id][mtBold] = bold;

		Matext_Refresh(id);
		Matext_Save(id);
		SendClientMessageEx(playerid, COLOR_SERVER, "MATEXT: {FFFFFF}Material Text Bold changed to Option %d", bold);
	}
	return 1;
}

CMD:destroymatext(playerid, params[])
{
	static
	    id = 0;

	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You don't have permission to use this Command!");

	if (sscanf(params, "d", id))
	    return SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/destroymatext [matextid]");

	if ((id < 0 || id >= MAX_MT) || !MatextData[id][mtExists])
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF} You have specified an invalid Material Text ID.");

	Matext_Delete(id);
	SendClientMessageEx(playerid, COLOR_SERVER, "OBJECT: {FFFFFF}You have successfully destroyed Material Text ID: %d.", id);
	return 1;
}

CMD:destroyobject(playerid, params[])
{
	static
	    id = 0;

	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You don't have permission to use this Command!");

	if (sscanf(params, "d", id))
	    return SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/destroyobject [object id]");

	if ((id < 0 || id >= MAX_COBJECT) || !ObjectData[id][objExists])
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF} You have specified an invalid Created Object ID.");

	Object_Delete(id);
	SendClientMessageEx(playerid, COLOR_SERVER, "OBJECT: {FFFFFF}You have successfully destroyed Created Object ID: %d.", id);
	return 1;
}


public OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	if (response == EDIT_RESPONSE_FINAL)
	{
		if (EditingObject[playerid] != -1 && ObjectData[EditingObject[playerid]][objExists])
	    {
			ObjectData[EditingObject[playerid]][objPos][0] = x;
			ObjectData[EditingObject[playerid]][objPos][1] = y;
			ObjectData[EditingObject[playerid]][objPos][2] = z;
			ObjectData[EditingObject[playerid]][objPos][3] = rx;
			ObjectData[EditingObject[playerid]][objPos][4] = ry;
			ObjectData[EditingObject[playerid]][objPos][5] = rz;

			Object_Refresh(EditingObject[playerid]);
			Object_Save(EditingObject[playerid]);

			SendClientMessageEx(playerid, COLOR_SERVER, "OBJECT: {FFFFFF}You've edited the position of Object ID: %d.", EditingObject[playerid]);
	    }
		else if (EditingMatext[playerid] != -1 && MatextData[EditingMatext[playerid]][mtExists])
	    {
			MatextData[EditingMatext[playerid]][mtPos][0] = x;
			MatextData[EditingMatext[playerid]][mtPos][1] = y;
			MatextData[EditingMatext[playerid]][mtPos][2] = z;
			MatextData[EditingMatext[playerid]][mtPos][3] = rx;
			MatextData[EditingMatext[playerid]][mtPos][4] = ry;
			MatextData[EditingMatext[playerid]][mtPos][5] = rz;

			Matext_Refresh(EditingMatext[playerid]);
			Matext_Save(EditingMatext[playerid]);

			SendClientMessageEx(playerid, COLOR_SERVER, "MATEXT: {FFFFFF}You've edited the position of Material Text ID: %d.", EditingMatext[playerid]);
	    }
	}
	if (response == EDIT_RESPONSE_FINAL || response == EDIT_RESPONSE_CANCEL)
	{
	    if (EditingObject[playerid] != -1)
			Object_Refresh(EditingObject[playerid]);
			
        EditingObject[playerid] = -1;
	}
	return 1;
}
