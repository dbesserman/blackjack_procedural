require 'pry'

#-------------------------------------------------------------------------
# => VARIABLES
#-------------------------------------------------------------------------

ranks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 'jack', 'queen', 'king', 'Ace']
colors = ['hearts', 'diamonds', 'spades', 'clubs']

#-------------------------------------------------------------------------
# => FUNCTIONS
#-------------------------------------------------------------------------

### BEGIN THE GAME

def generate_deck(ranks, colors, deck)
  4.times do #lets arbitrarly decide that there will be 4 decks
    ranks.each do |rank|
      colors.each do |color|
        card = {} 
        card[:rank] = rank
        card[:color] = color
        deck.push(card)
      end
    end
  end
  deck.shuffle!
end

def begin_game(table, deck)
  bets(table)
  deal_initial_hand(table, deck)
end
   
def set_table(nb_of_players, table)
  i = 0
  nb_of_players.times do 
    i += 1
    begin
      print "player #{i}, please enter your name: "
      answer = gets.chomp
      if answer == 'dealer'
        puts 'There already is a dealer. Please enter an other name.'
      elsif answer == ''
        puts "You didn't enter a name. Please enter a name."
      else
        table.push({name: "#{answer}", hand: [], chips: 100, bet: 0, final_situation: '', tokens: []})
      end
    end until answer.downcase.chomp != 'dealer' && answer != ''
  end
  table.push({name: 'Dealer', hand: [], chips: 1500, final_situation: '', tokens: []})
end
# :bet and :final_situation will be reset at the end of each round. They are here to make the gain distribution easier.

def nb_of_players()
  begin
    puts "\nthis table allows up to 7 players"      
    print 'how many people will be playing ? '
    nb_of_players = gets.chomp.to_i
  end until (nb_of_players <= 7) && (nb_of_players > 0)  
  nb_of_players
end

def bets(table) 
  table.select {|participant| participant[:name] != 'Dealer'}.each do |player|
    begin
      puts "You have #{player[:chips]} chips #{player[:name]}."
      print "How  much chips would you like to bet ? "
      answer = gets.chomp.to_i 
      if answer >= player[:chips]
        puts "Sorry, you don't have enough chips."
      end
    end until answer <= player[:chips]
  player[:chips] -= answer
  player[:bet] += answer
  end
end

def deal_initial_hand(table, deck) # initial deal
  2.times do
    table.each do |participant|
      participant[:hand].push(deck.pop) 
    end
  end
end

### PLAY

def play(table, deck, dealer_turn)
  table.each do |participant|
    if participant[:name] != 'Dealer'
      player_turn(table, deck, participant, dealer_turn)
    else
      dealer_turn(table, deck, participant, dealer_turn)
    end
  end
end

def player_turn(table, deck, participant, dealer_turn)
  number_of_aces_used = 0
  loop do
    if  total_value(participant) < 21
      print_table(table, dealer_turn)
      puts "Your turn #{participant[:name]}."
      puts "You have bet #{participant[:bet]}."
      print 'hit or stay: '
      answer = gets.chomp.downcase
      if answer == 'hit'
        hit(participant, deck)
      elsif answer == 'stay'
        print_table(table, dealer_turn)
        set_final_situation(participant)
        break
      end
    elsif total_value(participant) == 21
      break
    elsif check_for_aces(participant[:hand])
      optimize_total_value(participant)
    else 
      break # bust
    end
  print_table(table, dealer_turn)
  end 
  set_final_situation(participant)
end

def dealer_turn(table, deck, participant, dealer_turn)
  dealer_turn = true # Reveals the hidden card
  print_table(table, dealer_turn)
  number_of_aces_used = 0
  sleep 1
  loop do
    while total_value(participant) < 17 # the dealer stays if his initial value is between 17 and 21
      sleep 1
      hit(participant, deck)
      if total_value(participant) > 21 && check_for_aces(participant[:hand])
        optimize_total_value(participant)
      end
      print_table(table, dealer_turn)
    end
    break
  end
  set_final_situation(participant)
end

def set_final_situation(participant)
  if total_value(participant) == 21 && participant[:hand].length == 2
    puts "\t=> blackjack"
    participant[:final_situation] = 'blackjack'
  elsif total_value(participant) <= 21
    puts "\t=> total_value: #{total_value(participant)}\n"
    participant[:final_situation] = total_value(participant)
  elsif total_value(participant) > 21
    if participant[:name] != 'Dealer'
      puts "\t=> you busted :("
    else
      puts "\t=> the dealer has busted"
    end
    participant[:final_situation] = 'busted'
  end
  participant[:tokens] = []
end

def hit(participant, deck)
  participant[:hand].push(deck.pop)
end

def check_for_aces(hand)
  hand.any? {|card| card[:rank] == 'Ace'}
end

# bust_with_ace is a method that automatically reduces the total_value of an Ace owner if he busts.
# thus, the game will automatically choose  the Ace value that maximizes his hand value within the 21 constraint.  

def optimize_total_value(participant)
  number_of_aces = participant[:hand].count {|card| card[:rank] == 'Ace'}
  number_of_aces_used = participant[:tokens].count
  loop do
    if number_of_aces_used < number_of_aces && total_value(participant) > 21
      participant[:tokens].push('token')
      number_of_aces_used += 1
    else
      break
    end
  end
