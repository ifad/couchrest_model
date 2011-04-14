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
      end

    end
  end
end
