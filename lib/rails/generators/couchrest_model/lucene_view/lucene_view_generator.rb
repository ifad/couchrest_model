require 'rails/generators/couchrest_model'

module CouchrestModel
  module Generators
    class LuceneViewGenerator < Base
      desc %[Creates a generic Lucene view that indexes every CouchRest::Model instance]

      def create_lucene_view
        template 'lucene.js', 'db/couch/_design/lucene.js'
      end
    end
  end
end
