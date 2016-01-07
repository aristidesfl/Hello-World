install = (details) ->
	if details.reason is "install"
		# Open welcome page
		chrome.tabs.create({url: "welcome.html"})

		# Make extension work on all tabs without having to refresh or restart browser
		chrome.windows.getAll (windows) ->
			for myWindow in windows
				chrome.tabs.getAllInWindow myWindow.id, (tabs) ->
					for tab in tabs
						chrome.tabs.executeScript(tab.id, {file: "js/content.js"}) unless tab.url.startsWith("chrome")

initialize = ->
	mixpanel.register({'Extension: Version': chrome.app.getDetails().version})

	license =
		email: ''
		key: ''
		verified: false

	# Check with the server if the user has a valid license
	chrome.storage.sync.get license, (results) ->
		license = results
		if not license.email or not license.key # No license data
			updateLicenseAndContinue(false)
		else if navigator.onLine # Contact server and check if license if valid
			data = new FormData()
			data.append('email', license.email)
			data.append('key', license.key)
			request = new XMLHttpRequest();
			request.open('POST', 'https://smoothkeyscroll.herokuapp.com/license/verify', true);
			request.onerror = -> updateLicenseAndContinue(false)
			request.onload = -> updateLicenseAndContinue(request.responseText is 'Valid')
			request.send(data)
		else # Offline, proced with stored license data
			initializeIntenta()

	# Report usage statistics
	chrome.storage.sync.get {scrollCount: -1, notificationCount: -1}, (results) ->
		data = new FormData()
		data.append('id', mixpanel.get_distinct_id())
		data.append('scroll_count', results.scrollCount)
		data.append('notification_count', results.notificationCount)
		request = new XMLHttpRequest();
		request.open('POST', 'https://smoothkeyscroll.herokuapp.com/analytics/submit', true);
		request.send(data)
		mixpanel.people.set({
			scroll_count: results.scrollCount
			notification_count: results.notificationCount
		})

	updateLicenseAndContinue = (verified) ->
		license.verified = verified
		chrome.storage.sync.set(license)
		initializeIntenta()

	initializeIntenta = ->
		return no if license.verified
		console.log 'initializeIntenta'
		window.agent = new IntentaAgent();
		window.agent.setEnv('production');
		window.agent.setToken('BWEATVykfSpY7JyyA1j8tA');
		window.agent.run();

chrome.runtime.onInstalled.addListener(install)
chrome.runtime.onInstalled.addListener(initialize)
chrome.runtime.onStartup.addListener(initialize)
