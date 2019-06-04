###############################################################################
# From Schema.fbs
###############################################################################

@enum ArrowUnionMode::Int16    ArrowSparse ArrowDense
@enum ArrowPrecision::Int16    ArrowHalf ArrowSingle ArrowDouble
@enum ArrowDateUnit::Int16     ArrowDate32 ArrowDate64
@enum ArrowTimeUnit::Int16     ArrowSecond ArrowMillisecond ArrowMicrosecond ArrowNanosecond
@enum ArrowIntervalUnit::Int16 ArrowYearMonth ArrowDayTime
@enum ArrowEndianness::Int16   ArrowLittle ArrowBig

abstract type ArrowDataType end

mutable struct ArrowNull   <: ArrowDataType end
mutable struct ArrowBool <: ArrowDataType end
mutable struct ArrowStruct <: ArrowDataType end
mutable struct ArrowList   <: ArrowDataType end
mutable struct ArrowString <: ArrowDataType end
mutable struct ArrowBinary <: ArrowDataType end

const arrownull   = ArrowNull()
const arrowbool   = ArrowBool()
const arrowstring = ArrowString()
const arrowbinary = ArrowBinary()
const arrowlist = ArrowList()
const arrowstruct = ArrowStruct()

mutable struct ArrowFixedSizeList <: ArrowDataType
    listSize::Int32
end

mutable struct ArrowMap <: ArrowDataType
    keysSorted::Bool
end

mutable struct ArrowUnion <: ArrowDataType
    mode::ArrowUnionMode
    typeIds::Vector{Int32}
end

mutable struct ArrowInt <: ArrowDataType
    bitWidth::Int32
    is_signed::Bool
end

mutable struct ArrowFloatingPoint <: ArrowDataType
    precision::ArrowPrecision
end

mutable struct ArrowFixedSizeBinary <: ArrowDataType
    byteWidth::Int32
end

mutable struct ArrowDecimal <: ArrowDataType
    precision::Int32
    scale::Int32
end

mutable struct ArrowDate <: ArrowDataType
    unit::ArrowDateUnit
end

FlatBuffers.@DEFAULT ArrowDate unit = ArrowDate32

mutable struct ArrowTime <: ArrowDataType
    unit::ArrowTimeUnit
    bitWidth::Int32
end

FlatBuffers.@DEFAULT ArrowTime unit = ArrowMillisecond bitWidth = 32

mutable struct ArrowTimestamp
    unit::ArrowTimeUnit
    timezone::String
end

mutable struct ArrowInterval
    unit::ArrowIntervalUnit
end

FlatBuffers.@UNION ArrowType (
                              Nothing,
                              ArrowNull,
                              ArrowInt,
                              ArrowFloatingPoint,
                              ArrowBinary,
                              ArrowString,
                              ArrowBool,
                              ArrowDecimal,
                              ArrowDate,
                              ArrowTime,
                              ArrowTimestamp,
                              ArrowInterval,
                              ArrowList,
                              ArrowStruct,
                              ArrowUnion,
                              ArrowFixedSizeBinary,
                              ArrowFixedSizeList,
                              ArrowMap
                             )

mutable struct ArrowKeyValue
    key::String
    value::String
end

mutable struct ArrowDictionaryEncoding
    id::Int64
    indexType::ArrowInt
    isOrdered::Bool
end

ArrowDictionaryEncoding() = ArrowDictionaryEncoding(0, ArowInt(32, true), false)

mutable struct ArrowField
    name::String
    nullable::Bool
    typ::ArrowType
    dictionary::ArrowDictionaryEncoding
    children::Vector{ArrowField}
    custom_meadata::Vector{ArrowKeyValue}
end

function ArrowField(name::AbstractString, typ::ArrowType)
    ArrowField(name, true, typ, ArrowDictionaryEncoding(), ArrowField[], ArrowKeyValue[])
end

ArrowField(name::AbstractString, ::Type{T}) where {T} = ArrowField(name, jltype(T))

function ArrowField(name::AbstractString, ::Type{T}) where {T <: AbstractVector}
    ret = ArrowField(name, arrowlist)
    push!(ret.children, ArrowField("", eltype(T)))
    ret
end

function ArrowField(name::AbstractString, ::Type{T}) where {T <: NamedTuple}
    ret = ArrowField(name, arrowstruct)
    append!(ret.children, ArrowField.(zip(x.names, x.types)))
    ret
end

struct ArrowBuffer
    offset::Int64
    length::Int64
end

mutable struct ArrowSchema
    endianness::ArrowEndianness
    fields::Vector{ArrowField}
    custom_meadata::Vector{ArrowKeyValue}
end

FlatBuffers.@DEFAULT ArrowSchema endianness = ArrowLittle

###############################################################################
# From fields to Arrow type
###############################################################################

jltype(field::ArrowField) = jltype(field.typ, field)
jltype(typ::ArrowType, field::ArrowField) = jltype(typ)
jltype(typ::ArrowList, field::ArrowField) = Vector{jltype(field.children[1])}

function jltype(typ::ArrowStruct, field::ArrowField)
    NamedTuple{tuple([Symbol(v.name) for v in field.children]...), Tuple{jltype.(field.children)...}}
end

###############################################################################
# Bytes types
###############################################################################

# Type to distinguish between List<UInt8> and Binary

struct Binary
    value::AbstractVector{UInt8}
end

struct FixedSizeBinary{N}
    value::AbstractVector{UInt8}

    function FixedSizeBinary{M}(v::AbstractVector{UInt8}) where M
        @assert length(v) == M
        new(v)
    end
