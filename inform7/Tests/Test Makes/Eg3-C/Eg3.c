#include "inform7_clib.h"

char *current_201_style = "";
void HTML_begin(void) {
	current_201_style = "";
	printf("<html><body>\n");
}

void HTML_styling_receiver(int id, wchar_t c, char *style) {
	if (id == 201) {
		if (strcmp(style, current_201_style) != 0) {
			if (current_201_style) printf("</span>");
			current_201_style = style;
			if (style) printf("<span class=\"%s\">", style);
		}
		if (c == '&') printf("&amp;");
		else if (c == '<') printf("&lt;");
		else if (c == '>') printf("&gt;");
		else putchar(c);
	}
}

void HTML_end(void) {
	if (current_201_style) printf("</span>");
	printf("</html></body>\n");
}

int main(int argc, char **argv) {
	printf("Hello from the C source code.\n");
	i7process_t proc = i7_new_process();
	i7_set_process_receiver(&proc, HTML_styling_receiver);
	HTML_begin();
	int exit_code = i7_run_process(&proc);
	HTML_end();
	if (exit_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return exit_code;
}
