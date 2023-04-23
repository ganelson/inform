
#include "glk.h"
#include "iosglk_startup.h"

@class GlulxAccelEntry;
@class GlkObjIdEntry;

/* This structure contains VM state which is not stored in a normal save file, but which is needed for an autorestore.
 
	(The reason it's not stored in a normal save file is that it's useless unless you serialize the entire Glk state along with the VM. Glulx normally doesn't do that, but for an iOS autosave, we do.)
 */
typedef struct library_state_data_struct {
	BOOL active;
	glui32 protectstart, protectend;
	glui32 iosys_mode, iosys_rock;
	glui32 stringtable;
	NSArray<NSNumber *> *accel_params;
	NSArray<GlulxAccelEntry *> *accel_funcs;
	glui32 gamefiletag;
	NSArray<GlkObjIdEntry *> *id_map_list;
} library_state_data;

void iosglk_do_autosave(glui32 selector, glui32 arg0, glui32 arg1, glui32 arg2);
void iosglk_clear_autosave(void);
void iosglk_set_can_restart_flag(int);
int iosglk_can_restart_cleanly(void);
void iosglk_shut_down_process(void) GLK_ATTRIBUTE_NORETURN;


@interface GlkObjIdEntry : NSObject <NSSecureCoding> {
	glui32 objclass;
	glui32 tag;
	glui32 dispid;
}

- (instancetype) initWithClass:(int)objclass tag:(NSNumber *)tag id:(glui32)dispid;
@property (NS_NONATOMIC_IOSONLY, readonly) glui32 objclass;
@property (NS_NONATOMIC_IOSONLY, readonly) glui32 tag;
@property (NS_NONATOMIC_IOSONLY, readonly) glui32 dispid;

@end


@interface GlulxAccelEntry : NSObject <NSSecureCoding> {
	glui32 index;
	glui32 addr;
}

- (instancetype) initWithIndex:(glui32)index addr:(glui32)addr;

@property (NS_NONATOMIC_IOSONLY, readonly) glui32 index;
@property (NS_NONATOMIC_IOSONLY, readonly) glui32 addr;

@end
