require './helper.rb'

# FLUSH can be A-2-3-4-5 !
# FLUSH can be A-2-3-4-5 !
# FLUSH can be A-2-3-4-5 !
# FLUSH can be A-2-3-4-5 !
# FLUSH can be A-2-3-4-5 !
# FLUSH can be A-2-3-4-5 !
# FLUSH can be A-2-3-4-5 !

def royal_flush? cards
	same_suits = cards.group_by{|m| m[0]}.inject {|sum,x| x[1].count >= sum[1].count ? x : sum }
	result = false
	electable_cards = []
	same_suits[1].each{|el| electable_cards << el.dup}
	if same_suits[1].count >= 5
		same_suits[1].map do |x|
			x.slice!(x[0])
		end
		sorted = same_suits[1].map{|n| RANKS_TO_INT[n]}.sort
		if sorted.count == 7
			if r = royal_flush_from7?(sorted)
				s = electable_cards.select{|x| r.include?(RANKS_TO_INT[x.delete(x[0])])}
				result = [r.last, s]
			else
				return false
			end
		elsif sorted.count == 6
			if r = royal_flush_from6?(sorted)
				s = electable_cards.select{|x| r.include?(RANKS_TO_INT[x.delete(x[0])])}
				result = [r.last, s]
			else
				return false
			end
		elsif sorted.count == 5
			if r = royal_flush_from5?(sorted)
				s = electable_cards.select{|x| r.include?(RANKS_TO_INT[x.delete(x[0])])}
				result = [r.last, s]
			else
				return false
			end
		end
	end
	return result
end

def straight_flush? cards
	same_suits = cards.group_by{|m| m[0]}.inject {|sum,x| x[1].count >= sum[1].count ? x : sum }
	result = false
	electable_cards = []
	same_suits[1].each{|el| electable_cards << el.dup}
	if same_suits[1].count >= 5
		same_suits[1].map do |x|
			x.slice!(x[0])
		end
		sorted = same_suits[1].map{|n| RANKS_TO_INT[n]}.sort
		if sorted.count == 7
			if r = straight_flush_from7?(sorted)
				s = electable_cards.select{|x| r.include?(RANKS_TO_INT[x.delete(x[0])]) || (r[0] == 0 && x.delete(x[0]) == RANKS.last)}
				# BUGGY SHOULD BE result = [r.last, s.uniq{|y| y.delete(y[0])}]
				result = [r.last, s.uniq{|y| y.delete(y[0])}]
			else
				return false
			end
		elsif sorted.count == 6
			if r = straight_flush_from6?(sorted)
				s = electable_cards.select{|x| r.include?(RANKS_TO_INT[x.delete(x[0])]) || (r[0] == 0 && x.delete(x[0]) == RANKS.last)}
				result = [r.last, s.uniq{|y| y.delete(y[0])}]
			else
				return false
			end
		elsif sorted.count == 5
			if r = straight_flush_from5?(sorted)
				s = electable_cards.select{|x| r.include?(RANKS_TO_INT[x.delete(x[0])]) || (r[0] == 0 && x.delete(x[0]) == RANKS.last)}
				result = [r.last, s.uniq{|y| y.delete(y[0])}]
			else
				return false
			end
		end
	end
	return result
end

def four_of_a_kind? cards
	same_rank = cards.group_by{|m| m.delete(m[0])}.inject {|sum,x| x[1].count >= sum[1].count ? x : sum }
	result = false
	if same_rank[1].count == 4
		result = [RANKS_TO_INT[same_rank[1].last.delete(same_rank[1].last[0])], same_rank[1]]
	end
	return result
end

def foul_house? cards
	same_rank = cards.group_by{|m| m.delete(m[0])}
	three = same_rank.inject {|acc,it| (it[1].count == 3) && (acc[1].count != 3 || RANKS_TO_INT[it[0]] > RANKS_TO_INT[acc[0]]) ? it : acc }
	return false unless three[1].count == 3
	remaining_cards = cards - three[1]
	same_rank = remaining_cards.group_by{|m| m.delete(m[0])}
	double = same_rank.inject {|acc,it| (it[1].count == 2) && (acc[1].count != 2 || RANKS_TO_INT[it[0]] > RANKS_TO_INT[acc[0]]) ? it : acc }
	return false unless double[1].count == 2
	return [RANKS_TO_INT[three[1].last.delete(three[1].last[0])], three[1] + double[1]]
end

def flush? cards
	same_suits = cards.group_by{|m| m[0]}.inject {|acc,it| it[1].count >= acc[1].count ? it : acc }
	if same_suits[1].count >= 5
		sorted = same_suits[1].sort_by{|x| RANKS_TO_INT[x.delete(x[0])]}.reverse
		return [RANKS_TO_INT[sorted.first.delete(sorted.first[0])], sorted[0..4]]
	end
	return false
end

def straight? cards
	ranks = cards.map{|c| c.delete(c[0]) }

	ordered_int_ranks = ranks.map{|oir| RANKS_TO_INT[oir] }.sort.reverse
	card_index = 1
	if ordered_int_ranks.first == RANKS_TO_INT[RANKS.last]
		ordered_int_ranks << 0
	end
	last = ordered_int_ranks[0]
	suit = [last]
	while card_index <= ordered_int_ranks.count
		if last == ordered_int_ranks[card_index]
			card_index += 1
			next
		end
		if ordered_int_ranks[card_index] == last - 1
			suit.push(ordered_int_ranks[card_index])
		else
			suit = [ordered_int_ranks[card_index]]
		end
		if suit.count == 5
			electable_cards = []
			cards.each do |c|
				if (suit.include?(RANKS_TO_INT[c.delete(c[0])]) || (suit.last == 0 && c.delete(c[0]) == RANKS.last)) && !electable_cards.map{|el| el.delete(el[0])}.include?(c.delete(c[0]))
					electable_cards << c
				end
			end
			return [suit.first, electable_cards]
		end
		last = ordered_int_ranks[card_index]
		card_index += 1
	end
	return false
