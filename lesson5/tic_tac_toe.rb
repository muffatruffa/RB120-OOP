require 'yaml'
require 'erb'

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

# Plays a one round game.
# It has to be provided with players and a Board
class GameRoundCrafter
  attr_reader :winner
  attr_accessor :board, :players

  def initialize(args)
    @board = args[:board]
    @players = args[:players]
    @players_enum = @players.to_enum
    @current_player = @players_enum.next
    @winner = nil
  end

  def play
    loop do
      display_game_field if @current_player.need_display?
      current_player_moves
      @winner = @current_player if current_player_won?
      break if current_player_won? || game_over?

      swap_player_clear_screen
    end
    clear
    display_game_field

    winner&.scored
  end

  def won_message
    winner.won_message
  end

  private

  def current_player_won?
    board.player_won?(@current_player)
  end

  def display_game_field
    display_intro
    puts ""
    board.draw
    puts ""
  end

  def display_intro
    players.each(&:display_info_game_field)
  end

  def game_over?
    board.unmarked_squares_number.empty?
  end

  def clear
    system 'clear'
  end

  def current_player_moves
    @current_player.move(board)
  end

  def swap_player_clear_screen
    @current_player = @players_enum.next
  rescue StopIteration
    @players_enum.rewind
    clear
    retry
  end
end

# Can draw other objects at the moment very close to board:
# the caller has to mix in Enumerable and respond to size
class Drawer
  attr_reader :margin_width, :column_width, :margin, :padding

  def initialize
    set_layout_sizes
    set_layout_components
  end

  def set_layout_sizes
    @margin_width = 5
    @column_width = 5
  end

  def set_layout_components
    @margin = ' ' * margin_width
    @padding = ' ' * (column_width / 2)
  end

  def draw_board(drawable, numbers_of_columns)
    last_row = drawable.drop(drawable.size - numbers_of_columns)
    all_rows_but_last = drawable.take(drawable.size - numbers_of_columns)

    all_rows_but_last.each_slice(numbers_of_columns) do |row|
      print_board_row(row)
      print_row_separator(row)
    end
    print_board_row(last_row)
  end

  private

  def print_board_row(row)
    print before_after_data(row) + "\n" + margin

    row.each_with_index do |column_data, index|
      row_ending = '|'
      row_ending = "\n" if index == row.size - 1
      line = { padding1: padding, column_data: column_data,
               padding2: padding, row_ending: row_ending }
      print format("%<padding1>s%<column_data>s%<padding2>s%<row_ending>s",
                   line)
    end

    print before_after_data(row) + "\n"
  end

  def print_row_separator(row)
    print margin + format("%<line>s+",
                          line: '-' * column_width) * (row.size - 1)
    print '-' * column_width + "\n"
  end

  def before_after_data(row)
    margin + format("%<spaces>s|",
                    spaces: ' ' * column_width) * (row.size - 1)
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def ==(other)
    marker == other.marker
  end
end

# Allows access to a double array as a single array using a Tile jargon
# To mix this in you have to implement #two_d_array
# and #set_tile_value(tile,value)
module Tileable
  include Enumerable

  def size
    number_of_tiles
  end

  def []=(tile_number, value)
    return unless valid_square?(tile_number)

    set_tile_value(two_d_array[row(tile_number)][column(tile_number)], value)
  end

  private

  def number_of_tiles
    number_of_rows_columns * number_of_rows_columns
  end

  def each
    (1..size).each { |tile_number| yield self[tile_number] }
  end

  def [](tile_number)
    return nil unless valid_square?(tile_number)

    two_d_array[row(tile_number)][column(tile_number)]
  end

  def tile_number(target_object)
    square_index = find_index { |square| square.equal? target_object }
    square_index + 1 if square_index
  end

  def column(tile_number)
    (tile_number - 1) % number_of_rows_columns
  end

  def row(tile_number)
    (tile_number - column(tile_number) - 1) / number_of_rows_columns
  end

  def flatten_index(row, column)
    row * number_of_rows_columns + column
  end

  def row_column_to_square_number(row, column)
    flatten_index(row, column) + 1
  end

  def valid_square?(tile_number)
    tile_number > 0 && tile_number <= size
  end

  def rows
    two_d_array.clone
  end

  def columns
    two_d_array.transpose
  end

  def main_diagonal
    diagonal = [[]]
    0.upto(number_of_rows_columns - 1) do |row_number|
      column_number = row_number
      diagonal[0] << two_d_array[row_number][column_number]
    end
    diagonal
  end

  def secondary_diagonal
    diagonal = [[]]
    0.upto(number_of_rows_columns - 1) do |row_number|
      column_number = number_of_rows_columns - 1 - row_number
      diagonal[0] << two_d_array[row_number][column_number]
    end
    diagonal
  end

  def all_same?(tiles)
    tiles.all? { |tile| tile == tiles.first }
  end
