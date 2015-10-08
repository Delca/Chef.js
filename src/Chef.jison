%lex

%s MODE_CHECK
%x RECIPE_MODE
%x COMMENT_SINGLE_LINE

%%

<<EOF>> {return 'TOKEN_EOF';}
<RECIPE_MODE><<EOF>> {return 'TOKEN_EOF';}

\/\/ {yy.lexer.begin("COMMENT_SINGLE_LINE");}
<RECIPE_MODE>\/\/ {yy.lexer.begin("COMMENT_SINGLE_LINE");}
<COMMENT_SINGLE_LINE>[^\n]+ {}
// TODO: find a way to allow comment-only lines
<COMMENT_SINGLE_LINE>\n {yy.lexer.popState();}

// We ensure this kind of line return by removing all \r
// manually before parsing the file.
// Windows, FUCK YOU.
<RECIPE_MODE>\n {return 'TOKEN_NEWLINE';}
<RECIPE_MODE>\. {return 'TOKEN_DOT';}
\n {return 'TOKEN_NEWLINE';}
\. {if(yy.lexer.topState() == 'INITIAL'){/*console.log('BEGIN MODE_CHECK');*/ yy.lexer.begin("MODE_CHECK");}return 'TOKEN_DOT';}


Ingredients\.\n {/*console.log('Oh ingredients');*/ yy.lexer.popState(); yy.lexer.begin("RECIPE_MODE"); return 'TOKEN_INGREDIENTS_HEAD';}
Method\.\n {yy.lexer.begin("RECIPE_MODE"); return 'TOKEN_METHOD_HEAD';}
"Cooking time:" {yy.lexer.begin("RECIPE_MODE"); return 'TOKEN_COOKING_TIME';}
"Pre-heat oven to" {yy.lexer.begin("RECIPE_MODE"); return 'TOKEN_PREHEAT_OVEN_START';}

<MODE_CHECK>\s+ {return 'WHITE';}
<MODE_CHECK>.+ {/*console.log('AS_MODE_CHECK_' + yytext + '_');*/ return 'IDENTIFIER_PART';}

<RECIPE_MODE>Ingredients\.\n {yy.lexer.begin("RECIPE_MODE"); return 'TOKEN_INGREDIENTS_HEAD';}
<RECIPE_MODE>Method\.\n {yy.lexer.begin("RECIPE_MODE"); return 'TOKEN_METHOD_HEAD';}
<RECIPE_MODE>"Cooking time:" {yy.lexer.begin("RECIPE_MODE"); return 'TOKEN_COOKING_TIME';}
<RECIPE_MODE>"Pre-heat oven to" {yy.lexer.begin("RECIPE_MODE"); return 'TOKEN_PREHEAT_OVEN_START';}
<RECIPE_MODE>"degrees Celsius" {return 'TOKEN_PREHEAT_OVEN_END';}
<RECIPE_MODE>"gas mark" {return 'TOKEN_PREHEAT_OVEN_GASMARK';}

