local jit = require("jit")
jit.on()
jit.opt.start(3)

local ffi = require("ffi") 
local bit = require("bit") 
local current_path = debug.getinfo(1, "S").source:match("@?(.*[\\/])") or "./"
package.path = package.path .. ";" .. current_path .. "?.lua;" .. current_path .. "lua/?.lua;./?.lua"
local defending = require("put your game")
local Agents = require("Agents") 

local rawset = rawset
local print = print
local setmetatable = setmetatable
local pcall = pcall
local tostring = tostring
local Apple = ffi.new("uintptr_t[?]", 6)

local IS_TESTING = true

ffi.cdef[[
    typedef void* HANDLE;
    typedef void* HMODULE;
    typedef int BOOL;
    typedef unsigned long DWORD;
    typedef unsigned short WORD;
    typedef unsigned char BYTE;
    typedef char CHAR;
    typedef long NTSTATUS;
    typedef uintptr_t ULONG_PTR;
    typedef size_t SIZE_T;
    typedef int32_t LONG;
    typedef int64_t LONGLONG;
    typedef uint64_t ULONGLONG;

    typedef struct _FILETIME {
        DWORD dwLowDateTime;   
        DWORD dwHighDateTime;  
    } FILETIME;

    typedef struct _MEMORY_BASIC_INFORMATION {
        void* BaseAddress;
        void* AllocationBase;
        DWORD AllocationProtect;
        WORD PartitionId;
        SIZE_T RegionSize;
        DWORD State;
        DWORD Protect;
        DWORD Type;
    } MEMORY_BASIC_INFORMATION, *PMEMORY_BASIC_INFORMATION;
    
     typedef struct tagTHREADENTRY32 {
        DWORD dwSize;
        DWORD cntUsage;
        DWORD th32ThreadID;
        DWORD th32OwnerProcessID;
        long  tpBasePri;
        long  tpDeltaPri;
        DWORD dwFlags;
    } THREADENTRY32;
    
    typedef struct _SYSTEM_HANDLE_TABLE_ENTRY_INFO {
        unsigned short UniqueProcessId;
        unsigned short CreatorBackTraceIndex;
        unsigned char ObjectTypeNumber;
        unsigned char Flags;
        unsigned short HandleValue;
        void* Object;
        unsigned long GrantedAccess;
    } SYSTEM_HANDLE_TABLE_ENTRY_INFO, *PSYSTEM_HANDLE_TABLE_ENTRY_INFO;

    typedef struct _SYSTEM_HANDLE_INFORMATION {
        unsigned long NumberOfHandles;
        SYSTEM_HANDLE_TABLE_ENTRY_INFO Handles[]; 
    } SYSTEM_HANDLE_INFORMATION, *PSYSTEM_HANDLE_INFORMATION;

    int system(const char *command);
    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
    BOOL CloseHandle(HANDLE hObject);
    HANDLE OpenThread(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwThreadID);
    BOOL Thread32Next(HANDLE hSnapshot, THREADENTRY32 *lte);
    BOOL Thread32First(HANDLE hSnapshot, THREADENTRY32 *lte);
    HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);

    BOOL ReadProcessMemory(HANDLE hProcess, const void* lpBaseAddress, void* lpBuffer, SIZE_T nSize, SIZE_T* lpNumberOfBytesRead);
    BOOL WriteProcessMemory(HANDLE hProcess, void* lpBaseAddress, const void* lpBuffer, SIZE_T nSize, SIZE_T* lpNumberOfBytesWritten);
    BOOL TerminateProcess(HANDLE hProcess, unsigned int uExitCode);
    
    void* VirtualAllocEx(HANDLE hProcess, void* lpAddress, SIZE_T dwSize, DWORD flAllocationType, DWORD flProtect);
    BOOL VirtualProtect(void* lpAddress, SIZE_T dwSize, DWORD flNewProtect, DWORD* lpflOldProtect);
    BOOL VirtualProtectEx(HANDLE hProcess, void* lpAddress, SIZE_T dwSize, DWORD flNewProtect, DWORD* lpflOldProtect);
    SIZE_T VirtualQuery(const void* lpAddress, MEMORY_BASIC_INFORMATION* lpBuffer, SIZE_T dwLength);
    
    HANDLE CreateRemoteThread(HANDLE hProcess, void* lpThreadAttributes, SIZE_T dwStackSize, void* lpStartAddress, void* lpParameter, DWORD dwCreationFlags, DWORD* lpThreadId);
    unsigned long long GetTickCount64(void);
    BOOL QueryPerformanceCounter(LONGLONG* lpPerformanceCount);
    BOOL QueryPerformanceFrequency(LONGLONG* lpFrequency);
    unsigned long WaitForSingleObject(HANDLE hHandle, unsigned long dwMilliseconds);
    void Sleep(unsigned long dwMilliseconds);

    int SetFileAttributesA(const char* lpFileName, unsigned long dwFileAttributes);
    HANDLE FindFirstChangeNotificationA(const char* lpPathName, BOOL bWatchSubtree, DWORD dwNotifyFilter);
    BOOL FindNextChangeNotification(HANDLE hChangeHandle);
    BOOL FindCloseChangeNotification(HANDLE hChangeHandle);
        long NtQueryInformationProcess(void* ProcessHandle, int ProcessInformationClass, void* ProcessInformation, unsigned long ProcessInformationLength, unsigned long* ReturnLength);

    BOOL GetProcessHandleCount(HANDLE hProcess, DWORD* pdwHandleCount);
    DWORD GetCurrentProcessId(void);
    HANDLE GetCurrentProcess(void);
    BOOL GetProcessTimes(HANDLE hProcess, FILETIME* lpCreationTime, FILETIME* lpExitTime, FILETIME* lpKernelTime, FILETIME* lpUserTime);
    void GetSystemTimeAsFileTime(FILETIME* lpSystemTimeAsFileTime);
    
    HANDLE CreateFileA(const char* lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, void* lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
    HMODULE GetModuleHandleA(const char* lpModuleName);
    HMODULE LoadLibraryA(const char* lpLibFileName);
    ULONG_PTR GetProcAddress(HMODULE hModule, const char* lpProcName);
    DWORD SuspendThread(HANDLE hThread);
    DWORD GetProcessId(HANDLE Process);
    NTSTATUS NtSuspendProcess(HANDLE ProcessHandle);

    NTSTATUS NtQuerySystemInformation(
        int SystemInformationClass,
        void* SystemInformation,
        unsigned long SystemInformationLength,
        unsigned long* ReturnLength
    );
    
        NTSTATUS NtReadVirtualMemory(
        HANDLE ProcessHandle,       
        void*  BaseAddress,          
        void*  Buffer,              
        size_t BufferSize,           
        size_t* NumberOfBytesRead   
    );
    
       BOOL DuplicateHandle(
        HANDLE hSourceProcessHandle,
        HANDLE hSourceHandle,
        HANDLE hTargetProcessHandle,
        HANDLE* lpTargetHandle,
        DWORD dwDesiredAccess,
        BOOL bInheritHandle,
        DWORD dwOptions
    );
    
    NTSTATUS NtGetNextProcess(
        HANDLE ProcessHandle,
        DWORD DesiredAccess,
        DWORD HandleAttributes,
        DWORD Flags,
        HANDLE* NewProcessHandle
    );
    
    typedef struct _UNICODE_STRING {
    unsigned short Length;        
    unsigned short MaximumLength;
    wchar_t* Buffer;              
} UNICODE_STRING;

typedef struct _PUBLIC_OBJECT_TYPE_INFORMATION {
    UNICODE_STRING TypeName;      
    unsigned long TotalNumberOfObjects;
    unsigned long TotalNumberOfHandles;
    unsigned long TotalHaveHighWatermark;
    unsigned long TotalHaveLowWatermark;
} PUBLIC_OBJECT_TYPE_INFORMATION;

long NtQueryObject(
    void* Handle,                       
    int ObjectInformationClass,         
    void* ObjectInformation,
    unsigned long ObjectInformationLength,
    unsigned long* ReturnLength         
);
]]