end

class Board
  include Tileable

  attr_reader :drawer
  attr_accessor :number_of_rows_columns

  def initialize(rows_columns = 3)
    @drawer = Drawer.new
    reset(rows_columns)
  end

  def draw
    drawer.draw_board(self, number_of_rows_columns)
  end

  def reset(rows_columns = number_of_rows_columns)
    @number_of_rows_columns = rows_columns
    @squares = Array.new(number_of_rows_columns) do |_|
      Array.new(number_of_rows_columns) { Square.new }
    end
  end

  def unmarked_squares_number
    unmarked = []
    each_with_index do |square_object, square_index|
      unmarked << square_index + 1 if square_object.unmarked?
    end
    unmarked
  end

  def player_won?(player)
    winning_combinations.each do |combination|
      squares = combination.map { |square| square_number(square) }
      return true if squares.include?(player.choice) &&
                     all_same_marker?(combination)
    end
    false
  end

  def suggest(player)
    winning_move(player.marker) ||
      defensive_move(player.marker) ||
      corner_center_or_any_move
  end

  private

  def two_d_array
    @squares
  end

  def set_tile_value(tile, value)
    tile.marker = value
  end

  def square_number(square)
    tile_number(square)
  end

  def all_same_marker?(squares_to_compare)
    all_same?(squares_to_compare)
  end

  def select_marked(target_marker)
    marked = []
    each_with_index do |square_object, square_index|
      marked << square_index + 1 if square_object.marker == target_marker
    end
    marked
  end

  def winning_move(target_marker)
    winning_combinations.each do |combination|
      if winning_line?(target_marker, combination)
        empty = combination.find(&:unmarked?)
        return square_number(empty)
      end
    end
    nil
  end

  def defensive_move(target_marker)
    winning_combinations.each do |combination|
      if threat_line?(target_marker, combination)
        empty = combination.find(&:unmarked?)
        return square_number(empty)
      end
    end
    nil
  end

  def corner_center_or_any_move
    target = corners_squares_number + [center_square_number]
    target &= unmarked_squares_number
    if target.include?(center_square_number)
      center_square_number
    elsif !target.empty?
      target.sample
    else
      unmarked_squares_number.sample
    end
  end

  def winning_combinations
    rows + columns + main_diagonal + secondary_diagonal
  end

  def winning_line?(target_marker, combination)
    marked = combination.count { |square| target_marker == square.marker }
    unmarked = combination.count(&:unmarked?)
    marked == (combination.size - 1) &&
      unmarked == 1
  end

  def threat_line?(target_marker, combination)
    empty_count = combination.count(&:unmarked?)
    marked = combination.select(&:marked?)
    empty_count == 1 &&
      all_same_marker?(marked) &&
      target_marker != marked.first.marker
  end

  def center_square_number
    row = column = number_of_rows_columns / 2
    row_column_to_square_number(row, column)
  end

  def corners_squares_number
    [1,
     number_of_rows_columns,
     size - number_of_rows_columns + 1,
     size]
  end
end

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
  def move(board)
    @choice = pick_one_of(board.unmarked_squares_number)
    add_choice
    board[choice] = marker
  end

  def pick_one_of(available_choices)
    square = nil
    loop do
      prompt "Choose a square (#{joinor(available_choices)})"
      square = gets.chomp.strip
      break if choice_valid?(square, available_choices)

      print_margin "Sorry, that's not a valid choise.\n"\
        "Enter one of: #{joinor(available_choices)}"
    end
    square.to_i
  end

  def choice_valid?(square, available_choices)
    /\A\d\d?\Z/.match(square) && available_choices.include?(square.to_i)
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
  def move(board)
    @choice = board.suggest(self)
    add_choice
    board[choice] = marker
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

