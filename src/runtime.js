var ast = require('./ast')
var fs = require('fs');
var chefParser = require('../chef');
var readline = require('readline');
var stream = require('stream');

var ASTNode = ast.ASTNode;
var NodeType = ast.NodeType;
var NodeSubtype = ast.NodeSubtype;
var isDry = ast.isDry;

// -- RUNTIME --

function readIntFromSTDIN() {
	var buffer = new Buffer(32);
	var ans = '';
	
	process.stdout.write('Enter an integer: ');
	
	while(1) {
	
		var byteRead = fs.readSync(process.stdin.fd, buffer, 0, 32, null);
		ans = buffer.toString('utf8').substr(0, byteRead-1).replace(' ', '');
	
		if (parseInt(ans) + '' != 'NaN') {
			break;
		}
		
	}
	
	return parseInt(ans);
}

//readIntFromSTDIN()

function copy(obj) {
	return JSON.parse(JSON.stringify(obj));
}

function WorkSpace(recipeList)
{
	this.isAWorkSpace = true;

	this.ingredients = [];
	this.bowls = [];
	this.dishes = [];
	this.loopStack = [];
	this.searchForLoopEnd = false;
	this.recipes = {};
	
	if (recipeList.isAWorkSpace) {
		this.copyWorkSpace(recipeList);
		return;
	}
	
	this.bowls[1] = [];
	this.dishes[1] = [];

	for (var i = 0; i < recipeList.length; ++i) {
		this.recipes[recipeList[i].val1.title.val1.val1.toLowerCase()] = recipeList[i];
	}
}

WorkSpace.prototype.copyWorkSpace = function(other) {
	for (var i = 0; i < other.bowls.length; ++i) {
		if (other.bowls[i] + '' !== 'undefined') {
			this.bowls[i] = [];
			for (var j = 0; j < other.bowls[i].length; ++j) {
				this.bowls[i].push(copy(other.bowls[i][j]));
			}
		}
	}
	for (var i = 0; i < other.dishes.length; ++i) {
		if (other.dishes[i] + '' !== 'undefined') {
			this.dishes[i] = [];
			for (var j = 0; j < other.dishes[i].length; ++j) {
				this.dishes[i].push(copy(other.dishes[i][j]));
			}
		}
	}

	this.recipes = other.recipes;
}

WorkSpace.prototype.getRecipe = function(recipeName) {
	if (this.recipes[recipeName.toLowerCase()] + '' !== 'undefined') {
		return this.recipes[recipeName.toLowerCase()];
	}
	
	console.log('Error: could not find recipe ' + recipeName);
	process.exit();
}

WorkSpace.prototype.toString = function() {
	var str = '-- Workspace --\n\n';
	
	str += 'Ingredients\n';
	if (this.ingredients.length > 0) {
		for (var i = 0; i < this.ingredients.length; ++i) {
			str += '- ' + this.ingredients[i] + '\n';
		}
	}
	else {
		str += 'No ingredients here.\n'
	}


	str += '\nBowls\n';
	for(var i = 0; i < this.bowls.length; ++i) {
		if (this.bowls[i] + '' === 'undefined') continue;
		str += 'Bowl ' + i + ': [';
		for(var j = 0; j < this.bowls[i].length; ++j) 
			str += (j>0?', ':'') + this.bowls[i][j].quantity + (this.bowls[i][j].state?'':'l');
		str += ']\n';
	}


	str += '\nDishes\n';
	for(var i = 0; i < this.dishes.length; ++i) {
		if (this.dishes[i] + '' === 'undefined') continue;
		str += 'Dish ' + i + ': [';
		for(var j = 0; j < this.dishes[i].length; ++j) 
			str += (j>0?', ':'') + this.dishes[i][j].quantity + (this.dishes[i][j].state?'':'l');
		str += ']\n';
	}


	
	str += '\n';
	
	return str;
}

WorkSpace.prototype.getIngredient = function(name) {
	for(var i in this.ingredients) {
		if (this.ingredients[i].id == name) {
			return this.ingredients[i];
		}
	}
	
	var ingr = new Ingredient(name, 0, true);
	this.ingredients.push(ingr);
	
	return ingr;	
}

WorkSpace.prototype.getBowl = function(i) {
	if (this.bowls[i] + '' === 'undefined') {
		this.bowls[i] = [];
	}
	
	return this.bowls[i];
}

WorkSpace.prototype.getDish = function(i) {
	if (this.dishes[i] + '' === 'undefined') {
		this.dishes[i] = [];
	}
	
	return this.dishes[i];
}

WorkSpace.prototype.rollBowl = function(bowlNum, depth) {
	var bowl = this.getBowl(bowlNum);
	if (bowl.length <= 0) return;
	var ingr = bowl.pop();
	bowl.splice(Math.max(0, bowl.length - depth), 0, ingr);
}

