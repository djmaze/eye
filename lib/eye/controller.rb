require 'celluloid'

require 'yaml'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/string/filters'

require_relative 'utils/leak_19'

Eye.send(:extend, Eye::Logger::Helpers)

class Eye::Controller
  include Celluloid

  autoload :Load,           'eye/controller/load'
  autoload :Helpers,        'eye/controller/helpers'
  autoload :Commands,       'eye/controller/commands'
  autoload :Status,         'eye/controller/status'
  autoload :SendCommand,    'eye/controller/send_command'
  autoload :ShowHistory,    'eye/controller/show_history'
  autoload :Options,        'eye/controller/options'

  include Eye::Logger::Helpers
  include Eye::Controller::Load
  include Eye::Controller::Helpers
  include Eye::Controller::Commands
  include Eye::Controller::Status
  include Eye::Controller::SendCommand
  include Eye::Controller::ShowHistory
  include Eye::Controller::Options

  attr_reader :applications, :current_config

  def initialize
    @applications = []
    @current_config = Eye::Config.new

    Eye.instance_variable_set(:@logger, Eye::Logger.new('eye'))
    @logger = Eye.logger 
    Celluloid::logger = Eye.logger

    Eye::SystemResources.setup
    
    info "starting #{Eye::ABOUT} (#{$$})"
  end

  def settings
    current_config.settings
  end

end
