package octacube.vscode.providers;

import vscode.CancellationToken;
import vscode.Event;
import vscode.EventEmitter;
import vscode.ProviderResult;
import vscode.Uri;
import vscode.ViewColumn;

using Lambda;

class TCssPreviewProvider extends TCssNode
{
	public static final scheme = "tcss-preview";

	public var onDidChange:Event<Uri>;

	var _onDidChange:EventEmitter<Uri>;

	override function create()
	{
		this._onDidChange = new EventEmitter<Uri>();
		this.onDidChange = _onDidChange.event;

		core.context.subscriptions.push(Vscode.workspace.registerTextDocumentContentProvider(TCssPreviewProvider.scheme, this));
		core.context.subscriptions.push(Vscode.commands.registerCommand("tcss.showPreview", showPreview));
	}

	function showPreview(?uri:Uri)
	{
		if (uri == null)
		{
			final editor = Vscode.window.activeTextEditor;
			if (editor != null)
				uri = editor.document.uri;
		}

		if (uri == null)
			return;

		Vscode.workspace.openTextDocument(uri.with({scheme: scheme})).then((doc) ->
		{
			Vscode.languages.setTextDocumentLanguage(doc, "css");
			Vscode.window.showTextDocument(doc, ViewColumn.Beside, true);
		});
	}

	public function provideTextDocumentContent(uri:Uri, token:CancellationToken):ProviderResult<String>
	{
		final doc = Vscode.workspace.textDocuments.find(d -> d.uri.fsPath == uri.fsPath);

		if (doc == null)
		{
			return "/* Error: Source document not found. Try to focus the original file. * /";
		}

		return try
		{
			core.tcssService.generateCss({uri: doc.uri.fsPath, content: doc.getText()});
		} catch (e:haxe.Exception)
		{
			"/* TСSS Generation Error:\n" + e.message + "\n* /";
		}
	}

	public function update(uri:Uri)
	{
		_onDidChange.fire(uri);
	}
}
