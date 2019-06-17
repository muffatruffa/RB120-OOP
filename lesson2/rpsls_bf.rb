class Player
  attr_accessor :move, :name

  def initialize
    set_name
  end
end

class Human < Player
  def set_name
    n = nil
    loop do
      puts "Hello, choose a name for yuor player."
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  def move_from_str(str)
    moves = [
      Rock.new,
      Paper.new,
      Scissors.new,
      Lizard.new,
      Spock.new
    ]
    obj_index = Move.allowed_moves.index(str)
    moves[obj_index]
  end

  def choose
    choice = nil
    allowed_str = Move.allowed_moves.join(", ")
    loop do
      puts "Please choose #{allowed_str}"
      choice = gets.chomp
      break if Move.allowed_moves.include? choice
      puts "Sorry, invalid choice."
    end
    self.move = move_from_str(choice)
  end
end

class Computer < Player
  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def move_from_int(num)
    moves = [
      Rock.new,
      Paper.new,
      Scissors.new,
      Lizard.new,
      Spock.new
    ]
    moves[num]
  end

  def choose
    self.move = move_from_int(Move.random_value)
  end
end

class Move
  include Comparable
  attr_reader :value

  VALUES = %w(rock paper scissors lizard spock)

  def initialize(idx)
    @value = VALUES[idx]
  end

  def <=>(other_move)
    compare_with(other_move)
  end

  def to_s
    value
  end

  def self.random_value
    (1..(VALUES.size - 1)).to_a.sample
  end

  def self.allowed_moves
    VALUES.clone
  end
end

class Rock < Move
  def initialize
    super(0)
  end

  def compare_with(other_move)
    other_move.compare_rock
  end

  def compare_rock
    0
  end

  def compare_paper
    1
  end

  def compare_scissors
    -1
  end

  def compare_lizard
    -1
  end

  def compare_spock
    1
  end
end

class Paper < Move
  def initialize
    super(1)
  end

  def compare_with(other_move)
    other_move.compare_paper
  end

  def compare_rock
    -1
  end

  def compare_paper
    0
  end

  def compare_scissors
    1
  end

  def compare_lizard
    1
  end

  def compare_spock
    -1
  end
end

class Scissors < Move
  def initialize
    super(2)
  end

  def compare_with(other_move)
    other_move.compare_scissors
  end

  def compare_rock
    1
  end

  def compare_paper
    -1
  end

  def compare_scissors
    0
  end

  def compare_lizard
    -1
  end

  def compare_spock
    1
  end
end

class Lizard < Move
  def initialize
    super(3)
  end

  def compare_with(other_move)
    other_move.compare_lizard
  end

  def compare_rock
    1
  end

  def compare_paper
    -1
  end

  def compare_scissors
    1
  end

  def compare_lizard
    0
  end

  def compare_spock
    -1
  end
end

class Spock < Move
  def initialize
    super(4)
  end

  def compare_with(other_move)
    other_move.compare_spock
  end

  def compare_rock
    -1
  end

  def compare_paper
    1
  end

  def compare_scissors
    -1
  end

  def compare_lizard
    1
  end

  def compare_spock
    0
  end
end

class Round
  attr_reader :players, :moves
  def initialize(players)
    @players = players
    @moves = []
  end

  def add_move(move)
    @moves << move
  end

  def tie?
    return nil if @moves.empty?
    first = @moves[0]
    @moves.all? { |move| move == first }
  end

  def winner
    return nil if @moves.empty? || tie?
    best_move = 0
    @moves.each_index do |move_idx|
      best_move = move_idx if @moves[move_idx] > @moves[best_move]
    end
    @players[best_move]
  end

  def play
    @players.each do |player|
      player.choose
      add_move(player.move)
    end
    display_result
  end

  def display_winner
    display_moves
    puts "#{winner.name} won!"
  end

  def display_moves
    @players.each_index do |idx|
      puts "#{@players[idx].name} chose #{@moves[idx]}"
    end
  end

  def display_result
    if tie?
      display_tie
    else
      display_winner
    end
  end

  def display_tie
    display_moves
    puts "It's a tie!"
  end
end

class RPSGame
  attr_accessor :human, :computer

  GAME_THRESHOLD = 2

  CLEAR_SCREEN = 3

  def initialize(human = Human.new, computer = Computer.new)
    @human = human
    @computer = computer
    @rounds = []
  end

  def clear_screen
    (@rounds.size % CLEAR_SCREEN == 0) &&
      (system('clear') || system('cls'))
  end

  def add_round
    @rounds << Round.new([human, computer])
  end

  def winner?
    scores = { human => 0, computer => 0 }
    @rounds.each do |round|
      scores[round.winner] += 1 if round.winner
    end
    scores.any? { |_player, score| score == GAME_THRESHOLD }
  end

  def play_again?
    user_answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      user_answer = gets.chomp
      break if ['y', 'n'].include? user_answer.downcase
      puts "Sorry, must be y or n"
    end
    user_answer.downcase == 'y'
  end

  def display_winner
    return unless winner?
    puts "We have a Game winner"
    puts "*** #{winner.name} ***"
  end

  def display_summary
    puts
    puts "Rounds summary"
    @rounds.each_index do |idx|
      current_round = @rounds[idx]
      puts "Round\t#{idx + 1}"
      current_round.display_result
    end
    puts "#{winner.name} won the Game!" if winner
  end

  def winner
    game_winner = nil
    scores = { human => 0, computer => 0 }
    @rounds.each do |round|
      scores[round.winner] += 1 if round.winner
    end
    scores.each do |player, score|
      game_winner = player if score == GAME_THRESHOLD
    end
    game_winner
  end

  def on?
    !winner?
  end

  def human_scores
    scores = 0
    @rounds.each do |round|
      scores += 1 if round.winner && round.winner == human
    end
    scores
  end

  def computer_scores
    scores = 0
    @rounds.each do |round|
      scores += 1 if round.winner && round.winner == computer
    end
    scores
  end

  def play_rounds
    loop do
      add_round
      @rounds.last.play
      puts "#{human.name} scored: #{human_scores}"
      puts "#{computer.name} scored: #{computer_scores}"
      break unless on? && play_again?
      clear_screen
    end
  end

  def play
    play_rounds
    display_winner if winner?
  end
end

class RPSSession
  attr_reader :games

  def initialize
    @game = RPSGame.new
    @games = []
    @end_session = false
  end

  def add_game(game)
    @games << game
  end

  def play_games
    display_welcome_message
    add_game(@game)
    @games.last.play
    loop do
      break unless play_again?
      @game = RPSGame.new(@game.human, @game.computer)
      add_game(@game)
      @games.last.play
    end
    display_goodbye_message
  end

  def play_again?
    user_answer = nil
    loop do
      puts "Would you like to play another game? (y/n)"
      user_answer = gets.chomp
      break if ['y', 'n'].include? user_answer.downcase
      puts "Sorry, must be y or n"
    end
    user_answer.downcase == 'y'
  end

  def display_welcome_message
    puts "Hello #{@game.human.name}"
    puts "Welcome to Rock, Paper, Scissors, Lizard, Spock!"
  end

  def display_goodbye_message
    puts "Thanks for playing Rock, Paper, Scissors, Lizard, Spock. Good bye! "
  end
end
session = RPSSession.new
session.play_games

session.games.each_index do |idx|
  puts
  puts "Game #{idx + 1}"
  session.games[idx].display_summary
end

# system('clear') || system('cls')
# game.play
