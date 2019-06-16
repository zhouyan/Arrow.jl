# SparseTensor.fbs

mutable struct AarrowSparseTensorIndexCOO
  indicesBuffer::ArrowBuffer
end

mutable struct ArrowSparseMatrixIndexCSR
  indptrBuffer::ArrowBuffer
  indicesBuffer::ArrowBuffer
end

@UNION ArrowSparseTensorIndex (Nothing,SparseTensorIndexCOO,SparseMatrixIndexCSR)

mutable struct ArrowSparseTensor
  typ::ArrowType
  shape::Vector{ArrowTensorDim}
  non_zero_length::Int64
  sparseIndex::ArrowSparseTensorIndex
  data::ArrowBuffer
end
