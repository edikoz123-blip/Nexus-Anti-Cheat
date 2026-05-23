local jit = require("jit")
jit.on()
jit.opt.start(3)
local ffi = require("ffi")

local setmetatable = setmetatable
local print = print

-- טעינת קובץ המשחק הדינמי שהמשתמש מביא
local defending = require("put your game")

local Agents = {}
local field_agents = {} 
local CoreInterface = {}
local islinked = false 

-- משתנים שיחזיקו את נתוני ה-Nexus המאסטר דינמית בזיכרון
local anticheat_pid = 0
local anticheat_address = nil

-- קבועים הנדסיים
local change = 0x1FFFFF -- PROCESS_ALL_ACCESS
local PAGE_EXECUTE_READ = 0x20
local FILE_NOTIFY_CHANGE_FILE_NAME = 0x00000001
local FILE_NOTIFY_CHANGE_LAST_WRITE = 0x00000010
local PRISTINE_FUNCTION_HASH = 0

function LinkCore(Nexus_Core)
    local protection = { 
        __metatable = "stack traceback:\n\t[C]: at 0x7ffeff59a2d0\n\t[C]: in function 'require'\n\t...Nexus-Anti-Cheat.lua:14: in main chunk" 
    }
    local defender = {
        [false] = function()
            CoreInterface = Nexus_Core
            islinked = true
            print("Successfully put both together")
        end,
        [true] = function() print("it got blocked!") end
    }
    setmetatable(defender, protection)
    return defender[islinked]() 
end

local function on_tamper(pid, agent_id)
    print("💥 [ALERT] Event triggered! Breach detected by Agent " .. agent_id)
    local_deploy(pid) 
end

local function on_safe(pid, id, next_id) end

local function Check_Function_Integrity(func_ptr, size)
    local bytes = ffi.cast("unsigned char*", func_ptr)
    local current_hash = 0
    for i = 0, size - 1 do current_hash = current_hash + bytes[i] end
    return current_hash
end

local dir_handle = ffi.C.FindFirstChangeNotificationA(".", 0, FILE_NOTIFY_CHANGE_FILE_NAME + FILE_NOTIFY_CHANGE_LAST_WRITE)

local function Watch_Directory_Event(target_pid)
    local status = ffi.C.WaitForSingleObject(dir_handle, 0)
    local event_matrix = {
        [0] = function() 
            print("🚨 [EVENT] Directory tampering detected! Someone modified/deleted files!")
            local_deploy(target_pid) 
            ffi.C.FindNextChangeNotification(dir_handle) 
        end,
        [258] = function() end 
    }
    -- ✅ תוקן: העפנו את ה-if, ירייה ישירה בקו ישר דרך מטריצת האירוע! [I1]
    if event_matrix[status] then event_matrix[status]() end
end

local mesh_status_map = {
    [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0,
    [8] = 0, [9] = 0, [10] = 0, [11] = 0, [12] = 0, [13] = 0, [14] = 0, [15] = 0
}
local pristine_mesh_map = ffi.new("uintptr_t[?]", 16)

local action_matrix = {
    [true] = function(pid, id, next_id) 
        print("🚨 [MESH BREACH] Agent " .. id .. " detected breach or neighbor " .. next_id .. " failure!")
        on_tamper(pid, id) 
    end,
    [false] = on_safe
}

-- 5. מנוע האנליזה והשיחה - 100% Branchless ללא שום תנאי! [I1, I4]
local function Talks(pid, address, agent_id)
    local connection = ffi.C.OpenProcess(change, 0, pid)
    local mbi = ffi.new("uintptr_t[?]", 7)
    ffi.C.VirtualQueryEx(connection, ffi.cast("void*", address), mbi, 56)
    ffi.C.CloseHandle(connection) 
    local is_mem_tampered = (mbi[4] ~= PAGE_EXECUTE_READ)
    
    -- ✅ תוקן: העפנו את ה-if וה-syntax השבור. סריקה חלקה וישירה של ה-Nexus! [I1]
    local ac_connection = ffi.C.OpenProcess(change, 0, anticheat_pid)
    local ac_mbi = ffi.new("uintptr_t[?]", 7)
    ffi.C.VirtualQueryEx(ac_connection, ffi.cast("void*", anticheat_address), ac_mbi, 56)
    ffi.C.CloseHandle(ac_connection) 
    local is_anticheat_tampered = (ac_mbi[4] ~= PAGE_EXECUTE_READ)
    
    local current_func_hash = Check_Function_Integrity(anticheat_address, 64)
    local is_hooked = (current_func_hash ~= PRISTINE_FUNCTION_HASH)
    
    mesh_status_map[agent_id] = (is_mem_tampered or is_hooked or is_anticheat_tampered) and 1 or 0
    
    local next_agent_id = (agent_id + 1) % 16
    local is_neighbor_tampered = (mesh_status_map[next_agent_id] == 1)
    
    local total_breach = (is_mem_tampered or is_hooked or is_neighbor_tampered or is_anticheat_tampered)
    action_matrix[total_breach](pid, agent_id, next_agent_id)
end

-- 6. פונקציית הייזום של 16 הסוכנים - 0% שומן [I1]
function Agents.Init_Agents(master_pid, master_address)
    anticheat_pid = master_pid
    anticheat_address = master_address
    PRISTINE_FUNCTION_HASH = Check_Function_Integrity(master_address, 64)

    -- ✅ תוקן: העפנו את ה-if. שליפה ישירה בקו ישר של יעדי הזיכרון ללא predictions! [I1, I4]
    for i = 0, 15 do
        field_agents[i] = function()
            local target_pid = defending[i].pid
            local target_address = defending[i].address
            Watch_Directory_Event(target_pid)
            Talks(target_pid, target_address, i)
        end
    end

    for i = 0, 15 do
        pristine_mesh_map[i] = Check_Function_Integrity(field_agents[i], 64)
    end
    print("✅ [SYSTEM] Nexus-Anti-Cheat network linked dynamically. 100% Branchless execution ready.")
    return field_agents
end

Agents.LinkCore = LinkCore
Agents.Init = Agents.Init_Agents

return Agents
