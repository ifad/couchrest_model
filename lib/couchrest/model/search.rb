module CouchRest
  module Model
    module Search
      extend ActiveSupport::Concern

      module ClassMethods

        def search(query, options = {})
          options[:limit] ||= self.count

          # This works around the C-L error:
          #
          #   java.lang.IllegalArgumentException: numHits must be > 0; please
          #   use TotalHitCountCollector if you just need the total hit count
          #
          # that should be fixed properly in C-L itself. FIXME!
          options.delete(:limit) if options[:limit] == 0

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

          design = "lucene/#@lucene_index" # TODO Use a DesignDoc instance

          super(design, model, query, "#{model.name} \"#@lucene_query\" Search")

          setup_sorting
        end

        def lucene_query
          @lucene_query.dup if @lucene_query
        end

        def count
          @count ||= begin
            previous = self.query.dup
            self.query.update(:include_fields => false, :limit => 1)

            result!['total_rows'].tap do
              self.query = previous
              self.result = nil
            end
          end
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

            search = query.except(:q, :sort).merge(:q => typed_lucene_query)

            if query[:sort].present?
              search[:sort] = query[:sort].join(',')
            end

            unless query.key?(:include_docs)
              search[:include_docs] = true
            end

            use_database.search(design_doc, search)
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
            raise "Cannot merge #{self.class} with #{view.class}"
          end

          query = [self.lucene_query, view.lucene_query].compact.
            map {|q| "(#{q})" }.join(' AND ').presence

          sort = (self.query[:sort] || []).concat(view.query[:sort] || [])

          options = self.query.except(:sort).update(view.query.except(:sort))

          self.class.new(self, query, options).tap do |result|
            result.query[:sort] = sort
            result.send(:setup_sorting) # FIXME this sucks, and should be refactored
          end
        end

        def setup_sorting
          sort = Array.wrap(query[:sort])
          if sort.present?
            has_direction = query.key?(:descending)
            direction = query.delete(:descending) ? '\\' : '/'

            query[:sort] = sort.map do |field|
              if field[0].in?(%w(\\ /))
                has_direction ? field.tap { field[0] = direction } : field
              else
                direction + field
              end
            end
          end
        end
      end

    end
  end
end
