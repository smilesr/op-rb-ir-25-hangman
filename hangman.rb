require 'pry'

class SecretWord
  attr_accessor :secretword

  def initialize
    @secretword = select_word
    puts @secretword
  end

  def select_word
    chosen_line = nil
    File.foreach("words.txt").each_with_index do |line, number|
      chosen_line = line if rand < 1.0/(number+1)
    end  
    return chosen_line.downcase.strip!
  end   
end


class Play
  def initialize(secret, display_board)
    @secret = secret.secretword
    @correct_letters_arr = []
    @incorrect_letters_arr = []
    @display = display_board
  end

  def ask_for_letter
    guess = nil
    until (guess =~ /[a-z]/)
      puts "Guess a letter: "
      guess = gets.downcase.chomp
      if guess !~ /[a-z]/
        puts "That is not a letter."
      end
    end
    find_letter(guess)
  end

  def find_letter(guess)
    if @correct_letters_arr.include?(guess) || @incorrect_letters_arr.include?(guess)
      puts "You have already guessed that letter"
      ask_for_letter
    end
    if @secret.include?(guess)
      correct_letters(guess)
    else
      incorrect_letters(guess)
    end
  end

  def incorrect_letters(guess)
    @incorrect_letters_arr << guess
    @display.turns
  end

  def correct_letters(guess)
    @correct_letters_arr << guess
    @display.show_word(guess)
  end
end

class Display
  def initialize (secret)
    @secret = secret.secretword
    @display_word = blank_word
    @turns = 6
  end

  def blank_word
    display_word =''
    for pos in 0..@secret.length - 1
      display_word[pos] = '_'
    end
    display_word
  end

  def show_word(guess)
    for pos in 0..@secret.length - 1
      if @secret[pos] == guess
          @display_word[pos] = guess
      end
    end
    puts @display_word
  end

  def turns
    @turns -= 1
    puts "Wrong."
    puts "You have #{@turns} wrong guesses left"
  end

  def winner_loser
    if @display_word == @secret
      return 1
    elsif  @turns == 0
      return 2
    else
      return 0  
    end
  end
end

secret = SecretWord.new
display_board = Display.new(secret)
play_now = Play.new(secret, display_board)
finished = 0
until finished > 0
  play_now.ask_for_letter
  finished = display_board.winner_loser
  if finished == 1
    puts "YOU WIN!"
  elsif finished == 2
    puts "YOU LOSE."
  end
end

