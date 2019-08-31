require 'yaml'
require 'erb'
require_relative 'game_crafter'
require_relative 't_o_player'
require_relative 'deck'

# Allow to retreive inputs from the user
# using messages stored in .yml file.
# To mix this in and use it's #retrieve method implement:
# #handle_option_message, #validator #handle_option_error.
# To use ERB template in .yml file
# provide suitable binding in #local_binding
module Retrievable
  attr_accessor :options, :current_option_key

  def self.included(klass)
    to_inlcude = constants.lazy
                          .map { |constant| const_get(constant) }
                          .select do |constant|
                            constant.instance_of?(Module)
                          end
    to_inlcude.to_a.each { |nested_module| klass.include nested_module }
  end

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

  module HandleOptions
    attr_accessor :retrieved_options
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

    # set @current_option_key @local_binding. #option_key is used to
    # retrieve from .yml file, #local_binding is used for
    # the evaluation of ERB templates
    def set_option_binding(option_key, template_binding)
      self.current_option_key = option_key
      self.local_binding = template_binding
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
  end

  # provides #validator
  module BakedRgx
    RGX = { no_empty: /\S/, # succeed only if not empty string given
            y_n: /\A[yn]\Z/i, # succeed if y or n given, case insensitive
            any: /.*/, # succeed for any character from 0 to many
            character: /\A.\Z/, # succeed only if any one character
            one_digit: /\A\d\Z/,
            "3_5_7": /\A[357]\Z/,
            "2_to_9": /\A[2-9]\Z/,
            h_s: /\A[hs]\Z/i } # succeed if h or s given, case insensitive

    def self.all
      RGX.dup
    end

    def self.add(new_baked)
      all.merge! new_baked
    end

    def self.[](rgx_key)
      all[rgx_key]
    end

    def validator
      BakedRgx[options[current_option_key]]
    end
  end
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

    def print_margin(message, margin = MARGIN, tail = "\n")
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

    def clear
      system('clear') || system('cls')
    end
  end
end

class Card
  SUITS = ["Spade", "Hearts", "Clubs", "Diamonds"]
  RANKS = [2, 3, 4, 5, 6, 7, 8, 9, 10, "Jack", "Queen", "King", "Ace"]
  UTF_SUITS = ["\u2660", "\u2665", "\u2663", "\u2666"]

  attr_accessor :suit, :rank, :utf_suit, :hidden

  def initialize(suit, rank)
    @suit = suit
    @rank = rank
    @utf_suit = UTF_SUITS[SUITS.index(suit)]
    @hidden = false
  end

  def value
    case rank
    when Integer then rank
    when "Ace" then 11
    else 10
    end
  end

  def to_s
    return " |#{rank} #{utf_suit}| " unless hidden
    " |? ?| "
  end
end

# Kind of intrface or abstract class has to be implemented to
# access the game logic (the Board)
class Ruler
  def ruler_error(methode_name)
    raise NotImplementedError,
          "This #{self.class} cannot respond to: " + methode_name
  end

  def draw
    ruler_error(__method__.to_s)
  end

  def exhausted?
    ruler_error(__method__.to_s)
  end

  def caused_winn?
    ruler_error(__method__.to_s)
  end

  def update_for_choice
    ruler_error(__method__.to_s)
  end

  def availables
    ruler_error(__method__.to_s)
  end

  def suggest
    ruler_error(__method__.to_s)
  end
end

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

class Deck
  include Printer
  attr_accessor :cards

  def initialize
    reset
    shuffule_deck!
  end

  def reset
    @cards = []
    Card::SUITS.each do |suit|
      Card::RANKS.each do |rank|
        @cards << Card.new(suit, rank)
      end
    end
  end

  def take_one
    cards.pop
  end

  private

  def shuffule_deck!
    cards.shuffle!
  end
end

class ToDeckRuler < Deck
  def initialize(players)
    super()
    @players = players
    deal
  end

  def availables
    cards
  end

  def update_for_choice(player)
    take_one if player.hit?
  end

  def draw
    @players.each do |player|
      player.reset_hidden if some_one_busted?
      puts
      print_margin "#{player.name}'s cards ( #{player.pronoun} )"
      player.cards.each do |card|
        sleep(0.5)
        print_margin(card.to_s, Printer::MARGIN, '')
      end
      print_margin("( #{player.score_message} )", Printer::MARGIN, '')
      puts
    end
  end

  def player_busted?(player)
    player.busted?
  end

  def player_score(player)
    player.score_value
  end

  def caused_winn?(player)
    return false unless player.last?

    return false if player_busted?(player)

    players_but_current = @players.reject do |other|
      other.equal?(player)
    end

    players_but_current.all? do |other|
      player_score(player) > player_score(other)
    end
  end

  def exhausted?(player)
    return true if some_one_busted? || player.last?
    false
  end

  def some_one_busted?
    @players.any?(&:busted?)
  end

  def winner
    return @players.reject(&:busted?).first if some_one_busted?
    max_score = @players.first.score_value
    round_winner = @players.first
    @players.each do |player|
      round_winner = player if player.score_value > max_score
    end
    round_winner
  end

  def tie?
    first_score = player_score(@players.first)
    @players.all? { |player| player_score(player) == first_score }
  end

  def deal
    @players.each do |player|
      deal_one_hidden(player) unless player.user_player?
      deal_one(player) if player.user_player?

      deal_one(player)
    end
  end

  private

  def deal_one(player)
    player.add_to_hand(take_one)
  end

  def deal_one_hidden(player)
    distributed = take_one
    distributed.hidden = true
    player.add_to_hand(distributed)
  end
