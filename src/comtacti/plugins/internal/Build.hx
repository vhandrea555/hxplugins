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
					var path = MacroTools.getPath(ecall, false);
					if (path == null)
						return Map.mapExpr(map, e);
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
	
	private static function getHookFilterExpr(hooksName:String, functionCall:String, pos:Position):Expr
	{
		return Context.parse('
		{
			var __hooks = ' + hooksName + ';
			for (__hook in __hooks)
			{
				__last_ret = ' + functionCall + ';
			}
			
			__last_ret;
		}', pos);
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
			var __hooks = ' + hooksName + ';
			var __last_ret = comtacti.types.Option.None;
			for (__hook in __hooks)
			{
				switch(__last_ret = ' + functionCall + ')
				{
					case comtacti.types.Option.None:
					case comtacti.types.Option.Some(s):' + actionForSome + '
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
			var isFilter = false;
			
			for (meta in field.meta)
			{
				switch(meta.name)
				{
					case ":hookable": isHook = true;
					case ":hookableMap": isMap = true;
					case ":hookableFilter": isFilter = true;
				}
			}
			
			
			
			var expr = null;
			var hooksVar = field.name + "__hooks__";
			
			if (isMap || isHook || isFilter)
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
						
						if (isMap || isFilter)
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
						
						var functionCall = "__hook.func(" + args.join(",") + ")";
						
						var actionForSome =
							if (isMap) "" else "break;";
						
						if (!isFilter)
						{
							var changeExprRet = changeExpr(func.expr, function(pos) return getHookCallExpr(hooksVar, actionForSome, functionCall, pos));
						
							var expr = if (!changeExprRet.changed)
							{
								expr:EBlock([getHookCallExpr(hooksVar, (isVoid) ? "return;" : "return s;", functionCall, field.pos), changeExprRet.retExpr]),
								pos:field.pos
							} else {
								changeExprRet.retExpr;
							}
							
							func.expr = expr;
						} else {
							//var __last_ret = function() { func contents }();
							//return {getHookFilterExpr(hooksVar, functionCall, pos)}
							var pos = field.pos;
							var block = [];
							block.push( {
								expr: EVars([ {
									type:func.ret,
									name:"__last_ret",
									expr:
									{
										expr: ECall( 
										{
											expr:EFunction(null, { ret:func.ret, params:func.params, expr:func.expr, args:[] } ),
											pos:pos
										}, []),
										pos:pos
									}
								}]),
								pos:pos
							});
							
							block.push( { 
								expr:EReturn(getHookFilterExpr(hooksVar, functionCall, pos)),
								pos:pos
							} );
							
							func.expr = { expr:EBlock(block), pos:pos };
						}
						
						
					default: throw new Error("A variable cannot be hookable. Only function can be hookable", field.pos);
				}
				
			}
			retFields.push(field);
		}
		
		
		//if there is no Hook.getHookResults(), add this as the first expression of the function
		
		return retFields;
	}
	
}