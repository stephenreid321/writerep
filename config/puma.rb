workers Integer(ENV['WEB_CONCURRENCY'] || 3)
threads Integer(ENV['MIN_THREADS'] || 1), Integer(ENV['MAX_THREADS'] || 1)
port        ENV['PORT']
environment ENV['RACK_ENV']

preload_app!
