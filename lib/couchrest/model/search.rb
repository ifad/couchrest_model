module CouchRest
  module Model
    module Search
      extend ActiveSupport::Concern

      module ClassMethods

        def search(query, options = {})
          index = options.delete(:index) || 'search'

          query = query.blank? ? nil : "(#{query})"
          klass = "#{self.model_type_key}:\"#{self.name}\""

          ret = database.search(
            "_design/lucene/#{index}", options.update(
              :q            => [klass, query].compact.join(' AND '),
              :include_docs => true
          ))

          ret['rows'].map! {|row| new row['doc'], :directly_set_attributes => true }
        end

        def skip_from_index
          before_save do |document|
            document['skip_from_index'] = true
          end
        end


      end

    end
  end
end
