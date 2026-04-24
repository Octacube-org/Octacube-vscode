import octacube.vscode.Core;

class Main
{
	@:expose("activate")
	static function activate(context:vscode.ExtensionContext)
	{
		Core.start(context);
	}
}
