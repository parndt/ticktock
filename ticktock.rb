require 'bundler/setup'
require 'pathname'
require 'yaml'
require 'harvested'
require 'active_support/core_ext'
require 'money'
require 'money/bank/google_currency'
require 'pry'

class TickTock

  attr_accessor :config

  def initialize(config: File.expand_path('../config/authentication.yml', __FILE__))
    read_config! config
  end

  def report!(from, to, user_id: @config[:user_id])
    harvest.reports.time_by_user user_id, from, to
  end

  def unbilled(entries)
    entries.reject(&:is_billed).reject{|e| Array(@config[:bad_project_ids]).include?(e.project_id) }
  end

  def summed(entries)
    entries.sum { |entry| (entry.hours_with_timer || entry.hours).to_f }
  end

  def hours_output_file
    File.expand_path('../.hours', __FILE__)
  end

  def semimonthly_hours!(user_id: @config[:user_id], write_output: true)
    entries = report! *current_semimonthly_period, user_id: user_id
    output = summed(entries)
    write_output!(output) if write_output
    output
  end

  def uninvoiced_hours!(user_id: @config[:user_id], write_output: true)
    output = round_up_to_nearest_half_hour(summed(uninvoiced_entries))
    write_output!(output) if write_output
    output
  end

  def uninvoiced_entries(user_id: @config[:user_id])
    entries = report! Time.now - 3.months, Time.now, user_id: user_id
    entries = round_entries_up_to_nearest_half_hour(unbilled(entries))
    entries
  end

  def uninvoiced_income_projection(currency_conversion: true, home_currency: @config[:home_currency])
    Money.default_bank = Money::Bank::GoogleCurrency.new if currency_conversion

    entries = add_project_and_client_to_entries(uninvoiced_entries)
    group_entry_values_by_currency(entries).map do |currency, income_data_points|
      if currency_conversion
        Money.new(
          income_data_points.sum * 100, # convert it to cents
          currency
        ).exchange_to(home_currency).to_f
      else
        income_data_points.sum
      end
    end.sum
  end

  def add_project_and_client_to_entries(entries)
    entries.map do |entry|
      entry["project"] = find_project(entry["project_id"])
      entry["client"] = find_client(entry.project.client_id)
      entry
    end
  end

  def group_entry_values_by_currency(entries)
    entries.inject({}) do |hash, entry|
      income_data_point = entry.hours * entry.project.hourly_rate.to_f
      (hash[entry.client.currency.split(' ').last] ||= []) << income_data_point
      hash
    end
  end

  def uninvoiced_income_projection!
    write_output!(uninvoiced_income_projection)
  end

  def round_up_to_nearest_quarter_hour(hours)
    (hours * 4).ceil / 4.0
  end

  def round_up_to_nearest_half_hour(hours)
    (hours * 2).ceil / 2.0
  end

  def round_entries_up_to_nearest_half_hour(entries)
    entries.map do |entry|
      entry["hours"] = round_up_to_nearest_half_hour((entry.hours_with_timer || entry.hours).to_f)
      entry
    end
  end

  def all_projects
    @all_projects ||= harvest.projects.all
  end

  def all_clients
    @all_clients ||= harvest.clients.all
  end

  def find_project(id)
    all_projects.detect { |project| project.id == id }
  end

  def find_client(id)
    all_clients.detect { |client| client.id == id }
  end

  def harvest
    @harvest ||= Harvest.client subdomain: config[:subdomain],
                                username: config[:username],
                                password: config[:password]
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
    File.open(hours_output_file, 'w+') { |file| file.write(hours); file.write("\n") }
  end

end

if ENV['UNINVOICED']
  TickTock.new.uninvoiced_hours!
elsif ENV['SEMIMONTHLY']
  TickTock.new.semimonthly_hours!
elsif ENV['PROJECTION']
  TickTock.new.uninvoiced_income_projection!
end
