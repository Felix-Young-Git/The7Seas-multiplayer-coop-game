 THIS IS THE README FOR THE MULTIPLAYER COOP GAME The7seas

Automated Testing Tool:
- Several of the files and 2 of the folders are not related to the game but instead to testing. 
- The tool checks that the functions that will test the game files work correctly, and tests the game files every time a new commit is pushed to the repo.
- The tests include: Checking file names, image sizes, and references.
- I added this because I wanted to learn more about testing and I wanted my game naming, file references, and art assets to be consistent, and for all of this to be flagged in an automated way.
- The first time I ran the tests on the game I found MANY issues, so this was legitimately helpful. 






To play the game (in godot):

	- Currently, when running the game, godot runs 2 instances of the game, to turn this off go to
	  debug, then to custimaize run instances, then set to 1

	- The host can just press the Host button and the client can press the join button, or, if you want a 
	private lobby then the host puts in a code and then presses the Host button, and then the client puts 
	the same code in the join textbox and presses the join button.
