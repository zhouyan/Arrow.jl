# Message.fbs

mutable struct ArrowFieldNode
    length::Int64
    null_count::Int64
end

mutable struct ArrowRecordBatch
    length::Int64
    nodes::Vector{ArrowFieldNode}
    buffers::Vector{Buffer}
end

mutable struct ArrowDictionaryBatch
    id::Int64
    data::ArrowRecordBatch
    isDelta::Bool
end

@DEFAULT ArrowDictionaryBatch isDelta = false

@UNION ArrowMessageHeader (
                           Nothing,
                           ArrowSchema,
                           ArrowDictionaryBatch,
                           ArrowRecordBatch,
                           ArrowTensor,
                           ArrowSparseTensor
                          )

mutable struct Message
    version::ArrowMetadataVersion
    header::ArrowMessageHeader
    bodyLength::Int64
    custom_metadata::Vector{ArrowKeyValue}
end
