/*
   winstart.c: Windows-specific code for the Glulxe interpreter.
*/

#include <windows.h>

#include "glk.h"
#include "gi_blorb.h"
#include "WinGlk.h"

#include "resource.h"

int InitGlk(unsigned int iVersion);

/* Entry point for all Glk applications */
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
  /* Attempt to initialise Glk */
  if (InitGlk(0x00000700) == 0)
    exit(0);

  /* Call the Windows specific initialization routine */
  if (winglk_startup_code(lpCmdLine) != 0)
  {
    /* Run the application */
    glk_main();

    /* There is no return from this routine */
    glk_exit();
  }

  return 0;
}

/* These are defined in glulxe.h */
extern int locate_gamefile(int isblorb);
extern strid_t gamefile;
extern char *init_err;

#define IDS_GLULXE_TITLE  31000
#define IDS_GLULXE_OPEN   31001
#define IDS_GLULXE_FILTER 31002

int winglk_startup_code(const char* cmdline)
{
  const char* pszFileName = 0;
  char* pszSeparator;
  char sExeName[_MAX_PATH];
  char sFileName[_MAX_PATH];
  char sWindowTitle[256];
  char sBuffer[12];
  int iBufferCount, iExtLoop;
  HINSTANCE hResources;
  frefid_t GameRef;

  winglk_set_gui(IDI_GLULX);
  winglk_app_set_name("Glulxe");
  winglk_set_menu_name("&Glulxe");
  winglk_show_game_dialog();

  hResources = winglk_get_resource_handle();
  LoadString(hResources,IDS_GLULXE_TITLE,sWindowTitle,256);
  winglk_window_set_title(sWindowTitle);
  winglk_set_about_text("Windows Glulxe 0.4.7.139");

  /* Set up the help file */
  if (GetModuleFileName(0,sExeName,_MAX_PATH) == 0)
    return 0;
  pszSeparator = strrchr(sExeName,'.');
  if (pszSeparator != 0)
  {
    strcpy(pszSeparator,".chm");
    winglk_set_help_file(sExeName);
  }

  /* First look for a Blorb file with the same name as the executable. */
  if (GetModuleFileName(0,sExeName,_MAX_PATH) == 0)
    return 0;
  pszSeparator = strrchr(sExeName,'.');
  if (pszSeparator != 0)
  {
    static char* Extensions[5] = { ".blb", ".blorb", ".glb", ".gblorb", ".ulx" };

    for (iExtLoop = 0; iExtLoop < 5; iExtLoop++)
    {
      strcpy(pszSeparator,Extensions[iExtLoop]);
      if (GetFileAttributes(sExeName) != INVALID_FILE_ATTRIBUTES)
      {
        pszFileName = sExeName;
        break;
      }
    }
  }

  if (pszFileName == 0)
  {
    char sOpenTitle[256];
    char sOpenFilter[256];

    /* Check the command line for a file, or prompt the user. */
    LoadString(hResources,IDS_GLULXE_OPEN,sOpenTitle,256);
    LoadString(hResources,IDS_GLULXE_FILTER,sOpenFilter,256);
    pszFileName = winglk_get_initial_filename(cmdline,sOpenTitle,sOpenFilter);
  }
  if (pszFileName == 0)
    return 0;

  /* Open the file as a stream */
  strcpy(sFileName,pszFileName);
  GameRef = winglk_fileref_create_by_name(
    fileusage_BinaryMode|fileusage_Data,sFileName,0,0);
  if (GameRef == 0)
    return 0;
  gamefile = glk_stream_open_file(GameRef,filemode_Read,0);
  glk_fileref_destroy(GameRef);

  /* Examine the loaded file to see what type it is. */
  glk_stream_set_position(gamefile,0,seekmode_Start);
  iBufferCount = glk_get_buffer_stream(gamefile,sBuffer,12);
  if (iBufferCount < 12)
    return 0;

  if (sBuffer[0] == 'G' && sBuffer[1] == 'l' && sBuffer[2] == 'u' && sBuffer[3] == 'l')
  {
    char* pszPeriod;

    if (locate_gamefile(0) == 0)
      return 0;

    /* Look for a Blorb resource file */
    pszPeriod = strrchr(sFileName,'.');
    if (pszPeriod)
    {
      static char* Extensions[2] = { ".blb", ".blorb" };
      frefid_t BlorbRef = 0;

      for (iExtLoop = 0; iExtLoop < 2; iExtLoop++)
      {
        strcpy(pszPeriod,Extensions[iExtLoop]);

        /* Attempt to open the resource Blorb file */
        BlorbRef = winglk_fileref_create_by_name(
          fileusage_BinaryMode|fileusage_Data,sFileName,0,0);

        if (glk_fileref_does_file_exist(BlorbRef))
        {
          strid_t BlorbFile = glk_stream_open_file(BlorbRef,filemode_Read,0);
          giblorb_set_resource_map(BlorbFile);
          break;
        }
      }
    }
  }
  else if (sBuffer[0] == 'F' && sBuffer[1] == 'O' && sBuffer[2] == 'R' && sBuffer[3] == 'M'
    && sBuffer[8] == 'I' && sBuffer[9] == 'F' && sBuffer[10] == 'R' && sBuffer[11] == 'S')
  {
    if (locate_gamefile(1) == 0)
    {
      if (init_err != 0)
        MessageBox(0,init_err,"Glulxe",MB_OK|MB_ICONERROR);
      return 0;
    }
  }
  else
  {
    MessageBox(0,"This is not a Glulx game file.","Glulxe",MB_OK|MB_ICONERROR);
    return 0;
  }

  /* Set up the resource directory. */
  pszSeparator = strrchr(sFileName,'\\');
  if (pszSeparator != 0)
  {
    *pszSeparator = '\0';
    winglk_set_resource_directory(sFileName);
  }

  /* Load configuration data */
  strcpy(sFileName,pszFileName);
  winglk_load_config_file(sFileName);

  return 1;
}
