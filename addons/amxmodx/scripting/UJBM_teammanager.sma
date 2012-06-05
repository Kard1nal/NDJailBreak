#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#define m_iVGUI			510
#define m_fGameHUDInitialized	349

#define get_bit(%1,%2) 		( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)	 	%1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )
#define TEAM_REFRESH_DELAY 60.0




// Old Style Menus
stock const FIRST_JOIN_MSG[] =		"#Team_Select";
stock const FIRST_JOIN_MSG_SPEC[] =	"#Team_Select_Spect";
stock const INGAME_JOIN_MSG[] =		"#IG_Team_Select";
stock const INGAME_JOIN_MSG_SPEC[] =	"#IG_Team_Select_Spect";
const iMaxLen = sizeof(INGAME_JOIN_MSG_SPEC);

// New VGUI Menus
stock const VGUI_JOIN_TEAM_NUM =		2;


new g_PlayerNomic
new gp_TeamRatio
new gp_CtMax
new gp_AutoJoin

new CTCount
new TCount
new g_AcceptRules = 0
new g_MsgShowMenu

public plugin_init()
{
	
	register_plugin("[UJBM] Team Manager", "1.1", "R_O_O_T");
	//register_event("TeamInfo", "event_TeamInfo", "a");
	register_dictionary("ujbm.txt")
	register_message(get_user_msgid("ShowMenu"), "message_ShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "message_VGUIMenu");
	g_MsgShowMenu = get_user_msgid("ShowMenu")
	
	register_concmd("jb_nomic", "adm_nomic", ADMIN_KICK)
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	register_clcmd("chooseteam","show_team_menu",0,"")
	

	register_clcmd("jointeam", "jointeam")
	register_clcmd("joinclass", "jointeam")
	
	gp_TeamRatio = register_cvar("jb_teamratio", "3")
	gp_CtMax = register_cvar("jb_maxct", "6")
	gp_AutoJoin = register_cvar("jb_autojoin", "1")
	
	
	server_cmd("sv_restartround 10")
	
	
}




public message_ShowMenu(iMsgid, iDest, id)
{
	static sMenuCode[iMaxLen];
	get_msg_arg_string(4, sMenuCode, sizeof(sMenuCode) - 1);
	if(equal(sMenuCode, FIRST_JOIN_MSG) || equal(sMenuCode, FIRST_JOIN_MSG_SPEC))
	{
		if (get_pcvar_num ( gp_AutoJoin) == 1)  set_autojoin_task(id, iMsgid)
		else show_team_menu(id)
		return PLUGIN_HANDLED;
		
	}
	return PLUGIN_CONTINUE;
}

public message_VGUIMenu(iMsgid, iDest, id)
{
	if(get_msg_arg_int(1) != VGUI_JOIN_TEAM_NUM)
	{
		return PLUGIN_CONTINUE;
	}
	
	
	if (get_pcvar_num ( gp_AutoJoin) == 1)  set_autojoin_task(id, iMsgid)
	else show_team_menu(id)
	return PLUGIN_HANDLED;
}

public task_Autojoin(iParam[], id)
{
	new iMsgBlock = get_msg_block(iParam[0]);
	set_msg_block(iParam[0], BLOCK_SET);
	engclient_cmd(id, "jointeam", "1")
	engclient_cmd(id, "joinclass", "1")
	
	set_msg_block(iParam[0], iMsgBlock);
	
	
	
}



public count_teams()
{
	CTCount = 0
	TCount = 0
	
	
	new Players[32] 
	new playerCount, i 
	get_players(Players, playerCount, "") 
	for (i=0; i<playerCount; i++) 
	{
		if (is_user_connected(Players[i])) 
		{
			if (cs_get_user_team(Players[i]) == CS_TEAM_CT) CTCount++;
			if (cs_get_user_team(Players[i]) == CS_TEAM_T) TCount++;
		}
	}
	
	
	
	
}

bool:is_ct_allowed()
{
new count
count = ((TCount + CTCount) / get_pcvar_num(gp_TeamRatio))
if(count < 2)
	count = 2
	
	else if(count > get_pcvar_num(gp_CtMax))
		count = get_pcvar_num(gp_CtMax)
if( count > CTCount )
	{
		return true
	} 
	
	
return false
}


stock set_autojoin_task(id, iMsgid)
{

		new iParam[2];
		iParam[0] = iMsgid;
		set_task(0.1, "task_Autojoin", id, iParam, sizeof(iParam));
	
}



public team_choice(id, menu, item)
{
	static dst[32], data[5], access, callback
	
	static restore, vgui, msgblock

	if(item == MENU_EXIT)
	{
		msgblock = get_msg_block(g_MsgShowMenu)
		set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
		dllfunc(DLLFunc_ClientPutInServer, id)
		set_msg_block(g_MsgShowMenu, msgblock)
		set_pdata_int(id, m_fGameHUDInitialized, 1)
		engclient_cmd(id, "jointeam", "6")
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	restore = get_pdata_int(id, m_iVGUI)
	vgui = restore & (1<<0)
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore & ~(1<<0))

		
	//	static roundloop
	//roundloop = floatround(get_pcvar_float(gp_RetryTime) / 2)
	//team_count()
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	menu_destroy(menu)
	
	
	
	switch(data[0])
	{
		case('1'): 
		{
			msgblock = get_msg_block(g_MsgShowMenu)
			set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
			engclient_cmd(id, "jointeam", "1")
			engclient_cmd(id, "joinclass", "1")
			set_msg_block(g_MsgShowMenu, msgblock)

		}
		case('2'): 
		{
			if(!is_user_admin(id) && get_bit(g_PlayerNomic, id))
				return PLUGIN_HANDLED
			
			if(is_ct_allowed() || is_user_admin(id))
			{
			count_teams()
			msgblock = get_msg_block(g_MsgShowMenu)
			set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
			engclient_cmd(id, "jointeam", "2")
			engclient_cmd(id, "joinclass", "2")
			set_msg_block(g_MsgShowMenu, msgblock)
			}
			else
				client_print(id, print_center, "%L", LANG_SERVER, "UJBM_TEAM_CTFULL")
			//if (g_RoundStarted >= roundloop) user_silentkill(id)
		}
		
	}
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore)
	return PLUGIN_HANDLED
}



