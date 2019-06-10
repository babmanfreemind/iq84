PLAYER_NAMES = ['John', 'Bob', 'Alice', 'Aria', 'Sabine', 'Paul', 'Marie', 'Koby']

require 'pp'
require './matchers.rb'
require './winners.rb'
require './space_invaders.rb'
require './logger.rb'

class GameError < StandardError
end
class DeckError < StandardError
end

class Pot
	attr_reader :money
	attr_reader :status
	attr_reader :raises
	def initialize
		@raises = 0
		@money = 0
		@status = 'INGAME'
	end

	def change_status new_status
		@status = new_status
	end

	def raised
		@raises += 1
	end

	def withdraw
		all = @money
		@money = 0
		return all
	end

	def put money
		@money += money
	end
end

class Table
	attr_reader :players
	def initialize(player_nbr, logger)
		raise StandardError, "Too much players" if player_nbr > 8
		raise StandardError, "Not enough players" if player_nbr < 2
		# @logs = File.open("logs", "w")
		@p = []
		@round = 0
		@blind = 10
		@logger = logger
		i = 0
		while i < player_nbr do
			@p.push(Player.new(PLAYER_NAMES[i]))
			i += 1
		end
		@players = Hash[@p.map{|x| [x.name, x]}]
		@turns = {}
		last = @p.first.name
		@p.reverse.each do |y|
			@turns[y.name] = last
			last = y.name
		end
		@button = @p.first.name
		@talking_player = @p.first.name
		clean_table
	end

	def put_card
		@cards.push(@deck.take_one)
	end

	def blinds
		# draw
		payed = @players[@talking_player].pay_lblind(@blind)
		@pot[@talking_player].put(payed[0])
		@pot[@talking_player].change_status(payed[1])
		@highest_bet = payed[0] unless payed[0] < @highest_bet
		# draw
		next_player

		payed = @players[@talking_player].pay_bblind(@blind * 2)
		@pot[@talking_player].put(payed[0])
		@pot[@talking_player].change_status(payed[1])
		@highest_bet = payed[0] unless payed[0] < @highest_bet
		# draw
		next_player
	end

	def next_player
		@talking_player = @turns[@talking_player]
		status = @pot[@talking_player].status
		if status == "FOLD" || status == 'TAPPED OUT'
			next_player
		end
	end

	def can_continue?
		folded_players = 0
		paid_players = 0
		tapped_out_players = 0
		money_to_go_next = @pot.map{|_name, p| p.money}.max
		players_number = @pot.count
		@pot.each do |k, v|
			status = v.status
			tapped_out_players += 1 if status == 'TAPPED OUT'
			paid_players += 1 if status == 'PAID' && v.money == money_to_go_next
			folded_players += 1 if status == 'FOLD'
		end
		return false if folded_players == players_number - 1
		return false if tapped_out_players + folded_players == players_number
		return false if folded_players + tapped_out_players + paid_players == players_number
		return true
	end

	def equalize
		move = 0
		while can_continue? do
			payed = @players[@talking_player].play(@pot, @highest_bet, @blind)
			payed[2] = divide(payed[0], @blind * 2)
			# @logger.log_signature(@talking_player, @players[@talking_player].cards, @pot, @cards, payed)
			@pot[@talking_player].put(payed[0])
			# p "highest_bet is #{@highest_bet}"
			# p "#{@talking_player} #{payed[1]} and put #{payed[0]}"
			@pot[@talking_player].change_status(payed[1])
			@pot[@talking_player].raised if payed[1] == 'RAISED'
			# pp @pot
			# p '____________________________________________________________________'
			@highest_bet = @pot[@talking_player].money unless @pot[@talking_player].money < @highest_bet
			# draw
			move += 1
			next_player if can_continue?
		end
	end

	def reset_pot
		@pot.each do |name, pot|
			if pot.status == 'TAPPED OUT' && @intermediary_pot[name].money == 0
				max_win = 0
				@pot.each do |_name, potception|
					if potception.money > pot.money
						max_win += pot.money
					else
						max_win += potception.money
					end
				end
				@intermediary_pot[name].put(max_win)
			end
			if pot.status == 'PAID'
				pot.change_status('INGAME')
			end
		end
		withdraw_pot
	end

	def withdraw_pot
		@pot.each do |name, pot|
			m = pot.withdraw
			@global_pot += m
		end
	end

	def play_round
		@highest_bet = 0
		@talking_player = @button
		return unless can_continue?
		next_player if @pot[@talking_player].status == 'FOLD' || @pot[@talking_player].status == 'TAPPED OUT'
		equalize
	end

	def reduce_winners
		score = nil
		all_gud = true
		@players.each do |playa_name, playa|
			if @winners.include?(playa_name)
				if score == nil
					score = playa.points
				elsif playa.points != score
					all_gud = false
				end
			end
		end
		raise GameError.new("Reduce winners : winners dont have same score") unless all_gud
		if score < 40
			ultimate_winners = REDUCERS[0].call(@winners, @players, @cards)
		else
			ultimate_winners = REDUCERS[(score / 20) - 1].call(@winners, @players, @cards)
		end
		@winners = ultimate_winners
	end

	def divide a,b
		a / b
	end

	# need tests
	def share_money
		old_pot = @global_pot
		# WINNERS COUNT CAN BE ZERO ! WTF ?
		share = divide(@global_pot, @winners.count)
		if @winners.count == 1
			@players[@winners.first].receive_money(@global_pot)
			@global_pot = 0
		else
			payed_players = 0
			@winners.each do |name|
				m = @intermediary_pot[name]
				if m.money != 0
					payed_players += 1
					if m.money > share
						@players[name].receive_money(share)
						@global_pot -= share
					else
						@players[name].receive_money(m.money)
						@global_pot -= m.money
					end
				end
			end
			if payed_players != @winners.count
				share = divide(@global_pot, @winners.count - payed_players)
				@winners.each do |name|
					if @intermediary_pot[name].money == 0
						@players[name].receive_money(share)
						@global_pot -= share
					end
				end
			end
			rest = share != 0 ? old_pot % share : 0
			if rest != 0
				while rest != 0
					gifted_player = rand(@winners.count - 1)
					@players[@winners[gifted_player]].receive_money(1)
					rest -= 1
					@global_pot -= 1
				end
				# share rest randomly
			end
		end
	end

	def clean_table
		@highest_bet = 0
		@global_pot = 0
		@pot = Hash[@p.map{|p| [p.name, Pot.new]}]
		@intermediary_pot = Hash[@p.map{|p| [p.name, Pot.new]}]
		@cards = []
		@deck = Deck.new()
		@p.each do |playa|
			playa.empty_hand
		end
		# BAD DEAL
		2.times.each do
			@p.each do |playa|
				playa.take_card(@deck)
			end
		end
	end

	def play
		# @logs.seek(0, IO::SEEK_SET)
		# @logs.puts "#{@round}"
		@round += 1
		if @round % 20 == 0
			# 20 - 40 - 60 - 100 - 200 - 300 - 400 - 800 - 1600
			@blind *= 2
		end
		# p '--------------------PREFLOP--------------------'
		blinds
		equalize
		reset_pot
		# p '--------------------FLOP--------------------'
		3.times do
			put_card
		end
		play_round
		reset_pot
		# p '--------------------TURN--------------------'
		put_card
		play_round
		reset_pot
		#p '--------------------RIVER--------------------'
		put_card
		play_round
		reset_pot
		highest_score = 0
		@winners = []
		@players.each do |player_name, player|
			s = @pot[player_name].status
			if s != 'FOLD'
				player.calculate_points(@cards)
				player_score = player.points
				if player_score > highest_score
					highest_score = player_score
					@winners = [player_name]
				elsif player_score == highest_score
					@winners.push(player_name)
				end
			end
		end
		if @winners.count > 1
			reduce_winners
		end
		# @logger.commit_signatures(@winners)
		share_money
		@logger.log_hand_strengh(@players, @winners)
		clean_table
		# p "@winners are #{@winners} with #{highest_score}"
		recap = 0
		@players.each do |_name, player|
			recap += player.money
		end
		staying_players = @players.select{|name, playa| playa.money != 0}
		if staying_players.count == 1
			return false
		end
		true
	end

	def draw
		system 'clear'
		SpaceInvaders.draw(@pot, @cards, @players)
		sleep 1
	end
