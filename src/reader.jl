struct ArrayData
    datatype::ArrowDataType
    length::Int64
    null_count::Int64
    buffers::Vector{Vector{UInt8}}
    children::Vector{ArrowData}
end

struct RecordBatch
    schema::ArrowSchema
    data::Vector{ArrayData}
end

struct DictionaryBatch
    id::Int64
    data::RecordBatch
    isDelta::Bool
end

struct Message
end

function read(io::IO, ::Type{Message})
    len = readio(io, Int32)
    metadata = Flatbuffers.deserializer(IOBuffer(read(io, len)), ArrowMessage)
end

struct RecordBatchStreamReader
    batches::RecordBatch
end

struct RecordBatchFileReader
end
