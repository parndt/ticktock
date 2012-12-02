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

  def unbilled(entries)
    entries.reject(&:is_billed)
  end

  def summed(entries)
    entries.sum { |entry| entry.hours.to_f }
  end

  def hours_output_file
    File.expand_path('../.hours', __FILE__)
  end

  def semimonthly_hours!(user_id = @config[:user_id])
    entries = report! user_id, *current_semimonthly_period
    write_output! summed(entries)
  end

  def uninvoiced_hours!(user_id = @config[:user_id])
    entries = report! user_id, Time.now - 1.year, Time.now
    write_output! round_up_to_nearest_quarter_hour(summed(unbilled(entries)))
  end

  def round_up_to_nearest_quarter_hour(hours)
    (hours * 4).ceil / 4.0
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

  def write_output!(hours)
    File.open(hours_output_file, 'w+') { |file| file.write hours }
  end

end

if ENV['UNINVOICED']
  TickTock.new.uninvoiced_hours!
elsif ENV['SEMIMONTHLY']
  TickTock.new.semimonthly_hours!
end
