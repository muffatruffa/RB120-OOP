# question5

# You are given the following class that has been implemented:

class KrispyKreme
  def initialize(filling_type, glazing)
    @filling_type = filling_type
    @glazing = glazing
  end

  def plain?
    @filling_type.nil?
  end

  def no_glaze?
    @glazing.nil?
  end

  def to_s
    str = case [plain?, no_glaze?]
          when [true, true] then "Plain"
          when [true, false] then "Plain with #{@glazing}"
          when [false, true] then @filling_type
          when [false, false] then "#{@filling_type} with #{@glazing}"
          end
  end
end

donut1 = KrispyKreme.new(nil, nil)
donut2 = KrispyKreme.new("Vanilla", nil)
donut3 = KrispyKreme.new(nil, "sugar")
donut4 = KrispyKreme.new(nil, "chocolate sprinkles")
donut5 = KrispyKreme.new("Custard", "icing")

puts donut1
puts donut2
puts donut3
puts donut4
puts donut5

