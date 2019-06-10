require './database_concerns.rb'

class Action
	attr_reader :player
	attr_reader :move
	attr_reader :bblinds
	attr_accessor :won

	def initialize pstatus, pmoney, pplayer
		@move = pstatus
		@bblinds = pmoney
		@player = pplayer
		@won = nil
	end
end

class Signature
	attr_reader :situation
	attr_reader :move

	def initialize psituation, pmove
		@situation = psituation
		@move = Move.new(pmove[1], pmove[2])
	end
end

class Logger
	attr_reader :data
	attr_reader :signatures

	def initialize
		@data = {}
		@signatures = {}
	end

	def commit_signatures winners
		d = DatabaseConcerns.new
		d.create_tables
		d.set_counts
		@signatures.each do |signature, moves|
		  moves.each do |move|
		   if winners.include?(move.player)
		    move.won = true
		   else
		    move.won = false
		   end
		  end
		  d.insert_signature_and_moves(signature, moves)
		end
		d.close
		@signatures = {}
	end

	# TEST DISS SHIIT BOI !!
	def log_signature(talkin, player_cards, pot, cards, talked)
		round_name = case cards.count
			when 0
				"p"
			when 3
				"f"
			when 4
				"t"
			when 5
				"r"
			else
				raise StandardError, "Log signature : should not happend, cards count is #{cards.count}"
		end
		best_color = best_color(player_cards + cards, round_name)

		# PREFIX SIGNATURE BY ROUND NAME (p for preflop, f for flop, t for turn, r for river)
		table_abstract = abstract_cards(cards, best_color)
		hand_abstract = abstract_cards(player_cards, best_color)
		
		players_weight = 0
		pot.each do |_pname, player|
			s = player.status
			if s == "PAID"
				players_weight += 10
			elsif s == "RAISED" || s == "TAPPED OUT"
				players_weight += 15
			elsif s == "INGAME" || s == "LBLIND" || s == "BBLIND"
				players_weight += 5
			end
		end
		# player_nbr = 99
		# signature = round_name + player_nbr.to_s + hand_abstract + table_abstract
		separator = table_abstract.count != 0 ? '-' : ''
		signature = round_name + players_weight.to_s + '-' + hand_abstract.join('-') + separator + table_abstract.join('-')
		
		# BAD !!!  WE CAN HAVE TWO SIGNATURE WITH SAME SITUATION
		move = Action.new(talked[1], talked[2], talkin)
		if !@signatures[signature]
			@signatures[signature] = [move]
		else
			@signatures[signature] << move
		end
	end

	def log_move

	end

	def best_color(cards, round_name)
		cards_with_same_colors = cards.group_by{|c| c[0]}
		count = 0
		best = nil
		cards_with_same_colors.each do |color, v|
			if v.count > count
				count = v.count
				best = color
			end
		end
		return best if round_name == 'p'
		return best if round_name == 'f' && count >= 3
		return best if round_name == 't' && count >= 4
		return best if round_name == 'r' && count >= 5
		nil
	end

	def log_hand_strengh(players, winners)
		# ABSTRACT ZERO
		players.each do |pname, playa|
			cards = playa.cards
			win = winners.include?(pname)
			c1_value = RANKS_TO_INT[cards[0].delete(cards[0][0])]
			c2_value = RANKS_TO_INT[cards[1].delete(cards[1][0])]
			if cards[0].delete(cards[0][0]) == cards[1].delete(cards[1][0])
				if c1_value > c2_value
					couple = cards[0].delete(cards[0][0]) + cards[1].delete(cards[1][0])
				else
					couple = cards[1].delete(cards[1][0]) + cards[0].delete(cards[0][0])
				end
			elsif cards[0][0] == cards[1][0]
				if c1_value > c2_value
					couple = 'X' + cards[0].delete(cards[0][0]) + 'X' + cards[1].delete(cards[1][0])
				else
					couple = 'X' + cards[1].delete(cards[1][0]) + 'X' + cards[0].delete(cards[0][0])
				end
			else
				if c1_value > c2_value
					couple = 'X' + cards[0].delete(cards[0][0]) + 'Y' + cards[1].delete(cards[1][0])
				else
					couple = 'X' + cards[1].delete(cards[1][0]) + 'Y' + cards[0].delete(cards[0][0])
				end
			end
			if !data[couple]
				if win
					data[couple] = [1,0]
				else
					data[couple] = [0,1]
				end
			else
				if win
					data[couple][0] += 1
				else
					data[couple][1] += 1
				end
			end
		end
	end

	def abstract_cards cards, best_color
		d = []
		sorted_cards = cards.sort_by{|c| RANKS_TO_INT[c.delete(c[0])]}.reverse
		sorted_cards.each do |c|
			if c[0] == best_color
				d << c.gsub(best_color, 'X')
			else
				d << c.gsub(c[0], 'Y')
			end
		end
		d
	end
end

# HA SA
# A A

# D10 S10
# 10 10

# C5 CJ
# X5 XJ

# H8 HA
# X8 XA