local ops = require "ops"

local assem = {}

assem.assemble_and_write = function (inpath, outpath)
    local infile = io.input(inpath)
    local program = assem.assemble(infile)
    local bin = assem.link(program, 0)
    assem.write_bin(bin, outpath)
    infile:close()
end

assem.assemble = function (infile)
    local program = assem.tokenize(infile)
    assem.parse(program)
    return program
end

assem.write_bin = function (bin, outpath)
    local outfile = io.open(outpath, "wb")
    for _,word in ipairs(bin) do
        outfile:write(string.char(
                          bit.band(0xff, word),
                          bit.band(0xff, bit.rshift(word, 8))))
    end
    outfile:close()
end

assem.tokenize = function (infile)
    local lines = {}
    for line in infile:lines() do
        lines[#lines+1] = assem.tokenize_line(line)
    end
    return lines
end

assem.tokenize_line = function (line)
    line = line:gsub(";.*", "") -- strip comments
    if line:match("^%s*$") then
        return nil
    end
    local tokens = {}
    tokens.raw_line = line
    -- possible tokens
    local sig_def = {
        "%b''",    -- quote
        '%b""',    -- quote
        "%S",      -- single symbol
        "[%w_]+",  -- word or number
    }
    local pos = 0
    local token_pos, token_end
    repeat
        -- locate the earliest valid token, otherwise longest
        token_pos, token_end = nil, nil
        for _, sig in ipairs(sig_def) do
            local try_pos, try_end = line:find(sig, pos+1)
            -- skip past escaped quotes
            -- and the dreaded triple backslash (best solution for now)
            while try_pos and (line:find("^[^\\]\\['\"]", try_end-2) or
                               line:find("^\\\\\\['\"]", try_end-3))
            do
                local new_end = line:find(line:sub(try_end, try_end), try_end+1)
                if new_end then
                    try_end = new_end
                else
                    error("incomplete string")
                end
            end
            if try_pos and ((not token_pos) or
                    try_pos < token_pos or
                    (try_pos == token_pos and try_end > token_end))
            then
                token_pos, token_end = try_pos, try_end
            end
        end
        if token_pos then
            pos = token_end
            tokens[#tokens+1] = line:sub(token_pos, token_end)
        end
    until not token_pos
--    print(table.concat(tokens, ' | '))
    return tokens
end

assem.parse = function (lines, defined)
    defined = defined or {}
    for _, line in ipairs(lines) do
        assem.parse_line(line, defined)
--        if line.words then for _, w in ipairs(line.words) do if type(w) == "number" then io.write(("%04x "):format(w)) else io.write(w, " ") end end print() end
    end
end
assem.parse_line = function (line, defined)
    local pos = 1
    -- defining a symbol
    if line[pos+1] == '=' then
        defined[line[pos]] = assem.parse_expr(line, pos+2, defined)
        return
    end
    -- if not directive or op, must be label
    if line[pos] ~= '.' and not ops.by_name[line[pos]:lower()] then
        line.label = line[pos]
        pos = pos + 1
        if line[pos] == ':' then pos = pos + 1 end -- skip label colon
    end
    -- directive
    if line[pos] == "." then
        if line[pos+1] == "data" then
            pos = pos + 2
            line.words = {}
            local found
            repeat
                found, pos = assem.parse_expr_into(line, pos, defined, line.words)
                pos = pos + 1 -- skip comma
            until not found
        end
        return
    end
    -- operator
    local opname = line[pos]
    if not opname then
        return
    end
    pos = pos + 1
    local op = ops.by_name[opname]
    assert(op, "unknown op")
    -- parse up to two arguments
    local mode0, arg0, mode1, arg1
    mode0, arg0, pos = assem.parse_arg(line, pos, defined)
    mode1, arg1, pos = assem.parse_arg(line, pos, defined)

    local op_and_args =
        bit.lshift(op.code, 12) +
        bit.lshift(mode0 or 0, 4) +
        bit.lshift(mode1 or 0, 0)

    line.words = {op_and_args}
    line.words[#line.words+1] = arg0
    line.words[#line.words+1] = arg1
end

assem.parse_arg = function (line, pos, defined)
    local mode_id
    if not line[pos] then
        return 0x0, nil, pos
    end
    if line[pos] == "#" or line[pos] == "*" then
        mode_id = line[pos]
        pos = pos + 1
    end
    local reg = {
        a = 0,
        b = 1,
        c = 2,
        d = 3,
        pc = 4,
        sp = 5,
    }
    local reg_code = reg[line[pos]]
    if reg_code then
        -- #reg or just reg both are value
        local mode = mode_id == "*" and reg_code+6 or reg_code
        return mode, nil, pos+2
    end
    local parsed
    parsed, pos = assem.parse_expr(line, pos, defined)
    if mode_id == "#" or (mode_id ~= "*" and type(parsed) == "string") then
        return 0xC, parsed, pos+1
    else
        return 0xD, parsed, pos+1
    end
end

assem.parse_expr = function (line, pos, defined)
    if not line[pos] then
        return nil, pos
    elseif line[pos] == "$" then
        local num = tonumber(line[pos+1], 16)
        assert(num, "Could not parse hex.")
        return num, pos+2
    elseif line[pos]:find("^%d") then
        local num = tonumber(line[pos])
        assert(num, "Could not parse decimal.")
        return num, pos+1
    elseif line[pos]:find("^['\"]") then
        local esc = line[pos]:gsub('\\(.)', '%1')
        return {esc:sub(2, -2):byte(1, esc:len())}, pos+1
    else
        return defined[line[pos]] or line[pos], pos+1
    end
end

assem.parse_expr_into = function (line, pos, defined, list)
    local res
    res, pos = assem.parse_expr(line, pos, defined)
    if type(res) == "table" then
        for _,v in ipairs(res) do
            list[#list+1] = v
        end
        return true, pos
    elseif res then
        list[#list+1] = res
        return true, pos
    else
        return false, pos
    end
end

assem.link = function (program, pc)
    -- find program labels
    local labels = {}
    for _,line in ipairs(program) do
        if line.label then
            labels[line.label] = pc
        end
        pc = pc + (line.words and #line.words or 0)
    end

    -- apply program labels and make bin
    pc = 1
    local bin = {}
    for _,line in ipairs(program) do
        if not line.words then
            goto continue
        end
        io.write(line.raw_line, (" "):rep(40 - line.raw_line:len()))
        for _,word in ipairs(line.words) do
            if type(word) == "string" then
                assert(labels[word], "undefined label")
                bin[pc] = labels[word]
            else
                bin[pc] = word
            end
            io.write(("%04x "):format(bin[pc]))
            pc = pc + 1
        end
        print()
        ::continue::
    end
    return bin
end

return assem
