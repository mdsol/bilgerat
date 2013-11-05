# encoding: utf-8

# Based on https://github.com/cucumber/cucumber/blob/master/lib/cucumber/formatter/pretty.rb and the other cucumber
# built in formatters.
# There was no handy api so I had to reverse engineer

class Bilgerat

  def initialize(step_mother, path_or_io, options)
  end


  def before_background(background)
    @background_failed = nil
    reset_scenario_info
    @in_background = background
  end

  def after_background(background)
    @in_background = nil
    @background_tags = @tags
    @tags = nil
  end

  def tag_name(tag)
    (@tags ||= []) << tag
  end

  def scenario_name(keyword, name, file_colon_line, source_indent)
    reset_scenario_info
    @current_scenario_info = {keyword: keyword, name: name, file_colon_line: file_colon_line, tags: @tags}
    @tags = nil
  end

  def after_table_row(table_row)
    return unless @in_examples and Cucumber::Ast::OutlineTable::ExampleRow === table_row
    @example_num += 1  if !@header_row
    if table_row.exception
      hipchat_exception(table_row.exception)
    elsif !@header_row && table_row.failed?
      hipchat_exception('<failure had no exception>')
    end
    @header_row = false
  end

  def before_examples(*args)
    @in_examples = true
    @header_row = true
  end

  def after_examples(*args)
    @in_examples = false
  end

  def exception(exception, status)
    hipchat_exception(exception)
  end

  # file_colon_line is new in cucumber 1.2.0.  Give it default of nil to be reverse compatible
  def step_name(keyword, step_match, status, source_indent, background, file_colon_line=nil)
    @current_failed_step_info = nil
    #TODO: detect if we are running in strict mode somehow, and if so also send a message when status == :pending
    if status == :failed
      @current_failed_step_info = {step_match: step_match, file_colon_line: file_colon_line, status: status}
    end
  end

  private

  # send failure report to hipchat
  def hipchat_exception(exception)
    # If the background fails only send one message the first time
    return if @background_failed

    # If this is a failing scenario output includes:
    # 1a) file & line number for scenario
    # 1b) all tags, including those declared on the feature
    # 1c) scenario name
    # 2) failing step
    # 3) The exception

    # If this is a failing example, then output includes:
    # 1) For the first failing example in an outline the same as above, omitted for the subsequent examples
    # 2) "Example #X failed:"
    # 3) the exception

    # If this was a failing background step:
    # 1a) file & line number for background
    # 1b) "Background step failed:"
    # 2) failing step
    # 3) the exception

    sb = ''

    # part 1
    unless @had_failing_example
      if @current_scenario_info
        sb << "# #{ @current_scenario_info[:file_colon_line] }\n"
        all_tags = (@background_tags || []) + (@current_scenario_info[:tags] || [])
        sb << all_tags.join(' ') + "\n"  if all_tags.size > 0
        sb << "#{ @current_scenario_info[:keyword]}: #{ @current_scenario_info[:name]}\n"
      elsif @in_background
        sb << "# #{ @in_background.file_colon_line }\nBackground step failed:\n"
        @background_failed = true
      else
        sb = 'error: no scenario info'
      end
    end

    # part2
    if @current_failed_step_info # Failing scenario or background, not example
      sb << "#{ current_step_match_to_str } # "
      fcl = @current_failed_step_info[:file_colon_line]  # line in the feature file, may be nil
      sb << fcl << ' → ' if fcl
      sb << @current_failed_step_info[:step_match].file_colon_line << "\n"
    elsif @example_num
      @had_failing_example = true
      sb << "Example ##{@example_num} failed:\n"
    end

    adapter.hip_post( "#{ sb }#{ build_exception_detail(exception) }", color: :error )
  end

  # Convert the step match (saved from step_name(), above into a string for outputting.
  def current_step_match_to_str
    current_step_match = @current_failed_step_info[:step_match]
    # current_step_match might be a StepMatch or a NoStepMatch.  If a NoStepMatch we must pass in dummy argument to format_args
    args = current_step_match.is_a?(Cucumber::NoStepMatch)? [nil] : []
    current_step_match.format_args(*args)
  end

  def adapter
    HipchatAdapter
  end

  # Based on cucumber code
  def build_exception_detail(exception)
    return exception if exception.is_a? String
    backtrace = Array.new

    message = exception.message
    if defined?(RAILS_ROOT) && message.include?('Exception caught')
      matches = message.match(/Showing <i>(.+)<\/i>(?:.+) #(\d+)/)
      backtrace += ["#{RAILS_ROOT}/#{matches[1]}:#{matches[2]}"] if matches
      matches = message.match(/<code>([^(\/)]+)<\//m)
      message = matches ? matches[1] : ""
    end

    unless exception.instance_of?(RuntimeError)
      message = "#{message} (#{exception.class})"
    end

    message << "\n" << backtrace.join("\n")
  end

  def reset_scenario_info
    @current_failed_step_info = @current_scenario_info = @example_num = @had_failing_example = nil
    @example_num = 0
  end

end

# In theory in the future there might be different adapters that can plug in to the output formatter, but for now
# there is just this one.
class HipchatAdapter

  class << self
    DEFAULTS = {
        :message_format => 'text',
        :notify => '1'
    }.freeze


    # Send a message to a HipChat room
    # TODO: fork a thread so we don't block tests while we wait for the network
    def hip_post(message, options = {})
      if ENV['DEBUG_BILGERAT']
        unless @debug_file
          @debug_file = File.open(ENV['DEBUG_BILGERAT'], 'w')
          @debug_file.puts "<debugfile>"
          at_exit { @debug_file.puts "</debugfile>" }
        end
        @debug_file.puts "<HIPPOST>#{ message }</HIPPOST>"
      end

      return unless configured?

      def option(sym)
        return options[sym] if options.keys.include?(sym)
        DEFAULTS[sym]
      end

      # Replace the 'error' color with a real color
      options[:color] = error_color if options[:color] == :error

      begin
        client[config['room']].send(username, message, DEFAULTS.merge(options))
        puts "sent msg to hipchat"
      rescue  => ex
        puts "Caught #{ex.class}; disabling hipchat notification"
        @configured = false
      end
    end

    # Config hash, from yml file

    private

    def error_color
      @error_color ||= config['error_color'] || 'red'
    end

    # Returns something that looks like a hash.  It returns values from the raw bash by first looking under the
    # current context, then under 'default'
    def config
      config_file = ENV['HIPCHAT_CONFIG_PATH'] || 'config/hipchat.yml'
      return nil unless File.exists?(config_file)


      @config ||= Class.new do
        @raw_config_yaml = YAML.load_file(config_file)

        @context = ENV['BILGERAT_CONTEXT'] if ENV['BILGERAT_CONTEXT'] && ENV['BILGERAT_CONTEXT'].length > 0

        def self.[](sym)
          sym = sym.to_s
          if @context
            hash = @raw_config_yaml[@context]
            return hash[sym] if hash && hash.keys.include?(sym)
          end
          @raw_config_yaml['default'][sym]
        end
      end
    end

    # Are we configured to send messages to HipChat?  If not just drop messages.
    def configured?
      if @configured.nil?
        @configured = !!(config && config['room'] && config['auth_token'])
      else
        @configured
      end
    end

    def client
      require 'hipchat'
      @client ||= HipChat::Client.new(config['auth_token'])
    end

    # The username as we want it to appear in the HipChat room.
    def username
      @username ||= begin
        env_var = config['user']
        case env_var
          when nil then
            'Bilge Rat'
          when Regexp.compile('#{TEST_ENV_NUMBER}') then
            test_env_number = ENV['TEST_ENV_NUMBER']
            test_env_number = '1' if test_env_number == ''
            env_var.gsub('#{TEST_ENV_NUMBER}', test_env_number || '')
          else
            env_var
        end
      end
    end

  end
end
