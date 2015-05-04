Provides a simple interface to make event hooks so plugins can interact with existing code.

It provides three basic types of interaction hooks:
  * @:hookable : the basic kind, it will execute all added hooks in order of priority until the first that returns an actual value (Some()). If no hook returns an actual value, the original function code is called:
```
var ret:Option<ReturnValue> = None;
while(isNone(ret) && hasNextHookFunction())
{
	ret = nextHookFunction(farg1,farg2,...);
}
```
  * @:hookableMap : it will execute all added hooks in order of priority, and will receive an accumulated `Option<FunctionReturnType>` as additional argument:
```
var ret:Option<ReturnValue> = None;
while(hasNextHookFunction())
{
	ret = nextHookFunction(farg1,farg2,...,ret);
}
```
  * @:hookableFilter : it will first execute the original function. All hook functions will then filter the function result:
```
var ret:ReturnValue = originalFunction();
for (hookFunc in hooks)
{
	ret = hookFunc(farg1,farg2,...,ret);
}
```

Also inside hookable and hookableMap functions, a special construct "Hook.getHookResults()" can be used to extract values from the hook functions and then work with them. The default behavior if this call isn't used is that if the hook function return an actual value, the original content won't execute.

Adding a common plugin interface for all haxe targets is a planned feature.