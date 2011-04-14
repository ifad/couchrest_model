module CouchRest
  module Model
    module Migrations
      extend self

      def migrate!
        sources.each do |file|
          migrate read_source(file)
        end
      end

      def sources
        Dir["db/couch/**/*.js"]
      end

      def read_source(file)
        source = File.read(file).
          gsub(/\n\s*/, '').      # Our JS multiline string implementation :-p
          gsub(/\/\*.*?\*\//, '') # And strip multiline comments as well.

        Design.new(JSON.parse(source)).tap do |document|
          document.database = Base.database

          document['_id']      ||= "_design/#{File.basename(file, '.js')}"
          document['language'] ||= 'javascript'
        end
      end

      def generate_version_for(document)
        document['version'] = Date.today.strftime('%Y%m%d01').to_i
      end

      def should_upgrade(current, document)
        current['version'].blank? || \
          current['version'].to_i < document['version'].to_i
      end

      def migrate(document)
        puts "== #{document.id}"

        if document['version'].blank?
          puts "   WARNING: no version specified"
          generate_version_for document
        end

        current = document.database.get(document.id) rescue nil

        if current.nil?
          document.save
          puts "   created (#{document['version']})"

        elsif should_upgrade current, document
          current.update(document)
          current.save
          puts "   upgraded (#{current['version']} -> #{document['version']})"

        else
          puts "   up to date (#{current['version']})"
        end
      end
    end
  end
end