# Allow to retreive inputs from the user
# using messages stored in .yml file.
# To mix this in and use it's #retrieve method implement:
# #handle_option_message, #validator #handle_option_error.
# To use ERB template in .yml file
# provide suitable binding in #local_binding
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

# Plays a Tic Tac Toe contest or a sequence of unrelated rounds.
# In a contest it keeps score of how many times (rounds) a player win.
# Just two players allowed, board could be any dimension but user can choose
# 3 5 or 7. User can choose players names, markers contest winning score.
class TTTGamesRunner
  include Retrievable
  include Printer

  attr_reader :game
  attr_accessor :multi_game, :players, :contest_threshold, :board, :user_quit

  VALIDATORS = { no_empty: /\S/, # succeed only if not empty string given
                 y_n: /\A[yn]\Z/i, # succeed if y or n given, case insensitive
                 any: /.*/, # succeed for any character from 0 to many
                 character: /\A.\Z/, # succeed only if any one character
                 one_digit: /\A\d\Z/,
                 "3_5_7": /\A[357]\Z/,
                 "2_to_9": /\A[2-9]\Z/ }

  YAML_KEYS_TEMPLATES = %w(ttt_welcome ttt_game
                           ttt_players ttt_first_player
                           ttt_may_choose player_quit
                           ttt_contest_winner) # options not included

  def initialize
    @board = Board.new
    @players = [first_player_default, scond_player_default]
    @game = GameRoundCrafter.new(players: players, board: board)
    @contest_threshold = 2
    @multi_game = true
    @retrieved_options = {}
    @user_game_options = [:first_player, :board_rows,
                          :multi_game, :contest_threshold]
    @user_players_options = [:players_name, :players_markers]
    @validators = VALIDATORS.dup
    @messages_file = 'ttt_messages.yml'
    load_yaml_file
  end

  def play_games
    clear
    if multi_game
      play_contest
    else
      play_sequences
    end
  end

  def start_game
    clear
    display_welcome_game_explanation
    handle_user_options if user_choose_options?
  end

  def end_game
    display_goodbye_message
  end

  private

  attr_accessor :user_game_options, :user_players_options, :retrieved_options,
                :current_option_key, :local_binding
  attr_reader :validators

  def play_sequences
    loop do
      game.play
      display_result
      break if games_over?

      clear
      new_game_same_players
      print_margin "Let's play again!"
    end
  end

  def play_contest
    loop do
      play_sequences
      display_contest_winner if contest_winner?
      break unless contest_winner? && play_new_game?

      reset_players_score
      new_game_same_players
      clear
    end
  end

  def games_over?
    if multi_game
      contest_winner? || player_quit?
    else
      player_quit?
    end
  end

  def reset_players_score
    players.each(&:reset_games_won)
  end

  def display_contest_winner
    display_template_bind("ttt_contest_winner")
  end

  def play_new_game?(yes = 'y')
    yes == set_retrieve_option(:new_game).downcase
  end

  def first_player_default
    player = Human.new
    player.user_player = true
    player
  end

  def scond_player_default
    Computer.new
  end

  def display_welcome_game_explanation
    print_message("ttt_welcome", tail: "\n\n")
    display_template_bind("ttt_game")
    display_players_defaults
    puts ""
    print_message("ttt_may_choose", tail: "\n\n")
  end

  # Get all option settings from user for @game and @players.
  # Store them in @retrieved_options and updates the default settings
  def handle_user_options
    retrieve_players_settings
    retrieve_game_settings
    update_default
  end

  # You must updates players_settings before game_setting
  def update_default
    update_players_settings
    update_game_settings
  end

  def update_players_settings
    players.each_index do |player_default_index|
      players[player_default_index].name =
        retrieved_options[:players_name][player_default_index]
      players[player_default_index].marker =
        retrieved_options[:players_markers][player_default_index]
    end
  end

  def update_game_settings
    update_first_player
    board.reset(retrieved_options[:board_rows].to_i)
    @game = GameRoundCrafter.new(players: players, board: board)
    self.multi_game = retrieved_options[:multi_game].downcase == 'y'
    return unless multi_game

    self.contest_threshold = retrieved_options[:contest_threshold].to_i
  end

  def update_first_player
    user_player = players.select(&:user_player?).first
    players.delete_if(&:user_player?)
    if retrieved_options[:first_player].downcase == 'y'
      players.prepend user_player
    else
      players.push user_player
    end
  end

  def retrieve_players_settings
    user_players_options.each do |option_key|
      clear
      retrieved_merge_retrieve_many(players, option_key)
    end
  end

  def retrieve_game_settings
    user_game_options.each do |option_key|
      clear
      # do not ask if user chosen do not play a contest
      next if option_key == :contest_threshold && single_game_chosen?

      handle_option_intro(option_key)
      retrieved_merge_retrieve(option_key)
    end
  end

  def user_choose_options?(yes = 'y')
    yes == set_retrieve_option(:user_choose).downcase
  end

  def single_game_chosen?
    return false if retrieved_options[:multi_game].nil?

    retrieved_options[:multi_game].downcase == 'n'
  end

  # Player need to implement #template_binding to public it's binding
  def display_players_defaults
    players.each do |player|
      display_template_bind("ttt_players", player.template_binding)
    end
    display_template_bind("ttt_first_player", first_player.template_binding)
  end

  # keys are options that will be chosen by user, values are keys
  # to access VALIDATORS
  def options
    { players_name: :no_empty,
      players_markers: :character,
      first_player: :y_n,
      board_rows: :"3_5_7",
      multi_game: :y_n,
      contest_threshold: :"2_to_9",
      player_quit: :any,
      user_choose: :y_n,
      new_game: :y_n }
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

  # Last of Methods required by Retrievable
  # called by #retieve
  def validator
    validators.fetch(options[current_option_key])
  end

  # set @current_option_key @local_binding. #option_key is used to
  # retrieve from .yml file, #local_binding is used for
  # the evaluation of ERB templates
  def set_option_binding(option_key, template_binding)
    self.current_option_key = option_key
    self.local_binding = template_binding
  end

  def retrieved_merge_retrieve(option_key, template_binding: nil)
    retrieved_options[option_key] =
      set_retrieve_option(option_key, template_binding: template_binding)
  end

  def retrieved_merge_retrieve_many(enumerable, option_key)
    handle_option_intro(option_key)
    retrieved = enumerable.each_with_object([]) do |item, result|
      answer = nil
      loop do
        answer = set_retrieve_option(option_key,
                                     template_binding: item.template_binding)
        downcased = result.map(&:downcase)
        break unless downcased.include?(answer.downcase)

        handle_uniq_error
      end
      result << answer
    end
    retrieved_options[option_key] = retrieved
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

  def first_player
    players.first
  end

  def new_game_same_players
    players.each(&:reset_choices)
    board.reset
    @game = GameRoundCrafter.new(players: players, board: board)
  end

  def display_result
    return print_margin game.won_message if game.winner

    display_tie
  end

  def display_goodbye_message
    puts
    print_margin "Thanks for palying Tic Tac Toe! Goodbye!"
  end

  def display_tie
    print_margin "It's a tie!"
  end

  def clear
    system 'clear'
  end

  def contest_winner
    winner = players.select { |player| player.games_won == contest_threshold }
    return winner.first unless winner.empty?

    nil
  end

  def contest_winner?
    players.any? { |player| player.games_won == contest_threshold }
  end

  def player_quit?(quit = 'q')
    quit == set_retrieve_option(:player_quit).downcase
  end

  def prompt(message, margin = '  ')
    return if message.nil? || message == ''

    lines = message.split(/\n/)
    lines[0..-2].each { |message_line| print margin + message_line + "\n" }
    print margin + lines[-1] + " => "
  end

  def print_margin(message, margin = '  ', tail = "\n\n")
    return if message.nil? || message == ''

    lines = message.split(/\n/)
    lines[0..-2].each { |message_line| print margin + message_line + "\n" }
    print margin + lines[-1] + tail
  end
end

contest = TTTGamesRunner.new
contest.start_game
contest.play_games
contest.end_game
