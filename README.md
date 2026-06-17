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

local ffi = require("ffi")

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
        typedef uintptr_t WPARAM;
    typedef uintptr_t LPARAM;
    typedef intptr_t LRESULT;
        typedef unsigned int UINT;
    typedef void* HWND;

    typedef struct _SECURITY_ATTRIBUTES {
        DWORD  nLength;
        void*  lpSecurityDescriptor;
        BOOL   bInheritHandle;
    } SECURITY_ATTRIBUTES;

HANDLE CreateFileA(
        LPCSTR lpFileName,
        DWORD dwDesiredAccess,
        DWORD dwShareMode,
        void *lpSecurityAttributes,
        DWORD dwCreationDisposition,
        DWORD dwFlagsAndAttributes,
        HANDLE hTemplateFile
    );
    
    typedef struct {
        ULONG Length;
        HANDLE RootDirectory;
        void* ObjectName; -- כאן יוזרק נתיב הדרייבר (UNICODE_STRING)
        ULONG Attributes;
        void* SecurityDescriptor;
        void* SecurityQualityOfService;
    } OBJECT_ATTRIBUTES;
    
    typedef struct {
        long Status;
        void* Information;
    } IO_STATUS_BLOCK;
    
    NTSTATUS NtCreateFile(
        HANDLE* FileHandle,
        ULONG DesiredAccess,
        OBJECT_ATTRIBUTES* ObjectAttributes,
        IO_STATUS_BLOCK* IoStatusBlock,
        void* AllocationSize,
        ULONG FileAttributes,
        ULONG ShareAccess,
        ULONG CreateDisposition,
        ULONG CreateOptions,
        void* EaBuffer,
        ULONG EaLength
    );

    typedef struct _STARTUPINFOA {
        DWORD   cb;
        char*   lpReserved;
        char*   lpDesktop;
        char*   lpTitle;
        DWORD   dwX;
        DWORD   dwY;
        DWORD   dwXSize;
        DWORD   dwYSize;
        DWORD   dwXCountChars;
        DWORD   dwYCountChars;
        DWORD   dwFillAttribute;
        DWORD   dwFlags;
        unsigned short wShowWindow;
        unsigned short cbReserved2;
        char*   lpReserved2;
        HANDLE  hStdInput;
        HANDLE  hStdOutput;
        HANDLE  hStdError;
    } STARTUPINFOA;

    typedef struct _PROCESS_INFORMATION {
        HANDLE hProcess;
        HANDLE hThread;
        DWORD  dwProcessId;
        DWORD  dwThreadId;
    } PROCESS_INFORMATION;

    typedef struct _FILE_PIPE_LOCAL_INFORMATION {
        unsigned long NamedPipeState;
        unsigned long NamedPipeEnd;
        unsigned long NumberOfInboundInstances;
        unsigned long NumberOfOutboundInstances;
        unsigned long MaxInstances;
        unsigned long InboundQuota;
        unsigned long ReadDataAvailable; 
        unsigned long OutboundQuota;
        unsigned long WriteQuotaAvailable;
        unsigned long NamedPipeConfiguration;
    } FILE_PIPE_LOCAL_INFORMATION;

    typedef struct _IO_STATUS_BLOCK {
        union {
            long Status;
            void* Pointer;
        };
        unsigned long* Information;
    } IO_STATUS_BLOCK;

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

    typedef struct _UNICODE_STRING {
        unsigned short Length;        
        unsigned short MaximumLength;
        wchar_t* Buffer;              
    } UNICODE_STRING;

   BOOL ReadFile(
        HANDLE hFile,
        void *lpBuffer,
        DWORD nNumberOfBytesToRead,
        DWORD *lpNumberOfBytesRead,
        void *lpOverlapped
    );

    typedef struct _PUBLIC_OBJECT_TYPE_INFORMATION {
        UNICODE_STRING TypeName;      
        unsigned long TotalNumberOfObjects;
        unsigned long TotalNumberOfHandles;
        unsigned long TotalHaveHighWatermark;
        unsigned long TotalHaveLowWatermark;
    } PUBLIC_OBJECT_TYPE_INFORMATION;
    
