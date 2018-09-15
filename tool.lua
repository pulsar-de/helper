--[[

    tool.lua

        - a lua tool library with useful functions
        - based on: "luadch/core/util.lua" written by blastbeat and pulsar
        - license:  GNU General Public License, Version 3

    Last change: 2018-09-14



    [ Application programming interface (API) ]


    true, err = tool.SaveArray( array, path )

        - saves an array to a local file
        - returns: true, nil on success
        - returns: nil, err if array could not be saved
        - example: result, err = tool.SaveArray( array, path ); if result then ... else ... err

    true, err = tool.SaveTable( tbl, name, path )

        - saves a table to a local file
        - returns: true, nil on success
        - returns: nil, err on error
        - example: result, err = tool.SaveTable( tbl, name, path ); if result then ... else ... err

    table, err = tool.LoadTable( path )

        - loads a local table from file
        - returns: table, nil on success
        - returns: nil, err on error
        - example: tbl, err = tool.LoadTable( path ); if tbl then ... else ... err

    number/nil, number/err, number, number = tool.FormatSeconds( t )

        - converts time to: days, hours, minutes, seconds
        - returns: number, number, number, number (d,h,m,s) on success
        - returns: nil, err on error
        - example: d, h, m, s = tool.FormatSeconds( os.difftime( os.time( ), signal.get( "start" ) ) ) )

    string/nil = tool.FormatBytes( bytes )

        - convert bytes to the right unit, returns converted bytes as a sting e.g. "209.81 GB"
        - returns: string, nil on success
        - returns: nil, err on error
        - example: string, err = tool.FormatBytes( bytes ); if string then ... else ... err

    string = tool.GeneratePass( len )

        - returns a random generated alphanumerical password string with length = len
        - if no param is specified then len = 20 (max. 1000)
        - if len is invalid then len = 20
        - example: pass = tool.GeneratePass( 10 )

    string/nil, nil/err = tool.TrimString( string )

        - trim whitespaces only from both ends of a string
        - returns: string, nil on success
        - returns: nil, err on error
        - example: string, err = tool.TrimString( string ); if string then ... else ... err

    true/nil, nil/err = tool.TableIsEmpty( tbl )

        - check if a table is empty
        - returns: true, nil on success
        - returns nil, err if param is not a table or table is not empty
        - example: result, err = tool.TableIsEmpty( tbl ); if result then ... else ... err

    true/nil, nil/err = tool.TableIndexExists( tbl, index )

        - check if a table index exists
        - returns: true, nil if index exists
        - returns: nil, nil if index not exists
        - returns: nil, err if tbl is not a table
        - example: result, err = tool.TableIndexExists( tbl, index ); if result then ... else ... err

    true/nil, nil/err = tool.TableIndexChange( tbl, old_index, new_index )

        - check if a table index exists
        - returns: true, nil on success
        - returns: nil, err on error
        - example: result, err = tool.TableIndexChange( tbl, old_index, new_index ); if result then .. else .. err

    true/nil, err = tool.FileExists( str )

        - check if a file exists
        - returns: true if file exists
        - returns: nil, err on error
        - example: result, err = tool.FileExists( str ); if result then ... else err

    true/nil, msg/err = tool.MakeFile( file )

        - make an empty file (textfile) if not exists
        - returns: true, msg if new file was created
        - returns: nil, msg if file already exists
        - returns: nil, err if file could not created
        - example: result, err = tool.MakeFile( file ); if result then ... else err

    true/nil, msg/err = tool.ClearFile( file )

        - clears a file (textfile)
        - returns: true, msg if file was cleared
        - returns: nil, err if file could not be cleared or not found
        - example: result, err = tool.ClearFile( file ); if result then ... else err

    true/nil, msg/err = tool.FileWrite( txt, file[, timestamp] )

        - write text in a new line on the bottom of a file optional with timestamp
        - returns: true, msg if text was successfully written
        - returns: nil, err if text could not be written
        - timestamp is optional and has three posible values: "time" or "date" or "both"
        - example: result, err = tool.FileWrite( txt, file[, timestamp] ); if result then .. else err

]]


