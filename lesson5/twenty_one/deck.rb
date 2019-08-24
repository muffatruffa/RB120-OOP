require_relative 'card'
require_relative 'ruler'
require_relative 'printer'

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
    # start_tracking_players(players)
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
      puts
      print_margin player.class.to_s
      player.cards.each { |card| print_margin(card.to_s, Printer::MARGIN, '') }
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
