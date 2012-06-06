/* Deathrun Loxotron
*
* 1.0 
* - Public Release.
* 1.1
* - Только раз за раунд можно использовать лохотрон.
* - Только кт может использовать лохотрон.
* - Исправлена ошибка в логах.
*/

#include < dhudmessage >
#include < hamsandwich >
#include < fakemeta_util >
#include < colorchat >
#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fun >

#define NAME			"[DR] Loxotron"
#define VERSION			"1.2"
#define AUTHOR			"Kard1nal"

#define HUDS			255, 0, 100, 0.15, 0.2, 1, 0.0, 0.5, 1.0, 1.0 -1

const KEYSMENU = 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

new Linsprite 
new moneys
new armors
new healts
new redoff
new oneround[33]

public plugin_init() 
{
	register_plugin(NAME, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawns", 1)

	register_clcmd("say /loxotron", "lox")
	register_clcmd("say /lox", "lox")
	register_clcmd("lox", "lox")
	register_menu("lox", KEYSMENU, "loxmenu")
	
	moneys = register_cvar("dr_moneys", "16000")
	armors = register_cvar("dr_armors", "255")
	healts = register_cvar("dr_healts", "255")
}

public plugin_precache() 
	Linsprite = precache_model("sprites/shockwave.spr")

public lox(id)
{
	if(!is_user_alive(id))
	{
		ColorChat(id, GREEN, "[loxotron] ^1Только для ^4живых^1!")
		return;
	}
	
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		ColorChat(id, GREEN, "[loxotron] ^1Доступно только для зеков!")
		return;
	}
	if(oneround[id])
	{
			ColorChat(id, GREEN, "[loxotron] ^1Возможно использовать только раз за раунд!")
			return;	
	}
	static menu[1000], len
	len = 0
		
	len = formatex(menu[len], charsmax(menu) - len, "\rИграем в лохотрон?^n\rТы можешь выйграть что-то^n\rиз этого!^n\rУдачи^n\r** - \yСмерть^n\r** - \yОболочка^n\r** - \y%d Брони и %d Здоровья^n\r** - \yВсе гранаты^n\r** - \yГравитация^n\r** - \yСкорость^n\r** - \y%d Денег^n^n^n", get_pcvar_num(armors), get_pcvar_num(healts), get_pcvar_num(moneys));

	len += formatex(menu[len], charsmax(menu) - len, "\r1.\yДа^n");
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\yНет^n");

	show_menu(id, KEYSMENU, menu, -1, "loxmenu");
}

public loxmenu(id, key)
{
	switch( key ) 
	{
		case 0:
		{
			{
				new name[32], shans
				get_user_name(id,name,31)
				shans = random_num(0,100)
				set_dhudmessage(HUDS)
				if (shans < 40)
				{
					show_dhudmessage(0, "%s Выиграл смерть", name)
					ColorChat(id, GREEN, "[loxotron] ^1Извините, но вы выиграли ^4смерть^1.")
					user_kill(id)
				}
				else 
				if (shans > 40 && shans < 50)
				{
					show_dhudmessage(0, "%s Выиграл %d брони и %d здоровья", name, get_pcvar_num(armors), get_pcvar_num(healts))
					ColorChat(id, GREEN, "[loxotron] ^1Вы выиграли ^4%d брони ^1и ^4%d здоровья", get_pcvar_num(armors), get_pcvar_num(healts))
					fm_set_user_armor(id, get_pcvar_num(armors))
					fm_set_user_health(id, get_pcvar_num(healts))
				}
				else
				if (shans > 50 && shans < 60)
				{
					show_dhudmessage(0, "%s Выиграл все гранаты", name)
					ColorChat(id, GREEN, "[loxotron] ^1Вы выиграли ^4Все гранаты")
					fm_give_item(id, "weapon_hegrenade")
					fm_give_item(id, "weapon_flashbang")
					fm_give_item(id, "weapon_flashbang")
					fm_give_item(id, "weapon_smokegrenade")
				}
				else
				if (shans > 60 && shans < 70)
				{
					show_dhudmessage(0, "%s Выиграл оболочку", name)
					ColorChat(id, GREEN, "[loxotron] ^1Вы выиграли ^4оболочку")
					set_user_rendering(id, kRenderFxGlowShell, random_num(0, 255), random_num(0, 255), random_num(0, 255), kRenderNormal, random_num(0, 255) );
					redoff = true
				}
				else
				if (shans > 70 && shans < 80)
				{
					show_dhudmessage(0, "%s Выиграл Скорость", name)
					ColorChat(id, GREEN, "[loxotron] ^1Вы выиграли ^4Скорость")
					set_user_maxspeed(id, 400.0)
				}
				else
				if (shans > 80 && shans < 90)
				{
					show_dhudmessage(0, "%s Выиграл Гравитацию", name)
					ColorChat(id, GREEN, "[loxotron] ^1Вы выиграли ^4Гравитацию")
					set_user_gravity( id, 0.5 )
				}
				else
				if (shans > 90 && shans < 100)
				{
					show_dhudmessage(0, "%s Выиграл %d денег", name, get_pcvar_num(moneys))
					ColorChat(id, GREEN, "[loxotron] ^1Вы выиграли ^4%d денег", get_pcvar_num(moneys))
					cs_set_user_money(id, cs_get_user_money(id)+get_pcvar_num(moneys))

				}
			}
			Linial(id)
			oneround[id] = true
		}
		case 1:
			ColorChat(id, GREEN, "[DR] ^1Не хотите - как хотите")
	}
}

public PlayerSpawns(id)
{
	oneround[id] = false
	if(!redoff)
	return
	else
	set_task(0.1, "glowoff", id)
}

public glowoff(id)
{
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 25 );
}

public Linial(id)
{
	static origin[3]
	get_user_origin(id, origin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]-20)	
	write_coord(origin[0]) 
	write_coord(origin[1]) 
	write_coord(origin[2]+70)
	write_short(Linsprite)
	write_byte(0)
	write_byte(255)
	write_byte(6)
	write_byte(60) 
	write_byte(255) 
	write_byte(255) 
	write_byte(0) 
	write_byte(0) 
	write_byte(255)
	write_byte(0)
	message_end()
}
/* Loxotron
* By Kard1nal
* Skype: Kard1nal
* WebSite: forum.ndsys.pro
*/

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
