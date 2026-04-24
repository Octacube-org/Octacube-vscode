package octacube.vscode;

class BaseNode
{
	var core:Core;

	public function new(core:Core)
	{
		this.core = core;
		create();
	}

	function create() {}
}
