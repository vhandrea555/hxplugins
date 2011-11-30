package comtacti.plugins.internal;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import macrotools.MacroTools;
import macrotools.Map;
import macrotools.Print;
using Lambda;
#end

/**
 * ...
 * @author Waneck
 */

class Build 
{	
	private static function changeExpr(e:Expr, to:Position->Expr):{changed:Bool, retExpr:Expr}
	{
		var changed = false;
		function map(e:Expr)
		{
			switch(e.expr)
			{
				case ECall(ecall, params):
					var path = MacroTools.getPath(ecall);
					var p1 = path.pop();
					var p2 = path.pop();
					if (params.length == 0 && p2 == "Hook" && p1 == "getHookResults")
					{
						changed = true;
						return to(e.pos);
					} else {
						return Map.mapExpr(map, e);
					}
				default:
					return Map.mapExpr(map, e);
			}
		}
		
		var ret = Map.mapExpr(map, e);
		return {changed:changed, retExpr:ret};
	}
	
	//then inspect into each of these functions, replacing Hook.getHookResults() with
	/*
	
	{
		var hooks = methodName__hooks__;
		var ret = None;
		for (h in hooks)
		{
			switch(ret = h.func(this, other, arguments))
			{
				case None:
				case Some(s):
					break; //or continue
			}
		}
		
		ret;
	}*/
	private static function getHookCallExpr(hooksName:String, actionForSome:String, functionCall:String, pos:Position):Expr
	{
		return Context.parse('
		{
			var hooks = ' + hooksName + ';
			var __last_ret = None;
			for (hook in hooks)
			{
				switch(__last_ret = ' + functionCall + ')
				{
					case None:
					case Some(s):' + actionForSome + '
				}
			}
			
			__last_ret;
		}', pos);
	}
	
	public static function build():Array<Field>
	{
		//first get all methods that have @:hookable or @:hookableMap as metadata
		
		var retFields = [];
		var cls = Context.getLocalClass();
		var clsName = cls.toString();
		var cls = cls.get();
		
		for (field in Context.getBuildFields())
		{
			var isHook = false;
			var isMap = false;
			
			for (meta in field.meta)
			{
				switch(meta.name)
				{
					case ":hookable": isHook = true;
					case ":hookableMap": isMap = true;
				}
			}
			
			
			
			var expr = null;
			var hooksVar = field.name + "__hooks__";
			
			if (isMap || isHook)
			{
				retFields.push(
				{
					pos:field.pos,
					name:hooksVar,
					meta:[],
					kind:FVar(null, { expr:EArrayDecl([]), pos:field.pos } ),
					doc:null,
					access:[AStatic]
				});
				
				switch(field.kind)
				{
					case FFun(func):
						var args = (field.access.has(AStatic)) ? [] : ["this"];
						
						if (isMap)
						{
							args.push("__last_ret");
						}
						
						for (arg in func.args)
						{
							args.push( arg.name );
						}
						
						var isVoid = if (func.ret != null) switch(func.ret)
						{
							case TPath(p): p.name == "Void" && p.pack.length == 0;
							default: false;
						} else false;
						
						if (field.name == "new") isVoid = true;
						
						var functionCall = "hook.func(" + args.join(",") + ")";
						
						var actionForSome =
							if (isMap) "" else "break;";
						
						var changeExprRet = changeExpr(func.expr, function(pos) return getHookCallExpr(hooksVar, actionForSome, functionCall, pos));
						
						var expr = if (!changeExprRet.changed)
						{
							expr:EBlock([getHookCallExpr(hooksVar, (isVoid) ? "return;" : "return s;", functionCall, field.pos), changeExprRet.retExpr]),
							pos:field.pos
						} else {
							changeExprRet.retExpr;
						}
						
						func.expr = expr;
						
					default: throw new Error("A variable cannot be hookable. Only function can be hookable", field.pos);
				}
				
			}
			retFields.push(field);
		}
		
		
		//if there is no Hook.getHookResults(), add this as the first expression of the function
		
		return retFields;
	}
	
}