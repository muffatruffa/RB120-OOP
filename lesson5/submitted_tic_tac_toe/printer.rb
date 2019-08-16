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

  def print_margin(message, margin = MARGIN, tail = "\n\n")
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
