# Schema.fbs

@enum ArrowMetadataVersion::Int16 ArrowV1 ArrowV2 ArrowV3 ArrowV4
@enum ArrowUnionMode::Int16       ArrowSparse ArrowDense
@enum ArrowPrecision::Int16       ArrowHalf ArrowSingle ArrowDouble
@enum ArrowDateUnit::Int16        ArrowDate32 ArrowDate64
@enum ArrowTimeUnit::Int16        ArrowSecond ArrowMillisecond ArrowMicrosecond ArrowNanosecond
@enum ArrowIntervalUnit::Int16    ArrowYearMonth ArrowDayTime
@enum ArrowEndianness::Int16      ArrowLittle ArrowBig

abstract type ArrowDataType end

mutable struct ArrowNull   <: ArrowDataType end
mutable struct ArrowBool   <: ArrowDataType end
mutable struct ArrowStruct <: ArrowDataType end
mutable struct ArrowList   <: ArrowDataType end
mutable struct ArrowString <: ArrowDataType end
mutable struct ArrowBinary <: ArrowDataType end

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

@DEFAULT ArrowDate unit = ArrowDate32

mutable struct ArrowTime <: ArrowDataType
    unit::ArrowTimeUnit
    bitWidth::Int32
end

@DEFAULT ArrowTime unit = ArrowMillisecond bitWidth = 32

mutable struct ArrowTimestamp
    unit::ArrowTimeUnit
    timezone::String
end

mutable struct ArrowInterval
    unit::ArrowIntervalUnit
end

@UNION ArrowType (
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

mutable struct ArrowField
    name::String
    nullable::Bool
    typid::Int8
    typ::ArrowType
    dictionary::ArrowDictionaryEncoding
    children::Vector{ArrowField}
    custom_meadata::Vector{ArrowKeyValue}
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

@DEFAULT ArrowSchema endianness = ArrowLittle
