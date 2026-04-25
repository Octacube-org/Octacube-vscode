package octacube.vscode.util;

import js.node.ChildProcess;

class HaxelibTools
{
	public static function isHaxelibInstalled():Bool
	{
		return try
		{
			ChildProcess.execSync('haxelib version');

			true;
		} catch (e:Dynamic)
		{
			false;
		}
	}

	public static function getLibPath(libName:String):String
	{
		try
		{
			final output:String = Std.string(ChildProcess.execSync('haxelib libpath $libName'));

			return StringTools.trim(output);
		} catch (e:Dynamic) {}

		return null;
	}

	public static function installLib():Bool
	{
		return try
		{
			ChildProcess.execSync('haxelib git octa-tcss https://github.com/Octacube-org/Octa-tcss.git');

			true;
		} catch (e:Dynamic)
		{
			false;
		}
	}
}
