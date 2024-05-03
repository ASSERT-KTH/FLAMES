#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# part of https://github.com/ConsenSys/python-solidity-parser
# derived from https://github.com/federicobond/solidity-parser-antlr/
#


from antlr4 import *
from solidity_parser.solidity_antlr4.SolidityLexer import SolidityLexer
from solidity_parser.solidity_antlr4.SolidityParser import SolidityParser
from solidity_parser.solidity_antlr4.SolidityVisitor import SolidityVisitor

import threading
import queue


class Node(dict):
    """
    provide a dict interface and object attrib access
    """
    ENABLE_LOC = False
    NONCHILD_KEYS = ("type","name","loc")

    def __init__(self, ctx, **kwargs):
        for k, v in kwargs.items():
            self[k] = v

        if Node.ENABLE_LOC:
            self["loc"] = Node._get_loc(ctx)

    def __getattr__(self, item):
        return self[item]  # raise exception if attribute does not exist

    def __setattr__(self, name, value):
        self[name] = value

    @staticmethod
    def _get_loc(ctx):
        return {
            'start': {
                'line': ctx.start.line,
                'column': ctx.start.column
            },
            'end': {
                'line': ctx.stop.line,
                'column': ctx.stop.column
            }
        }


class AstVisitor(SolidityVisitor):

    def __init__(self):
        self.require_locations = []

    def _mapCommasToNulls(self, children):
        if not children or len(children) == 0:
            return []

        values = []
        comma = True

        for el in children:
            if comma:
                if el.getText() == ',':
                    values.append(None)
                else:
                    values.append(el)
                    comma = False
            else:
                if el.getText() != ',':
                    raise Exception('expected comma')

                comma = True

        if comma:
            values.append(None)

        return values

    def _createNode(self, **kwargs):
        ## todo: add loc!
        return Node(**kwargs)

    def visit(self, tree):
        """
        override the default visit to optionally accept a range of children nodes

        :param tree:
        :return:
        """
        if tree is None:
            return None
        elif isinstance(tree, list):
            return self._visit_nodes(tree)
        else:
            print(tree)
            if isinstance(tree, SolidityParser.ExpressionStatementContext) and tree.getText() != 'require' and 'require' in tree.getText():
                self.require_locations.append((tree.start.line, tree.start.column, tree.stop.line, tree.stop.column))
            return super().visit(tree)

    def _visit_nodes(self, nodes):
        """
        modified version of visitChildren() that returns an array of results

        :param nodes:
        :return:
        """
        allresults = []
        result = self.defaultResult()
        for c in nodes:
            childResult = c.accept(self)
            result = self.aggregateResult(result, childResult)
            allresults.append(result)
        return allresults




def parse(text, start="sourceUnit", loc=False, strict=False):
    print("parsing")
    from antlr4.InputStream import InputStream
    from antlr4 import FileStream, CommonTokenStream

    input_stream = InputStream(text)

    lexer = SolidityLexer(input_stream)
    token_stream = CommonTokenStream(lexer)
    parser = SolidityParser(token_stream)
    sol = SolidityVisitor()
    print(sol)
    ast = AstVisitor()

    Node.ENABLE_LOC = loc

    ast.visit(getattr(parser, start)())

    return ast.require_locations


def parse_file(path, start="sourceUnit", loc=False, strict=False):
    with open(path, 'r', encoding="utf-8") as f:
        return parse(f.read(), start=start, loc=loc, strict=strict)



def visit(node, callback_object):
    """

    Walks the AST produced by parse/parse_file and calls callback_object.visit<Node.type>

    :param node: ASTNode returned from parse()
    :param callback: an object implementing the visitor pattern
    :return:
    """

    if node is None or not isinstance(node, Node):
        return node

    # call callback if it is available
    if hasattr(callback_object, "visit"+node.type):
        getattr(callback_object, "visit"+node.type)(node)

    for k,v in node.items():
        if k in node.NONCHILD_KEYS:
            # skip non child items
            continue

        # item is array?
        if isinstance(v, list):
            [visit(child, callback_object) for child in v]
        else:
            visit(v, callback_object)


