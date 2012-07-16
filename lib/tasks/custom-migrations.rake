namespace :couchrest do

  desc "Load views in db/couch/* into the configured couchdb instance"
  task :migrate_custom => :environment do
    require 'couchrest/model/utils/migrate/custom'
    CouchRest::Model::Utils::Migrate::Custom.run!
  end

end
