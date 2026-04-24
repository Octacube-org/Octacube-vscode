package octacube.vscode.tcss;

@:native('tcss.Api')
extern class Api
{
	public static var version:String;

	public static function createEnv(paths:Array<String>, getModulePath:String->String, importFunc:String->DocumentData):Environment;
	public static function analyze(env:Environment, doc:DocumentData):Array<ErrorData>;
	public static function getHover(env:Environment, doc:DocumentData, offset:Int):Null<String>;
	public static function getDefinition(env:Environment, doc:DocumentData, offset:Int):Pos;
	public static function generateCss(env:Environment, doc:DocumentData):String;
	public static function getCompletions(env:Environment, doc:DocumentData, offset:Int):Array<CompletionData>;
}

extern class Environment {}

typedef DocumentData =
{
	var uri:String;
	var content:String;
}

typedef ErrorData =
{
	info:String,
	pos:Pos
}

typedef Pos =
{
	var min:Int;
	var max:Int;
	var line:Int;
	var char:Int;
	var endLine:Int;
	var endChar:Int;
	var file:String;
}

typedef CompletionData =
{
	var label:String;
	var kind:String;
	var ?insertText:String;
	var ?isSnippet:Bool;
	var ?detail:String;
	var ?documentation:String;
	var ?sortText:String;
}
