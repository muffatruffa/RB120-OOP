require_relative 'drawer'
require_relative 'square'

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

# Inherited by the Board logic in order to comunicate with the GameRoundCrafter.
class BoardRuler < Ruler
  attr_reader :drawer

  def initialize(args = {})
    @drawer = args.fetch(:drawer, Drawer.new)
  end

  def draw
    drawer.draw_board(self, number_of_rows_columns)
  end

  def exhausted?
    unmarked_squares_number.empty?
  end

  def caused_winn?(player)
    winning_combinations.each do |combination|
      squares = combination.map { |square| square_number(square) }
      return true if squares.include?(player.choice) &&
                     all_same_marker?(combination)
    end
    false
  end

  def update_for_choice(player)
    self[player.choice] = player.marker
  end

  def availables
    unmarked_squares_number
  end

  def suggest(player)
    winning_move(player.marker) ||
      defensive_move(player.marker) ||
      corner_center_or_any_move
  end
end