public show_team_menu(id)
{
	static menu, menuname[32], option[64]
	
	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_TEAM_MENU")
	menu = menu_create(menuname, "team_choice")
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_TEAM_MENU_T")
	menu_additem(menu, option, "1", 0)
	if (is_ct_allowed())
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_TEAM_MENU_CT")
		menu_additem(menu, option, "2", 0)
	}
	else
	{
		formatex(option, charsmax(option), "\d%L\w", LANG_SERVER, "UJBM_TEAM_MENU_CT")
		menu_additem(menu, option, "2", 0)
	}
	menu_display(id, menu)
	
	
	
	
	
	return PLUGIN_HANDLED
	
	
	
}



public cmd_nomic(id)
{
	static CsTeams:team
	team = cs_get_user_team(id)
	if(team == CS_TEAM_CT)
	{
		if (is_user_alive(id)) strip_user_weapons(id)
		if(!is_user_admin(id))
			set_bit(g_PlayerNomic, id)
		
		user_silentkill(id)
		cs_set_user_team(id, CS_TEAM_T)
	}
	return PLUGIN_HANDLED
}


public client_putinserver(id)
{
	clear_bit(g_PlayerNomic, id)
}



public rules_accept(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static dst[32], data[5], access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	menu_destroy(menu)
	
	
	switch(data[0])
	{
		case('1'):
		{
			cmd_nomic(id)
		}
		
		case('2'):
		{
			set_bit(g_AcceptRules,id)
		}
	}
	return PLUGIN_HANDLED
}




public cmd_accept_rules(id)
	
{
if (is_user_alive(id))
{
	static menu, menuname[512], option[128]
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_RULES_ACCEPT")
		menu = menu_create(menuname, "rules_accept")
		
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_RULES_NOACCEPT")
		menu_additem(menu, option, "1", 0)
		
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_RULES_YESACCEPT")
		menu_additem(menu, option, "2", 0)
		menu_display(id, menu)
	}
	
}
return PLUGIN_HANDLED
}


public player_spawn(id)
{

if (! get_bit(g_AcceptRules, id)) cmd_accept_rules(id)
return HAM_IGNORED
}

public client_disconnect(id)
{
count_teams()
}

public adm_nomic(id)
{
static player, user[32]
if(id == 0 || is_user_admin(id))
{
	read_argv(1, user, charsmax(user))
	player = cmd_target(id, user, 3)
	if(is_user_connected(player))
	{
		cmd_nomic(player)
	}
}
return PLUGIN_HANDLED
}


public jointeam(id)
{
	return PLUGIN_HANDLED
}




