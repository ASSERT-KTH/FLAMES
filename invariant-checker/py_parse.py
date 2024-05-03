import re

class Token:
    def __init__(self, value):
        self.value = value

def parse_expression(expression):
    tokens = []
    i = 0

    while i < len(expression):
        c = expression[i]
        if c == '+':
            if i + 1 < len(expression) and expression[i + 1] == '+':
                tokens.append(Token("++"))
                i += 1
            else:
                tokens.append(Token("+"))
        elif c == '-':
            if i + 1 < len(expression) and expression[i + 1] == '-':
                tokens.append(Token("--"))
                i += 1
            elif i + 1 < len(expression) and expression[i + 1] == '>':
                tokens.append(Token("->"))
                i += 1
            else:
                tokens.append(Token("-"))
        elif c in ['*', '/', '%', '&', '|', '^', '<', '>', '!', '~']:
            op = c
            i += 1
            while i < len(expression) and expression[i] not in "+-*/%&|^<>=!~?:":
                op += expression[i]
                i += 1
            tokens.append(Token(op))
            continue
        elif c == '=':
            if i + 1 < len(expression) and expression[i + 1] == '=':
                tokens.append(Token("=="))
                i += 1
            else:
                tokens.append(Token("="))
        elif c == '|':
            if i + 1 < len(expression) and expression[i + 1] == '=':
                tokens.append(Token("|="))
                i += 1
            elif i + 1 < len(expression) and expression[i + 1] == '|':
                tokens.append(Token("||"))
                i += 1
            else:
                tokens.append(Token("|"))
        elif c == '>':
            if i + 1 < len(expression) and expression[i + 1] == '>':
                if i + 2 < len(expression) and expression[i + 2] == '=':
                    tokens.append(Token(">>="))
                    i += 2
                else:
                    tokens.append(Token(">>"))
                    i += 1
            elif i + 1 < len(expression) and expression[i + 1] == '=':
                tokens.append(Token(">="))
                i += 1
            else:
                tokens.append(Token(">"))
        elif c == '<':
            if i + 1 < len(expression) and expression[i + 1] == '<':
                if i + 2 < len(expression) and expression[i + 2] == '=':
                    tokens.append(Token("<<="))
                    i += 2
                else:
                    tokens.append(Token("<<"))
                    i += 1
            elif i + 1 < len(expression) and expression[i + 1] == '=':
                tokens.append(Token("<="))
                i += 1
            else:
                tokens.append(Token("<"))
        elif c == '?':
            tokens.append(Token("?"))
        elif c == ':':
            tokens.append(Token(":"))
        else:
            m = re.match(r'^[a-zA-Z_]\w*', expression[i:])
            if m:
                tokens.append(Token(m.group(0)))
                i += len(m.group(0)) - 1
            else:
                raise ValueError("Invalid expression")

        i += 1

    return tokens

expressions = [
    "expression",
    "expression++",
    "expression--",
    "new typeName",
    "expression[expression]",
    "expression(expression)",
    "expression.identifier",
    "(expression)",
    "++expression",
    "--expression",
    "+expression",
    "-expression",
    "after expression",
    "delete expression",
    "!expression",
    "~expression",
    "expression**expression",
    "expression*expression",
    "expression/expression",
    "expression%expression",
    "expression+expression",
    "expression-expression",
    "expression<<expression",
    "expression>>expression",
    "expression&expression",
    "expression^expression",
    "expression|expression",
    "expression<expression",
    "expression>expression",
    "expression<=expression",
    "expression>=expression",
    "expression==expression",
    "expression!=expression",
    "expression&&expression",
    "expression||expression",
    "expression?expression:expression",
    "expression=expression",
    "expression|=expression",
    "expression^=expression",
    "expression&=expression",
    "expression<<=expression",
    "expression>>=expression",
    "expression+=expression",
    "expression-=expression",
    "expression*=expression",
    "expression/=expression",
    "expression%=expression",
]

for exp in expressions:
    print([token.value for token in parse_expression(exp)])
