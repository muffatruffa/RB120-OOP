require_relative 'drawer'
require_relative 'square'

# Allows access to a double array as a single array using a Tile jargon
# To mix this in you have to implement #two_d_array
# and #set_tile_value(tile,value)
module Tileable
  include Enumerable

  def size
    number_of_tiles
  end

  def []=(tile_number, value)
    return unless valid_square?(tile_number)

    set_tile_value(two_d_array[row(tile_number)][column(tile_number)], value)
  end

  private

  def number_of_tiles
    number_of_rows_columns * number_of_rows_columns
  end

  def each
    (1..size).each { |tile_number| yield self[tile_number] }
  end

  def [](tile_number)
    return nil unless valid_square?(tile_number)

    two_d_array[row(tile_number)][column(tile_number)]
  end

  def tile_number(target_object)
    square_index = find_index { |square| square.equal? target_object }
    square_index + 1 if square_index
  end

  def column(tile_number)
    (tile_number - 1) % number_of_rows_columns
  end

  def row(tile_number)
    (tile_number - column(tile_number) - 1) / number_of_rows_columns
  end

  def flatten_index(row, column)
    row * number_of_rows_columns + column
  end

  def row_column_to_square_number(row, column)
    flatten_index(row, column) + 1
  end

  def valid_square?(tile_number)
    tile_number > 0 && tile_number <= size
  end

  def rows
    two_d_array.clone
  end

  def columns
    two_d_array.transpose
  end

  def main_diagonal
    diagonal = [[]]
    0.upto(number_of_rows_columns - 1) do |row_number|
      column_number = row_number
      diagonal[0] << two_d_array[row_number][column_number]
    end
    diagonal
  end

  def secondary_diagonal
    diagonal = [[]]
    0.upto(number_of_rows_columns - 1) do |row_number|
      column_number = number_of_rows_columns - 1 - row_number
      diagonal[0] << two_d_array[row_number][column_number]
    end
    diagonal
  end

  def all_same?(tiles)
    tiles.all? { |tile| tile == tiles.first }
  end
end

class Board
  include Tileable

  attr_reader :drawer
  attr_accessor :number_of_rows_columns

  def initialize(rows_columns = 3)
    @drawer = Drawer.new
    reset(rows_columns)
  end

  def draw
    drawer.draw_board(self, number_of_rows_columns)
  end

  def reset(rows_columns = number_of_rows_columns)
    @number_of_rows_columns = rows_columns
    @squares = Array.new(number_of_rows_columns) do |_|
      Array.new(number_of_rows_columns) { Square.new }
    end
  end

  def unmarked_squares_number
    unmarked = []
    each_with_index do |square_object, square_index|
      unmarked << square_index + 1 if square_object.unmarked?
    end
    unmarked
  end

  def player_won?(player)
    winning_combinations.each do |combination|
      squares = combination.map { |square| square_number(square) }
      return true if squares.include?(player.choice) &&
                     all_same_marker?(combination)
    end
    false
  end

  def suggest(player)
    winning_move(player.marker) ||
      defensive_move(player.marker) ||
      corner_center_or_any_move
  end

  private

  def two_d_array
    @squares
  end

  def set_tile_value(tile, value)
    tile.marker = value
  end

  def square_number(square)
    tile_number(square)
  end

  def all_same_marker?(squares_to_compare)
    all_same?(squares_to_compare)
  end

  def select_marked(target_marker)
    marked = []
    each_with_index do |square_object, square_index|
      marked << square_index + 1 if square_object.marker == target_marker
    end
    marked
  end

  def winning_move(target_marker)
    winning_combinations.each do |combination|
      if winning_line?(target_marker, combination)
        empty = combination.find(&:unmarked?)
        return square_number(empty)
      end
    end
    nil
  end

  def defensive_move(target_marker)
    winning_combinations.each do |combination|
      if threat_line?(target_marker, combination)
        empty = combination.find(&:unmarked?)
        return square_number(empty)
      end
    end
    nil
  end

  def corner_center_or_any_move
    target = corners_squares_number + [center_square_number]
    target &= unmarked_squares_number
    if target.include?(center_square_number)
      center_square_number
    elsif !target.empty?
      target.sample
    else
      unmarked_squares_number.sample
    end
  end

  def winning_combinations
    rows + columns + main_diagonal + secondary_diagonal
  end

  def winning_line?(target_marker, combination)
    marked = combination.count { |square| target_marker == square.marker }
    unmarked = combination.count(&:unmarked?)
    marked == (combination.size - 1) &&
      unmarked == 1
  end

  def threat_line?(target_marker, combination)
    empty_count = combination.count(&:unmarked?)
    marked = combination.select(&:marked?)
    empty_count == 1 &&
      all_same_marker?(marked) &&
      target_marker != marked.first.marker
  end

  def center_square_number
    row = column = number_of_rows_columns / 2
    row_column_to_square_number(row, column)
  end

  def corners_squares_number
    [1,
     number_of_rows_columns,
     size - number_of_rows_columns + 1,
     size]
  end
end
