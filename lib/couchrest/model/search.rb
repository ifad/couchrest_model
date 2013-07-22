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

        def lucene_query
          @lucene_query.dup if @lucene_query
        end

        def count
          query.update(:include_docs => false)
          result!['total_rows']
        end
        alias :total_count :count
        alias :size :count

        def empty?
          count.zero?
        end

        protected

        def typed_lucene_query
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

            use_database.search(design_doc, query.merge(:q => typed_lucene_query))
          end
        end

        def update_query(new_query = {})
          self.class.new(self, @lucene_query, new_query.update(:index => @lucene_index))
        end

        def can_reduce?
          false
        end

        private

        # For merging multiple queries
        def method_missing(meth, *args, &block)
          if model.respond_to?(meth)
            merge(model.public_send(meth, *args, &block))
          else
            super
          end
        end

        def merge(view)
          unless view.is_a?(self.class)
            raise "Cannot merge #{self.class} and #{query.class}"
          end

          query = [self.lucene_query, view.lucene_query].compact.
            map {|q| "(#{q})" }.join(' AND ').presence

          options = self.query.update(view.query)


          self.class.new(self, query, options)
        end
      end

    end
  end
end
