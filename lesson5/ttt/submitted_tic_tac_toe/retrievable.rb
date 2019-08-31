# Allow to retreive inputs from the user
# using messages stored in .yml file.
# To mix this in and use it's #retrieve method implement:
# #handle_option_message, #validator #handle_option_error.
# To use ERB template in .yml file
# provide suitable binding in #local_binding

require 'yaml'
require 'erb'

module Retrievable
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
end
