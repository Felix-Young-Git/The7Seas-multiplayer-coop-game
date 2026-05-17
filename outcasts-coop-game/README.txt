THIS IS THE README FOR THE MULTIPLAYER COOP GAME OUTCASTS

To play the game:

	- currently, when running the game, godot runs 2 instances of the game, to turn this off go to
	  debug, then to custimaize run instances, then set to 1

	- One player will be the host, and so will click the "host" button

	- The other players will connect to the host by entering the hosts IP address
		- If the other players are on the same network as the host, they should enter the hosts
		LOCAL IP ADDRESS, which can be found by entering "ipconfig" in the terminal and looking
		for the IPV4 number, this is NOT the one displayed in the game.
		- If the other players are not on the same network as the host, then they shouold enter the
		hosts public IP address as shown in the game. 

	- IMPORTANT:
		- If the host is not playing on FELIX's computer, then they will need to setup a port
		forwarding rule for their router: (steps from CHATGPT)
			Step 1. Find your local IPv4 address
				On the HOST computer:
					Open Command Prompt and run: ipconfig
					Look for: IPv4 Address. . . . . . . . . . : 192.168.x.x
					Example: 192.168.1.42
					This is your LOCAL IP. You will need it for port forwarding.
			Step 2. Log into your router
				Usually visit one of these in a browser:
					192.168.1.1
					192.168.0.1
					10.0.0.1
				Common router brands:
					Netgear
					TP-Link
					ASUS
					Linksys
					Xfinity routers
				If you do not know the login:
					check the sticker on the router or search the router model
			Step 3. Find “Port Forwarding”
				Usually under:
					Advanced/NAT/Firewall/Gaming/Virtual Servers
					Names vary by router.
			Step 4. Create a port forwarding rule
				Create:
					SETTING			VALUE
					Service Name		GodotGame
					Protocol			UDP (Not TCP)
					External Port	42069
					Internal Port	42069
					Internal IP		your local IPv4
