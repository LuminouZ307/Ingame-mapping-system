
#include <a_samp>
#include <a_mysql>//R39-6
#include <sscanf2>
#include <streamer>
#include <zcmd>

#define MYSQL_HOSTNAME "127.0.0.1"
#define MYSQL_USERNAME "root"
#define MYSQL_DATABASE "object"
#define MYSQL_PASSWORD ""
#define MAX_COBJECT 100

#define DIALOG_EDIT 		100
#define DIALOG_COORD        101
#define DIALOG_X            102
#define DIALOG_Y            103
#define DIALOG_Z            104
#define DIALOG_RX           105
#define DIALOG_RY           106
#define DIALOG_RZ           107


#define COLOR_SERVER 	  (0xC6E2FFFF)

new sqldata;
new EditingObject[MAX_PLAYERS];

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
	sqldata = mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_DATABASE, MYSQL_PASSWORD);

	if (mysql_errno(sqldata) != 0)
	{
	    printf("MYSQL Connection to \"%s\" failed!\a", MYSQL_HOSTNAME);
	}
	else
	{
		printf("MYSQL Connection to \"%s\" passed!", MYSQL_HOSTNAME);
	}
}

public OnGameModeInit()
{
    MYSQL_Connect();
    mysql_tquery(sqldata, "SELECT * FROM `object`", "Object_Load", "");
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

cache_get_field_int(row, const field_name[])
{
	new
	    str[12];

	cache_get_field_content(row, field_name, str, sqldata, sizeof(str));
	return strval(str);
}

stock Float:cache_get_field_float(row, const field_name[])
{
	new
	    str[16];

	cache_get_field_content(row, field_name, str, sqldata, sizeof(str));
	return floatstr(str);
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

forward OnObjectCreated(objid);
public OnObjectCreated(objid)
{
    if (objid == -1 || !ObjectData[objid][objExists])
		return 0;

	ObjectData[objid][objID] = cache_insert_id(sqldata);
 	Object_Save(objid);

	return 1;
}

forward Object_Load();
public Object_Load()
{
    static
	    rows,
	    fields;

	cache_get_data(rows, fields, sqldata);

	for (new i = 0; i < rows; i ++) if (i < MAX_COBJECT)
	{
	    ObjectData[i][objExists] = true;
	    ObjectData[i][objID] = cache_get_field_int(i, "objID");
	    ObjectData[i][objModel] = cache_get_field_int(i, "objectModel");
	    ObjectData[i][objPos][0] = cache_get_field_float(i, "objectX");
        ObjectData[i][objPos][1] = cache_get_field_float(i, "objectY");
        ObjectData[i][objPos][2] = cache_get_field_float(i, "objectZ");
        ObjectData[i][objPos][3] = cache_get_field_float(i, "objectRX");
        ObjectData[i][objPos][4] = cache_get_field_float(i, "objectRY");
        ObjectData[i][objPos][5] = cache_get_field_float(i, "objectRZ");
        ObjectData[i][objInterior] = cache_get_field_int(i, "objectInterior");
		ObjectData[i][objVW] = cache_get_field_int(i, "objectWorld");

		Object_Refresh(i);
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
	    id = 0;

	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF}You don't have permission to use this Command!");

	if (sscanf(params, "d", id))
	    return SendClientMessage(playerid, COLOR_SERVER, "SYNTAX: {FFFFFF}/editobject [object id]");

	if ((id < 0 || id >= MAX_COBJECT) || !ObjectData[id][objExists])
	    return SendClientMessage(playerid, COLOR_SERVER, "ERROR: {FFFFFF} You have specified an invalid Created Object ID.");
	    
	EditingObject[playerid] = id;
	ShowPlayerDialog(playerid, DIALOG_EDIT, DIALOG_STYLE_LIST, "Object Editing", "Edit with Move Object\nWith Coordinate", "Select", "Cancel");
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
	}
	if (response == EDIT_RESPONSE_FINAL || response == EDIT_RESPONSE_CANCEL)
	{
	    if (EditingObject[playerid] != -1)
			Object_Refresh(EditingObject[playerid]);
			
        EditingObject[playerid] = -1;
	}
	return 1;
}
