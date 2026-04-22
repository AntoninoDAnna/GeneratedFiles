mutable struct Tag
    tag::String
    #=
    Order records by position. if pos<0 they are put at the end of the list.
    =#
    pos::Int64 ##
    Tag(s, pos) = new(s,pos)
    Tag(s) = Tag(s,-1)
end

mutable struct  Record
    buffer::IOBuffer
    tag::Tag
    Record(b::IOBuffer,tag::Tag) = new(b,tag)
    Record(b::IOBuffer,tag::AbstractString, pos::Int64 = -1) = new(b,Tag(tag,pos))
    Record(b,tag::Tag) = new(IOBuffer(b),tag)
    Record(b,tag::AbstractString,pos::Int64=-1) = new(IOBuffer(b),Tag(tag,pos))
end

mutable struct GeneratedFile
    filename::String
    records::Vector{Record}
    GeneratedFile(io::String, r::Vector{Record} = Record[]) = new(io,r)
end

import Base: show

function show(io::IO,gf::GeneratedFile)
    nr = length(gf.records)
    print(io,"GeneratedFile: $(gf.filename) with $nr records")
end

show(io::IO,r::Record) = show(io,r.tag)

show(io::IO,t::Tag) = print(io,"Tag: ", t.tag," position: ", t.pos)

import Base: print

function Base.print(io::IO,r::Record)
    print(io,"Record: ",r.tag.tag,"\nText: ",String(take!(r.buffer)))
end