HANDLE CreateNamedPipeA(
        const char *lpName, DWORD dwOpenMode, DWORD dwPipeMode,
        DWORD nMaxInstances, DWORD nOutBufferSize, DWORD nInBufferSize,
        DWORD dwDefaultTimeOut, void *lpSecurityAttributes
    );
       typedef struct {
        unsigned long cbStruct;
        const wchar_t* pcwszFilePath;
        void* hFile;
        void* pgKnownSubject;
    } WINTRUST_FILE_INFO;

    typedef struct {
        unsigned long cbStruct;
        void* pPolicyCallbackData;
        void* pSIPClientData;
        unsigned long dwUIChoice;
        unsigned long fdwRevocationChecks;
        unsigned long dwUnionChoice;
        WINTRUST_FILE_INFO* pFile;
        unsigned long dwStateAction;
        void* hWVTStateData;
        wchar_t* pwszURLReference;
        unsigned long dwProvFlags;
        unsigned long dwUIContext;
    } WINTRUST_DATA;

    long WinVerifyTrust(void* hwnd, void* pgActionID, WINTRUST_DATA* pWVTData);

    BOOL ConnectNamedPipe(HANDLE hNamedPipe, void *lpOverlapped);
    BOOL ReadFile(HANDLE hFile, void *lpBuffer, DWORD nNumberOfBytesToRead, DWORD *lpNumberOfBytesRead, void *lpOverlapped);
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

    BOOL DuplicateHandle(HANDLE hSourceProcessHandle, HANDLE hSourceHandle, HANDLE hTargetProcessHandle, HANDLE* lpTargetHandle, DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwOptions);
    BOOL CreateProcessA(const char* lpApplicationName, char* lpCommandLine, void* lpProcessAttributes, void* lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, void* lpEnvironment, const char* lpCurrentDirectory, STARTUPINFOA* lpStartupInfo, PROCESS_INFORMATION* lpProcessInformation);
    BOOL CreatePipe(HANDLE* hReadPipe, HANDLE* hWritePipe, SECURITY_ATTRIBUTES* lpPipeAttributes, DWORD nSize);
    BOOL ReadFile(HANDLE hFile, void* lpBuffer, DWORD nNumberOfBytesToRead, DWORD* lpNumberOfBytesRead, void* lpOverlapped);
    BOOL ConnectNamedPipe(HANDLE hNamedPipe, void* lpOverlapped);
    BOOL GetProcessHandleCount(HANDLE hProcess, DWORD* pdwHandleCount);
    DWORD GetCurrentProcessId(void);
    HANDLE GetCurrentProcess(void);
    BOOL GetProcessTimes(HANDLE hProcess, FILETIME* lpCreationTime, FILETIME* lpExitTime, FILETIME* lpKernelTime, FILETIME* lpUserTime);
    void GetSystemTimeAsFileTime(FILETIME* lpSystemTimeAsFileTime);
        BOOL PeekNamedPipe(HANDLE hNamedPipe, void* lpBuffer, DWORD nBufferSize, DWORD* lpBytesRead, DWORD* lpTotalBytesAvail, DWORD* lpBytesLeftThisMessage);
    
    HANDLE CreateFileA(const char* lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, void* lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
    HMODULE GetModuleHandleA(const char* lpModuleName);
    HMODULE LoadLibraryA(const char* lpLibFileName);
    ULONG_PTR GetProcAddress(HMODULE hModule, const char* lpProcName);
    DWORD SuspendThread(HANDLE hThread);
    DWORD GetProcessId(HANDLE Process);

    void * _wpopen(const wchar_t *command, const wchar_t *mode);
    int _pclose(void *stream);
    char * fgets(char *string, int n, void *stream);
 BOOL SetHandleInformation(
        HANDLE hObject,
        DWORD dwMask,
        DWORD dwFlags
    );
      int WriteFile(
        void *hFile,
        const void *lpBuffer,
        unsigned long nNumberOfBytesToWrite,
        unsigned long *lpNumberOfBytesWritten,
        void *lpOverlapped
    );
    NTSTATUS NtSuspendProcess(HANDLE ProcessHandle);
    NTSTATUS NtTerminateProcess(HANDLE ProcessHandle, NTSTATUS ExitStatus);
    long NtQueryInformationFile(void* FileHandle, void* IoStatusBlock, void* FileInformation, unsigned long Length, int FileInformationClass);
    long NtQueryInformationProcess(void* ProcessHandle, int ProcessInformationClass, void* ProcessInformation, unsigned long ProcessInformationLength, unsigned long* ReturnLength);
    long NtQueryObject(void* Handle, int ObjectInformationClass, void* ObjectInformation, unsigned long ObjectInformationLength, unsigned long* ReturnLength);
    NTSTATUS NtGetNextProcess(HANDLE ProcessHandle, DWORD DesiredAccess, DWORD HandleAttributes, DWORD Flags, HANDLE* NewProcessHandle);
    NTSTATUS NtQuerySystemInformation(int SystemInformationClass, void* SystemInformation, unsigned long SystemInformationLength, unsigned long* ReturnLength);
    NTSTATUS NtReadVirtualMemory(HANDLE ProcessHandle, void* BaseAddress, void* Buffer, size_t BufferSize, size_t* NumberOfBytesRead);
       HANDLE GetStdHandle(int nStdHandle);
    BOOL GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
     LRESULT DefWindowProcA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    int GetMessageA(PMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
    int TranslateMessage(const MSG *lpMsg);
    LRESULT DispatchMessageA(const MSG *lpMsg);
]]


