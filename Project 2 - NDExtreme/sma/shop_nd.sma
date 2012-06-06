/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN "Extra-shop"
#define VERSION "1.1"
#define AUTHOR "Kard1nal"

new keysmenu = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
new T_item_1, T_item_2, T_item_3, T_item_4, T_item_5, T_item_6, T_item_7,T_item_8, CT_item_1, CT_item_2, CT_item_3
new bool:g_CrowBar[33], g_Chain[33], g_Electro[33], g_speed[33], g_HasWeapon[33]
new Round[33]
new g_msgSayText

new const g_chain_weaponmodel[] = { "models/extreme-shop/p_moto.mdl" }
new const g_chain_viewmodel[] = { "models/extreme-shop/v_moto.mdl" }

new const g_crow_weaponmodel[] = { "models/extreme-shop/p_palo.mdl" }
new const g_crow_viewmodel[] = { "models/extreme-shop/v_palo.mdl" }

new const g_electro_weaponmodel[] = { "models/extreme-shop/p_electro.mdl" }
new const g_electro_viewmodel[] = { "models/extreme-shop/v_electro.mdl" }

public plugin_init() {
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "Spawn_player", 1)
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage")
	
	register_menu("MenuT", keysmenu, "ShopT")
	register_menu("MenuCT", keysmenu, "ShopCT")
	
	T_item_1 = register_cvar("jbe_crowbarcost", "9000")
	T_item_2 = register_cvar("jbe_chaincost", "12000")
	T_item_3 = register_cvar("jbe_electrocost", "10000")
	T_item_4 = register_cvar("jbe_speedcost", "12000")
	T_item_5 = register_cvar("jbe_grenadecost", "5000")
	T_item_6 = register_cvar("jbe_gravitycost", "13000")
	T_item_7 = register_cvar("jbe_glockcost", "16000")
	
	CT_item_1 = register_cvar("jbe_electrocostCT", "6000")
	CT_item_2 = register_cvar("jbe_invisecostCT", "16000")
	CT_item_3 = register_cvar("jbe_extracost", "16000")
	
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
	register_event( "CurWeapon", "WeaponChange", "be", "1=1" )
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	register_clcmd("say /shop", "clcmd_shop")
	
	g_msgSayText = get_user_msgid("SayText")
	
}

public plugin_precache()
{
	precache_model( "models/extreme-shop/p_moto.mdl" )
	precache_model( "models/extreme-shop/v_moto.mdl" )
	precache_model( "models/extreme-shop/p_electro.mdl" )
	precache_model( "models/extreme-shop/v_electro.mdl" )
	precache_model( "models/extreme-shop/p_palo.mdl" )
	precache_model( "models/extreme-shop/v_palo.mdl" )
	precache_sound( "extreme-shop/MTSlash.wav" )
	precache_sound( "extreme-shop/MTConvoca.wav" )
	precache_sound( "extreme-shop/MTHitWall.wav" )
	precache_sound( "extreme-shop/MTHit2.wav" )
	precache_sound( "extreme-shop/MTStab.wav" )
	precache_sound( "extreme-shop/ESlash.wav" )
	precache_sound( "extreme-shop/EConvoca.wav" )
	precache_sound( "extreme-shop/EHitWall.wav" )
	precache_sound( "extreme-shop/EHit2.wav" )
	precache_sound( "extreme-shop/EStab.wav" )
	
}
	

public WeaponChange(id)
{
	if(g_speed[id])
	set_user_maxspeed(id, 600.0)
	
	if (read_data(1) != 1)
		return
	
	static weapon;
	weapon = read_data(2);
	
	if (weapon == CSW_KNIFE && g_Chain[id])
	{
		set_pev(id, pev_viewmodel2, g_chain_viewmodel)
		set_pev(id, pev_weaponmodel2, g_chain_weaponmodel)
	}
	if (weapon == CSW_KNIFE && g_CrowBar[id])
	{
		set_pev(id, pev_viewmodel2, g_crow_viewmodel)
		set_pev(id, pev_weaponmodel2, g_crow_weaponmodel)
	}
	if (weapon == CSW_KNIFE && g_Electro[id])
	{
		set_pev(id, pev_viewmodel2, g_electro_viewmodel)
		set_pev(id, pev_weaponmodel2, g_electro_weaponmodel)
	}
	
}

public TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
		
	if (get_user_weapon(attacker) == CSW_KNIFE && !IsGrenade(inflictor) && g_Chain[attacker])
	{
		SetHamParamFloat(4, 500.0)
	}
	if (get_user_weapon(attacker) == CSW_KNIFE && !IsGrenade(inflictor) && g_Electro[attacker])
	{
		SetHamParamFloat(4, 100.0)
	}
	if (get_user_weapon(attacker) == CSW_KNIFE && !IsGrenade(inflictor) && g_CrowBar[attacker] && get_user_team(attacker) != get_user_team(victim))
	{
		SetHamParamFloat(4, 50.0)
	}
	
	if (get_user_team(victim) == get_user_team(attacker) && IsGrenade(inflictor))
	{
		return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED;
		
	if (g_Chain[id] && equal(sample[8], "kni", 3))
	{
		volume = 0.6;
		
		if (equal(sample[14], "sla", 3))
		{
			engfunc(EngFunc_EmitSound, id, channel, "extreme-shop/MTSlash.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		if(equal(sample,"weapons/knife_deploy1.wav"))
		{
			engfunc(EngFunc_EmitSound, id, channel, "extreme-shop/MTConvoca.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		if (equal(sample[14], "hit", 3))
		{
			if (sample[17] == 'w') 
			{
				engfunc(EngFunc_EmitSound, id, channel,"extreme-shop/MTHitWall.wav", volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			else 
			{
				engfunc(EngFunc_EmitSound, id, channel, "extreme-shop/MTHit2.wav", volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
		if (equal(sample[14], "sta", 3)) 
		{
			engfunc(EngFunc_EmitSound, id, channel, "extreme-shop/MTStab.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
	}
	if (g_Electro[id] && equal(sample[8], "kni", 3))
	{
		volume = 0.6;
		
		if (equal(sample[14], "sla", 3))
		{
			engfunc(EngFunc_EmitSound, id, channel, "extreme-shop/ESlash.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		if(equal(sample,"weapons/knife_deploy1.wav"))
		{
			engfunc(EngFunc_EmitSound, id, channel, "extreme-shop/EConvoca.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		if (equal(sample[14], "hit", 3))
		{
			if (sample[17] == 'w') 
			{
				engfunc(EngFunc_EmitSound, id, channel,"extreme-shop/EHitWall.wav", volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			else 
			{
				engfunc(EngFunc_EmitSound, id, channel, "extreme-shop/EHit2.wav", volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
		if (equal(sample[14], "sta", 3)) 
		{
			engfunc(EngFunc_EmitSound, id, channel, "extreme-shop/EStab.wav", volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public Spawn_player(id)
{
	if(is_user_alive(id) && is_user_connected(id))
	{
		g_CrowBar[id] = false
		g_Chain[id] = false
		g_Electro[id] = false
		g_speed[id] = false
		g_HasWeapon[id] = false
		set_user_rendering(id)
	}
}


public clcmd_shop(id)
{
	if(!is_user_alive(id))
	return PLUGIN_HANDLED
	
	static menu[500], len
	len = 0
	
	if(get_user_team(id) == 1)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\rМагазин для террористов^n^n")
		
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\wВантус - \y%d $^n", get_pcvar_num(T_item_1))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\wБензопила - \y%d $^n", get_pcvar_num(T_item_2))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\wЭлектрошок - \y%d $^n", get_pcvar_num(T_item_3))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\wСкорость - \y%d $^n", get_pcvar_num(T_item_4))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r5.\wГранаты - \y%d $^n", get_pcvar_num(T_item_5))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r6.\wГравитация - \y%d $^n", get_pcvar_num(T_item_6))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r7.\wГлок - \y%d $^n", get_pcvar_num(T_item_7))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r0.\wВыход^n")
		
		show_menu(id, keysmenu, menu, -1, "MenuT")
	}
	if(get_user_team(id) == 2)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\rМагазин для контр-террористов^n^n")
		
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\wЭлектрошок - \y%d $^n", get_pcvar_num(CT_item_1))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\wНевидимость(раз в 20 раундов) - \y%d $^n", get_pcvar_num(CT_item_2))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\wЭкстранабор - \y%d $^n", get_pcvar_num(CT_item_3))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\wСкорость - \y%d $^n", get_pcvar_num(T_item_4))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r0.\wВыход^n")
		
		show_menu(id, keysmenu, menu, -1, "MenuCT")
	}
	
	return PLUGIN_HANDLED
}

public ShopT(id, key)
{
	    new alive = is_user_alive(id)
	    new team = get_user_team(id)
	    new user_money = cs_get_user_money(id) 
	    new CostT1 = get_pcvar_num(T_item_1)
	    new CostT2 = get_pcvar_num(T_item_2)
	    new CostT3 = get_pcvar_num(T_item_3)
	    new CostT4 = get_pcvar_num(T_item_4)
	    new CostT5 = get_pcvar_num(T_item_5)
	    new CostT6 = get_pcvar_num(T_item_6)
	    new CostT7 = get_pcvar_num(T_item_7)
	    switch(key)
	    {
	    	case 0:
		{
			if(user_money >= CostT1 && alive && team == 1 && !g_HasWeapon[id])
			{
				engclient_cmd(id, "weapon_knife")
				set_pev(id, pev_viewmodel2, g_crow_viewmodel)
				set_pev(id, pev_weaponmodel2, g_crow_weaponmodel)
				g_CrowBar[id] = true
				g_HasWeapon[id] = true
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrВантус" )
				cs_set_user_money(id, user_money - CostT1)
			}
			else if(g_HasWeapon[id])
			{
				client_printcolor(id, "/g[Магазин] /yу Вас уже есть /ctrВантус!" )
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
		case 1:
		{
			if(user_money >= CostT2 && alive && team == 1 && !g_HasWeapon[id])
			{
				engclient_cmd(id, "weapon_knife")
				set_pev(id, pev_viewmodel2, g_chain_viewmodel)
				set_pev(id, pev_weaponmodel2, g_chain_weaponmodel)
				g_Chain[id] = true
				g_HasWeapon[id] = true
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrБензопилу" )
				cs_set_user_money(id, user_money - CostT2)
			}
			else if(g_HasWeapon[id])
			{
				client_printcolor(id, "/g[Магазин] /yу Вас уже есть /ctrБензопила!" )
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
		case 2:
		{
			if(user_money >= CostT3 && alive && team == 1 && !g_HasWeapon[id])
			{
				engclient_cmd(id, "weapon_knife")
				set_pev(id, pev_viewmodel2, g_electro_viewmodel)
				set_pev(id, pev_weaponmodel2, g_electro_weaponmodel)
				g_Electro[id] = true
				g_HasWeapon[id] = true
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrЭлектрошок" )
				cs_set_user_money(id, user_money - CostT3)
			}
			else if(g_HasWeapon[id])
			{
				client_printcolor(id, "/g[Магазин] /yу Вас уже есть /ctrЭлектрошок!" )
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
		case 3:
		{
			if(user_money >= CostT4 && alive && team == 1)
			{
				set_user_maxspeed(id, 600.0)
				g_speed[id] = true
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrСкорость" )
				cs_set_user_money(id, user_money - CostT4)
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
		case 4:
		{
			if(user_money >= CostT5 && alive && team == 1)
			{
				give_item(id, "weapon_hegrenade")
				give_item(id, "weapon_flashbang")
				give_item(id, "weapon_flashbang")
				give_item(id, "weapon_smokegrenade")
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrГранаты" )
				cs_set_user_money(id, user_money - CostT5)
				
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
		case 5:
		{
			if(user_money >= CostT6 && alive & team == 1)
			{
				set_user_gravity(id, 0.2)
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrГравитацию" )
				cs_set_user_money(id, user_money - CostT6)
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
		case 6:
		{
			if(user_money >= CostT7 && alive & team == 1)
			{
				give_item(id, "weapon_glock18")
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrГлок" )
				cs_set_user_money(id, user_money - CostT7)
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
	}
	
	//menu_destroy(menu)
	
	return PLUGIN_HANDLED
}  


public ShopCT(id, key)
{
	    new alive = is_user_alive(id)
	    new team = get_user_team(id)
	    new user_money = cs_get_user_money(id) 
	    new CostCT1 = get_pcvar_num(CT_item_1)
	    new CostCT2 = get_pcvar_num(CT_item_2)
	    new CostCT3 = get_pcvar_num(CT_item_3)
	    new CostCT4 = get_pcvar_num(T_item_4)
	    switch(key)
	    {
	    	case 0:
		{
			if(user_money >= CostCT1 && alive && team == 2)
			{
				engclient_cmd(id, "weapon_knife")
				set_pev(id, pev_viewmodel2, g_electro_viewmodel)
				set_pev(id, pev_weaponmodel2, g_electro_weaponmodel)
				g_Electro[id] = true
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrЭлектрошок" )
				cs_set_user_money(id, user_money - CostCT1)
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватет /ctrденег!" )
			}
		}
		case 1:
		{
			if(user_money >= CostCT2 && alive && team == 2 && Round[id] == 0)
			{
				set_user_rendering(id, kRenderFxGlowShell, 0 , 0 , 0 , kRenderTransAlpha, 0 )
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrНевидимость" )
				cs_set_user_money(id, user_money - CostCT2)
			}
			else if(Round[id] > 0)
			{
				client_printcolor(id, "/g[Магазин] /yПодождите /ctr%d /yраунда(ов)!", Round[id] )
				
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
		case 2:
		{
			if(user_money >= CostCT3 && alive && team == 2)
			{
				cs_set_user_armor(id, 500, CS_ARMOR_VESTHELM)
				set_user_health(id, 500)
				give_item(id, "weapon_m249")
				cs_set_user_bpammo(id, CSW_M249, 200)
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrЭкстранабор" )
				cs_set_user_money(id, user_money - CostCT3)
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
		case 3:
		{
			if(user_money >= CostCT4 && alive && team == 2)
			{
				set_user_maxspeed(id, 320.0)
				g_speed[id] = true
				client_printcolor(id, "/g[Магазин] /yВы купили /ctrСкорость" )
				cs_set_user_money(id, user_money - CostCT4)
			}
			else
			{
				client_printcolor(id, "/g[Магазин] /yу Вас не хватает /ctrденег!" )
			}
		}
	}
	
	return PLUGIN_HANDLED
}


public round_start()
{
	for(new id = 0; id < 33; id++)
	{
		if(Round[id] > 0 && is_user_alive(id))
		{
			Round[id] -= 1
		}
	}
}

bool:IsGrenade(i_Inflictor)
{
	static s_Classname[8];
	pev(i_Inflictor, pev_classname, s_Classname, charsmax(s_Classname));
        
	return equal(s_Classname, "grenade") ? true : false;
}

stock client_printcolor(const id, const input[], any:...) 
{ 
    new iCount = 1, iPlayers[32] 
     
    static szMsg[191] 
    vformat(szMsg, charsmax(szMsg), input, 3) 
     
    replace_all(szMsg, 190, "/g", "^4") // green txt 
    replace_all(szMsg, 190, "/y", "^1") // orange txt 
    replace_all(szMsg, 190, "/ctr", "^3") // team txt 
    replace_all(szMsg, 190, "/w", "^0") // team txt 
     
    if(id) iPlayers[0] = id 
    else get_players(iPlayers, iCount, "ch") 
         
    for (new i = 0; i < iCount; i++) 
    { 
        if (is_user_connected(iPlayers[i])) 
        { 
            message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, iPlayers[i]) 
            write_byte(iPlayers[i]) 
            write_string(szMsg) 
            message_end() 
        } 
    }
}
