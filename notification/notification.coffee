# Notification service for home automation system

require 'coffee-script'

nconf   = require 'nconf'
zmq     = require 'zmq'
Email   = (require './lib/email').Email

notificationActions =
	email: "email",
	default: "email"

# Load configuration settings (argv > env > config.json)
nconf.argv().env().file {file: 'config.json'}

# Set up emailer
email = new Email nconf.get 'email'

# Set up zmq socket, connect and subscribe to notification events
brokerSubAddr = 'tcp://127.0.0.1:9999'
brokerSub = zmq.socket 'sub'
brokerSub.identity = 'notification' + process.pid

brokerSub.connect brokerSubAddr, (err) ->
	throw err if err
	console.log 'Sub Broker connected!'

brokerSub.subscribe 'notification'

emailTarget = (target, pkg) ->
	console.log "Emailing notification to #{target}"
	email.send target, pkg.subject or "", pkg.content or "", (err, msg) ->
		console.log err or msg

handlePkg = (pkg) ->
	switch pkg.action
		when "email"
			targets = pkg.targets or (nconf.get 'defaultEmailTargets') or []
			targets = [targets] if typeof targets is "string"

			emailTarget target, pkg for target in targets
		else
			console.log "Unknown service.."


brokerSub.on 'message', (topic, data) ->
	try
		pkg = JSON.parse data

		pkg.action = pkg.action or notificationActions.default
		pkg.action = notificationActions.default if not notificationActions[pkg.action]?

		handlePkg pkg

	catch error
		console.dir error

process.on 'SIGINT', () ->
	brokerSub.close()