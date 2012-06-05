#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#define PLUGIN_NAME	"[ND.JBM] Main"
#define PLUGIN_AUTHOR	"ND.TEAM"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_CVAR	"ND JailBreak Manager"

#define TASK_STATUS	2487000
#define TASK_FREEDAY	2487100
#define TASK_ROUND	2487200
#define TASK_HELP	2487300
#define TASK_SAFETIME	2487400
#define TASK_FREEEND	2487500
#define TASK_GIVEITEMS	2487600
#define TEAM_MENU	"#Team_Select_Spect"
#define TEAM_MENU2	"#Team_Select"
#define HUD_DELAY		Float:4.0
#define CELL_RADIUS	Float:200.0

#define get_bit(%1,%2) 		( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)	 	%1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )

#define vec_len(%1)		floatsqroot(%1[0] * %1[0] + %1[1] * %1[1] + %1[2] * %1[2])
#define vec_mul(%1,%2)		( %1[0] *= %2, %1[1] *= %2, %1[2] *= %2)
#define vec_copy(%1,%2)		( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])

// Offsets
#define m_iPrimaryWeapon	116
#define m_iVGUI			510
#define m_fGameHUDInitialized	349
#define m_fNextHudTextArgsGameTime	198

#define GRENCOST	10000
#define HECOST	12000
#define CHAINCOST	14000
#define SHIELDCOST	16000
#define FDCOST	12000
#define CROWBARCOST	16000
#define CTDEAGLECOST 1000
#define CTFLASHCOST 3000
#define HPCOST 4000
#define NVGCOST 1500
#define CTSMOKECOST 3000
#define FLASHLIGHTCOST 2000

#define ALIEN_RED 180
#define ALIEN_GREEN 240
#define ALIEN_BLUE 140


#define OFFSET_TEAM 		114
#define OFFSET_PAINSHOCK 108
#define OFFSET_LINUX 5
#define Keyscl_min (1<<0)|(1<<1) // Keys: 12





enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }
enum _lastrequest { _knife, _deagle, _freeday, _weapon }
enum _duel { _name[16], _csw, _entname[32], _opt[32], _sel[32] }

new gp_PrecacheSpawn
new gp_PrecacheKeyValue
new gp_CrowbarMul
new gp_BoxMax
new gp_TalkMode
new gp_VoiceBlock
new gp_RetryTime
new gp_FDLength
new gp_ButtonShoot
new gp_SimonSteps
new gp_GlowModels
new gp_AutoLastresquest
new gp_LastRequest
new gp_NoGame
new gp_Motd
new gp_TShop
new gp_CTShop
new gp_GameHP
new gp_Games
new gp_ShowColor
new gp_Effects
new gp_ShowFD
new gp_ShowWanted
new g_MaxClients
new g_MsgStatusText
new g_MsgStatusIcon
new g_MsgClCorpse
new g_MsgMOTD
new gc_TalkMode
new gc_VoiceBlock
new gc_SimonSteps
new gc_ButtonShoot
new gp_Help
new Float:gc_CrowbarMul

// Precache

new const _FistModels[][] = { "models/p_bknuckles.mdl", "models/v_bknuckles.mdl" }
new const _CrowbarModels[][] = { "models/p_crowbar.mdl", "models/v_crowbar.mdl" , "models/w_crowbar.mdl" }
new const _RpgModels[][] = { "models/p_rpg.mdl", "models/v_rpg.mdl" , "models/w_rpg.mdl", "models/rpgrocket.mdl" }
new const _RpgSounds[][] = { "weapons/rocketfire1.wav", "weapons/explode3.wav", "weapons/rocket1.wav" }

new SpriteExplosion
new const _FistSounds[][] = { "weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav" }
new const _RemoveEntities[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
}

new const _WeaponsFree[][] = { "weapon_m4a1", "weapon_deagle", "weapon_g3sg1", "weapon_elite", "weapon_ak47", "weapon_mp5navy", "weapon_m3" }
new const _WeaponsFreeCSW[] = { CSW_M4A1, CSW_DEAGLE, CSW_G3SG1, CSW_ELITE, CSW_AK47, CSW_MP5NAVY, CSW_M3 }
new const _WeaponsFreeAmmo[] = { 999, 999, 999, 999, 999, 999, 999, 999 }

new const _Duel[][_duel] =
{
{ "Deagle", CSW_DEAGLE, "weapon_deagle", "UJBM_MENU_LASTREQ_OPT4", "UJBM_MENU_LASTREQ_SEL4" },
{ "Grenades", CSW_FLASHBANG, "weapon_flashbang", "UJBM_MENU_LASTREQ_OPT5", "UJBM_MENU_LASTREQ_SEL5" }, //rpg!!!
///rpg
{ "Grenades", CSW_HEGRENADE, "weapon_hegrenade", "UJBM_MENU_LASTREQ_OPT6", "UJBM_MENU_LASTREQ_SEL6" },
{ "m249", CSW_M249, "weapon_m249", "UJBM_MENU_LASTREQ_OPT8", "UJBM_MENU_LASTREQ_SEL8" },
{ "Awp", CSW_AWP, "weapon_awp", "UJBM_MENU_LASTREQ_OPT7", "UJBM_MENU_LASTREQ_SEL7" }
}


// Reasons
new const g_Reasons[][] =  {
"",
"UJBM_PRISONER_REASON_1",
"UJBM_PRISONER_REASON_2",
"UJBM_PRISONER_REASON_3",
"UJBM_PRISONER_REASON_4",
"UJBM_PRISONER_REASON_5",
"UJBM_PRISONER_REASON_6"
}

// HudSync: 0=ttinfo / 1=info / 2=simon / 3=ctinfo / 4=player / 5=day / 6=center / 7=help / 8=timer
new const g_HudSync[][_hud] =
{
{0,  0.6,  0.2,  2.0},
{0, -1.0,  0.7,  5.0},
{0,  0.1,  0.2,  2.0},
{0,  0.1,  0.3,  2.0},
{0, -1.0,  0.9,  3.0},
{0,  0.6,  0.1,  3.0},
{0, -1.0,  0.6,  3.0},
{0,  0.8,  0.3, 20.0},
{0, -1.0,  0.4,  3.0},
{0,  0.1,  0.5,  2.0},
{0,  -1.0,  0.55,  2.0}


}

// Colors: 0:Simon / 1:Freeday / 2:CT Duel / 3:TT Duel
new const g_Colors[][3] = { {0, 255, 0}, {255, 140, 0}, {0, 0, 255}, {255, 0, 0} }


//new CsTeams:g_PlayerTeam[33]
new Trie:g_CellManagers
new g_JailDay
new g_PlayerJoin
new g_PlayerReason[33]
new g_PlayerSpect[33]
new g_PlayerSimon[33]

new g_PlayerWanted
new g_PlayerCrowbar
new g_PlayerVoice
new g_PlayerRevolt
new g_PlayerHelp
new g_PlayerFreeday
new g_PlayerLast

new g_NoShowShop = 0
/*new g_FreedayNext*/
//new g_TeamCount[CsTeams]
//new g_TeamAlive[CsTeams]
new g_BoxStarted
/*new g_CrowbarCount*/
new g_Simon
new g_SimonAllowed
new g_SimonTalking
new g_SimonVoice
new g_RoundStarted
new g_LastDenied
new g_Freeday
new g_RoundEnd
new m_iTrail
new g_Duel
new g_DuelA
new g_DuelB
new g_Buttons[10]
new g_GameMode = 1
new g_nogamerounds
new gmsgSetFOV
new gp_Bind
new g_BackToCT = 0
new g_Fonarik = 0
new CTallowed[31]
new Tallowed[31]
new bindstr[33]
new g_iMsgSayText

new gmsgBombDrop



public plugin_init()
{

unregister_forward(FM_Spawn, gp_PrecacheSpawn)
unregister_forward(FM_KeyValue, gp_PrecacheKeyValue)


register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

register_dictionary("ujbm.txt")

g_MsgStatusText = get_user_msgid("StatusText")
g_MsgStatusIcon = get_user_msgid("StatusIcon")
g_MsgMOTD = get_user_msgid("MOTD")
g_MsgClCorpse = get_user_msgid("ClCorpse")
gmsgBombDrop   = get_user_msgid("BombDrop")
new Copyright[10] = PLUGIN_AUTHOR;

register_touch("crowbar", "worldspawn",	"cr_bar_snd")


register_message(g_MsgStatusText, "msg_statustext")
register_message(g_MsgStatusIcon, "msg_statusicon")
register_message(g_MsgMOTD, "msg_motd")
register_message(g_MsgClCorpse, "msg_clcorpse")


register_event("CurWeapon", "current_weapon", "be", "1=1", "2=29")
register_event("CurWeapon", "current_weapon_fl", "be", "1=1", "2=25")
register_event("StatusValue", "player_status", "be", "1=2", "2!0")
register_event("StatusValue", "player_status", "be", "1=1", "2=0")

register_impulse(100, "impulse_100")


register_forward(FM_Touch, "crowbar_touch")

RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_flashbang", "rpg_pre")
//RegisterHam(Ham_Weapon_WeaponIdle, "weapon_flashbang", "rpg_idle")
RegisterHam(Ham_Weapon_Reload, "weapon_flashbang", "rpg_reload")

register_touch("rpg_missile", "worldspawn",	"rocket_touch")
register_touch("rpg_missile", "player",		"rocket_touch")


RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
RegisterHam(Ham_TakeDamage, "player", "player_damage")

RegisterHam(Ham_TraceAttack, "player", "player_attack")


RegisterHam(Ham_TraceAttack, "func_button", "button_attack")
RegisterHam(Ham_Killed, "player", "player_killed", 1)
RegisterHam(Ham_Item_PreFrame, "player", "player_maxspeed", 1 );

register_forward(FM_SetClientKeyValue, "set_client_kv")
register_forward(FM_EmitSound, "sound_emit")
register_forward(FM_Voice_SetClientListening, "voice_listening")
register_forward(FM_CmdStart, "player_cmdstart", 1)


register_logevent("round_end", 2, "1=Round_End")
register_logevent("round_first", 2, "0=World triggered", "1&Restart_Round_")
register_logevent("round_first", 2, "0=World triggered", "1=Game_Commencing")
register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")


register_clcmd("drop","drop",0,"")
register_clcmd("+simonvoice", "cmd_voiceon")
register_clcmd("-simonvoice", "cmd_voiceoff")

register_clcmd("say /voice", "cmd_simon_micr")	
register_clcmd("say /micr", "cmd_simon_micr")	
register_clcmd("say /fd", "cmd_freeday")
register_clcmd("say /menu", "cmd_simonmenu")



register_clcmd("say /freeday", "cmd_freeday")
register_clcmd("say /day", "cmd_freeday")
register_clcmd("say /lr", "cmd_lastrequest")
register_clcmd("say /lastrequest", "cmd_lastrequest")
register_clcmd("say /duel", "cmd_lastrequest")
register_clcmd("say /simon", "cmd_simon")
register_clcmd("say /open", "cmd_open")

register_clcmd("say /help", "cmd_help")

//register_clcmd("say /lr1", "cmd_lastrequest1")
///kids protection

if (Copyright[6] != 'T' || Copyright[2] != 'O' || Copyright[0] != 'R' ||  Copyright[4] != 'O' ) return PLUGIN_HANDLED
///kids protection
gp_GlowModels = register_cvar("jb_glowmodels", "0")
gp_SimonSteps = register_cvar("jb_simonsteps", "1")
gp_CrowbarMul = register_cvar("jb_crowbarmultiplier", "25.0")

gp_BoxMax = register_cvar("jb_boxmax", "6")
gp_RetryTime = register_cvar("jb_retrytime", "10.0")

gp_AutoLastresquest = register_cvar("jb_autolastrequest", "1")
gp_LastRequest = register_cvar("jb_lastrequest", "1")
gp_Motd = register_cvar("jb_motd", "1")
gp_TalkMode = register_cvar("jb_talkmode", "2")	// 0-alltak / 1-tt talk / 2-tt no talk
gp_VoiceBlock = register_cvar("jb_blockvoice", "0")	// 0-dont block / 1-block voicerecord / 2-block voicerecord except simon
gp_ButtonShoot = register_cvar("jb_buttonshoot", "1")	// 0-standard / 1-func_button shoots!
gp_NoGame = register_cvar("jb_nogamerounds", "10")
gp_TShop = register_cvar("jb_tshop", "abcdefg")
gp_CTShop = register_cvar("jb_ctshop", "abcdef")
gp_Games = register_cvar("jb_games", "abcdef")
gp_Bind = register_cvar("jb_bindkey","v")
gp_Help = register_cvar("jb_autohelp","2")
gp_FDLength = register_cvar("jb_fdlen","120.0")
gp_GameHP = register_cvar("jb_hpmultiplier","200")
gp_ShowColor = register_cvar("jb_hud_showcolor","1")
gp_ShowFD = register_cvar("jb_hud_showfd","1")
gp_ShowWanted = register_cvar("jb_hud_show_wanted","1")
gp_Effects= register_cvar("jb_game_effects","2")


g_MaxClients = get_global_int(GL_maxClients)

for(new i = 0; i < sizeof(g_HudSync); i++)
g_HudSync[i][_hudsync] = CreateHudSyncObj()


gmsgSetFOV = get_user_msgid( "SetFOV" )
g_iMsgSayText = get_user_msgid("SayText");


set_task(320.0, "help_trollface", _, _, _, "b")


setup_buttons()
return PLUGIN_CONTINUE
}


