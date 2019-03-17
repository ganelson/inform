
#include "glk.h"
#include "iosglk_startup.h"

/* This structure contains VM state which is not stored in a normal save file, but which is needed for an autorestore.
 
	(The reason it's not stored in a normal save file is that it's useless unless you serialize the entire Glk state along with the VM. Glulx normally doesn't do that, but for an iOS autosave, we do.)
 */
typedef struct library_state_data_struct {
	BOOL active;
	glui32 protectstart, protectend;
	glui32 iosys_mode, iosys_rock;
	glui32 stringtable;
	NSArray *accel_params; // array of NSNumber -- manually retained!
	NSArray *accel_funcs; // array of GlulxAccelEntry -- manually retained!
	glui32 gamefiletag;
	NSArray *id_map_list; // array of GlkObjIdEntry -- manually retained!
} library_state_data;

extern void iosglk_do_autosave(glui32 eventaddr);
extern void iosglk_clear_autosave(void);
extern void iosglk_set_can_restart_flag(int);
extern int iosglk_can_restart_cleanly(void);
extern void iosglk_shut_down_process(void) GLK_ATTRIBUTE_NORETURN;


@interface GlkObjIdEntry : NSObject {
	glui32 objclass;
	glui32 tag;
	glui32 dispid;
}

- (id) initWithClass:(int)objclass tag:(NSNumber *)tag id:(glui32)dispid;
- (glui32) objclass;
- (glui32) tag;
- (glui32) dispid;

@end


@interface GlulxAccelEntry : NSObject {
	glui32 index;
	glui32 addr;
}

- (id) initWithIndex:(glui32)index addr:(glui32)addr;

- (glui32) index;
- (glui32) addr;

@end
