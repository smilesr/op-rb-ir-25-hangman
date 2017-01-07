require 'json'

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
  def initialize(secret, display_board, x)
    @secret = secret
    @correct_letters_arr = []
    @incorrect_letters_arr = []
    @display = display_board
    @x = x
    @play = self
  end

  def ask_for_letter
    guess = nil
    until (guess =~ /[a-z]/)
      puts "Guess a letter or type 'save' to save game: "
      guess = gets.downcase.chomp
      if guess == 'save'
        @x.save_game @secret, @display, @play
      end
      if guess !~ /[a-z]/
        puts "That is not a letter."
      end
    end
    display_word = find_letter(guess)
    display_word
  end

  def find_letter(guess)
    if @correct_letters_arr.include?(guess) || @incorrect_letters_arr.include?(guess)
      puts "You have already guessed that letter"
      ask_for_letter
    end
    if @secret.secretword.include?(guess)
      correct_letters(guess)
    else
      incorrect_letters(guess)
    end
  end

  def incorrect_letters(guess)
    @incorrect_letters_arr << guess
    @display.turns(@incorrect_letters_arr)
  end

  def correct_letters(guess)
    @correct_letters_arr << guess
    display_word = @display.show_word(guess)
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
    @display_word
  end

  def turns(arr)
    @turns -= 1
    puts "Wrong."
    print "Wrong guesses: "
    arr.each{|letter| print "#{letter} "}
    puts
    puts "You have #{@turns} wrong guesses left"
  end

  def winner_loser(display_word)
    # display_word parameter used here rather than @display_word to address bug in which recovered saved-game fails to update @display_word
    puts @display_word
    puts display_word
    if display_word == @secret
      return 1
    elsif  @turns == 0
      return 2
    else
      return 0  
    end
  end
end

class SaveGame
  def save_game secret, display, play
    file_arr=[["savedgame_secret.txt", secret],["savedgame_display.txt",display],["savedgame_play.txt",play]]
    file_arr.each do |item|
      File.open(item[0],"w+") do |f|
        f.write(Marshal.dump(item[1]))
        f.close
      end
    end
    exit
  end
end

puts "Type 'new' or 'saved':"
answer = gets.downcase.chomp

if answer == 'new'
  secret = SecretWord.new
  display_board = Display.new(secret)
  x = SaveGame.new
  play_now = Play.new(secret, display_board, x)
else
  file = File.open("savedgame_secret.txt", "r")
  secret = Marshal.load(file.read)
  file.close
  file = File.open("savedgame_display.txt", "r")
  display_board = Marshal.load(file.read)
  file.close
  file = File.open("savedgame_play.txt", "r")
  play_now = Marshal.load(file.read)
  file.close
end

finished = 0
until finished > 0
  display_word = play_now.ask_for_letter 
  finished = display_board.winner_loser(display_word)
  if finished == 1
    puts "YOU WIN!"
  elsif finished == 2
    puts "YOU LOSE."
  end
end