public plugin_precache()
{
static i
precache_model("models/player/ujbm_v1/ujbm_v1.mdl")




for(i = 0; i < sizeof(_FistModels); i++)
	precache_model(_FistModels[i])
	
for(i = 0; i < sizeof(_CrowbarModels); i++)
		precache_model(_CrowbarModels[i])
	
for(i = 0; i < sizeof(_RpgModels); i++)
		precache_model(_RpgModels[i])
	
	
for(i = 0; i < sizeof(_FistSounds); i++)
		precache_sound(_FistSounds[i])
	
for(i = 0; i < sizeof(_RpgSounds); i++)
		precache_sound(_RpgSounds[i])
	
SpriteExplosion = precache_model("sprites/fexplo1.spr") 	
m_iTrail = precache_model("sprites/smoke.spr")
	
precache_sound("alien_alarm.wav")
precache_sound("jbextreme/nm_goodbadugly.wav")
precache_sound("jbextreme/brass_bell_C.wav")
precache_sound("ambience/the_horror2.wav")
precache_sound("debris/metal2.wav")
precache_sound("items/gunpickup2.wav")
precache_sound("weapons/cbar_hit1.wav")
precache_sound("weapons/cbar_miss1.wav")
precache_sound("jbextreme/box.mp3")

	
	
	
g_CellManagers = TrieCreate()
gp_PrecacheSpawn = register_forward(FM_Spawn, "precache_spawn", 1)
gp_PrecacheKeyValue = register_forward(FM_KeyValue, "precache_keyvalue", 1)
}

public plugin_natives() 
{ 
	register_library("ujbm"); 
	register_native ("get_simon", "_get_simon",0)
	register_native ("get_gamemode", "_get_gamemode",0)
	register_native ("get_fd", "_get_fd",0)
	register_native ("get_wanted", "_get_wanted",0)
	register_native ("get_last", "_get_last",0)
} 

public _get_simon(iPlugin, iParams) 
{ 
	return g_Simon;
}  

public _get_last(iPlugin, iParams) 
{ 
	return g_PlayerLast;
}  

public _get_gamemode(iPlugin, iParams) 
{ 
	return g_GameMode;
}  

public bool:_get_fd(iPlugin, iParams) 
{ 
	new id = get_param(1);
	if (get_bit(g_PlayerFreeday, id))return true;
	return false;
}  


public bool:_get_wanted(iPlugin, iParams) 
{ 
	new id = get_param(1);
	if (get_bit(g_PlayerWanted, id))return true;
	return false;
}  



public precache_spawn(ent)
{
	if(is_valid_ent(ent))
	{
		static szClass[33]
		entity_get_string(ent, EV_SZ_classname, szClass, sizeof(szClass))
		for(new i = 0; i < sizeof(_RemoveEntities); i++)
			if(equal(szClass, _RemoveEntities[i]))
			remove_entity(ent)
	}
}


public precache_keyvalue(ent, kvd_handle)
{
	static info[32]
	if(!is_valid_ent(ent))
		return FMRES_IGNORED
	
	get_kvd(kvd_handle, KV_ClassName, info, charsmax(info))
	if(!equal(info, "multi_manager"))
		return FMRES_IGNORED
	
	get_kvd(kvd_handle, KV_KeyName, info, charsmax(info))
	TrieSetCell(g_CellManagers, info, ent)
	return FMRES_IGNORED
}

public client_putinserver(id)
{
	clear_bit(g_PlayerJoin, id)
	clear_bit(g_PlayerHelp, id)
	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerWanted, id)
	clear_bit(g_SimonTalking, id)
	clear_bit(g_SimonVoice, id)
	g_PlayerSpect[id] = 0
	g_PlayerSimon[id] = 0
	
	first_join(id)
	
}


public client_disconnect(id)
{
	if(g_Simon == id)
	{
		g_Simon = 0
		ClearSyncHud(0, g_HudSync[2][_hudsync])
		player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "UJBM_SIMON_HASGONE")
	}
	else if(g_PlayerLast == id || (g_Duel && (id == g_DuelA || id == g_DuelB)))
	{
		g_Duel = 0
		g_DuelA = 0
		g_DuelB = 0
		g_LastDenied = 0
		//g_BlockWeapons = 0
		g_PlayerLast = 0
	}
	
}

public client_PostThink(id)
{
	if(id != g_Simon || !gc_SimonSteps || !is_user_alive(id) ||
	!(entity_get_int(id, EV_INT_flags) & FL_ONGROUND) || entity_get_int(id, EV_ENT_groundentity))
	return PLUGIN_CONTINUE
	
	static Float:origin[3]
	static Float:last[3]
	
	entity_get_vector(id, EV_VEC_origin, origin)
	if(get_distance_f(origin, last) < 32.0)
	{
		return PLUGIN_CONTINUE
	}
	
	vec_copy(origin, last)
	if(entity_get_int(id, EV_INT_bInDuck))
		origin[2] -= 18.0
	else
		origin[2] -= 36.0
	
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0)
	write_byte(TE_WORLDDECAL)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_byte(105)
	message_end()
	
	return PLUGIN_CONTINUE
}


public msg_statustext(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public msg_statusicon(msgid, dest, id)
{
	static icon[5] 
	get_msg_arg_string(2, icon, charsmax(icon))
	if(icon[0] == 'b' && icon[2] == 'y' && icon[3] == 'z')
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0))
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}
\
public msg_motd(msgid, dest, id)
{
	if(get_pcvar_num(gp_Motd))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public msg_clcorpse(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public current_weapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	if(get_bit(g_PlayerCrowbar, id))
	{
		set_pev(id, pev_viewmodel2, _CrowbarModels[1])
		set_pev(id, pev_weaponmodel2, _CrowbarModels[0])
	}
	else
	{
		set_pev(id, pev_viewmodel2, _FistModels[1])
		set_pev(id, pev_weaponmodel2, _FistModels[0])
	}
	return PLUGIN_CONTINUE
}

public player_status(id)
{
	
	static type, player, CsTeams:team, name[32], health
	type = read_data(1)
	player = read_data(2)
	switch(type)
	{
		case(1):
		{
			ClearSyncHud(id, g_HudSync[1][_hudsync])
		}
		case(2):
		{
			if (player == g_Simon) return PLUGIN_HANDLED
			team = cs_get_user_team(player)
			if((team != CS_TEAM_T) && (team != CS_TEAM_CT))
				return PLUGIN_HANDLED
			
			health = get_user_health(player)
			get_user_name(player, name, charsmax(name))
			player_hudmessage(id, 4, 2.0, {0, 255, 0}, "%L", LANG_SERVER,
			(team == CS_TEAM_T) ? "UJBM_PRISONER_STATUS" : "UJBM_GUARD_STATUS", name, health)
		}
	}
	
	return PLUGIN_HANDLED
}

public impulse_100(id)
{
	if(!get_bit(g_Fonarik,id))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}






public  player_maxspeed(id)
{
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	
	switch (g_GameMode)
	{
		case 3: 
		{
			if (cs_get_user_team(id) == CS_TEAM_T) set_user_maxspeed(id ,310.0)
		}
		case  4: 
		{ 
			
			if (g_Simon == id) set_user_maxspeed(id ,450.0)
			
		}
		case  5: 
		{ 
			
			if (g_Simon == id) set_user_maxspeed(id ,320.0)
			
		}
		
		default:
	{
		set_user_maxspeed(id ,250.0)
		
	}
}
	return PLUGIN_HANDLED

}





public player_spawn(id)
{
	static CsTeams:team

	if(!is_user_connected(id))
		return HAM_IGNORED
	
	set_pdata_float(id, m_fNextHudTextArgsGameTime, get_gametime() + 999999.0)
	player_strip_weapons(id)
	if(g_RoundEnd)
	{
		g_RoundEnd = 0
		g_JailDay++
	}
	
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
	
	
	clear_bit(g_PlayerWanted, id)
	team = cs_get_user_team(id)
	
	if (!get_bit(g_NoShowShop,id)) cmd_shop(id)
	
	
	
	
	switch(team)
	{
		case(CS_TEAM_T):
		{
			g_PlayerLast = 0
			if(!g_PlayerReason[id])
				g_PlayerReason[id] = random_num(1, 6)
			
			player_hudmessage(id, 0, 5.0, {255, 0, 255}, "%L %L", LANG_SERVER, "UJBM_PRISONER_REASON",
			LANG_SERVER, g_Reasons[g_PlayerReason[id]])
			
			
			client_infochanged(id)
			entity_set_int(id, EV_INT_body, 2)
			if (g_GameMode == 0)
			{ 
				entity_set_int(id, EV_INT_skin, 3)
			}  else
			/*if(get_bit(g_FreedayAuto, id))
		{			
			freeday_set(0, id)
			clear_bit(g_FreedayAuto, id)
		}
		else*/
	{
		entity_set_int(id, EV_INT_skin, random_num(0, 2))
	}
	
	
			cs_set_user_armor(id, 0, CS_ARMOR_NONE)

}
case(CS_TEAM_CT):
{
	
	
	g_PlayerSimon[id]++
	
	set_user_info(id, "model", "ujbm_v1")
	entity_set_int(id, EV_INT_body, 3)
	cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM)
	
	new r = random_num(1,3)
	switch (r)
	{
		case 1:
		{
			set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 6.0)
			show_hudmessage(id, "%L", LANG_SERVER, "UJBM_WARN_FK")
		}
		case 2:
		{
			set_hudmessage(0, 255, 0, -1.0, 0.60, 0, 6.0, 6.0)
			show_hudmessage(id, "%L", LANG_SERVER, "UJBM_WARN_RULES")
		}
		default:
	{
		set_hudmessage(0, 212, 255, -1.0, 0.80, 0, 6.0, 6.0)
		show_hudmessage(id, "%L", LANG_SERVER, "UJBM_WARN_MICR")
	}
}

}
}




	if (g_GameMode == 4 || g_GameMode == 5)
{
	
if (cs_get_user_team(id) == CS_TEAM_CT)
{

set_bit(g_BackToCT, id)
cs_set_user_team2(id, CS_TEAM_T)
}

new j = 0;			
strip_user_weapons(id)
j = random_num(0, sizeof(_WeaponsFree) - 1)	
give_item(id, "weapon_knife")
give_item(id, _WeaponsFree[j])
cs_set_user_bpammo(id, _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])

}


	return HAM_IGNORED
}

public task_inviz()
{
/*
message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, g_Simon)
write_short(~0)
write_short(~0)
write_short(0x0004) // stay faded
write_byte(ALIEN_RED)
write_byte(ALIEN_GREEN)
write_byte(ALIEN_BLUE)
write_byte(100)
message_end()
g_Faded = 1*/
set_user_rendering(g_Simon, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0 )	
}

public player_damage(victim, ent, attacker, Float:damage, bits)
{
if (victim == attacker || !is_user_connected(attacker))
return HAM_IGNORED;

if ((g_GameMode  ==  5 )&& (g_Simon  ==  attacker) )
{
set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderNormal, 0 )
/*
if (g_Faded)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, g_Simon)
	write_short(1<<10)
	write_short(1<<10)
	write_short(0x0000) // fade out
	write_byte(ALIEN_RED)
	write_byte(ALIEN_GREEN)
	write_byte(ALIEN_BLUE)
	write_byte(100)
	message_end()
}
g_Faded = 0*/
remove_task(7447)
set_task(3.1, "task_inviz",7447);
}
/*
if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
return HAM_IGNORED
*/

switch(g_Duel)
{
	case(0):
	{
		if(attacker == ent && get_user_weapon(attacker) == CSW_KNIFE && get_bit(g_PlayerCrowbar, attacker) )
		{
			SetHamParamFloat(4, damage * gc_CrowbarMul)
			return HAM_OVERRIDE
		}
	}
	case(2):
	{
		if(attacker != g_PlayerLast)
			return HAM_SUPERCEDE
		}
		default:
	{
		if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
			return HAM_IGNORED
			
		return HAM_SUPERCEDE
		}
	}
	
return HAM_IGNORED
}



public player_damage2(victim, ent, attacker, Float:damage, bits)
{
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	//if ((g_GameMode  ==  4 )&& (g_Simon  ==  victim) )  set_pdata_float(victim, OFFSET_PAINSHOCK, 1.0, OFFSET_LINUX)
	/*
	if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
		return HAM_IGNORED
	*/
	
	switch(g_Duel)
	{
		case(0):
		{
			if(attacker == ent && get_user_weapon(attacker) == CSW_KNIFE && get_bit(g_PlayerCrowbar, attacker) )
			{
				SetHamParamFloat(4, damage * gc_CrowbarMul)
				return HAM_OVERRIDE
			}
		}
		case(2):
		{
			if(attacker != g_PlayerLast)
				return HAM_SUPERCEDE
		}
		default:
	{
		if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
			return HAM_IGNORED
			
		return HAM_SUPERCEDE
		}
	}
	
	return HAM_IGNORED
}






