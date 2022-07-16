/*
   winstart.c: Windows-specific code for the Glulxe interpreter.
*/

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

#include "glk.h"
#include "gi_blorb.h"
#if VM_DEBUGGER
#include "gi_debug.h" 
#endif
#include "glulxe.h"
#include "gestalt.h"

#include "WinGlk.h"

/* Entry point for all Glk applications */
int WINAPI WinMain(HINSTANCE instance, HINSTANCE prevInstance, LPSTR cmdLine, int show)
{
  /* Attempt to initialise Glk */
  if (InitGlk(0x00000704) == 0)
    exit(1);

  /* Call the Windows specific initialization routine */
  if (winglk_startup_code(cmdLine) != 0)
  {
    /* Run the application */
#if VM_DEBUGGER
    gidebug_announce_cycle(gidebug_cycle_Start);
#endif
    glk_main();

    /* There is no return from this routine */
    glk_exit();
  }
  return 0;
}

/* Resource identifiers */
#define IDI_GLULX           128
#define IDS_GLULXE_TITLE  31000
#define IDS_GLULXE_OPEN   31001
#define IDS_GLULXE_FILTER 31002

/* Fail with an error */
void fatal(const char* msg)
{
  if (msg)
    MessageBox(0,msg,"Glulxe",MB_OK|MB_ICONERROR);
  exit(1);
}

/* Set the path to the help file from the executable path, if the help file can be found. */
void set_help_file(void)
{
  char path[_MAX_PATH];
  char* end;

  GetModuleFileName(0,path,sizeof path);
  end = strrchr(path,'.');
  if (!end)
    return;

  strcpy(end,".chm");
  if (GetFileAttributes(path) != INVALID_FILE_ATTRIBUTES)
  {
    winglk_set_help_file(path);
    return;
  }

  end = strrchr(path,'(');
  if (end > path)
  {
    strcpy(end-1,".chm");
    if (GetFileAttributes(path) != INVALID_FILE_ATTRIBUTES)
    {
      winglk_set_help_file(path);
      return;
    }
  }
}

