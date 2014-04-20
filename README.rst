Polaris is a Minetest_ mod that makes Minetest into a game about navigation. Polaris puts you in a randomly generated world, then guides you to a handful of randomly selected locations ("waypoints") and requires you to find your way back to them unaided within a time limit. If you like running through forests and leaping across hills at breakneck speeds while trying not to get lost, Polaris is for you!

How to play
============================================================

First compile the MoonScript files to Lua. If you have MoonScript installed, the command ``moonc FILE`` will suffice; otherwise, use `the online compiler`__. `Install the mod`_ with the name "polaris" (Minetest will complain if you use a capital letter). Then create a new world, enable the mod, and start a single-player game. Creative mode should be off, but damage is optional.

..
__ http://moonscript.org/compiler/

When you begin the game, you'll get a few useful items, and you'll see a timer and information about how to get to the first waypoint like this:

.. image:: http://i.imgur.com/JOfAF60.png

Here the heads-up display says that the next waypoint is waypoint number 1, and it's 57 meters (i.e., node-lengths) away (on the X-Z plane; i.e., as the crow flies) and 113 degrees to the right. Travel to the waypoint. Notice that in Polaris, you can run much faster and jump somewhat higher than normal (high enough to jump on top of a two-block column). The waypoint is an ordinary chunk of ground, but for now (as long as your compass points to it), you can see it easily because rainbows are constantly shooting out of it:

.. image:: http://i.imgur.com/NUFlm4N.png

Punch the waypoint to tell the game you've found it. You will then be asked to find a new waypoint (the rainbows will stop shooting out of this one, and your heads-up display will guide you to the new one). Later, you will be asked to find an old waypoint: the direction and distance indicators will disappear, and there won't be any rainbows at your destination, so you'll need to use your own sense of direction and any landmarks or shortcuts you've built yourself. As the game continues, you'll need to find waypoints both old and new. There's a small time bonus each time you find a waypoint, and you'll receive a prize for every few waypoints you find. Try to find as many waypoints as you can before running out of time.

Note that waypoints are locations, not blocks. If you destroy the block at a waypoint, making it unpunchable, you can restore the waypoint to punchability by placing a new block there.

You don't have to worry about nightfall. Daylight is enforced during Polaris.

To make the game easier or harder, see the top of the code for some parameters to tweak.

Caveats
============================================================

- Sometimes, waypoints are created in an air node. This is a bug; it might have to do with sand blocks falling after they're generated. As always, you can make the waypoint punchable by placing a block at its position.

- There isn't much control exerted on the difficulty of the game. For example, it's possible to get a very easy game if all your waypoints are generated in a big lake.

- Multiplayer is not implemented.

- You can't save, in the sense that if you quit Minetest during a game of Polaris and then return to the world (without disabling the mod), things will get screwed up (e.g., the current waypoint will be reset to 1). Polaris is meant to be played in one sitting, anyway.

- Similarly, you can't play Polaris with an existing world, only a new one for which you have Polaris enabled from the start. This is because waypoints are only created inside a ``minetest.register_on_generated`` callback.

License
============================================================

Textures are licensed under a `Creative Commons Attribution-ShareAlike 4.0 International License`_.

This program is copyright 2014 Kodi Arfer.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the `GNU Lesser General Public License`_ for more details.

.. _Minetest: http://minetest.net
.. _`Install the mod`: http://wiki.minetest.net/Installing_Mods
.. _`Creative Commons Attribution-ShareAlike 4.0 International License`: http://creativecommons.org/licenses/by-sa/4.0/
.. _`GNU Lesser General Public License`: http://www.gnu.org/licenses/
