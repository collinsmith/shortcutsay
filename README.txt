- About -
This plugin was created in order to help make some commands more versatile and also make admins jobs easier. I was looking for a plugin that had similar functionality, but I could not find one, so I made my own. Hopefully other people find this useful.

- Description -
This plugin creates the additional ability for servers to define their own custom say functions. These functions can be as simple as having a function that redefines another plugins command (for different languages, or to make more versions of that command without having any knowledge of the plugins code), or creating simple macros to help say, ban players. Some people (myself included obviously) think that it might be easier to type "/ban tirant" then open up the console and ban him there with more properties.

- The Config File -
The configuration file is loaded at the start of every map loading new commands and changes to the settings. Some basic settings include the access to the commands, prefixes that precede commands, and all commands as well as their functions. The syntax of this file is very important, so only add commands once you understand how this file works (by reading this). All commands can have arguments that can be executed, arguments can either be predefined, or made as parameters. A parameter is defined by creating it within <> characters. Below is what a valid command form looks like. The words in <> tags represent only what the user should receive should he type in incorrect parameters. The actual wording matter not, it's only to help you know the syntax.

Command Form
Quote:
{command} = {function}
Whenever {prefix}{command} is typed, it will execute {function}. A simple example is...

Example 1
Quote:
info = say "Hello!"
Tirant : /info
Tirant : Hello!
Example 2
Quote:
info = say "Hello <Name>!"
Tirant : /info Tirant
Tirant : Hello Tirant!
Lets take a say command that we would like to automate. Let's say that you like telling players information about your server, but typing it out every time is a pain. Well, there are two solutions: bind that to a key, or make it a server command using this plugin.

- Command Prefixes -
A command prefix is a symbol that must show up before a valid command. There are two types of prefixes, one that doesn't hide your macro message, and one that hides your macro message. These symbols are completely customizable, and can really be a cool feature to your mod. A simple example is like the /help command, which is very annoying to see on some servers, so making the '/' prefix hidden, would mean they see the information, but the command is never shown.

- Admin Commands -
Code:

shortcut_toggle [0/1] - Enable/Disable Shortcut Say plugin

- CVARS -
Code:

shortcut_say [0/1] - Enable/Disable Shortcut Say plugin

- Drawbacks to this Plugin -
The major drawback to using this plugin is that this plugin has no knowledge of whether or not the command is actually used, it will only know if the syntax they have entered is correct, and execute the command from that player. After that it is up to the plugin that has the command to execute the function, so the command functions must be correct. You can also only have ONE version of every command, so you cannot override. This might be fixed in a later version, but for now it is alright. There is also a glitch where a player types a command using a shown symbol, and his message not displaying, this is because the players message is being hidden, however no such error effects the same command when a shown symbol is used. This glitch only effects SAY and SAY_TEAM functions.

- Credits -
Tirant - Code
Exolent/Arkshine - Teaching me Trie

- Installation -
Just drag and drop, or place the files into their own corresponding folder one by one. Make sure you add the plugin into your plugins.ini!

- Donations -
If you find this plugin useful, donations are greatly appreciated. Any amount is appreciated, and donations can be made here.