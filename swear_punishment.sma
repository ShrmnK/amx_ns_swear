/* AMX Mod X Script
* 
* Swear Punishment by KrX
* Based on plugin "Swear Filter" v1.0a by SuicideDog
* Some code taken from semaja2's Admin Weapons: Rework v1.0
* Some code taken from White Panther's NS: RTD v0.9.0
* Idea & Plugin Name by White Knight
* 
* Many thanks to White Knight for helping to test
* 
* Replaces badwords as input from swearwords.ini with *'s, 
* then performs punishment on client
*
* Uses swearwords.ini file (ns/addons/amxmodx/configs/swear/swearwords.ini)
* 
*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <ns>
#include <fakemeta>

// max number of words in word list 
#define MAX_WORDS 192

// DO NOT TOUCH ANYTHING ELSE FROM HERE UNLESS YOU KNOW WHAT YOU ARE DOING!

#pragma semicolon 1

static plugin_version[] = "0.3b";
static cvar_realslap, cvar_death, cvar_notify, cvar_slaphp, cvar_slapap;
static cvar_slow, cvar_slowspeed, cvar_burry, Float:cvar_burry_y;
new g_swearsNames[MAX_WORDS][32];
new g_swearsNum;

public plugin_init() 
{ 
	register_plugin("Swear Punishment",plugin_version,"KrX");
	register_cvar("KrX_swearpunish",plugin_version,FCVAR_SERVER);
	
	register_clcmd("say","swearcheck");
	register_clcmd("say_team","swearcheck");
	
	register_cvar("amx_sp_realslap", "1");
	register_cvar("amx_sp_death", "1");
	register_cvar("amx_sp_notify", "1");
	register_cvar("amx_sp_slaphp", "30");
	register_cvar("amx_sp_slapap", "30");
	register_cvar("amx_sp_burry", "1");
	register_cvar("amx_sp_burry_y", "30.0");
	register_cvar("amx_sp_slow", "1");
	register_cvar("amx_sp_slowspeed", "100");
	cvar_realslap = get_cvar_pointer("amx_sp_realslap");
	cvar_death = get_cvar_pointer("amx_sp_death");
	cvar_notify = get_cvar_pointer("amx_sp_notify");
	cvar_slaphp = get_cvar_pointer("amx_sp_slaphp");
	cvar_slapap = get_cvar_pointer("amx_sp_slapap");
	cvar_burry = get_cvar_pointer("amx_sp_burry");
	cvar_burry_y = get_cvar_float("amx_sp_burry_y");
	cvar_slow = get_cvar_pointer("amx_sp_slow");
	cvar_slowspeed = get_cvar_pointer("amx_sp_slowspeed");
	readList();
	
	server_print("[Swear Punishment v%s] Loaded Succesfully!", plugin_version);
}

readList() 
{ 
	// file to read words from 
	new szCustomDir[64];
	new filename[64];
	get_configsdir( szCustomDir, 63 );
	format(filename, 63, "%s/swear/swearwords.ini", szCustomDir );
	
	if(!file_exists(filename) ){
		log_message("Swear Punishment v%s: file %s not found", plugin_version, filename); 
		return; 
	} 
	new iLen;
	while( g_swearsNum < MAX_WORDS && read_file(filename, g_swearsNum ,g_swearsNames[g_swearsNum][1],30,iLen) ) 
	{ 
		if( g_swearsNames[g_swearsNum][0] == ';') continue;
		g_swearsNames[g_swearsNum][0] = iLen; 
		++g_swearsNum;
	}
	log_message("Swear Punishment v%s: loaded %d words", plugin_version, g_swearsNum ); 
} 

public swearcheck(id) 
{
	new szSaid[192];
	read_args(szSaid,191);
	new bool:found = false;
	new pos, i = 0;
	while ( i < g_swearsNum )
	{
		if ( (pos = containi(szSaid,g_swearsNames[i][1])) != -1 ){ 
			new len = g_swearsNames[i][0];
			while(len--) {
				szSaid[pos++] = '*';
			}
			found = true;
			continue;
		}
		i++;
	}
	if ( found ){
		new cmd[32];
		read_argv(0,cmd,31);
		engclient_cmd(id,cmd,szSaid);
		
		// START PUNISHMENT!
		// DICE: 1 = SLAP!
		// DICE: 2 = Stuck (Burried)!
		// DICE: 3 = Slow Speed!
		// DICE: 4 = ClipSize
		
		new dice;		
		dice = (random(3) + 1);	// Random will generate number between 0 to param
		
		if(!get_pcvar_num(cvar_burry) && !get_pcvar_num(cvar_slow)) {	// Check if all options other than slap
			dice = 1;
		} else {
			if(!get_pcvar_num(cvar_burry)) {	// Check if option is cvar-enabled
				while(dice == 2) {	// If it has not be enabled, keep rolling until option is not chosen
					dice = (random(3) + 1);
				}
			}
			
			if(!get_pcvar_num(cvar_slow)) {	// Check if option is cvar-enabled
				while(dice == 3) {	// If it has not be enabled, keep rolling until option is not chosen
					dice = (random(3) + 1);
				}
			}
		}
		
		switch (dice)
		{
			case 1:
			{
				if(get_pcvar_num(cvar_realslap))	// If Really Slap
					user_slap(id, 0, 1);
				new name[33], tempprintf[129], tempsHP[11], tempsAP[11];
				get_user_name(id, name, 32);
				num_to_str(get_pcvar_num(cvar_slaphp), tempsHP, 10);
				num_to_str(get_pcvar_num(cvar_slapap), tempsAP, 10);
				
				strcat(tempprintf, "* ", 128);
				strcat(tempprintf, name, 128);
				strcat(tempprintf, " has been been slapped ", 128);
				
				if(get_user_health(id) > get_pcvar_num(cvar_slaphp)) {
					set_user_health(id, (get_user_health(id) - get_pcvar_num(cvar_slaphp)));
					strcat(tempprintf, tempsHP, 128);
				} else {
					if(!get_pcvar_num(cvar_death)) {
						set_user_health(id, 1);
						strcat(tempprintf, "until 1hp", 128);
					} else {
						user_kill(id);
						strcat(tempprintf, "until death", 128);
					}
				}
				strcat(tempprintf, " and ", 128);
				if(get_user_health(id) > get_pcvar_num(cvar_slaphp)) {
					set_user_armor(id, (get_user_armor(id) - get_pcvar_num(cvar_slapap)));
					strcat(tempprintf, tempsAP, 128);
				} else {
					if(!get_pcvar_num(cvar_death)) {
						set_user_armor(id, 1);
						strcat(tempprintf, "until 1ap", 128);
					} else {
						set_user_armor(id, 0);
						strcat(tempprintf, "until no ap", 128);
					}
				}
				strcat(tempprintf, " for swearing *", 128);
				if(get_pcvar_num(cvar_notify))
					client_print(0, print_chat, "%s", tempprintf);
			}
			
			case 2:
			{
				new name[33];
				get_user_name(id, name, 32);
				
				new Float:origin[3];
				pev(id, pev_origin, origin);
				origin[2] -= cvar_burry_y;
				set_pev(id, pev_origin, origin);
				
				if(get_pcvar_num(cvar_notify))
					client_print(0, print_chat, "* %s has been burried for swearing *", name);
			}
			
			case 3:
			{
				new name[33];
				get_user_name(id, name, 32);
				
				ns_set_speedchange(id, (- get_pcvar_num(cvar_slowspeed)));
				
				if(get_pcvar_num(cvar_notify))
					client_print(0, print_chat, "* %s has his speed reduced by %d for swearing *", name, get_pcvar_num(cvar_slowspeed));
			}
		}
	}
	return PLUGIN_CONTINUE;
} 
