package plugins;
import comtacti.plugins.Hook;
import comtacti.plugins.Hookable;
import comtacti.types.Option;
import comtacti.types.Option;
import utest.Assert;

/**
 * ...
 * @author Waneck
 */

class HookTests 
{
	private var tOne:TestOne;
	
	public function new() 
	{
		
	}
	
	public function setup()
	{
		tOne = new TestOne();
		/*
		Hook.addHook(TestOne, "testReturn", tReturn3, 100);
		Hook.addHook(TestOne, "testReturn", tReturn1, 1000);
		Hook.addHook(TestOne, "testReturn", tReturn2, -200);*/
	}
	
	public function test_Void_Interception()
	{
		TestOne.test = false;
		tOne.testVoid();
		Assert.isTrue(TestOne.test);
		
		Hook.addHook(TestOne, "testVoid", tVoid);
		TestOne.test = false;
		tOne.testVoid();
		Assert.isFalse(TestOne.test);
		
		Assert.isTrue(Hook.removeHook(TestOne, "testVoid", tVoid));
		TestOne.test = false;
		tOne.testVoid();
		Assert.isTrue(TestOne.test);
	}
	
	public function test_Static_Interception()
	{
		Assert.equals("Hello, World!", TestOne.testStatic());
		Hook.addHook(TestOne, "testStatic", tStatic);
		Assert.equals("Changed message", TestOne.testStatic());
		Hook.removeHook(TestOne, "testStatic", tStatic);
		Assert.equals("Hello, World!", TestOne.testStatic());
	}
	
	public function test_Priorities()
	{
		Assert.equals("Hello, World!", tOne.testReturn());
		Hook.addHook(TestOne, "testReturn", tReturn1, 100);
		Hook.addHook(TestOne, "testReturn", tReturn3, 1000);
		Hook.addHook(TestOne, "testReturn", tReturn2, -200);
		Assert.equals("Changed Highest Priority", tOne.testReturn());
	}
	
	public function test_Unchanged_HookResults()
	{
		Assert.equals("default value other", tOne.testHookResults(""));
		Hook.addHook(TestOne, "testHookResults", tHookResults, 1000);
		Hook.addHook(TestOne, "testHookResults", tHookResults2, -1000);
		Assert.equals("a Tampered message other", tOne.testHookResults("a "));
		Assert.isTrue(tOne.called);
	}
	
	public function test_Map()
	{
		Assert.equals(10, tOne.testMap());
		Hook.addHook(TestOne, "testMap", tMap);
		Hook.addHook(TestOne, "testMap", tMap);
		Hook.addHook(TestOne, "testMap", tMap);
		Assert.equals(12, tOne.testMap());
	}
	
	private function tVoid(me:TestOne)
	{
		TestOne.test = false;
		return Some(null);
	}
	
	private function tStatic()
	{
		return Some("Changed message");
	}
	
	private function tReturn1(me:TestOne)
	{
		return Some("Changed message");
	}
	
	private function tReturn2(me:TestOne)
	{
		return Some("Changed message2");
	}
	
	private function tReturn3(me:TestOne)
	{
		return Some("Changed Highest Priority");
	}
	
	private function tHookResults(me:TestOne, a:String)
	{
		me.called = true;
		return None;
	}
	
	private function tHookResults2(me:TestOne, a:String)
	{
		return Some(a + "Tampered message");
	}
	
	private function tMap(me:TestOne, acc:Option<Int>)
	{
		return switch(acc)
		{
			case None: Some(0);
			case Some(i): Some(i + 1);
		}
	}
	
	public function teardown()
	{
		
	}
	
}

class TestOne implements Hookable
{
	public static var test = false;
	
	public var called:Bool;
	
	public function new()
	{
		
	}
	
	@:hookable public static function testStatic():String
	{
		return "Hello, World!";
	}
	
	//in this default behavior, all hooks will be executed automatically,
	//and the first that returns Some() will halt execution and the value will be returned
	@:hookable public function testVoid():Void
	{
		test = true;
	}
	
	@:hookable public function testReturn():String
	{
		return "Hello, World!";
	}
	
	//when Hook.getHookResults() is manually called, all hooks will still be executed
	//automatically, but the first that returns Some() will send its results to Hook.getHookResults()
	//and then you can handle with the hook results yourself (Make checks/validity, etc)
	@:hookable public function testHookResults(a:String):String
	{
		var lastRet:Option<String> = Hook.getHookResults();
		var ret = switch(lastRet)
		{
			case None: "default value";
			case Some(s): s;
		};
		
		return ret + " other";
	}
	
	//hookableMap will change the needed function signature, so an Option<ReturnType> is also added
	//to the function signature. This way all hooks are always executed, and the accumulated result will 
	//be sent as a parameter for each hook.
	//Note that Hook.getHookResults() is required here, because if not there wouldn't be a way to get the
	//hook results
	@:hookableMap public function testMap():Int
	{
		var lastRet:Option<Int> = Hook.getHookResults();
		var ret = switch(lastRet)
		{
			case None: 0;
			case Some(b): b;
		}
		return ret + 10;
	}
}