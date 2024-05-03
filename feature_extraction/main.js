"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var fs = require("fs");
var path = require("path");
var parser = require('@solidity-parser/parser');
var n = 0;
function changeRequireStatements(filePath, resultFolder, token) {
    if (!fs.existsSync(resultFolder)) {
        fs.mkdirSync(resultFolder, { recursive: true });
    }
    var text = fs.readFileSync(filePath, 'utf-8');
    var ast = parser.parse(text, { loc: true });
    var locations = [];
    parser.visit(ast, {
        ExpressionStatement: function (node) {
            if (node.expression == null)
                return;
            if (node.expression.type === 'FunctionCall' && node.expression.expression.type === 'Identifier' && node.expression.expression.name === 'require') {
                // Add loc to the list of locations
                locations.push(node.loc);
            }
        },
    });
    locations.forEach(function (location, i) {
        var start = location.start, end = location.end;
        var lines = text.split('\n');
        if (start.line === end.line) {
            lines[start.line - 1] =
                lines[start.line - 1].substring(0, start.column) + token + lines[start.line - 1].substring(end.column + 1);
        }
        else {
            lines[start.line - 1] = lines[start.line - 1].substring(0, start.column) + token;
            lines[end.line - 1] = lines[end.line - 1].substring(end.column + 1);
            lines.splice(start.line, end.line - start.line - 1);
        }
        var resultFilePath = path.join(resultFolder, path.basename(filePath, path.extname(filePath)) + "_".concat(i, ".sol"));
        fs.writeFileSync(resultFilePath, lines.join('\n'), 'utf-8');
    });
}
function main() {
    var sourceFolderPath = '/Users/gabrielemorello/Code/FLAMES/feature_extraction/sources';
    var resultFolderPath = './results';
    fs.readdirSync(sourceFolderPath).forEach(function (file) {
        if (file.endsWith('.sol')) {
            var filePath = path.join(sourceFolderPath, file);
            changeRequireStatements(filePath, path.join(resultFolderPath, file), '<REQUIRE>');
        }
    });
}
if (require.main === module) {
    main();
}
