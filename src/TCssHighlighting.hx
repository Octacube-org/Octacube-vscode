import haxe.Json;
import sys.io.File;

typedef TmLanguage =
{
	var ?$schema:String;
	var name:String;
	var scopeName:String;
	var patterns:Array<TmPattern>;
	var repository:Dynamic<TmPattern>;
}

@:forward
abstract TmLanguageAccess(TmLanguage) from TmLanguage
{
	public function new(?o:TmLanguage)
	{
		this = o;
	}

	public function addPattern(name:String, pattern:TmPattern)
	{
		this.patterns.push({include: '#$name'});
		Reflect.setField(this.repository, name, pattern);
	}
}

typedef TmPattern =
{
	var ?name:String;
	var ?match:String;
	var ?begin:String;
	var ?end:String;
	var ?contentName:String;
	var ?comment:String;
	var ?captures:Dynamic<TmCapture>;
	var ?beginCaptures:Dynamic<TmCapture>;
	var ?endCaptures:Dynamic<TmCapture>;
	var ?patterns:Array<TmPattern>;
	var ?include:String;
}

typedef TmCapture =
{
	var ?name:String;
	var ?patterns:Array<TmPattern>;
}

final keywords:Array<String> = [
	'import',
	'extern',
	'extends',
	'virtual',
	'abstract',
	'public',
	'custom',
	'default',
	'collection',
	'struct'
];

enum abstract Patterns(String) from String to String
{
	private final esc = '\\\\.';

	// Chars
	private final lowercase = 'a-z';
	private final uppercase = 'A-Z';
	private final anycase = '$lowercase$uppercase';
	private final digits = '0-9';
	private final otherId = '_.\\-';
	private final anyId = '$anycase$digits$otherId';

	// pattern parts
	private final type = '(?:$esc|[$anycase])(?:$esc|[$anyId])*';
	private final id = '(?:$esc|[$lowercase])(?:$esc|[$anyId])*';
	private final listContent = '(?:$id(?:\\s*,\\s*$id)*)?';

	// patterns
	final typePattern = '($type)|%';

	final fieldPattern = '\\b($type)\\s+((?:$id))(?=\\s*[:;=])';
	final fieldPatternMultBegin = '\\b($id)\\s+\\{';
	final fieldPatternMultEnd = '\\}';
}

function main()
{
	var tmLanguage:TmLanguageAccess =
		{
			"$schema": "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
			name: "Octacube Typed Cascading Style Sheets",
			scopeName: "source.tcss",
			patterns: [],
			repository: {}
		}

	addComments(tmLanguage);
	addStrings(tmLanguage);
	addCssBlock(tmLanguage);
	addRulescriptEasterEgg(tmLanguage);
	addKeywords(tmLanguage);
	addConstants(tmLanguage);
	addFields(tmLanguage);
	addTypes(tmLanguage);
	addOperators(tmLanguage);

	File.saveContent('tcss/tmLanguage.json', Json.stringify(tmLanguage, '  '));
}

function addCssBlock(t:TmLanguageAccess)
{
	t.addPattern("css-block",
		{
			begin: "\\b(extern\\s+css)\\s+(</>)",
			beginCaptures: {"0": {name: "punctuation.section.embedded.begin.tcss"}},
			end: "(</>)",
			endCaptures: {"0": {name: "punctuation.section.embedded.end.tcss"}},
			patterns: [
				{
					begin: "^|(?<=\\s)",
					end: "(?=</>)",
					contentName: "source.css",
					patterns: [
						{
							include: "source.css#rule-list-innards"
						},
						{
							include: "source.css"
						}
					]
				}
			]
		});
}

function addComments(t:TmLanguageAccess)
{
	t.addPattern("comments",
		{
			patterns: [
				{
					name: "comment.block.tcss",
					begin: "/\\*",
					end: "\\*/"
				},
				{
					name: "comment.line.double-slash.tcss",
					begin: "//",
					end: "$"
				}
			]
		});
}

