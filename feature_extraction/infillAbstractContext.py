from tqdm import tqdm
import os
from pathlib import Path

from antlr4 import *
from solidity_parser.solidity_antlr4.SolidityLexer import SolidityLexer
from solidity_parser.solidity_antlr4.SolidityParser import SolidityParser
from solidity_parser.solidity_antlr4.SolidityVisitor import SolidityVisitor

class RequireVisitor(SolidityVisitor):
    def __init__(self):
        self.locations = []
        self.current_contract = None
        self.current_function = None
        self.current_block = None
        self.blocks = []

    def visitBlock(self, ctx: SolidityParser.BlockContext):
        block = (ctx.start.line, ctx.start.column, ctx.stop.line, ctx.stop.column)

        if self.check_nested(block):
            pass
        else:
            self.current_block = block
            self.blocks += [{
                'start_line': ctx.start.line,
                'start_column': ctx.start.column,
                'end_line': ctx.stop.line,
                'end_column': ctx.stop.column,
            }]        
        return self.visitChildren(ctx)
    
    def check_nested(self, block):
        if self.current_block:
            if block[0] > self.current_block[0]:
                if block[2] < self.current_block[2]:
                    return True
                if block[2] == self.current_block[2] and block[3] < self.current_block[3]:
                    return True
            if block[0] == self.current_block[0] and block[1] > self.current_block[1]:
                if block[2] < self.current_block[2]:
                    return True
                if block[2] == self.current_block[2] and block[3] < self.current_block[3]:
                    return True

        return False

    
    def visitContractDefinition(self, ctx: SolidityParser.ContractDefinitionContext):
        self.current_contract = (ctx.start.line, ctx.stop.line)

        return self.visitChildren(ctx)
    
        
    def visitFunctionDefinition(self, ctx:SolidityParser.FunctionDefinitionContext):

        self.current_function = (ctx.start.line, ctx.stop.line)
        return super().visitFunctionDefinition(ctx)

    
    def visitModifierDefinition(self, ctx: SolidityParser.ModifierDefinitionContext):

        self.current_function = (ctx.start.line, ctx.stop.line)

        return super().visitModifierDefinition(ctx)


    def visitExpressionStatement(self, ctx:SolidityParser.ExpressionStatementContext):
        text = ctx.getText()
        if 'require' in text:
            try: 
                children = [child for child in ctx.getChild(0).getChild(2).getChild(0).getChildren() if child.getText() != 'require']
                if len(children) == 3:
                    pred, _, comment = children
                if len(children) == 1:
                    pred = children[0]
                
                start = ctx.start
                stop = ctx.stop
                self.locations.append({
                    'require': {
                        'start_line': start.line,
                        'start_column': start.column,
                        'end_line': stop.line,
                        'end_column': stop.column,
                        'text': text,
                        'predicate': pred.getText(),
                        'comment': comment.getText() if len(children) == 3 else None
                    },
                    'contract': {
                        'start_line': self.current_contract[0],
                        'end_line': self.current_contract[1]
                    },
                    'function': {
                        'start_line': self.current_function[0],
                        'end_line': self.current_function[1]
                    },
                    'block': {
                        'start_line': self.current_block[0],
                        'start_column': self.current_block[1],
                        'end_line': self.current_block[2],
                        'end_column': self.current_block[3]
                    }
                })
            except:
                print(ctx.getText())



def parse(text):
    if not text:
        return None
    input_stream = InputStream(text)
    lexer = SolidityLexer(input_stream)
    token_stream = CommonTokenStream(lexer)
    parser = SolidityParser(token_stream, output=None)
    visitor = RequireVisitor()
    tree = parser.sourceUnit()

    visitor.visit(tree)    


    return visitor.locations, visitor.blocks


