require_relative 'retrievable'

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
