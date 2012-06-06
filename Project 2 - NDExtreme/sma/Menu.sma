#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define PLUGIN "Jailmenu"
#define VERSION "2.0"
#define AUTHOR "Kard1nal"

public plugin_init() {

register_clcmd("jailmenu", "cmdMenu", ADMIN_ALL);
register_plugin(PLUGIN, VERSION, AUTHOR);
}

public cmdMenu(id)

{

if(cs_get_user_team(id) == CS_TEAM_T)
{
new i_Menu = menu_create("\wМеню Заключённого\r", "shop_choice_T");
menu_additem(i_Menu, "\rМагазин", "1", 0);
menu_additem(i_Menu, "\dМеню последнего зека", "2", 0);
menu_additem(i_Menu, "\wЛототрон", "3", 0);
menu_additem(i_Menu, "\yVIP меню", "4", 0);
menu_setprop(i_Menu, MPROP_NEXTNAME, "Далее");
menu_setprop(i_Menu, MPROP_BACKNAME, "Назад");
menu_setprop(i_Menu, MPROP_EXITNAME, "Выход");

menu_display(id, i_Menu, 0)
}
else
if(cs_get_user_team(id) == CS_TEAM_CT)
{
new i_Menu = menu_create("\wМеню Охранника\r", "shop_choice_CT");
menu_additem(i_Menu, "\rВзять саймона", "1", 0);
menu_additem(i_Menu, "\yМагазин", "2", 0);
menu_additem(i_Menu, "\wВыписать FD", "3", 0);
menu_additem(i_Menu, "\wОткрыть клетки! [\dСаймон\w]", "4", 0);
menu_additem(i_Menu, "\wИгры \r[New] \w[\dАдмин\w]", "5", 0);
menu_additem(i_Menu, "\yVIP меню", "6", 0);
menu_setprop(i_Menu, MPROP_NEXTNAME, "Далее");
menu_setprop(i_Menu, MPROP_BACKNAME, "Назад");
menu_setprop(i_Menu, MPROP_EXITNAME, "Выход");

menu_display(id, i_Menu, 0)
}
return PLUGIN_HANDLED
}

public client_authorized(id)
{
client_cmd(id, "bind ^"F3^" ^"jailmenu^"")
}

public shop_choice_T(id, menu, item) {
if( item < 0 ) return PLUGIN_CONTINUE;
new cmd[3], access, callback;
menu_item_getinfo(menu, item, access, cmd,2,_,_, callback);
new Choise = str_to_num(cmd)
switch (Choise) {
case 1: {
client_cmd(id, "say /shop")
}
case 2: {
client_cmd(id, "say /lr")
}
case 3: {
client_cmd(id, "lox")
}
case 4: {
client_cmd(id, "vip_menu_zona")
}
}
return PLUGIN_HANDLED;
}


public shop_choice_CT(id, menu, item) {
if( item < 0 ) return PLUGIN_CONTINUE;
new cmd[3], access, callback;
menu_item_getinfo(menu, item, access, cmd,2,_,_, callback);
new Choise = str_to_num(cmd)
switch (Choise) {
case 1: {
client_cmd(id, "say /simon")
}
case 2: {
client_cmd(id, "say /shop")
}
case 3: {
client_cmd(id, "say /fd")
}
case 4: {
client_cmd(id, "say /open")
}
case 5: {
client_cmd(id, "say /games")
}
case 6: {
client_cmd(id, "vip_menu_zona")
}
}
return PLUGIN_HANDLED;
}