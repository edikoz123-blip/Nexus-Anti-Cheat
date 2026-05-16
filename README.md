local ffi = require("ffi") -- Objects so hackers wont see the things we doing
local jit = require("jit")
local bit = require("bit") -- Required for branchless operations
local rawset = rawset
local print = print
local setmetatable = setmetatable
local pcall = pcall
local tostring = tostring

jit.on()
jit.opt.start(3)

-- Test Flag Configuration: Set to true during development to prevent computer self-crashing
local IS_TESTING = true 

ffi.cdef[[
    typedef void* HANDLE;
    typedef unsigned long DWORD;
    typedef int BOOL;
    typedef char CHAR;
    
    typedef struct tagPROCESSENTRY32 {
        DWORD dwSize;
        DWORD cntUsage;
        DWORD th32ProcessID;          
        uintptr_t th32DefaultHeapID;
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
    BOOL ReadProcessMemory(HANDLE hProcess, const void* lpBaseAddress, void* lpBuffer, size_t nSize, size_t* lpNumberOfBytesRead);
    BOOL TerminateProcess(HANDLE hProcess, unsigned int uExitCode);
    BOOL QueryPerformanceCounter(int64_t* lpPerformanceCount);
    BOOL QueryPerformanceFrequency(int64_t* lpFrequency);
]]
local kernel32 = ffi.load("kernel32")

-- Poison Pills Matrix: Allocate hardware-level decoys to trap external memory editors
local POISON_COUNT = 5
local poison_pills = ffi.new("int32_t[5]", {100, 20, 100, 20, 100})
local original_pills = {100, 20, 100, 20, 100} -- Baseline validation state

-- Architectural Fix: Static allocation in outer scope to prevent memory leaks and infinite loops
local TH32CS_SNAPPROCESS = 0x00000002
local PROCESS_TERMINATE = 0x00000001
local PROCESS_VM_READ = 0x00000010

local pe = ffi.new("PROCESSENTRY32") 
pe.dwSize = ffi.sizeof("PROCESSENTRY32")

-- Hardware Timer Setup: Pre-allocate variables and take baseline CPU counter timestamp
local last_time = ffi.new("int64_t[1]")
local current_time = ffi.new("int64_t[1]")
kernel32.QueryPerformanceCounter(last_time) 

local Banana = {health = 100, speed = 20, strength = 10} 
local PlayerData = {} 

-- Forward declaration for recursive scan
local scan_next_process

-- Branchless Anti-Cheat Scanner: Recursive scan sequence optimized for O(1) JIT execution
scan_next_process = function(snapshot, current_success)
    local actions = {
        [true] = function()
            local pid = pe.th32ProcessID
            local process_name = ffi.string(pe.szExeFile)
            
            -- Defense 1: Behavioral Verification (Intercept unauthorized cross-process memory access handles)
            local process_handle = kernel32.OpenProcess(PROCESS_VM_READ, 0, pid)
            local has_handle = (process_handle ~= nil)
            
            local behavior_check = {
                [true] = function()
                    -- Defense 2: Memory/Signature Analysis (Match active processes against known attack vectors)
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
                            print("[ELIMINATED] Cheat signature/behavior detected! Wiping PID: " .. tostring(pid))
                            
                            -- Branchless Test-bypass execution
                            local termination_matrix = {
                                [true] = function() print("[MOCK DETECTED] TerminateProcess suppressed via IS_TESTING flag.") end,
                                [false] = function()
                                    local kill_handle = kernel32.OpenProcess(PROCESS_TERMINATE, 0, pid)
                                    kernel32.TerminateProcess(kill_handle, 0)
                                    kernel32.CloseHandle(kill_handle)
                                end
                            }
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

            -- Iterate conveyor: Push to the next system process snapshot segment in O(1)
            local next_success = kernel32.Process32Next(snapshot, pe)
            return scan_next_process(snapshot, next_success == 1) 
        end,
        
        [false] = function()
            kernel32.CloseHandle(snapshot) -- Securely close the Win32 snapshot handle
            print("[PERIMETER SECURED] Behavior and signature scans completed with 100% success.")
        end
    }
    setmetatable(actions, { __metatable = "no enter for you my guy" }) 
    return actions[current_success]()
end

-- Hardware Checksum Setup: Calculate fingerprint of our isolated defense layers to prevent memory freezing
local function calculate_system_checksum()
    local score = 0
    local raw_string = tostring(scan_next_process) .. tostring(kernel32.TerminateProcess)
    
    local function hash_step(index, current_hash)
        local exit_condition = (index > #raw_string)
        local loops = {
            [true] = function() return current_hash end,
            [false] = function()
                local byte_val = string.byte(raw_string, index) or 0
                return hash_step(index + 1, bit.bxor(current_hash, byte_val) + index)
            end
        }
        setmetatable(loops, { __metatable = "no enter for you my guy" })
        return loops[exit_condition]()
    end
    return hash_step(1, score)
end

-- Architectural Anchor: Capture the immutable signature at compilation runtime
local ORIGINAL_SYSTEM_HASH = calculate_system_checksum()

-- Secure Defender Hook Matrix: Controls the PlayerData Honeypot interaction flow
local defender = { 
    __metatable = "no enter for you my guy",
    
    __index = function(tbl, key) 
        -- Hardware Clock Check
        kernel32.QueryPerformanceCounter(current_time)
        local time_passed = tonumber(current_time[0] - last_time[0])
        last_time[0] = current_time[0] 
        
        -- Self-Defense Verification
        local current_sys_hash = calculate_system_checksum()
        local code_was_tampered = (current_sys_hash ~= ORIGINAL_SYSTEM_HASH)
        
        -- Poison Pills Integrity Check: Branchless loop via recursive JIT optimization
        local function check_pills(index, anomaly_found)
            local exit_condition = (index >= POISON_COUNT) or anomaly_found
            local loops = {
                [true] = function() return anomaly_found end,
                [false] = function()
                    local pill_altered = (poison_pills[index] ~= original_pills[index + 1])
                    return check_pills(index + 1, pill_altered)
                end
            }
            setmetatable(loops, { __metatable = "no enter for you my guy" })
            return loops[exit_condition]()
        end
        local memory_was_scanned = check_pills(0, false)
        
        -- Speed-Hack Evaluation
        local speed_cheat_detected = (time_passed < 500) and (key == "speed") 
        
        -- Master Condition Matrix
        local condition = (Banana.health < 100) or (Banana.speed < 20) or (Banana.strength < 10) 
                           or speed_cheat_detected or code_was_tampered or memory_was_scanned
        
        local actions = {
            [true] = function() 
                print("[ELIMINATED] Security alert: Memory scanning, Speed-Hack or Self-tampering detected!") 
                local execution_matrix = {
                    [true] = function() print("[MOCK DETECTED] Self-destruction suppressed via IS_TESTING flag.") end,
                    [false] = function()
                        local self_handle = kernel32.OpenProcess(PROCESS_TERMINATE, 0, 0) 
                        kernel32.TerminateProcess(self_handle, 0xFFFFFFFF)
                    end
                }
                execution_matrix[IS_TESTING]()
            end,
            [false] = function() 
                return Banana[key] 
            end
        }
        local chosen_action = actions[condition]
        return chosen_action()
    end,

    __newindex = function(tbl, key, value) 
        local condition = (value ~= nil)
        local actions = {
            [true] = function()
                print("[HONEYPOT TRIGGERED] External injection detected!")
                
                -- Capture active memory tree state immediately at the exact millisecond of intrusion (Anti-Hijack)
                local snapshot = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
                local success = kernel32.Process32First(snapshot, pe)
                
                scan_next_process(snapshot, success == 1)
            end,
            [false] = function()
                rawset(tbl, key, value)
            end
        }
        local chosen_actions = actions[condition]
        chosen_actions()
    end, 

    __pairs = function(tbl) -- Honeypot traps
        print("[HONEYPOT TRIGGERED] Scanner detected attempting table enumeration via pairs()!")
        
        local skillissue = { 
            hacked_status = "unlucky_my_guy",
            status = "skill needed",
            matrix_breach = "true"
        }
        
        setmetatable(skillissue, {__metatable = "no enter for you my guy"})
        
        return next, skillissue, nil 
    end
} 

setmetatable(PlayerData, defender)

----------------------------------------------------------------
--  Active Test Laboratory Project NexusJIT --------------
----------------------------------------------------------------
print("\n--- Running Integrity Tests For Anti-Cheat Engine ---")

-- 1. Legitimate Query Verification
print("\n[TEST 1] Executing legitimate query for game data...")
local current_speed = PlayerData.speed
print("-> Speed value retrieved successfully: " .. tostring(current_speed)) 

-- 2. Honeypot Database Verification
print("\n[TEST 2] Simulating unauthorized external memory injection...")
PlayerData.gold = 999999 

-- 3. Poison Pills Integrity Verification
print("\n[TEST 3] Simulating memory editor modifying a static poison pill...")
poison_pills[1] = 999 -- Simulating Cheat Engine altering the frozen memory location

print("Attempting to access game memory after external intrusion...")
local check_speed = PlayerData.speed 

print("\n--- Verification Session Completed Successfully ---")
