# frozen_string_literal: true

require "redi_search/index"
require "active_support/concern"

module RediSearch
  module Model
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength
    class_methods do
      attr_reader :redi_search_index, :redi_search_serializer

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def redi_search(schema:, **options)
        @redi_search_index = Index.new(
          [options[:index_prefix],
           model_name.plural, RediSearch.env].compact.join("_"),
          schema,
          self
        )
        @redi_search_serializer = options[:serializer]
        register_redi_search_commit_hooks

        scope :search_import, -> { all }

        class << self
          def search(term = nil, **term_options)
            redi_search_index.search(term, **term_options)
          end

          def spellcheck(term, distance: 1)
            redi_search_index.spellcheck(term, distance: distance)
          end

          def reindex
            redi_search_index.reindex(search_import.map(&:redi_search_document))
          end
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      private

      def register_redi_search_commit_hooks
        after_commit(:redi_search_add_document, on: %i(create update)) if
          respond_to?(:after_commit)
        after_destroy_commit(:redi_search_delete_document) if
          respond_to?(:after_destroy_commit)
      end
    end
    # rubocop:enable Metrics/BlockLength

    def redi_search_document
      Document.for_object(
        self.class.redi_search_index, self,
        serializer: self.class.redi_search_serializer
      )
    end

    def redi_search_delete_document
      return unless self.class.redi_search_index.exist?

      self.class.redi_search_index.del(
        redi_search_document, delete_document: true
      )
    end

    def redi_search_add_document
      return unless self.class.redi_search_index.exist?

      self.class.redi_search_index.add(redi_search_document, replace: true)
    end
  end
end
