import 'dart:io';

void main() {
  final dir = Directory('d:/New folder (4)/ai_healthcare/lib');
  for(final file in dir.listSync(recursive: true)) {
    if(file is File && file.path.endsWith('.dart')) {
      final code = file.readAsStringSync();
      int index = -1;
      while ((index = code.indexOf('Container(', index + 1)) != -1) {
         int parens = 0;
         int endIndex = index + 9;
         bool inString = false;
         String stringChar = '';
         for(int i = index + 9; i < code.length; i++) {
           if (code[i] == '\'' || code[i] == '"') {
             if (!inString) {
               inString = true;
               stringChar = code[i];
             } else if (code[i] == stringChar && code[i-1] != '\\') {
               inString = false;
             }
           }
           if (!inString) {
             if(code[i] == '(') parens++;
             else if(code[i] == ')') parens--;
             if(parens == 0) {
               endIndex = i;
               break;
             }
           }
         }
         
         final block = code.substring(index, endIndex + 1);
         
         // simple check if color: is top-level
         // we just split by comma at top-level
         List<String> args = [];
         int lastComma = index + 10;
         int nest = 0;
         for(int i = index + 10; i < endIndex; i++) {
            if(block[i - index] == '(' || block[i - index] == '[' || block[i - index] == '{') nest++;
            if(block[i - index] == ')' || block[i - index] == ']' || block[i - index] == '}') nest--;
            if(nest == 0 && block[i - index] == ',') {
               args.add(block.substring(lastComma - index, i - index).trim());
               lastComma = i + 1;
            }
         }
         args.add(block.substring(lastComma - index, endIndex - index).trim());
         
         bool hasColor = false;
         bool hasDec = false;
         for(var arg in args) {
            if(arg.startsWith('color:') || arg.startsWith('color :')) hasColor = true;
            if(arg.startsWith('decoration:') || arg.startsWith('decoration :')) hasDec = true;
         }
         if(hasColor && hasDec) {
            print('--------------');
            print('BUG IN: \${file.path}');
            print(block);
         }
      }
    }
  }
}
