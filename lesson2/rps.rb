class Player
  attr_accessor :move, :name
  attr_reader :game_score

  def initialize
    set_name
    @game_score = 0
  end

  def scored
    @game_score += 1
  end
end

class Human < Player
  def set_name
    n = nil
    loop do
      puts "What's your name?'"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  def choose
    choice = nil
    loop do
      puts "Please choose rock, paper, or scissors:"
      choice = gets.chomp
      break if Move.allowed_moves.include? choice
      puts "Sorry, invalid choice."
    end
    self.move = Move.new(choice)
  end
end

class Computer < Player
  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def choose
    self.move = Move.new(Move.random_value)
  end
end

class Move
  include Comparable
  attr_reader :value
  VALUES = %w(rock paper scissors)
  def initialize(value)
    @value = value
  end

  def <=>(other_move)
    rules = { 'rock' => { 'rock' => 0, 'paper' => -1, 'scissors' => 1 },
              'paper' => { 'rock' => 1, 'paper' => 0, 'scissors' => -1 },
              'scissors' => { 'rock' => -1, 'paper' => 1, 'scissors' => 0 } }
    rules[value][other_move.value]
  end

  def to_s
    value
  end

  def self.random_value
    VALUES.sample
  end

  def self.allowed_moves
    VALUES.clone
  end
end

class Rule
  def initialize; end
end

def compare(move1, move); end

class RPSGame
  attr_accessor :human, :computer

  def initialize
    @human = Human.new
    @computer = Computer.new
  end

  def display_welcome_message
    puts "Welcome to Rock, Paper, Scissors!"
  end

  def display_goodbye_message
    puts "Thanks for playing Rock, Paper, Scissors. Good bye! "
  end

  def tie?
    human.move == computer.move
  end

  def display_turn
    puts "#{human.name} chose #{human.move}."
    puts "#{computer.name} chose #{computer.move}."
  end

  def display_winner
    if human.move > computer.move
      human.scored
      puts "#{human.name} won!"
    else
      computer.scored
      puts "#{computer.name} won!"
    end
    puts "Human scores: #{human.game_score}, Computer scores: #{computer.game_score}"
  end

  def display_tie
    puts "It's a tie!"
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

  def play
    display_welcome_message
    loop do
      human.choose
      computer.choose
      display_turn
      if tie?
        display_tie
      else
        display_winner
      end
      break unless play_again?
    end
    display_goodbye_message
  end
end

game = RPSGame.new

game.play
