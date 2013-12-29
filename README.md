# Swisscom PhoneCalls

If you have a Swisscom IP Phone, there's a option on the Swisscom portal to have a list of all your answered and missed calls.

These scripts and app will fetch the info from the Swisscom website, populate a database and feed the result to an iPhone app.

This is clearly a hack because Swisscom may change the format of the data provided.

Server Stuff
------------

- <b>database.txt</b> contains the structure of the database: I've made a MySQL DB, but any DB can be used, even a NoSQL db.

- <b>swisscom.pl</b> is a perl script that scraps the infos from the Swisscom portal. This script needs your Swisscom login/pwd!

- <b>swisscom_calls.php</b> should be made available via a webserver so the iOS app can use it.

## Notes ##

The Swisscom.pl script uses Prowl http://www.prowlapp.com to send notifications. Comment if you don't use it.

Rename the swisscom_calls.php page and switch your server to HTTPS, so your data remains almost private (just kidding because NSA)

The iOS app is for iPhone/IOS7.

It's my first ARC app and I feel dirty. I'm not in control of the memory management and I don't like it.

No Storyboards, because.
