namespace :db do
  namespace :couch do

    desc "Load views in db/couch/* into the configured couchdb instance"
    task :migrate => :environment do
      Dir["db/couch/**/*.js"].each do |file|
        source = File.read(file).
          gsub(/\n\s*/, '').      # Our JS multiline string implementation :-p
          gsub(/\/\*.*?\*\//, '') # And strip multiline comments as well.

        document = CouchRest::Design.new JSON.parse(source)
        document.database = CouchRest::Model::Base.database

        document['_id']      ||= "_design/#{File.basename(file, '.js')}"
        document['language'] ||= 'javascript'

        current = document.database.get(document.id) rescue nil
        if current.nil?
          puts "Creating #{document.id}"
          document.save
        else
          puts "Upgrading #{document.id} #{document.rev}"
          current.update(document)
          current.save
        end
      end
    end

  end
end
