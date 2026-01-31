/// ChatGPT-accurate syntax highlighting color palette
/// Based on exact ChatGPT code block styling
library chatgpt_theme;

import 'package:flutter/material.dart';

/// ChatGPT-style syntax highlighting colors
/// These match the exact colors used in ChatGPT's code blocks
class ChatGPTCodeColors {
  // Code block backgrounds
  static const Color codeBlockBg = Color(0xFF0F0F0F);
  static const Color codeBlockBgLight = Color(0xFFF7F7F8);
  static const Color inlineCodeBg = Color(0xFF1A1A1A);
  static const Color inlineCodeBgLight = Color(0xFFE5E5E5);
  
  // Syntax colors (Dark mode - ChatGPT exact)
  static const Color keyword = Color(0xFF569CD6);       // Blue - if, for, class, def
  static const Color functionDef = Color(0xFFF44747);   // Red - function DEFINITIONS (def home, function foo)
  static const Color functionCall = Color(0xFFDCDCAA);  // Yellow - function CALLS (print(), len())
  static const Color className = Color(0xFF4EC9B0);     // Teal - class names, types
  static const Color string = Color(0xFF6A9955);        // Green - strings
  static const Color number = Color(0xFFB5CEA8);        // Light green - numbers
  static const Color variable = Color(0xFF9CDCFE);      // Light blue - variables
  static const Color comment = Color(0xFF6A737D);       // Grey - comments
  static const Color error = Color(0xFFF44747);         // Red - errors
  static const Color bashCommand = Color(0xFF89D185);   // Light green - bash commands
  static const Color operator = Color(0xFFD4D4D4);      // White - operators
  static const Color punctuation = Color(0xFFD4D4D4);   // White - brackets, commas
  static const Color constant = Color(0xFF569CD6);      // Blue - True, False, None
  static const Color decorator = Color(0xFFDCDCAA);     // Yellow - @decorators
  static const Color builtin = Color(0xFF4EC9B0);       // Teal - built-in types
  
  ChatGPTCodeColors._();
}

/// ChatGPT-style dark theme for flutter_highlight
/// Keys match highlight.js token classes
const chatGPTDarkTheme = {
  'root': TextStyle(
    backgroundColor: Colors.transparent,
    color: Color(0xFFE0E0E0),
  ),
  
  // Keywords (blue)
  'keyword': TextStyle(color: Color(0xFF4EC9B0)),
  'selector-tag': TextStyle(color: Color(0xFF569CD6)),
  'literal': TextStyle(color: Color(0xFF569CD6)),
  'built_in': TextStyle(color: Color(0xFF4EC9B0)),
  
  // Strings (green)
  'string': TextStyle(color: Color(0xFF6A9955)),
  'doctag': TextStyle(color: Color(0xFF6A9955)),
  'template-tag': TextStyle(color: Color(0xFF6A9955)),
  'template-variable': TextStyle(color: Color(0xFF6A9955)),
  'link': TextStyle(color: Color(0xFF6A9955)),
  'quote': TextStyle(color: Color(0xFF6A9955)),
  
  // Functions - DEFINITIONS are RED, CALLS are YELLOW (ChatGPT style)
  'title': TextStyle(color: Color(0xFFF44747)),           // Function/class definitions - RED
  'title.function': TextStyle(color: Color(0xFFF44747)),  // def foo() -> RED
  'title.class': TextStyle(color: Color(0xFF4EC9B0)),     // class Foo -> TEAL
  'function': TextStyle(color: Color(0xFFDCDCAA)),        // Function calls - YELLOW
  'name': TextStyle(color: Color(0xFFDCDCAA)),
  
  // Types and classes (teal)
  'type': TextStyle(color: Color(0xFF4EC9B0)),
  'class': TextStyle(color: Color(0xFF4EC9B0)),
  
  // Variables (light blue)
  'variable': TextStyle(color: Color(0xFF9CDCFE)),
  'attr': TextStyle(color: Color(0xFF9CDCFE)),
  'attribute': TextStyle(color: Color(0xFF9CDCFE)),
  'params': TextStyle(color: Color(0xFF9CDCFE)),
  
  // Numbers (light green)
  'number': TextStyle(color: Color(0xFFF44747)),
  
  // Comments (grey)
  'comment': TextStyle(
    color: Color(0xFF6A737D),
    fontStyle: FontStyle.italic,
  ),
  
  // Meta/decorators (yellow)
  'meta': TextStyle(color: Color(0xFFDCDCAA)),
  'meta-keyword': TextStyle(color: Color(0xFFDCDCAA)),
  'meta-string': TextStyle(color: Color(0xFF6A9955)),
  'decorator': TextStyle(color: Color(0xFFDCDCAA)),
  'annotation': TextStyle(color: Color(0xFFDCDCAA)),
  
  // Punctuation/operators (white)
  'punctuation': TextStyle(color: Color(0xFFD4D4D4)),
  'operator': TextStyle(color: Color(0xFFD4D4D4)),
  
  // Special
  'regexp': TextStyle(color: Color(0xFFD16969)),
  'symbol': TextStyle(color: Color(0xFFB5CEA8)),
  'selector-class': TextStyle(color: Color(0xFF4EC9B0)),
  'selector-id': TextStyle(color: Color(0xFFDCDCAA)),
  'selector-attr': TextStyle(color: Color(0xFFDCDCAA)),
  'selector-pseudo': TextStyle(color: Color(0xFFDCDCAA)),
  
  // HTML/XML
  'tag': TextStyle(color: Color(0xFF569CD6)),
  
  // Bold/emphasis from markdown
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  
  // Subst for template strings
  'subst': TextStyle(color: Color(0xFF9CDCFE)),
  
  // Addition/deletion for diffs
  'addition': TextStyle(
    color: Color(0xFF6A9955),
    backgroundColor: Color(0x332EA043),
  ),
  'deletion': TextStyle(
    color: Color(0xFFF44747),
    backgroundColor: Color(0x33F44747),
  ),
  
  // Section headers
  'section': TextStyle(
    color: Color(0xFF569CD6),
    fontWeight: FontWeight.bold,
  ),
};

