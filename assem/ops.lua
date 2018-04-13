local ops = {}

local rmw = {"dest", "src"}

ops.by_code = {
    [0x00] = {name = "mov",  args = rmw},
    [0x02] = {name = "add",  args = rmw},
    [0x03] = {name = "sub",  args = rmw},
    [0x04] = {name = "mul",  args = rmw},
    [0x05] = {name = "fmul", args = rmw},
    [0x06] = {name = "div",  args = rmw},
    [0x07] = {name = "fdiv", args = rmw},
    [0x08] = {name = "rem",  args = rmw},
    [0x09] = {name = "mod",  args = rmw},
    [0x0A] = {name = "shr",  args = rmw},
    [0x0B] = {name = "shl",  args = rmw},
    [0x0E] = {name = "or",   args = rmw},
    [0x10] = {name = "and",  args = rmw},
    [0x12] = {name = "xor",  args = rmw},
    [0x14] = {name = "eq",   args = {"src", "src"}},
    [0x15] = {name = "neq",  args = {"src", "src"}},
    [0x16] = {name = "gt",   args = {"src", "src"}},
    [0x17] = {name = "le",   args = {"src", "src"}},
    [0x18] = {name = "sgt",  args = {"src", "src"}},
    [0x19] = {name = "sle",  args = {"src", "src"}},
    [0x1A] = {name = "push", args = {"src"}},
    [0x1C] = {name = "pop",  args = {"dest"}},
    [0x1E] = {name = "call", args = {"src"}},
}

ops.by_name = {}
for i = 0,31 do
    local v = ops.by_code[i]
    if v then
        v.code = i
        ops.by_name[v.name] = v
    end
end

return ops
