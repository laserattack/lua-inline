-- Проверка зависимостей
local ok, ffi = pcall(require, "ffi")
if not ok then
    error("This module requires LuaJIT with FFI support")
end

local function check_gcc()
    local check_cmd =
        ffi.os == "Windows"
        and "gcc --version >NUL 2>&1"
        or "gcc --version >/dev/null 2>&1"
    return os.execute(check_cmd) == 0
end

if not check_gcc() then
    error("GCC compiler is required but not found in the system")
end
--

local function assert_strings(...)
    for _, v in ipairs({...}) do
       assert(type(v) == "string")
    end
end

local function write_file(path, content)
    assert_strings(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    assert(file:close())
end

local function filter_protos(path)
    assert_strings(path)
    local protos = {}
    local file = assert(
        io.open(path, "r"),
        "check C code (compile error)")
    for l in file:lines() do
        if not l:find("%.h") then
            protos[#protos+1] = l:gsub("/%*.-%*/", "")
        end
    end
    assert(file:close())
    return table.concat(protos, "")
end

local counter = 0
local function inline(c_code)
    assert_strings(c_code)

    counter = counter + 1
    local prefix = "./"..counter.."_"

    --
    local c_path = prefix.."code.c"
    local proto_path = prefix.."protos.txt"

    local lib_path
    local extract_protos_cmd

    if ffi.os == "Windows" then
        lib_path = prefix.."shared.dll"
        extract_protos_cmd =
            "gcc -aux-info "..proto_path.." "..c_path.." 2>NUL"
    else
        lib_path = prefix.."shared.so"
        extract_protos_cmd =
            "gcc -aux-info "..proto_path.." "..c_path.." 2>/dev/null"
    end

    local shared_lib_compile_cmd =
        "gcc -shared -fPIC -o "..lib_path.." "..c_path
    --

    local success, result = pcall(function ()
        -- Запись кода в файл
        write_file(c_path, c_code)

        -- Получение всех прототипов функций из кода)
        os.execute(extract_protos_cmd)
        local protos = filter_protos(proto_path)

        os.execute(shared_lib_compile_cmd)

        ffi.cdef(protos)
        local lib = ffi.load(lib_path)

        local func_pattern = "([%a_][%w_]+)%s*%("
        for name in protos:gmatch(func_pattern) do
            if not pcall(function ()
                _G[name] = lib[name]
            end) then
                error(
                    "function '"
                    ..name
                    .."' is not in the library. "..
                    "mb it's static/inline/deadcode?")
            end
        end
    end)

    os.remove(proto_path)
    os.remove(c_path)
    os.remove(lib_path)

    if not success then
        error(result)
    end
end

return inline