<RECIPE_MODE>"Take" {return 'TOKEN_TAKE';}
<RECIPE_MODE>"from" {return 'TOKEN_FROM';}
<RECIPE_MODE>"refrigerator" {return 'TOKEN_REFRIGERATOR';}
<RECIPE_MODE>"Put" {return 'TOKEN_PUT';}
<RECIPE_MODE>"into" {return 'TOKEN_INTO';}
<RECIPE_MODE>"mixing bowl" {return 'TOKEN_MIXING_BOWL';}
<RECIPE_MODE>"Fold" {return 'TOKEN_FOLD';}
<RECIPE_MODE>"Add" {return 'TOKEN_ADD';}
<RECIPE_MODE>"to" {return 'TOKEN_TO';}
<RECIPE_MODE>"Remove" {return 'TOKEN_REMOVE';}
<RECIPE_MODE>"from" {return 'TOKEN_FROM';}
<RECIPE_MODE>"Combine" {return 'TOKEN_COMBINE';}
<RECIPE_MODE>"Divide" {return 'TOKEN_DIVIDE';}
<RECIPE_MODE>"dry" {return 'TOKEN_DRY';}
<RECIPE_MODE>"ingredients" {return 'TOKEN_INGREDIENTS';}
<RECIPE_MODE>"Liquefy"|"Liquify" {return 'TOKEN_LIQUIFY';}
<RECIPE_MODE>"contents" {return 'TOKEN_CONTENTS';}
<RECIPE_MODE>"of" {return 'TOKEN_OF';}
<RECIPE_MODE>"the" {return 'TOKEN_THE';}
<RECIPE_MODE>"Stir" {return 'TOKEN_STIR';}
<RECIPE_MODE>"for" {return 'TOKEN_FOR';}
<RECIPE_MODE>"Mix" {return 'TOKEN_MIX';}
<RECIPE_MODE>"well" {return 'TOKEN_WELL';}
<RECIPE_MODE>"Clean" {return 'TOKEN_CLEAN';}
<RECIPE_MODE>"Pour" {return 'TOKEN_POUR';}
<RECIPE_MODE>"baking dish" {return 'TOKEN_BAKING_DISH';}
<RECIPE_MODE>"until" {return 'TOKEN_UNTIL';}
<RECIPE_MODE>"Set" {return 'TOKEN_SET';}
<RECIPE_MODE>"aside" {return 'TOKEN_ASIDE';}
<RECIPE_MODE>"Serve" {return 'TOKEN_SERVE';}
<RECIPE_MODE>"with" {return 'TOKEN_WITH';}
<RECIPE_MODE>"Refrigerate" {return 'TOKEN_REFRIGERATE';}
<RECIPE_MODE>"Serves" {return 'TOKEN_SERVES';}


<RECIPE_MODE>heaped|level {return 'TOKEN_MEASURE_TYPE';}
// 'g' and 'l' are not here, because otherwise we would not be able to parse words starting with those letters
<RECIPE_MODE>kg|pinches|pinch|ml|dashes|dash|cups|cup|teaspoons|teaspoon|tablespoons|tablespoon {return 'TOKEN_MEASURE';}
<RECIPE_MODE>hours|hour {return 'TOKEN_HOURS';}
<RECIPE_MODE>minutes|minute {return 'TOKEN_MINUTES';}

<RECIPE_MODE>[0-9]*[3-9]th|11th|12th|1st|2nd|3rd {yytext = yytext.replace('st', '').replace('nd', '').replace('rd', '').replace('th', ''); return 'ORDINAL';}
<RECIPE_MODE>[0-9]+ {return 'INTEGER';}

// IDENTIFIER_PART starts with a lowercase letter, while
// TITLE_PART starts with an uppercase letter.
<RECIPE_MODE>[a-z][a-zA-Z0-9]* {if (yytext == 'l' || yytext == 'g'){ return 'TOKEN_MEASURE';} /*console.log('GOT IDENTIFIER PART ' + yytext);*/ return 'IDENTIFIER_PART';}
<RECIPE_MODE>[A-Z][a-zA-Z0-9]* {/*console.log('GOT TITLE PART ' + yytext);*/ return 'TITLE_PART';}

<RECIPE_MODE>\s+ {return 'WHITE';}

[^\.\n]+ {/*console.log('AS_GENERIC_TITLE_PART_' + yytext + '_');*/ return 'TITLE_PART';}


/lex

%{
var ast = require('./src/ast');
var fs = require('fs');

var ASTNode = ast.ASTNode;
var NodeType = ast.NodeType;
var NodeSubtype = ast.NodeSubtype;
var isDry = ast.isDry;

%}

%start file
%%

file
	: prog {return $1;};

prog
	: prog recipe {$1.push($2); $$ = $1;}
	| recipe {$$ = [$1];}
	| 'TOKEN_NEWLINE'
	;

recipe
	: title optionalDescription ingredientSection cookingTimeAndOven method optionalServeStatement {$$ = new ASTNode(NodeType.RECIPE, {title: $1, cookingTimeAndOven: $3}, {ingredients: $3, method: $5, serve: $6});}
	;
	
nextLine
	: 'TOKEN_NEWLINE'
	| nextLine 'TOKEN_NEWLINE'
	| 'TOKEN_EOF'
	;
	