end

### PRINT TABLE

def print_table(table, dealer_turn)
  system 'clear'
  big_separator
  table.each do |participant| # a participant can be a player or the dealer
    puts "\n#{participant[:name]}'s hand:"
    if participant[:name] == 'Dealer' && dealer_turn == false
      binding.pry
      puts "\t#{participant[:hand][0][:rank]} of #{participant[:hand][0][:color]}\n"
      puts "\t**** hidden card ****"
      puts "\t>> temporary value: #{card_value(participant[:hand][0])}"
    else
      participant[:hand].each do |card|
        puts "\t#{card[:rank]} of #{card[:color]}\n"    
      end
      if participant[:final_situation] == ''
        puts  "\t=> optimal value: #{total_value(participant)}"
      else
        puts "\t=> final situation: #{participant[:final_situation]}"
      end
    end
    medium_separator()
  end
  big_separator()
end

def card_value(card) 
  case card[:rank]
  when 2, 3, 4, 5, 6, 7, 8, 9
    value = card[:rank]
  when 10, 'jack', 'queen', 'king'
    value = 10
  when 'Ace'
    value = 11
  end
  value
end

def total_value(participant)
  total_value = 0
  participant[:hand].each {|card| total_value += card_value(card)}
  total_value -=  participant[:tokens].length * 10
  total_value # Do I have to add the return value again ?
end

### RESOLUTION

def chip_distribution(table)
  bank = table.last[:chips] 
  table.select {|participant| participant[:name] != 'Dealer'}.each do |player|
    case 
      when player[:final_situation] == 'busted'
        player_lost(table, player)
      when table.last[:final_situation] == 'busted' # table.last is the dealer.  
        player_won(table, player)
      when player[:final_situation] == 'blackjack' && table.last[:final_situation] == 'blackjack'
        push(player)
      when player[:final_situation] == 'blackjack'
        player_won(table, player)
      when table.last[:final_situation] == 'blackjack'
        player_lost(table, player)
      when player[:final_situation] > table.last[:final_situation]
  # From this elsif statement, both the player's and the dealer's final situations can only be integers
        player_won(table, player)
      when player[:final_situation] < table.last[:final_situation]
        player_lost(table, player)
      when player[:final_situation] == table.last[:final_situation]
        push(player)
    end
  end
end

def player_won(table, player)
  if player[:final_situation] == 'blackjack'
    puts "#{player[:name]} won #{player[:bet] * 1.5} chips."
    player[:bet] *= 2.5
  else
    puts "#{player[:name]} won #{player[:bet]} chips."
    player[:bet] *= 2
  end
  player[:chips] += player[:bet]
  table.last[:chips] -= player[:bet] # table.last represents the dealer
  player[:bet] = 0 
end

def player_lost(table, player)
  table.last[:chips] += player[:bet]
  puts "#{player[:name]} lost #{player[:bet]}."
  player[:bet] = 0
end

def push(player)
  puts "It's a push."
  player[:chips] += player[:bet]
  player[:bet] = 0
end

### RESOLUTION

def resolution(table) # Is it possible to do the same thing with only one itteration ?
  table.select {|participant| participant[:name != 'Dealer']}.each do 
    if participant[:chips] <= 0
      puts "#{participant[:name]} left the table." 
    end    
  end
  if table.last[:chips] <= 0
    puts 'The dealer went bankrupt !'
    remove_participants_without_chips(table)
  end
  remove_participants_without_chips(table)
  clean_table(table)
end

def remove_participants_without_chips(table)
  table.keep_if {|participant| participant[:chips] > 0}
end

def clean_table(table)
  table.each do |participant|
    participant[:hand] = []
  end
end

def game_continues?(table)
  if table.count {|participant| participant[:name] == 'Dealer'} == 0
    congratulate_winners(table)
    return false
  elsif table.count {|participant| participant[:name] != 'Dealer'} == 0
    puts "No player left."
    return false
  else
    return true
  end
end

def congratulate_winners(table)
  table.each {|winner| puts "Congratulation #{winner}!"}
end

### SEPARATORS

def small_separator()
  10.times {print '-'}
end

def medium_separator()
  40.times {print '-'}
end

def big_separator()
  2.times do 
    80.times {print '-'}
    puts ''
  end 
end

#-------------------------------------------------------------------------
# => PROGRAM
#-------------------------------------------------------------------------

deck = []
table = []
dealer_turn = false 
# One of the dealer's cards stays hidden utill it's his turn to play (then dealer_turn becomes true)




set_table(nb_of_players(), table)

puts "\nWelcome to the table.\n"

loop do
  dealer_turn = false

  puts 'the game starts.'
  print_table(table, dealer_turn)
  binding.pry

  generate_deck(ranks, colors, deck)
  begin_game(table, deck)
  print_table(table, dealer_turn)
  
  play(table, deck, dealer_turn)
  
  chip_distribution(table)

  resolution(table)

  if !game_continues?(table)
    break
  end
end

# dealing a card: shuffle the deck and pop vs. sample the deck
# when to us '' and when to use "" -i.e. should I use '' each time "" is not necessary- or always use "" 
#   unless I nead '' properties (since '' are converted to "" anyway in the return value)
# print_table takes 2 arguments -table and total_value- total_value is calculated with a method that