def objectify(start_node):
    """
    Create an OOP like structure from the tree for easy access of most common information

    sourceUnit
       .pragmas []
       .imports []
       .contracts { name: contract}
           .statevars
           .enums
           .structs
           .functions
           .modifiers
           .

    :param tree:
    :return:
    """

    current_contract = None
    current_function = None

    class ObjectifyContractVisitor(object):

        def __init__(self, node):
            self._node = node
            self.name = node.name

            self.dependencies = []
            self.stateVars = {}
            self.names = {}
            self.enums = {}
            self.structs = {}
            self.mappings = {}
            self.events = {}
            self.modifiers = {}
            self.functions = {}
            self.constructor = None
            self.inherited_names = {}


        def visitEnumDefinition(self, _node):
            self.enums[_node.name]=_node
            self.names[_node.name]=_node

        def visitStructDefinition(self, _node):
            self.structs[_node.name]=_node
            self.names[_node.name]=_node

        def visitStateVariableDeclaration(self, _node):

            class VarDecVisitor(object):

                def __init__(self, current_contract):
                    self._current_contract = current_contract

                def visitVariableDeclaration(self, __node):
                    self._current_contract.stateVars[__node.name] = __node
                    self._current_contract.names[__node.name] = __node

            visit(_node, VarDecVisitor(self))

        def visitEventDefinition(self, _node):

            class EventFunctionVisitor(object):
                def __init__(self, node):
                    self.arguments = {}
                    self.declarations = {}
                    self._node = node

                def visitVariableDeclaration(self, __node):
                    self.arguments[__node.name] = __node
                    self.declarations[__node.name] = __node

            current_function = EventFunctionVisitor(_node)
            visit(_node, current_function)
            self.names[_node.name] = current_function
            self.events[_node.name] = current_function


        def visitFunctionDefinition(self, _node, _definition_type=None):

            class FunctionObject(object):

                def __init__(self, node):
                    self._node = node
                    if(node.type=="FunctionDefinition"):
                        self.visibility = node.visibility
                        self.stateMutability = node.stateMutability
                        self.isConstructor = node.isConstructor
                        self.isFallback = node.isFallback
                        self.isReceive = node.isReceive
                    self.arguments = {}
                    self.returns = {}
                    self.declarations = {}
                    self.identifiers = []
                    
                    

            class FunctionArgumentVisitor(object):

                def __init__(self):
                    self.parameters = {}

                def visitParameter(self, __node):
                    self.parameters[__node.name] = __node

            class VarDecVisitor(object):

                def __init__(self):
                    self.variable_declarations = {}

                def visitVariableDeclaration(self, __node):
                    self.variable_declarations[__node.name] = __node

            class IdentifierDecVisitor(object):

                def __init__(self):
                    self.idents = []

                def visitIdentifier(self, __node):
                    self.idents.append(__node)

                def visitAssemblyCall(self, __node):
                    self.idents.append(__node)

            current_function = FunctionObject(_node)
            self.names[_node.name] = current_function
            if _definition_type=="ModifierDefinition":
                self.modifiers[_node.name] = current_function
            else:
                self.functions[_node.name] = current_function
                if current_function.isConstructor:
                    self.constructor = current_function

            ## get parameters
            funcargvisitor = FunctionArgumentVisitor()
            visit(_node.parameters, funcargvisitor)
            current_function.arguments = funcargvisitor.parameters
            current_function.declarations.update(current_function.arguments)


            ## get returnParams
            if _node.get("returnParameters"):
                # because modifiers dont
                funcargvisitor = FunctionArgumentVisitor()
                visit(_node.returnParameters, funcargvisitor)
                current_function.returns = funcargvisitor.parameters
                current_function.declarations.update(current_function.returns)


            ## get vardecs in body
            vardecs = VarDecVisitor()
            visit(_node.body, vardecs)
            current_function.declarations.update(vardecs.variable_declarations)

            ## get all identifiers
            idents = IdentifierDecVisitor()
            visit(_node, idents)
            current_function.identifiers = idents

        def visitModifierDefinition(self, _node):
            return self.visitFunctionDefinition(_node, "ModifierDefinition")


    class ObjectifySourceUnitVisitor(object):

        def __init__(self, node):
            self._node = node
            self.imports = []
            self.pragmas = []
            self.contracts = {}

            self._current_contract = None

        def visitPragmaDirective(self, node):
            self.pragmas.append(node)

        def visitImportDirective(self, node):
            self.imports.append(node)

        def visitContractDefinition(self, node):
            self.contracts[node.name] = ObjectifyContractVisitor(node)
            self._current_contract = self.contracts[node.name]

            # subparse the contracts //slightly inefficient but more readable :)
            visit(node, self.contracts[node.name])

    objectified_source_unit = ObjectifySourceUnitVisitor(start_node)
    visit(start_node, objectified_source_unit)
    return objectified_source_unit
