local ops = {}

local rmw = {"dest", "src"}

ops.by_code = {
    [0x0] = {
        name = "mov",
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = emu[b]
        end
    },
    [0x1] = {
        name = "add",
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = bit.band(emu[a] + emu[b], 0xffff)
        end
    },
    [0x2] = {
        name = "sub",
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = bit.band(emu[a] - emu[b], 0xffff)
        end
    },
    [0x3] = {
        name = "lsub",
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = bit.band(emu[b] - emu[a], 0xffff)
        end
    },
    [0x4] = {
        name = "mul",
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = bit.band(emu[a] * emu[b], 0xffff)
        end
    },
    [0x5] = {
        name = "fmul", -- fractional multiply, used to get lower word
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = bit.band(emu[a] * emu[b] / 0x10000, 0xffff)
        end
    },
    [0x6] = {
        name = "div",
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = bit.band(emu[a] / emu[b], 0xffff)
        end
    },
    [0x7] = {
        name = "ldiv",
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = bit.band(emu[b] / emu[a], 0xffff)
        end
    },
    [0x8] = {
        name = "mod",
        args = rmw,
        exec = function (emu, a, b)
            emu[a] = bit.band(emu[a] % emu[b], 0xffff)
        end
    },
    [0x9] = {
        name = "equ",
        args = rmw,
        exec = function (emu, a, b)
            emu.truth = emu[a] == emu[b]
        end
    },
    [0xA] = {
        name = "gtt",
        args = {"src", "src"},
        exec = function (emu, a, b)
            emu.truth = emu[a] > emu[b]
        end
    },
    [0xB] = {
        name = "gte",
        args = {"src", "src"},
        exec = function (emu, a, b)
            emu.truth = emu[a] >= emu[b]
        end
    },
    [0xC] = {
        name = "iff",
        args = {},
        exec = function (emu, a, b)
            emu.skip = emu.truth
        end
    },
    [0xD] = {
        name = "ift",
        args = {},
        exec = function (emu, a, b)
            emu.skip = not emu.truth
        end
    },
    [0xE] = {
        name = "push",
        args = {"src"},
        exec = function (emu, a)
            emu[emu.sp] = emu[a]
            emu.sp = emu.sp + 1
            if emu.sp > 0xffff then
                print "Warn: stack pointer wrapped to 0"
                emu.sp = 0
            end
        end
    },
    [0xF] = {
        name = "pop",
        args = {"dest"},
        exec = function (emu, a)
            emu.sp = emu.sp - 1
            emu[a] = emu[emu.sp]
            if emu.sp < 0x0 then
                print "Warn: stack pointer wrapped to 0xffff"
                emu.sp = 0xffff
            end
        end
    },
}

ops.by_name = {}
for i = 0,15 do
    local v = ops.by_code[i]
    v.code = i
    ops.by_name[v.name] = v
end

return ops
