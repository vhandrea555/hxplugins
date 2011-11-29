package comtacti.types;

/**
 * ...
 * @author Waneck
 */

#if stax
typedef Option<T> = haxe.Prelude.Option<T>;
#else
enum Option<T>
{
	None;
	Some(val:T);
}
#end