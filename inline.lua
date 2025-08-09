local ffi = require("ffi")

-- Подготовка имен файлов и используемых команд
local c_path = "./temp.c"
local proto_path = "./temp.txt"

local lib_path
local extract_protos_cmd

if ffi.os == "Windows" then
    lib_path = "./temp.dll"
    extract_protos_cmd =
        "gcc -aux-info "..proto_path.." "..c_path.." 2>NUL"
else
    lib_path = "./temp.so"
    extract_protos_cmd =
        "gcc -aux-info "..proto_path.." "..c_path.." 2>/dev/null"
end

local shared_lib_compile_cmd =
    "gcc -shared -fPIC -o "..lib_path.." "..c_path
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

local function extract_protos(path)
    assert_strings(path)
    local protos = {}
    local file = assert(io.open(path, "r"))
    for l in file:lines() do
        if not l:find("%.h") then
            protos[#protos+1] = l:gsub("/%*.-%*/", "")
        end
    end
    assert(file:close())
    return table.concat(protos, "")
end

local function inline(c_code)
    assert_strings(c_code)

    local success, result = pcall(function ()
        -- Запись кода в файл
        write_file(c_path, c_code)

        -- Получение всех прототипов функций из кода
        assert(os.execute(extract_protos_cmd))
        local protos = extract_protos(proto_path)

        assert(os.execute(shared_lib_compile_cmd))

        ffi.cdef(protos)
        local lib = ffi.load(lib_path)

        local func_pattern = "([%a_][%w_]+)%s*%("
        for name in protos:gmatch(func_pattern) do
            _G[name] = lib[name]
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