def abstract_context_invariants(file_path, result_folder, token):
    Path(result_folder).mkdir(parents=True, exist_ok=True)
    print(file_path)

    with open(file_path, 'r', encoding="utf-8") as f:
        text = f.read()
        locations, blocks = parse(text)

    abstract = create_abstracts(blocks, text)

    for i, location in enumerate(locations):
        # rewrite block in abstract
        
        context = rewrite_block(location['block'], text, abstract)

        infilled = change_requirement_statement(location, token, text, context)


        with open(os.path.join(result_folder, file_path.split('/')[-1][:-4] + f'_{i}.sol' ), 'w', encoding="utf-8", ) as f:
            f.write(infilled)
    
    with open(os.path.join(result_folder, file_path.split('/')[-1][:-4] + '_abstract.sol' ), 'w', encoding="utf-8", ) as f:
        f.write(abstract)
    with open(os.path.join(result_folder, file_path.split('/')[-1][:-4] + '_original.sol' ), 'w', encoding="utf-8", ) as f:
        f.write(text)



def change_require_statements_string(text, token):
    locations, blocks = parse(text)
    result = []
    
    abstract = create_abstracts(blocks, text)

    for i, location in enumerate(locations):
        
        context = rewrite_block(location['block'], text, abstract)

        infilled = change_requirement_statement(location, token, text, context)

        require = location['require']['text']
        predicate = location['require']['predicate']
        comment = location['require']['comment']

        result.append(('\n'.join(infilled) + "\n", require[8:], predicate, comment))
    return result



def create_abstracts(blocks, text):
    lines = text.split('\n')

    for block in blocks:
        start_line = block['start_line'] - 1
        start_column = block['start_column'] + 1
        end_line = block['end_line'] - 1
        end_column = block['end_column']
    
        if start_line == end_line:
            lines[start_line ] = lines[start_line][:start_column] + ' ' * (end_column - start_column) + lines[start_line][end_column:]
        else:
            lines[start_line] = lines[start_line].replace(lines[start_line][start_column:], ' ' * len(lines[start_line ][start_column:]))
            lines[end_line] = lines[end_line].replace(lines[end_line][:end_column], ' ' * len(lines[end_line][:end_column]))
            lines[start_line + 1:end_line] = [' ' * len(line) for line in lines[start_line + 1:end_line]]

    return '\n'.join(lines)


def rewrite_block(block, original_text, abstract):
    start_line = block['start_line'] - 1
    start_column = block['start_column']
    end_line = block['end_line']
    end_column = block['end_column']

    abs_lines = abstract.split('\n')
    org_lines = original_text.split('\n')

    if start_line == end_line:
        abs_lines[start_line ] = abs_lines[start_line][:start_column] + org_lines[start_column:end_column] + abs_lines[start_line][end_column:]
    else:
        abs_lines[start_line] = abs_lines[start_line].replace(abs_lines[start_line][start_column:], org_lines[start_line][start_column:])
        abs_lines[end_line] = abs_lines[end_line].replace(abs_lines[end_line][:end_column], org_lines[end_line][:end_column])
        abs_lines[start_line:end_line] = org_lines[start_line:end_line]

    return '\n'.join(abs_lines)



def change_requirement_statement(location, token, original_text, abstract):
    start_line = location['require']['start_line']
    start_column = location['require']['start_column']
    end_line = location['require']['end_line']
    end_column = location['require']['end_column']

    abs_lines = abstract.split('\n')
    org_lines = original_text.split('\n')

    if start_line == end_line:
        abs_lines[start_line - 1] = org_lines[start_line - 1][:start_column] + token + org_lines[start_line - 1][end_column + 1:]
    else:
        abs_lines[start_line - 1] = org_lines[start_line - 1][:start_column] + token
        abs_lines[start_line:end_line-1] = ['' for _ in range(start_line, end_line - 1)]
        abs_lines[end_line - 1] = org_lines[end_line - 1][end_column + 1:]

    non_empty_lines = [line for line in abs_lines if line.strip() != '']
    
    return '\n'.join(non_empty_lines)
        
        


def main():
    for f in tqdm(os.listdir("/Users/gabrielemorello/Code/FLAMES/feature_extraction/sources")):
        if f.endswith("36.sol"):
            abstract_context_invariants(f"/Users/gabrielemorello/Code/FLAMES/feature_extraction/sources/{f}", f"./results/{f}/", "require(<FILL_ME>);")

if __name__ == "__main__":
    main()

