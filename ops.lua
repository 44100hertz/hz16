local ops = {}

ops.by_code = {
  [0x0] = {
    name = "mov",
    args = 2,
    exec = function (emu, a, b)
      emu[a] = emu[b]
    end
  },
  [0x1] = {
    name = "add",
    args = 2,
    exec = function (emu, a, b)
      emu[a] = bit.band(emu[a] + emu[b], 0xffff)
    end
  },
  [0x2] = {
    name = "sub",
    args = 2,
    exec = function (emu, a, b)
      emu[a] = bit.band(emu[a] - emu[b], 0xffff)
    end
  },
  [0x3] = {
    name = "lsub",
    args = 2,
    exec = function (emu, a, b)
      emu[a] = bit.band(emu[b] - emu[a], 0xffff)
    end
  },
  [0x4] = {
    name = "mul",
    args = 2,
    exec = function (emu, a, b)
      emu[a] = bit.band(emu[a] * emu[b], 0xffff)
    end
  },
  [0x5] = {
    name = "fmul", -- fractional multiply, used to get lower word
    args = 2,
    exec = function (emu, a, b)
      emu[a] = bit.band(emu[a] * emu[b] / 0x10000, 0xffff)
    end
  },
  [0x6] = {
    name = "div",
    args = 2,
    exec = function (emu, a, b)
      emu[a] = bit.band(emu[a] / emu[b], 0xffff)
    end
  },
  [0x7] = {
    name = "ldiv",
    args = 2,
    exec = function (emu, a, b)
      emu[a] = bit.band(emu[b] / emu[a], 0xffff)
    end
  },
  [0x8] = {
    name = "mod",
    args = 2,
    exec = function (emu, a, b)
      emu[a] = bit.band(emu[a] % emu[b], 0xffff)
    end
  },
  [0x9] = {
    name = "equ",
    args = 2,
    exec = function (emu, a, b)
      emu.truth = emu[a] == emu[b]
    end
  },
  [0xA] = {
    name = "gtt",
    args = 2,
    exec = function (emu, a, b)
      emu.truth = emu[a] > emu[b]
    end
  },
  [0xB] = {
    name = "gte",
    args = 2,
    exec = function (emu, a, b)
      emu.truth = emu[a] >= emu[b]
    end
  },
  [0xC] = {
    name = "iff",
    args = 0,
    exec = function (emu, a, b)
      emu.skip = emu.truth
    end
  },
  [0xD] = {
    name = "ift",
    args = 0,
    exec = function (emu, a, b)
      emu.skip = not emu.truth
    end
  },
  [0xE] = {
    name = "push",
    args = 1,
    exec = function (emu, a)
      emu.mem[emu.sp] = emu[a]
      emu.sp = emu.sp + 1
      if emu.sp > 0xffff then
        print "Warn: stack pointer wrapped to 0"
        emu.sp = 0
      end
    end
  },
  [0xF] = {
    name = "pop",
    args = 0,
    exec = function (t, a)
      emu[a] = emu.mem[t.sp]
      emu.sp = emu.sp - 1
      if emu.sp < 0x0 then
        print "Warn: stack pointer wrapped to 0xffff"
        emu.sp = 0xffff
      end
    end
  },
}

ops.by_name = {}
for k, v in ipairs(ops.by_code) do
  ops.by_name[v.name] = v
end

return ops