public  player_attack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	static CsTeams:vteam, CsTeams:ateam
	if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
		return HAM_IGNORED
	
	vteam = cs_get_user_team(victim)
	ateam = cs_get_user_team(attacker)
	
	if(ateam == CS_TEAM_CT && vteam == CS_TEAM_CT)
		return HAM_SUPERCEDE
	
	switch(g_Duel)
	{
		case(0):
		{
			if(ateam == CS_TEAM_CT && vteam == CS_TEAM_T)
			{
				if(get_bit(g_PlayerRevolt, victim))
				{
					clear_bit(g_PlayerRevolt, victim)
					hud_status(0)
				}
				return HAM_IGNORED
			}
		}
		case(2):
		{
			if(attacker != g_PlayerLast)
				return HAM_SUPERCEDE
		}
		case(5):
		{
			
		}
		default:
	{
		if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
			return HAM_IGNORED
			
		return HAM_SUPERCEDE
		}
	}
	
	if(ateam == CS_TEAM_T && vteam == CS_TEAM_T && !g_BoxStarted)
		return HAM_SUPERCEDE
	
	if(ateam == CS_TEAM_T && vteam == CS_TEAM_CT &&g_GameMode <=1)
	{
		if(!g_PlayerRevolt)
			revolt_start()
		
		set_bit(g_PlayerRevolt, attacker)
		clear_bit(g_PlayerFreeday, attacker)
	}
	
	return HAM_IGNORED
}

public button_attack(button, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(is_valid_ent(button) && gc_ButtonShoot)
	{
		ExecuteHamB(Ham_Use, button, id, 0, 2, 1.0)
		entity_set_float(button, EV_FL_frame, 0.0)
	}
	
	return HAM_IGNORED
}

public task_last()
{
	new Players[32] 
	new playerCount, i, TAlive
	
	get_players(Players, playerCount, "ac") 
	for (i=0; i<playerCount; i++) 
	{
		if (is_user_connected(Players[i])) 
			
		if ( cs_get_user_team(Players[i]) == CS_TEAM_T )
		{
			TAlive++;
		}
	}	
	if (TAlive == 1) 
	{
		
		for (i=0; i<playerCount; i++) 
		{
			if ( cs_get_user_team(Players[i]) == CS_TEAM_T ) 
			{
				g_PlayerLast = Players[i];
				if (get_pcvar_num(gp_AutoLastresquest)) cmd_lastrequest(Players[i])
				break;
			}
		}
		
	}
	return PLUGIN_CONTINUE
}

public player_killed(victim, attacker, shouldgib)
{
	static CsTeams:vteam, CsTeams:kteam
	
	
	
	
	if(!(0 < attacker <= g_MaxClients) || !is_user_connected(attacker))
		kteam = CS_TEAM_UNASSIGNED
	else
		kteam = cs_get_user_team(attacker)
	
	vteam = cs_get_user_team(victim)
	
	
	
	switch (g_GameMode)
	{
		case 2:
			
		
	{
		
		
		if (vteam == CS_TEAM_T && kteam == CS_TEAM_CT && is_user_connected(attacker))
			give_item(attacker, "ammo_buckshot")
		}
		
		case 4:
		{
			
			if (victim == g_Simon) cs_set_user_money(attacker, 16000)
			else if (attacker == g_Simon) set_user_health(g_Simon, get_user_health(g_Simon) + 100)
			}
		case 5:
		{
			
			if (victim == g_Simon) cs_set_user_money(attacker, 16000)
			else if (attacker == g_Simon) set_user_health(g_Simon, get_user_health(g_Simon) + 100)
			}
		default:
	{
		
		if (vteam == CS_TEAM_T)
		{
			remove_task(677365)
			set_task(2.1, "task_last", 677365)
		}
		
		
		
		if(g_Simon == victim)
		{
			g_Simon = 0
			ClearSyncHud(0, g_HudSync[2][_hudsync])
			player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "UJBM_SIMON_KILLED")
			
			
			if (vteam == CS_TEAM_CT && kteam == CS_TEAM_T && is_user_connected(attacker)) 
				if (victim == g_Simon)
					cs_set_user_money(attacker, cs_get_user_money(attacker) + 3500)
				else cs_set_user_money(attacker, cs_get_user_money(attacker) + 500)
				else  if (vteam == CS_TEAM_T && kteam == CS_TEAM_T && is_user_connected(attacker)) cs_set_user_money(attacker, cs_get_user_money(attacker) + 200)
			}
			
		if (get_bit(g_PlayerCrowbar,victim)) 
			{
				spawn_crowbar(victim)
				clear_bit(g_PlayerCrowbar, victim)
			}
			
			
		switch(g_Duel)
			{
				case(0):
				{
					switch(vteam)
					{
						case(CS_TEAM_CT):
						{
							if(kteam == CS_TEAM_T && !get_bit(g_PlayerWanted, attacker))
							{
								set_bit(g_PlayerWanted, attacker)
								entity_set_int(attacker, EV_INT_skin, 4)
							}
						}
						case(CS_TEAM_T):
						{
							clear_bit(g_PlayerRevolt, victim)
							clear_bit(g_PlayerWanted, victim)
						}
					}
				}
				default:
			{
				if(g_Duel != 2 && (attacker == g_DuelA || attacker == g_DuelB))
				{
					set_user_rendering(victim, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
					set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
					g_Duel = 0
					g_LastDenied = 0
					//g_BlockWeapons = 0
					g_PlayerLast = 0
					if (g_Duel == 5) 
					{
						player_strip_weapons(attacker)
						give_item(attacker,"weapon_knife")
					}
					
					
				}
			}
		}
		
		
		hud_status(0)
	}
}
	return HAM_IGNORED
}



public set_client_kv(id, const info[], const key[])
{
if(equal(key, "model"))
	return FMRES_SUPERCEDE
	
return FMRES_IGNORED
}

public sound_emit(id, channel, sample[])
{
	if(is_user_alive(id) )
	{
		
		if (equal(sample, "weapons/knife_", 14))
			
		
		switch(sample[17])
		{
			case('b'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			case('w'):
			{
				if (get_bit(g_PlayerCrowbar,id))
					emit_sound(id, CHAN_WEAPON, "weapons/cbar_hit1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
				else
					emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
			}
			case('1', '2'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/bullet_hit2.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM)
			}
			
			case('s'):
			{
				if (get_bit(g_PlayerCrowbar,id))
					emit_sound(id, CHAN_WEAPON, "weapons/cbar_miss1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
		} 
		
		
		
		
		return FMRES_SUPERCEDE
		
		
		
	}
	return FMRES_IGNORED
}

public voice_listening(receiver, sender, bool:listen)
{
	if((receiver == sender))
		return FMRES_IGNORED
	
	if(is_user_admin(sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, true)
		return FMRES_SUPERCEDE
	}
	
	switch(gc_VoiceBlock)
	{
		case(2):
		{
			if((sender != g_Simon) && (!get_bit(g_SimonVoice, sender) && gc_VoiceBlock))
			{
				engfunc(EngFunc_SetClientListening, receiver, sender, false)
				return FMRES_SUPERCEDE
			}
		}
		case(1):
		{
			if(!get_bit(g_SimonVoice, sender) && gc_VoiceBlock)
			{
				engfunc(EngFunc_SetClientListening, receiver, sender, false)
				return FMRES_SUPERCEDE
			}
		}
	}
	if(!is_user_alive(sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}
	
	if(sender == g_Simon)
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, true)
		return FMRES_SUPERCEDE
	}
	
	if(get_bit(g_PlayerVoice, sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, true)
		return FMRES_SUPERCEDE
	}
	
	listen = true
	
	if(g_SimonTalking && (sender != g_Simon))
	{
		listen = false
	}
	else
	{
		static CsTeams:steam
		steam = cs_get_user_team(sender)
		switch(gc_TalkMode)
		{
			case(2):
			{
				listen = (steam == CS_TEAM_CT)
			}
			case(1):
			{
				listen = (steam == CS_TEAM_CT || steam == CS_TEAM_T)
			}
		}
	}
	
	engfunc(EngFunc_SetClientListening, receiver, sender, listen)
	return FMRES_SUPERCEDE
}

public player_cmdstart(id, uc, random)
{
	if(g_Duel > 3)
	{
		if (_Duel[g_Duel - 4][_csw] != CSW_M249) 	cs_set_user_bpammo(id, _Duel[g_Duel - 4][_csw], 1)
	}
}

public round_first()
{
	
	g_JailDay = 0
	for(new i = 1; i <= g_MaxClients; i++)
	{
		g_PlayerSimon[i] = 0
		
	}
	
	set_cvar_num("sv_alltalk", 1)
	set_cvar_num("mp_roundtime", 2)
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("mp_tkpunish", 0)
	set_cvar_num("mp_friendlyfire", 1)
	round_end()
	g_GameMode = 1	
}

public round_end()
{
	server_cmd("jb_unblock_weapons")
	g_PlayerRevolt = 0
	g_PlayerFreeday = 0
	/*  g_PlayerVoice = 0*/
	g_PlayerLast = 0
	g_BoxStarted = 0
	/*g_CrowbarCount = 0*/
	g_Simon = 0
	g_SimonAllowed = 0
	g_RoundStarted = 0
	g_LastDenied = 0
	
	
	new Ent = -1 
	while((Ent = find_ent_by_class(Ent, "rpg_off")))
	{
		remove_entity(Ent)
	}
	g_Freeday = 0
	/*g_FreedayNext = (random_num(0,99) >= 95)*/
	g_RoundEnd = 1
	g_Duel = 0
	g_Fonarik = 0
	
	
	
	remove_task(TASK_STATUS)
	remove_task(TASK_FREEDAY)
	remove_task(TASK_FREEEND)
	remove_task(TASK_ROUND)
	remove_task(TASK_GIVEITEMS)
	
	
	
	
	
	for(new i = 0; i < sizeof(g_HudSync); i++)
		ClearSyncHud(0, g_HudSync[i][_hudsync])
	
	if (g_GameMode > 1) 
	{
		
		set_lights("#OFF");
		fog(false)
		
		new Players[32] 	
		
		new playerCount, i 
		get_players(Players, playerCount, "c") 
		for (i=0; i<playerCount; i++) 
		{
			if (is_user_connected(Players[i]))
			{
				if (get_bit(g_BackToCT, Players[i])) cs_set_user_team2(Players[i], CS_TEAM_CT)	
				client_infochanged(Players[i])
				set_user_maxspeed(Players[i], 250.0)
				menu_cancel(Players[i])
				player_strip_weapons(Players[i])
			}
			
		}
		/*if (g_Faded)
	{
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, g_Simon)
		write_short(1<<10)
		write_short(1<<10)
		write_short(0x0000) // fade out
		write_byte(ALIEN_RED)
		write_byte(ALIEN_GREEN)
		write_byte(ALIEN_BLUE)
		write_byte(100)
		message_end()
	}*/
		remove_task(7447)
		remove_task(666)
		g_BackToCT = 0
}
	g_GameMode = 1


}

public SimonAllowed()
{
g_SimonAllowed = 1
}
public round_start()
{
gc_TalkMode = get_pcvar_num(gp_TalkMode)
gc_VoiceBlock = get_pcvar_num(gp_VoiceBlock)
gc_SimonSteps = get_pcvar_num(gp_SimonSteps)
gc_ButtonShoot = get_pcvar_num(gp_ButtonShoot)
gc_CrowbarMul = get_pcvar_float(gp_CrowbarMul)
get_pcvar_string(gp_TShop, Tallowed,31)
get_pcvar_string(gp_CTShop, CTallowed,31)
get_pcvar_string(gp_Bind, bindstr,32)
g_GameMode = 1
g_SimonAllowed = 0
/*g_FreedayNext = 0*/

g_nogamerounds++

new ent = -1
while((ent = find_ent_by_class(ent, "crowbar")))
{
if (is_valid_ent(ent)) remove_entity(ent)
}



if(g_RoundEnd)
	return
	
set_task(HUD_DELAY, "hud_status", TASK_STATUS, _, _, "b")
set_task(random_float(2.0,5.0), "SimonAllowed")
player_hudmessage(0, 5, 5.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_DAY", g_JailDay)

}



public cmd_voiceon(id)
{
	client_cmd(id, "+voicerecord")
	set_bit(g_SimonVoice, id)
	if(g_Simon == id || is_user_admin(id))
		set_bit(g_SimonTalking, id)
	
	return PLUGIN_HANDLED
}

public cmd_voiceoff(id)
{
	client_cmd(id, "-voicerecord")
	clear_bit(g_SimonVoice, id)
	if(g_Simon == id || is_user_admin(id))
		clear_bit(g_SimonTalking, id)
	
	return PLUGIN_HANDLED
}

public cmd_simon(id)
{
	static CsTeams:team, name[32]
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	
	team = cs_get_user_team(id)
	if(g_SimonAllowed != 0 && !g_Freeday && is_user_alive(id) && team == CS_TEAM_CT && !g_Simon)
	{
		g_Simon = id
		get_user_name(id, name, charsmax(name))
		entity_set_int(id, EV_INT_body, 1)
		g_PlayerSimon[id]--
		if(get_pcvar_num(gp_GlowModels))
			player_glow(id, g_Colors[0])
		give_item(id, "weapon_p228")
		give_item(id, "ammo_357sig")
		give_item(id, "ammo_357sig")
		give_item(id, "ammo_357sig")
		give_item(id, "ammo_357sig")
		cmd_simonmenu(id)
		hud_status(0)
	}
	return PLUGIN_HANDLED
}

public cmd_open(id)
{
	if(id == g_Simon || id == is_user_admin(id))
		jail_open()
	
	return PLUGIN_HANDLED
}



public cmd_box(id)
{
	
	if((id == g_Simon || is_user_admin(id)) && g_GameMode == 1)
	{
		new Players[32] 
		new playerCount, i, TAlive
		
		get_players(Players, playerCount, "ac") 
		for (i=0; i<playerCount; i++) 
		{
			if (is_user_connected(Players[i])) 
				
			if ( cs_get_user_team(Players[i]) == CS_TEAM_T )
			{
				TAlive++;
			}
		}
		
		if(TAlive<= get_pcvar_num(gp_BoxMax) && TAlive > 1)
		{
			for(i = 1; i <= g_MaxClients; i++)
				if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
				set_user_health(i, 100)
			
			set_cvar_num("mp_tkpunish", 0)
			set_cvar_num("mp_friendlyfire", 1)
			g_BoxStarted = 1
			emit_sound(0, CHAN_AUTO, "jbextreme/box.mp3", 1.0, ATTN_NORM, 0, PITCH_NORM)
			player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_BOX")
		}
		else
		{
			player_hudmessage(id, 1, 3.0, _, "%L", LANG_SERVER, "UJBM_GUARD_CANTBOX")
		}
	}
	return PLUGIN_HANDLED
}


public cmd_help(id)
{
	if(id > g_MaxClients)
		id -= TASK_HELP
	
	remove_task(TASK_HELP + id)
	
	
	
	show_motd(id,"jb_help.txt","Ultimate Jail Break Manager");
	
	
	
}

public cmd_minmodels(id)
{
	if(id > g_MaxClients)
		id -= TASK_HELP
	
	remove_task(TASK_HELP + id)
	
	
	
	query_client_cvar(id, "cl_minmodels", "cvar_result_func"); 
	
	
	
}








public cmd_freeday(id)
{
	
	if (g_GameMode == 1)
	{
		static menu, menuname[32], option[64]
		if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || is_user_admin(id))
		{
			formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY")
			menu = menu_create(menuname, "freeday_choice")
			
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY_PLAYER")
			menu_additem(menu, option, "1", 0)
			
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_FREEDAY_ALL")
			menu_additem(menu, option, "2", 0)
			
			menu_display(id, menu)
		}
		
	}
	return PLUGIN_HANDLED
}

public cmd_freeday_player(id)
{
	if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || is_user_admin(id))
		menu_players(id, CS_TEAM_T, id, 1, "freeday_select", "%L", LANG_SERVER, "UJBM_MENU_FREEDAY")
	
	return PLUGIN_CONTINUE
}


public cmd_punish(id)
{
	if((id  == g_Simon) || is_user_admin(id) )
		menu_players(id, CS_TEAM_CT, id, 1, "cmd_punish_ct", "%L", LANG_SERVER, "UJBM_MENU_PUNISH")
	
	return PLUGIN_CONTINUE
}



public cmd_lastrequest(id)
{
	
	static i, num[5], menu, menuname[32], option[64]
	if (!is_user_alive(g_PlayerLast)) task_last();
	if(!get_pcvar_num(gp_LastRequest) || g_Freeday || g_LastDenied || g_PlayerLast !=id || !is_user_alive(id) || g_GameMode >= 2)
		return PLUGIN_CONTINUE
	
	
	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ")
	menu = menu_create(menuname, "lastrequest_select")
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT1")
	menu_additem(menu, option, "1", 0)
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT2")
	menu_additem(menu, option, "2", 0)
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_OPT3")
	menu_additem(menu, option, "3", 0)
	
	for(i = 0; i < sizeof(_Duel); i++)
	{
		num_to_str(i + 4, num, charsmax(num))
		formatex(option, charsmax(option), "%L", LANG_SERVER, _Duel[i][_opt])
		menu_additem(menu, option, num, 0)
	}
	
	
	menu_display(id, menu)
	return PLUGIN_CONTINUE
}

public adm_freeday(id)
{
	static player, user[32]
	if(!is_user_admin(id))
		return PLUGIN_CONTINUE
	
	read_argv(1, user, charsmax(user))
	player = cmd_target(id, user, 2)
	if(is_user_connected(player) && cs_get_user_team(player) == CS_TEAM_T)
	{
		freeday_set(id, player)
	}
	return PLUGIN_HANDLED
}


public adm_open(id)
{
	if(!is_user_admin(id))
		return PLUGIN_CONTINUE
	
	jail_open()
	return PLUGIN_HANDLED
}

public adm_box(id)
{
	if(!is_user_admin(id))
		return PLUGIN_CONTINUE
	
	cmd_box(-1)
	return PLUGIN_HANDLED
}






public revolt_start()
{
	client_cmd(0,"speak ambience/siren")
	set_task(8.0, "stop_sound")
	hud_status(0)
}

public stop_sound(task)
{
	client_cmd(0, "stopsound")
}


public show_color(id)
{
	new n = 0;
	if (id == 0)
	{
		
		/*new name[32], szStatus[64]*/
		
		new Players[32] 
		new playerCount, i 
		get_players(Players, playerCount, "ac") 
		for (i=0; i<playerCount; i++) 
		{
			if (is_user_connected(Players[i])) 
				if ( cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]))
			{
				n=entity_get_int(Players[i], EV_INT_skin);
				switch (n)
				{
					case 0: 
					{
						
						player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {200, 100, 0}, "%L", LANG_SERVER,	"UJBM__COLOR_ORANGE")
					}
					
					case 1: 
					{
						
						player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {255, 255, 255}, "%L", LANG_SERVER,	"UJBM__COLOR_WHITE")
					}
					
					case 2: 
					{
						player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {150, 200, 0}, "%L", LANG_SERVER,	"UJBM__COLOR_YELLOW")
					}
					
					case 3: 
					{
						player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {0, 200, 0}, "%L", LANG_SERVER,	"UJBM__COLOR_GREEN")
					}
					
					case 4: 
					{
						
						player_hudmessage(Players[i], 10, HUD_DELAY + 1.0, {200, 0, 0}, "%L", LANG_SERVER,	"UJBM__COLOR_RED")
					}
				}
				
			}
		}
	}
	else
		
