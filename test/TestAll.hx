package ;
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
		
		var report = Report.create(runner);
		runner.run();
	}
	
}