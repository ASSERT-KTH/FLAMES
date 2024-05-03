#[derive(Debug)]
enum Token {
    Identifier(String),
    Operator(String),
}

fn parse_expression(expression: &str) -> Vec<Token> {
    let mut tokens = Vec::new();
    let mut chars = expression.chars().peekable();

    while let Some(c) = chars.next() {
        match c {
            '+' => {
                if let Some(&'+') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("++".to_string()));
                } else if let Some(&'=') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("+=".to_string()));
                } else {
                    tokens.push(Token::Operator("+".to_string()));
                }
            }
            '-' => {
                if let Some(&'-') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("--".to_string()));
                } else if let Some(&'>') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("->".to_string()));
                } else if let Some(&'=') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("-=".to_string()));
                } else {
                    tokens.push(Token::Operator("-".to_string()));
                }
            }
            '*' => {
                if let Some(&'*') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("**".to_string()));
                } else if let Some(&'=') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("*=".to_string()));
                } else {
                    tokens.push(Token::Operator("*".to_string()));
                }
            }
            '&' => {
                if let Some(&'=') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("&=".to_string()));
                } else if let Some(&'&') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("&&".to_string()));
                } else {
                    tokens.push(Token::Operator("&".to_string()));
                }
            }
            '|' => {
                if let Some(&'=') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("|=".to_string()));
                } else if let Some(&'|') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("||".to_string()));
                } else {
                    tokens.push(Token::Operator("|".to_string()));
                }
            }
            '/' | '!' | '=' | '^' | '%' => {
                let mut op = String::new();
                op.push(c);
                if let Some(&'=') = chars.peek() {
                    op.push(chars.next().unwrap());
                }
                tokens.push(Token::Operator(op));   
            }
            '>' => {
                if let Some(&'>') = chars.peek() {
                    chars.next();
                    if let Some(&'=') = chars.peek() {
                        chars.next();
                        tokens.push(Token::Operator(">>=".to_string()));
                    } else {
                        tokens.push(Token::Operator(">>".to_string()));
                    }
                } else if let Some(&'=') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator(">=".to_string()));
                } else {
                    tokens.push(Token::Operator(">".to_string()));
                }
            }
            '<' => {
                if let Some(&'<') = chars.peek() {
                    chars.next();
                    if let Some(&'=') = chars.peek() {
                        chars.next();
                        tokens.push(Token::Operator("<<=".to_string()));
                    } else {
                        tokens.push(Token::Operator("<<".to_string()));
                    }
                } else if let Some(&'=') = chars.peek() {
                    chars.next();
                    tokens.push(Token::Operator("<=".to_string()));
                } else {
                    tokens.push(Token::Operator("<".to_string()));
                }
            }
            '?' => tokens.push(Token::Operator("?".to_string())),
            ':' => tokens.push(Token::Operator(":".to_string())),
            '~' => tokens.push(Token::Operator("~".to_string())),
            _ => {
                let mut id = String::new();
                id.push(c);
                while let Some(&next) = chars.peek() {
                    if "+-*/%&|^<>=!~?:".contains(next) {
                        break;
                    }
                    id.push(next);
                    chars.next();
                }
                tokens.push(Token::Identifier(id));
            }
        }
    }

    // treat 'new', 'after' and 'delete' as operators
    


    tokens
}

fn main() {
    let expressions = vec![
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
    ];

    for exp in expressions {
        println!("{:?}", parse_expression(exp));
    }
}
