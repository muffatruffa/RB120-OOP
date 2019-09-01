# Create an empty class named Cat.
# add a parameter to #initialize that provides a name for the Cat object. Use an instance variable to print a greeting with the provided name.

class Cat
  def initialize(name)
    @name = name
    greet
  end

  def greet
    print "Hello! My name is @name!"
  end
end

# Using the code from the previous exercise, create an instance of Cat and assign it to a variable named kitty.

kitty = Cat.new('Sophie') # => #<Cat:0x0000556cf4eeff50 @name="Sophie">

# >> Hello! My name is @name!
