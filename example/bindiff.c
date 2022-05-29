#include "locale.h"
#include "stdio.h"
#include "stdlib.h"
#include "wchar.h"

#define LINELENGTH 0x10

#undef STRINGIFY_EX
#define STRINGIFY_EX(...) #__VA_ARGS__
#undef STRINGIFY
#define STRINGIFY(...) STRINGIFY_EX(__VA_ARGS__)

#define ANSI_ESC "\x1B"
#define ANSI_CSI ANSI_ESC "["
#define ANSI_SGR_STR(str) ANSI_CSI str "m"
#define ANSI_SGR(x) ANSI_SGR_STR(STRINGIFY(x))

#define RESET ANSI_SGR(0)
#define BOLD ANSI_SGR(1)
#define FAINT ANSI_SGR(2)
#define RED ANSI_SGR(31)
#define GREEN ANSI_SGR(32)
#define BLUE ANSI_SGR(34)

FILE *file[] = {NULL, NULL};

void finish(int status) {
  if (file[0])
    fclose(file[0]);
  if (file[1])
    fclose(file[1]);
  fwprintf(stdout, L"" RESET);
  exit(status);
}

void open_file(int file_number, const char *path) {
  if (!(file[file_number] = fopen(path, "rb"))) {
    fwprintf(stderr, L"" RED BOLD "Error opening file %i: \"%s\"" RESET "\n",
             file_number + 1, path);
    finish(EXIT_FAILURE);
  }
}

void check_file_errors(int file_number) {
  int err = ferror(file[file_number]);
  if (err) {
    fwprintf(stderr, L"" RED BOLD "Error reading file %i: %i" RESET "\n",
             file_number + 1, err);
    finish(EXIT_FAILURE);
  }
}

int main(int argc, char *argv[]) {
  setlocale(LC_ALL, "");
  fwide(stderr, 1);
  fwide(stdout, 1);

  // Reset the graphics mode before we begin.
  fwprintf(stdout, L"" RESET);

  if (argc < 3) {
    fwprintf(stderr, L"" RED BOLD "Too few arguments" RESET "\n");
    finish(EXIT_FAILURE);
  }

  open_file(0, argv[1]);
  open_file(1, argv[2]);

  fwprintf(stdout, L"" RESET "A: " GREEN "%s\n", argv[1]);
  fwprintf(stdout, L"" RESET "B: " RED "%s\n", argv[2]);

  unsigned char bytes1[LINELENGTH] = {0};
  unsigned char bytes2[LINELENGTH] = {0};

  for (size_t line = 0; !feof(file[0]) && !feof(file[1]); line += LINELENGTH) {
    size_t read1 = fread(bytes1, 1, LINELENGTH, file[0]);
    size_t read2 = fread(bytes2, 1, LINELENGTH, file[1]);
    size_t read = read1 > read2 ? read2 : read1;
    int diff = 0;

    for (size_t i = 0; i < read; ++i) {
      if (bytes1[i] != bytes2[i]) {
        diff = 1;
        break;
      }
    }

    if (diff) {
      // Print green line (file 1).
      fwprintf(stdout, L"\n%08zX", line);

      for (size_t i = 0; i < read; ++i) {
        fwprintf(stdout, L" " RESET);
        if (bytes1[i] != bytes2[i])
          fwprintf(stdout, L"" GREEN BOLD "%02X", bytes1[i]);
        else
          fwprintf(stdout, L"" BLUE FAINT "%02X", bytes1[i]);
      }

      // Print red line (file 2).
      fwprintf(stdout, L"\n" RESET "%08zX", line);

      for (size_t i = 0; i < read; ++i) {
        fwprintf(stdout, L" " RESET);
        if (bytes1[i] != bytes2[i])
          fwprintf(stdout, L"" RED BOLD "%02X", bytes2[i]);
        else
          fwprintf(stdout, L"" BLUE FAINT "%02X", bytes2[i]);
      }

      fwprintf(stdout, L"" RESET "\n");
    }

    check_file_errors(0);
    check_file_errors(1);
  }

  finish(EXIT_SUCCESS);
}
