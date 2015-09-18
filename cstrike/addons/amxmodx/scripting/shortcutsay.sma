/**
 * AMX Mod X Script.
 *
 * ¦ Author  : Tirant
 * ¦ Plugin  : Shortcut Say Commands
 * ¦ Version : v0.0.1
 *
 * Support:
 *	
 *
 * Description:
 *	This plugin enables admins with the correct levels to use say-commands
 *	to execute defined functions from that player ingame.
 *
 * Requirements:
 *	AMX Mod X 1.8.x or higher.
 *
 * Additional Sources:
 * (!) Zombie Plague:
 *	[ https://forums.alliedmods.net/showthread.php?t=72505 	]
 *	- Design of the configuration file.
 *
 * Credits:
 *	Tirant : Coding
 */
#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

/**
 * Defined constant representing the location of the configurations file this
 * plugin will use.
 */
#define CONFIGS_FILE "shortcutsay.ini"

/**
 * Defined constant representing the location of the dictionary file this
 * plugin will use.
 */
#define LANGUAGE_FILE "shortcutsay.txt"

/**
 * Static constant field representing the name of this plugin.
 */
static const Plugin [] = "Shortcut Say Commands";

/**
 * Static constant field representing the author of this plugin.
 */
static const Author [] = "Tirant";

/**
 * Static constant field representing the version of this plugin.
 */
static const Version[] = "0.0.1";

/**
 * Enumerated fields representing the various sections inside of the CONFIGS_FILE.
 */
enum _:eSectionParseList {
	SECTION_NONE = 0,
	SECTION_ACCESS_FLAGS,
	SECTION_COMMANDS_PREFIXES,
	SECTION_COMMANDS
};

/**
 * Static Array: field representing a list of functions attached to commands. Each
 * function is set in the loadCustomConfigs() method, and the indeces of these 
 * functions are matched with their command executor's located in g_tCmdCommands.
 */
static Array:g_aFunctionList;

/**
 * Static Trie: field representing a list of command executors that a player needs
 * to type in order for its' function to be executed.  These commands are not
 * case-sensitive, and are registered inside of the loadCustomConfigs() method.
 */
static Trie:g_tCmdCommands;

/**
 * Enumerated fields representing the two types of prefixes that commands will use.
 * A hidden prefix will hide the usage of the clients command, while the shown
 * prefix will display the command to the public.
 */
enum _:eCommandPre {
	PREFIX_HIDDEN = 0,
	PREFIX_SHOWN
};

/**
 * Static constant field representing the command prefixes config file symbols.  These
 * are defined in order to create a looping check, rather than a if-else if-else series.
 */
static const g_szConfigFileCmdsPre[eCommandPre][] = {
	"HIDDEN COMMANDS",
	"DISPLAYED COMMANDS"
};

/**
 * Static Trie: field representing all command prefixes that are allowed to be used
 * this plugin. Every prefix located within this Trie will act as a command checker
 * any any valid command following a symbol will be executed.
 */
static Trie:g_tCmdPrefixes;

/**
 * Enumerated fields representing a series of CVars that are used in this plugin.
 */
enum _:eCvarList {
	CVAR_ENABLED = 0,
	CVAR_ACCESS
};

/**
 * Static constant field representing the config file symbols associated with the CVars
 * located in the eCvarList enumeration.
 */
static const g_szConfigFileCvars[eCvarList][] = {
	"ENABLE/DISABLE MOD",
	"MINIMUM ACCESS"
};


/**
 * Static array field representing the pointers for enumerations listed in the eCvarList
 * field.  These CVars are assigned values inside of the plugin_init() method.
 */
static g_pCvars[eCvarList];

/**
 * Static array field representing the access flags for fields located within the eCvarList
 * field.  These CVars are assigned values inside of the loadCustomConfigs() method, and
 * checked on players whenever their commands are executed.
 */
static g_pCvarsAccess[eCvarList];

/**
 * AMXModX native forward executed upon the loading of this plugin into the modification.  This
 * method is used to register this plugin, as well as check to see if it is currently enabled.
 * If this plugin is not enabled, then it will stop the plugin here. This method is also used 
 * to precache any files, but used in this plugin to initialize the config file values and cache
 * them using the loadCustomConfigs() method.
 */
