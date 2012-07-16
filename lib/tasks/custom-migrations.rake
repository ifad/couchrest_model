namespace :couchrest do

  desc "Load views in db/couch/* into the configured couchdb instance"
  task :migrate_custom => :environment do
    require 'couchrest/model/migrate/custom'
    CouchRest::Model::Migrate::Custom.run!
  end

end
