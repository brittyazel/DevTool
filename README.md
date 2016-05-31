# ViragDevTool Info

ViragDevTool is Lua World of Warcraft addon for addon-developers. 
Functionality is similar to a debugger. 

This addon can help new developers to understand WoW API.
Main idea is to examine WoW API or your addon's variables in table-like UI. 
Much easier to use then default print or chat debug

**[Curse download page](http://mods.curse.com/addons/wow/varrendevtool)** 


> Lua is not my main language. I come from Java world so some things probably could be done better, but it works for me.

## How To Use

Main (and the only) function you can use is **ViragDevTool_AddData(data, "some string name")**:
```lua
--- Adds data to ViragDevTool UI list to monitor
-- @param data (any type)- is object you would like to track. 
-- Default behavior is reference and not object copy
-- @param dataName (string or nil) - name tag to show in UI for you variable. 
-- Main purpose is to give readable names to objects you want to track.
function ViragDevTool_AddData(data, dataName)
 ...
end
```
![ViragDevTool demo][demo]

Lets suppose you have `MyModFN` function in yours addon
```lua
function MyModFN()
    local var = {}
    ... some code here
    ViragDevTool_AddData(var, "My local var in MyModFN")
end
```
This will add var as new row in ViragDevTool UI `HybridScrollFrameTemplate` list

For example 
```lua
ViragDevTool_AddData(_G, "_G")
```
Output: 

![ViragDevTool Global vars demo][GDemo]

| Id(Row in list)   | Type          | Data Name  | Data Value  |
| ----------------- | ------------- | ---------- | -----------------------|
| 1                 | table         | \_G (number of objects in the table) | value   |

### Other functionality
* **Clicking on table name** will expand and show its children
* **Clicking on function name** will try to call the function. **WARNING BE CAREFUL**
* If table has WoW API `GetObjectType()` then its type will be visible in value column
* Strings in value column have no line brakes


### TODO list:

ViragDevTool is in beta (probably even early alpha) so there is lots of stuff to add and tune.

1. Create dynamic text and color size chooser (probably not everyone likes SystemFont_Small)
2. Create edit text ui so we can call functions with args
3. Add filters by object name and type
4. Add Events tracking
5. Add object deep copy option
6. Add predefined buttons for every WoW API (just like _G)
7. Add close frame button 
8. Add row delimiters so we can resize rows in table
9. Add function args info and description from mapping file

### How to contribute
For now this addon will be updated only when i need certain feature in my other addon's development

Prefered option is to use Github issue tracker if you have some todos, bugs, feature requests, and more. 
https://github.com/varren/ViragDevTool/issues

Can also use Curse comments board
http://mods.curse.com/addons/wow/varrendevtool



> Inspired by Rover addon from Wildstar 
> http://mods.curse.com/ws-addons/wildstar/220043-rover

[demo]: http://legacy.curseforge.com/media/images/89/812/1844ef88f22d780658b2150f0cc20c19.png "Logo Title Text 2"
[GDemo]: http://i.gyazo.com/e0287b175965c790b229e4b99418203d.png