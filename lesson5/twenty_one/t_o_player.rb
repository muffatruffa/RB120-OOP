require_relative 'retrievable'

class TwentyOnePlayer
  include Retrievable

  BUSTED_THRESHOLD = 21

  attr_reader :cards

  def initialize
    @cards = []
    @score = 0
    @messages_file = 'to_templates.yml'
    load_yaml_file
    self.options = { stay: :h_s }
  end

  def move(game_crafter)
    loop do
      break if busted?

      reset_hidden
      game_crafter.display_game_field
      @picked_card = nil
      break if stay?

      @picked_card = hit(game_crafter.available_choices)
      add_choice
      game_crafter.accomodate_choice(self)
    end
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

  def display_info_game_field
    display_template_bind("t_o_player_hit")
  end

  private

  attr_reader :picked_card
  attr_accessor :local_binding # :current_option_key,

  def hit(deck)
    deck.last
  end

  def reset_hidden
    cards.each { |card| card.hidden = false if card.hidden }
  end

  def add_choice
    @cards << @picked_card unless picked_card.nil?
  end

  def won_message
    "who won?"
  end
end

class Dealer < TwentyOnePlayer
  STAY_THRESHOLD = 16
  def last?
    true
  end

  def need_display?
    false
  end

  def user_player?
    false
  end

  private

  def stay?
    score_value > STAY_THRESHOLD
  end
end

class Gambler < TwentyOnePlayer
  def user_player?
    true
  end

  def last?
    false
  end

  def need_display?
    false
  end

  private

  def stay?
    set_retrieve_option(:stay).downcase == 's'
  end
end
