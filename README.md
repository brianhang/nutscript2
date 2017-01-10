# NutScript 2
NutScript 2 is a free roleplay gamemode framework. The intent of NutScript 2 is to provide some functions generally found in most roleplay gamemodes for Garry's Mod so starting a new gamemode is easier as you no longer have to spend a lot of time programming the base of a roleplay gamemode. NutScript 2 aims to provide some general functionality, so any gamemode could be created. The functions provided with NutScript 2 can be found on the [[wiki|https://github.com/brianhang/nutscript2/wiki]].

# Usage
To create your own roleplay gamemode using NutScript 2, first [[set up the normal gamemode files|http://wiki.garrysmod.com/page/Gamemode_Creation]]. In the `cl_init.lua` and `init.lua` files, add the following at the top: `DeriveGamemode("nutscript2")`. This will make your gamemode derive from NutScript so the included function, classes, and hooks can be used. If you need to use features from another gamemode, set `NUT_BASE` to the name of the desired gamemode. For example, if you wanted to have a spawn menu and the tool gun, add `NUT_BASE = "sandbox"` before the call to `DeriveGamemode`.

After you have derived from NutScript 2, a quick way to add functionality to your gamemode is through plugins.
