# Allow to retreive inputs from the user
# using messages stored in .yml file.
# To mix this in and use it's #retrieve method implement:
# #handle_option_message, #validator #handle_option_error.
# To use ERB template in .yml file
# provide suitable binding in #local_binding

require 'yaml'
require 'erb'

module Retrievable
  attr_accessor :options, :current_option_key

  def self.included(klass)
    to_inlcude = constants.lazy
                          .map { |constant| const_get(constant) }
                          .select do |constant|
                            constant.instance_of?(Module)
                          end
    to_inlcude.to_a.each { |nested_module| klass.include nested_module }
  end

  private

  def load_yaml_file
    @messages = YAML.load_file(@messages_file)
  end

  def print_message(key, tail: '', margin: '  ')
    lines = @messages[key].split(/\n/)
    lines[0..-2].each { |message_line| puts margin + message_line }
    print margin + lines[-1] + tail
  end

  def message(key)
    return '' if @messages[key].nil?

    template = ERB.new(@messages[key])
    case local_binding
    when Hash
      template.result_with_hash(local_binding)
    when Binding
      template.result(local_binding)
    else
      template.result
    end
  end

  def retrieve
    answer = nil
    loop do
      handle_option_message
      answer = gets.chomp.strip
      break if validator.match(answer)

      handle_option_error
    end
    answer
  end

  module HandleOptions
    def concat_to_option_key(key, tail)
      key.to_s + tail
    end

    def option_intro(key = current_option_key)
      concat_to_option_key key, "_intro"
    end

    def option_message(key = current_option_key)
      concat_to_option_key key, "_option"
    end

    def option_error(key = current_option_key)
      concat_to_option_key key, "_error"
    end

    def option_uniq_error(key = current_option_key)
      concat_to_option_key key, "_uniq"
    end

    # Use this to display to user just once
    # It IS NOT called by #retieve
    def handle_option_intro(key = current_option_key)
      print_margin message(option_intro(key))
    end

    # First of Methods required by Retrievable
    # called by #retieve
    def handle_option_message(key = current_option_key)
      prompt message(option_message(key))
    end

    # called by #retieve
    def handle_option_error(key = current_option_key)
      print_margin message(option_error(key))
    end

    # called by #retieve
    def handle_uniq_error(key = current_option_key)
      print_margin message(option_uniq_error(key))
    end

    # set @current_option_key @local_binding. #option_key is used to
    # retrieve from .yml file, #local_binding is used for
    # the evaluation of ERB templates
    def set_option_binding(option_key, template_binding)
      self.current_option_key = option_key
      self.local_binding = template_binding
    end

    # Use this to retrieve a message from .yml file containing a ERB template
    # that need a binding
    def display_template_bind(message_key, template_binding = binding)
      self.local_binding = template_binding
      print_margin message(message_key)
    end

    # set @current_option_key @local_binding and retrieve option
    # from user
    def set_retrieve_option(option_key, template_binding: nil)
      set_option_binding(option_key, template_binding)
      retrieve
    end
  end

  # provides #validator
  module BakedRgx
    RGX = { no_empty: /\S/, # succeed only if not empty string given
            y_n: /\A[yn]\Z/i, # succeed if y or n given, case insensitive
            any: /.*/, # succeed for any character from 0 to many
            character: /\A.\Z/, # succeed only if any one character
            one_digit: /\A\d\Z/,
            "3_5_7": /\A[357]\Z/,
            "2_to_9": /\A[2-9]\Z/,
            h_s: /\A[hs]\Z/i } # succeed if h or s given, case insensitive

    def self.all
      RGX.dup
    end

    def self.add(new_baked)
      all.merge! new_baked
    end

    def self.[](rgx_key)
      all[rgx_key]
    end

    def validator
      BakedRgx[options[current_option_key]]
    end
  end
  module Printer
    MARGIN = '  '

    def prompt(message, margin = MARGIN)
      return if message.nil? || message == ''

      lines = message.split(/\n/)
      lines[0..-2].each do |message_line|
        print_halves(margin + message_line + "\n")
      end
      print_halves(margin + lines[-1] + " => ")
    end

    def print_margin(message, margin = MARGIN, tail = "\n")
      return if message.nil? || message == ''

      lines = message.split(/\n/)
      lines[0..-2].each do |message_line|
        print_halves(margin + message_line + "\n")
      end
      print_halves(margin + lines[-1] + tail)
    end

    def print_halves(to_slice, margin = MARGIN, min_size = 80)
      return print to_slice if to_slice.size < min_size

      median = to_slice.size / 2
      print(to_slice[0..median] + "\n")
      print(margin + to_slice[(median + 1)..-1].lstrip)
    end
  end
end