end

class TwentyOnePlayer
  include Retrievable

  BUSTED_THRESHOLD = 21

  attr_reader :cards, :score
  attr_accessor :name

  def initialize(args = {})
    reset_cards
    @score = 0
    @messages_file = 'to_templates.yml'
    load_yaml_file
    self.options = { stay: :h_s }
    @name = args[:name] || default_name
  end

  def move(game_crafter)
    display_template_bind("player_turn")
    reset_hidden
    game_crafter.display_game_field
    loop do
      break if busted?

      @picked_card = nil
      break if stay?

      @picked_card = hit(game_crafter.available_choices)
      add_choice
      game_crafter.accomodate_choice(self)
      display_cards_delay
    end
    clear_before_stay unless busted?
    display_template_bind("player_stayed_busted")
  end

  def add_to_hand(card)
    cards << card
  end

  def scored
    @score += 1
  end

  def hit?
    !!picked_card
  end

  def busted?
    score_value > BUSTED_THRESHOLD
  end

  def score_value
    value_sum = @cards.inject(0) do |sum, card|
      sum + card.value
    end
    aces = cards.count { |card| card.rank == "Ace" }
    aces.times do |_|
      value_sum -= 10 if value_sum > BUSTED_THRESHOLD
    end
    value_sum
  end

  def score_message
    return "?" if cards.any?(&:hidden)

    score_value.to_s
  end

  def reset_hidden
    cards.each { |card| card.hidden = false if card.hidden }
  end

  def need_display?
    false
  end

  def display_cards_delay
    puts
    print_margin "#{name} hit and received #{@picked_card}"
    print_margin("#{name}'s cards:", Printer::MARGIN, "")
    cards.map(&:to_s).each do |card|
      sleep(0.5)
      print_margin(card, Printer::MARGIN, "")
    end
    print_margin "( #{score_value} )"
  end

  def template_binding
    binding
  end

  def reset_cards
    @cards = []
  end

  def reset_score_cards
    reset_cards
    @score = 0
  end

  def won_message
    "#{name} won!"
  end

  def display_info_game_field; end

  private

  attr_reader :picked_card
  attr_accessor :local_binding # :current_option_key,

  def hit(deck)
    deck.last
  end

  def add_choice
    @cards << @picked_card unless picked_card.nil?
  end

  def default_name
    ''
  end

  def clear_before_stay; end
end

class Dealer < TwentyOnePlayer
  STAY_THRESHOLD = 16

  def last?
    true
  end

  def user_player?
    false
  end

  def pronoun
    "Dealer"
  end

  def determiner
    "Dealer's"
  end

  private

  def stay?
    score_value > STAY_THRESHOLD
  end

  def default_names
    %w(HAL TARDIS HER Minsky R2D2 GERTY)
  end

  def default_name
    default_names.sample
  end
end

class Gambler < TwentyOnePlayer
  def pronoun
    "You"
  end

  def user_player?
    true
  end

  def last?
    false
  end

  def determiner
    "Your"
  end

  private

  def stay?
    set_retrieve_option(:stay).downcase == 's'
  end

  def clear_before_stay
    clear
  end

  def default_names
    %w(Betty Pebbles Bamm Fred Wilma Barney)
  end

  def default_name
    default_names.sample
  end
end

# Subclassed in order to bridge the child class with the ruler.
class GameCrafter
  attr_reader :ruler

  def initialize(ruler)
    @ruler = ruler
  end

  def display_game_field
    ruler.draw
  end

  def available_choices
    ruler.availables
  end

  def strategy_choice(player)
    minded_choice || ruler.suggest(player)
  end

  def minded_choice
    nil
  end

  def accomodate_choice(player)
    ruler.update_for_choice(player)
  end

  def player_won?(player)
    ruler.caused_winn?(player)
  end

  def exhausted?(player)
    ruler.exhausted?(player)
  end
end

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