title
	: upperIdentifier 'TOKEN_DOT' 'TOKEN_NEWLINE' 'TOKEN_NEWLINE' {if(yy.lexer.topState() != 'MODE_CHECK'){/*console.log('BEGIN MODE_CHECK');*/ yy.lexer.begin("MODE_CHECK");}$$ = new ASTNode(NodeType.TITLE, $1);}
	;
	
optionalServeStatement
	: 'TOKEN_NEWLINE' servesDishes nextLine {$$ = $2}
	| nextLine {$$ = new ASTNode(NodeType.UNARY_INT, 0, null, null, NodeSubtype.SERVES);}
	;
	
optionalDescription
	: description 'TOKEN_NEWLINE'
	|
	;
	
description
	: identifier 'TOKEN_NEWLINE'
	| description identifier 'TOKEN_NEWLINE'
	| upperIdentifier 'TOKEN_NEWLINE'
	| description upperIdentifier 'TOKEN_NEWLINE'
	| 'TOKEN_DOT' 'TOKEN_NEWLINE'
	| description 'TOKEN_DOT' 'TOKEN_NEWLINE'
	| 'WHITE' 'TOKEN_NEWLINE'
	| description 'WHITE' 'TOKEN_NEWLINE'
	;	

upperIdentifier
	: upperIdentifier 'WHITE' 'TITLE_PART' {$1.val1 += ' ' + $3; $$ = $1;}
	| upperIdentifier 'WHITE' 'IDENTIFIER_PART' {$1.val1 += ' ' + $3; $$ = $1;}
	| 'TITLE_PART' {$$ = new ASTNode(NodeType.IDENTIFIER, $1);}
	;
	
identifier
	: identifier 'WHITE' 'IDENTIFIER_PART' {$1.val1 += ' ' + $3; $$ = $1;}
	| identifier 'WHITE' 'TITLE_PART' {$1.val1 += ' ' + $3; $$ = $1;}
	| 'IDENTIFIER_PART' {$$ = new ASTNode(NodeType.IDENTIFIER, $1);}
	;
	
ingredientSection
	: 'TOKEN_INGREDIENTS_HEAD' ingredientList 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.INGREDIENTS, $2);}
	;
	
ingredientList
	: ingredientList ingredientDeclaration {$1.push($2); $$ = $1;}
	| ingredientDeclaration {$$ = [$1];}
	;
	
ingredientDeclaration
	: identifier 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.INGREDIENT, $1, undefined, true);}
	| 'INTEGER' 'WHITE' identifier 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.INGREDIENT, $3, $1, true);}
	| 'INTEGER' 'WHITE' ingredientMeasure 'WHITE' identifier 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.INGREDIENT, $5, $1, $3);}
	| ingredientMeasure 'WHITE' identifier 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.INGREDIENT, $3, undefined, $1);}
	;
	
ingredientMeasure
	: 'TOKEN_MEASURE_TYPE' 'TOKEN_MEASURE' {$$ = isDry($2, $1);}
	| 'TOKEN_MEASURE' {$$ = isDry($1);}
	;
	
timeUnit
	: 'TOKEN_MINUTES'
	| 'TOKEN_HOURS'
	;

cookingTimeAndOven
	: cookingTime 'TOKEN_NEWLINE'
	| ovenTemperature 'TOKEN_NEWLINE'
	| cookingTime ovenTemperature 'TOKEN_NEWLINE'
	| ovenTemperature cookingTime 'TOKEN_NEWLINE'
	|
	;
	
cookingTime
	: 'TOKEN_COOKING_TIME' 'WHITE' 'INTEGER' 'WHITE' timeUnit 'TOKEN_DOT' 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.COOKING_TIME, $3, $5);}
	;
	
ovenTemperature
	: 'TOKEN_PREHEAT_OVEN_START' 'WHITE' 'INTEGER' 'WHITE' 'TOKEN_PREHEAT_OVEN_END' 'TOKEN_DOT' 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.OVEN_TEMPERATURE, $3);}
	| 'TOKEN_PREHEAT_OVEN_START' 'WHITE' 'INTEGER' 'WHITE' 'TOKEN_PREHEAT_OVEN_END' 'WHITE' 'TOKEN_PREHEAT_OVEN_GAS_MARK' 'INTEGER' 'TOKEN_DOT' 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.OVEN_TEMPERATURE, $3, $8);}
	;
	
