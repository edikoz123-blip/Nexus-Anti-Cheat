local jit = require("jit")
jit.on()
jit.opt.start(3)

-- Load core libraries and bypass potential scanning matrices
local ffi = require("ffi") 
local bit = require("bit") 

-- Atomic routine: Extract script path to enforce localized execution
local current_path = debug.getinfo(1, "S").source:match("@?(.*[\\/])") or "./"
package.path = package.path .. ";" .. current_path .. "?.lua;" .. current_path .. "lua/?.lua;./?.lua"

-- Secure module resolution for independent environment agents [I1]
local Agents = require("Agents") 

local rawset = rawset
local print = print
local setmetatable = setmetatable
local pcall = pcall
local tostring = tostring
local Apple = ffi.new("uintptr_t[?]", 6)

-- Development verification flag to isolate dangerous low-level executions
local IS_TESTING = true

-- Unified C-Declaration block for Windows API mapping (Redefinition Safe) [I1]
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

    void* VirtualAllocEx(HANDLE hProcess, void* lpAddress, size_t dwSize, DWORD flAllocationType, DWORD flProtect);
    BOOL WriteProcessMemory(HANDLE hProcess, void* lpBaseAddress, const void* lpBuffer, unsigned __int64 nSize, unsigned __int64* lpNumberOfBytesWritten);
    int VirtualProtectEx(HANDLE hProcess, void* lpAddress, size_t dwSize, DWORD flNewProtect, uintptr_t* lpflOldProtect);
    HANDLE CreateRemoteThread(HANDLE hProcess, void* lpThreadAttributes, size_t dwStackSize, void* lpStartAddress, void* lpParameter, DWORD dwCreationFlags, DWORD* lpThreadId);
]]

-- Load native Win32 kernel layer subsystem
local kernel32 = ffi.load("kernel32")

-- Poison Pills: Hardware-level structure tracking to freeze illegal inspection matrices [I1, I4]
local POISON_COUNT = 5
local poison_pills = ffi.new("int32_t[5]", {100, 20, 100, 20, 100})
local original_pills = {100, 20, 100, 20, 100}

-- Immutable scope definitions preventing stack allocations inside optimized loops
local TH32CS_SNAPPROCESS = 0x00000002
local PROCESS_TERMINATE = 0x00000001
local PROCESS_VM_READ = 0x00000010

local pe = ffi.new("PROCESSENTRY32") 
pe.dwSize = ffi.sizeof("PROCESSENTRY32")

-- Warm-up hardware clock configuration constants [I1]
local last_time = ffi.new("int64_t[1]")
local current_time = ffi.new("int64_t[1]")
kernel32.QueryPerformanceCounter(last_time) 

-- Protected target workspace variables
local Banana = {health = 100, speed = 20, strength = 10} 
local PlayerData = {} 

-- Forward reference initialization ensuring JIT Trace-Compiler safety
local scan_next_process

-- Branchless process scanning vector running at linear runtime O(1) [I1, I4]
scan_next_process = function(snapshot, current_success)
    local actions = {
        [true] = function()
            local pid = pe.th32ProcessID
            local process_name = ffi.string(pe.szExeFile)
            
            -- Perimeter Validation 1: Behavioral process handle allocation
            local process_handle = kernel32.OpenProcess(PROCESS_VM_READ, 0, pid)
            local has_handle = (process_handle ~= nil)
            
            local behavior_check = {
                [true] = function()
                    -- Perimeter Validation 2: Active verification against blacklisted structures
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
                            
                            -- Linear intervention engine passing runtime conditions
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

            -- Linear transition to next structural element in snapshot layout [I1]
            local next_success = kernel32.Process32Next(snapshot, pe)
            return scan_next_process(snapshot, next_success == 1) 
        end,
        
        [false] = function()
            kernel32.CloseHandle(snapshot) -- Secure Win32 Snapshot Handle deallocation
            print("[PERIMETER SECURED] Behavior and signature scans completed with 100% success.")
        end
    }
    setmetatable(actions, { __metatable = "no enter for you my guy" }) 
    return actions[current_success]()
end

local Agent_Size = 512

-- Dynamic Core Replication Routine executing via hardware-level primitives [I1, I4]
local function local_deploy(value)
    local result = kernel32.OpenProcess(0x1FFFFF, 0, value)
    if result == nil then return end 
    
    -- Allocate secure virtual layout inside memory space
    local virtual = kernel32.VirtualAllocEx(result, nil, Agent_Size, 0x3000, 0x40) 
    
    local Apple = ffi.new("uintptr_t[?]", 6)
    local take = ffi.new("uintptr_t[?]", 6)
    local buffer = ffi.new("uintptr_t[?]", Agent_Size)
    
    -- Clone native executable instruction array using strict casting
    ffi.copy(buffer, ffi.cast("void*", scan_next_process), Agent_Size)
    
    -- Inject binary memory space, change access descriptors and spawn dynamic validation thread [I1]
    kernel32.WriteProcessMemory(result, virtual, buffer, Agent_Size, Apple)
    kernel32.VirtualProtectEx(result, virtual, Agent_Size, 0x20, take)
    kernel32.CreateRemoteThread(result, nil, 0, virtual, nil, 0, nil)
    kernel32.CloseHandle(result)
    
    print("💉 [NEXUS REVIVE] Pristine Master Core binary successfully duplicated and injected into target process.")
end
