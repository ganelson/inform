#include "inform7_clib.h"

char current_201_style[256];
void HTML_begin(void) {
	current_201_style[0] = 0;
	printf("<html><body>\n");
}

void HTML_styling_receiver(int id, wchar_t c, char *style) {
	if (id == I7_BODY_TEXT_ID) {
		if (strcmp(style, current_201_style) != 0) {
			if (current_201_style[0]) printf("</span>");
			strcpy(current_201_style, style);
			if (style[0]) printf("<span class=\"%s\">", style);
		}
		if (c == '&') printf("&amp;");
		else if (c == '<') printf("&lt;");
		else if (c == '>') printf("&gt;");
		else putchar(c);
	}
}

void HTML_end(void) {
	if (current_201_style[0]) printf("</span>");
	printf("</html></body>\n");
}

int main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_set_process_receiver(&proc, HTML_styling_receiver, 1);
	HTML_begin();
	int exit_code = i7_run_process(&proc);
	HTML_end();
	if (exit_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return exit_code;
}
