#include <stdio.h>
#include <stdlib.h>

#include <parser.tab.h>
#include <symtab.h>
#include <ast.h>

const int SEMANTIC_CHECK = 1;

int main(int argc, const char* argv[]) {
	if (argc < 2) {
		fprintf(stderr, "Usage: %s <c1-source>\n", argv[0]);
		return EXIT_FAILURE;
	}
	
	FILE *in = fopen(argv[1], "r");
	if (in == NULL) {
		fprintf(stderr, "Failed to read c1 source file\n");
		return EXIT_FAILURE;
	}
	
	ParseResult result = astParse(in);
	SymDefTable tab;
	switch (result.tag) {
	case PARSE_OK:
		printf("[✓] syntax\n");
		printf("[✓] analysis\n");
		
		tab = symDefTableNew(&result.tab, &result.ok);
		astProgramPrint(&result.ok, 0, stdout);
		symDefTablePrint(&tab, 0, stdout);
		
		astProgramRelease(&result.ok);
		symDefTableRelease(&tab);
		return EXIT_SUCCESS;
		
	case PARSE_ERR_SYNTAX:
		printf("[x] syntax\n");
		puts(result.err);
		break;
		
	case PARSE_ERR_SEMANTIC:
		printf("[✓] syntax\n");
		printf("[x] analysis\n");
		puts(result.err);
		break;
	}
	
	return EXIT_FAILURE;
}
