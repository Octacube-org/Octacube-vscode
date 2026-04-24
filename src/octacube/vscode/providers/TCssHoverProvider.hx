package octacube.vscode.providers;

import vscode.MarkdownString;
import vscode.Position;
import vscode.TextDocument;
import vscode.ProviderResult;
import vscode.CancellationToken;
import vscode.Hover;

class TCssHoverProvider extends TCssNode
{
	override function create()
	{
		core.context.subscriptions.push(Vscode.languages.registerHoverProvider({language: "tcss"}, this));
	}

	public function provideHover(document:TextDocument, position:Position, token:CancellationToken):ProviderResult<Hover>
	{
		final offset = document.offsetAt(position);

		final text:String = service.getHover(
			{
				uri: document.uri.fsPath,
				content: document.getText()
			}, offset);

		if (text != null)
			return new Hover(new MarkdownString(text));

		return null;
	}
}
