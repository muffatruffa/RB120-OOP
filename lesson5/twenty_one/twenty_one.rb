require 'pry'
require_relative 'game_crafter'
require_relative 't_o_player'
require_relative 'deck'

# Plays a one round game.
# It has to be provided with players and a Ruler for the parent class.
class GameRoundCrafter < GameCrafter
  include Printer
  attr_reader :winner
  attr_accessor :ruler, :players

  def initialize(args)
    @players = args[:players]
    @players_enum = @players.to_enum
    @current_player = @players_enum.next
    @winner = nil
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
    clear
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
end

class TORunner
  include Retrievable

  attr_accessor :players, :game

  def initialize
    @players = [Gambler.new, Dealer.new]
    @game = GameRoundCrafter.new(
      { players: players, ruler: ToDeckRuler.new(players) }
    )
    @messages_file = 'to_templates.yml'
    load_yaml_file
  end

  def play
    start
    game.play
  end

  private

  attr_accessor :local_binding

  def display_welcome_game_explanation
    print_message("to_welcome", tail: "\n\n")
    display_template_bind("to_rules")
    display_template_bind("to_game")
  end

  def start
    display_welcome_game_explanation
  end
end

to_game = TORunner.new
to_game.play
