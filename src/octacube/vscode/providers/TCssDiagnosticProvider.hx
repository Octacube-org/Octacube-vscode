package octacube.vscode.providers;

import vscode.Uri;
import octacube.vscode.tcss.Api;
import vscode.DiagnosticCollection;
import vscode.DiagnosticSeverity;
import vscode.Diagnostic;
import vscode.Range;

class TCssDiagnosticProvider extends TCssNode
{
	var collection:DiagnosticCollection;

	override function create()
	{
		collection = Vscode.languages.createDiagnosticCollection("tcss");

		core.context.subscriptions.push(collection);
	}

	public function updateDiagnostics(parserErrors:Array<ErrorData>)
	{
		collection.clear();

		final diagnostics:Map<String, Array<Diagnostic>> = [];

		for (error in parserErrors)
		{
			final range = new Range(error.pos.line - 1, error.pos.char, error.pos.endLine - 1, error.pos.endChar);
			final diagnostic = new Diagnostic(range, error.info, DiagnosticSeverity.Error);
			diagnostic.source = 'tcss';

			if (!diagnostics.exists(error.pos.file))
				diagnostics[error.pos.file] = [];

			diagnostics[error.pos.file].push(diagnostic);
		}

		for (file => diagnostic in diagnostics)
		{
			collection.set(Uri.file(file), diagnostic);
		}
	}
}
