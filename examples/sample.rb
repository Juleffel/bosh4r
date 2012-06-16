require 'bosh4r'

session = Bosh4r::Session.new('gg@localhost', 'password')
p session.sid
