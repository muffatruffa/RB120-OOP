require_relative './print_helpers'

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
      print "=> Choose a name for yuor player: "
      n = gets.chomp.strip
      break unless n.empty?
      print "=> Sorry, must enter a name composed of letters: "
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
      print "=> Choose one: #{allowed_str}: "

      choice = Move.validate_user_input(gets.chomp.strip)
      break if choice
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
  attr_reader :value, :rules_key

  RULES = { rk: { rk: false, pa: false, sc: true, sp: false, lz: true },
            pa: { rk: true, pa: false, sc: false, sp: true, lz: false },
            sc: { rk: false, pa: true, sc: false, sp: false, lz: true },
            sp: { rk: true, pa: false, sc: true, sp: false, lz: true },
            lz: { rk: false, pa: true, sc: false, sp: true, lz: false } }

  VALUES = %w(rock paper scissors lizard spock)

  def initialize
    @value = self.class.name.downcase
  end

  def self.validate_user_input(user_input)
    case user_input
    when /\Ar[ock]*\Z/i then VALUES[0]
    when /\Ap[aper]*\Z/i then VALUES[1]
    when /\As[cissors]*\Z/i then VALUES[2]
    when /\Al[izard]*\Z/i then VALUES[3]
    when /\Asp[ock]*\Z/i then VALUES[4]
    else false
    end
  end

  def ==(other)
    rules_key == other.rules_key
  end

  def >(other)
    RULES[rules_key][other.rules_key]
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
    super
    @rules_key = :rk
  end
end

class Paper < Move
  def initialize
    super
    @rules_key = :pa
  end
end

class Scissors < Move
  def initialize
    super
    @rules_key = :sc
  end
end

class Lizard < Move
  def initialize
    super
    @rules_key = :lz
  end
end

class Spock < Move
  def initialize
    super
    @rules_key = :sp
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
    puts "   #{winner.name} won!"
  end

  def display_moves
    @players.each_index do |idx|
      puts "   #{@players[idx].name} chose #{@moves[idx]}"
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
    puts "   It's a tie!"
  end
end

class RPSGame
  attr_accessor :human, :computer

  GAME_THRESHOLD = 5

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

  def scores
    game_scores = { human => 0, computer => 0 }
    @rounds.each do |round|
      game_scores[round.winner] += 1 if round.winner
    end
    game_scores
  end

  def winner?
    scores().any? { |_player, score| score == GAME_THRESHOLD }
  end

  def retrieve_play_again_answer
    print "=> Press any key to continue the game or q to end this game. "
    gets.chomp.strip
  end

  def play_again?(user_answer)
    user_answer.downcase != 'q'
  end

  def display_winner
    puts "   We have a Game winner"
    puts "   *** #{winner.name} ***"
  end

  def display_summary
    puts
    puts " Rounds summary"
    @rounds.each_index do |idx|
      current_round = @rounds[idx]
      puts " Round\t#{idx + 1}"
      current_round.display_result
    end
    puts
    puts " #{winner.name} won the Game!" if winner
  end

  def winner
    game_winner = nil
    scores().each do |player, score|
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
      puts "   #{human.name} scored: #{human_scores}"
      puts "   #{computer.name} scored: #{computer_scores}"
      break unless on? && play_again?(retrieve_play_again_answer)
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
      break unless play_again?(retrieve_play_again_answer)
      @game = RPSGame.new(@game.human, @game.computer)
      add_game(@game)
      @games.last.play
    end
    display_goodbye_message
  end

  def retrieve_play_again_answer
    user_answer = nil
    loop do
      print "   Would you like to play another game? (y/n) "
      user_answer = gets.chomp
      break if ['y', 'n'].include? user_answer.downcase
      puts "   Sorry, must be y or n"
    end
    user_answer
  end

  def play_again?(user_answer)
    user_answer.downcase == 'y'
  end

  def display_welcome_message
    puts "   Hello #{@game.human.name}"
    puts "   You will play against #{@game.computer.name}."
    puts "   To win a match you need to win #{RPSGame::GAME_THRESHOLD} rounds."
  end

  def display_goodbye_message
    puts "   Thanks for playing Rock, Paper, Scissors, Lizard, Spock. Good bye!"
  end
end

print_intro
session = RPSSession.new
session.play_games

session.games.each_index do |idx|
  puts
  puts "Game #{idx + 1}"
  session.games[idx].display_summary
end

# system('clear') || system('cls')
# game.play
