#define _GNU_SOURCE

#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>

typedef struct _GdkDisplay GdkDisplay;
typedef struct _GdkCursor GdkCursor;

typedef GdkCursor *(*cursor_func_t)(GdkDisplay *, const char *);

/*
 * The library has already been loaded by the time this constructor runs.
 *
 * Restore the original LD_PRELOAD state so processes subsequently launched
 * from Nemo do not inherit this shim.
 */
__attribute__((constructor))
static void
cursor_fix_init(void)
{
    const char *original =
        getenv("NEMO_CURSOR_FIX_ORIG_LD_PRELOAD");

    if (original && *original)
        setenv("LD_PRELOAD", original, 1);
    else
        unsetenv("LD_PRELOAD");

    unsetenv("NEMO_CURSOR_FIX_ORIG_LD_PRELOAD");
}

GdkCursor *
gdk_cursor_new_from_name(GdkDisplay *display, const char *name)
{
    static cursor_func_t real_func = NULL;

    if (!real_func)
        real_func = (cursor_func_t)
            dlsym(RTLD_NEXT, "gdk_cursor_new_from_name");

    if (name &&
        (strcmp(name, "col-resize") == 0 ||
         strcmp(name, "ew-resize") == 0))
        name = "h_double_arrow";

    return real_func(display, name);
}
