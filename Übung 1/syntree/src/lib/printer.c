/***************************************************************************//**
 * @file printer.c
 * Implementation of the printer.
 ******************************************************************************/

#include "printer.h"
#include "vec.h"

/* ******************************************************* private interface */

static void visitExpr(Printer *self, const Expr *expr) {
	// TODO: eventuell Ergänzungen vornehmen
	switch (expr->tag) {
	case EXPR_INT:
		fprintf(self->out,"%d",expr->val);
		break;
		
	case EXPR_VAR:
	fprintf(self->out,"%c",expr->var);
		break;
		
	case EXPR_ADD:
		fprintf(self->out, "(");
		visitExpr(self, expr->op.lhs);
		fprintf(self->out, "+");
		visitExpr(self, expr->op.rhs);
		fprintf(self->out, ")");
		break;
		
	case EXPR_SUB:
		fprintf(self->out, "(");
		visitExpr(self, expr->op.lhs);
		fprintf(self->out, "-");
		visitExpr(self, expr->op.rhs);
		fprintf(self->out, ")");
		break;
		
	case EXPR_MUL:
		fprintf(self->out, "(");
		visitExpr(self, expr->op.lhs);
		fprintf(self->out, "*");
		visitExpr(self, expr->op.rhs);
		fprintf(self->out, ")");
		break;
		
	case EXPR_DIV:
		fprintf(self->out, "(");
		visitExpr(self, expr->op.lhs);
		fprintf(self->out, "/");
		visitExpr(self, expr->op.rhs);
		fprintf(self->out, ")");	
		break;
	}
}

static void visitStmt(Printer *self, const Stmt *stmt) {
	// TODO: eventuell Ergänzungen vornehmen
	switch (stmt->tag) {
	case STMT_EXPR: 
		visitExpr(self, &stmt->expr);
		break;
		
	case STMT_SET:
		fprintf(self->out, "%c",stmt->set.var);
		fprintf(self->out, "=");
		visitExpr(self, &stmt->set.expr);
		fprintf(self->out, "\n");
		break;
	}
}

static void visitRoot(Printer *self, const Root *root) {
	// TODO: eventuell Ergänzungen vornehmen
	vecForEach(const Stmt *stmt, root->stmt_list) {
		visitStmt(self, stmt);
	}
}

/* ******************************************************** public interface */

void printerFormat(Printer *self, const Root *root) {
	visitRoot(self, root);
}

/* *************************************************************** unit tests */

#ifdef TEST
#include <stdio.h>
#include <string.h>
#include <ctype.h>

static bool test(const Root *root, const char *expected) {
	bool rc = true;
	Printer printer = { .out = tmpfile() };
	long len = strlen(expected);
	
	printerFormat(&printer, root);
	
	long act_len = ftell(printer.out);
	if (act_len > len) {
		len = act_len;
	}
	
	char buf[len+1];
	rewind(printer.out);
	fread(buf, 1, len, printer.out);
	buf[len] = '\0';
	
	// trim whitespace from the back of the string to be a bit more permissive
	while (isspace(buf[--len]));
	buf[++len] = '\0';
	
	if (!(rc = (strcmp(buf, expected) == 0))) {
		fprintf(
			stderr, "unexpected output, expected: '%s', actual: '%s'",
			expected, buf
		);
	}
	
	fclose(printer.out);
	return rc;
}

bool printer_add(void) {
	Root root = rootFromStmt(stmtFromExpr(
		exprFromAdd(
			exprFromInt(4),
			exprFromInt(2)
		)
	));
	return test(&root, "(4+2)");
}

bool printer_sub(void) {
	Root root = rootFromStmt(stmtFromExpr(
		exprFromSub(
			exprFromInt(4),
			exprFromInt(2)
		)
	));
	return test(&root, "(4-2)");
}

bool printer_mul(void) {
	Root root = rootFromStmt(stmtFromExpr(
		exprFromMul(
			exprFromInt(4),
			exprFromInt(2)
		)
	));
	return test(&root, "(4*2)");
}

bool printer_div(void) {
	Root root = rootFromStmt(stmtFromExpr(
		exprFromDiv(
			exprFromInt(4),
			exprFromInt(2)
		)
	));
	return test(&root, "(4/2)");
}

bool printer_set(void) {
	Root root = rootFromStmt(stmtFromSet('a', exprFromInt(1)));
	return test(&root, "a=1");
}
bool printer_set_and_add(void) {
	Root root = rootFromStmt(stmtFromSet('a', exprFromInt(1)));
	rootPushStmt(&root, stmtFromExpr(exprFromAdd(exprFromVar('a'), exprFromVar('a'))));
	return test(&root, "a=1\n(a+a)");
}
#endif
