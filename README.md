
# LIT - Love Input Tool

Input capture compatible with controllers. Divides input into "digital" and
"analogic", and creates a layer of abstraction so you can worry about only
inputs that are used within your game.

It has a save/load feature for your custom inputs! Nice!

It also comes with a simple interface for configuring these custom inputs.
Of course, for your own game, you might want to create your own interface,
but hopefully it shows you how is it that it allows both joystick and keyboard.

A simple testing example is given. To see what I mean, you can clone this
repository in a subdirectory named `input` of a love game folder, and add
a `main.lua` file that only requires `input.example` to see what I mean.
Then run that. If your controller isn't recognizing the analogic input, you
can try to reconfigure all inputs by pressing `F1`. See what happens!

