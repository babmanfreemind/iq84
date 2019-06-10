class Colors
attr_accessor :red
def self.colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def self.white
	white = Proc.new {|text|
	  text
	}
end

def self.red
	red = Proc.new {|text|
	  colorize(text, 31)
	}
end
def self.green
  green = Proc.new {|text|
	  colorize(text, 32)
	}
end

def self.yellow
  yellow = Proc.new {|text|
	  colorize(text, 33)
	}
end

def self.blue
	blue = Proc.new {|text|
		colorize(text, 34)
	}
end

def self.pink
  red = Proc.new {|text|
	  colorize(text, 35)
	}
end

def self.light_blue
  red = Proc.new {|text|
	  colorize(text, 36)
	}
end
end

class SpaceInvaders

	def self.shape
		[
			[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0],
			[0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
			[0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0],
			[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
			[0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0],
			[0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0],
			[0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		]
	end

	def self.draw pot, cards, players
		money = [
			""
		]
		names = [
			"",
			"",
			"",
			"",
			""
		]
		map = [
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
		]
		dcards = [
			"",
			"",
			""
		]
		colors = [Colors.white, Colors.pink, Colors.light_blue, Colors.yellow, Colors.green, Colors.red, Colors.blue]
		statuses = {"INGAME" => 0, "LBLIND" => 1, "BBLIND" => 2, "PAID" => 3, "RAISED" => 4, "FOLD" => 5, "TAPPED OUT" => 6}
		player_nbr = 0
		pot.each do |playa_name, playa|
			money[0] += (players[playa_name].money.to_s + blank(13))[0..14] + blank(1)
			names[0] += ((playa_name + blank(13))[0..14] + blank(1))
			names[1] += (playa.money.to_s + blank(15))[0..14] + blank(1)
			dd = [
				"",
				"",
				""
			]
			players[playa_name].cards.each do |c|
				s = c.size > 2 ? " ___ " : " __ "
				dd[0] += s
				dd[1] += "|#{c}|"
				dd[2] += s
			end
			names[2] += (dd[0] + blank(13))[0..14]
			names[3] += (dd[1] + blank(13))[0..14]
			names[4] += (dd[2] + blank(13))[0..14]
			(0..10).each do |l|
				color = colors[statuses[playa.status]]
				map[l] += ("   " + color.call(line(l)))
			end
			player_nbr += 1
		end
		cards.each do |c|
			s = c.size > 2 ? " ___ " : " __ "
			dcards[0] += blank(6) + s
			dcards[1] += blank(6) + "|#{c}|"
			dcards[2] += blank(6) + s
		end
		puts blank(6) + money[0]
		names.each do |n|
			puts blank(6) + n
		end
		map.each do |m|
			puts m
		end
		dcards.each do |d|
			puts d
		end
	end

	def self.blank size
		size.times.map{" "}.join
	end

	def self.line index
		l = ""
		shape[index].each do |x|
			if x == 1
				l = l + "\u25A0"
			else
				l = l + " "
			end
		end
		return l
	end
end