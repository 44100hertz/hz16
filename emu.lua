local ops = require "ops"

local emu = {}

function emu.run (path)
    do
        local mem = {}
        local i = 0
        local file = io.open(path, "rb")
        for c in file:read("*all"):gmatch(".") do
            local index = math.floor(i/2)
            local rem = i % 2
            if rem == 0 then
                mem[index] = string.byte(c)
            else
                mem[index] = bit.bor(mem[index], bit.lshift(string.byte(c), 8))
            end
            i = i + 1
        end
        emu.mem = mem
    end

    emu.a = 0
    emu.b = 0
    emu.c = 0
    emu.d = 0
    emu.pc = 0
    emu.sp = 0
    emu.truth = false
    emu.skip = false

    while emu[0xffff] == 0 do
        emu:tick()
    end
end

function emu:tick ()
    local word = self:get_word()

    local code   = bit.band(0xf, bit.rshift(word, 12))
    local unused = bit.band(0xf, bit.rshift(word, 8))
    local amode1 = bit.band(0xf, bit.rshift(word, 4))
    local amode2 = bit.band(0xf, bit.rshift(word, 0))

    local op = ops.by_code[code]
    local arg1 = self:get_key(amode1)
    local arg2 = self:get_key(amode2)

    -- hack to detect assign immediate
    if (op.args[1] == "dest" and amode1 == 0x7) or
        (op.args[2] == "dest" and amode2 == 0x7)
    then
        error("attempt to assign to immediate")
    end

    if self.skip then
        -- "use" a skip
        self.skip = false
    else
--        print(("a:%04x b:%04x c:%04x d:%04x pc:%04x sp:%04x word:%04x"):format(emu.a, emu.b, emu.c, emu.d, emu.pc, emu.sp, word))
        op.exec(self, arg1, arg2)
    end
end

function emu:get_key (amode)
    local regs = {[0] = "a", "b", "c", "d", "pc", "sp"}
    local lobits = bit.band(amode, 0x7)
    local val = regs[lobits]
    if not val then
        val = self.pc
        self:get_word()
    end
    local is_ptr = bit.band(amode, 0x8) == 0x8
    return is_ptr and self[val] or val
end

function emu:get_word()
    local word = self[self.pc]
    self.pc = (self.pc + 1) % 0x10000
    return word
end

emu.mt = {
    __index = function (t, k)
        if type(k) == "number" then
            return rawget(t, "mem")[k] or 0
        else
            return rawget(t, k)
        end
    end,
    __newindex = function (t, k, v)
        if type(k) == "number" then
            if k == 0xFF00 then
                io.write(string.char(v))
            end
            rawget(t, "mem")[k] = v
        else
            rawset(t, k, v)
        end
    end,
}

setmetatable(emu, emu.mt)

return emu
