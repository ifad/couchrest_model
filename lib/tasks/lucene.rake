namespace :db do
  namespace :couch do

    desc "Load views in db/couch/* into the configured couchdb instance"
    task :migrate => :environment do
      require 'couchrest/model/migrations'
      CouchRest::Model::Migrations.migrate!
      puts
    end

  end
end
