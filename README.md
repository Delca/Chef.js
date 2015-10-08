# Chef.js
You can [try it here](http://delca.github.io/Chef.js)!

Chef.js is an effort to implement a JavaScript interpreter for the Chef programming language.
Parsing the recipe was done by writing a context-free grammar representing the language, then using [Jison](https://github.com/zaach/jison) to create a parser from that grammar.

[Chef's specifications](http://www.dangermouse.net/esoteric/chef.html) were originally described by David Morgan-Mar.

Although the goal is to stay as close as possible to the original, the behaviour is not guaranteed to always match this document.
As a result, the *Fibonacci Numbers with Caramel Sauce* recipe offered with the specifications does not work with this interpreter.
