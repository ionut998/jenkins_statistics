require 'json'
require 'net/http'
require 'active_support/all'

require './lib/data_fetcher'
require './lib/dashboard_updater'

Dir.glob(File.join('.', 'lib', 'jobs', '*.rb'), &method(:require))


class JenkinsStatistics
  SERVICES = {
    env: ENV,
    db: nil,
  }

  def self.run(*jobs)
    jobs.each do |job_name|
      job_class = job_name.to_s.classify.constantize
      inject_dependecies(job_class.new).run
    end
  end

  def self.inject_dependecies(job)
    arguments = job.method(:init).parameters.map do |(_, name)|
      SERVICES[name]
    end
    job.init(*arguments)
    job
  end

  private_class_method :inject_dependecies
end