end

class Player
	attr_reader :money
	attr_reader :name
	attr_reader :points
	attr_reader :cards
	attr_reader :best_cards

	# SHOULD HAVE A PLAYER WITH MEMORIES
	# AND A PLAYER WHO KNOWS HAND STRENGH
	# AND COMPLETE WITH DUMMY BOTS
	def initialize(pname, cards = false)
		@name = pname
		@money = 3000
		@cards = []
		@points = 0
		@best_cards = []
		if cards
			@cards = cards
		end
	end

	def empty_hand
		@cards = []
	end

	def receive_money amount
		# p "#{@name} receive #{amount}"
		@money += amount
	end

	def play pot, highest_bet, blind
		status = pot[@name].status
		diff = highest_bet - pot[@name].money
		# check = check?(pot, highest_bet)
		if status == 'RAISED' && diff == 0
			return [0, 'PAID']
		end
		raises = pot[@name].raises
		random_4 = rand(4)
		# NEVER BACK DOWN
		# random_4 = 1
		# if random_4 == 0 && diff != 0
		if 1 == 0 && diff != 0
			# RAND_3 SHOULD BE BASED ON HAND QUALITY
			# NEED CHECK IF POSSIBLE
			return [0, 'FOLD']
		end
		if @money <= diff
			all = @money
			@money -= all
			return [all, 'TAPPED OUT']
		end
		# raise ?
		if (random_4 == 1 && raises < 3 && @money > highest_bet + diff)
			if @money < (highest_bet * 2) + diff
				all = @money
				@money = 0
				return [all, 'TAPPED OUT']
			else
				if highest_bet == 0
					if @money > (blind * 6)
						@money -= (blind * 6)
						return [(blind * 6), 'RAISED']
					else
						all = @money
						@money -= all
						return [all, 'TAPPED OUT']
					end
				else
					raise_amount = (rand(highest_bet) + blind)
					if @money <= raise_amount + diff
						all = @money
						@money = 0
						return [all, "TAPPED OUT"]
					else
						@money -= raise_amount + diff
						return [raise_amount + diff, 'RAISED']
					end
				end
			end
		end
		@money -= diff
		return [diff, 'PAID']
	end

	def take_card deck
		@cards.push(deck.take_one)
	end

	def pay_lblind(price)
		return [@money, 'ALL IN'] if price > @money
		@money -= price
		return [price, 'LBLIND']
	end

	def pay_bblind(price)
		# SOME PEOPLE SAY YOU CAN FOLD AT THIS POINT
		# BEFORE PAYING BB
		return [@money, 'ALL IN'] if price > @money
		@money -= price
		return [price, 'BBLIND']
	end

	def cards_copy cards
		Marshal.load(Marshal.dump(cards))
	end

	def calculate_points table_cards
		c = @cards + table_cards
		if r = royal_flush?(cards_copy(c))
			@best_cards = r[1]
			@points = 200 + r[0]
		elsif r = straight_flush?(cards_copy(c))
			@best_cards = r[1]
			@points = 180 + r[0]
		elsif r = four_of_a_kind?(cards_copy(c))
			@best_cards = r[1]
			@points = 160 + r[0]
		elsif r = foul_house?(cards_copy(c))
			@best_cards = r[1]
			@points = 140 + r[0]
		elsif r = flush?(cards_copy(c))
			@best_cards = r[1]
			@points = 120 + r[0]
		elsif r = straight?(cards_copy(c))
			@best_cards = r[1]
			@points = 100 + r[0]
		elsif r = three_of_a_kind?(cards_copy(c))
			@best_cards = r[1]
			@points = 80 + r[0]
		elsif r = two_pair?(cards_copy(c))
			@best_cards = r[1]
			@points = 60 + r[0]
		elsif r = pair?(cards_copy(c))
			@best_cards = r[1]
			@points = 40 + r[0]
		else
			c = highest_card(@cards).first
			@best_cards = [c]
			@points = RANKS_TO_INT[c.delete(c[0])]
		end
	end
