package ;
import plugins.HookFilterTests;
import plugins.HookTests;
import utest.ui.Report;

/**
 * ...
 * @author Waneck
 */

class TestAll 
{

	static function main() 
	{
		var runner = new utest.Runner();

		runner.addCase(new HookTests());
		runner.addCase(new HookFilterTests());
		
		var report = Report.create(runner);
		runner.run();
	}
	
}