package octacube.vscode;

import vscode.OutputChannel;

class Log extends BaseNode
{
	var logger:OutputChannel;

	override function create()
	{
		logger = Vscode.window.createOutputChannel('Octacube');
	}

	public function log(info:String)
	{
		logger.appendLine('[INFO]: ' + info);
	}

	public function error(error:String)
	{
		logger.appendLine('[ERROR]: ' + error);
	}
}
