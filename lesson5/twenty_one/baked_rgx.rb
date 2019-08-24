module BakedRgx
  attr_accessor :options, :current_option_key

  RGX = { no_empty: /\S/, # succeed only if not empty string given
          y_n: /\A[yn]\Z/i, # succeed if y or n given, case insensitive
          any: /.*/, # succeed for any character from 0 to many
          character: /\A.\Z/, # succeed only if any one character
          one_digit: /\A\d\Z/,
          "3_5_7": /\A[357]\Z/,
          "2_to_9": /\A[2-9]\Z/,
          h_s: /\A[hs]\Z/i } # succeed if h or s given, case insensitive

  def self.all
    RGX.dup
  end

  def self.add(new_baked)
    all.merge! new_baked
  end

  def self.[](rgx_key)
    all[rgx_key]
  end

  def validator
    BakedRgx[options[current_option_key]]
  end
end
