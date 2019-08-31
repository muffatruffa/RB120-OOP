require_relative 'game_round_crafter'
require_relative 'board'
require_relative 'player'
require_relative 'retrievable'
require_relative 'printer'

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
    @game = GameRoundCrafter.new(players: players, ruler: board)
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
    @game = GameRoundCrafter.new(players: players, ruler: board)
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
    @game = GameRoundCrafter.new(players: players, ruler: board)
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
