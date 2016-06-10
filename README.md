# ViragDevTool Info

> Looking for Legion Beta to test and update this addon

ViragDevTool is Lua World of Warcraft addon for addon-developers. 
Functionality is similar to a debugger. 

This addon can help new developers to understand WoW API.
Main idea is to examine WoW API or your addon's variables in table-like UI. 
Much easier to use then default print or chat debug

**[Curse download page](http://mods.curse.com/addons/wow/varrendevtool)** 

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

#### Here is how i use ViragDevTool_AddData:
```lua
--define print fn so we can easily turn it off 
function MyOtherAddon_Print(strName, tData) 
    if ViragDevTool_AddData and MyOtherAddon.kbDEBUG then 
        ViragDevTool_AddData(tData, strName) 
    end
end

-- use this function all over my code instead of print
MyOtherAddon_Print("MyOtherAddon", MyOtherAddon) -- sends object to UI
```
### How to use sidebar:
There are 3 tabs in sidebar and text field has different behavior in each tab.

* **In \vdt history tab** it is just easy way to call `/vdt ...` for example you can print `find Virag` and it is the same as printing `/vdt find Virag` in chat

* **In Events tab** textfield can only use `eventname` or `eventname unit` and this is the same as `/vdt eventadd eventname` or `/vdt eventadd unit` where eventname is Blizzard API event(http://wowwiki.wikia.com/wiki/Events_A-Z_(Full_List)) string name 
For example: `UNIT_AURA player` in textbox is the same as `/vdt eventadd UNIT_AURA player` in chat
```lua
if unit then f:RegisterUnitEvent(event, unit)
else f:RegisterEvent(event) end
```
![ViragDevTool events demo][eventsDemo]

* **In Fn Call Log** tab you can type `tableName functionName` into textfield and it will try to find `_G.tableName.functionName` and if this field is a function it will be replaced with logger function like this:
```lua
tParent[fnName] = function(...)
   ViragDevTool:Add({ ... }) -- will add args to the list
   local result = { savedOldFn(...) }
   ViragDevTool:Add(result) -- will add return value to the list
   return unpack(result)
end
```
![ViragDevTool logger demo][loggerDemo]

### /CMD

* **/vdt - toggle ui**
* **/vdt help - for everything else**

### Other functionality
* **Clicking on table name** will expand and show its children
* **Clicking on function name** will try to call the function. **WARNING BE CAREFUL**
* If table has WoW API `GetObjectType()` then its type will be visible in value column
* Can monitor WoW API events
* Can log function calls:  their input args and return values

* Note: Strings in value column have no line brakes

### TODO list:

ViragDevTool is in beta (probably even early alpha) so there is lots of stuff to add and tune.

1. Create dynamic text and color size chooser (probably not everyone likes SystemFont_Small)
2. Create edit text ui so we can call functions with args
3. Add filters by object name and type
4. Add object deep copy option
5. Add predefined buttons for every WoW API (just like _G)
6. Add row delimiters so we can resize rows in table
7. Add function args info and description from mapping file

### How to contribute
For now this addon will be updated only when i need certain feature in my other addon's development

Preferred option is to use Github issue tracker if you have some todos, bugs, feature requests, and more. 
https://github.com/varren/ViragDevTool/issues

Can also use Curse comments board
http://mods.curse.com/addons/wow/varrendevtool

> Inspired by Rover addon from Wildstar 
> http://mods.curse.com/ws-addons/wildstar/220043-rover

[demo]: http://legacy.curseforge.com/media/images/89/812/1844ef88f22d780658b2150f0cc20c19.png "Logo Title Text 2"
[GDemo]: http://i.gyazo.com/e0287b175965c790b229e4b99418203d.png
[eventsDemo]: https://i.gyazo.com/1093752a1a066e7143b8cfcf1926d8da.png
[loggerDemo]: https://i.gyazo.com/ea97b93c56ee95d20a88f5ec154df5ca.png