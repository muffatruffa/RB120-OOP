require_relative 'printer'

# A player in a TTT game or contest, can choose and keep track of games won.
class TTTPlayer
  include Printer

  attr_reader :games_won, :choice
  attr_accessor :name, :marker, :user_player

  def initialize(args = {})
    @marker = args[:marker] || default_marker
    @name = args[:name] || default_name
    @games_won = 0
    @choice = nil
    @choices = []
    @user_player = false
  end

  def template_binding
    binding
  end

  def reset_games_won
    @games_won = 0
  end

  def reset_choices
    @choices = []
  end

  def scored
    @games_won += 1
  end

  def choices
    joinor(@choices, ', ', 'and')
  end

  def display_info_game_field
    tail = user_player ? "  ( you )" : ""
    print_margin "#{name} ( #{marker} ): #{choices}" + tail
  end

  def default_name
    ''
  end

  def default_marker
    raise NotImplementedError,
          "This #{self.class} cannot respond to: " + methode_name
  end

  def need_display?
    false
  end

  def won_message
    "#{name} won!"
  end

  def marker_message
    "My marker is: #{marker}"
  end

  def user_player?
    @user_player
  end

  private

  def joinor(line, separator=', ', and_or='or')
    len = line.size
    case len
    when 0
      ''
    when 1
      line[0].to_s
    when 2
      line[0].to_s + " #{and_or} " + line[1].to_s
    else
      line[0..-2].join(separator) + " #{and_or} " + line[-1].to_s
    end
  end

  def add_choice
    @choices << @choice
  end
end

class Human < TTTPlayer
  def move(game_crafter)
    @choice = pick_one_of(game_crafter.available_choices)
    add_choice
    game_crafter.accomodate_choice(self)
  end

  def pick_one_of(available_choices)
    square = nil
    loop do
      prompt "Choose a square (#{joinor(available_choices)})"
      square = gets.chomp.to_i
      break if available_choices.include?(square)

      print_margin "Sorry, that's not a valid choise.\n"\
        "Enter one of: #{joinor(available_choices)}"
    end
    square
  end

  def default_marker
    'X'
  end

  def need_display?
    true
  end

  def marker_message
    "You're a: #{marker}"
  end

  def default_names
    %w(Betty Pebbles Bamm Fred Wilma Barney)
  end

  def default_name
    default_names.sample
  end

  def name_message
    "Your player name could be: " +
      default_names[0..-2].join(', ') +
      ' or ' + default_names[-1] + '.'
  end

  def determiner
    'Your'
  end
end

class Computer < TTTPlayer
  def move(game_crafter)
    @choice = game_crafter.strategy_choice(self)
    add_choice
    game_crafter.accomodate_choice(self)
  end

  def marker_message
    "Computer is a #{marker}."
  end

  def default_names
    %w(HAL TARDIS HER Minsky R2D2 GERTY)
  end

  def default_name
    default_names.sample
  end

  def default_marker
    'O'
  end

  def name_message
    "Computer's player name could be: " +
      default_names[0..-2].join(', ') +
      ' or ' + default_names[-1] + '.'
  end

  def determiner
    "Computer's"
  end
end
