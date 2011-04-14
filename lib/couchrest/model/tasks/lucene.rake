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

        puts "== #{document.id}"

        if document['version'].blank?
          puts "   WARNING: no version specified"
          document['version'] = Date.today.strftime('%Y%m%d01').to_i
        end

        current = document.database.get(document.id) rescue nil

        if current.nil?
          puts "   created (#{document['version']})"
          document.save
        else

          if current['version'].blank? || current['version'] < document['version']
            puts "   upgraded (#{current['version']} -> #{document['version']})"

            current.update(document)
            current.save
          else
            puts "   up to date (#{current['version']})"
          end
        end

        puts
      end
    end

  end
end
