/***************************************************************************//**
 * @file calculator.c
 * Implementation of the calculator.
 ******************************************************************************/

#include "calculator.h"
#include "vec.h"

/* ******************************************************* private interface */

static void visitExpr(Calculator *self, const Expr *expr) {
	int rhs;
	int lhs;
	int index;
	switch (expr->tag) {
	case EXPR_INT:
		self->result = expr->val;
		break;
		
	case EXPR_VAR:
		index = expr->var - 'a';
	    self->result = self->var_values[index];
		break;
		
	case EXPR_ADD:
		visitExpr(self, expr->op.lhs);
		lhs = self->result;
		visitExpr(self, expr->op.rhs);
		rhs = self->result;
		
		self->result = lhs + rhs;
		break;
		
	case EXPR_SUB:
		visitExpr(self, expr->op.lhs);
		lhs = self->result;
		visitExpr(self, expr->op.rhs);
		rhs = self->result;

		self->result = lhs - rhs;
		break;
		
	case EXPR_MUL:
		visitExpr(self, expr->op.lhs);
		lhs = self->result;
		visitExpr(self, expr->op.rhs);
		rhs = self->result;

		self->result = lhs * rhs;
		break;
		
	case EXPR_DIV:
		visitExpr(self, expr->op.lhs);
		lhs = self->result;
		visitExpr(self, expr->op.rhs);
		rhs = self->result;
	
		self->result = lhs / rhs;
		break;
	}
}

static void visitStmt(Calculator *self, const Stmt *stmt) {
	// TODO: eventuell Ergänzungen vornehmen
	switch (stmt->tag) {
	case STMT_EXPR:
		visitExpr(self, &stmt->expr);
		break;
		
	case STMT_SET:
		visitExpr(self, &stmt->set.expr);
		int index = stmt->set.var - 'a';
		self->var_values[index] = self->result;
		self->result = 0;
		break;
	}
}

static void visitRoot(Calculator *self, const Root *root) {
	// TODO: eventuell Ergänzungen vornehmen
	vecForEach(const Stmt *stmt, root->stmt_list) {
		visitStmt(self, stmt);
	}
}

/* ******************************************************** public interface */

int calculatorCalc(Calculator *self, Root *root) {
	// fill vars[] with chars a-z and results[] with 0
	for (int i = 0; i < 26; i++){
		self->var_values[i]= 0;
		
	}
	self->result = 0; 
	visitRoot(self, root);
	return self->result;
}

/* *************************************************************** unit tests */

#ifdef TEST
#include <stdio.h>

#define EXPECT(COND) \
	if (!(COND)) { \
		fprintf(stderr, #COND " failed "); \
		return false; \
	}

bool calc_add(void) {
	Calculator calc;
	Root root = rootFromStmt(stmtFromExpr(
		exprFromAdd(
			exprFromInt(4),
			exprFromInt(2)
		)
	));
	
	EXPECT(calculatorCalc(&calc, &root) == 6);
	return true;
}

bool calc_sub(void) {
	Calculator calc;
	Root root = rootFromStmt(stmtFromExpr(
		exprFromSub(
			exprFromInt(4),
			exprFromInt(2)
		)
	));
	
	EXPECT(calculatorCalc(&calc, &root) == 2);
	return true;
}

bool calc_mul(void) {
	Calculator calc;
	Root root = rootFromStmt(stmtFromExpr(
		exprFromMul(
			exprFromInt(4),
			exprFromInt(2)
		)
	));
	
	EXPECT(calculatorCalc(&calc, &root) == 8);
	return true;
}

bool calc_div(void) {
	Calculator calc;
	Root root = rootFromStmt(stmtFromExpr(
		exprFromDiv(
			exprFromInt(4),
			exprFromInt(2)
		)
	));
	
	EXPECT(calculatorCalc(&calc, &root) == 2);
	return true;
}

bool calc_set(void) {
	Calculator calc;
	Root root = rootFromStmt(stmtFromSet('a', exprFromInt(1)));
	
	EXPECT(calculatorCalc(&calc, &root) == 0);
	return true;
}

bool calc_vars(void) {
	Root root = rootFromStmt(stmtFromSet('i', exprFromInt(1)));
	
	rootPushStmt(&root, stmtFromSet('j', exprFromInt(2)));
	rootPushStmt(&root, stmtFromExpr(
		exprFromAdd(exprFromVar('i'), exprFromVar('j'))
	));
	
	Calculator calc;
	EXPECT(calculatorCalc(&calc, &root) == 3);
	return true;
}
bool calc_set_and_add(void) {
	Root root = rootFromStmt(stmtFromSet('a', exprFromInt(1)));
	rootPushStmt(&root, stmtFromExpr(exprFromAdd(exprFromVar('a'), exprFromVar('a'))));
	Calculator calc;
	EXPECT(calculatorCalc(&calc, &root) == 2);
	return true;
}
bool calc_complex_test(void) {
	// Initialize root with multiple statements
	Root root = rootFromStmt(stmtFromSet('a', exprFromInt(3)));          // a = 3
	rootPushStmt(&root, stmtFromSet('b', exprFromInt(4)));               // b = 4
	rootPushStmt(&root, stmtFromSet('c', exprFromAdd(                   // c = a + b
		exprFromVar('a'), 
		exprFromVar('b')
	)));
	rootPushStmt(&root, stmtFromExpr(                                   // (a * b) + c
		exprFromAdd(
			exprFromMul(
				exprFromVar('a'),
				exprFromVar('b')
			),
			exprFromVar('c')
		)
	));

	Calculator calc;
	EXPECT(calculatorCalc(&calc, &root) == 19);  // Final result should be 19

	// Optional: Check internal variable values directly
	EXPECT(calc.var_values['a' - 'a'] == 3);
	EXPECT(calc.var_values['b' - 'a'] == 4);
	EXPECT(calc.var_values['c' - 'a'] == 7);

	return true;
}
#endif
