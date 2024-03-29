#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2019 Ward
#
#====================================================================

# Let kiwi deal with int expression

template `*`*(variable: Variable, coefficient: int): Term = `*`(variable, float coefficient)
template `/`*(variable: Variable, denominator: int): Term = `/`(variable, float denominator)
template `*`*(term: Term, coefficient: int): Term = `*`(term, float coefficient)
template `/`*(term: Term, denominator: int): Term = `/`(term, float denominator)
template `*`*(expression: Expression, coefficient: int): Expression = `*`(expression, float coefficient)
template `/`*(expression: Expression, denominator: int): Expression = `/`(expression, float denominator)
template `*`*(lhs: int, rhs: Expression): Expression = `*`(float lhs, rhs)
template `*`*(lhs: int, rhs: Term | Variable): Term = `*`(float lhs, rhs)
template `+`*(expression: Expression, constant: int): Expression = `+`(expression, float constant)
template `-`*(lhs: Expression, rhs: int): Expression = `-`(lhs, float rhs)
template `+`*(term: Term, constant: int): Expression = `+`(term, float constant)
template `-`*(lhs: Term, rhs: int): Expression = `-`(lhs, float rhs)
template `+`*(variable: Variable, constant: int): Expression = `+`(variable, float constant)
template `-`*(lhs: Variable, rhs: int): Expression = `-`(lhs, float rhs)
template `+`*(lhs: int, rhs: Expression | Term | Variable): Expression = `+`(float lhs, rhs)
template `-`*(lhs: int, rhs: Expression | Term | Variable): Expression = `-`(float lhs, rhs)
template `==`*(expression: Expression, constant: int): Constraint = `==`(expression, float constant)
template `<=`*(expression: Expression, constant: int): Constraint = `<=`(expression, float constant)
template `>=`*(expression: Expression, constant: int): Constraint = `>=`(expression, float constant)
template `==`*(lhs: Term, rhs: int): Constraint = `==`(lhs, float rhs)
template `<=`*(lhs: Term, rhs: int): Constraint = `<=`(lhs, float rhs)
template `>=`*(lhs: Term, rhs: int): Constraint = `>=`(lhs, float rhs)
template `==`*(variable: Variable, constant: int): Constraint = `==`(variable, float constant)
template `<=`*(lhs: Variable, rhs: int): Constraint = `<=`(lhs, float rhs)
template `>=`*(variable: Variable, constant: int): Constraint = `>=`(variable, float constant)
template `==`*(lhs: int, rhs: Expression | Term | Variable): Constraint = `==`(float lhs, rhs)
template `<=`*(constant: int, expression: Expression): Constraint = `<=`(float constant, expression)
template `<=`*(constant: int, term: Term): Constraint = `<=`(float constant, term)
template `<=`*(constant: int, variable: Variable): Constraint = `<=`(float constant, variable)
template `>=`*(constant: int, term: Term): Constraint = `>=`(float constant, term)
template `>=`*(constant: int, variable: Variable): Constraint = `>=`(float constant, variable)
