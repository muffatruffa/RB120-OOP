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
