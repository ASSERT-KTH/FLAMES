import * as fs from 'fs';
import * as path from 'path';

const parser = require('@solidity-parser/parser')




const n = 0;

function changeRequireStatements(filePath: string, resultFolder: string, token: string): void {
    if (!fs.existsSync(resultFolder)) {
        fs.mkdirSync(resultFolder, { recursive: true });
    }

    const text: string = fs.readFileSync(filePath, 'utf-8');

    const ast = parser.parse(text, { loc: true });

    const locations: any[] = [];

    parser.visit(ast, {
        ExpressionStatement: function (node) {
            if (node.expression == null) return;
            if (node.expression.type === 'FunctionCall' && node.expression.expression.type === 'Identifier' && node.expression.expression.name === 'require') {
                // Add loc to the list of locations
                locations.push(node.loc)


            }  
        },
    })
      


    locations.forEach((location: any, i: number) => {
        const { start, end } = location;
        const lines: string[] = text.split('\n');

        if (start.line === end.line) {
            lines[start.line - 1] =
                lines[start.line - 1].substring(0, start.column) + token + lines[start.line - 1].substring(end.column + 1);
        } else {
            lines[start.line - 1] = lines[start.line - 1].substring(0, start.column) + token;
            lines[end.line - 1] = lines[end.line - 1].substring(end.column + 1);
            lines.splice(start.line, end.line - start.line - 1);
        }

        const resultFilePath: string = path.join(resultFolder, path.basename(filePath, path.extname(filePath)) + `_${i}.sol`);
        fs.writeFileSync(resultFilePath, lines.join('\n'), 'utf-8');
    });
}

function main(): void {
    const sourceFolderPath: string = '/Users/gabrielemorello/Code/FLAMES/feature_extraction/sources';
    const resultFolderPath: string = './results';

    fs.readdirSync(sourceFolderPath).forEach((file: string) => {
        if (file.endsWith('.sol')) {
            const filePath: string = path.join(sourceFolderPath, file);
            changeRequireStatements(filePath, path.join(resultFolderPath, file), '<REQUIRE>');
        }
    });
}

if (require.main === module) {
    main();
}
