## Bouncing Balls

This "version" of Edwin has led me to create Ricochet which you can see here:

https://giphy.com/gifs/8eNM74lYc0qnkWx4hP/html5

# Edwin

Edwin is a (beta!) library for [Processing Java](processing.org/download/) that essentially lets you have layers in Processing so you can run multiple sketches at once. Edwin is a god class that requires you to encapsulate your sketch in a class that gets its own draw, mouse, and keyboard functions. Edwin takes over executing Processing, so it hijacks mouseMoved() and all functions like it! All you need to do is encapsulate your sketch in a class and have that implement my interface Kid

```java
interface Kid {
    void draw(PGraphics canvas); 
    String mouse(); 
    String keyboard(KeyEvent event);
}
```

The mouse() and keyboard() functions are called for every event, so you need to route accordingly. They return a String so that they can communicate backwards to whoever called it (meaning Kids can have their own Kids). Edwin also has a series of helper variables to let you determine the state of the mouse -- `if (edwin.mouseBtnReleased == RIGHT) ...`. See the source and my provided classes for examples. **Edwin also handles beginDraw() and endDraw() on the canvas so do not call them in your class, just do your drawing.**

The only file out of all these that you absolutely need is Edwin_v2_2a.pde. A simple Kid class (with some built-in stuff) might look like this

```java
class Simple implements Kid {
    Album buttons; //Albums do not have coordinates, they're like a condensed spritesheet
    RectBody buttonBody; //we'll use this RectBody to track the image's body when drawn

    Simple() {
        buttons = new Album(GadgetPanel.BUTTON_FILENAME);
        buttonBody = new RectBody(80, 20, buttons.w, buttons.h);
    }

    void draw(PGraphics canvas) {
        canvas.image(buttons.page(GadgetPanel.OK), buttonBody.x, buttonBody.y);
    }

    String mouse() {
        if (edwin.mouseBtnReleased == LEFT && buttonBody.isMouseOver()) {
            println("Button clicked");
        }
        return "";
    }

    String keyboard(KeyEvent event) {
        return "";
    }
}
```

Then take the file EdwinGerm.pde and do some simple initializing like so

```java
Edwin edwin;

void setup() {
    size(800, 800);
    edwin = new Edwin();
    edwin.addKid(new Simple()); 
}

void draw() {
    edwin.think();
    image(edwin.canvas, 0, 0);
}

```

Feel free to rename EdwinGerm.pde (and the folder it's in!) to whatever your project is. If you're interested in trying out this library and have questions just ask

moonbaseone@hush.com

/u/mercurus_


## Albums and Pages...

I made my own sprite/tile editor called AlbumEditor which is very much still in beta. I'm trying to make it easy to create one sprite plus all its animations and colors schemes in one package. Feel free to play around with it but I'm not going to write up instructions yet since it's likely to change in the future. 

At the moment, besides encapsulating sketches, probably the most helpful class is BoundedInt. It's for keeping track of a number that has a minimum and maximum, and can handle incrementing and stuff for you. That way you don't need to keep track of the value, min, max, step, etc using individual variables.


## Old version of LightLattice helped me produce this:

https://gfycat.com/cluelessinfiniteamericanindianhorse

Shout out to this guy for the mushroom

https://sketchfab.com/3d-models/low-poly-mushroom-d70cf47f89804e26a63d37f5224dcfd4

And this site for easy color schemes

https://coolors.co/dce6ed-9ac5ea-3176bc-134372-05162b


## StarWebPositioner helped me produce this:

https://gfycat.com/pitifuluntidydowitcher-generative-art-processing-java