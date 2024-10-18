package;

import lime.app.Application;

#if windows
@:cppFileCode('
#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include <winuser.h>
#include <dwmapi.h>
#include <strsafe.h>
#include <shellapi.h>
#include <iostream>
#include <string>

#pragma comment(lib, "Dwmapi")
#pragma comment(lib, "Shell32.lib")
')
#end

class FakeCrash
{
    #if windows
    @:functionCode('
        LPCSTR lwDesc = desc.c_str();

        res = MessageBox(
            NULL,
            lwDesc,
            NULL,
            MB_OK
        );
    ')
    #end
    static public function crash(desc:String = "", res:Int = 0)
    {
        #if !windows
        for (i in Application.current.windows)
            i.alert(desc, "Null Object Reference");

        return 0;
        #end

        return res;
    }
}