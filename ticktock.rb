require 'bundler/setup'
require 'pathname'
require 'harvested'

class TickTock

  attr_accessor :config

  def initialize
    unless (config_file = Pathname.new(File.expand_path('../config/authentication.yml', __FILE__))).exist?
      FileUtils::cp "#{config_file}.example", config_file.to_s
    end
    @config = YAML::load config_file.read
  end

end

TickTock.new