int winglk_startup_code(const char* cmdline)
{
  HINSTANCE resourceHandle;

  char path[_MAX_PATH];
  const char* gamePath = NULL;
  const char* gameInfoPath = NULL;
  int gotGameInfo = FALSE;

  char header[12];
  char* end;
  int i;

  /* Customize the Windows Glk interface for Glulxe. */
  winglk_set_gui(IDI_GLULX);
  winglk_app_set_name("Glulxe");
  winglk_set_menu_name("&Glulxe");
  winglk_show_game_dialog();
  set_help_file();

  resourceHandle = winglk_get_resource_handle();
  {
    char text[256];
    glui32 terpVersion;

    /* Set the window title from a (possibly localized) resource string. */
    LoadString(resourceHandle,IDS_GLULXE_TITLE,text,sizeof text);
    winglk_window_set_title(text);

    /* Set the Windows Glulxe version number in the About dialog. */
    terpVersion = do_gestalt(gestulx_TerpVersion,0);
    snprintf(text,sizeof text,"Windows Glulxe %d.%d.%d.%d",
      (terpVersion & 0xFFFF0000) >> 16,(terpVersion & 0xFF00) >> 8,(terpVersion &0xFF),WINGLK_BUILD_NUMBER);
    winglk_set_about_text(text);
  }

  /* Look for a game file with the same name as the executable. */
  GetModuleFileName(0,path,sizeof path);
  end = strrchr(path,'.');
  if (end)
  {
    static const char* gameExts[] = { ".blb", ".blorb", ".glb", ".gblorb", ".ulx" };
    for (i = 0; i < sizeof gameExts / sizeof gameExts[0]; i++)
    {
      strcpy(end,gameExts[i]);
      if (GetFileAttributes(path) != INVALID_FILE_ATTRIBUTES)
      {
        gamePath = path;
        break;
      }
    }
  }

  /* Read the command line. */
  for (i = 1; i < __argc; i++)
  {
#if VM_DEBUGGER
    if (strcmp(__argv[i],"--gameinfo") == 0)
    {
      i++;
      if (i < __argc)
        gameInfoPath = __argv[i];
      continue;
    }
    if (strcmp(__argv[i],"--cpu") == 0)
    {
      debugger_track_cpu(TRUE);
      continue;
    }
    if (strcmp(__argv[i],"--starttrap") == 0)
    {
      debugger_set_start_trap(TRUE);
      continue;
    }
    if (strcmp(__argv[i],"--quittrap") == 0)
    {
      debugger_set_quit_trap(TRUE);
      continue;
    }
    if (strcmp(__argv[i],"--crashtrap") == 0)
    {
      debugger_set_crash_trap(TRUE);
      continue;
    }
#endif /* VM_DEBUGGER */
    if (!gamePath)
      gamePath = __argv[i];
  }

  /* Ask the user for a game to load, if none given on the command line. */
  if (!gamePath)
  {
    char title[256], filter[256];
    LoadString(resourceHandle,IDS_GLULXE_OPEN,title,sizeof title);
    LoadString(resourceHandle,IDS_GLULXE_FILTER,filter,sizeof filter);
    gamePath = winglk_get_initial_filename(NULL,title,filter);
  }

  /* Give up if there is no game to load. */
  if (!gamePath)
    return 0;

  /* Open the game file as a stream */
  {
    frefid_t gameFileRef = winglk_fileref_create_by_name(fileusage_BinaryMode|fileusage_Data,(char*)gamePath,0,0);
    if (glk_fileref_does_file_exist(gameFileRef))
      gamefile = glk_stream_open_file(gameFileRef,filemode_Read,0);
    glk_fileref_destroy(gameFileRef);
  }
  if (gamefile == 0)
    fatal("Could not open the game file.");

#if VM_DEBUGGER
  /* Open the game info file as a stream and pass it to the debugger. */
  if (gameInfoPath)
  {
    frefid_t gameInfoFileRef = winglk_fileref_create_by_name(fileusage_BinaryMode|fileusage_Data,(char*)gameInfoPath,0,0);
    if (glk_fileref_does_file_exist(gameInfoFileRef))
    {
      strid_t gameInfoStream = glk_stream_open_file(gameInfoFileRef,filemode_Read,0);
      glk_fileref_destroy(gameInfoFileRef);
      if (gameInfoStream != 0)
      {
        if (debugger_load_info_stream(gameInfoStream))
          gotGameInfo = TRUE;
      }
    }
  }
  gidebug_debugging_available(debugger_cmd_handler,debugger_cycle_handler);
#endif

  /* Examine the loaded game file to see what type it is. */
  glk_stream_set_position(gamefile,0,seekmode_Start);
  if (glk_get_buffer_stream(gamefile,header,sizeof header) < sizeof header)
    fatal("The data in this stand-alone game is too short to read.");
  if (memcmp(header,"Glul",4) == 0)
  {
    char blorbPath[_MAX_PATH];

    if (!locate_gamefile(0))
      fatal(init_err);

    /* We have a plain Glulx file, so look for a Blorb resource file. */
    strcpy(blorbPath,gamePath);
    end = strrchr(blorbPath,'.');
    if (end)
    {
      static const char* blorbExts[] = { ".blb", ".blorb" };
      for (i = 0; i < sizeof blorbExts / sizeof blorbExts[0]; i++)
      {
        frefid_t blorbFileRef;

        strcpy(end,blorbExts[i]);
        blorbFileRef = winglk_fileref_create_by_name(fileusage_BinaryMode|fileusage_Data,blorbPath,0,0);
        if (glk_fileref_does_file_exist(blorbFileRef))
        {
          strid_t blorbStream = glk_stream_open_file(blorbFileRef,filemode_Read,0);
          glk_fileref_destroy(blorbFileRef);
          if (blorbStream != 0)
          {
            giblorb_set_resource_map(blorbStream);
            break;
          }
        }
      }
    }
  }
  else if ((memcmp(header,"FORM",4) == 0) && (memcmp(header+8,"IFRS",4) == 0))
  {
    /* We have a Blorb file */
    if (!locate_gamefile(1))
      fatal(init_err);

#if VM_DEBUGGER
    /* Load the game info from the Blorb file, if it wasn't loaded from a separate file. */
    if (!gotGameInfo)
    {
      giblorb_result_t result;
      glui32 id_Dbug = giblorb_make_id('D','b','u','g');
      giblorb_err_t error = giblorb_load_chunk_by_type(giblorb_get_resource_map(),giblorb_method_FilePos,&result,id_Dbug,0);
      if (error != 0)
      {
        if (debugger_load_info_chunk(gamefile,result.data.startpos,result.length))
          gotGameInfo = TRUE;
      }
    }
#endif
  }
  else
    fatal("This is neither a Glulx game file nor a Blorb file which contains one.");

  /* Set up the resource directory. */
  {
    char resourceDir[_MAX_PATH];

    strcpy(resourceDir,gamePath);
    end = strrchr(resourceDir,'\\');
    if (end)
    {
      *end = '\0';
      winglk_set_resource_directory(resourceDir);
    }
  }

  /* Load configuration data */
  winglk_load_config_file(gamePath);
  return 1;
}