end

def three_of_a_kind? cards
	same_rank = cards.group_by{|m| m.delete(m[0])}
	three = same_rank.inject {|acc,it| (it[1].count == 3) && (acc[1].count != 3 || RANKS_TO_INT[it[0]] > RANKS_TO_INT[acc[0]]) ? it : acc }
	three_value = three[1].last.delete(three[1].last[0])
	return [RANKS_TO_INT[three_value], three[1]] if three[1].count == 3
	return false
end

def two_pair? cards
	same_rank = cards.group_by{|m| m.delete(m[0])}
	first_pair = same_rank.inject {|acc,it| (it[1].count == 2) && (acc[1].count != 2 || RANKS_TO_INT[it[0]] > RANKS_TO_INT[acc[0]]) ? it : acc }
	return false unless first_pair[1].count == 2
	remaining_cards = cards - first_pair[1]
	same_rank = remaining_cards.group_by{|m| m.delete(m[0])}
	second_pair = same_rank.inject {|acc,it| (it[1].count == 2) && (acc[1].count != 2 || RANKS_TO_INT[it[0]] > RANKS_TO_INT[acc[0]]) ? it : acc }
	return false unless second_pair[1].count == 2
	fp_rank = first_pair[1].last.delete(first_pair[1].last[0])
	sp_rank = second_pair[1].last.delete(second_pair[1].last[0])
	fp_value = RANKS_TO_INT[fp_rank]
	sp_value = RANKS_TO_INT[sp_rank]
	return [fp_value, first_pair[1] + second_pair[1]] if fp_value > sp_value
	return [sp_value, first_pair[1] + second_pair[1]]
end

def pair? cards
	same_rank = cards.group_by{|m| m.delete(m[0])}
	pair = same_rank.inject {|acc,it| (it[1].count == 2) && (acc[1].count != 2 || RANKS_TO_INT[it[0]] > RANKS_TO_INT[acc[0]]) ? it : acc }
	return false unless pair[1].count == 2
	p_value = pair[1].last.delete(pair[1].last[0])
	return [RANKS_TO_INT[p_value], pair[1]]
end

def highest_card cards
	raise StandardError, "Highest card : works with the two player cards only : received #{cards.count} cards" if cards.count > 2
	return cards.sort_by{|c| RANKS_TO_INT[c.delete(c[0])]}.reverse
end

def generate_card cards
	search = true
	while search
		s = SUITS.sample
		r = RANKS.sample
		card = s + r
		unless cards.include?(card)
			cards.push(card)
			search = false
		end
	end
end

def generate
	sets = 0
	File.open('dataset', 'w') do |f|
		while sets < 20000
			card_nbr = 0
			cards = []
			while cards.length < 7
				generate_card(cards)
				card_nbr += 1
			end
			f.write(cards.join(','))
			f.write("\n")
			sets += 1
			cards = []
			card_nbr = 0
		end
	end
end

def straight_flush_from5? sorted
	if sorted.last == RANKS_TO_INT[RANKS.last]
		sorted.unshift(0)
		if sorted[0..4].inject(&:+) == (sorted[0] * 5 + 10)
			return sorted[0..4]
		end
		if sorted[1..5].inject(&:+) == (sorted[0] * 5 + 10)
			return sorted[1..5]
		end
	else
		if sorted.inject(&:+) == (sorted[0] * 5 + 10)
			return sorted
		end
	end
=begin
	if sorted.inject(&:+) == (sorted[0] * 5 + 10)
		return sorted
	end
=end
	return false
end

def straight_flush_from6? sorted
	sources = [
		sorted[1..5],
		sorted[0..4]
	]
	sources.each do |s|
=begin
		if s.inject(&:+) == (s[0] * 5 + 10)
			return s
		end
=end
		if s.last == RANKS_TO_INT[RANKS.last]
			s.unshift(0)
			if s[0..4].inject(&:+) == (s[0] * 5 + 10)
				return s[0..4]
			end
			if s[1..5].inject(&:+) == (s[0] * 5 + 10)
				return s[1..5]
			end
		else
			if s.inject(&:+) == (s[0] * 5 + 10)
				return s
			end
		end
	end
	return false
end

def straight_flush_from7? sorted
	sources = [
		sorted[2..6],
		sorted[1..5],
		sorted[0..4]
	]
	sources.each do |s|
		if s.last == RANKS_TO_INT[RANKS.last]
			s.unshift(0)
			if s[0..4].inject(&:+) == (s[0] * 5 + 10)
				return s[0..4]
			end
			if s[1..5].inject(&:+) == (s[0] * 5 + 10)
				return s[1..5]
			end
		else
			if s.inject(&:+) == (s[0] * 5 + 10)
				return s
			end
		end
=begin
		if s.inject(&:+) == (s[0] * 5 + 10)
			return s
		end
=end
	end
	return false
end

def royal_flush_from5? sorted
	if sorted.inject(&:+) == 50
		return sorted
	end
	return false
end

def royal_flush_from6? sorted
	if sorted[1..5].inject(&:+) == 50
		return sorted[1..5]
	end
	return false
end

def royal_flush_from7? sorted
	if sorted[2..6].inject(&:+) == 50
		return sorted[2..6]
	end
	return false
end
