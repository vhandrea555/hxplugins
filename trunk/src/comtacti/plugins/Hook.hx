package comtacti.plugins;

private typedef StdType = Type;
import comtacti.plugins.Errors;
#if display
import comtacti.types.Option;

#end
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import macrotools.MacroTools;
import macrotools.Print;
import macrotools.TypeTools;

#end
/**
 * ...
 * @author Waneck
 */

class Hook 
{	
#if display
	/**
	 * This is a special construct that should be only used inside a hookable function.
	 * It doesn't really exist, so if you're having compilation errors you've probably 
	 * forgotten to add the @:hookable / @:hookableMap metadata or to have the current class
	 * implement Hookable
	 * 
	 * @return An Option<CurrentFunctionReturnType>
	 */

	public static function getHookResults():Option<Dynamic>
	{
		return None;
	}
#end
	
#if (macro && !display)
	private static function checkHook(hookClass:Expr, methodNameExpr:Expr, method:Expr):Array<Expr>
	{
		var pos = Context.currentPos();
		//get method signature
		var clsName = MacroTools.getPath(hookClass).join(".");
		var methodName = MacroTools.getString(methodNameExpr, false, true);
		
		var cls = Context.getType(clsName);
		if (cls == null)
			throw new Error("Class not found", hookClass.pos);
		
		var isStatic = false;
		var meth = 
		{
			var found = null;
			var cls = cls;
			while (found == null && cls != null)
			{
				switch(Context.follow(cls))
				{
					case TInst(cl, _):
						var cl = cl.get();
						
						if (methodName == "new")
						{
							found = (cl.constructor == null) ? null : cl.constructor.get();
						}
						
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
									isStatic = true;
									found = f;
									break;
								}
							}
						}
						
						cls = (cl.superClass != null) ? TInst(cl.superClass.t, null) : null;
						
					default: throw new Error("Hooks only work with classes", hookClass.pos);
				}
				
				
			}
			
			found;
		};
		
		if (meth == null)
			throw new Error("Method not found: " + methodName, method.pos);
			
		var isMap = meth.meta.has(":hookableMap");
		if (! (meth.meta.has(":hookable") || isMap) )
		 throw new Error("Method is not hookable: " + methodName, methodNameExpr.pos);
		
		//begin ensure that method follows signature needed
		var block = [];
		
		//we need to get a ComplexType of the haxe.macro.Type 
		var curSig = meth.type;
		var ctypeSig = TypeTools.toString(curSig);
		var ctype = TypeTools.getComplexType(ctypeSig);
		
		//get the method signature needed
		var neededType = switch(ctype)
		{
			case TFunction(args, ret):
				//check if first argument is Void type
				if (args.length == 1 && !isStatic)
				{
					switch(args[0])
					{
						case TPath(p):
							if (p.name == "Void" && p.pack.length == 0)
							{
								args.shift();
							}
						default:
					}
				}
				
				//add Option<> to the return type
				ret = TPath( {
					sub:null,
					params:[TPType(ret)],
					name:"Option",
					pack:["comtacti", "types"]
				});
				
				//add acc as first argument
				if (isMap)
				{
					args.unshift(ret);
				}
				
				//add a "me" as first argument
				if (!isStatic)
				{
					var clsPath = clsName.split(".");
					args.unshift(TPath(
					{
						sub:null,
						params:[],
						name:clsPath.pop(),
						pack:clsPath
					}));
				}
				
				TFunction(args, ret);
			default: throw new Error("Expected a function type", method.pos);
		};
		
		//ensure that type is of needed type
		//by making var method:MethodType = methodVarSent;
		//and then calling Hook.unsafeAdd(ClassName, "methodName", method)
		
		block.push( {
			expr:EVars([ { type:neededType, name:"method", expr:method } ]),
			pos:method.pos
		});
		
		return block;
	}
#end
	
	/**
	 * Usage:
		 * Hook.addHook(path.to.Class, "method", function(self:path.to.Class, real, func, args):Option<ReturnValue>, priority):Void
	 * Adds a hook
	 * 
	 * @param	hookClass
	 * @param	methodName
	 * @param	method
	 * @return
	 */
	@:macro public static function addHook(
#if display
	arr:Array<Expr>
#else
	hookClass:ExprRequire<Class<Dynamic>>, methodNameExpr:ExprRequire<String>, method:Expr, ?priority:ExprRequire<Int>
#end
	):Expr
	{
#if display
		return MacroTools.mkCall(["comtacti", "plugins", "Hook", "unsafeAdd"], arr, Context.currentPos());
#else
		var pos = Context.currentPos();
		var block = checkHook(hookClass, methodNameExpr, method);
		block.push(
			MacroTools.mkCall(["comtacti", "plugins", "Hook", "unsafeAdd"], [hookClass, methodNameExpr, {expr:EConst(CIdent("method")), pos:method.pos}, priority], pos)
		);
		
		return { expr:EBlock(block), pos:pos };
#end
	}
	
	public static function unsafeAdd(cls:Class<Dynamic>, methodName:String, method:Dynamic, ?priority=0):Void
	{
		if (method == null) throw HAssert("Null method");
		
		var hooks:Array<{priority:Int, func:Dynamic}> = Reflect.field(cls, methodName + "__hooks__");
		if (hooks == null || !Std.is(hooks, Array))
		{
			throw HookNotAvailable(StdType.getClassName(cls), methodName);
		}
		
		//hooks.push( { priority:priority, func:method } );
		
		for (i in 0...hooks.length)
		{
			var h = hooks[i];
			if (h.priority < priority)
			{
				hooks.insert(i, { priority:priority, func:method } );
				return;
			}
		}
		
		hooks.push( { priority:priority, func:method } );
	}
	
	public static function unsafeRemove(cls:Class<Dynamic>, methodName:String, method:Dynamic):Bool
	{
		if (method == null) throw HAssert("Null method");
		
		var hooks:Array<{priority:Int, func:Dynamic}> = Reflect.field(cls, methodName + "__hooks__");
		if (hooks == null || !Std.is(hooks, Array))
		{
			throw HookNotAvailable(StdType.getClassName(cls), methodName);
		}
		
		var i = 0;
		var found = false;
		for (hook in hooks)
		{
			if (Reflect.compareMethods(hook.func, method))
			{
				found = true;
				break;
			}
			i++;
		}
		
		if (!found) return false;
		
		hooks.splice(i, 1);
		return true;
	}
	
	/**
	 * Usage:
		 * Hook.removeHook(path.to.Class, "method", function(self:path.to.Class, real, func, args):Option<ReturnValue>):Void
	 * Adds a hook
	 * 
	 * @param	hookClass
	 * @param	methodName
	 * @param	method
	 * @return
	 */
	@:macro public static function removeHook(
#if display
	arr:Array<Expr>
#else
	hookClass:ExprRequire<Class<Dynamic>>, methodNameExpr:ExprRequire<String>, method:Expr
#end
	):Expr
	{
#if display
		return MacroTools.mkCall(["comtacti", "plugins", "Hook", "unsafeRemove"], arr, Context.currentPos());
#else
		var pos = Context.currentPos();
		var block = checkHook(hookClass, methodNameExpr, method);
		block.push(
			MacroTools.mkCall(["comtacti", "plugins", "Hook", "unsafeRemove"], [hookClass, methodNameExpr, {expr:EConst(CIdent("method")), pos:method.pos}], pos)
		);
		
		return { expr:EBlock(block), pos:pos };
#end
	}
}