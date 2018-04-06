local ops = require "ops"

local emu = {}

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
                io.write(string.char(v), "\n")
            end
            rawget(t, "mem")[k] = v
        else
            rawset(t, k, v)
        end
    end,
}

setmetatable(emu, emu.mt)

function emu.run (file)
    do
        local mem = {}
        local i = 0
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

    while emu.mem[0xffff] ~= 0 do
        emu:tick()
    end
end

function emu:tick ()
    local word = self:get_word()

    local code   = bit.band(0xf, bit.rshift(word, 4))
    local unused = bit.band(0xf, bit.rshift(word, 0))
    local amode1 = bit.band(0xf, bit.rshift(word, 12))
    local amode2 = bit.band(0xf, bit.rshift(word, 8))

    print(("%x %x %x %x"):format(code, unused, amode1, amode2))

    local op = ops.by_code[code]
    local arg1 = self:get_key(amode1)
    local arg2 = self:get_key(amode2)

    print(op.name, arg1, arg2)

    if not self.skip then
        op.exec(self, arg1, arg2)
    end
end

function emu:get_key (amode)
    -- immed       0    1    2    3    4     5
    -- addr        6    7    8    9    A     B
    local regs = {"a", "b", "c", "d", "pc", "sp"}
    if amode < 0x6 then
        -- register value
        return regs[amode + 1]
    elseif amode < 0xC then
        -- register pointer
        return self[regs[amode + 1 - 6]]
    elseif amode == 0xC then
        -- immediate value; gives pointer to ROM
        local ret = self.pc
        self:get_word() -- skip address
        return ret
    elseif amode == 0xD then
        -- immediate pointer
        return self:get_word()
    else
        error(("Invalid mode: %x"):format(amode))
    end
end

function emu:get_word()
    local word = self[self.pc]
    self.pc = (self.pc + 1) % 0x10000
    return word
end

return emu
