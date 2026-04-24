package octacube.vscode;

import haxe.Timer;
import octacube.vscode.providers.TCssPreviewProvider;
import octacube.vscode.tcss.TCssService;
import vscode.ExtensionContext;
import vscode.TextDocumentChangeEvent;

class Core
{
	public final tcssService:TCssService;
	public final context:ExtensionContext;
	public final log:Log;

	public function new(context:ExtensionContext)
	{
		this.context = context;

		log = new Log(this);

		tcssService = new TCssService(this);

		Vscode.workspace.onDidChangeTextDocument(update);
	}

	var timer:Timer = null;

	function update(event:TextDocumentChangeEvent)
	{
		if (event.document.languageId != "tcss")
			return;

		if (timer != null)
		{
			timer.stop();
			timer = null;
		}

		timer = Timer.delay(() ->
		{
			tcssService.updateSema(event.document);

			final previewUri = event.document.uri.with({scheme: TCssPreviewProvider.scheme});
			tcssService.previewProvider.update(previewUri);

			timer = null;
		}, 500);
	}

	public static function start(context:ExtensionContext)
	{
		new Core(context);
	}
}