method
	: 'TOKEN_METHOD_HEAD' methodList {$$ = new ASTNode(NodeType.METHOD, $2);}
	;
	
methodList
	: methodList completeMethodStatement {$1.push($2); $$ = $1;}
	| completeMethodStatement {$$ = [$1];}
	;
	
completeMethodStatement
	: methodStatement 'TOKEN_NEWLINE' {$$ = $1;}
	| methodStatement 'WHITE' {$$ = $1;}
	;
	
methodStatement
	: takeFromRefrigerator
	| putIntoMixingBowl
	| foldIntoMixingBowl
	| addToMixingBowl
	| removeFromMixingBowl
	| combineIntoMixingBowl
	| divideIntoMixingBowl
	| addDryIngredientsToMixingBowl
	| liquifyIngredient
	| liquifyMixingBowl
	| stirForMinutes
	| stirIngredientIntoMixingBowl
	| mixMixingBowlWell
	| cleanMixingBowl
	| pourContentsIntoBakingDish
	| actionLoopStart
	| actionLoopEnd
	| setAside
	| serveWith
	| refrigerate
//	| servesDishes
	;
	
targetMixingBowl
	: 'TOKEN_MIXING_BOWL' {$$ = new ASTNode(NodeType.MIXING_BOWL, 1);}
	| 'ORDINAL' 'WHITE' 'TOKEN_MIXING_BOWL' {$$ = new ASTNode(NodeType.MIXING_BOWL, $1);}
	;
	
targetBakingDish
	: 'TOKEN_BAKING_DISH' {$$ = new ASTNode(NodeType.BAKING_DISH, 1);}
	| 'ORDINAL' 'WHITE' 'TOKEN_BAKING_DISH' {$$ = new ASTNode(NodeType.MIXING_BOWL, $1);}
	| 'TOKEN_THE' 'WHITE' 'TOKEN_BAKING_DISH' {$$ = new ASTNode(NodeType.BAKING_DISH, 1);}
	| 'TOKEN_THE' 'WHITE' 'ORDINAL' 'WHITE' 'TOKEN_BAKING_DISH' {$$ = new ASTNode(NodeType.MIXING_BOWL, $3);}
	;
	
takeFromRefrigerator
	: 'TOKEN_TAKE' 'WHITE' identifier 'WHITE' 'TOKEN_FROM' 'WHITE' 'TOKEN_REFRIGERATOR' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_INGR, $3, null, null, NodeSubtype.TAKE_FROM_REFRIGERATOR);}
	;
	
putIntoMixingBowl
	: 'TOKEN_PUT' 'WHITE' identifier 'WHITE' 'TOKEN_INTO' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $7, null, NodeSubtype.PUT);}
	| 'TOKEN_PUT' 'WHITE' identifier 'WHITE' 'TOKEN_INTO' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $9, null, NodeSubtype.PUT);}
	;

// TODO: only the 'Fold' rule is equipped with the optionalTHE
// Add it to other similar rules	
optionalTHE
	: 'WHITE' 'TOKEN_THE' 'WHITE'
	| 'WHITE'
	;
	
foldIntoMixingBowl
	: 'TOKEN_FOLD' optionalTHE identifier 'WHITE' 'TOKEN_INTO' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $7, null, NodeSubtype.FOLD);}
	| 'TOKEN_FOLD' optionalTHE identifier 'WHITE' 'TOKEN_INTO' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $9, null, NodeSubtype.FOLD);}
	;
	
addToMixingBowl
	: 'TOKEN_ADD' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, new ASTNode(NodeType.MIXING_BOWL, 1), null, NodeSubtype.ADD);}
	| 'TOKEN_ADD' 'WHITE' identifier 'WHITE' 'TOKEN_TO' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $7, null, NodeSubtype.ADD);}
	| 'TOKEN_ADD' 'WHITE' identifier 'WHITE' 'TOKEN_TO' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $9, null, NodeSubtype.ADD);}
	;
	
