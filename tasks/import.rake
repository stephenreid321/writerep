task :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'boot.rb'))
end

namespace :import do
  task :mps => :environment do
    Representative.import_mps
  end
end