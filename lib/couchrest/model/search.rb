module CouchRest
  module Model
    module Search
      extend ActiveSupport::Concern

      module ClassMethods

        def search(query, options = {})
          View.new(self, query, options)
        end

        def skip_from_index
          before_save do |document|
            document['skip_from_index'] = true
          end
        end
      end

      class View < CouchRest::Model::Designs::View
        def initialize(model, lucene_query, query = {})
          @lucene_query = lucene_query
          @lucene_index = query.delete(:index) || 'search'

          query.update(:include_docs => true)

          design = "_design/lucene/#@lucene_index" # TODO Use a DesignDoc instance

          super(design, model, query, "#{model.name} \"#@lucene_query\" Search")
        end

        def total_count
          result!['total_rows']
        end

        protected

        def lucene_query
          klass = "#{model.model_type_key}:\"#{model.name}\""
          query = @lucene_query.blank? ? nil : "(#@lucene_query)"

          [klass, query].compact.join(' AND ')
        end

        def result!
          execute && result
        end

        def execute
          self.result ||= begin
            raise "No database defined for #{model.name!}" if use_database.nil?

            use_database.search(design_doc, query.merge(:q => lucene_query))
          end
        end

        def update_query(new_query = {})
          self.class.new(self, @lucene_query, new_query.update(:index => @lucene_index))
        end

        def can_reduce?
          false
        end
      end

    end
  end
end
