// Parses the output of Elm's `Debug.toString` (elm/core 1.0.x) into a small tagged AST that
// src/Inspector.elm decodes. Regenerate js/parser.js after editing: `npm run build:parser`.
//
//   { t: "record", fields: [[name, value], ...] }      { a = 1, b = "x" }
//   { t: "list" | "array" | "set", items: [...] }      [1,2]  Array.fromList [1]  Set.fromList [1]
//   { t: "dict", entries: [[key, value], ...] }        Dict.fromList [("a",1)]
//   { t: "tuple", items: [...] }                       (1,"x")
//   { t: "custom", name, args: [...] }                 Nothing  Just 1  Editing 1 "x"
//   { t: "string" | "char" | "number" | "bool" | "unit" | "function" | "internals" | "bytes" | "file", v }

Start
  = _ value:Value _ { return value; }

Value
  = CustomWithArgs
  / Atom

Atom
  = Record
  / Collection
  / List
  / Tuple
  / Unit
  / "(" _ value:Value _ ")" { return value; }
  / Number
  / Char
  / String
  / Special
  / Bool
  / name:CtorName { return { t: "custom", name, args: [] }; }

CustomWithArgs
  = name:CtorName args:(" " _ @Atom)+ { return { t: "custom", name, args }; }

Record
  = "{" _ "}" { return { t: "record", fields: [] }; }
  / "{" _ head:Field tail:("," _ @Field)* _ "}" { return { t: "record", fields: [head, ...tail] }; }

Field
  = name:FieldName _ "=" _ value:Value _ { return [name, value]; }

Collection
  = "Dict.fromList" _ items:Items { return { t: "dict", entries: items.map((tuple) => tuple.items ?? [tuple, { t: "unit" }]) }; }
  / "Set.fromList" _ items:Items { return { t: "set", items }; }
  / "Array.fromList" _ items:Items { return { t: "array", items }; }

List
  = items:Items { return { t: "list", items }; }

Items
  = "[" _ "]" { return []; }
  / "[" _ head:Value _ tail:("," _ @Value _)* "]" { return [head, ...tail]; }

Tuple
  = "(" _ head:Value _ tail:("," _ @Value _)+ ")" { return { t: "tuple", items: [head, ...tail] }; }

Unit
  = "(" _ ")" { return { t: "unit" }; }

Number
  = value:$("-"? ("Infinity" !NameChar / [0-9]+ ("." [0-9]+)? ([eE] [+-]? [0-9]+)?)) { return { t: "number", v: value }; }
  / "NaN" !NameChar { return { t: "number", v: "NaN" }; }

Bool
  = "True" !NameChar { return { t: "bool", v: true }; }
  / "False" !NameChar { return { t: "bool", v: false }; }

Special
  = "<function>" { return { t: "function" }; }
  / "<internals>" { return { t: "internals" }; }
  / "<" digits:$[0-9]+ " bytes>" { return { t: "bytes", v: parseInt(digits, 10) }; }
  / "<" name:$(!">" .)* ">" { return { t: "file", v: name }; }

CtorName
  = $([A-Z] NameChar*)

FieldName
  = $(!(" " / "=" / "," / "}") .)+

NameChar
  = [a-zA-Z0-9_]

String
  = '"' chars:(StringChar)* '"' { return { t: "string", v: chars.join("") }; }

StringChar
  = !('"' / "\\") @.
  / "\\" @Escape

Char
  = "'" chars:(CharChar)+ "'" { return { t: "char", v: chars.join("") }; }

CharChar
  = !("'" / "\\") @.
  / "\\" @Escape

Escape
  = "n" { return "\n"; }
  / "t" { return "\t"; }
  / "r" { return "\r"; }
  / "v" { return "\v"; }
  / "0" { return "\0"; }
  / "b" { return "\b"; }
  / "f" { return "\f"; }
  / .

_ "whitespace"
  = [ \t\n\r]*
