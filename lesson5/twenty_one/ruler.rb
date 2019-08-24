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
