# ViragDevTool Info

ViragDevTool is Lua World of Warcraft addon to help new developers with WoW API. 
This addon help you examine WoW API or your addon variables. 
Much easier to use than default print or console debug


## How To Use

Main (and the only) function you can use is **ViragDevTool_AddData(data, "some string name")**:
```lua
--- Adds data to ViragDevTool UI list to monitor
-- @param data (any type)- is object you would like to track. 
-- Default behavior is shallow copy
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
* **Clicking on function name** wil try to call the function. **WARNING BE CAREFUL**
* If table has WoW API `GetObjectType()` then its type will be visible in value column
* Strings in value column have no line brakes


### TODO list:

ViragDevTool is in beta (probably even early alpha) so there is lots of stuff to add and tune.

1. Create dynamic text and color size chooser (probably not everyone likes SystemFont_Small)
2. Create edittext field so we can call functions with args
3. Add filters by object name and type
4. Add Events tracking
5. Add object deep copy option
6. Add predefined buttons for every WoW API (just like _G)
7. Add close frame button and /slash cmd
8. Add row delimiters so we can resize tows in table
9. Add function args info and description from from mapping file

### How to contribute
For now this addon will be updated only when i need certain feature in my other addon development

Prefered option is to use Github issue tracker if you have some todos, bugs, feature requests, and more. 
https://github.com/varren/ViragDevTool/issues

Can also use Curse comments board
http://mods.curse.com/addons/wow/varrendevtool


> Inspired by Rover addon from Wildstar 
> http://mods.curse.com/ws-addons/wildstar/220043-rover

[demo]: http://legacy.curseforge.com/media/images/89/812/1844ef88f22d780658b2150f0cc20c19.png "Logo Title Text 2"
[GDemo]: http://i.gyazo.com/e0287b175965c790b229e4b99418203d.png