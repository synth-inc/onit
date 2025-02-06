//
//  Highlighting.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import Foundation
import HighlightSwift

extension HighlightLanguage {
  static func language(for markdownLanguage: String) -> HighlightLanguage? {
    switch markdownLanguage.lowercased() {
    case "applescript": return .appleScript
    case "arduino": return .arduino
    case "awk": return .awk
    case "bash": return .bash
    case "basic": return .basic
    case "c": return .c
    case "cpp", "c++": return .cPlusPlus
    case "cs", "c#", "csharp": return .cSharp
    case "clojure": return .clojure
    case "css": return .css
    case "dart": return .dart
    case "delphi": return .delphi
    case "diff": return .diff
    case "django": return .django
    case "dockerfile": return .dockerfile
    case "elixir": return .elixir
    case "elm": return .elm
    case "erlang": return .erlang
    case "gherkin": return .gherkin
    case "go": return .go
    case "gradle": return .gradle
    case "graphql": return .graphQL
    case "haskell": return .haskell
    case "html": return .html
    case "java": return .java
    case "javascript", "js": return .javaScript
    case "json": return .json
    case "julia": return .julia
    case "kotlin": return .kotlin
    case "latex", "tex": return .latex
    case "less": return .less
    case "lisp": return .lisp
    case "lua": return .lua
    case "makefile": return .makefile
    case "markdown", "md": return .markdown
    case "mathematica": return .mathematica
    case "matlab": return .matlab
    case "nix": return .nix
    case "objectivec", "objc": return .objectiveC
    case "perl": return .perl
    case "php": return .php
    case "phptemp", "php-template": return .phpTemplate
    case "plaintext", "text": return .plaintext
    case "postgresql", "psql": return .postgreSQL
    case "protobuf", "protocolbuffers": return .protocolBuffers
    case "python", "py": return .python
    case "python-repl": return .pythonRepl
    case "r": return .r
    case "ruby", "rb": return .ruby
    case "rust", "rs": return .rust
    case "scala": return .scala
    case "scss": return .scss
    case "shell", "sh": return .shell
    case "sql": return .sql
    case "swift": return .swift
    case "toml": return .toml
    case "typescript", "ts": return .typeScript
    case "vbnet", "vb", "visualbasic": return .visualBasic
    case "webassembly", "wasm": return .webAssembly
    case "yaml", "yml": return .yaml
    default: return nil
    }
  }

}
