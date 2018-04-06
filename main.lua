local emu = require "emu"
local assem = require "assem"

assem.assemble(io.open("test.asm", "r"), io.open("compiled.bin", "w"))