removeFromMixingBowl
	: 'TOKEN_REMOVE' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, new ASTNode(NodeType.MIXING_BOWL, 1), null, NodeSubtype.REMOVE);}
	| 'TOKEN_REMOVE' 'WHITE' identifier 'WHITE' 'TOKEN_FROM' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $7, null, NodeSubtype.REMOVE);}
	| 'TOKEN_REMOVE' 'WHITE' identifier 'WHITE' 'TOKEN_FROM' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $9, null, NodeSubtype.REMOVE);}
	;
	
combineIntoMixingBowl
	: 'TOKEN_COMBINE' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, new ASTNode(NodeType.MIXING_BOWL, 1), null, NodeSubtype.COMBINE);}
	| 'TOKEN_COMBINE' 'WHITE' identifier 'WHITE' 'TOKEN_INTO' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $7, null, NodeSubtype.COMBINE);}
	| 'TOKEN_COMBINE' 'WHITE' identifier 'WHITE' 'TOKEN_INTO' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $9, null, NodeSubtype.COMBINE);}
	;
	
divideIntoMixingBowl
	: 'TOKEN_DIVIDE' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, new ASTNode(NodeType.MIXING_BOWL, 1), null, NodeSubtype.DIVIDE);}
	| 'TOKEN_DIVIDE' 'WHITE' identifier 'WHITE' 'TOKEN_INTO' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $7, null, NodeSubtype.DIVIDE);}
	| 'TOKEN_DIVIDE' 'WHITE' identifier 'WHITE' 'TOKEN_INTO' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $9, null, NodeSubtype.DIVIDE);}
	;
	
addDryIngredientsToMixingBowl
	: 'TOKEN_ADD' 'WHITE' 'TOKEN_DRY' 'WHITE' 'TOKEN_INGREDIENTS' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, new ASTNode(NodeType.MIXING_BOWL, 1), null, null, NodeSubtype.ADD_DRY);}
	| 'TOKEN_ADD' 'WHITE' 'TOKEN_DRY' 'WHITE' 'TOKEN_INGREDIENTS' 'WHITE' 'TOKEN_TO' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, $9, null, null, NodeSubtype.ADD_DRY);}
	| 'TOKEN_ADD' 'WHITE' 'TOKEN_DRY' 'WHITE' 'TOKEN_INGREDIENTS' 'WHITE' 'TOKEN_TO' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, $11, null, null, NodeSubtype.ADD_DRY);}
	;
	
liquifyIngredient
	: 'TOKEN_LIQUIFY' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_INGR, $3, null, null, NodeSubtype.LIQUEFY_INGR);}
	;
	
liquifyMixingBowl
	: 'TOKEN_LIQUIFY' 'WHITE' 'TOKEN_CONTENTS' 'WHITE' 'TOKEN_OF' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, $9, null, null, NodeSubtype.LIQUEFY_BOWL);}
	;
	
stirForMinutes
	: 'TOKEN_STIR' 'WHITE' 'TOKEN_FOR' 'WHITE' 'INTEGER' 'WHITE' 'TOKEN_MINUTES' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_BOWL_INT, new ASTNode(NodeType.MIXING_BOWL, 1), $5, null, NodeSubtype.STIR);}
	| 'TOKEN_STIR' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'WHITE' 'TOKEN_FOR' 'WHITE' 'INTEGER' 'WHITE' 'TOKEN_MINUTES' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_BOWL_INT, $5, $9, null, NodeSubtype.STIR);}
	;
	
stirIngredientIntoMixingBowl
	: 'TOKEN_STIR' 'WHITE' identifier 'WHITE' 'TOKEN_INTO' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_INGR_BOWL, $3, $9, null, NodeSubtype.STIR_INTO);}
	;
	
mixMixingBowlWell
	: 'TOKEN_MIX' 'WHITE' 'TOKEN_WELL' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, new ASTNode(NodeType.MIXING_BOWL, 1), null, null, NodeSubtype.MIX);}
	| 'TOKEN_MIX' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'WHITE' 'TOKEN_WELL' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, $5, null, null, NodeSubtype.MIX);}
	;
	
