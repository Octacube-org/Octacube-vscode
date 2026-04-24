package octacube.vscode;

import octacube.vscode.tcss.TCssService;

class TCssNode extends BaseNode
{
	public var service:TCssService;

	public function new(service:TCssService)
	{
		this.service = service;
		super(service.core);
	}
}
