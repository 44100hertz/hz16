local lex = {}

lex.tokenize = function (infile)
    local lines = {}
    for line in infile:lines() do
        lines[#lines+1] = lex.tokenize_line(line)
    end
    return lines
end

lex.tokenize_line = function (line)
    line = line:gsub(";.*", "") -- strip comments
    if line:match("^%s*$") then
        return nil
    end
    local tokens = {}
    tokens.raw_line = line
    -- possible tokens
    local sig_def = {
        "%b''",  -- quote
        '%b""',  -- quote
        "%S",    -- single symbol
        "[%a_][%w_]*",     -- token
        "-?[%dA-Fa-f_]+",  -- number
    }
    local pos = 0
    repeat
        -- locate the earliest valid token, otherwise longest
        local token_pos, token_end = nil, nil
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

return lex
