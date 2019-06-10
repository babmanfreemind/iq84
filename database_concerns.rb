# Import the driver.
require 'pg'


class DatabaseConcerns
	def initialize
		@conn = PG.connect(
			user: 'iq84',
			dbname: 'iq84_db',
			host: 'iq84_db',
			port: 26257,
			sslmode: 'disable'
			)
	end

	def set_counts
		res = @conn.exec('SELECT * FROM ids_counter LIMIT 1')
		@signatures_count = res[0]["signatures_count"].to_i
		@actions_count = res[0]["actions_count"].to_i
	end

	def create_tables
		@conn.exec('CREATE TABLE IF NOT EXISTS ids_counter (signatures_count INT, actions_count INT)')
		@conn.exec('CREATE TABLE IF NOT EXISTS signatures (id INT PRIMARY KEY, definition STRING)')
		@conn.exec('CREATE TABLE IF NOT EXISTS actions (id INT PRIMARY KEY, signature_id INT, move STRING, bblinds INT, winrate DECIMAL(7, 3), won INT, lost INT)')
		if @conn.exec('SELECT * FROM actions LIMIT 1').count == 0
			@conn.exec('CREATE INDEX ON actions (signature_id)')
		end
		if @conn.exec('SELECT * FROM ids_counter LIMIT 1').count == 0
			@conn.exec('INSERT INTO ids_counter (signatures_count, actions_count) VALUES (0, 0)')
		end
	end

	def update_action action, new_version
		won = action['won'].to_i
		lost = action['lost'].to_i
		if new_version.won
			won += 1
			winrate = won * 100 / (won + lost)
			@conn.exec("UPDATE actions SET won = #{won}, winrate = #{winrate} WHERE id = #{action['id']}")
		else
			lost += 1
			winrate = won * 100 / (won + lost)
			@conn.exec("UPDATE actions SET lost = #{lost}, winrate = #{winrate} WHERE id = #{action['id']}")
		end
	end

	def create_action signature_id, action
		@actions_count += 1
		if action.won
			values = "(#{@actions_count}, #{signature_id}, '#{action.move}', #{action.bblinds}, 100, 1, 0)"
		else
			values = "(#{@actions_count}, #{signature_id}, '#{action.move}', #{action.bblinds}, 0, 0, 1)"
		end
		@conn.exec("INSERT INTO actions (id, signature_id, move, bblinds, winrate, won, lost) VALUES #{values}")
	end

	def insert_signature signature_definition
		@signatures_count += 1
		@conn.exec("INSERT INTO signatures (id, definition) VALUES (#{@signatures_count}, '#{signature_definition}')")
	end

	def find_or_create_signature signature_definition
		res = @conn.exec("SELECT id FROM signatures WHERE definition = '#{signature_definition}' LIMIT 1")
		if res.count != 0
			return res[0]['id']
		end
		insert_signature(signature_definition)
		return @signatures_count
	end

	def insert_or_update_action new_action, signature_id
		res = @conn.exec("SELECT * FROM actions WHERE signature_id = #{signature_id} AND move = '#{new_action.move}' AND bblinds = '#{new_action.bblinds}' LIMIT 1")
		if res.count != 0
			update_action(res[0], new_action)
		else
			create_action(signature_id, new_action)
		end
	end

	def insert_signature_and_moves signature_definition, actions
		signature_id = find_or_create_signature(signature_definition)
		actions.each do |a|
			insert_or_update_action(a, signature_id)
		end
	end

	def close
		@conn.exec("UPDATE ids_counter SET signatures_count = #{@signatures_count}, actions_count = #{@actions_count}")
		@conn.close()
	end

end

