package octacube.vscode.providers;

import vscode.CompletionItem;
import vscode.CompletionItemProvider;
import vscode.SnippetString;

class TCssCompletionProvider extends TCssNode
{
	override function create()
	{
		core.context.subscriptions.push(Vscode.languages.registerCompletionItemProvider(
			{
				language: "tcss"
			}, createCompletionProvider(), '\n', '='));
	}

	public function createCompletionProvider():CompletionItemProvider<CompletionItem>
	{
		return {
			provideCompletionItems: (doc, position, token, context) ->
			{
				final offset = doc.offsetAt(position);

				var items:Array<CompletionItem> = [];

				final itemData = service.getCompletions({uri: doc.uri.fsPath, content: doc.getText()}, offset);

				if (itemData == null)
					return null;

				for (data in itemData)
				{
					final item = new CompletionItem(data.label, switch (data.kind)
					{
						case 'CLASS': Class;
						case 'FIELD': Field;
						case 'ENUMVALUE': EnumMember;
						default: Value;
					});
					item.detail = data.detail;
					item.documentation = data.documentation;
					item.insertText = data.isSnippet ? new SnippetString(data.insertText) : data.insertText;
					item.sortText = data.sortText;

					items.push(item);
				}

				return items;
			}
		};
	}
}