function addKeywords(t:TmLanguageAccess)
{
	t.addPattern("keywords",
		{
			patterns: [
				{
					begin: "\\b(collection)\\s+(class)\\b\\s*(\\()",
					beginCaptures:
						{
							"1": {name: "keyword.control.tcss"},
							"2": {name: "keyword.control.tcss"},
							"3": {name: "punctuation.definition.parameters.begin.tcss"}
						},
					end: "(\\))",
					endCaptures:
						{
							"1": {name: "punctuation.definition.parameters.end.tcss"}
						},
					patterns: [
						{
							match: "\\b([a-zA-Z0-9_]+)\\b\\s*(:)\\s*\\b([a-zA-Z0-9_]+)\\b",
							captures:
								{
									"1": {name: "entity.name.type.tcss"},
									"2": {name: "keyword.operator.tcss"},
									"3": {name: "entity.name.type.tcss"}
								}
						},
						{
							match: ",",
							name: "punctuation.separator.tcss"
						}
					]
				},
				{
					name: "keyword.control.tcss",
					match: "\\b(" + keywords.join('|') + ")\\b"
				},
				{
					match: "\\b(collection)\\s+(class)\\b",
					captures:
						{
							"1": {name: "keyword.control.tcss"},
							"2": {name: "keyword.control.tcss"}
						}
				},
				{
					match: "\\b(class|abstract|rule)\\s+([a-zA-Z0-9_.,\\-]+)",
					captures:
						{
							"1": {name: "keyword.control.tcss"},
							"2":
								{
									patterns: [
										{
											match: Patterns.typePattern, // "\\b[a-zA-Z0-9_]+\\b",
											name: "entity.name.type.tcss"
										}
									]
								}
						}
				}
			]
		});
}

function addStrings(t:TmLanguageAccess)
{
	t.addPattern("strings",
		{
			patterns: [
				{
					name: "string.quoted.other.tcss",
					begin: "@<",
					end: ">"
				},
				{
					name: "string.quoted.double.tcss",
					begin: "\"",
					end: "\""
				}
			]
		});
}

function addConstants(t:TmLanguageAccess)
{
	t.addPattern("constants",
		{
			patterns: [
				{
					name: "constant.other.color.rgb-value.tcss",
					match: "#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?\\b"
				},
				{
					name: "constant.numeric.tcss",
					match: "\\b\\d+([a-z%]+)?(?!\\w)"
				}
			]
		});
}

function addFields(t:TmLanguageAccess)
{
	t.addPattern("fields",
		{
			patterns: [
				{
					begin: Patterns.fieldPatternMultBegin,
					beginCaptures:
						{
							"1": {name: "entity.name.type.tcss"}
						},
					end: Patterns.fieldPatternMultEnd,
					patterns: [
						{
							match: ",",
							name: "punctuation.separator.tcss"
						},
						{
							match: "\\b[a-zA-Z0-9_]+\\b",
							name: "variable.other.readwrite.tcss"
						}
					]
				},
				{
					match: Patterns.fieldPattern,
					captures:
						{
							"1": {name: "entity.name.type.tcss"},
							"2": {name: "variable.other.readwrite.tcss"}
						}
				}
			]
		});
}

function addTypes(t:TmLanguageAccess)
{
	t.addPattern("types",
		{
			patterns: [
				{
					name: "entity.name.type.tcss",
					match: Patterns.typePattern
				}
			]
		});
}

function addOperators(t:TmLanguageAccess)
{
	t.addPattern("operators",
		{
			patterns: [
				{
					name: "keyword.operator.tcss",
					match: "(=|\\||;|\\{|\\})"
				}
			]
		});
}

function addRulescriptEasterEgg(t:TmLanguageAccess)
{
	t.addPattern("rulescript",
		{
			match: "\\b(extern\\s+rule)\\s+(script)\\b",
			captures:
				{
					"1": {name: "keyword.control.tcss"},
					"2": {name: "variable.language.self.tcss"}
				}
		});
}
