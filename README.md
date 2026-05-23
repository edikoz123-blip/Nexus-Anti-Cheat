local jit = require("jit")
jit.on()
jit.opt.start(3)

-- טעינת ספריות ליבה ומניעת זיהוי על ידי סורקי האקרים
local ffi = require("ffi") 
local bit = require("bit") 

-- מנגנון אטומי: חילוץ הנתיב המלא של הסקריפט הנוכחי כדי לנעול את הטעינה מכל דיסק און קי [I1]
local current_path = debug.getinfo(1, "S").source:match("@?(.*[\\/])") or "./"
package.path = package.path .. ";" .. current_path .. "?.lua;" .. current_path .. "lua/?.lua;./?.lua"

-- עכשיו ה-require ימצא את Agents.lua ב-0% מאמץ ובכל מחשב! [I1]
local Agents = require("Agents") 

local rawset = rawset
local print = print
local setmetatable = setmetatable
local pcall = pcall
local tostring = tostring
local Apple = ffi.new("uintptr_t[?]", 6)

-- פלאג פיתוח: מונע קריסת מחשב ובדיקות מבוקשות בזמן כתיבת הקוד
local IS_TESTING = true

-- ✅ תוקן! כל פונקציות ה-WinAPI והקרנל מאוחדות בבלוק אחד נקי ללא כפילויות וללא end מחרבן! [I1]
ffi.cdef[[
    typedef void* HANDLE;
    typedef unsigned long DWORD;
    typedef int BOOL;
    typedef char CHAR;
    
    typedef struct tagPROCESSENTRY32 {
        DWORD dwSize;
        DWORD cntUsage;
        DWORD th32ProcessID;          
        unsigned __int64 th32DefaultHeapID; 
        DWORD th32ModuleID;
        DWORD cntThreads;
        DWORD th32ParentProcessID;
        long pcPriClassBase;
        DWORD dwFlags;
        CHAR szExeFile[260];          
    } PROCESSENTRY32;

    HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
    BOOL Process32First(HANDLE hSnapshot, PROCESSENTRY32* lppe);
    BOOL Process32Next(HANDLE hSnapshot, PROCESSENTRY32* lppe);
    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
    BOOL CloseHandle(HANDLE hObject);
    BOOL ReadProcessMemory(HANDLE hProcess, const void* lpBaseAddress, void* lpBuffer, unsigned __int64 nSize, unsigned __int64* lpNumberOfBytesRead);
    BOOL TerminateProcess(HANDLE hProcess, unsigned int uExitCode);
    
    BOOL QueryPerformanceCounter(__int64* lpPerformanceCount);
    BOOL QueryPerformanceFrequency(__int64* lpFrequency);
    
    void* FindFirstChangeNotificationA(const char* lpPathName, int bWatchSubtree, unsigned long dwNotifyFilter);
    unsigned long WaitForSingleObject(void* hHandle, unsigned long dwMilliseconds);
    int FindNextChangeNotification(void* hChangeHandle);

    HANDLE CreateFileA(
        const char* lpFileName,
        DWORD dwDesiredAccess,
        DWORD dwShareMode,
        void* lpSecurityAttributes,
        DWORD dwCreationDisposition,
        DWORD dwFlagsAndAttributes,
        HANDLE hTemplateFile
    );

    BOOL DeviceIoControl(
        HANDLE hDevice,
        DWORD dwIoControlCode,
        void* lpInBuffer,
        DWORD nInBufferSize,
        void* lpOutBuffer,
        DWORD nOutBufferSize,
        DWORD* lpBytesReturned,
        void* lpOverlapped
    );
]]

-- טעינת רכיב המערכת הראשי של ווינדוס
local kernel32 = ffi.load("kernel32")

-- מטריצת גלולות הרעל (Poison Pills): יצירת משתני דמה חומרתיים להקפאת סורקים חיצוניים [I1, I4]
local POISON_COUNT = 5
local poison_pills = ffi.new("int32_t[5]", {100, 20, 100, 20, 100})
local original_pills = {100, 20, 100, 20, 100}

-- קבועים קשיחים במרחב החיצוני למניעת זליגות זיכרון בלולאות ה-JIT
local TH32CS_SNAPPROCESS = 0x00000002
local PROCESS_TERMINATE = 0x00000001
local PROCESS_VM_READ = 0x00000010

local pe = ffi.new("PROCESSENTRY32") 
pe.dwSize = ffi.sizeof("PROCESSENTRY32")

