package plugins;
import comtacti.plugins.Hook;
import comtacti.plugins.Hookable;
import utest.Assert;

using Lambda;

/**
 * ...
 * @author Waneck
 */

class HookFilterTests 
{
	private var filterTest:FilterTest;
	
	public function new() 
	{
		
	}
	
	public function setup()
	{
		filterTest = new FilterTest();
	}
	
	public function test_Hook_Filter()
	{
		Assert.same([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], filterTest.oneToTen(true));
		Hook.addHook(FilterTest, "oneToTen", tFilterEven);
		Hook.addHook(FilterTest, "oneToTen", tFilterFive);
		Hook.addHook(FilterTest, "oneToTen", tAddIfArgument);
		
		Assert.same([1, 3, 7, 9, 100], filterTest.oneToTen(true));
	}
	
	private function tFilterEven(me:FilterTest, acc:Array<Int>, anArgument:Bool):Array<Int>
	{
		return acc.filter(function(i) return i % 2 != 0).array();
	}
	
	private function tFilterFive(me:FilterTest, acc:Array<Int>, anArgument:Bool):Array<Int>
	{
		return acc.filter(function(i) return i != 5).array();
	}
	
	private function tAddIfArgument(me:FilterTest, acc:Array<Int>, anArgument:Bool):Array<Int>
	{
		if (anArgument) acc.push(100);
		return acc;
	}
}

/**
 * Filters will always texecute the function first, and will receive functions of type self->ReturnType->args->ReturnType,
 * which will filter the initial result
 */
class FilterTest implements Hookable
{
	public function new()
	{
		
	}
	
	@:hookableFilter public function oneToTen(anArgument:Bool):Array<Int>
	{
		return Lambda.array({ iterator: function () return 1...11 } );
	}
	
}