{
	n=entity_get_int(id, EV_INT_skin);
	switch (n)
	{
		case 0: 
		{
			
			player_hudmessage(id, 10, HUD_DELAY + 1.0, {200, 100, 0}, "%L", LANG_SERVER,	"UJBM__COLOR_ORANGE")
		}
		
		case 1: 
		{
			
			player_hudmessage(id, 10, HUD_DELAY + 1.0, {255, 255, 255}, "%L", LANG_SERVER,	"UJBM__COLOR_WHITE")
		}
		
		case 2: 
		{
			player_hudmessage(id, 10, HUD_DELAY + 1.0, {150, 200, 0}, "%L", LANG_SERVER,	"UJBM__COLOR_YELLOW")
		}
		
		case 3: 
		{
			player_hudmessage(id, 10, HUD_DELAY + 1.0, {0, 200, 0}, "%L", LANG_SERVER,	"UJBM__COLOR_GREEN")
		}
		
		case 4: 
		{
			
			player_hudmessage(id, 10, HUD_DELAY + 1.0, {200, 0, 0}, "%L", LANG_SERVER,	"UJBM__COLOR_RED")
		}
	}	
	
}
}


stock show_count()
{
new Players[32] 
new playerCount, i,TAlive,TAll
new szStatus[64]
get_players(Players, playerCount, "c") 
for (i=0; i<playerCount; i++) 
{
	if (is_user_connected(Players[i])) 
		
		if ( cs_get_user_team(Players[i]) == CS_TEAM_T)
		{
			TAll++;
			if (is_user_alive(Players[i])) TAlive++;
		}
	}
	
	
	
formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS", TAlive,TAll)
message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
write_byte(0)
write_string(szStatus)
message_end()
}



public hud_status(task)
{
	static i, n
	new name[32], szStatus[64], wanted[512], fdlist[512]
	
	
	
	
	if(g_RoundStarted < (get_pcvar_num(gp_RetryTime) / 2))
		g_RoundStarted++
	
	
	
	
	
	
	
	switch (g_GameMode)
		
{
	
	
	case 0:
	{
		show_count()
		
		n = 0
		formatex(wanted, charsmax(wanted), "%L", LANG_SERVER, "UJBM_PRISONER_WANTED")
		n = strlen(wanted)
		for(i = 0; i < g_MaxClients; i++)
		{
			
			if(get_bit(g_PlayerWanted, i) && is_user_alive(i) && n < charsmax(wanted))
			{
				get_user_name(i, name, charsmax(name))
				n += copy(wanted[n], charsmax(wanted) - n, "^n^t")
				n += copy(wanted[n], charsmax(wanted) - n, name)
			}
		}
		
		
		player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_FREEDAY")
		if(g_PlayerWanted)
			player_hudmessage(0, 3, HUD_DELAY + 1.0, {255, 25, 50}, "%s", wanted)
			else if(g_PlayerRevolt)
				player_hudmessage(0, 3, HUD_DELAY + 1.0, {255, 25, 50}, "%L", LANG_SERVER, "UJBM_PRISONER_REVOLT")
			
		}
		
		
		case 1:
			
	{
		show_count()
		if (get_pcvar_num (gp_ShowColor) == 1) show_color(0)
		
		if (get_pcvar_num (gp_ShowFD) == 1) 
		{
			n = 0
			formatex(fdlist, charsmax(fdlist), "%L", LANG_SERVER, "UJBM_FREEDAY_SINGLE")
			n = strlen(fdlist)
			for(i = 0; i < g_MaxClients; i++)
			{
				if(get_bit(g_PlayerFreeday, i) && is_user_alive(i) && n < charsmax(fdlist))
				{
					get_user_name(i, name, charsmax(name))
					n += copy(fdlist[n], charsmax(fdlist) - n, "^n^t")
					n += copy(fdlist[n], charsmax(fdlist) - n, name)
				}
				
			}
			if(g_PlayerFreeday)		
				player_hudmessage(0, 9, HUD_DELAY + 1.0, {0, 255, 0}, "%s", fdlist)	
				
			}
			
			
			
		if (get_pcvar_num (gp_ShowWanted) == 1) 
			{	
				n = 0
				formatex(wanted, charsmax(wanted), "%L", LANG_SERVER, "UJBM_PRISONER_WANTED")
				n = strlen(wanted)
				for(i = 0; i < g_MaxClients; i++)
				{
					if(get_bit(g_PlayerWanted, i) && is_user_alive(i) && n < charsmax(wanted))
					{
						get_user_name(i, name, charsmax(name))
						n += copy(wanted[n], charsmax(wanted) - n, "^n^t")
						n += copy(wanted[n], charsmax(wanted) - n, name)
					}
				}
				if(g_PlayerWanted)
					player_hudmessage(0, 3, HUD_DELAY + 1.0, {255, 25, 50}, "%s", wanted)
				
			}
		if(!g_Simon && g_SimonAllowed )
			{
				cmd_simon(random_num(1, g_MaxClients))
			}
			else  if (g_Simon  != 0)
		{
			
			get_user_name(g_Simon, name, charsmax(name))
			player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_SIMON_FOLLOW", name)
		}
		
		if(g_PlayerRevolt)
			player_hudmessage(0, 3, HUD_DELAY + 1.0, {255, 25, 50}, "%L", LANG_SERVER, "UJBM_PRISONER_REVOLT")
			
			
			
		}
		
		case 2:
			
	{
		player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_ZOMBIEDAY")
	}
	
	case 3:
		
	{
		player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_HNS")
	}
	
	case 4:
	{
		get_user_name(g_Simon, name, charsmax(name))
		player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_ALIENDAY", name)
		formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS_ALIENHP", get_user_health(g_Simon))
		message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
		write_byte(0)
		write_string(szStatus)
		message_end()
	}
	
	case 5:
	{
		get_user_name(g_Simon, name, charsmax(name))
		player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_ALIENDAY", name)
		formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS_ALIENHP", get_user_health(g_Simon))
		message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
		write_byte(0)
		write_string(szStatus)
		message_end()
	}
	
	case 6:
	{
		get_user_name(g_Simon, name, charsmax(name))
		player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_GORDONDAY")
		formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "UJBM_STATUS_GORDONHP", get_user_health(g_Simon))
		message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
		write_byte(0)
		write_string(szStatus)
		message_end()
	}
	
	
}








}





public prisoner_last(id)
{
static name[32], Float:roundmax


if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T && g_GameMode <= 1)
{
	
	get_user_name(id, name, charsmax(name))
	g_PlayerLast = id
	player_hudmessage(0, 6, 5.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PRISONER_LAST", name)
	remove_task(TASK_ROUND)
	if(roundmax > 0.0)
	{
		player_hudmessage(0, 8, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_STATUS_ENDTIMER", floatround(roundmax - 60.0))
		set_task(roundmax - 60.0, "check_end", TASK_ROUND)
	}
	
	static i
	new Players[32] 
	new playerCount, CTAlive
	
	
	get_players(Players, playerCount, "ac") 
	for (i=0; i<playerCount; i++) 
	{
		if (is_user_connected(Players[i])) 
			
			if ( cs_get_user_team(Players[i]) == CS_TEAM_CT )
			{
				CTAlive++;
			}
		}
		
		
	if((CTAlive> 0) && get_pcvar_num(gp_AutoLastresquest) && (g_GameMode == 1))
			cmd_lastrequest(id)
	}
	else if (g_GameMode == 2)
	{
		set_user_health(id, 1000)
		player_glow(id, g_Colors[3])
		set_user_maxspeed(id, 275.0)
	}
}

public freeday_select(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static dst[32], data[5], player, access, callback
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	player = str_to_num(data)
	freeday_set(id, player)
	return PLUGIN_HANDLED
}

public duel_knives(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		g_LastDenied = 0
		return PLUGIN_HANDLED
	}
	
	static dst[32], data[5], access, callback, option[128], player, src[32]
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, src, charsmax(src))
	player = str_to_num(data)
	formatex(option, charsmax(option), "%L^n%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SEL3", src, LANG_SERVER, "UJBM_MENU_DUEL_SEL", src, dst)
	player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
	
	g_DuelA = id
	clear_bit(g_PlayerCrowbar, id)
	player_strip_weapons(id)
	player_glow(id, g_Colors[3])
	set_user_health(id, 100)
	
	g_DuelB = player
	player_strip_weapons(player)
	player_glow(player, g_Colors[2])
	set_user_health(player, 100)
	server_cmd("jb_unblock_teams")
	return PLUGIN_HANDLED
}

