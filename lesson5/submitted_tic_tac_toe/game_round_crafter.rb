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