WorkSpace.prototype.pourBowlIntoDish = function(bowlNum, dishNum) {
var bowl = this.getBowl(bowlNum);
var dish = this.getDish(dishNum);

for(var i = 0; i < bowl.length; ++i) {
	dish.push(bowl[i]);
}

}

WorkSpace.prototype.pushLoopStart = function(actionVerb, ingrName, currExePoint) {
this.loopStack.push({verb: actionVerb, ingr:this.getIngredient(ingrName), startExePoint: currExePoint});
//console.log(this.loopStack[this.loopStack.length - 1]);
this.performLoopCheck();
//console.log('searching for the end ' + this.searchForLoopEnd);
}

function matchVerbWithPreterit (verb, preterit) {
var matching = false;

matching |= (verb.toLowerCase() + 'ed') == preterit.toLowerCase();
matching |= (verb.toLowerCase() + 'd') == preterit.toLowerCase();

return matching;
}

WorkSpace.prototype.checkLoopEnd = function(preteritVerb, ingrName, currExePoint) {
//console.log(this.loopStack);
if (matchVerbWithPreterit(this.loopStack[this.loopStack.length - 1].verb, preteritVerb)) {
	//console.log('Matching loop end');
	if (ingrName != null) {
		var ingr = this.getIngredient(ingrName);
		ingr.quantity = Math.max(0, ingr.quantity - 1);
		
	}
	this.performLoopCheck();
	
	if (this.searchForLoopEnd) {
		this.searchForLoopEnd = false;
		return currExePoint;
	}


	return this.loopStack[this.loopStack.length - 1].startExePoint;

}
else {
	//console.log('Non matching loop end: ' + this.loopStack[this.loopStack.length - 1].verb + ' vs. ' +  preteritVerb);
	return -1;
}
}

WorkSpace.prototype.performLoopCheck = function(currExePoint) {
//console.log('Check (' + this.loopStack[this.loopStack.length - 1].verb + '): ' + this.loopStack[this.loopStack.length - 1].ingr.quantity);
if (this.loopStack[this.loopStack.length - 1].ingr.quantity == 0) {
this.searchForLoopEnd = true;
//console.log('Check found 0, stopping the loop');
}
}

// See http://bost.ocks.org/mike/shuffle/
WorkSpace.prototype.shuffleBowl = function(bowlNum) {
var bowl = this.getBowl(bowlNum);
var leftToShuffle = bowl.length;
var tempIngr, indToShuffle;

while (leftToShuffle) {
indToShuffle = Math.floor(Math.random() * leftToShuffle--);

tempIngr = bowl[leftToShuffle];
bowl[leftToShuffle] = bowl[indToShuffle];
bowl[indToShuffle] = tempIngr;
}
}

WorkSpace.prototype.cleanBowl = function(bowlNum) {
var bowl = this.getBowl(bowlNum);
bowl.splice(0, bowl.length);
}

WorkSpace.prototype.printDish = function(dishNum) {
	var dish = this.getDish(dishNum);
	
	var buffer = '';
	
	for (var i = dish.length - 1; i >= 0; --i) {
		if (dish[i].state) {
			buffer += '' + dish[i].quantity;
		}
		else {
			buffer += String.fromCharCode(dish[i].quantity);
		}
	}
	
	process.stdout.write(buffer);
}

WorkSpace.prototype.printDishes = function(num) {
var ind = 1;
while (ind <= num) {
	this.printDish(ind);	
	++ind;
}
}

function Ingredient(id, quantity, state)
{
	this.id = id;
	this.quantity = quantity;
	this.state = state;
}

Ingredient.prototype.toString = function() {
	return this.id + ' (' + this.state?"solid":"liquid" + '): ' + this.quantity; 
}

// By convention, we will only execute the first recipe from the list
// All other recipes are considered as auxilliary recipes
function executeRecipe(recipeList, workspace) {
if (recipeList.length <= 0) {
console.log("I ain't got no recipes...");
return;
}

var recipe = recipeList[0];
//console.log('Executing recipe ' + recipeList[0].val1.title.val1.val1);

// Declare ingredients
for (var i = recipe.val2.ingredients.val1.length - 1; i >= 0 ; --i) {
	workspace.ingredients.push(new Ingredient(recipe.val2.ingredients.val1[i].val1.val1,
											  recipe.val2.ingredients.val1[i].val2,
											  recipe.val2.ingredients.val1[i].val3));
}

//console.log('' + workspace);

// Execute commands
var exePoint = 0;

for (;exePoint < recipe.val2.method.val1.length; ++exePoint) {
	exePoint = executeCommand(workspace, recipe.val2.method.val1[exePoint], exePoint);
	
	if (exePoint < 0) {
		break;
	}
}

// 'Refrigerate' overrides the 'Serves' statement, and
// we check that it was the command which got us out of
// the loop by checking the last exePoint value
if (exePoint != -2) {
executeCommand(workspace, recipe.val2.serve, 0);
}


}