------------------------------
-- DEFINITION / DECLARATION --
------------------------------

--// functions
local SortSerialize
local SaveArray
local SaveTable
local LoadTable
local FormatSeconds
local FormatBytes
local GeneratePass
local TrimString
local TableIsEmpty
local TableIndexExists
local TableIndexChange
local FileExists
local MakeFile
local ClearFile
local FileWrite

--// table lookups
local os_time = os.time
local os_date = os.date
local io_open = io.open
local math_floor = math.floor
local math_random = math.random
local math_randomseed = math.randomseed
local string_format = string.format
local string_find = string.find
local string_match = string.match
local table_insert = table.insert
local table_sort = table.sort


----------
-- CODE --
----------

--// Helper function for data serialization by blastbeat
SortSerialize = function( tbl, name, file, tab, r )
    tab = tab or ""
    local temp = { }
    for key, k in pairs( tbl ) do
        --if type( key ) == "string" or "number" then
            table_insert( temp, key )
        --end
    end
    table_sort( temp )
    local str = tab .. name
    if r then
        file:write( str .. " {\n\n" )
    else
        file:write( str .. " = {\n\n" )
    end
    for k, key in ipairs( temp ) do
        if ( type( tbl[ key ] ) ~= "function" ) then
            local skey = ( type( key ) == "string" ) and string_format( "[ %q ]", key ) or string_format( "[ %d ]", key )
            if type( tbl[ key ] ) == "table" then
                SortSerialize( tbl[ key ], skey, file, tab .. "    " )
                file:write( ",\n" )
            else
                local svalue = ( type( tbl[ key ] ) == "string" ) and string_format( "%q", tbl[ key ] ) or tostring( tbl[ key ] )
                file:write( tab .. "    " .. skey .. " = " .. svalue )
                file:write( ",\n" )
            end
        end
    end
    file:write( "\n" )
    file:write( tab .. "}" )
end

