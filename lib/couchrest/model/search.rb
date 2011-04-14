module CouchRest
  module Model
    module Search
      extend ActiveSupport::Concern

      module ClassMethods

        def search(query, options = {})
          index = options.delete(:index) || 'search'

          ret = database.search(
            "_design/lucene/#{index}", options.update(
              :q            => "couchrest_type:#{self.name} AND (#{query})",
              :include_docs => true
          ))

          ret['rows'].map! {|row| new row['doc'] }
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