function executeCommand(workspace, command, exePoint) {

//console.log('Executing command ' + command.type + ' ' + command.subtype + ' ' + command.val1 + ' ' + command.val2 + ' ' + command.val3);

if (false && command.type == 14) {
console.log(''+workspace);

	for (var i  =0; i < workspace.ingredients.length; ++i) {
		if ('' + workspace.ingredients[i].quantity === 'undefined') {
			console.log('NOPE');
			process.exit(0);
		}
	}
}

if (workspace.searchForLoopEnd) {
	//console.log('Searching for the end of the loop');
	if (command.type == NodeType.LOOP && command.subtype == NodeSubtype.END) {
		//console.log('Testing potential loop end');
		var tempExePoint = executeCommand_LOOP(workspace, command, exePoint);
		if (tempExePoint != -1) {
			return tempExePoint;
		}
		
	}
	else {
		//console.log('Nope, ignoring command');
	}
	
	return exePoint;
}	

switch(command.type) {
case NodeType.UNARY_INGR:
return executeCommand_UNARY_INGR(workspace, command, exePoint);
break;

case NodeType.BINARY_INGR_BOWL:
return executeCommand_BINARY_INGR_BOWL(workspace, command, exePoint);
break;

case NodeType.UNARY_BOWL:
return executeCommand_UNARY_BOWL(workspace, command, exePoint);
break;

case NodeType.BINARY_BOWL_INT:
return executeCommand_BINARY_BOWL_INT(workspace, command, exePoint);
break;

case NodeType.BINARY_BOWL_DISH:
return executeCommand_BINARY_BOWL_DISH(workspace, command, exePoint);
break;

case NodeType.LOOP:
var tempExe = executeCommand_LOOP(workspace, command, exePoint);
if(exePoint == -1) {
	console.log('Error: non-matching loop terminator, ' + command.val1.val1 + ' while ' + workspace.loopStack[workspace.loopStack.length - 1].verb.toLowerCase() + 'ed' + ' was expected');
	process.exit();
}
return tempExe;
break;

case NodeType.UNARY_RECIPE:
return executeCommand_UNARY_RECIPE(workspace, command, exePoint);
break;

case NodeType.SET_ASIDE:
workspace.searchForLoopEnd = true;
break;

case NodeType.UNARY_INT:
return executeCommand_UNARY_INT(workspace, command, exePoint);
break;

default:
console.log('COMMAND NOT YET IMPLEMENTED ' + command.type + ' ' + command.subtype);
break;
}


return exePoint;
}

function executeCommand_UNARY_INGR(workspace, command, exePoint) {

switch(command.subtype) {
case NodeSubtype.TAKE_FROM_REFRIGERATOR:

var ingredient = workspace.getIngredient(command.val1.val1);

//console.log('TODO: read integer from stdin');
//console.log('GOT INGR ' + readIntFromSTDIN());

ingredient.quantity = readIntFromSTDIN();

break;

case NodeSubtype.LIQUEFY_INGR:
workspace.getIngredient(command.val1.val1).state = false;
break;
}

return exePoint;
}