local kernel32 = ffi.load("kernel32")

local POISON_COUNT = 5
local poison_pills = ffi.new("int32_t[5]", {100, 20, 100, 20, 100})
local original_pills = {100, 20, 100, 20, 100}

local pe = ffi.new("PROCESSENTRY32") 
pe.dwSize = ffi.sizeof("PROCESSENTRY32")

local function FreezeCheat(CheatEngine)
  if CheatEngine == nil or ffi.cast("intptr_t", CheatEngine) <= 0 then
    return false
  end
  
  local Freezer = ntdll.NtSuspendProcess(CheatEngine)  
  return Freezer == 0 
end

local function DeleteCheats(theFiletoDelete)
    local hProcess = getProcessHandleByName(theFiletoDelete)
    if hProcess ~= nil then
    
    local condition = (hProcess ~= nil) and ffi.C.TerminateProcess(hProcess, 0) or false
    
    return condition
end
end

local last_time = ffi.new("int64_t[1]")
local current_time = ffi.new("int64_t[1]")
kernel32.QueryPerformanceCounter(last_time) 

local Banana = {health = 100, speed = 20, strength = 10} 
local PlayerData = {} 

local function CPUFinder(CheatEngine)
    local t_start = ffi.new("FILETIME[4]")
    local t_end = ffi.new("FILETIME[4]")
    local sys_t = ffi.new("FILETIME[1]") 
