# ViragDevTool Info

ViragDevTool is Lua World of Warcraft addon for addon-developers. 
The core functionality is similar to a debugger, and can be instrumental is visualizing tables, events, and function calls. 

This addon can help new developers to understand WoW API.
The main idea is to examine WoW API or your addon's variables in a table-like UI, which is much easier to use then default print() or chat debugging.


## How To Use

The main (and the only) function you can use is **AddData(data, "some string name")**:

```lua
--- Adds data to ViragDevTool UI list to monitor
-- @param data (any type)- is object you would like to track. 
-- Default behavior is reference and not object copy
-- @param dataName (string or nil) - name tag to show in UI for you variable. 
-- Main purpose is to give readable names to objects you want to track.
function ViragDevTool:AddData(data, dataName) 
  ...
end
```

Let's suppose you have `MyModFN` function in your addon.
```lua
function MyModFN()
  local var = {}
  ... some code here 
  ViragDevTool:AddData(var, "My local var in MyModFN")
end
```
This code will add `var` as a new row in the ViragDevTool UI `HybridScrollFrameTemplate` list.

For example:
```lua
ViragDevTool:AddData(_G, "_G")
```


### Here is an example of how I use ViragDevTool:AddData()
```lua
--I define a print function so we can easily turn it off 
function MyOtherAddon_Print(strName, tData) 
  if ViragDevTool.AddData and MyOtherAddon.kbDEBUG then 
    ViragDevTool:AddData(tData, strName) 
  end
end

-- I use this function all over my code instead of print
MyOtherAddon_Print("MyOtherAddon", MyOtherAddon) --sends object to UI
```
### How to use sidebar:
There are 3 tabs in sidebar and text field has different behavior in each tab.

* **History tab:** is just an easy way to call `/vdt ...` for example you can print `find Virag` and it is the same as printing `/vdt find Virag` in chat
* **Events tab:** text field can only use `eventname` or `eventname unit` and this is the same as `/vdt eventadd eventname` or `/vdt eventadd unit` where `eventname` is a [Blizzard API event](https://wowpedia.fandom.com/wiki/Events) string name 
  * For example: `UNIT_AURA player` in the text box is the same as `/vdt eventadd UNIT_AURA player` in chat
* **Fn Call Log tab:** you can type `tableName functionName` into the text field, and it will try to find `_G.tableName.functionName`, and if this field is a function it will be replaced with logger function like this:

```lua
tParent[fnName] = function(...)
   ViragDevTool:Add({ ... }) -- will add args to the list
   local result = { savedOldFn(...) }
   ViragDevTool:Add(result) -- will add return value to the list
   return unpack(result)
end
```

### How to use function arguments:
You can specify coma separated arguments that will be passed to the function. Can be string, number, nil, true/false, and table. 
To pass table you have to specify prefix `t=`. Let's suppose I want to pass ViragDevToolFrame as a argument, then the string has to be `t=ViragDevToolFrame`

* Demo1: FN Call Args: `t=Frame, 12, a12` => someFunction(_G.Frame (table) , 12 (number), a12 (string))
* Demo2: FN Call Args: `t=Frame.Frame2.Frame3` => someFunction(_G.Frame.Frame2.Frame3 (table))

### /CMD

* **/vdt** - toggles the main UI window
* **/vdt help** - Lists help actions in the chat window

### Other functionality
* **Clicking on table name** will expand and show its children
* **Clicking on function name** will try to call the function. **WARNING: BE CAREFUL**
* If table has WoW API `GetObjectType()` then its type will be visible in value column
* Can monitor WoW API events
* Can log function calls, their input args, and return values

    * **Note: Strings in the 'value' column have no line breaks**