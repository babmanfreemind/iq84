require './matchers.rb'

def expect(t, expression, value)
  if expression == value
    p "#{t} pass"
  else
    p "#{t} FAILED"
  end
end

cards1 = ['H3', 'DA', 'H4', 'H5', 'S9', 'H2', 'H6']
expect('straight_flush1', straight_flush?(cards1), [5, ['H3', 'H4', 'H5', 'H2', 'H6']])

cards2 = ['H3', 'DA', 'H4', 'H5', 'S9', 'H2', 'C6']
expect('straight_flush2', straight_flush?(cards2), false)

cards3 = ['H3', 'HA', 'H4', 'H5', 'S9', 'H2', 'C6']
expect('straight_flush3', straight_flush?(cards3), [4, ['H3', 'HA', 'H4', 'H5', 'H2']])

cards4 = ['H3', 'HA', 'H4', 'H5', 'H6', 'H2', 'C6']
expect('straight_flush4', straight_flush?(cards4), [5, ['H3', 'H4', 'H5', 'H6', 'H2']])

cards5 = ['H3', 'HA', 'H4', 'H5', 'H6', 'H2', 'H7']
expect('straight_flush5', straight_flush?(cards5), [6, ['H3', 'H4', 'H5', 'H6', 'H7']])

cards6 = ['H3', 'HA', 'H4', 'H5', 'H10', 'H2', 'C7']
expect('straight1', straight?(cards6), [4, ['H3', 'HA', 'H4', 'H5', 'H2']])

cards7 = ['D3', 'HA', 'S4', 'C5', 'H10', 'H2', 'C6']
expect('straight2', straight?(cards7), [5, ['D3', 'S4', 'C5', 'H2', 'C6']])

cards8 = ['D10', 'HA', 'SJ', 'CQ', 'H10', 'H2', 'CK']
expect('straight3', straight?(cards8), [13, ['D10', 'HA', 'SJ', 'CQ', 'CK']])

cards9 = ['D10', 'HA', 'SJ', 'CQ', 'H10', 'H2', 'C2']
expect('straight4', straight?(cards9), false)

cards10 = ['D7', 'HA', 'S8', 'CJ', 'H10', 'H2', 'C9']
expect('straight5', straight?(cards10), [10, ['D7', 'S8', 'CJ', 'H10', 'C9']])