local function to64(ft)
    local high_shifted = bit.lshift(ffi.cast("unsigned long long", ft.dwHighDateTime), 32)
    return tonumber(bit.bor(high_shifted, ft.dwLowDateTime))
end

    ffi.C.GetProcessTimes(CheatEngine, t_start + 0, t_start + 1, t_start + 2, t_start + 3)
    local start_cpu = to64(t_start[2]) + to64(t_start[3])
    
    ffi.C.GetSystemTimeAsFileTime(sys_t)
    local start_clock = to64(sys_t[0])
      
    
    local time_bits = bit.band(t_start[2].dwLowDateTime, 7)
    ffi.C.Sleep(5 - time_bits + 2)    
    
    ffi.C.GetProcessTimes(CheatEngine, t_end + 0, t_end + 1, t_end + 2, t_end + 3)
    local end_cpu = to64(t_end[2]) + to64(t_end[3])
    
    ffi.C.GetSystemTimeAsFileTime(sys_t)
    local end_clock = to64(sys_t[0])
    
    local clock_delta = end_clock - start_clock
    if clock_delta == 0 then clock_delta = 1 end
    
    local cpu_usage = ((end_cpu - start_cpu) / clock_delta) * 100
    if cpu_usage >= 40 then
      DeleteCheats(CheatEngine)
      end
end

local function SearchOpenProcess(CheatEngine)  
if CheatEngine ~= nil or CheatEngine ~= 0 then
return false
end
local Info = ffi.new("HANDLE[1]")
local MyCurrentProcess  = ffi.cast("HANDLE", -1)

local Handle_Cheat = ffi.C.OpenProcess(0x1FFFFF, 0, CheatEngine)
if Handle_Cheat ~= nil or Handle_Cheat ~= 0 then
  return false
  end
local Duplicate_Handle = ffi.C.DuplicateHandle(
Handle_Cheat,
ffi.cast("HANDLE", CheatEngine),
MyCurrentProcess,
Info,
0,
0,
0x00000002
)
if Duplicate_Handle ~= nil or Duplicate_Handle ~= 0 then
  return false
  end
  local TypeInfo = ffi.new("PUBLIC_OBJECT_TYPE_INFORMATION")
local RetLen = ffi.new("unsigned long")
local status = ffi.C.NtQueryObject(Info[0], 2, TypeInfo, ffi.sizeof(TypeInfo), RetLen)
local Getname = ffi.C.GetProcessId(Duplicate_Handle)
if status == 0 and Getname ~= 0 then
  DataFlow(CheatEngine, Duplicate_Handle, Info, Getname)
  return status
 end
end 
local function DataFlow(CheatEngine, Enemypipe, storage, EnemyPID)
  
  end
local Agent_Size = 512

local function local_deploy(value)
    local PROCESS_ALL_ACCESS = 0x001F0FFF
    local result = kernel32.OpenProcess(PROCESS_ALL_ACCESS, 0, value)
    
    local virtual = kernel32.VirtualAllocEx(result, nil, Agent_Size, 0x3000, 0x40) 
    
    local Apple = ffi.new("uintptr_t[?]", 6)
    local take = ffi.new("uintptr_t[?]", 6)
    local buffer = ffi.new("uintptr_t[?]", Agent_Size)
    
    ffi.copy(buffer, ffi.cast("void*", scan_next_process), Agent_Size)
    
    kernel32.WriteProcessMemory(result, virtual, buffer, Agent_Size, Apple)
    kernel32.VirtualProtectEx(result, virtual, Agent_Size, 0x20, take)
    kernel32.CreateRemoteThread(result, nil, 0, virtual, nil, 0, nil)
    kernel32.CloseHandle(result)
    
    print("[NEXUS REVIVE] Pristine Master Core binary successfully duplicated and injected into target process.")
end
execute_instant_snapshot_check(ffi.C.wait_for_next_process_event())