public duel_guns(id, menu, item)
{
	if(item == MENU_EXIT || g_PlayerLast != id)
	{
		menu_destroy(menu)
		g_LastDenied = 0
		g_Duel = 0
		return PLUGIN_HANDLED
	}
	
	
	static gun, dst[32], data[5], access, callback, option[128], player, src[32]
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, src, charsmax(src))
	player = str_to_num(data)
	formatex(option, charsmax(option), "%L^n%L", LANG_SERVER, _Duel[g_Duel - 4][_sel], src, LANG_SERVER, "UJBM_MENU_DUEL_SEL", src, dst)
	emit_sound(0, CHAN_AUTO, "jbextreme/nm_goodbadugly.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
	
	
	
	
	switch (_Duel[g_Duel - 4][_csw])
	{
		case  CSW_M249:
		{
			g_DuelA = id
			player_strip_weapons(id)
			gun = give_item(id, _Duel[g_Duel - 4][_entname])
			cs_set_weapon_ammo(gun, 2000)
			cs_set_user_bpammo(id,CSW_M249,0)
			set_user_health(id, 2000)
			entity_set_int(id, EV_INT_body, 4)
			player_glow(id, g_Colors[3])
			
			
			g_DuelB = player
			player_strip_weapons(player)
			gun = give_item(player, _Duel[g_Duel - 4][_entname])
			cs_set_weapon_ammo(gun, 2000)
			set_user_health(player, 2000)
			cs_set_user_bpammo(player,CSW_M249,0)
			entity_set_int(player, EV_INT_body, 4)
			player_glow(player, g_Colors[2])
		}
		
		case  CSW_FLASHBANG:
		{
			g_DuelA = id
			player_strip_weapons(id)
			gun = give_item(id, _Duel[g_Duel - 4][_entname])
			cs_set_weapon_ammo(gun, 1)
			set_user_health(id, 2000)
			entity_set_int(id, EV_INT_body, 4)
			player_glow(id, g_Colors[3])
			
			current_weapon_fl(id)
			
			g_DuelB = player
			player_strip_weapons(player)
			gun = give_item(player, _Duel[g_Duel - 4][_entname])
			cs_set_weapon_ammo(gun, 1)
			set_user_health(player, 2000)
			entity_set_int(player, EV_INT_body, 4)
			player_glow(player, g_Colors[2])
			current_weapon_fl(player)
		}
		
		
		
		default:
	{
		player_strip_weapons(id)
		g_DuelA = id
		gun = give_item(id, _Duel[g_Duel - 4][_entname])
		cs_set_weapon_ammo(gun, 1)
		set_user_health(id, 100)
		player_glow(id, g_Colors[3])
		
		g_DuelB = player
		player_strip_weapons(player)
		gun = give_item(player, _Duel[g_Duel - 4][_entname])
		cs_set_weapon_ammo(gun, 1)
		set_user_health(player, 100)
		player_glow(player, g_Colors[2])
	}
}
	server_cmd("jb_block_weapons")
	return PLUGIN_HANDLED
}

public freeday_choice(id, menu, item)
{
if(item == MENU_EXIT)
{
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

static dst[32], data[5], access, callback

menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
menu_destroy(menu)
get_user_name(id, dst, charsmax(dst))
switch(data[0])
{
	case('1'):
	{
		cmd_freeday_player(id)
	}
	case('2'):
	{
		if((id == g_Simon) || is_user_admin(id))
		{
			g_Simon = 0
			
			get_user_name(id, dst, charsmax(dst))
			client_print(0, print_console, "%s gives freeday for everyone", dst)
			server_print("JBE Client %i gives freeday for everyone", id)
			
			g_GameMode = 0
			
			g_Simon = 0	
			emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			hud_status(0)
			g_PlayerFreeday = 0
			
			jail_open()
			
			
			new Players[32] 
			new playerCount, i 
			get_players(Players, playerCount, "ac")
			for (i=0; i<playerCount; i++) 
			{
				entity_set_int(Players[i], EV_INT_skin, 3)
			}
			
			
			
			
			
			new Float:FDLEN = get_pcvar_float(gp_FDLength) 
			if (FDLEN < 20.0) FDLEN = 99999.0
			set_task(FDLEN, "task_freeday_end",TASK_FREEEND)
		}
	}
}
return PLUGIN_HANDLED
}

public lastrequest_select(id, menu, item)
{
if(item == MENU_EXIT || g_PlayerLast != id)
{
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

static i, dst[32], data[5], access, callback, option[64]

menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
get_user_name(id, dst, charsmax(dst))
switch(data[0])
{
	case('1'):
	{
		cs_set_user_money(id,16000,1)
		user_silentkill(id)
	}
	case('2'):
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_LASTREQ_SEL2", dst)
		player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
		g_Duel = 2
		player_strip_weapons_all()
		i = random_num(0, sizeof(_WeaponsFree) - 1)
		give_item(id, _WeaponsFree[i])
		server_cmd("jb_block_weapons")
		cs_set_user_bpammo(id, _WeaponsFreeCSW[i], _WeaponsFreeAmmo[i])
	}
	case('3'):
	{
		g_Duel = 3
		menu_players(id, CS_TEAM_CT, 0, 1, "duel_knives", "%L", LANG_SERVER, "UJBM_MENU_DUEL")
	}
	default:
{
	g_Duel = str_to_num(data)
	menu_players(id, CS_TEAM_CT, 0, 1, "duel_guns", "%L", LANG_SERVER, "UJBM_MENU_DUEL")
}
}
g_LastDenied = 1
menu_destroy(menu)
return PLUGIN_HANDLED
}

public setup_buttons()
{
new ent[3]
new Float:origin[3]
new info[32]
new pos

while((pos <= sizeof(g_Buttons)) && (ent[0] = engfunc(EngFunc_FindEntityByString, ent[0], "classname", "info_player_deathmatch")))
{
pev(ent[0], pev_origin, origin)
while((ent[1] = engfunc(EngFunc_FindEntityInSphere, ent[1], origin, CELL_RADIUS)))
{
	if(!is_valid_ent(ent[1]))
		continue
		
	entity_get_string(ent[1], EV_SZ_classname, info, charsmax(info))
	if(!equal(info, "func_door"))
			continue
			
	entity_get_string(ent[1], EV_SZ_targetname, info, charsmax(info))
	if(!info[0])
			continue
			
	if(TrieKeyExists(g_CellManagers, info))
			{
				TrieGetCell(g_CellManagers, info, ent[2])
			}
		else
			{
				ent[2] = engfunc(EngFunc_FindEntityByString, 0, "target", info)
			}
			
	if(is_valid_ent(ent[2]) && (in_array(ent[2], g_Buttons, sizeof(g_Buttons)) < 0))
			{
				g_Buttons[pos] = ent[2]
				pos++
				break
			}
		}
	}
TrieDestroy(g_CellManagers)
}

stock in_array(needle, data[], size)
{
	for(new i = 0; i < size; i++)
	{
		if(data[i] == needle)
			return i
	}
	return -1
}

stock freeday_set(id, player)
{
	static src[32], dst[32]
	get_user_name(player, dst, charsmax(dst))
	
	if(is_user_alive(player) && !get_bit(g_PlayerWanted, player))
	{
		set_bit(g_PlayerFreeday, player)
		entity_set_int(player, EV_INT_skin, 3)
		if(get_pcvar_num(gp_GlowModels))
			player_glow(player, g_Colors[1])
		
		if(0 < id <= g_MaxClients)
		{
			get_user_name(id, src, charsmax(src))
			player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_FREEDAYGIVE", src, dst)
		}
		else if(g_GameMode == 1)
		{
			player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_PRISONER_HASFREEDAY", dst)
		}
	}
}

stock first_join(id)
{
	if (get_bit(g_PlayerJoin, id)) return PLUGIN_CONTINUE
	
	switch (get_pcvar_num(gp_Help))
	{
		case 1:{
			set_task(5.0, "cmd_help", TASK_HELP + id)
		}
		case 2:{
			if (!is_user_admin(id))	
				set_task(5.0, "cmd_help", TASK_HELP + id)
		}
	}
	
	
	set_task(20.0, "cmd_minmodels", TASK_HELP + id)
	set_bit(g_PlayerJoin, id)
	clear_bit(g_PlayerHelp, id)
	
	return PLUGIN_CONTINUE
}


stock player_hudmessage(id, hudid, Float:time = 0.0, color[3] = {0, 255, 0}, msg[], any:...)
{
static text[512], Float:x, Float:y
x = g_HudSync[hudid][_x]
y = g_HudSync[hudid][_y]

if(time > 0)
	set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, time, 0.00, 0.00)
	else
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, g_HudSync[hudid][_time], 0.00, 0.00)
	
vformat(text, charsmax(text), msg, 6)
ShowSyncHudMsg(id, g_HudSync[hudid][_hudsync], text)
}

stock menu_players(id, CsTeams:team, skip, alive, callback[], title[], any:...)
{
	static i, name[32], num[5], menu, menuname[32]
	vformat(menuname, charsmax(menuname), title, 7)
	menu = menu_create(menuname, callback)
	for(i = 1; i <= g_MaxClients; i++)
	{
		if(!is_user_connected(i) || (alive && !is_user_alive(i)) || (skip == i))
			continue
		
		if(!(team == CS_TEAM_T || team == CS_TEAM_CT) || ((team == CS_TEAM_T || team == CS_TEAM_CT) && (cs_get_user_team(i) == team)))
		{
			get_user_name(i, name, charsmax(name))
			num_to_str(i, num, charsmax(num))
			menu_additem(menu, name, num, 0)
		}
	}
	menu_display(id, menu)
}

stock player_glow(id, color[3], amount=40)
{
	set_user_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, amount)
}

stock player_strip_weapons(id)
{
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	set_pdata_int(id, m_iPrimaryWeapon, 0)
}

stock player_strip_weapons_all()
{
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(is_user_alive(i))
		{
			player_strip_weapons(i)
		}
	}
}



public jail_open()
{
	static i
	for(i = 0; i < sizeof(g_Buttons); i++)
	{
		if(g_Buttons[i])
		{
			ExecuteHamB(Ham_Use, g_Buttons[i], 0, 0, 1, 1.0)
			entity_set_float(g_Buttons[i], EV_FL_frame, 0.0)
		}
	}
}



public fog(bool:on)
	
{
if (on)
{
	message_begin(MSG_ALL,get_user_msgid("Fog"),{0,0,0},0)
	write_byte(random_num(180,244))  // R
	write_byte(1)  // G
	write_byte(1)  // B
	write_byte(10) // SD
	write_byte(41)  // ED
	write_byte(95)   // D1
	write_byte(59)  // D2
	message_end()	
	
}
else
{
	message_begin(MSG_ALL,get_user_msgid("Fog"),{0,0,0},0)
	write_byte(0)  // R
	write_byte(0)  // G
	write_byte(0)  // B
	write_byte(0) // SD
	write_byte(0)  // ED
	write_byte(0)   // D1
	write_byte(0)  // D2
	message_end()
}


}


public client_infochanged(id) 
{ 
if (is_user_connected(id))
{
	if (g_GameMode != 6 && id != g_Simon)  set_user_info(id, "model", "ujbm_v1")
}

      
} 

public cvar_result_func(id, const cvar[], const value[]) 
{ 
  
  if (value[0] != '0') Showcl_min(id)
  
} 



public cmd_zmday(id)
{
if (is_user_admin(id)) cmd_game_zombie()	
}