end

###############################################################################
# Datetime types
###############################################################################

const DateUnit = Union{Dates.Day,Dates.Millisecond}

struct Datestamp{P <: DateUnit, T <: Union{Int32,Int64}}
    value::T
end

const Date32 = Datestamp{Dates.Day,Int32}
const Date64 = Datestamp{Dates.Millisecond,Int64}

const TimeUnit = Union{Dates.Second,Dates.Millisecond,Dates.Microsecond,Dates.Nanosecond}

struct Timestamp{P <: TimeUnit, T <: Union{Int32,Int64}}
    value::T
end

struct TimeOfDay{P <: TimeUnit, T <: Union{Int32,Int64}}
    value::T
end

struct Decimal{P,S} # TODO
    value::UInt128
end

###############################################################################
# Type mapping for composite Arrow types
###############################################################################

###############################################################################
# Type mapping for singleton Arrow types
###############################################################################

jltype(::ArrowNull)   = Missing
jltype(::ArrowBool)   = Bool
jltype(::ArrowString) = String
jltype(::ArrowBinary) = Binary

arrowtype(::Type{Missing})        = arrownull
arrowtype(::Type{Bool})           = arrowbool
arrowtype(::Type{AbstractString}) = arrowstring
arrowtype(::Type{Binary})         = arrowbinary

###############################################################################
# Type mapping for parameteric Arrow types
###############################################################################

abstract type ArrowIntType{W,S} end
jltype(::Type{ArrowIntType{8, true}})  = Int8
jltype(::Type{ArrowIntType{16,true}})  = Int16
jltype(::Type{ArrowIntType{32,true}})  = Int32
jltype(::Type{ArrowIntType{64,true}})  = Int64
jltype(::Type{ArrowIntType{8, false}}) = UInt8
jltype(::Type{ArrowIntType{16,false}}) = UInt16
jltype(::Type{ArrowIntType{32,false}}) = UInt32
jltype(::Type{ArrowIntType{64,false}}) = UInt64
jltype(x::ArrowInt) = jltype(ArrowIntType{x.bitWidth,x.is_signed})

arrowtype(::Type{T}) where {T <: Signed}   = ArrowInt(sizeof(T) * 8, true)
arrowtype(::Type{T}) where {T <: Unsigned} = ArrowInt(sizeof(T) * 8, false)

abstract type ArrowFloatType{P} end
jltype(::Type{ArrowFloatType{ArrowHalf}})   = Float16
jltype(::Type{ArrowFloatType{ArrowSingle}}) = Float32
jltype(::Type{ArrowFloatType{ArrowDouble}}) = Float64
jltype(x::ArrowFloatingPoint) = jltype(ArrowFloatType{x.precision})

arrowtype(::Type{Float16}) = ArrowFloatingPoint(ArrowHalf)
arrowtype(::Type{Float32}) = ArrowFloatingPoint(ArrowSingle)
arrowtype(::Type{Float64}) = ArrowFloatingPoint(ArrowDouble)

abstract type ArrowDateType{U} end
jltype(::Type{ArrowDateType{ArrowDate32}}) = Date32
jltype(::Type{ArrowDateType{ArrowDate64}}) = Date64
jltype(x::ArrowDate) = jltype(ArrowDateType{x.unit})

arrowtype(::Type{Date32}) = ArrowDate(ArrowDa32)
arrowtype(::Type{Date64}) = ArrowDate(ArrowDa64)

abstract type ArrowTimeUnitType{U} end
jltype(::Type{ArrowTimeUnitType{ArrowSecond}})      = Dates.Second
jltype(::Type{ArrowTimeUnitType{ArrowMillisecond}}) = Dates.Millisecond
jltype(::Type{ArrowTimeUnitType{ArrowMicrosecond}}) = Dates.Microsecond
jltype(::Type{ArrowTimeUnitType{ArrowNanosecond}})  = Dates.Nanosecond
jltype(x::ArrowTimeUnit) = jltype(ArrowTimeUnit{x})

arrowtimeunit(::Type{Dates.Second})      = ArrowSecond
arrowtimeunit(::Type{Dates.Millisecond}) = ArrowMillisecond
arrowtimeunit(::Type{Dates.Microsecond}) = ArrowMicrosecond
arrowtimeunit(::Type{Dates.Nanosecond})  = ArrowNanosecond

jltype(x::ArrowTime)      = TimeOfDay{jltype(ArrowTimeUnitType{x.unit}),jltype(ArrowInt(x.bitWidth,true))}
jltype(x::ArrowTimestamp) = Timestamp{jltype(ArrowTimeUnitType{x.unit})}

arrowtype(::Type{TimeOfDay{P,T}}) where {P,T} = ArrowTime(arrowtimeunit(P),sizeof(T) * 8)
arrowtype(::Type{Timestamp{P}})   where {P}   = ArrowTimestamp(arrowtimeunit(P))

jltype(x::ArrowDecimal) = Decimal{Int(x.precision),Int(x.scale)}
arrowtype(::Type{Decimal{P,S}}) where {P,S} = ArrowDecimal(P,S)

jltype(x::ArrowFixedSizeBinary) = FixedSizeBinary{Int(x.bytewidth)}
arrowtype(::Type{FixedSizeBinary{W}}) where {W} = ArrowFixedSizeBinary(W)

# TODO interval

###############################################################################
# Type mapping for composite Arrow types
###############################################################################

# TODO List
# TODO Struct
# TODO Union
# TODO FixedSizeList
# TODO Map
