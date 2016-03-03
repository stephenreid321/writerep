activate-template
=================

Activate Digital Padrino/Mongoid template project

## Delayed::Job
```
gem 'delayed_job_mongoid'
gem 'delayed_job_active_record'
```

tasks/jobs.rake:
```ruby
task :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'boot.rb'))
end

namespace :jobs do
  
  desc 'Clear the delayed_job queue'
  task :clear => :environment do
    Delayed::Job.delete_all
  end

  desc 'Start a delayed_job worker'
  task :work => :environment do
    Delayed::Worker.new.start
  end
  
  desc 'Start a delayed_job worker and exit when all available jobs are complete'
  task :workoff => :environment do
    Delayed::Worker.new(:exit_on_complete => true).start
  end  
  
end
```

Procfile:
```
worker: bundle exec rake jobs:work   
```

lib/delayed_job_airbrake.rb:
```ruby
module Delayed
  class Worker
    alias_method :original_handle_failed_job, :handle_failed_job

    protected
    def handle_failed_job(job, error)
      Airbrake.notify(error)
      original_handle_failed_job(job,error)
    end
  end
end
```

## Postgres + ActiveRecord
```
gem 'pg'
gem 'activerecord', '>=4.0', require: 'active_record'
gem 'activerecord_any_of', github: 'oelmekki/activerecord_any_of'
```

boot.rb:
```
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
```

app.rb:
```
use ActiveRecord::ConnectionAdapters::ConnectionManagement
```

unicorn.rb:
```
before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end
```

Rakefile:
```
PadrinoTasks.use(:activerecord)
```

## Testing
```
group :test do
  gem 'minitest-rg'
  gem 'launchy'
  gem 'factory_girl'
  gem 'capybara'
  gem 'poltergeist'
end
```
