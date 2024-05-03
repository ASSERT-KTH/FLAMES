assert check_equivalence('x++', 'x++') == True
assert check_equivalence('new int', 'new int') == True
assert check_equivalence('x[0]', 'x[0]') == True
assert check_equivalence('foo()', 'foo()') == True
assert check_equivalence('x.y', 'x.y') == True
assert check_equivalence('(x)', '(x)') == True
assert check_equivalence('++x', '++x') == True
assert check_equivalence('+x', '+x') == True
assert check_equivalence('after x', 'after x') == True
assert check_equivalence('!x', '!x') == True
assert check_equivalence('~x', '~x') == True
assert check_equivalence('x ** y', 'x ** y') == True
assert check_equivalence('x * y', 'x * y') == True
assert check_equivalence('x + y', 'x + y') == True
assert check_equivalence('x << y', 'x << y') == True
assert check_equivalence('x & y', 'x & y') == True
assert check_equivalence('x ^ y', 'x ^ y') == True
assert check_equivalence('x | y', 'x | y') == True
assert check_equivalence('x < y', 'x < y') == True
assert check_equivalence('x == y', 'x == y') == True
assert check_equivalence('x && y', 'x && y') == True
assert check_equivalence('x || y', 'x || y') == True
assert check_equivalence('x ? y : z', 'x ? y : z') == True
assert check_equivalence('x = y', 'x = y') == True
assert check_equivalence('x |= y', 'x |= y') == True
assert check_equivalence('x ^= y', 'x ^= y') == True
assert check_equivalence('x &= y', 'x &= y') == True
assert check_equivalence('x <<= y', 'x <<= y') == True
assert check_equivalence('x >>= y', 'x >>= y') == True
assert check_equivalence('x += y', 'x += y') == True
assert check_equivalence('x -= y', 'x -= y') == True
assert check_equivalence('x *= y', 'x *= y') == True
assert check_equivalence('x /= y', 'x /= y') == True
assert check_equivalence('x %= y', 'x %= y') == True