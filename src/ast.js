
var ASTNode = function (type, val1, val2, val3, subtype) {
	this.type = type;
	this.val1 = val1;
	this.val2 = val2;
	this.val3 = val3;
	this.subtype = subtype;
}

var NodeType = function (){}

NodeType.TITLE = 0;
NodeType.INGREDIENTS = 1;
NodeType.INGREDIENT = 2;
NodeType.COOKING_TIME = 3;
NodeType.OVEN_TEMPERATURE = 4;
NodeType.METHOD = 5;
//NodeType.METHOD_LIST = 6;
NodeType.UNARY_INGR = 7;
NodeType.BINARY_INGR_BOWL = 8;
NodeType.UNARY_BOWL = 9;
NodeType.BINARY_BOWL_INT = 10;
NodeType.BINARY_BOWL_DISH = 11;
NodeType.LOOP = 12;
NodeType.SET_ASIDE = 13;
NodeType.UNARY_RECIPE = 14;
NodeType.UNARY_INT = 15;
NodeType.IDENTIFIER = 16;
NodeType.MIXING_BOWL = 17;
NodeType.BAKING_DISH = 18;
NodeType.RECIPE = 19;

var NodeSubtype = function () {}

NodeSubtype.TAKE_FROM_REFRIGERATOR = 0;
NodeSubtype.LIQUEFY_INGR = 1;
NodeSubtype.PUT = 2;
NodeSubtype.FOLD = 3;
NodeSubtype.ADD = 4;
NodeSubtype.REMOVE = 5;
NodeSubtype.COMBINE = 6;
NodeSubtype.DIVIDE = 7;
NodeSubtype.STIR_INTO = 8;
NodeSubtype.ADD_DRY = 9;
NodeSubtype.LIQUEFY_BOWL = 10;
NodeSubtype.MIX = 11;
NodeSubtype.CLEAN = 12;
NodeSubtype.STIR = 13;
NodeSubtype.POUR = 14;
NodeSubtype.SERVE_WITH = 15;
NodeSubtype.REFRIGERATE = 16;
NodeSubtype.SERVES = 17;
NodeSubtype.START = 18;
NodeSubtype.END = 19;

var isDry = function(measure, measureType) {
if (measureType + '' !== 'undefined') return true;

if (measure == 'g'
	|| measure == 'kg'
	|| measure == 'pinch'
	|| measure == 'pinches'
	// separator, below is my interpretation of the specifications
	|| measure == 'cup'
	|| measure == 'cups'
	|| measure == 'teaspoon'
	|| measure == 'teaspoons'
	|| measure == 'tablespoon'
	|| measure == 'tablespoons')
	return true;
	
	return false;
}

module.exports.ASTNode = ASTNode;
module.exports.NodeType = NodeType;
module.exports.NodeSubtype = NodeSubtype;
module.exports.isDry = isDry;





