/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.types;

/**
    This module contains just a small portion of the Tcl/Tk declarations.
*/

import std.exception;

import dtk.utils;

enum uint TCL_OK = 0;
enum uint TCL_ERROR = 1;

struct CData
{
    @disable this();
    @disable this(this);
}

/// opaque handle to client data
alias ClientData = CData*;

alias extern(C) void function(Tcl_Obj objPtr) Tcl_FreeInternalRepProc;
alias extern(C) void function(ClientData clientData) Tcl_CmdDeleteProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, int objc, const Tcl_Obj **objv) Tcl_ObjCmdProc;
alias extern(C) void function(Tcl_Obj srcPtr, Tcl_Obj dupPtr) Tcl_DupInternalRepProc;
alias extern(C) void function(Tcl_Obj objPtr) Tcl_UpdateStringProc;
alias extern(C) int function(Tcl_Interp* interp, Tcl_Obj objPtr) Tcl_SetFromAnyProc;
alias extern(C) long  Tcl_WideInt;
alias extern(C) ulong Tcl_WideUInt;
alias extern(C) void function(char* blockPtr) Tcl_FreeProc;

const Tcl_FreeProc* TCL_STATIC = cast(Tcl_FreeProc*)0;

struct Tk_Window_
{
    @disable this();
    @disable this(this);
}

/// opaque handle to a window
alias Tk_Window = Tk_Window_*;

struct Tcl_Command_
{
    @disable this();
    @disable this(this);
}

/// opaque handle to a command
alias Tcl_Command = Tcl_Command_*;

alias extern(C) void function(char* blockPtr) FreeProc;

/*
 * Using structs so I can iterate the members via __traits(allMembers, TclProcs).
 * This simplifies loading the symbols dynamically.
 */
struct TclProcs
{
__gshared extern(C):
    // Note: We must call this function before any other TCL function
    void function(const char* argv0) Tcl_FindExecutable;
    const(char*) function() Tcl_GetNameOfExecutable;
    int function(Tcl_Interp* interp, char* str) Tcl_Eval;
    Tcl_Interp* function() Tcl_CreateInterp;
    char* function(Tcl_Obj * objPtr, int* lengthPtr) Tcl_GetStringFromObj;
    char* function(const Tcl_Obj * objPtr) Tcl_GetString;
    void function(Tcl_Interp* interp, char* str, Tcl_FreeProc* freeProc) Tcl_SetResult;
    Tcl_Command function(Tcl_Interp* interp, char* cmdName,
                                      Tcl_ObjCmdProc proc, ClientData clientData,
                                      Tcl_CmdDeleteProc deleteProc) Tcl_CreateObjCommand;

    int function(Tcl_Interp* interp) Tcl_Init;
    void function(Tcl_Interp* interp) Tcl_DeleteInterp;
}

struct TkProcs
{
__gshared extern(C):
    int function(Tcl_Interp* interp) Tk_Init;
    Tk_Window function(Tcl_Interp* interp) Tk_MainWindow;
    void function() Tk_MainLoop;
    //~ HWND function(Window window) tk_GetHWND;
}

mixin ExportMembers!TkProcs;
mixin ExportMembers!TclProcs;

struct Tcl_Interp
{
    char* result;               /* If the last command returned a string
                                 * result, this points to it. */
    FreeProc freeProc;

    /* Zero means the string result is
     * statically allocated. TCL_DYNAMIC means
     * it was allocated with ckalloc and should
     * be freed with ckfree. Other values give
     * the address of procedure to invoke to
     * free the result. Tcl_Eval must free it
     * before executing next command. */
    int errorLine;              /* When TCL_ERROR is returned, this gives
                                 * the line number within the command where
                                 * the error occurred (1 if first line). */
}

struct Tcl_ObjType
{
    char* name;                 /* Name of the type, e.g. "int". */
    Tcl_FreeInternalRepProc* freeIntRepProc;

    /* Called to free any storage for the type's
     * internal rep. NULL if the internal rep
     * does not need freeing. */
    Tcl_DupInternalRepProc* dupIntRepProc;

    /* Called to create a new object as a copy
     * of an existing object. */
    Tcl_UpdateStringProc* updateStringProc;

    /* Called to update the string rep from the
     * type's internal representation. */
    Tcl_SetFromAnyProc* setFromAnyProc;

    /* Called to convert the object's internal
     * rep to this type. Frees the internal rep
     * of the old type. Returns TCL_ERROR on
     * failure. */
}

/*
 * One of the following structures exists for each object in the Tcl
 * system. An object stores a value as either a string, some internal
 * representation, or both.
 */
struct Tcl_Obj
{
    int refCount;               /* When 0 the object will be freed. */
    char* bytes;                /* This points to the first byte of the
                                 * object's string representation. The array
                                 * must be followed by a null byte (i.e., at
                                 * offset length) but may also contain
                                 * embedded null characters. The array's
                                 * storage is allocated by ckalloc. NULL
                                 * means the string rep is invalid and must
                                 * be regenerated from the internal rep.
                                 * Clients should use Tcl_GetStringFromObj
                                 * or Tcl_GetString to get a pointer to the
                                 * byte array as a readonly value. */
    int length;                 /* The number of bytes at *bytes, not
                                 * including the terminating null. */
    Tcl_ObjType* typePtr;       /* Denotes the object's type. Always
                                 * corresponds to the type of the object's
                                 * internal rep. NULL indicates the object
                                 * has no internal rep (has no type). */
    union internalRep_          /* The internal representation: */
    {
        int intValue;           /*   - an int integer value */
        double doubleValue;     /*   - a double-precision floating value */
        void* otherValuePtr;    /*   - another, type-specific value */
        Tcl_WideInt wideValue;  /*   - a int value */
        struct twoPtrValue_     /*   - internal rep as two pointers */
        {
            void* ptr1;
            void* ptr2;
        }

        twoPtrValue_ twoPtrValue;
    }

    internalRep_ internalRep;
}