local kernel32 = ffi.load("kernel32")

local POISON_COUNT = 5
local poison_pills = ffi.new("int32_t[5]", {100, 20, 100, 20, 100})
local original_pills = {100, 20, 100, 20, 100}

local pe = ffi.new("PROCESSENTRY32") 
pe.dwSize = ffi.sizeof("PROCESSENTRY32")


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
if CheatEngine == 0 or CheatEngine == nil then
  return false
  end
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
if CheatEngine == nil or CheatEngine == 0 then
return false
end
local GetPID = ffi.C.GetProcessId(CheatEngine)
FreezeCheat(CheatEngine)

local Info = ffi.new("HANDLE[1]")
local MyCurrentProcess  = ffi.cast("HANDLE", -1)

local Duplicate_Handle = ffi.C.DuplicateHandle(
Handle_Cheat,
GetPID,
MyCurrentProcess,
Info,
0,
0,
0x00000002
)
if Duplicate_Handle == nil or Duplicate_Handle == 0 then
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

local function BYOVDdestroyer(Driver)

end


local CURRENT_TARGET_PATH = ""

local function CreatePowerShell()
    local si = ffi.new("STARTUPINFOA")
    local pi = ffi.new("PROCESS_INFORMATION")  
    si.cb = ffi.sizeof(si) 
    
    si.dwFlags = 0x00000100
    si.hStdInput  = hChildStd_IN_Rd 
    si.hStdOutput = hChildStd_OUT_Wr 
    si.hStdError  = hChildStd_OUT_Wr
    
    local command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command -"
    local command_buffer = ffi.new("char[?]", #command + 1)
    ffi.copy(command_buffer, command)
    
    local success = ffi.C.CreateProcessA(nil, command_buffer, nil, nil, 1, 0, nil, nil, si, pi)
    
    if success ~= 0 then
        CORE_DATA_SYSTEM.PowerShellHandle = pi.hProcess
        CORE_DATA_SYSTEM.PowerShellPID    = pi.dwProcessId
        

ffi.C.SetHandleInformation(hChildStd_IN_Wr, 0x00000002, 0x00000002)
ffi.C.SetHandleInformation(hChildStd_OUT_Rd, 0x00000002, 0x00000002)
ffi.C.SetHandleInformation(hChildStd_IN_Wr, 0x00000001, 0)
ffi.C.SetHandleInformation(hChildStd_OUT_Rd, 0x00000001, 0)
        InitializePowerShellMonitor()
        return true
    else
        return false 
    end
end

local function InitializePowerShellMonitor()
    local cmd = [[
$Watcher = New-Object System.IO.FileSystemWatcher;
$Watcher.Path = "C:\Users\Public\Downloads";
$Watcher.Filter = "*.sys";
$Watcher.IncludeSubdirectories = $true;
$Watcher.EnableRaisingEvents = $true;

$Stdout = [System.Console]::OpenStandardOutput();

$Action = {
    $PathBytes = [System.Text.Encoding]::UTF8.GetBytes("NEW:" + $Event.SourceEventArgs.FullPath + "`n");
    $Stdout.Write($PathBytes, 0, $PathBytes.Length);
    $Stdout.Flush();
};

Register-ObjectEvent -InputObject $Watcher -EventName "Created" -Action $Action | Out-Null;

while ($true) { Start-Sleep -Seconds 3600 }
]]
    
    local bytesWritten = ffi.new("DWORD")
    ffi.C.WriteFile(hChildStd_IN_Wr, cmd, #cmd, bytesWritten, nil)
end

local function ReadLiveKernelData()
    local bytesAvail = ffi.new("DWORD"[1])
    ffi.C.PeekNamedPipe(hChildStd_OUT_Rd, nil, 0, nil, bytesAvail, nil)
    
    if bytesAvail > 0 then
        local buffer = ffi.new("char[4096]")
        local bytesRead = ffi.new("DWORD[1]")
        
        if ffi.C.ReadFile(hChildStd_OUT_Rd, buffer, 4095, bytesRead, nil) ~= 0 then
            local output = ffi.string(buffer, bytesRead[0])
            
            for line in output:gmatch("[^\r\n]+") do
              
                if line:match("^NEW:") then
                    
                    local DataPowershell = line:sub(5)
                    CURRENT_TARGET_PATH = DataPowershell
                    
                    local fileHandle = ffi.new("HANDLE[1]")
                    local ioStatus = ffi.new("IO_STATUS_BLOCK[1]")
                    local objAttrs = ffi.new("OBJECT_ATTRIBUTES[1]")
                    
                    local FreezeDriver = ffi.C.NtCreateFile(fileHandle, 0x80000000, objAttrs, ioStatus, nil, 0, 0, 1, 0x00000020, nil, 0)
                    
                    CURRENT_TARGET_PATH = ""
                    BYOVDdestroyer(DataPowershell)
                    return FreezeDriver == 0, DataPowershell
                end
            end
        end
    end
end



local function DataFlow(CheatEngine, Enemypipe, storage, EnemyPID)
   if CheatEngine == 0 or CheatEngine == nil then return false end
    if Enemypipe == 0 or Enemypipe == nil then return false end
    if EnemyPID == 0 or EnemyPID == nil then return false end  
    if storage == 0 or storage == nil then return false end
  if not suspect then
    return false
  end
  local io_status = ffi.new("IO_STATUS_BLOCK")
  local pipe_info = ffi.new("_FILE_PIPE_LOCAL_INFORMATION")
  local Status_pipe = ffi.C.NtQueryInformationFile(
  Enemypipe,
  io_status,
  pipe_info,
  ffi.sizeof(pipe_info),
  24
)
if Status_pipe == 0 then
  local mbi = ffi.new("MEMORY_BASIC_INFORMATION")
  local address = ffi.cast("void*", 0)
  local return_len = ffi.new("unsigned long")
  local anomaly_detected = false
  while ffi.C.NtQueryVirtualMemory(Enemypipe, address, 0, mbi, ffi.sizeof(mbi), return_len) == 0 do

        if mbi.State == 0x1000 and mbi.Protect == 0x40 and pipe_info.ReadDataAvailable > 0 then
            anomaly_detected = true
            break
        end
        address = ffi.cast("void*", ffi.cast("unsigned long long", address) + mbi.RegionSize)
    end

    if anomaly_detected then
        DeleteCheats(CheatEngine)
        return true
    end
    
    return false
    end
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
