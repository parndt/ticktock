require 'bundler/setup'
require 'pathname'
require 'yaml'
require 'harvested'
require 'active_support/core_ext'

class TickTock

  attr_accessor :config

  def initialize(config = File.expand_path('../config/authentication.yml', __FILE__))
    read_config! config
  end

  def report!(user_id = @config[:user_id], from, to)
    harvest.reports.time_by_user user_id, from, to
  end

  def semimonthly_hours!(user_id = @config[:user_id])
    entries = report! user_id, *current_semimonthly_period
    entries.map { |entry| entry.hours.to_f }.sum
  end

  def harvest
    @harvest ||= Harvest.client config[:subdomain],
                                config[:username],
                                config[:password]
  end

  def current_semimonthly_period
    @timeframe = if Time.now.day <= 15
      [Time.now.beginning_of_month, Time.now.beginning_of_month + 14.days]
    else
      [Time.now.beginning_of_month + 15.days, Time.now.end_of_month]
    end
  end

  def read_config!(config)
    unless File.exist?(config)
      FileUtils::cp "#{config}.example", config.to_s
    end
    @config = ::HashWithIndifferentAccess.new
    @config.update YAML::load(File.read(config))
  end

end
