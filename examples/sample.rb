require 'bosh4r'

session = Bosh4r::Session.new('foo@localhost', 'password')
p session.sid
