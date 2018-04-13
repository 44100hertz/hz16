local assem = require "assem"

local infile = arg[1] or "test.asm"
local bin = arg[2] or infile:gsub("[.]%w*$", ".bin")
assem.assemble_and_write(infile, bin)