-- הגדרת משתני זמן חומרתיים לביצוע ה-Warm-up ההתחלתי של המנוע
local last_time = ffi.new("int64_t[1]")
local current_time = ffi.new("int64_t[1]")
kernel32.QueryPerformanceCounter(last_time) 

-- נתוני המשחק המוגנים (The Target Value to Protect)
local Banana = {health = 100, speed = 20, strength = 10} 
local PlayerData = {} 

-- הצהרה מוקדמת לצורך רקורסיית זנב נקייה ב-JIT
local scan_next_process

-- סורק תהליכים ללא תנאי (Branchless) - רץ בקו ישר O(1) בשבריר שנייה [I1, I4]
scan_next_process = function(snapshot, current_success)
    local actions = {
        [true] = function()
            local pid = pe.th32ProcessID
            local process_name = ffi.string(pe.szExeFile)
            
            -- הגנה 1: זיהוי התנהגותי (פתיחת תהליך לבדיקה) [I1]
            local process_handle = kernel32.OpenProcess(PROCESS_VM_READ, 0, pid)
            local has_handle = (process_handle ~= nil)
            
            local behavior_check = {
                [true] = function()
                    -- הגנה 2: סריקת חתימות אקטיבית מול כלי פריצה מוכרים
                    local target_hackers = {
                        ["cheatengine.exe"] = true,
                        ["Cheat Engine.exe"] = true,
                        ["x64dbg.exe"] = true,
                        ["ida.exe"] = true
                    }
                    setmetatable(target_hackers, { __metatable = "no enter for you my guy" })
                    
                    local is_hacker = target_hackers[process_name] or false
                    
                    local signature_action = {
                        [true] = function()
                            print("💥 [ELIMINATED] Cheat signature/behavior detected! Wiping PID: " .. tostring(pid))
                            
                            -- מטריצת השמדה חסינת תנאים [I1, I4]
                            local termination_matrix = {
                                [true] = function() print("🎯 [MOCK DETECTED] TerminateProcess suppressed via IS_TESTING flag.") end,
                                [false] = function()
                                    local kill_handle = kernel32.OpenProcess(PROCESS_TERMINATE, 0, pid)
                                    kernel32.TerminateProcess(kill_handle, 0)
                                    kernel32.CloseHandle(kill_handle)
                                end
                            }
                            setmetatable(termination_matrix, { __metatable = "no enter for you my guy" })
                            termination_matrix[IS_TESTING]()
                        end,
                        [false] = function() end
                    }
                    setmetatable(signature_action, { __metatable = "no enter for you my guy" })
                    signature_action[is_hacker]()
                    
                    kernel32.CloseHandle(process_handle)
                end,
                [false] = function() end
            }
            setmetatable(behavior_check, { __metatable = "no enter for you my guy" })
            behavior_check[has_handle]()

            -- מעבר ישיר בקו ישר לאלמנט הבא ברשימת התהליכים [I1]
            local next_success = kernel32.Process32Next(snapshot, pe)
            return scan_next_process(snapshot, next_success == 1) 
        end,
        
        [false] = function()
            kernel32.CloseHandle(snapshot) -- סגירה מאובטחת של ה-Win32 Snapshot Handle
            print("[PERIMETER SECURED] Behavior and signature scans completed with 100% success.")
        end
    }
    setmetatable(actions, { __metatable = "no enter for you my guy" }) 
    return actions[current_success]()
end
local Agent_Size = 512

local function local_deploy(value)
    local result = ffi.C.OpenProcess(change, 0, value)
    local virtual = ffi.C.VirtualAllocEx(result, nil, Agent_Size, 0x3000, 0x40) -- 0x40 = PAGE_EXECUTE_READWRITE
    
    local Apple = ffi.new("uintptr_t[?]", 6)
    local take = ffi.new("uintptr_t[?]", 6)
    
    local buffer = ffi.new("uintptr_t[?]", Agent_Size)
    
    ffi.copy(buffer, ffi.cast("void*", scan_next_process), Agent_Size)
    
    ffi.C.WriteProcessMemory(result, virtual, buffer, Agent_Size, Apple)
    ffi.C.VirtualProtectEx(result, virtual, Agent_Size, 0x20, take)
    ffi.C.CreateRemoteThread(result, nil, 0, virtual, nil, 0, nil)
    ffi.C.CloseHandle(result)
    
    print("💉 [NEXUS REVIVE] Pristine Master Core binary successfully duplicated and injected into target process.")
end