cleanMixingBowl
	: 'TOKEN_CLEAN' 'WHITE' 'ORDINAL' 'WHITE' 'TOKEN_MIXING_BOWL' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, new ASTNode(NodeType.MIXING_BOWL, $3), null, null, NodeSubtype.CLEAN);}
	| 'TOKEN_CLEAN' 'WHITE' 'TOKEN_THE' 'WHITE' 'ORDINAL' 'WHITE' 'TOKEN_MIXING_BOWL' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, new ASTNode(NodeType.MIXING_BOWL, $5), null, null, NodeSubtype.CLEAN);}
	| 'TOKEN_CLEAN' 'WHITE' 'TOKEN_THE' 'WHITE' 'TOKEN_MIXING_BOWL' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, new ASTNode(NodeType.MIXING_BOWL, 1), null, null, NodeSubtype.CLEAN);}
	| 'TOKEN_CLEAN' 'WHITE' 'TOKEN_MIXING_BOWL' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_BOWL, new ASTNode(NodeType.MIXING_BOWL, 1), null, null, NodeSubtype.CLEAN);}
	;
	
pourContentsIntoBakingDish
	: 'TOKEN_POUR' 'WHITE' 'TOKEN_CONTENTS' 'WHITE' 'TOKEN_OF' 'WHITE' 'TOKEN_THE' 'WHITE' targetMixingBowl 'WHITE' 'TOKEN_INTO' 'WHITE' targetBakingDish 'TOKEN_DOT' {$$ = new ASTNode(NodeType.BINARY_BOWL_DISH, $9, $13, null, NodeSubtype.POUR);}
	;
	
// Hack: sometimes the 'TOKEN_THE' may be omitted in English (example: reference implementation of the Fibonacci Numbers with Caramel Sauce)
// To handle this case, which would imply having two identifiers side-by-side,
// we only declare one identifier and split it ourselves into a verb and a ingredient identifier.
// The verb is considered to be the first "word" of the identifier (everything before the first space character).
actionLoopStart
	: upperIdentifier 'WHITE' 'TOKEN_THE' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.LOOP, $1, $5, null, NodeSubtype.START);}
	| upperIdentifier 'TOKEN_DOT' {
		var index = $1.val1.indexOf(' ');
	$$ = new ASTNode(NodeType.LOOP, new ASTNode(NodeType.IDENTIFIER, $1.val1.substring(0, index)), new ASTNode(NodeType.IDENTIFIER, $1.val1.substring(index + 1)), null, NodeSubtype.START);}
	;
	
actionLoopEnd
	: upperIdentifier 'WHITE' 'TOKEN_UNTIL' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.LOOP, $5, $1, null, NodeSubtype.END);}
	| upperIdentifier 'WHITE' 'TOKEN_THE' 'WHITE' identifier 'WHITE' 'TOKEN_UNTIL' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.LOOP, $9, $5, $1, NodeSubtype.END);}
	;
	
setAside
	: 'TOKEN_SET' 'WHITE' 'TOKEN_ASIDE' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.SET_ASIDE);}
	;
	
serveWith
	: 'TOKEN_SERVE' 'WHITE' 'TOKEN_WITH' 'WHITE' upperIdentifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_RECIPE, $5);}
	| 'TOKEN_SERVE' 'WHITE' 'TOKEN_WITH' 'WHITE' identifier 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_RECIPE, $5);}
	;
	
refrigerate
	: 'TOKEN_REFRIGERATE' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_INT, 0, null, null, NodeSubtype.REFRIGERATE);}
	| 'TOKEN_REFRIGERATE' 'WHITE' 'TOKEN_FOR' 'WHITE' 'INTEGER' 'WHITE' 'TOKEN_HOURS' 'TOKEN_DOT' {$$ = new ASTNode(NodeType.UNARY_INT, $5, null, null, NodeSubtype.REFRIGERATE);}
	;
	
servesDishes
	: 'TOKEN_SERVES' 'WHITE' 'INTEGER' 'TOKEN_DOT' 'TOKEN_NEWLINE' {$$ = new ASTNode(NodeType.UNARY_INT, $3, null, null, NodeSubtype.SERVES);}
	;
	