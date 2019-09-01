# Using the code from the previous exercise, add a getter method named #name and invoke it in place of @name in #greet
# Using the code from the previous exercise, add a setter method named #name. Then, rename kitty to 'Luna' and invoke #greet again.

class Cat
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def greet
    puts "Hello! My name is #{name}!"
  end
end

kitty = Cat.new('Sophie')
kitty.greet # => nil
kitty.name = 'Luna'
kitty.greet # => nil

# >> Hello! My name is Sophie!
# >> Hello! My name is Luna!

