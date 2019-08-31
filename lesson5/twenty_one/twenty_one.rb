require_relative 'game_crafter'
require_relative 't_o_player'
require_relative 'deck'

# Plays a one round game.
# It has to be provided with players and a Ruler for the parent class.
class GameRoundCrafter < GameCrafter
  include Printer

  attr_accessor :ruler, :players, :winner

  def initialize(args)
    @players = args[:players]
    @players_enum = @players.to_enum
    @current_player = @players_enum.next
    @winner = nil
    @link_display = true
    @scores_compare = true
    super(args[:ruler])
  end

  def play
    loop do
      display_game_field if @current_player.need_display?
      current_player_moves
      @winner = @current_player if current_player_won?
      break if current_player_won? || game_over?

      swap_player_clear_screen
    end
    clear unless @link_display
    display_game_field

    winner&.scored
  end

  def won_message
    winner.won_message
  end

  def display_game_field
    display_intro
    puts ""
    super
    puts ""
  end

  private

  def current_player_won?
    player_won?(@current_player)
  end

  def display_intro
    players.each(&:display_info_game_field)
  end

  def game_over?
    exhausted?(@current_player)
  end

  def clear
    system('clear') || system('cls')
  end

  def current_player_moves
    @current_player.move(self)
  end

  def swap_player_clear_screen
    @current_player = @players_enum.next
  rescue StopIteration
    @players_enum.rewind
    clear
    retry
  end

  def clear_last_display
    @clear_last
  end
end



class TORunner
  include Retrievable

  GAME_THRESHOLD = 2

  attr_accessor :players, :game, :game_ruler

  def initialize
    @players = [Gambler.new, Dealer.new]
    @game_ruler = ToDeckRuler.new(players)
    @game = GameRoundCrafter.new(
      { players: players,
        ruler: game_ruler,
        with_clear: false }
    )
    @messages_file = 'to_templates.yml'
    @retrieved_options = {}
    load_yaml_file
  end

  def play
    start
    play_games
  end

  private

  attr_accessor :local_binding

  def play_games
    loop do
      play_rounds
      display_game_result
      break unless player_new_game?

      clear
      print_margin "Let's play a new game!"
      new_game_same_players
    end
    display_template_bind("goodbye")
  end

  def player_new_game?(yes = 'y')
    yes == set_retrieve_option(:quit_game).downcase
  end

  def play_rounds
    loop do
      game.play
      set_winner_score
      display_round_result
      break if contest_winner? || player_quit?

      clear
      new_round
      print_margin "Let's play again!"
    end
  end

  def set_winner_score
    return if game.winner || game_ruler.tie?
    game.winner = game_ruler.winner
    game.winner.scored
  end

  def new_game_same_players
    players.each(&:reset_score_cards)
    @game_ruler = ToDeckRuler.new(players)
    @game = GameRoundCrafter.new(players: players,
                                 ruler: game_ruler)
  end

  def new_round
    players.each(&:reset_cards)
    @game_ruler = ToDeckRuler.new(players)
    @game = GameRoundCrafter.new(players: players,
                                 ruler: game_ruler)
  end

  def display_round_result
    display_template_bind("round_result")
  end

  def display_game_result
    display_template_bind("to_game_winner") if contest_winner?
  end

  def contest_winner?
    players.count { |player| player.score == GAME_THRESHOLD } > 0
  end

  def contest_winner
    players.select { |player| player.score == GAME_THRESHOLD }.first
  end

  def display_welcome_game_explanation
    print_message("to_welcome", tail: "\n\n")
    display_template_bind("to_rules")
  end

  def start
    clear
    display_welcome_game_explanation
    print_message("to_choose_name", tail: "\n\n")
    retrieve_players_name if user_choose_name?
    update_players_names
    clear
  end

  def update_players_names
    return unless retrieved_options[:players_name]
    players.each_index do |player_index|
      player = players[player_index]
      new_name = retrieved_options[:players_name][player_index]
      player.name = new_name
    end
  end

  def options
    { players_name: :no_empty,
      user_choose_name: :y_n,
      player_quit: :any,
      quit_game: :y_n }
  end

  def retrieve_players_name
    retrieved_merge_retrieve_many(players, :players_name)
  end

  def user_choose_name?(yes = 'y')
    yes == set_retrieve_option(:user_choose_name).downcase
  end

  def player_quit?(quit = 'q')
    quit == set_retrieve_option(:player_quit).downcase
  end
end

to_game = TORunner.new
to_game.play
