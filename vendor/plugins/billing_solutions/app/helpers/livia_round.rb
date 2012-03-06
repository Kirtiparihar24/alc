module LiviaRound

  # Rounding float number to two number after decimal point ie. 9.985 => 9.99
  # Beena S Shetty 28-11-2011
  def livia_round(number)
    num, dec = number.to_s.split(".")
    return (num+".00").to_f unless dec

    decimals = dec.split("")[0,3]
    return number if decimals.count < 3

    if decimals[2].to_i >= 5
      dec = (decimals[0] + decimals[1]).to_i + 1
      if dec == 100
        num = num.to_i + 1
        dec = "00"
      end
    else
      dec = decimals[0] + decimals[1]
    end
    (num.to_s + "." + dec.to_s).to_f.fixed_precision(2).to_f
  end
  
end