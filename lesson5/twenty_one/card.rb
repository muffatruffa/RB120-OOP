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
