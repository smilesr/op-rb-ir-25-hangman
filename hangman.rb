require 'json'
require 'fileutils'
require 'pry'
require 'pry-byebug'
$dir = 'saved_games'

class SecretWord
  attr_reader :secretword
  def initialize
    @secretword = select_word
    puts "Length of secretword is #{@secretword.length} letters."
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
  
  def initialize(secret, display_board, x)
    @secret = secret #instance of Secret
    @correct_letters_arr = []
    @incorrect_letters_arr = []
    @display = display_board #instance of Display
    @turn = 6
    @x = x
    @play = self #instance of Play
    @display_word = ''
  end
  
  def ask_for_letter
    guess = nil
    until (guess =~ /[a-z]/ && guess.length == 1 && fresh_letter?(guess))
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
      if fresh_letter?(guess) == false
        puts "You have already guessed that letter"
      end
    end
 
    @display_word = use_letter(guess)
    return @turn, @display_word

  end
  
  def fresh_letter?(guess)
    !@correct_letters_arr.include?(guess) && !@incorrect_letters_arr.include?(guess)
  end
  
  def use_letter(guess)
    if @secret.secretword.include?(guess)
      @correct_letters_arr << guess
    else
      @incorrect_letters_arr << guess
      decrement_turn
      guess = nil
    end
    @display.show_word(guess, @display_word)
  end

  def decrement_turn
    @turn -= 1
    @display.show_turns(@incorrect_letters_arr, @turn)
  end
end
# *******************************************************
class Display

  def initialize (secret)
    @secret = secret.secretword #instance of Secret
  end

  def show_word(guess, display_word)
    for pos in 0..@secret.length - 1
      if @secret[pos] == guess
          display_word[pos] = guess
      elsif display_word[pos] =~ /[a-z]/
          display_word[pos] = display_word[pos]
      else
          display_word[pos] = '_'
      end
    end
    puts display_word 
    display_word
  end

  def show_turns(arr, turn)
    puts "Wrong."
    print "Wrong guesses: "
    arr.each{|letter| print "#{letter} "}
    puts
    puts "You have #{turn} wrong guesses left."
  end
  
  def winner_loser(arr)
    display_word = arr[1]
    turn = arr[0]
    if display_word == @secret
      xxx = 1
    elsif  turn == 0
      xxx = 2
    else
      xxx = 0  
    end
    return xxx
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
  arr = play_now.ask_for_letter 
  finished = display_board.winner_loser(arr)

  if finished == 1
    puts "YOU WIN!"
  elsif finished == 2
    puts "YOU LOSE."
  end
end

