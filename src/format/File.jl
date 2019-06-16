# File.fbs

struct ArrowBlock
    offset::Int64
    metaDataLength::Int32
    bodyLength::Int64
end

mutable struct Footer
    version::ArrowMetadataVersion
    schema::ArrowSchema
    dictionaries::Vector{ArrowBlock}
    recordBatches::Vector{ArrowBlock}
end