/// ChatGPT-style light theme for flutter_highlight
const chatGPTLightTheme = {
  'root': TextStyle(
    backgroundColor: Colors.transparent,
    color: Color(0xFF24292E),
  ),
  
  // Keywords (blue)
  'keyword': TextStyle(color: Color(0xFFD73A49)),
  'selector-tag': TextStyle(color: Color(0xFFD73A49)),
  'literal': TextStyle(color: Color(0xFF005CC5)),
  'built_in': TextStyle(color: Color(0xFF005CC5)),
  
  // Strings (blue-ish green)
  'string': TextStyle(color: Color(0xFF032F62)),
  'doctag': TextStyle(color: Color(0xFF032F62)),
  'template-tag': TextStyle(color: Color(0xFF032F62)),
  'template-variable': TextStyle(color: Color(0xFF6F42C1)),
  
  // Functions
  'title': TextStyle(color: Color(0xFFD73A49)),          // Function definitions - RED
  'title.function': TextStyle(color: Color(0xFFD73A49)),
  'title.class': TextStyle(color: Color(0xFF6F42C1)),
  'function': TextStyle(color: Color(0xFF6F42C1)),
  'name': TextStyle(color: Color(0xFF6F42C1)),
  
  // Types (purple)
  'type': TextStyle(color: Color(0xFF6F42C1)),
  'class': TextStyle(color: Color(0xFF6F42C1)),
  
  // Variables
  'variable': TextStyle(color: Color(0xFF005CC5)),
  'attr': TextStyle(color: Color(0xFF005CC5)),
  'attribute': TextStyle(color: Color(0xFF005CC5)),
  'params': TextStyle(color: Color(0xFF24292E)),
  
  // Numbers
  'number': TextStyle(color: Color(0xFF005CC5)),
  
  // Comments (grey)
  'comment': TextStyle(
    color: Color(0xFF6A737D),
    fontStyle: FontStyle.italic,
  ),
  
  // Meta/decorators
  'meta': TextStyle(color: Color(0xFF6F42C1)),
  'meta-keyword': TextStyle(color: Color(0xFF6F42C1)),
  'meta-string': TextStyle(color: Color(0xFF032F62)),
  
  // Punctuation
  'punctuation': TextStyle(color: Color(0xFF24292E)),
  'operator': TextStyle(color: Color(0xFF24292E)),
  
  // Special
  'regexp': TextStyle(color: Color(0xFF032F62)),
  'symbol': TextStyle(color: Color(0xFF005CC5)),
  
  // HTML/XML
  'tag': TextStyle(color: Color(0xFF22863A)),
  
  // Bold/emphasis
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  
  // Diffs
  'addition': TextStyle(
    color: Color(0xFF22863A),
    backgroundColor: Color(0x40ACFFCD),
  ),
  'deletion': TextStyle(
    color: Color(0xFFB31D28),
    backgroundColor: Color(0x40FFCDD2),
  ),
  
  'section': TextStyle(
    color: Color(0xFF005CC5),
    fontWeight: FontWeight.bold,
  ),
};
