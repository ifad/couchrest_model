require 'rails/generators/couchrest_model'

module CouchrestModel
  module Generators
    class LuceneViewGenerator < Base
      desc %[Creates a generic Lucene view that indexes every CouchRest::Model instance]

      def create_lucene_view
        template 'lucene.js', 'db/couch/_design/lucene.js'
        puts "\n   Don't forget to run rake db:couchdb:migrate to push the view to CouchDB\n\n"
      end
    end
  end
end