public plugin_precache() {
	register_plugin(Plugin, Version, Author);
	register_cvar("shortcutsay_version", Version, FCVAR_SPONLY|FCVAR_SERVER);
	set_cvar_string("shortcutsay_version", Version);
	
	register_concmd("shortcut_toggle", "cmdToggle", _, "[0/1] - Enable/Disable Shortcut Say plugin", 0);
	
	// Admin efficiency plugin [0/1]
	g_pCvars[CVAR_ENABLED] = register_cvar("shortcut_say", "1");
	
	if (!get_pcvar_num(g_pCvars[CVAR_ENABLED]))
		return;
		
	g_tCmdPrefixes = TrieCreate();
	g_tCmdCommands = TrieCreate();
	g_aFunctionList = ArrayCreate(64, 1);
	
	loadCustomConfigs();
}

/**
 * AMXModX native forward executed upon the loading of this plugin into the modification.  This
 * method is used to register some needed commands into the plugin, but only if this plugin is
 * currently enabled.
 */
public plugin_init() {
	if (!get_pcvar_num(g_pCvars[CVAR_ENABLED]))
		return;
		
	register_clcmd("say",	   "cmdSay", _, " - Checks all entered text for specified commands");
	register_clcmd("say_team", "cmdSay", _, " - Checks all entered text for specified commands");
	
	register_dictionary(LANGUAGE_FILE);
}

/**
 * Private method that loads all information from the CONFIGS_FILE, and caches it into this 
 * plugin. This method will check to see if the file is valid, and if it is not, then this
 * plugin will crash.  This method will then open the file and go through it line by line,
 * searching section by section in order to cache the proper information reguarding this plugin.
 */
loadCustomConfigs() {
	new path[64];
	get_configsdir(path, charsmax(path));
	format(path, charsmax(path), "%s/%s", path, CONFIGS_FILE);
	if (!file_exists(path)) {
		new error[100];
		formatex(error, charsmax(error), "Cannot load customization file %s!", path);
		set_fail_state(error);
		return;
	}
	
	new linedata[1024], key[64], value[960], section, i;
	new file = fopen(path, "rt");
	while (file && !feof(file)) {
		fgets(file, linedata, charsmax(linedata));
		replace(linedata, charsmax(linedata), "^n", "");
		if (!linedata[0] || linedata[0] == ';')
			continue;

		if (linedata[0] == '[') {
			section++;
			continue;
		}
		
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=');
		trim(key);
		trim(value);
		
		switch (section) {
			case SECTION_ACCESS_FLAGS: {
				for (new i = 0; i < eCvarList; i++) {
					if (equal(key, g_szConfigFileCvars[i])) {
						if (equali(value, "ADMIN_ALL"))
							g_pCvarsAccess[i] = ADMIN_ALL;
						else
							g_pCvarsAccess[i] = read_flags(value);
					}
				}
			}
			case SECTION_COMMANDS_PREFIXES: {
				for (new i = 0; i < eCommandPre; i++) {
					if (equal(key, g_szConfigFileCmdsPre[i])) {
						// Parse the command prefixes
						while (value[0] != 0 && strtok(value, key, 1, value, charsmax(value), ',')) {
							trim(key);
							trim(value);
							strtolower(key);
							TrieSetCell(g_tCmdPrefixes, key, i);
						}
						break;
					}
				}
			}
			case SECTION_COMMANDS: {
				// Parse the command variations
				strtolower(key);
				TrieSetCell(g_tCmdCommands, key, i++);
				ArrayPushString(g_aFunctionList, value);
			}
		}
	}
	
	if (file)
		fclose(file);
}

/**
 * This method is called whenever a player types a message.  This method checks to see if this
 * plugin is enabled, and then is the player has valid access to use commands listed in this
 * plugin.  When a player's command is received, his entire message is scrutinized and split
 * apart to check if the syntax is valid and matches a command.  If a player's syntac is not
 * valid, then he is told of the correct syntax.  Because it is impossible to know if the commands
 * have failed or succeeded, this plugin will only tell you if the syntax is wrong when it is
 * according to the commands function, and right when it is right according the the commands
 * function.
 *
 * @param id	The player index who is sending this event.
 */
