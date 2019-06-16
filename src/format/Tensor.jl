# Tensor.fbs

mutable struct ArrowTensorDim
    size::Int64
    name::String
end

mutable struct ArrowTensor
    typ::ArrowType
    shape::Vector{ArrowTensorDim}
    strides::Vector{Int64}
    data::Buffer
end
