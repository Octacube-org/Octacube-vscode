package octacube.vscode.providers;

import octacube.vscode.tcss.Api.Pos;
import vscode.TextDocument;
import vscode.Position;
import vscode.CancellationToken;
import vscode.Location;
import vscode.Uri;
import vscode.Range;

class TCssDefinitionProvider extends TCssNode
{
	override function create()
	{
		Vscode.languages.registerDefinitionProvider('tcss', this);
	}

	public function provideDefinition(doc:TextDocument, position:Position, token:CancellationToken):Location
	{
		final pos:Pos = service.provideDefinition(
			{
				uri: doc.uri.fsPath,
				content: doc.getText()
			}, doc.offsetAt(position));

		if (pos != null)
		{
			return new Location(Uri.file(pos.file), new Range(pos.line - 1, pos.char, pos.endLine - 1, pos.endChar));
		}

		return null;
	}
}
