package comtacti.plugins;

/**
 * ...
 * @author Waneck
 */

enum HookErrors
{
	HAssert(msg:String);
	HookNotAvailable(clsName:String, method:String);
}