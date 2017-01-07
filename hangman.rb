require 'json'
require 'fileutils'
require 'pry'
require 'pry-byebug'
$dir = 'saved_games'

class SecretWord
  attr_reader :secretword
  def initialize
    @secretword = select_word
    puts @secretword
    # binding.pry
  end

  def select_word
    chosen_line = nil
    File.foreach("words.txt").each_with_index do |line, number|
      chosen_line = line if rand < 1.0/(number+1)
    end  
    return chosen_line.downcase.strip!
  end   
end
#*****************************************************
class Play
  #1
  def initialize(secret, display_board, x)
    @secret = secret #instance of Secret
    @correct_letters_arr = []
    @incorrect_letters_arr = []
    @display = display_board #instance of Display
    @x = x
    @play = self #instance of Play
  end
  #2
  def ask_for_letter
    guess = nil
    until (guess =~ /[a-z]/ && guess.length == 1)
      puts "Guess a letter or type 'save' to save game: "
      guess = gets.downcase.chomp
      if guess == 'save'
        @x.save_game @secret, @display, @play
      end
      if guess !~ /[a-z]/
        puts "That is not a letter."
      end
      if guess.length > 1
        puts "Only type one letter."
      end
    end
    display_word = find_letter(guess)
    display_word
  end
  #3
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
  #4
  def incorrect_letters(guess)
    @incorrect_letters_arr << guess
    @display.turns(@incorrect_letters_arr)
  end
  #5
  def correct_letters(guess)
    @correct_letters_arr << guess
    display_word = @display.show_word(guess)
  end
end
# *******************************************************
class Display
  #1
  def initialize (secret)
    @secret = secret.secretword #instance of Secret
    @display_word = blank_word
    @turns = 6
  end
  #2
  def blank_word
    display_word =''
    for pos in 0..@secret.length - 1
      display_word[pos] = '_'
    end
    display_word
  end
  #3
  def show_word(guess)
    for pos in 0..@secret.length - 1
      if @secret[pos] == guess
          @display_word[pos] = guess
      end
    end
    puts @display_word
    @display_word
  end
  #4
  def turns(arr)
    @turns -= 1
    puts "Wrong."
    puts @display_word
    print "Wrong guesses: "
    arr.each{|letter| print "#{letter} "}
    puts
    puts "You have #{@turns} wrong guesses left."
    @turns
  end
  #5
  def winner_loser(display_word)
    # display_word parameter used here rather than @display_word to address bug in which recovered saved-game fails to update @display_word
    if display_word == @secret
      return 1
    elsif  @turns == 0
      return 2
    else
      return 0  
    end
  end
end
#*********************************************************
class SaveGame
  def save_game secret, display, play
    puts "name your saved game:"
    name = gets.downcase.chomp

    file_arr=[["#{name}_secret.txt", secret],["#{name}_display.txt",display],["#{name}_play.txt",play]]
    unless File.directory?($dir)
      FileUtils::mkdir_p $dir
    end
    Dir.chdir($dir) do
      file_arr.each do |item|
        File.open(item[0],"w+") do |f|
          f.write(Marshal.dump(item[1]))
          f.close
        end
      end
    end
    exit
  end
end

puts "Do you want to start a new game or continue a saved game?"
puts "Type 'new' or 'saved':"
answer = gets.downcase.chomp

if answer == 'new'
  secret = SecretWord.new
  display_board = Display.new(secret)
  x = SaveGame.new
  play_now = Play.new(secret, display_board, x)
else
  Dir.chdir($dir) do
    puts "which game do you want to recover from this list?"
    (Dir["*_secret.txt"]).each{|item| puts item.scan(/^[a-z1-9]+/)}
    filename = gets.downcase.chomp
    file = File.open("#{filename}_secret.txt", "r")
    secret = Marshal.load(file.read)
    file.close
    file = File.open("#{filename}_display.txt", "r")
    display_board = Marshal.load(file.read)
    file.close
    file = File.open("#{filename}_play.txt", "r")
    play_now = Marshal.load(file.read)
    file.close
    FileUtils.rm (["#{filename}_secret.txt", "#{filename}_display.txt", "#{filename}_play.txt"])
  end
end

finished = 0

until finished > 0
  puts "entered loop"
  display_word = play_now.ask_for_letter 
  finished = display_board.winner_loser(display_word)
  if finished == 1
    puts "YOU WIN!"
  elsif finished == 2
    puts "YOU LOSE."
  end
end