end

class Deck
	SUITS = ['S', 'H', 'C', 'D']
  RANKS = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

  def initialize
    @cards = []
    generate_cards
    shuffle
  end

  def shuffle
    @cards = @cards.shuffle
  end

  def take_one
    raise DeckError.new("Deck is empty, cannot take card") if @cards.empty?
    @cards.pop
  end

  private

  def generate_cards
    SUITS.each do |s|
      RANKS.each do |r|
        @cards << s + r
      end
    end
  end
end

class Poker

	def self.log data
		log_nbr = Dir["./*"].select{|f| /log[0-9]{1}/ =~ f}.count
		File.open("log#{log_nbr}", 'w+') do |f|
			data.each do |i|
				key_to_str = "#{i[:r]}"
				f.write("#{i[:r]}")
				margin = ""
				(6 - key_to_str.size).times{margin << " "}
				f.write(margin)
				f.write("#{i[:v]}")
				f.write("\n")
			end
		end
	end

	def self.game
		l = Logger.new
		p Time.now
		it = 0
		while it < 2000
			t = Table.new(2, l)
			x = true
			p it if it % 100 == 0
			while x
				x = t.play()
			end
			it += 1
		end
		p Time.now
		ratios = []
		l.data.each do |k, v|
			ratio = v[1] == 0 ? 0 : v[0] * 100 / v[1]
			ratios << {r: ratio, v: k}
		end
		result = ratios.sort_by{|e| e[:r]}
		log(result)
=begin
=end
	end

end

# NEXT STEP
# ADD TESTS AT EVERY END OF ROUND
Poker.game()

=begin
def sort_n_print c
	pp c.sort_by{|x| RANKS_TO_INT[x.delete(x[0])]}
end

#playa.calculate_points(["H8", "C8", "HJ", "HQ", "C9"] + ["H10", "H9"])
playa.calculate_points(["H8", "C8", "D7", "S9", "HK"] + ["H10", "H9"])
p 'playa points'
p playa.points
cards = ["H6", "H8", "SK", "D5", "CQ"] + ["H7", "S4"]
p straight?(cards)
playa1 = Player.new('chum1', ['DQ', 'D6'])
playa2 = Player.new('chum2', ['SQ', 'S6'])
playa3 = Player.new('chum3', ['HK', 'H8'])
players = [playa1, playa2, playa3]
pla = Hash[players.map{|x| [x.name, x]}]
winners = ['chum1', 'chum2']
@deck = Deck.new()
# BAD DEAL
cards = ["H6", "H8", "SK", "D2", "CQ"]
2.times.each do
	players.each do |playa|
		# playa.take_card(@deck)
		playa.calculate_points(cards)
	end
end
# sort_n_print(playa1.cards + cards)
# sort_n_print(playa2.cards + cards)
pp REDUCERS[2].call(winners, pla, cards)
=end
