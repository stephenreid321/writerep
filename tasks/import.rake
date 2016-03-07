task :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'boot.rb'))
end

namespace :representatives do
  task :import => :environment do
    Representative.import
  end
end