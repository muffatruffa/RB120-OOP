# Can draw other objects at the moment very close to board:
# the caller has to mix in Enumerable and respond to size
class Drawer
  attr_reader :margin_width, :column_width, :margin, :padding

  def initialize
    set_layout_sizes
    set_layout_components
  end

  def set_layout_sizes
    @margin_width = 5
    @column_width = 5
  end

  def set_layout_components
    @margin = ' ' * margin_width
    @padding = ' ' * (column_width / 2)
  end

  def draw_board(drawable, numbers_of_columns)
    last_row = drawable.drop(drawable.size - numbers_of_columns)
    all_rows_but_last = drawable.take(drawable.size - numbers_of_columns)

    all_rows_but_last.each_slice(numbers_of_columns) do |row|
      print_board_row(row)
      print_row_separator(row)
    end
    print_board_row(last_row)
  end

  private

  def print_board_row(row)
    print before_after_data(row) + "\n" + margin

    row.each_with_index do |column_data, index|
      row_ending = '|'
      row_ending = "\n" if index == row.size - 1
      line = { padding1: padding, column_data: column_data,
               padding2: padding, row_ending: row_ending }
      print format("%<padding1>s%<column_data>s%<padding2>s%<row_ending>s",
                   line)
    end

    print before_after_data(row) + "\n"
  end

  def print_row_separator(row)
    print margin + format("%<line>s+",
                          line: '-' * column_width) * (row.size - 1)
    print '-' * column_width + "\n"
  end

  def before_after_data(row)
    margin + format("%<spaces>s|",
                    spaces: ' ' * column_width) * (row.size - 1)
  end
end
