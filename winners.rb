require './helper.rb'

# Need to FACTORIZE

class ReducerError < StandardError
end

bluff_reduce = Proc.new { |winners, players, cards|
	ultimate_winners = []
	best_cards = []
	players.each do |playa_name, playa|
		if winners.include?(playa_name)
			c = playa.cards + cards
			sorted_c = c.sort_by{|x| RANKS_TO_INT[x.delete(x[0])]}.reverse[0..4]
			if best_cards == []
				best_cards = sorted_c
				ultimate_winners = [playa_name]
			else
				if cards_are_equal(sorted_c, best_cards)
					ultimate_winners << playa_name
				else
					if cards_are_better(sorted_c, best_cards)
						ultimate_winners = [playa_name]
						best_cards = sorted_c
					end
				end
			end
		end
	end
	ultimate_winners
}

pair_reduce = Proc.new { |winners, players, cards|
	ultimate_winners = []
	best_cards = []
	players.each do |playa_name, playa|
		if winners.include?(playa_name)
			raise ReducerError.new("Player #{playa_name} doesnt have best_cards") if playa.best_cards.empty?
			c = playa.best_cards + n_best_cards(3, (cards + playa.cards) - playa.best_cards)
			sorted_c = c.sort_by{|x| RANKS_TO_INT[x.delete(x[0])]}.reverse[0..4]
			best_cards, ultimate_winners = check_for_best_cards(best_cards, ultimate_winners, sorted_c, playa_name)
		end
	end
	ultimate_winners
}

two_pair_reduce = Proc.new { |winners, players, cards|
	ultimate_winners = []
	best_cards = []
	players.each do |playa_name, playa|
		if winners.include?(playa_name)
			raise ReducerError.new("Player #{playa_name} doesnt have best_cards") if playa.best_cards.empty?
			c = playa.best_cards + n_best_cards(1, (cards + playa.cards) - playa.best_cards)
			sorted_c = c.sort_by{|x| RANKS_TO_INT[x.delete(x[0])]}.reverse[0..4]
			best_cards, ultimate_winners = check_for_best_cards(best_cards, ultimate_winners, sorted_c, playa_name)
		end
	end
	ultimate_winners
}

three_of_a_kind_reduce = Proc.new { |winners, players, cards|
	ultimate_winners = []
	best_cards = []
	players.each do |playa_name, playa|
		if winners.include?(playa_name)
			raise ReducerError.new("Player #{playa_name} doesnt have best_cards") if playa.best_cards.empty?
			c = playa.best_cards + n_best_cards(2, (cards + playa.cards) - playa.best_cards)
			sorted_c = c.sort_by{|x| RANKS_TO_INT[x.delete(x[0])]}.reverse[0..4]
			best_cards, ultimate_winners = check_for_best_cards(best_cards, ultimate_winners, sorted_c, playa_name)
		end
	end
	ultimate_winners
}

straight_reduce = Proc.new { |winners, players, cards|
	winners
}

flush_reduce = Proc.new { |winners, players, cards|
	winners
}

full_house_reduce = Proc.new { |winners, players, cards|
	winners
}

four_of_a_kind_reduce = Proc.new { |winners, players, cards|
	ultimate_winners = []
	best_cards = []
	players.each do |playa_name, playa|
		if winners.include?(playa_name)
			raise ReducerError.new("Player #{playa_name} doesnt have best_cards") if playa.best_cards.empty?
			c = playa.best_cards + n_best_cards(1, (cards + playa.cards) - playa.best_cards)
			sorted_c = c.sort_by{|x| RANKS_TO_INT[x.delete(x[0])]}.reverse[0..4]
			best_cards, ultimate_winners = check_for_best_cards(best_cards, ultimate_winners, sorted_c, playa_name)
		end
	end
	ultimate_winners
}

straight_flush_reduce = Proc.new { |winners, players, cards|
	winners
}

royal_flush_reduce = Proc.new { |winners, players, cards|
	winners
}

REDUCERS = [bluff_reduce, pair_reduce, two_pair_reduce, three_of_a_kind_reduce, straight_reduce,
flush_reduce, full_house_reduce, four_of_a_kind_reduce, straight_flush_reduce, royal_flush_reduce]

def cards_are_better c1, c2
	c1.each_with_index do |c, i|
		c1_score = RANKS_TO_INT[c.delete(c[0])]
		c2_score = RANKS_TO_INT[c2[i].delete(c2[i][0])]
		if c1_score > c2_score 
			return true
		elsif c2_score > c1_score
			return false
		end
	end
end

def cards_are_equal c1, c2
	c1.each_with_index do |c, i|
		c1_score = RANKS_TO_INT[c.delete(c[0])]
		c2_score = RANKS_TO_INT[c2[i].delete(c2[i][0])] 
		if c1_score != c2_score 
			return false
		end
	end
	return true
end

def n_best_cards n, cards
	y = cards.sort_by{|c| RANKS_TO_INT[c.delete(c[0])]}.reverse[0..(n - 1)]
end

def check_for_best_cards best_cards, ultimate_winners, sorted_c, playa_name
	if best_cards == []
		best_cards = sorted_c
		ultimate_winners = [playa_name]
	else
		if cards_are_equal(sorted_c, best_cards)
			ultimate_winners << playa_name
		else
			if cards_are_better(sorted_c, best_cards)
				ultimate_winners = [playa_name]
				best_cards = sorted_c
			end
		end
	end
	[best_cards, ultimate_winners]
end