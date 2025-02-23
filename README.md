I made this little game prototype to practice mobile game development, networked multiplayer game development, and also to get more comfortable with the Godot game engine.

Players engage in a fight to the death, swinging around using grappling hooks and firing their rocket launchers. The grappling hooks are rubberband-like, slinging the players around at great speeds. This was inspired by an old favorite of mine called Liero.

To keep things simple, I chose the mechanics so that though the players have fluid movement, they are limited to using a grappling hook to mvoe around. This means that their actions are discrete, which is easier to deal with over the network.

I implemented touchscreen joysticks; one for grappling hook and another one for shooting. Pressing your finger down near the joystick activates it, setting that point on the screen as the center of the joystick. When the player releases the joystick, the action is executed, or if the joystick is near its center point, nothing happens for shooting, and for the grappling hook, any existing grappling hook is detached.

For scalability, I made the game itself maintain a consistently-sized view so that having a bigger screen resolution doesn't mean you see more of the game world. The UI however stays more or less the same size, as I didn't want the joysticks to become huge on a larger tablet screen. This is likely not a sufficient solution as it depends on screen PPI, but at least works as a proof of concept on the UI scaling independently of the game camera, and seems to work reasonably well on the devices I used for testing.

The network code is using the ENet integration in Godot, and uses remote procedure calls for passing data between peers. Clients essentially send their inputs to the server and other clients, and the server sends back accurate game state information, though the clients do also run the game simulation at the same time. The clients also send ping messages to the server to measure network latency and calibrate their game clocks. Each client maintains their own clock that approximates the server clock. Game state events are sent with timestamps, which are used to catch the client simulation up to where the server is expected to be by the time the event arrives on the client.

All the art assets are CC0 and from [kenney.nl](https://kenney.nl/)
