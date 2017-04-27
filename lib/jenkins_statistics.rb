require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

$LOAD_PATH << File.expand_path('../', __FILE__)

ENV['RACK_ENV'] ||= 'development'

if %w(development test).include? ENV['RACK_ENV']
  require 'pry'
  require 'dotenv'
  case ENV['RACK_ENV']
  when 'test'
    Dotenv.load '.env.test'
  when 'development'
    Dotenv.load '.env'
  end
end

require 'singleton'
require 'json'
require 'net/http'
require 'active_support/all'

require 'data_fetcher'
require 'dashboard_updater'

Dir.glob(File.join('.', 'lib', 'jobs', '*.rb'), &method(:require))


class JenkinsStatistics
  include Singleton

  def self.run(*jobs)
    instance.run(*jobs)
  end

  def self.lookup(name)
    instance.lookup(name)
  end

  def initialize
    db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    Sequel::Model.plugin :timestamps
    # Sequel::Model.plugin :table_select
    # Sequel::Model.plugin :association_dependencies
    # Sequel.extension :pg_array_ops, :pg_array_ops
    db.extension :pg_enum#, :pg_array, :pg_json
    @services = {
      env: ENV,
      db: db,
    }
  end

  def run(*jobs)
    jobs.each do |job_name|
      job_class = job_name.to_s.classify.constantize
      inject_dependecies(job_class.new).run
    end
  end

  def lookup(name)
    @services[name.to_sym]
  end

  private

  def inject_dependecies(job)
    arguments = job.method(:init).parameters.map do |(_, name)|
      SERVICES[name]
    end
    job.init(*arguments)
    job
  end
end
