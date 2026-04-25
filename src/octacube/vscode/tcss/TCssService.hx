package octacube.vscode.tcss;

import haxe.io.Path;
import js.node.Crypto;
import js.node.Require;
import js.node.crypto.Verify;
import octacube.vscode.providers.TCssCompletionProvider;
import octacube.vscode.providers.TCssDefinitionProvider;
import octacube.vscode.providers.TCssDiagnosticProvider;
import octacube.vscode.providers.TCssHoverProvider;
import octacube.vscode.providers.TCssPreviewProvider;
import octacube.vscode.tcss.Api;
import octacube.vscode.util.HaxelibTools;
import sys.FileSystem;
import sys.io.File;
import vscode.TextDocument;
import vscode.Uri;

using StringTools;

class TCssService extends BaseNode
{
	public var paths:Array<String>;

	public var active:Bool = false;

	public var env:Environment;
	public var diagnostics:TCssDiagnosticProvider;
	public var definitions:TCssDefinitionProvider;
	public var completions:TCssCompletionProvider;
	public var previewProvider:TCssPreviewProvider;
	public var hover:TCssHoverProvider;

	override function create()
	{
		load();

		core.context.subscriptions.push(Vscode.commands.registerCommand("tcss.reload", load));
	}

	function load()
	{
		active = false;

		paths = ['./'];

		if (!HaxelibTools.isHaxelibInstalled())
		{
			Vscode.window.showErrorMessage("Haxelib was not found on the system. Some tcss functions may be unavailable.", "Install Haxe").then(selection ->
			{
				if (selection == "Install Haxe")
				{
					Vscode.env.openExternal(Uri.parse("https://haxe.org/download/"));
				}
			});
		}
		else
		{
			final libPath:String = HaxelibTools.getLibPath("octa-tcss");

			if (libPath == null)
			{
				final installText:String = "Install octa-tcss";
				final checkDocsText:String = "Check Docs";
				Vscode.window.showWarningMessage("The 'octa-tcss' library is not installed. Some tcss functions may be unavailable.", installText,
					checkDocsText)
					.then(selection ->
					{
						if (selection == installText)
							HaxelibTools.installLib();
						else if (selection == checkDocsText)
							Vscode.env.openExternal(Uri.parse("https://github.com/Octacube-org/Octa-tcss.git"));
					});
			}
			else
			{
				paths.push(libPath + 'std/');

				if (FileSystem.exists(libPath + '/vscode/main.js'))
				{
					function loadLib()
					{
						Require.cache.remove(Require.resolve(libPath + '/vscode/main.js'));

						final lib:Dynamic = Require.require(libPath + '/vscode/main.js');

						js.Lib.global.tcss = lib.tcss;

						switch (Api.version)
						{
							case '1.0.0':
								initService();
								this.core.log.log('Successfully loaded the `octa-tcss` API');
							default:
								Vscode.window.showWarningMessage("The selected version of `octa-tcss` uses an unsupported API. Please update the plugin to the latest version to ensure compatibility.");
						}
					}

					final isTrusted:Bool = checkCert(libPath + '/vscode/main.js', libPath + '/vscode/main.js.sig');

					if (isTrusted)
					{
						loadLib();
					}
					else
					{
						final message:String = "The 'octa-tcss' library bundle is unsigned or has an invalid signature.";

						function trustWarn()
						{
							Vscode.window.showWarningMessage(message, {}, "Trust and Execute", "Check folder", "Cancel").then(selection ->
							{
								if (selection == "Trust and Execute")
								{
									loadLib();
								}
								else if (selection == 'Check folder')
								{
									Vscode.env.openExternal(Uri.file(libPath));
									haxe.Timer.delay(() -> trustWarn(), 1000);
								}
								else
								{
									Vscode.window.setStatusBarMessage("TCSS: Library execution blocked", 5000);
								}

								return null;
							});
						}

						trustWarn();
					}
				}
				else
				{
					Vscode.window.showWarningMessage("The selected version of `octa-tcss` uses an unsupported API. Please update the plugin to the latest version to ensure compatibility.",
						'Check GitHub')
						.then(selection ->
						{
							Vscode.env.openExternal(Uri.parse("https://github.com/Octacube-org/Octa-tcss.git"));
						});
				}
			}
		}

		#if debug
		trace(paths);
		#end
	}

	function initService()
	{
		env = Api.createEnv(paths, getModulePath, this.importModule);

		diagnostics ??= new TCssDiagnosticProvider(this);
		hover ??= new TCssHoverProvider(this);
		definitions ??= new TCssDefinitionProvider(this);
		completions ??= new TCssCompletionProvider(this);
		previewProvider ??= new TCssPreviewProvider(this);

		active = true;

		updateSema(Vscode.window.activeTextEditor.document);
	}

	function checkCert(jsPath:String, sigPath:String):Bool
	{
		final pubKeyPath:String = Path.join([core.context.extensionPath, 'certs/public.pem']);

		try
		{
			final publicKey:String = File.getContent(pubKeyPath);
			final signature = js.node.Fs.readFileSync(sigPath);

			final verifier:Verify = Crypto.createVerify('sha256');
			verifier.update(File.getContent(jsPath));

			return verifier.verify(publicKey, signature);
		} catch (e)
		{
			core.log.error('Cert check error: ' + Std.string(e));

			return false;
		}
	}

	public function updateSema(doc:TextDocument)
	{
		if (!active)
			return;

		if (doc == null)
		{
			trace('null doc');
			return;
		}

		final errors = Api.analyze(env,
			{
				content: doc.getText(),
				uri: doc.uri.fsPath
			});

		diagnostics.updateDiagnostics(errors);
	}

	// File System

	public function getModulePath(moduleName:String):Null<String>
	{
		final filePath = '/' + moduleName + '.tcss';

		for (path in paths)
		{
			if (FileSystem.exists(path + filePath))
			{
				return Path.join([path, filePath]);
			}
		}

		return null;
	}

	function importModule(moduleName:String):DocumentData
	{
		final fileName = '$moduleName.tcss';

		var fullPath:String = null;
		if (Vscode.workspace.workspaceFolders != null && Vscode.workspace.workspaceFolders.length > 0)
		{
			for (folder in Vscode.workspace.workspaceFolders)
			{
				var checkPath = haxe.io.Path.join([folder.uri.fsPath, fileName]);
				if (FileSystem.exists(checkPath))
				{
					fullPath = checkPath;
					break;
				}
			}
		}

		if (fullPath == null)
		{
			fullPath = getModulePath(moduleName);
		}

		if (fullPath == null)
		{
			trace('Module not found: $fileName');
			return null;
		}

		final content = sys.io.File.getContent(fullPath);

		return {
			content: content,
			uri: fullPath
		}
	}

	public function getHover(doc:DocumentData, offset:Int):String
	{
		return Api.getHover(env, doc, offset);
	}

	public function provideDefinition(doc:DocumentData, offset:Int)
	{
		return Api.getDefinition(env, doc, offset);
	}

	public function generateCss(doc:DocumentData)
	{
		return Api.generateCss(env, doc);
	}

	public function getCompletions(doc:DocumentData, offset:Int)
	{
		return Api.getCompletions(env, doc, offset);
	}
}