public cmd_game_zombie()
{
jail_open()
g_GameMode = 2
g_BoxStarted = 0
server_cmd("jb_block_weapons")
g_Simon = 0
g_nogamerounds = 0

new Players[32] 
new playerCount, i 
get_players(Players, playerCount, "ac") 
for (i=0; i<playerCount; i++) 
{
	if (is_user_connected(Players[i]))
		if ( cs_get_user_team(Players[i]) == CS_TEAM_T)
		{
			player_strip_weapons(Players[i])
			set_user_maxspeed(Players[i], 200.0)
			set_user_health(Players[i], 800)
			give_item(Players[i], "item_assaultsuit")
			
			cs_set_user_nvg (Players[i],true);
			//engclient_cmd(Players[i], "nightvision") 
			
			entity_set_int(Players[i], EV_INT_body, 4)
			
			clear_bit(g_PlayerCrowbar, Players[i])
			message_begin( MSG_ONE, gmsgSetFOV, _, Players[i] )
			write_byte( 170  )
			message_end()
		} else 
		if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
		{
			strip_user_weapons(Players[i])
			give_item(Players[i], "weapon_m3")
			give_item(Players[i], "weapon_hegrenade")
			give_item(Players[i], "weapon_flashbang")
			give_item(Players[i], "ammo_buckshot")
			give_item(Players[i], "ammo_buckshot")
			give_item(Players[i], "ammo_buckshot")
			give_item(Players[i], "ammo_buckshot")
			give_item(Players[i], "ammo_buckshot")
			give_item(Players[i], "ammo_buckshot")
			give_item(Players[i], "ammo_buckshot")
			give_item(Players[i], "ammo_buckshot")
			set_user_health(Players[i], 100)
			set_user_maxspeed(Players[i], 250.0)
			set_bit(g_Fonarik, Players[i])
			client_cmd(Players[i], "impulse 100")
			player_glow(Players[i], g_Colors[2])
		}
	}
	
	
	
	
	
	
	
emit_sound(0, CHAN_AUTO, "ambience/the_horror2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
new effect = get_pcvar_num (gp_Effects)
if (effect > 0)
{
set_lights("b")
if (effect > 1) fog(true)
}
	
player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_ZM")
	
	
	
return PLUGIN_CONTINUE
}

public cmd_hns_start()
{
	server_cmd("jb_unblock_weapons")
	new Players[32] 
	new playerCount, i 
	get_players(Players, playerCount, "ac") 
	for (i=0; i<playerCount; i++) 
	{
		if (cs_get_user_team(Players[i]) == CS_TEAM_T)
		{
			give_item(Players[i], "weapon_knife")
			current_weapon(Players[i])
			give_item(Players[i], "weapon_flashbang")
			give_item(Players[i], "weapon_smokegrenade")
			set_user_maxspeed(Players[i], 300.0)
			set_user_health(Players[i], 100)
		}
		else
		{
			give_item(Players[i], "weapon_knife")
			current_weapon(Players[i])
			give_item(Players[i], "weapon_smokegrenade")
			set_bit(g_Fonarik, Players[i])
			client_cmd(Players[i], "impulse 100")
			
			
			new j = random_num(0, sizeof(_WeaponsFree) - 1)
			
			give_item(Players[i], _WeaponsFree[j])
			cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
			/// give two random guns
			
			new n = random_num(0, sizeof(_WeaponsFree) - 1)
			while (n == j) { 
				n = random_num(0, sizeof(_WeaponsFree) - 1) 
			}
			
			give_item(Players[i], _WeaponsFree[n])
			cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo[n])
		}
	}
	emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	new sz_msg[256];
	formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_HNS_START")
	client_print(0, print_center , sz_msg)
	
	return PLUGIN_CONTINUE
}



public  cmd_game_hns()
{
	
	g_nogamerounds = 0
	g_BoxStarted = 0
	jail_open()
	g_GameMode = 3
	g_SimonAllowed = 0
	g_Simon = 0
	
	
	emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_MENU_GAME_TEXT_HNS")
	
	
	set_lights("b");
	server_cmd("jb_block_weapons")
	
	
	new Players[32] 
	new playerCount, i 
	get_players(Players, playerCount, "ac")
	for (i=0; i<playerCount; i++) 
	{
		strip_user_weapons(Players[i])
	}
	set_task(30.0,"cmd_hns_start",TASK_GIVEITEMS)
	
	return PLUGIN_CONTINUE
}


/* public cmd_shop(id)
	
{


static roundloop
roundloop = floatround(get_pcvar_float(gp_RetryTime) / 2)

if(!is_user_alive(id) ||  g_GameMode >= 2 || (g_RoundStarted >= roundloop)) return PLUGIN_CONTINUE


static menu, menuname[32], option[64]
if(cs_get_user_team(id) == CS_TEAM_T)
{
	
	if (strlen(Tallowed) <= 0 ) return PLUGIN_CONTINUE
	
	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SHOP")
	menu = menu_create(menuname, "shop_choice_T")
	
	if (containi(Tallowed,"a") >= 0)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_CROWBAR",CROWBARCOST)
		menu_additem(menu, option, "1", 0)
	}
	
	if (containi(Tallowed,"b") >= 0)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_GRENAGES", GRENCOST)
		menu_additem(menu, option, "2", 0)
	}
	
	if (containi(Tallowed,"c") >= 0)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_CHAIN", CHAINCOST)
		menu_additem(menu, option, "3", 0)
	}
	
	if (containi(Tallowed,"d") >= 0)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_HE", HECOST)
		menu_additem(menu, option, "4", 0)
	}
	
	if (containi(Tallowed,"e") >= 0)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_SHIELD",SHIELDCOST)
		menu_additem(menu, option, "5", 0)
	}
	
	if (containi(Tallowed,"f") >= 0)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FD", FDCOST)
		menu_additem(menu, option, "6", 0)
	}
	
	if (containi(Tallowed,"g") >= 0)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FLASHLIGHT", FLASHLIGHTCOST)
		menu_additem(menu, option, "7", 0)
	}
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_NOSHOW")
	menu_additem(menu, option, "8", 0)
	
	
	menu_display(id, menu)
}
else 
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		
		if (strlen(CTallowed) <= 0 ) return PLUGIN_CONTINUE
		
		formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SHOP")
		menu = menu_create(menuname, "shop_choice_CT")
		
		if (containi(CTallowed,"a") >= 0)
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_DEAGLE", CTDEAGLECOST)
			menu_additem(menu, option, "1", 0)
		}
		
		if (containi(CTallowed,"b") >= 0)
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FLASHBANG_CT", CTFLASHCOST)
			menu_additem(menu, option, "2", 0)
		}
		
		if (containi(CTallowed,"c") >= 0)
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_SMOKE_CT",CTSMOKECOST)
			menu_additem(menu, option, "3", 0)
		}
		
		if (containi(CTallowed,"d") >= 0)
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_HP",HPCOST)
			menu_additem(menu, option, "4", 0)
		}
		
		if (containi(CTallowed,"e") >= 0)
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_NVG",NVGCOST)
			menu_additem(menu, option, "5", 0)
		}
		
		if (containi(CTallowed,"f") >= 0)
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_FLASHLIGHT",FLASHLIGHTCOST)
			menu_additem(menu, option, "6", 0)
		}
		
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SHOP_NOSHOW")
		menu_additem(menu, option, "7", 0)
		
		
		menu_display(id, menu)
		
	}
return PLUGIN_HANDLED
}


public shop_choice_T(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) ||  g_GameMode >= 2 )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static dst[32], data[5], access, callback
	new money = cs_get_user_money (id);
	new sz_msg[256];
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	menu_destroy(menu)
	get_user_name(id, dst, charsmax(dst))
	
	switch(data[0])
	{
		case('2'):
		{
			if (money >= GRENCOST) 
			{
				cs_set_user_money (id, money - GRENCOST, 0)
				give_item(id, "weapon_hegrenade")
				give_item(id, "weapon_flashbang")
				give_item(id, "weapon_flashbang")
				give_item(id, "weapon_smokegrenade")
			}
			
			else
				
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}
	
	
	case('4'):
	{
		if (money >= HECOST) 
		{
			cs_set_user_money (id, money - HECOST, 0)
			give_item(id, "weapon_hegrenade")
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}
	
	case('3'):
	{
		if (money >= CHAINCOST) 
		{
			cs_set_user_money (id, money - CHAINCOST, 0)
			give_item(id, "weapon_smokegrenade")
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}
	
	case('5'):
	{
		if (money >= SHIELDCOST) 
		{
			cs_set_user_money (id, money - SHIELDCOST, 0)
			give_item(id, "weapon_shield")
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}	
	
	
	case('1'):
	{
		if (money >= CROWBARCOST) 
		{
			cs_set_user_money (id, money - CROWBARCOST, 0)
			set_bit(g_PlayerCrowbar, id)
			current_weapon(id)
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}	
	
	case('6'):
	{
		if (money >= FDCOST) 
		{
			cs_set_user_money (id, money - FDCOST, 0)
			freeday_set(0, id)
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}	
	
	case('7'):
	{
		
		if (money >= FLASHLIGHTCOST) 
		{
			cs_set_user_money (id, money - FLASHLIGHTCOST, 0)
			set_bit(g_Fonarik, id)
			client_cmd(id, "impulse 100")
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
		
		
		
	}	
	
	case('8'):
	{
		set_bit(g_NoShowShop, id)
		formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_SHOWHOW")
		client_print(id, print_center , sz_msg)
		
	}	
	
	
	
	
	
	
	
}
	return PLUGIN_HANDLED
}


public shop_choice_CT(id, menu, item)
{
if(item == MENU_EXIT)
{
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

static dst[32], data[5], access, callback
new money = cs_get_user_money (id);
new sz_msg[256];

menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
menu_destroy(menu)
get_user_name(id, dst, charsmax(dst))

switch(data[0])
{
	case('1'):
	{
		if (money >= CTDEAGLECOST) 
		{
			cs_set_user_money (id, money - CTDEAGLECOST, 0)
			give_item(id, "weapon_deagle")
			give_item(id, "ammo_50ae")
			give_item(id, "ammo_50ae")
			give_item(id, "ammo_50ae")
			give_item(id, "ammo_50ae")
			give_item(id, "ammo_50ae")
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}
	
	case('2'):
	{
		if (money >= CTFLASHCOST) 
		{
			cs_set_user_money (id, money - CTFLASHCOST, 0)
			give_item(id, "weapon_flashbang")
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}
	
	case('3'):
	{
		if (money >= CTSMOKECOST) 
		{
			cs_set_user_money (id, money - CTSMOKECOST, 0)
			give_item(id, "weapon_smokegrenade")
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}
	
	case('4'):
	{
		if (money >= HPCOST) 
		{
			cs_set_user_money (id, money - HPCOST, 0)
			set_user_health(id, 150)
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}
	
	case('5'):
	{
		if (money >= NVGCOST) 
		{
			cs_set_user_money (id, money - NVGCOST, 0)
			cs_set_user_nvg (id,true);
			engclient_cmd(id, "nightvision") 
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
	}
	
	case('6'):
	{
		if (money >= FLASHLIGHTCOST) 
		{
			cs_set_user_money (id, money - FLASHLIGHTCOST, 0)
			set_bit(g_Fonarik, id)
			client_cmd(id, "impulse 100")
		}
		
		else
			
		{
			formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_NOT_ENOUGH")
			client_print(id, print_center , sz_msg)
		}
		
		
	}		
	
	case('7'):
	{
		set_bit(g_NoShowShop, id)
		formatex(sz_msg, charsmax(sz_msg), "^x03%L", LANG_SERVER, "UJBM_MENU_SHOP_SHOWHOW")
		client_print(id, print_center , sz_msg)
		
	}
	
	
}
if (!get_bit(g_NoShowShop, id)) cmd_shop(id)
return PLUGIN_HANDLED
}
 */


public cmd_shop(id)
{
client_cmd(id, "say /shop")
}


/* public cmd_football(id)
{
if (g_Simon == id || is_user_admin(id)) 
{
	player_hudmessage(0, 1, 8.0, _, "%L", LANG_SERVER, "UJBM_FOOTBALL")
	new n = 0;
	new name[32], szStatus[64]
	
	new bool:orange = true
	new Players[32] 
	
	new playerCount, i 
	get_players(Players, playerCount, "ac") 
	for (i=0; i<playerCount; i++) 
	{
		
		if ( cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]) && !get_bit(g_PlayerFreeday, id))
		{
			if (orange)
			{		
				entity_set_int(Players[i], EV_INT_skin, 0)
				orange=false;
			}
			else 
			{
				entity_set_int(Players[i], EV_INT_skin, 1)
				orange=true;
			}
			
		}
	}
	new origin[3]
	get_user_origin(id,origin)  // Gets the current location the player is at 
	
	
	set_task( 5.0 , "teleport" , 0 , origin , 4 );
	
	
	return PLUGIN_HANDLED
}
}

*/



public enable_player_voice(id, player)
{
static src[32], dst[32]
get_user_name(player, dst, charsmax(dst))


if (!get_bit(g_PlayerVoice, player)) 
	
{
	set_bit(g_PlayerVoice, player)
	if(0 < id <= g_MaxClients)
	{
		get_user_name(id, src, charsmax(src))
		player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_VOICEENABLED", src, dst)
	}
}

else
	
{
	clear_bit(g_PlayerVoice, player)
	if(0 < id <= g_MaxClients)
	{
		get_user_name(id, src, charsmax(src))
		player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_GUARD_VOICEDISABLED", src, dst)
	}		
	
}



}



public voice_enable_select(id, menu, item)
{

if(item == MENU_EXIT)
{
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

static dst[32], data[5], player, access, callback

menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
player = str_to_num(data)
enable_player_voice(id, player)	
cmd_simonmenu(id)
return PLUGIN_HANDLED
}
public cmd_simon_micr(id)
{
if (g_Simon == id || is_user_admin(id)) 
{
	menu_players(id, CS_TEAM_T, 0, 1, "voice_enable_select", "%L", LANG_SERVER, "UJBM_MENU_VOICE")
	
}
}


public  na2team(id) {

if (g_Simon == id || is_user_admin(id))
{
	
	new s = get_pcvar_num (gp_ShowColor)
	new playerCount, i 
	new Players[32] 
	new bool:orange = true
	get_players(Players, playerCount, "ac") 
	for (i=0; i<playerCount; i++) 
	{
		
		if ( cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]) && !get_bit(g_PlayerFreeday, Players[i]) && !get_bit(g_PlayerWanted, Players[i]))
		{
			if (orange)
			{		
				entity_set_int(Players[i], EV_INT_skin, 0)
				orange=false;
				if (s == 1) show_color(Players[i])
			}
			else 
			{
				entity_set_int(Players[i], EV_INT_skin, 1)
				orange=true;
				if (s == 1) show_color(Players[i])
			}
			
		}
	}
	
	
}
return PLUGIN_HANDLED
}


bool:GameAllowed()

{
if (g_GameMode > 1 || g_nogamerounds < get_pcvar_num(gp_NoGame))
return false	

return true;

}






