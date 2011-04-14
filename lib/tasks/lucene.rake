namespace :db do
  namespace :couch do

    desc "Load views in db/couch/* into the configured couchdb instance"
    task :migrate => :environment do
      Dir["db/couch/**/*.js"].each do |file|
        source = File.read(file).
          gsub(/\n\s*/, '').      # Our JS multiline string implementation :-p
          gsub(/\/\*.*?\*\//, '') # And strip multiline comments as well.
        document = JSON.parse source

        document['_id']      ||= "_design/#{File.basename(file, '.js')}"
        document['language'] ||= 'javascript'

        db = CouchRest::Model::Base.database
        id = document['_id']

        curr = db.get(id) rescue nil
        if curr.nil?
          db.save_doc(document)
        else
          db.delete_doc(curr)
          db.save_doc(document)
        end
      end
    end

  end
end
