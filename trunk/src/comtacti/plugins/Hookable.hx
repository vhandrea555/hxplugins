package comtacti.plugins;

/**
 * ...
 * @author Waneck
 */

#if (!macro && !RUNTIME_HOOK)

@:autoBuild(comtacti.plugins.internal.Build.build(#if RUNTIME_HOOK true #else false #end))
#end

interface Hookable #if RUNTIME_HOOK implements HookableAtRuntime #end
{
/*
	static function hook<T>(field:String, func:T);
*/
}