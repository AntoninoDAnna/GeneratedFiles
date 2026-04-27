const COMMENTCHAR = "%"
const START_RECORD = string(COMMENTCHAR,"-start-",COMMENTCHAR)
const END_RECORD = string(COMMENTCHAR,"-end-",COMMENTCHAR)
const TAG_REGEX = Regex("(?<=$(START_RECORD) |$(END_RECORD) )([^\\s]+)")
const POS_REGEX = Regex("(?<=$(START_RECORD) |$(END_RECORD) )([^\\s]+)(\\s*)(\\d+)")

function seekRecord(io::IOStream)
    while true
        eof(io) && return false
        startswith(io,START_RECORD) && return true
        readline(io)
    end
end

function findEndRecord(io::IOStream)
    p1 = position(io)
    p2 = -1
    while true
        if eof(io)
            p2 = position(io)
            break;
        end
        if startswith(io,END_RECORD)
            readline(io)
            p2 = position(io)
            break;
        end
        readline(io)
    end
    return p2
end

function readGF(filename)
    isfile(filename) || return GeneratedFile(filename)
    records = Vector{Record}()
    open(filename,"r") do io
        while seekRecord(io)
            push!(records,read_record(io))
        end
    end
    return GeneratedFile(filename,records)
end

function get_tag_and_pos(s::AbstractString)
    ms = match(POS_REGEX,s)
    isnothing(ms) && error("missing tag in Record")
    pos = parse(Int64,match(r"[\d]+",ms.match).match)
    tag = match(r"[^\s]+",ms.match).match
    return tag,pos
end

function read_record(b::IO)
    tag,pos = get_tag_and_pos(readline(b))
    is = position(b)
    length = 0
    for l in eachline(b)
        if !startswith(l,END_RECORD)
            length = position(b)-is
            continue
        end
        me = match(TAG_REGEX,l)
        isnothing(me) && error("missing tag at the end of a Record")
        if tag != me.match
            error("Record is malformed:\nIt start with $(tag)\nIt ends with $(me.match)")
        end
        break;
    end
    seek(b,is)
    return  Record(IOBuffer(read(b,length)),tag,pos)
end

import Base.isequal
Base.isequal(a::Tag,b::Tag) = isequal(a.tag,b.tag)



function add_records!(GF::GeneratedFile,r::Record...)
    idx = fill(true, length(r))
    for (i,_r) in enumerate(r)
        _idx = findfirst(x->isequal(x.tag, _r.tag), GF.records)
        !isnothing(_idx) || continue
        GF.records[_idx] = _r
        idx[i] = false
    end
    push!(GF.records,r[idx]...)
end

remove_records!(GF::GeneratedFile,tag::String) =  filter!(r->r.tag.tag != tag, GF.records)

remove_records!(GF::GeneratedFile,tag::Tag) = remove_record(GF,tag.tag)

import Base.write
function Base.write(r::Record,x...)
    r.buffer.writable || error("Cannot modify record $(r.tag.tag)")
    Base.write(r.buffer, x...)
end

function GF_write(io,r::Record)
    println(io,START_RECORD," ",r.tag.tag," ",r.tag.pos)
    sw = StringView(r.buffer.data[1:r.buffer.size])
    print(io,sw)
    sw[end]== '\n' || println(io)
    println(io,END_RECORD," ",r.tag.tag)
    nothing
end

function isless_Tag(a::Tag,b::Tag)
    a.pos == b.pos && return a.tag < b.tag
    return a.pos<b.pos
end
isless_Record(a::Record,b::Record) = isless_Tag(a.tag, b.tag)



function resolve_negative_pos!(R::Vector{Record})
    any(r.tag.pos<=0 for r in R)  || return
    maxP = max(1, maximum(R[i].tag.pos for i in eachindex(R))+1)

    for (i,r) in enumerate(R)
        r.tag.pos<=0 || continue;
        R[i].tag.pos = maxP
        maxP+=1
    end
    return
end

order_records!(R::Vector{Record}) = sort!(R,lt=isless_Record)

function GF_write(GF::GeneratedFile)
    resolve_negative_pos!(GF.records)
    order_records!(GF.records);
    open(GF.filename,"w") do io
        GF_write.(io,GF.records)
    end
    nothing
end
