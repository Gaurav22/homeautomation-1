window.onload = () ->

	flotOpts =
		lines:
			show: true
		points:
			show: false
		yaxis:
			position: 'right'
			tickDecimals: 0
			tickSize: 1
			autoscaleMargin: 0.1
			labelWidth: 35
		xaxis:
			mode: "time"
			timezone: "browser"
		crosshair:
			mode: "xy"
		grid:
			hoverable: true
		legend:
			position: "nw"

	plotOptsOverride =
		"voltage":
			yaxis:
				tickSize: null

	sensorlist = ['livingroom-bookshelf', 'refrigerator', 'bedroom', 'outside']
	sensordata = {}

	graphs = [
		{name: "voltage", attribute: "voltage", sensors: ['livingroom-bookshelf', 'bedroom', 'refrigerator']}
		{name: "other", attribute: "temperature", sensors: ['refrigerator']}
		{name: "rooms", attribute: "temperature", sensors: ['livingroom-bookshelf', 'bedroom', 'outside']}
		]

	$("#graphs").prepend "<div class='graph' id='graph-#{x.name}'>" for x in graphs

	socket = io.connect '#{window.location.protocol}://#{window.location.host}'

	socket.on 'connect', () ->
		console.log "connected"

	socket.on 'initial', (data) ->
		sensordata = data
		plotGraph graph, sensordata for graph in graphs


	prepareGraphData = (sensor, attribute, data) ->
		datapoints = _.map data, (x) -> [new Date(x.timestamp), x[attribute]]
		{label: sensor, data: datapoints}


	plotGraph = (graph, data) ->
		console.info "Plotting #{graph.name}"
		opts =
			if graph.name of plotOptsOverride
			then _.merge {}, flotOpts, plotOptsOverride[graph.name]
			else flotOpts
		graphData = (prepareGraphData sensor, graph.attribute, data[sensor] for sensor in graph.sensors)

		$.plot "#graph-#{graph.name}", graphData, opts


	sensorSubscribe = (sensor) ->
		console.info "Subscribing to #{sensor} events."
		socket.on sensor, (data) ->
			sensordata[sensor] = data

			# TODO: only plot affected graphs
			plotGraph graph, sensordata for graph in graphs


	setUpToolTip = () ->
		for x in graphs
			$("#graph-#{x.name}").bind 'plothover', (event, pos, item) ->
				$("#tooltip").remove()
				showToolTip item.pageX, item.pageY, "#{item.series.label}: #{item.datapoint[1]}" if item


	showToolTip = (x, y, contents) ->
		css = { top: y + 5, left: x + 5 }
		$('<div id="tooltip">' + contents + '</div>').css(css).appendTo("body").fadeIn(200)

	sensorSubscribe sensor for sensor in sensorlist
	setUpToolTip()