public  cmd_simonmenu(id)

{


if (g_Simon == id || is_user_admin(id))
{
	static menu, menuname[32], option[64]
	
	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU")
	menu = menu_create(menuname, "simon_choice")
	
	
	formatex(option, charsmax(option), "\r%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_OPEN")
	menu_additem(menu, option, "1", 0)
	
	
	formatex(option, charsmax(option), "\g%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_FD")
	menu_additem(menu, option, "2", 0)
	
	if (g_GameMode == 1)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_CLR")
		menu_additem(menu, option, "3", 0)
	}
	
	else
	{
		formatex(option, charsmax(option), "%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_CLR")
		menu_additem(menu, option, "3", 0)	
	}
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_VOICE")
	menu_additem(menu, option, "4", 0)
	
	formatex(option, charsmax(option), "\y%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_GONG")
	menu_additem(menu, option, "5", 0)
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_PUNISH")
	menu_additem(menu, option, "6", 0)
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_SIMON_GAMES")
	menu_additem(menu, option, "7", 0)
	
	formatex(option, charsmax(option), "%L",LANG_SERVER, "UJBM_MENU_BIND",bindstr)
	menu_additem(menu, option, "8", 0)
	
	menu_display(id, menu)
	
	
}
return PLUGIN_HANDLED
}


public  simon_gameschoice(id, menu, item)
{
if(item == MENU_EXIT || g_GameMode > 1)
{
	menu_destroy(menu)
	cmd_simonmenu(id)
	return PLUGIN_HANDLED
}

static dst[32], data[5], access, callback


menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
menu_destroy(menu)
get_user_name(id, dst, charsmax(dst))

switch(data[0])
{
	
	case('1'):
	{
		
		if (GameAllowed() || is_user_admin(id)) cmd_game_alien2()
	}
	
	case'2':
	{
		if (GameAllowed() || is_user_admin(id))cmd_game_zombie()
	}
	
	case('3'): 
	{
		if (GameAllowed() || is_user_admin(id)) cmd_game_hns()
	}
	
	case('4'):
	{
		if (GameAllowed() || is_user_admin(id)) cmd_game_alien()
	}
	
	case('7'):
	{
		if (GameAllowed() || is_user_admin(id)) cmd_game_gordon()
	}
	
	case('5'):
	{
		if (id == g_Simon || is_user_admin(id)) cmd_box(id)
	}
	
	case('6'):
	{
		if (id == g_Simon || is_user_admin(id)) cmd_footballmenu(id)
	}
	
	
}		
return PLUGIN_HANDLED
}




public  football_choice(id, menu, item)
{
if(item == MENU_EXIT || (g_Simon != id && !is_user_admin(id)))
{
	menu_destroy(menu)
	cmd_simonmenu(id)
	return PLUGIN_HANDLED
}

static dst[32], data[5], access, callback
menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
menu_destroy(menu)

switch(data[0])
{
	
	case('1'):
	{
		
		if (g_Simon == id || is_user_admin(id)) server_cmd("jb_football")
	}
	case('2'):
	{
		
		if (g_Simon == id || is_user_admin(id)) server_cmd("jb_spawnball")
	}
	
}
cmd_footballmenu(id)
return PLUGIN_HANDLED;
}



public cmd_footballmenu(id)

{
if ((g_Simon == id || is_user_admin(id)) && g_GameMode <= 1)
{
	static menu, menuname[32], option[64]
	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_FOOTBALL")
	menu = menu_create(menuname, "football_choice")
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_FOOTBALL_START")
	menu_additem(menu, option, "1", 0)
	
	formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_FOOTBALL_BALLSPAWN")
	menu_additem(menu, option, "2", 0)
	
	menu_display(id, menu)
}



return PLUGIN_HANDLED

}

public  cmd_simongamesmenu(id)

{
if ((g_Simon == id || is_user_admin(id)) && g_GameMode <= 1)
{
	static menu, menuname[32], option[64]
	
	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU")
	menu = menu_create(menuname, "simon_gameschoice")
	
	
	new allowed[31];
	get_pcvar_string(gp_Games, allowed,31)
	if (strlen(allowed) <= 0 ) return PLUGIN_CONTINUE
	
	//gp_Games
	
	
	if (GameAllowed() || is_user_admin(id))
	{
		if (containi(allowed,"a") >= 0)
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_ALIEN2")
			menu_additem(menu, option, "1", 0)
		}
		
		if (containi(allowed,"b") >= 0)
		{	
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_ZM")
			menu_additem(menu, option, "2", 0)
		}
		if (containi(allowed,"c") >= 0)
		{	
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_HNS")
			menu_additem(menu, option, "3", 0)
		}
		if (containi(allowed,"d") >= 0)
		{	
			formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_ALIEN")
			menu_additem(menu, option, "4", 0)
		}
	}
	else
	{
		if (containi(allowed,"a") >= 0)
		{
			formatex(option, charsmax(option), "\d%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_ALIEN2")
			menu_additem(menu, option, "1", 0)
		}
		if (containi(allowed,"b") >= 0)
		{	
			formatex(option, charsmax(option), "\d%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_ZM")
			menu_additem(menu, option, "2", 0)
		}
		if (containi(allowed,"c") >= 0)
		{	
			formatex(option, charsmax(option), "\d%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_HNS")
			menu_additem(menu, option, "3", 0)
		}
		if (containi(allowed,"d") >= 0)
		{	
			formatex(option, charsmax(option), "\d%L\w", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_ALIEN")
			menu_additem(menu, option, "4", 0)
		}
		
		
	}
	
	if (containi(allowed,"e") >= 0)
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_GUARD_BOX")
		menu_additem(menu, option, "5", 0)
	}
	if (containi(allowed,"f") >= 0 && is_plugin_loaded("[UJBM] Football"))
	{
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_FOOTBALL")
		menu_additem(menu, option, "6", 0)
	}
	
	if (containi(allowed,"g") >= 0)
	{	
		formatex(option, charsmax(option), "%L", LANG_SERVER, "UJBM_MENU_SIMONMENU_SIMON_GORDON")
		menu_additem(menu, option, "7", 0)
	}
	
	
	menu_display(id, menu)
	
	
}
return PLUGIN_HANDLED
}


stock cs_set_user_team2(index, {CsTeams,_}:team, update = 1)
{
if (index == g_Simon)
{
g_Simon = 0
hud_status(0)
}
set_pdata_int(index, OFFSET_TEAM, _:team)
set_pev(index, pev_team, _:team)

if(update)
{
static _msg_teaminfo; if(!_msg_teaminfo) _msg_teaminfo = get_user_msgid("TeamInfo")
static teaminfo[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

message_begin(MSG_ALL, _msg_teaminfo)
write_byte(index)
write_string(teaminfo[_:team])
message_end()
}
return 1
}









public  simon_choice(id, menu, item)
{
if(item == MENU_EXIT || !(id == g_Simon || is_user_admin(id)) )
{
menu_destroy(menu)
return PLUGIN_HANDLED
}

static dst[32], data[5], access, callback

menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
menu_destroy(menu)
get_user_name(id, dst, charsmax(dst))

switch(data[0])
{
case('1'): 
{
	jail_open()
	cmd_simonmenu(id)
}
case('2'): cmd_freeday(id)
	case('3'): na2team(id)
		case('4'): cmd_simon_micr(id)
			case('5'): 
		{
			emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			cmd_simonmenu(id)
		}
		//case('5'):
		
		case('6'): cmd_punish(id)
			case('7'): cmd_simongamesmenu(id)
			case('8'): {
			client_cmd(id,"bind ^"%s^" ^"say /menu^"", bindstr)
		}
		
	}		
return PLUGIN_HANDLED
}



public  cmd_game_alien()
{
	if (g_Simon == 0) return PLUGIN_HANDLED
	
	g_BoxStarted = 0
	g_nogamerounds = 0
	jail_open()
	g_GameMode = 4
	server_cmd("jb_block_weapons")
	hud_status(0)
	new j = 0
	new Players[32] 
	new playerCount, i 
	get_players(Players, playerCount, "ac") 
	for (i=0; i<playerCount; i++) 
	{
		if ( g_Simon != Players[i])
		{
			if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
			{
				set_bit(g_BackToCT, Players[i])
				cs_set_user_team2(Players[i], CS_TEAM_T)
			}			
			strip_user_weapons(Players[i])
			
			j = random_num(0, sizeof(_WeaponsFree) - 1)
			
			give_item(Players[i], "weapon_knife")
			give_item(Players[i], _WeaponsFree[j])
			cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
		}
		else
		{ 
			set_user_maxspeed(Players[i], 400.0)
			strip_user_weapons(Players[i])
			entity_set_int(Players[i], EV_INT_body, 5)
			set_user_health(Players[i], 130*playerCount)
			give_item(Players[i], "item_assaultsuit")
			give_item(Players[i], "item_longjump")
			give_item(Players[i], "weapon_knife")
			set_bit(g_PlayerCrowbar, Players[i])
			current_weapon(Players[i])
			
		}
		
		
	}
	
	new effect = get_pcvar_num (gp_Effects)
	if (effect > 0)
	{
		set_lights("b")
		if (effect > 1) fog(true)
	}
	emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	return PLUGIN_HANDLED
}




public radar_alien()
{
	new origin[3]
	get_user_origin(g_Simon,origin)
	
	message_begin(MSG_ALL, gmsgBombDrop, {0,0,0}, 0)
	write_coord(origin[0])	//X Coordinate
	write_coord(origin[1])	//Y Coordinate
	write_coord(origin[2])	//Z Coordinate
	write_byte(0)			//?? This byte seems to always be 0...so, w/e
	message_end()	
}


public give_items_alien()
{
	
	give_item(g_Simon, "item_assaultsuit")
	give_item(g_Simon, "item_longjump")
	give_item(g_Simon, "weapon_knife")
	set_bit(g_PlayerCrowbar, g_Simon)
	current_weapon(g_Simon)
	
}





public  cmd_game_alien2()
{
	if (g_Simon == 0) return PLUGIN_HANDLED
	g_nogamerounds = 0
	g_BoxStarted = 0
	jail_open()
	g_GameMode = 5
	server_cmd("jb_block_weapons")
	server_cmd("jb_block_teams")
	hud_status(0)
	
	new Players[32] 
	new playerCount, i 
	get_players(Players, playerCount, "ac")
	for (i=0; i<playerCount; i++) 
	{
		
		strip_user_weapons(Players[i])
		if ( g_Simon != Players[i])
		{
			if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
			{
				set_bit(g_BackToCT, Players[i])
				cs_set_user_team2(Players[i], CS_TEAM_T)
			}
			give_item(Players[i], "weapon_knife")
			new j = random_num(0, sizeof(_WeaponsFree) - 1)
			
			give_item(Players[i], _WeaponsFree[j])
			cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
			/// give two random guns
			
			new n = random_num(0, sizeof(_WeaponsFree) - 1)
			while (n == j) { 
				n = random_num(0, sizeof(_WeaponsFree) - 1) 
			}
			
			give_item(Players[i], _WeaponsFree[n])
			cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo[n])
		}
		
	}
	set_user_rendering(g_Simon, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0 )
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, g_Simon)
	write_short(~0)
	write_short(~0)
	write_short(0x0004) // stay faded
	write_byte(ALIEN_RED)
	write_byte(ALIEN_GREEN)
	write_byte(ALIEN_BLUE)
	write_byte(100)
	message_end()
	set_user_maxspeed(g_Simon, 320.0)
	entity_set_int(g_Simon, EV_INT_body, 5)
	new hp = get_pcvar_num(gp_GameHP)
	if (hp < 20) hp = 200
	
	set_user_health(g_Simon, hp*playerCount)
	set_task(20.0, "give_items_alien", TASK_GIVEITEMS)
	
	set_lights("z")
	emit_sound(0, CHAN_VOICE, "alien_alarm.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
	set_task(2.5, "radar_alien", 666, _, _, "b")
	set_task(5.0, "stop_sound")
	
	return PLUGIN_HANDLED
}



public  cmd_game_gordon()
{
	if (g_Simon == 0) return PLUGIN_HANDLED
	g_nogamerounds = 0
	g_BoxStarted = 0
	jail_open()
	g_GameMode = 6
	server_cmd("jb_block_weapons")
	server_cmd("jb_block_teams")
	hud_status(0)
	
	new Players[32] 
	new playerCount, i 
	get_players(Players, playerCount, "ac")
	for (i=0; i<playerCount; i++) 
	{
		strip_user_weapons(Players[i])
		if ( g_Simon != Players[i])
		{
			if (cs_get_user_team(Players[i]) == CS_TEAM_CT)
			{
				set_bit(g_BackToCT, Players[i])
				cs_set_user_team2(Players[i], CS_TEAM_T)
			}
			give_item(Players[i], "weapon_knife")
			new j = random_num(0, sizeof(_WeaponsFree) - 1)
			
			give_item(Players[i], _WeaponsFree[j])
			cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[j], _WeaponsFreeAmmo[j])
			/// give two random guns
			
			new n = random_num(0, sizeof(_WeaponsFree) - 1)
			while (n == j) { 
				n = random_num(0, sizeof(_WeaponsFree) - 1) 
			}
			
			give_item(Players[i], _WeaponsFree[n])
			cs_set_user_bpammo(Players[i], _WeaponsFreeCSW[n], _WeaponsFreeAmmo[n])
		}
		
	}
	
	//entity_set_int(g_Simon, EV_INT_body, 1)
	//entity_set_int(g_Simon, EV_INT_skin, 0)
	//client_cmd(g_Simon,"model gordon");
	set_user_info(g_Simon, "model", "gordon")
	/*	entity_set_int(g_Simon, EV_INT_skin, 0)
	entity_set_int(g_Simon, EV_INT_body, 1)
	entity_set_int(g_Simon, EV_INT_fixangle, 1);
	entity_set_int(g_Simon, EV_INT_playerclass, 1);
	*/
	
	
	
	new hp = get_pcvar_num(gp_GameHP)
	if (hp < 20) hp = 200
	
	set_user_maxspeed(g_Simon, 320.0)
	set_user_health(g_Simon,  hp*playerCount)
	set_task(5.0, "give_items_gordon", TASK_GIVEITEMS)
	
	set_lights("z")
	emit_sound(0, CHAN_VOICE, "alien_alarm.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
	set_task(5.0, "stop_sound")
	
	return PLUGIN_HANDLED
}