--// saves an array to a local file - by blastbeat
SaveArray = function( array, path )
    array = array or { }
    local file, err = io_open( path, "w+" )
    if not file then
        return nil, "tool.lua: " .. err
    end
    local iterate, savetbl
    iterate = function( tbl )
        local tmp = { }
        for key, value in pairs( tbl ) do
            tmp[ #tmp + 1 ] = tostring( key )
        end
        table_sort( tmp )
        for i, key in ipairs( tmp ) do
            key = tonumber( key ) or key
            if type( tbl[ key ] ) == "table" then
                file:write( ( ( type( key ) ~= "number" ) and tostring( key ) .. " = " ) or " " )
                savetbl( tbl[ key ] )
            else
                file:write( ( ( type( key ) ~= "number" and tostring( key ) .. " = " ) or "" ) .. ( ( type( tbl[ key ] ) == "string" ) and string_format( "%q", tbl[ key ] ) or tostring( tbl[ key ] ) ) .. ", " )
            end
        end
    end
    savetbl = function( tbl )
        local tmp = { }
        for key, value in pairs( tbl ) do
            tmp[ #tmp + 1 ] = tostring( key )
        end
        table_sort( tmp )
        file:write( "{ " )
        iterate( tbl )
        file:write( "}, " )
    end
    file:write( "return {\n\n" )
    for i, tbl in ipairs( array ) do
        if type( tbl ) == "table" then
            file:write( "    { " )
            iterate( tbl )
            file:write( "},\n" )
        else
            file:write( "    " .. string_format( "%q", tostring( tbl ) ) .. ",\n" )
        end
    end
    file:write( "\n}" )
    file:close( )
    return true
end

--// saves a table to a local file - by blastbeat
SaveTable = function( tbl, name, path )
    local file, err = io_open( path, "w+" )
    if file then
        file:write( "local " .. name .. "\n\n" )
        SortSerialize( tbl, name, file, "" )
        file:write( "\n\nreturn " .. name )
        file:close( )
        return true
    else
        return nil, "tool.lua: " .. err
    end
end

--// loads a local table from file - by blastbeat
LoadTable = function( path )
    local file, err = io_open( path, "r" )
    if not file then
        return nil, "tool.lua: " .. err
    end
    local content = file:read "*a"
    file:close( )
    local chunk, err = loadstring( content )
    if chunk then
        local ret = chunk( )
        if ret and type( ret ) == "table" then
            return ret
        else
            return nil, "tool.lua: error in LoadTable(), invalid table"
        end
    end
    return nil, "tool.lua: " .. err
end

--// converts time to: days, hours, minutes, seconds - by motnahp
FormatSeconds = function( t )
    local t = tonumber( t )
    if type( t ) ~= "number" then
        return nil, "tool.lua: error in FormatSeconds(), number expected, got " .. type( t )
    end
    return
        math_floor( t / ( 60 * 60 * 24 ) ),
        math_floor( t / ( 60 * 60 ) ) % 24,
        math_floor( t / 60 ) % 60,
        t % 60
end

--// convert bytes to the right unit - based on a function by Night
FormatBytes = function( bytes )
    local bytes = tonumber( bytes )
    if ( not bytes ) or ( not type( bytes ) == "number" ) or ( bytes < 0 ) or ( bytes == 1 / 0 ) then
        return nil, "tool.lua: error in FormatBytes(), invalid parameter"
    end
    if bytes == 0 then return "0 B" end
    local i, units = 1, { "B", "KB", "MB", "GB", "TB", "PB", "EB", "YB" }
    while bytes >= 1024 do
        bytes = bytes / 1024
        i = i + 1
    end
    if units[ i ] == "B" then
        return string_format( "%.0f", bytes ) .. " " .. ( units[ i ] or "?" )
    else
        return string_format( "%.2f", bytes ) .. " " .. ( units[ i ] or "?" )
    end
end

--// returns a random generated alphanumerical password - by blastbeat
GeneratePass = function( len )
    local len = tonumber( len )
    if not ( type( len ) == "number" ) or ( len < 0 ) or ( len > 1000 ) then len = 20 end
    local lower = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
                    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }
    local upper = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
    math_randomseed( os_time() )
    local pwd = ""
    for i = 1, len do
        local X = math_random( 0, 9 )
        if X < 4 then
            pwd = pwd .. math_random( 0, 9 )
        elseif ( X >= 4 ) and ( X < 6 ) then
            pwd = pwd .. upper[ math_random( 1, 25 ) ]
        else
            pwd = pwd .. lower[ math_random( 1, 25 ) ]
        end
    end
    return pwd
end

--// trim whitespaces from both ends of a string - by pulsar
TrimString = function( str )
    local str = tostring( str )
    if type( str ) ~= "string" then
        return nil, "tool.lua: error in TrimString(), string expected, got " .. type( str )
    end
    return string_find( str, "^%s*$" ) and "" or string_match( str, "^%s*(.*%S)" )
end

--// check if a table is empty - by pulsar
TableIsEmpty = function( tbl )
    if type( tbl ) ~= "table" then
        return nil, "tool.lua: error in TableIsEmpty(), table expected, got " .. type( tbl )
    end
    if next( tbl ) == nil then
        return true
    end
    return nil, "tool.lua: table in not empty"
end

--// check if a table index exists - by pulsar
TableIndexExists = function( tbl, index )
    if type( tbl ) ~= "table" then
        return nil, "tool.lua: error in TableIndexExists(), table expected for #1, got " .. type( tbl )
    end
    if tbl[ index ] ~= nil then
        return true
    else
        return nil
    end
end

--// change index in a table, new index has to be a string or a number
TableIndexChange = function( tbl, old_index, new_index )
    if type( tbl ) ~= "table" then
        return nil, "tool.lua: error in TableIndexChange(), table expected for #1, got " .. type( tbl )
    end
    if ( type( old_index ) ~= "string" ) and ( type( old_index ) ~= "number" ) then
        return nil, "tool.lua: error in TableIndexChange(), string or number expected for #2, got " .. type( old_index )
    end
    if ( type( new_index ) ~= "string" ) and ( type( new_index ) ~= "number" ) then
        return nil, "tool.lua: error in TableIndexChange(), string or number expected for #3, got " .. type( new_index )
    end
    local exists, err = TableIndexExists( tbl, old_index )
    if exists then
        local old_value = tbl[ old_index ]
        tbl[ new_index ] = old_value
        tbl[ old_index ] = nil
        return true, "tool.lua: table index successfully changed"
    else
        return nil, "tool.lua: table index not found"
    end
end

--// check if a file exists - by pulsar
FileExists = function( file )
    if type( file ) ~= "string" then
        return nil, "tool.lua: error in FileExists(), string expected, got " .. type( file )
    end
    local f, err = io_open( file, "r" )
    if f then
        f:close()
        return true
    else
        return nil, "tool.lua: error in FileExists(), could not check file because: " .. err
    end
end

--// make an empty file (textfile) if not exists - by pulsar
MakeFile = function( file )
    if not FileExists( file ) then
        local f, err = io_open( file, "w" )
        if f then
            f:close()
            return true, "tool.lua: file successfully created"
        else
            return nil, "tool.lua: error in MakeFile(), could not create file, reason: " .. err
        end
    else
        return nil, "tool.lua: error in MakeFile(), file already exists"
    end
end

--// clears a file (textfile) - by pulsar
ClearFile = function( file )
    if type( file ) ~= "string" then
        return nil, "tool.lua: error in ClearFile(), string expected, got " .. type( file )
    end
    if FileExists( file ) then
        local f, err = io_open( file, "w" )
        if f then
            f:close()
            return true, "tool.lua: file successfully cleared"
        else
            return nil, "tool.lua: error in ClearFile(), file could not be cleared because: " .. err
        end
    else
        return nil, "tool.lua: error in ClearFile(), file not found"
    end
end

--// write text in a new line on the bottom of a file optional with timestamp
FileWrite = function( txt, file, timestamp )
    if type( txt ) ~= "string" then
        return nil, "tool.lua: errir in FileWrite(), string expected for #1, got " .. type( txt )
    end
    if type( file ) ~= "string" then
        return nil, "tool.lua: error in FileWrite(), string expected for #2, got " .. type( file )
    end
    if ( not timestamp ) or ( type( timestamp ) ~= "string" ) then timestamp = "" end
    if timestamp == "time" then timestamp = "[" .. os_date( "%H:%M:%S" ) .. "] " end
    if timestamp == "date" then timestamp = "[" .. os_date( "%Y-%m-%d" ) .. "] " end
    if timestamp == "both" then timestamp = "[" .. os_date( "%Y-%m-%d %H:%M:%S" ) .. "] " end
    local result, err = FileExists( file )
    if result then
        local f, err = io_open( file, "a+" )
        if f then
            f:write( timestamp .. txt .. "\n" )
            f:close()
            return true, "tool.lua: successfully write text to file"
        else
            return nil, "tool.lua: error in FileWrite(), could not write text to file because: " .. err
        end
    else
        return nil, "tool.lua: " .. err
    end
end

return {

    SaveTable = SaveTable,
    LoadTable = LoadTable,
    SaveArray = SaveArray,
    FormatSeconds = FormatSeconds,
    FormatBytes = FormatBytes,
    GeneratePass = GeneratePass,
    TrimString = TrimString,
    TableIsEmpty = TableIsEmpty,
    TableIndexExists = TableIndexExists,
    TableIndexChange = TableIndexChange,
    FileExists = FileExists,
    MakeFile = MakeFile,
    ClearFile = ClearFile,
    FileWrite = FileWrite,

}