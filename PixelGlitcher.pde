/**
* Decorator class for applying a filter to a Kid
*/
class PixelGlitcher implements Kid {
    PGraphics myCanvas;
    Kid child;
    boolean enabled;

    PixelGlitcher(Kid kid) { this(kid, true); }
    PixelGlitcher(Kid kid, boolean startEnabled) {
        child = kid;
        enabled = startEnabled;
        myCanvas = createGraphics(width, height);
        myCanvas.beginDraw();
        myCanvas.textFont(edwin.defaultFont);
        myCanvas.endDraw();
    }

    void draw(PGraphics canvas) {
        myCanvas.beginDraw();
        myCanvas.clear();
        child.draw(myCanvas);
        if (enabled) {
            myCanvas.loadPixels();
            boolean offset = false;
            int loopCounter = 0;
            for (int i = 0; i < myCanvas.pixels.length; i++) {
                if (myCanvas.pixels[i] == 0) continue;
                //if (i % width == 0) offset = !offset;
                if (loopCounter++ % 5 == 0) offset = !offset;
                if (offset) myCanvas.pixels[i] = color(myCanvas.pixels[i], 100);
            }
            myCanvas.updatePixels();
        }
        myCanvas.endDraw();
        canvas.image(myCanvas, 0, 0);
    }

    String mouse() {
        return child.mouse();
    }

    String keyboard(KeyEvent event) {
        if (event.getAction() == KeyEvent.RELEASE && event.getKeyCode() == Keycodes.G) { //not case sensitive
            enabled = !enabled;
        }
        return child.keyboard(event);
    }
}