public give_items_gordon()
{
	//give_item(g_Simon, "weapon_knife")
	give_item(g_Simon, "weapon_flashbang")
	current_weapon_fl(g_Simon)
}



public  cmd_punish_ct(id, menu, item)
{
	
	if(item == MENU_EXIT ||( g_Simon != id &&!is_user_admin(id)))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static dst[32],src[32], data[5], player, access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	player = str_to_num(data)
	if (g_Simon == player) return PLUGIN_CONTINUE
	set_bit(g_BackToCT,player)
	cs_set_user_team2(player, CS_TEAM_T)
	
	strip_user_weapons(player)
	give_item(player, "weapon_knife")
	current_weapon(player)
	get_user_name(player, dst, charsmax(dst))
	get_user_name(id, src, charsmax(src))
	player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "UJBM_SIMON_PUNISH", src, dst,dst)
	
	
	
	
	
	
	
	return PLUGIN_HANDLED
}



public chooseteamfunc(id)
{
	if (g_GameMode == 4 || g_GameMode == 5) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE
}


public drop(id)
{
	if (get_bit(g_PlayerCrowbar,id) && (get_user_weapon(id) == CSW_KNIFE)) 
	{
		clear_bit(g_PlayerCrowbar, id)
		current_weapon(id)
		spawn_crowbar(id)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE	
}


public spawn_crowbar(id)
{
	new  ent
	new Float:where[3]
	
	ent = create_entity("info_target")
	set_pev(ent, pev_classname, "crowbar")
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_BOUNCE)
	entity_set_model(ent, "models/w_crowbar.mdl")
	pev(id, pev_origin, where)
	where[2] += 50.0;
	where[0] += random_float(-20.0, 20.0)
	where[1] += random_float(-20.0, 20.0)
	entity_set_origin(ent, where)
	where[0] = 0.0
	where[2] = 0.0
	where[1] = random_float(0.0, 180.0)
	entity_set_vector(ent, EV_VEC_angles, where)
	velocity_by_aim(id, 200, where)
	entity_set_vector(ent,EV_VEC_velocity,where)
	
	
	return PLUGIN_HANDLED
}


public cr_bar_snd(id, world)
	
{
new Float:v[3]
new Float:volume
entity_get_vector(id, EV_VEC_velocity, v)

v[0] = (v[0] * 0.45)
v[1] = (v[1] * 0.45)
v[2] = (v[2] * 0.45)
entity_set_vector(id, EV_VEC_velocity, v)
volume = get_speed(id) * 0.005; 
if (volume > 1.0) volume = 1.0
if (volume > 0.1) emit_sound(id, CHAN_AUTO, "debris/metal2.wav", volume, ATTN_NORM, 0, PITCH_NORM)
return PLUGIN_CONTINUE	
}


public crowbar_touch(ent, player)
{
static touch_class[32]

if (!pev_valid(ent))
	return FMRES_IGNORED
pev(ent, pev_classname, touch_class, 31)
	
if (!is_user_alive(player) || is_user_bot(player) || cs_get_user_team(player) == CS_TEAM_CT)
		return FMRES_IGNORED
	
if (equal(touch_class, "crowbar") && g_GameMode <= 3 && !get_bit(g_PlayerCrowbar, player))
	{
		set_bit(g_PlayerCrowbar, player)
		remove_entity(ent)
		if (get_user_weapon(player) == CSW_KNIFE) current_weapon(player)
		emit_sound(player, CHAN_AUTO, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		return FMRES_SUPERCEDE
	}
return FMRES_IGNORED
}


public task_freeday_end()
{
	emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	g_GameMode = 1
	set_hudmessage(0, 255, 0, -1.0, 0.35, 0, 6.0, 15.0)
	show_hudmessage(0, "%L", LANG_SERVER, "UJBM_STATUS_ENDFREEDAY")
	new playerCount, i 
	new Players[32] 
	get_players(Players, playerCount, "ac") 
	for (i=0; i<playerCount; i++) 
	{
		
		if ( cs_get_user_team(Players[i]) == CS_TEAM_T && is_user_alive(Players[i]) && !get_bit(g_PlayerFreeday, Players[i]) && !get_bit(g_PlayerWanted, Players[i]))
		{
			
			entity_set_int(Players[i], EV_INT_skin, random_num(0,2))
			if (get_pcvar_num (gp_ShowColor) == 1 ) show_color(Players[i])	
		}
	}
	
	
	
	return PLUGIN_CONTINUE
}


/*

public death_event()
{
	
	new id = read_data(2)
	if (g_Simon == id && g_GameMode == 5)
	{
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
		write_short(1<<10)
		write_short(1<<10)
		write_short(0x0000) // fade out
		write_byte(ALIEN_RED)
		write_byte(ALIEN_GREEN)
		write_byte(ALIEN_BLUE)
		write_byte(100)
		message_end()
	}
	return PLUGIN_CONTINUE
}
*/



public rocket_touch(id, world)
{
	
	
	
	new Float:location[3]
	new players[32]
	new playercount
	//stop_sound(0)
	entity_get_vector(id,EV_VEC_origin,location)
	emit_sound(id, CHAN_WEAPON, _RpgSounds[2], 0.0, 0.0, SND_STOP, PITCH_NORM)	
	explode(location, SpriteExplosion, 30, 10, 0)
	
	get_players(players,playercount,"a")
	
	for (new i=0; i<playercount; i++)
	{
		new Float:playerlocation[3]
		new Float:resultdistance
		
		pev(players[i], pev_origin, playerlocation)
		
		resultdistance = get_distance_f(playerlocation,location)
		
		if(resultdistance < 450.0)
		{
			fakedamage(players[i],"RPG",(1000.0 - (2.0*resultdistance)),DMG_BLAST)
			
		}
	}
	
	emit_sound(id, CHAN_AUTO, _RpgSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	remove_entity(id)
	
	return PLUGIN_CONTINUE	
}

public current_weapon_fl(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	
	if (g_Duel == 5 || (g_GameMode == 6 && id == g_Simon))
	{
		set_pev(id, pev_viewmodel2, _RpgModels[1])
		set_pev(id, pev_weaponmodel2, _RpgModels[0])	
	}	
	
	
	return PLUGIN_CONTINUE
}

public rpg_touch(id, world)
	
{
new Float:v[3]
new Float:volume
entity_get_vector(id, EV_VEC_velocity, v)

v[0] = (v[0] * 0.45)
v[1] = (v[1] * 0.45)
v[2] = (v[2] * 0.45)
entity_set_vector(id, EV_VEC_velocity, v)
volume = get_speed(id) * 0.005; 
if (volume > 1.0) volume = 1.0
if (volume > 0.1) emit_sound(id, CHAN_AUTO, "debris/metal2.wav", volume, ATTN_NORM, 0, PITCH_NORM)
return PLUGIN_CONTINUE	
}






public explode(Float:startloc[3], spritename, scale, framerate, flags)
{
message_begin( MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(3) // TE_EXPLOSION
write_coord(floatround(startloc[0]))
write_coord(floatround(startloc[1]))
write_coord(floatround(startloc[2])) // start location
write_short(spritename) // spritename
write_byte(scale) // scale of sprite
write_byte(framerate) // framerate of sprite
write_byte(flags) // flags
message_end()
}




public rpg_pre(weapon)
{
if (!is_valid_ent(weapon)) return PLUGIN_CONTINUE
new id = entity_get_edict( weapon, EV_ENT_owner )
if (g_Duel == 5 || (g_GameMode == 6 && id == g_Simon))
{
	new  ent
	new Float:where[3]
	new gmsgShake = get_user_msgid("ScreenShake") 
	message_begin(MSG_ONE, gmsgShake, {0,0,0}, id)
	write_short(255<< 14 ) //ammount 
	write_short(1 << 14) //lasts this long 
	write_short(255<< 14) //frequency 
	message_end() 
	
	ent = create_entity("info_target")
	set_pev(ent, pev_classname, "rpg_missile")
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_BOUNCE)
	entity_set_model(ent, "models/rpgrocket.mdl")
	pev(id, pev_origin, where)
	where[2] += 50.0;
	where[0] += random_float(-20.0, 20.0)
	where[1] += random_float(-20.0, 20.0)
	entity_set_origin(ent, where)
	entity_get_vector(id,EV_VEC_angles,where)
	//where[1] = random_float(0.0, 180.0)
	entity_set_vector(ent, EV_VEC_angles, where)
	velocity_by_aim(id, 700, where)
	//entity_set_edict(ent, EV_ENT_aiment, id );
	//where[2] += 200.0;
	entity_set_edict(ent,EV_ENT_owner,id)
	entity_set_vector(ent,EV_VEC_velocity,where)
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMFOLLOW )
	write_short(ent) // entity
	write_short(m_iTrail)  // model
	write_byte( 10 )       // lifeffffff
	write_byte( 8 )        // width
	
	write_byte( 130)      // r, g, b
	write_byte( 130 )    // r, g, b
	write_byte( 130 )      // r, g, b
	write_byte( 196 )	 // brightness
	message_end()
	emit_sound(id, CHAN_WEAPON, _RpgSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	emit_sound(ent, CHAN_WEAPON, _RpgSounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	RegisterHamFromEntity(Ham_Think,ent,"fw_rocket_think")
	set_pev(ent, pev_nextthink, get_gametime()+0.25);
	
	
	set_pdata_float( weapon , 46 , 2.5, 4 );
	set_user_weaponanim(id, 2)
	
	//cs_set_weapon_ammo(gun, 2000)
	return HAM_SUPERCEDE
}


return HAM_IGNORED
}

stock set_user_weaponanim(id, anim)
{
entity_set_int(id, EV_INT_weaponanim, anim)
message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
write_byte(anim)
write_byte(entity_get_int(id, EV_INT_body))
message_end()
}  
/*
public rpg_idle(weapon)
{
if (g_Duel == 5)
{
	new id = entity_get_edict( weapon, EV_ENT_owner )
	//set_user_weaponanim(id, 0)
}
return HAM_IGNORED
}
*/
public rpg_reload(weapon)
{
if (g_Duel == 5)
{
	new id = entity_get_edict( weapon, EV_ENT_owner )
	set_user_weaponanim(id, 2)
}
return HAM_IGNORED
}


public cmd_lastrequest1(id)
{
g_Duel = 5	
g_DuelA = id
player_strip_weapons(id)
new gun = give_item(id, _Duel[g_Duel - 4][_entname])
cs_set_weapon_ammo(gun, 1)
set_user_health(id, 2000)
entity_set_int(id, EV_INT_body, 4)
player_glow(id, g_Colors[3])

current_weapon_fl(id)

}

public fw_rocket_think(ent)
{

entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.25) 
new id = entity_get_edict( ent, EV_ENT_owner )
new Float:where[3]
entity_get_vector(id,EV_VEC_angles,where)
entity_set_vector(ent, EV_VEC_angles, where)
velocity_by_aim(id, 700, where)

entity_set_vector(ent,EV_VEC_velocity,where)

return PLUGIN_CONTINUE
}


public help_trollface()
{
new Msg[512];
format(Msg, 511, "%L",LANG_SERVER,"UJBM_HELP_CHAT");
client_print(0,print_chat,Msg)

format(Msg, 511, "^x01Powered by ^x03%s ^x01%s by ^x03%s",PLUGIN_CVAR,PLUGIN_VERSION,PLUGIN_AUTHOR);


new iPlayers[32], iNum, i;
get_players(iPlayers, iNum);

for(i = 0; i <= iNum; i++)
{
	new x = iPlayers[i];
	
	if(!is_user_connected(x) || is_user_bot(x)) continue;
	message_begin( MSG_ONE, g_iMsgSayText, {0,0,0}, x );
	write_byte  ( x );
	write_string( Msg );
	message_end ();
}


//client_print(0,print_chat,Msg)

return PLUGIN_CONTINUE
}




public Showcl_min(id) {
	
			new menu = menu_create("\yset cl_minmodels to 0? You will be able to see high quality models\w^n", "cl_choice")
			
			//formatex(option, charsmax(option),  )
			menu_additem(menu, "Yes", "1", 0)
			
			//formatex(option, charsmax(option), "\rNo^n")
			menu_additem(menu, "No, thanks", "2", 0)
			
			menu_display(id, menu)
	
	}

public cl_choice(id, menu, item) {
{
if(item == MENU_EXIT)
{
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

static dst[32], data[5], access, callback

menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
menu_destroy(menu)
	
if (data[0])
	{
		client_cmd(id,"cl_minmodels 0")
		client_print(id,print_console, "cl_minmodels is now 0, enjoy normal models :)")
	}
		
	}
return PLUGIN_CONTINUE
}
