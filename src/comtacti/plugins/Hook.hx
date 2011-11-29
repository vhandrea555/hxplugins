package comtacti.plugins;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import macrotools.MacroTools;

#end
/**
 * ...
 * @author Waneck
 */

class Hook 
{
#if macro
	
	//private static var hooksToBeAdded:Hash<Hash<Array<{expr:Expr}>>> = new Hash();
	
#end
	
	/**
	 * Usage:
		 * Hook.addHook(path.to.Class, "method", function(self:path.to.Class, real, func, args):Option<ReturnValue>):Void
		 * Hook.addHook(path.to.Class, "method", path.to.function):Void;
	 * Adds a hook
	 * 
	 * @param	hookClass
	 * @param	methodName
	 * @param	method
	 * @return
	 */
	@:macro public static function addHook(hookClass:ExprRequire<Class<Dynamic>>, methodName:ExprRequire<String>, method:Expr):Expr
	{
		/*var clsName = MacroTools.getPath(hookClass).join(".");
		var methodName = MacroTools.getString(methodName, false, true);
		
		var meths = hooksToBeAdded.get(clsName);
		if (meths == null)
		{
			meths = new Hash();
			hooksToBeAdded.set(clsName, meths);
		}
		
		var meth = meths.get(methodName);
		if (meth == null)
		{
			meth = [];
			meths.set(methodName, meth);
		}
		
		meth.push( { expr:  } );*/
		
		//get method signature
		var clsName = MacroTools.getPath(hookClass).join(".");
		var methodName = MacroTools.getString(methodName, false, true);
		
		var cls = Context.getType(clsName);
		if (cls == null)
			throw new Error("Class not found", hookClass.pos);
		
		var meth = switch(Context.follow(cls))
		{
			case TInst(cl, params):
				var cl = cl.get();
				var found = null;
				for (f in cl.fields.get())
				{
					if (f.name == methodName)
					{
						found = f;
						break;
					}
				}
				if (found == null)
				{
					for (f in cl.statics.get())
					{
						if (f.name == methodName)
						{
							found = f;
							break;
						}
					}
				}
				
				found;
			default: throw new Error("Hooks only work with classes", hookClass.pos);
		};
		
		if (meth == null)
			throw new Error("Method not found: " + methodName, method.pos);
		
		
		//ensure that method follows signature needed
		
	}
	
}