function executeCommand_BINARY_INGR_BOWL(workspace, command, exePoint) {

switch(command.subtype) {
case NodeSubtype.PUT:

workspace.getBowl(command.val2.val1).push(JSON.parse(JSON.stringify(workspace.getIngredient(command.val1.val1))));


break;
case NodeSubtype.FOLD:
//console.log('BEFORE'+workspace);
workspace.getIngredient(command.val1.val1).quantity = workspace.getBowl(command.val2.val1).pop().quantity;
//console.log('AFTER'+workspace);

break;
case NodeSubtype.ADD:
var ingredient = workspace.getIngredient(command.val1.val1);
var bowl = workspace.getBowl(command.val2.val1);

var targetIngr = copy(ingredient);

if (bowl.length > 0) {
	targetIngr.quantity = parseInt(targetIngr.quantity) + parseInt(bowl[bowl.length-1].quantity);
}
bowl.push(targetIngr);
break;
case NodeSubtype.REMOVE:
var ingredient = workspace.getIngredient(command.val1.val1);
var bowl = workspace.getBowl(command.val2.val1);

var targetIngr = copy(ingredient);

if (bowl.length > 0) {
	targetIngr.quantity = Math.max(0, bowl[bowl.length-1].quantity - targetIngr.quantity);
}
else {
	targetIngr.quantity = 0;
}
bowl.push(targetIngr);

break;
case NodeSubtype.COMBINE:
var ingredient = workspace.getIngredient(command.val1.val1);
var bowl = workspace.getBowl(command.val2.val1);

var targetIngr = copy(ingredient);

if (bowl.length > 0) {
	targetIngr.quantity *= bowl[bowl.length-1].quantity;
}
else {
	targetIngr.quantity = 0;
}
bowl.push(targetIngr);
break;
case NodeSubtype.DIVIDE:
var ingredient = workspace.getIngredient(command.val1.val1);
var bowl = workspace.getBowl(command.val2.val1);

var targetIngr = copy(ingredient);

if (bowl.length > 0 && bowl[bowl.length-1].quantity) {
	// (a/b>>0) is the fastest way to get integer diuvison in JavaScript
	// see http://stackoverflow.com/questions/4228356/integer-division-in-javascript
	targetIngr.quantity = (bowl[bowl.length-1].quantity / targetIngr.quantity >> 0);
}
else {
	console.log('Error: division by 0');
	process.exit();
}
bowl.push(targetIngr);

break;
case NodeSubtype.STIR_INTO:
var ingredient = workspace.getIngredient(command.val1.val1);
workspace.rollBowl(command.val2.val1, ingredient.quantity);
break;
}

return exePoint;
}

function executeCommand_UNARY_BOWL(workspace, command, exePoint) {

switch(command.subtype) {
case NodeSubtype.ADD_DRY:
var ingr = new Ingredient("Dry", 0, true);
for (var i = 0; i < workspace.ingredients.length; ++i)
{
	if (workspace.ingredients[i].state)
	{
		ingr.quantity += parseInt(workspace.ingredients[i].quantity);
	}
}
workspace.getBowl(command.val1.val1).push(ingr);
break;
case NodeSubtype.LIQUEFY_BOWL:
var bowl = workspace.getBowl(command.val1.val1);

for(var i = 0; i < bowl.length; ++i) {
	bowl[i].state = false;
}


break;
case NodeSubtype.MIX:
workspace.shuffleBowl(command.val1.val1);
break;
case NodeSubtype.CLEAN:
workspace.cleanBowl(command.val1.val1);
break;
}

return exePoint;
}

function executeCommand_BINARY_BOWL_INT(workspace, command, exePoint) {
switch(command.subtype) {
case NodeSubtype.STIR:
workspace.rollBowl(command.val1.val1, command.val2);
break;
}

return exePoint;

}

function executeCommand_BINARY_BOWL_DISH(workspace, command, exePoint) {
switch(command.subtype) {
case NodeSubtype.POUR:
workspace.pourBowlIntoDish(command.val1.val1, command.val2.val1);
break;
}

return exePoint;

}

function executeCommand_LOOP(workspace, command, exePoint) {
switch(command.subtype) {
case NodeSubtype.START:
//console.log(command)
workspace.pushLoopStart(command.val1.val1, command.val2.val1, exePoint);
break;
case NodeSubtype.END:
exePoint = workspace.checkLoopEnd(command.val1.val1, command.val2.val1, exePoint);



break;
}

return exePoint;

}

function executeCommand_UNARY_RECIPE(workspace, command, exePoint) {
switch(command.subtype) {
default:

var subWorkSpace = new WorkSpace(workspace);
executeRecipe([workspace.getRecipe(command.val1.val1)], subWorkSpace);

var firstBowl = workspace.getBowl(1);
for (var i = 0; i < subWorkSpace.bowls[1].length; ++i) {
	firstBowl.push(subWorkSpace.bowls[1][i]);
}

//console.log('Returned from recipe call');

break;
}

return exePoint;

}

function executeCommand_UNARY_INT(workspace, command, exePoint) {

switch(command.subtype) {
case NodeSubtype.SERVES:
workspace.printDishes(command.val1);
break;
case NodeSubtype.REFRIGERATE:
workspace.printDishes(command.val1);
exePoint = -2;
break;
}

return exePoint;
}



// -- EXECUTION --

//console.log('Parsing ' + process.argv[2] + ' ...');
file = fs.readFileSync(process.argv[2], 'utf-8');
// Manual fix to prevent Windows user from
// crashing the compiler simply by using it.
file = file.replace(/\r\n/g, '\n');
var fileAst = chefParser.parse(file);

//console.log('Executing ' + process.argv[2] + ' ...');
var myWorkspace = new WorkSpace(fileAst);

//process.stdout.write('Parsed and ready to execute !');
//process.exit(0);
//console.log('' + myWorkspace);
executeRecipe(fileAst, myWorkspace);
//console.log('' + myWorkspace);