public cmdSay(id) {
	if (!get_pcvar_num(g_pCvars[CVAR_ENABLED]))
		return PLUGIN_CONTINUE;
		
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	new szMessage[32];
	read_args(szMessage, charsmax(szMessage));
	remove_quotes(szMessage);
	copy(szMessage, 1, szMessage);

	new iValidCommand = 0, iCommand = 0;
	if (TrieGetCell(g_tCmdPrefixes, szMessage, iCommand)) {
		switch(iCommand) {
			case PREFIX_HIDDEN: iValidCommand = 1;
			case PREFIX_SHOWN:  iValidCommand = 2;
		}
	} else {
		return PLUGIN_CONTINUE;
	}
	
	if (iValidCommand > 0) {
		read_args(szMessage, charsmax(szMessage));
		remove_quotes(szMessage);
		new szCommand[16], szTarget[64];
		strbreak(szMessage[1], szCommand, charsmax(szCommand), szTarget, charsmax(szTarget));
		trim(szTarget);
		strtolower(szCommand);
		if (TrieGetCell(g_tCmdCommands, szCommand, iCommand)) {
			/* 
			 * Now that we know it IS a valid command of some sort, we can tell him
			 * that he has no access.
			 */
			if (!access(id, g_pCvarsAccess[CVAR_ACCESS])) {
				client_print(id, print_chat, "%L", id, "NO ACCESS");
				return PLUGIN_HANDLED;
			}
			
			new szFunction[64];
			ArrayGetString(g_aFunctionList, iCommand, szFunction, charsmax(szFunction));			
			if (contain(szFunction, "<") != -1) {
				new szTemp[32], szParameters[64], szFunctionTemp[64], bool:shouldPrint, i, j;
				copy(szFunctionTemp, charsmax(szFunction), szFunction);
				while (szFunctionTemp[0] != 0 && strtok(szFunctionTemp, szTemp, charsmax(szTemp), szFunctionTemp, charsmax(szFunctionTemp), '<')) {
					if (szFunctionTemp[0] != 0 && strtok(szFunctionTemp, szTemp, charsmax(szTemp), szFunctionTemp, charsmax(szFunctionTemp), '>')) {
						i++;
						format(szTemp, charsmax(szTemp), " <%s>", szTemp);
						add(szParameters, charsmax(szParameters), szTemp);
						if (szTarget[0] != 0) {
							shouldPrint = true;
							new szTemp2[32];
							if (strbreak(szTarget, szTemp2, charsmax(szTemp2), szTarget, charsmax(szTarget))) {
								format(szTemp2, charsmax(szTemp2), " %s", szTemp2);
								replace(szFunction, charsmax(szFunction), szTemp, szTemp2);
								j++;
							}
						} else {
							break;
						}
					}
				}
				
				if (j < i) {
					client_print(id, print_chat, "%L: %s%s", id, "BAD PARAMS", szCommand, szParameters);
				} else if (shouldPrint) {
					client_cmd(id, szFunction);
				} else {
					client_print(id, print_chat, "%L: %s%s", id, "BLANK COMMAND", szCommand, szParameters);
				}
			} else {
				client_cmd(id, szFunction);
			}
		
			switch (iValidCommand) {
				case 1:  return PLUGIN_HANDLED;
				case 2:  return PLUGIN_CONTINUE;
				default: return PLUGIN_CONTINUE;
			}
		}
	}
	return PLUGIN_CONTINUE;
}

/**
 * Public method called when a player says "admincmds_toggle" in his/her console.  If this player
 * has access, then this method will attempt to change the status of this plugin.
 */
public cmdToggle(id, level, cid) {
	if (!cmd_access(id, g_pCvarsAccess[CVAR_ENABLED], cid, 2))
		return PLUGIN_HANDLED;
	
	new arg[2];
	read_argv(1, arg, charsmax(arg));
	
	if (str_to_num(arg) == get_pcvar_num(g_pCvars[CVAR_ENABLED]))
		return PLUGIN_HANDLED;
	
	set_pcvar_num(g_pCvars[CVAR_ENABLED], str_to_num(arg));
	client_print(id, print_console, "You have just %sabled %s", str_to_num(arg) ? "en" : "dis", Plugin);
	
	return PLUGIN_HANDLED;
}
