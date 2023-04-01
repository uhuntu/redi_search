# frozen_string_literal: true

# FT.CREATE ... SCHEMA ... {field_name} VECTOR 
# {algorithm} 
# {count} [
#   {attribute_name} {attribute_value} 
#   ...
# ]

# title_embedding = VectorField("title_vector",
#   "FLAT", {
#       "TYPE": "FLOAT32",
#       "DIM": VECTOR_DIM,
#       "DISTANCE_METRIC": DISTANCE_METRIC,
#       "INITIAL_CAP": VECTOR_NUMBER,
#   }
# )

# FT.CREATE my_idx SCHEMA vec_field VECTOR 
# FLAT 6 = 3 * 2
# TYPE FLOAT32 
# DIM 128 
# DISTANCE_METRIC L2

# TYPE - Vector type. Current supported types are FLOAT32 and FLOAT64.
# DIM - Vector dimension specified as a positive integer.
# DISTANCE_METRIC - Supported distance metric, one of {L2, IP, COSINE}.
# INITIAL_CAP * Initial vector capacity in the index affecting memory allocation size of the index.
# BLOCK_SIZE * Block size to hold BLOCK_SIZE amount of vectors in a contiguous array. This is useful when the index is dynamic with respect to addition and deletion. Defaults to 1024.

# FT.CREATE my_index1 
# SCHEMA vector_field VECTOR 
# FLAT 10 
# TYPE FLOAT32 
# DIM 128 
# DISTANCE_METRIC L2 
# INITIAL_CAP 1000000 
# BLOCK_SIZE 1000

module RediSearch
  class Schema
    class VectorField < Field
      def initialize(
        name, 
        algorithm:        "FLAT",
        count:            0,
        type:             "FLOAT32",
        dim:              0,
        distance_metric:  "COSINE",
        initial_cap:      0,
        block_size:       1024,
        sortable:         false,
        no_index:         false, 
        &block
      )
        @name = name
        @value_block = block

        { algorithm:        algorithm,
          count:            count,
          type:             type,
          dim:              dim,
          distance_metric:  distance_metric,
          initial_cap:      initial_cap,
          block_size:       block_size,
          sortable:         sortable,
          no_index:         no_index 
        }.each do |attr, value|
          instance_variable_set("@#{attr}", value)
        end
      end

      def to_a
        query = [name.to_s, "VECTOR"]
        query += [algorithm, count]
        query += ["TYPE", type] if type
        query += ["DIM", dim] if dim
        query += ["DISTANCE_METRIC", distance_metric] if distance_metric
        query += ["INITIAL_CAP", initial_cap] if initial_cap
        query += ["BLOCK_SIZE", block_size] if block_size
        query += boolean_options_string

        query
      end

      private

      attr_reader :sortable, 
                  :no_index

      def boolean_options
        %i(sortable no_index)
      end
    end
  end
end
