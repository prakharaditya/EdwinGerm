/**
* Edwin
* v2.2 alpha
*
* Edwin is a god class that essentially allows you to have layers in Processing.
* Each "layer" class must implement Kid in order to be compatible with Edwin and 
* added to Edwin in setup() (or dynamically from your Scheme or whatever) using addKid().
* Each Kid class gets its own draw, mouse, and keyboard functions so you don't have to
* flood the ones provided by Processing. That means Edwin hijacks mouseMoved() and all like it!
* To use the editor make sure to include edwin.addKid(new AlbumEditor()); in your setup()
* Feel free to edit anything and everything in here.
* For a small example project see the comment below the Edwin class
*
* Made by mercurus - moonbaseone@hush.com
*/

import java.util.Arrays;
import java.util.BitSet;
import java.util.Collections;
import java.awt.Color;
import javax.swing.JColorChooser;
import javax.swing.JOptionPane;

void keyPressed(KeyEvent event) { edwin.handleKeyboard(event); }
void keyReleased(KeyEvent event) { edwin.handleKeyboard(event); }
void mouseMoved(MouseEvent event) { edwin.handleMouse(event); }
void mousePressed(MouseEvent event) { edwin.handleMouse(event); }
void mouseDragged(MouseEvent event) { edwin.handleMouse(event); }
void mouseReleased(MouseEvent event) { edwin.handleMouse(event); }
void mouseWheel(MouseEvent event) { edwin.handleMouse(event); }

/**
* I started off trying to implement an Entity Component System.
* So far Components haven't been useful for me so they're gone
* and I've renamed Entities to Kids, and Systems to Schemes.
* The rules aren't very fixed - from this base you can go in many directions
*/
interface Kid {
	//void think(); //called before drawSelf()
	void drawSelf(PGraphics canvas);
	String getName(); //might not be useful, may remove
	String mouse(); //returns a String so it can communicate backwards to whoever called it
	String keyboard(KeyEvent event);
}

/**
* These are intended to give you a way to manipulate Kids and have them talk to each other.
* Create your Scheme class and add it to Edwin similar to adding Kids - edwin.addScheme(new MyScheme());
* All Schemes are called in edwin.think() before the Kids
*/
interface Scheme {
	void play(ArrayList<Kid> kids);
}

/**
* Singleton that you add Kids and Schemes to. It's a fairly small class really
*/
class Edwin {
	PGraphics canvas;
	PFont defaultFont;
	ArrayList<Kid> kids, dismissed;
	ArrayList<Scheme> schemes;
	//now for some values you might check in your Kid classes
	XY mouseHoldInitial, mouseLast;
	int mouseHoldStartMillis, mouseHeldMillis, mouseTickLength, mouseTicking;
	int mouseBtnBeginHold, mouseBtnHeld, mouseBtnReleased, mouseWheelValue;
	boolean useSmooth, mouseHoldTicked, mouseHovering, isShiftDown;

	Edwin() {
		canvas = createGraphics(width, height);
		defaultFont = createFont(EdFiles.DATA_FOLDER + "consolas.ttf", 12); //not necessary to have
		schemes = new ArrayList<Scheme>();
		kids = new ArrayList<Kid>();
		dismissed = new ArrayList<Kid>(); //in a Scheme if some Kid needs to leave use edwin.dismiss(kid);
		mouseHoldInitial = new XY();
		mouseLast = new XY();
		mouseHeldMillis = mouseHoldStartMillis = mouseTicking = 0;
		mouseBtnHeld = mouseBtnBeginHold = mouseBtnReleased = mouseWheelValue = 0;
		useSmooth = true; //use Processing's built-in smooth() or noSmooth()
		mouseHovering = false; //true if the mouse event is a plain move
		mouseHoldTicked = false; //true for one drawSelf() tick every couple ms when you've been holding down a mouse button
		isShiftDown = false;
		mouseTickLength = 17; //number of cycles between ticks
	}

	void addScheme(Scheme scheme) {
		schemes.add(scheme);
	}

	void addKid(Kid kid) {
		kids.add(kid);
	}

	/** Use this in Schemes to safely remove Kids */
	void dismiss(Kid kid) {
		dismissed.add(kid);
	}

	void think() {
		if (mouseBtnHeld != 0) {
			mouseHeldMillis = millis() - mouseHoldStartMillis; //gives a more reliable figure than using mouse events to update
			if (++mouseTicking > mouseTickLength) {
				mouseTicking = 0;
				mouseHoldTicked = true;
			}
		}

		for (Scheme scheme : schemes) {
			scheme.play(kids);
		}
		for (Kid kid : dismissed) {
			kids.remove(kid);
		}
		dismissed.clear();

		//draw the family
		if (useSmooth) canvas.smooth();
		else canvas.noSmooth();
		canvas.beginDraw();
		canvas.background(EdColors.DEFAULT_BACKGROUND);
		canvas.textFont(defaultFont);
		for (Kid kid : kids) {
			//kid.think();
			kid.drawSelf(canvas);
		}
		canvas.endDraw();
		mouseHoldTicked = false;
	}

	void handleMouse(MouseEvent event) {
		boolean resetMouse = false;
		int action = event.getAction();
		if (action == MouseEvent.PRESS) {
			mouseHoldInitial.set(mouseX, mouseY);
			mouseBtnBeginHold = mouseBtnHeld = event.getButton();
			mouseHoldStartMillis = millis();
			mouseBtnReleased = 0;
		}
		else if (action == MouseEvent.RELEASE) {
			mouseBtnReleased = mouseBtnHeld;
			mouseBtnBeginHold = mouseBtnHeld = 0;
			resetMouse = true; //other resets need to happen after calling each Kid so they can use the values first
		}
		else if (action == MouseEvent.DRAG) {
			mouseBtnBeginHold = 0;
		}
		else if (action == MouseEvent.WHEEL) {
			mouseWheelValue = event.getCount(); // 1 == down (toward you), -1 == up (away from you)
		}
		else if (action == MouseEvent.MOVE) {
			mouseHovering = true;
		}

		//notify the kids
		for (Kid kid : kids) {
			//if (kid.mouse() != "") break; //if any respond we assume it handled the event and we don't need to check others
			//if (kid.mouse() != "") println(kid.mouse());
			kid.mouse();
		}

		//wrap up
		if (resetMouse) {
			mouseHeldMillis = mouseBtnReleased = mouseTicking = 0;
			//mouseHoldInitial.set(mouseX, mouseY);
		}
		mouseLast.set(mouseX, mouseY);
		mouseWheelValue = 0;
		mouseHovering = false;
	}

	/**
	* Keyboard interactions are complicated
	* so each Kid will get handed the event and let them react
	*/
	void handleKeyboard(KeyEvent event) {
		if (event.isShiftDown()) isShiftDown = true;
		else isShiftDown = false;
		for (Kid kid : kids) {
			//if (kid.keyboard(event) != "") break; //if any respond we assume it handled the event and we don't need to check others
			kid.keyboard(event);
		}
	}
} //end Edwin



/*** An example new project using Edwin:

Edwin edwin;
int aNum = 0;

void setup() {
	size(800, 600);
	edwin = new Edwin();

	String[] buttons = new String[] { AlbumEditor.BRUSH, AlbumEditor.LINE, AlbumEditor.PERIMETER, AlbumEditor.ADD_LAYER, AlbumEditor.ZOOM_OUT };
	Kid someMenu = new GridButtons(20, 80, 3, new Album(AlbumEditor.TOOL_MENU_FILENAME, 2.0), buttons) {
		@Override
		public void buttonClick(String clicked) {
			aNum += 1;
			println(clicked + " " + aNum);
		}
	};

	edwin.addKid(someMenu);
	edwin.addKid(new Simple());
}

void draw() {
	edwin.think();
	image(edwin.canvas, 0, 0);
}

class Simple implements Kid {
	Album buttons; //Albums do not have coordinates, they're like a condensed spritesheet
	RectBody buttonBody; //we'll use this RectBody to track the image's body when drawn

	Simple() {
		buttons = new Album(GadgetPanel.BUTTON_FILENAME);
		buttonBody = new RectBody(80, 20, buttons.w, buttons.h);
	}

	void drawSelf(PGraphics canvas) {
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

	String getName() {
		return "Simple";
	}
}

***/



// ===================================
// HELPERS
// ===================================

/** Simple class for holding coordinates */
class XY {
	float x, y;
	XY() { set(0, 0); }
	XY(float _x, float _y) { set(_x, _y); }
	XY clone() { return new XY(x, y); }
	String toString() { return "[x:" + x + " y:" + y + "]"; }
	String toStringInt() { return "[x:" + (int)x + " y:" + (int)y + "]"; }
	boolean equals(XY other) { return equals(other.x, other.y); }
	boolean equals(float _x, float _y) { return (x == _x && y == _y); }
	void set(XY other) { set(other.x, other.y); }
	void set(float _x, float _y) { x = _x; y = _y; }
	float distance(XY other) { return distance(other.x, other.y); }
	float distance(float _x, float _y) { return sqrt(pow(x - _x, 2) + pow(y - _y, 2)); }
	float angSin(XY other) { return sin(angle(other)); }
	float angCos(XY other) { return cos(angle(other)); }
	float angle(XY other) { return angle(other.x, other.y); }
	float angle(float _x, float _y) { return atan2(y - _y, x - _x); } //radians
	XY midpoint(float _x, float _y) { return new XY((x + _x) / 2.0, (y + _y) / 2.0); }
	XY midpoint(XY other) { return midpoint(other.x, other.y); }
}



/**
* A class for rectangle coordinates. Stores the top-left xy anchor, 
* width and height, plus a handful of helper functions.
* x and y are declared in the parent class XY
* I do this to demonstrate inheritance, not because I'm hopelessly addicted to OOP
*/
class RectBody extends XY {
	float w, h;
	RectBody() { set(0, 0, 0, 0); }
	RectBody(float _x, float _y, float _w, float _h) { set(_x, _y, _w, _h); }
	RectBody clone() { return new RectBody(x, y, w, h); }
	String toString() { return "[x:" + x + " y:" + y + " | w:" + w + " h:" + h + "]"; }
	boolean equals(RectBody other) { return equals(other.x, other.y, other.w, other.h); }
	boolean equals(float _x, float _y, float _w, float _h) { return (x == _x && y == _y && w == _w && h == _h); }
	void set(RectBody other) { set(other.x, other.y, other.w, other.h); }
	void set(float _x, float _y, float _w, float _h) { x = _x; y = _y; w = _w; h = _h; }
	void setSize(RectBody other) { setSize(other.w, other.h); }
	void setSize(float _w, float _h) { w = _w; h = _h; }

	/** Returns the x coordinate plus the width, the right boundary */
	float xw() { return x + w; }

	/** Returns the y coordinate plus the height, the bottom boundary */
	float yh() { return y + h; }
	
	/** Returns true if the incoming body overlaps this one */
	boolean intersects(RectBody other) {
		if (other.xw() >= x && other.x <= xw() &&
			other.yh() >= y && other.y <= yh()) {
			return true;
		}
		return false;
	}

	/** Takes a x coordinate and gives you the closest value inbounds */
	float insideX(float _x) {
		if (_x < x) {
			return x;
		}
		else if (_x >= xw()) {
			return xw();
		}
		return _x;
	}

	/** Takes a y coordinate and gives you the closest value inbounds */
	float insideY(float _y) {
		if (_y < y) {
			return y;
		}
		else if (_y >= yh()) {
			return yh();
		}
		return _y;
	}

	/** Returns true if the mouse is inbounds */
	boolean isMouseOver() { return containsPoint(mouseX, mouseY); }
	boolean containsPoint(XY other) { return containsPoint(other.x, other.y); }
	boolean containsPoint(float _x, float _y) {
		if (_x >= x && _x < xw() &&
			_y >= y && _y < yh()) {
			return true;
		}
		return false;
	}

	// NestedRectBody newChild() { newChild(0, 0, 0, 0); }
	// NestedRectBody newChild(float _x, float _y, float _w, float _h) {
	// 	return new NestedRectBody(this, _x, _y, _w, _h);
	// }
}



/**
* These are supposed to be children of a RectBody
* and are useful for mouse events because it can have contents assuming an origin of 0,0
* but then know its parent's xy offset when calculating isMouseOver() 
* and if you want the thing to move around it can know if it's inside its parent.
* Not intended to have any children of its own, not even sure if nesting more would work.
* see AlbumEditor for example usage
*/
class NestedRectBody extends RectBody {
	RectBody parent;
	NestedRectBody(RectBody parentBody) {
		super(); //call constructor from RectBody
		parent = parentBody;
	}
	NestedRectBody(RectBody parentBody, float _x, float _y, float _w, float _h) {
		super(_x, _y, _w, _h);
		parent = parentBody;
	}
	@Override
	boolean containsPoint(float _x, float _y) {
		_x -= parent.x;
		_y -= parent.y;
		if (_x >= x && _x < xw() &&
			_y >= y && _y < yh()) {
			return true;
		}
		return false;
	}
	float realX()  { return parent.x + x; }
	float realXW() { return parent.x + x + w; }
	float realY()  { return parent.y + y; }
	float realYH() { return parent.y + y + h; }
}



/** A class for keeping track of an integer that has a minimum and a maximum. */
class BoundedInt {
	int value, minimum, maximum, step;
	boolean isEnabled, loops;
	BoundedInt(int newMax) { this(0, newMax); }
	BoundedInt(int newMin, int newMax) { this(newMin, newMax, newMin); }
	BoundedInt(int newMin, int newMax, int num) { this(newMin, newMax, num, 1); }
	BoundedInt(int newMin, int newMax, int num, int increment) {
		reset(newMin, newMax, num);
		step = increment; //amount to inc/dec each time
		loops = false; //if you increment() at max then value gets set to min, and vice versa
		isEnabled = true; //something you can use if you want
	}
	BoundedInt clone() { BoundedInt schwarzenegger = new BoundedInt(minimum, maximum, value, step); schwarzenegger.loops = loops; schwarzenegger.isEnabled = isEnabled; return schwarzenegger; }
	String toString() { return "[min:" + minimum + "|max:" + maximum + "|val:" + value + "]"; }
	void set(int num) { value = min(max(minimum, num), maximum); } //assign value to num, or to minimum/maximum if it's out of bounds
	void reset(int newMin, int newMax) { reset(newMin, newMax, newMin); }
	void reset(int newMin, int newMax, int num) { minimum = newMin; maximum = newMax; value = num; }
	boolean contains(int num) { return (num >= minimum && num <= maximum); }
	boolean atMin() { return (value == minimum); }
	boolean atMax() { return (value == maximum); }
	int randomize() { value = (int)random(minimum, maximum + 1); return value; } //+1 here because the max of random() is exclusive
	int minimize() { value = minimum; return value; }
	int maximize() { value = maximum; return value; }

	int increment() { return increment(step); }
	int increment(int num) {
		if (value + num > maximum) {
			if (loops) value = minimum;
			else value = maximum;
			return value;
		}
		value += num;
		return value;
	}

	int decrement() { return decrement(step); }
	int decrement(int num) {
		if (value - num < minimum) {
			if (loops) value = maximum;
			else value = minimum;
			return value;
		}
		value -= num;
		return value;
	}

	int incrementMin() { return incrementMin(step); }
	int incrementMin(int num) { return setMin(minimum + num); }
	int decrementMin() { return decrementMin(step); }
	int decrementMin(int num) { return setMin(minimum - num); }
	int setMin(int newMin) {
		if (newMin > maximum) {
			minimum = maximum;
			return minimum;
		}
		minimum = newMin;
		value = max(minimum, value);
		return minimum;
	}

	int incrementMax() { return incrementMax(step); }
	int incrementMax(int num) { return setMax(maximum + num); }
	int decrementMax() { return decrementMax(step); }
	int decrementMax(int num) { return setMax(maximum - num); }
	int setMax(int newMax) {
		if (newMax < minimum) {
			maximum = minimum;
			return maximum;
		}
		maximum = newMax;
		value = min(maximum, value);
		return maximum;
	}
}



/** A class for keeping track of a floating point decimal that has a minimum and a maximum. */
class BoundedFloat {
	float value, minimum, maximum, step;
	boolean isEnabled, loops;
	BoundedFloat(float newMax) { this(0, newMax); }
	BoundedFloat(float newMin, float newMax) { this(newMin, newMax, newMin); }
	BoundedFloat(float newMin, float newMax, float num) { this(newMin, newMax, num, 1); }
	BoundedFloat(float newMin, float newMax, float num, float increment) {
		reset(newMin, newMax, num);
		step = increment; //amount to inc/dec each time
		loops = false; //if you increment() at max then value gets set to min, and vice versa
		isEnabled = true; //something you can use if you want
	}
	BoundedFloat clone() { BoundedFloat schwarzenegger = new BoundedFloat(minimum, maximum, value, step); schwarzenegger.loops = loops; schwarzenegger.isEnabled = isEnabled; return schwarzenegger; }
	String toString() { return "[min:" + minimum + "|max:" + maximum + "|val:" + value + "]"; }
	void set(float num) { value = min(max(minimum, num), maximum); } //assign value to num, or to minimum/maximum if it's out of bounds
	void reset(float newMin, float newMax) { reset(newMin, newMax, newMin); }
	void reset(float newMin, float newMax, float num) { minimum = newMin; maximum = newMax; value = num; }
	boolean contains(float num) { return (num >= minimum && num <= maximum); }
	boolean atMin() { return value == minimum; }
	boolean atMax() { return value == maximum; }
	float randomize() { value = random(minimum, maximum); return value; }
	float minimize() { value = minimum; return value; }
	float maximize() { value = maximum; return value; }

	float increment() { return increment(step); }
	float increment(float num) {
		if (value + num > maximum) {
			if (loops) value = minimum;
			else value = maximum;
			return value;
		}
		value += num;
		return value;
	}

	float decrement() { return decrement(step); }
	float decrement(float num) {
		if (value - num < minimum) {
			if (loops) value = maximum;
			else value = minimum;
			return value;
		}
		value -= num;
		return value;
	}

	float incrementMin() { return incrementMin(step); }
	float incrementMin(float num) { return setMin(minimum + num); }
	float decrementMin() { return decrementMin(step); }
	float decrementMin(float num) { return setMin(minimum - num); }
	float setMin(float newMin) {
		if (newMin > maximum) {
			minimum = maximum;
			return minimum;
		}
		minimum = newMin;
		value = max(minimum, value);
		return minimum;
	}

	float incrementMax() { return incrementMax(step); }
	float incrementMax(float num) { return setMax(maximum + num); }
	float decrementMax() { return decrementMax(step); }
	float decrementMax(float num) { return setMax(maximum - num); }
	float setMax(float newMax) {
		if (newMax < minimum) {
			maximum = minimum;
			return maximum;
		}
		maximum = newMax;
		value = min(maximum, value);
		return maximum;
	}
}



/**
* Basically a callback function
*/
class Command {
	void execute(String arg) {
		println("uh oh, empty Command object [arg=" + arg + "]");
	}
}



/** 
* Give this function an octave count and it will give you perlin noise
* with the max number of points you can have with that number of octaves.
* Values will be between 0 and 1
* See https://www.youtube.com/watch?v=6-0UaeJBumA
*/
float[] perlinNoise1D(int octaves) {
	int count, pitch, sample1, sample2;
	float noiseVal, scale, scaleAcc, scaleBias, blend;
	count = (int)pow(2, octaves);
	scaleBias = 2.0; //2 is standard. lower = more pronounced peaks

	float[] seedArray = new float[count];
	for (int i = 0; i < seedArray.length; i++) {
		seedArray[i] = random(1);
	}

	float[] values = new float[count];
	for (int x = 0; x < count; x++) {
		scale = 1;
		scaleAcc = 0;
		noiseVal = 0;
		for (int o = 0; o < octaves; o++) {
			pitch = count >> o;
			sample1 = (x / pitch) * pitch;
			sample2 = (sample1 + pitch) % count;
			blend = (x - sample1) / (float)pitch;
			noiseVal += scale * ((1 - blend) * seedArray[sample1] + blend * seedArray[sample2]);
			scaleAcc += scale;
			scale /= scaleBias;
		}
		values[x] = noiseVal / scaleAcc;
		//println(values[x]);
	}
	//println("len:" + values.length + ",  first:" + values[0] + ",  last:" + values[values.length - 1]);
	return values;
}

/** broken? tint should probably be between -1.0 and 1.0 */
int colorTint(int colr, float tint) {
	float r = colr >> 16 & 0xFF, //see https://processing.org/reference/red_.html
		g = colr >> 8 & 0xFF, //https://processing.org/reference/green_.html
		b = colr & 0xFF; //https://processing.org/reference/blue_.html
	r = max(0, min(255, r + (r * tint)));
	g = max(0, min(255, g + (g * tint)));
	b = max(0, min(255, b + (b * tint)));
	return color(r, g, b);
}

/** returns your JSON key and value as "key":value, */
String jsonKV(String keyName, int value) { return jsonKV(keyName, String.valueOf(value)); }
String jsonKV(String keyName, float value) { return jsonKV(keyName, String.valueOf(value)); }
String jsonKV(String keyName, boolean value) { return jsonKV(keyName, String.valueOf(value)); }
String jsonKV(String keyName, String value) { return jsonKVNoComma(keyName, value + ","); }
String jsonKVString(String keyName, String value) { return jsonKVNoComma(keyName, "\"" + value + "\","); }
String jsonKVNoComma(String keyName, String value) { return "\"" + keyName + "\":" + value; }



/** Constants */
final String TAB = "\t";

class EdColors {
	//Edwin VanCleef https://media-hearth.cursecdn.com/avatars/331/109/3.png
	//https://lospec.com/palette-list/dirtyboy
	public static final int DEFAULT_BACKGROUND = #070403, // #000000
	UI_LIGHT = #C4CFA1, 
	UI_NORMAL = #8B956D, 
	UI_DARK = #4D533C,
	UI_DARKEST = #1F1F1F,
	UI_EMPHASIS = #73342E,
	INFO = #5881C1,
	ROW_EVEN = #080808,
	ROW_ODD = #303030;
	/*
	UI_LIGHT = #FFFFFF, 
	UI_NORMAL = #AAE0F2, 
	UI_DARK = #2E6D99,
	UI_DARKEST = #26241F,
	*/
}

/** JSON keys for Album files */
class EdFiles {
	public static final String DATA_FOLDER = "data\\",
	BGD_COLOR = "backgroundColor",
	PX_WIDTH = "width",
	PX_HEIGHT = "height",
	DOTS = "dots",
	PIXEL_LAYERS = "pixelLayers",
	COLOR_PALETTE = "colorPalette",
	PALETTE_INDEX = "paletteIndex",
	TRANSPARENCY = "transparency",
	PIXEL_LAYER_NAME = "pixelLayerName",
	ALBUM_PAGES = "albumPages",
	PAGE_NAME = "pageName",
	LAYER_NUMBERS = "layerNumbers";
}

/**
* Ripped from Java's KeyEvent -- https://docs.oracle.com/javase/8/docs/api/constant-values.html
* Gives finer control over keyboard input. I think Processing cut these out to save on space (probably)
* but also simplified things with their global variables "key" and "keyCode"
* see https://processing.org/reference/keyCode.html
*/
class Keycodes {
	public static final int VK_UNDEFINED = 0,
	VK_TAB = 9,
	VK_SHIFT = 16, //probably easier to use event.isShiftDown(), event.isAltDown(), event.isControlDown()
	VK_CONTROL = 17,
	VK_ALT = 18,
	VK_LEFT = 37,
	VK_UP = 38,
	VK_RIGHT = 39,
	VK_DOWN = 40,
	VK_0 = 48,
	VK_1 = 49,
	VK_2 = 50,
	VK_3 = 51,
	VK_4 = 52,
	VK_5 = 53,
	VK_6 = 54,
	VK_7 = 55,
	VK_8 = 56,
	VK_9 = 57,
	VK_A = 65,
	VK_B = 66,
	VK_C = 67,
	VK_D = 68,
	VK_E = 69,
	VK_F = 70,
	VK_G = 71,
	VK_H = 72,
	VK_I = 73,
	VK_J = 74,
	VK_K = 75,
	VK_L = 76,
	VK_M = 77,
	VK_N = 78,
	VK_O = 79,
	VK_P = 80,
	VK_Q = 81,
	VK_R = 82,
	VK_S = 83,
	VK_T = 84,
	VK_U = 85,
	VK_V = 86,
	VK_W = 87,
	VK_X = 88,
	VK_Y = 89,
	VK_Z = 90,
	VK_NUMPAD0 = 96,
	VK_NUMPAD1 = 97,
	VK_NUMPAD2 = 98,
	VK_NUMPAD3 = 99,
	VK_NUMPAD4 = 100,
	VK_NUMPAD5 = 101,
	VK_NUMPAD6 = 102,
	VK_NUMPAD7 = 103,
	VK_NUMPAD8 = 104,
	VK_NUMPAD9 = 105,
	VK_F1 = 112,
	VK_F2 = 113,
	VK_F3 = 114,
	VK_F4 = 115,
	VK_F5 = 116,
	VK_F6 = 117,
	VK_F7 = 118,
	VK_F8 = 119,
	VK_F9 = 120,
	VK_F10 = 121,
	VK_F11 = 122,
	VK_F12 = 123,
	VK_PAGE_UP = 33,
	VK_PAGE_DOWN = 34,
	VK_END = 35,
	VK_HOME = 36,
	VK_DELETE = 127,
	VK_INSERT = 155,
	VK_BACK_SPACE = 8,
	VK_ENTER = 10,
	VK_ESCAPE = 27,
	VK_SPACE = 32,
	VK_CAPS_LOCK = 20,
	VK_NUM_LOCK = 144,
	VK_SCROLL_LOCK = 145,
	VK_AMPERSAND = 150,
	VK_ASTERISK = 151,
	VK_BACK_QUOTE = 192,
	VK_BACK_SLASH = 92,
	VK_BRACELEFT = 161,
	VK_BRACERIGHT = 162,
	VK_CLEAR = 12,
	VK_CLOSE_BRACKET = 93,
	VK_COLON = 513,
	VK_COMMA = 44,
	VK_CONVERT = 28,
	VK_DECIMAL = 110,
	VK_DIVIDE = 111,
	VK_DOLLAR = 515,
	VK_EQUALS = 61,
	VK_SLASH = 47,
	VK_META = 157,
	VK_MINUS = 45,
	VK_MULTIPLY = 106,
	VK_NUMBER_SIGN = 520,
	VK_OPEN_BRACKET = 91,	
	VK_PERIOD = 46,
	VK_PLUS = 521,	
	VK_PRINTSCREEN = 154,
	VK_QUOTE = 222,
	VK_QUOTEDBL = 152,
	VK_RIGHT_PARENTHESIS = 522,	
	VK_SEMICOLON = 59,
	VK_SEPARATOR = 108,
	VK_SUBTRACT = 109;
}



// ===================================
// DEFAULT KIDS
// ===================================

/** 
* A kind of sprite sheet that is made by my tile editor AlbumEditor.
* Albums have one set of pixel layers, and another set of "pages" that use 
* any number of those pixel layers to create an image. Also requires a 
* color palette so each pixel layer uses only one color. This allows you to
* reuse layers and quickly change the color scheme of all images fast and uniformly. 
* Files are typically saved with a .alb extension and are plain text (json)
* Just use its page() function to get a single image from the album
*/
class Album {
	PGraphics[] pages; //images or frames
	IntDict tableOfContents;
	int pixelW, pixelH;
	float w, h, scale;

	Album(String filename) { this(filename, 1.0); }
	Album(String filename, float albumScale) {
		JSONObject json = loadJSONObject(EdFiles.DATA_FOLDER + filename);
		JSONArray jsonPages = json.getJSONArray(EdFiles.ALBUM_PAGES);
		JSONArray jsonLayers = json.getJSONArray(EdFiles.PIXEL_LAYERS);
		JSONArray colorPalette = json.getJSONArray(EdFiles.COLOR_PALETTE);
		pixelW = json.getInt(EdFiles.PX_WIDTH);
		pixelH = json.getInt(EdFiles.PX_HEIGHT);
		scale = albumScale;
		w = pixelW * scale;
		h = pixelH * scale;
		tableOfContents = new IntDict();
		pages = new PGraphics[jsonPages.size()];
		int x = 0, y = 0; //x is calculated using y
		//loop through each page and draw it
		for (int i = 0; i < jsonPages.size(); i++) {
			JSONObject jsonPage = jsonPages.getJSONObject(i);
			PGraphics sheet = createGraphics((int)w, (int)h);
			sheet.beginDraw();
			sheet.noStroke();
			if (!json.isNull(EdFiles.BGD_COLOR)) {
				sheet.background(colorPalette.getInt(json.getInt(EdFiles.BGD_COLOR)));
			}
			//loop through each pixel layer used by the page
			for (int visibleLayerIndex : jsonPage.getJSONArray(EdFiles.LAYER_NUMBERS).getIntArray()) {
				JSONObject thisLayer = jsonLayers.getJSONObject(visibleLayerIndex);
				sheet.fill(colorPalette.getInt(thisLayer.getInt(EdFiles.PALETTE_INDEX)));
				//draw layer to current page
				for (int pixelIndex : thisLayer.getJSONArray(EdFiles.DOTS).getIntArray()) {
					//translate pixel index (from BitSet) to its xy coord
					y = pixelIndex / pixelW;
					x = pixelIndex - (y * pixelW);
					sheet.rect(x * scale, y * scale, ceil(scale), ceil(scale));
					//sheet.point(x, y);
				}
			}
			sheet.endDraw();
			pages[i] = sheet;
			tableOfContents.set(jsonPage.getString(EdFiles.PAGE_NAME), i);
		}
	}

	/**
	* Return the image associated with the pageName.
	* If it doesn't exist return the image at index 0 (the first defined page)
	*/
	PGraphics page(String pageName) {
		return pages[tableOfContents.get(pageName, 0)];
	}

	PGraphics randomPage() {
		return pages[(int)random(pages.length)];
	}
}



/**
* Simple class for a rectangle with words in it
*/
class TextLabel implements Kid {
	NestedRectBody body; 
	String text, id;
	Integer textColor, bgdColor, strokeColor; //nullable 
	final int PADDING = 4;

	//TextLabel(String labelText, float x, float y) { this(labelText, x, y, new RectBody()); }
	TextLabel(String labelText, float x, float y, RectBody parent) { this(labelText, x, y, parent, null, null, null); }
	TextLabel(String labelText, float x, float y, RectBody parent, Integer fgd, Integer bgd, Integer border) { 
		body = new NestedRectBody(parent, x, y, labelText.length() * 7 + PADDING * 2, 18); //7 here is an estimate of how many pixels wide one character is
		text = labelText;
		textColor = fgd;
		bgdColor = bgd;
		strokeColor = border;
		id = "TextLabel"; //can update if you want I guess. Probably easier to keep a reference to the object itself in your class rather than parse this id
	}

	void drawSelf(PGraphics canvas) {
		if (bgdColor != null || strokeColor != null) {
			if (bgdColor != null) canvas.fill(bgdColor);
			else canvas.noFill();
			if (strokeColor != null) canvas.stroke(strokeColor);
			else canvas.noStroke();
			canvas.strokeWeight(1); //no effect if noStroke()
			canvas.rect(body.x, body.y, body.w, body.h);
		}
		if (textColor != null) canvas.fill(textColor);
		else canvas.fill(EdColors.UI_DARKEST);
		canvas.text(text, body.x + PADDING, body.yh() - PADDING); //text draws from the bottom left going up and right
	}

	String mouse() {
		return "";
	}

	String keyboard(KeyEvent event) {
		return "";
	}

	String getName() {
		return id;
	}
}



/**
* A set of menu buttons that line up in a grid next to each other according to the number of columns specified. 
* The page names supplied (albumPages) become the buttons. To handle a button press you can either
* check its mouse() function to get the page name clicked, or you can override buttonClick()
* Checkboxes start as false (so togglePages should contain the true/enabled/checked album pages, if any)
*/
class GridButtons implements Kid {
	NestedRectBody body;
	Album buttonAlbum;
	String[] buttonPages, altPages, origPages;
	int columns;

	GridButtons(RectBody parent, float anchorX, float anchorY, int numCols, Album album, String[] albumPages) { this(parent, anchorX, anchorY, numCols, album, albumPages, albumPages); }
	GridButtons(RectBody parent, float anchorX, float anchorY, int numCols, Album album, String[] albumPages, String[] togglePages) {
		if (togglePages.length != albumPages.length) throw new IllegalArgumentException("Array lengths of page lists do not match");
		columns = min(max(1, numCols), albumPages.length); //quick error checking
		body = new NestedRectBody(parent, anchorX, anchorY, columns * album.w, ceil(albumPages.length / (float)columns) * album.h);
		buttonAlbum = album;
		buttonPages = albumPages;
		origPages = albumPages.clone();
		altPages = togglePages; 
	}

	/** You can override this or just pay attention to mouse() **/
	void buttonClick(String clicked) { }
	/************************************************************/

	void drawSelf(PGraphics canvas) {
		for (int i = 0; i < buttonPages.length; i++) {
			canvas.image(buttonAlbum.page(buttonPages[i]), 
				body.x + (i % columns) * buttonAlbum.w, 
				body.y + (i / columns) * buttonAlbum.h);
		}
	}

	String mouse() {
		if (!body.isMouseOver()) return "";
		int index = indexAtMouse();
		if (index < buttonPages.length) {
			if (edwin.mouseBtnReleased == LEFT) buttonClick(buttonPages[index]);
			return buttonPages[index]; //respond with the page name of the button the mouse is over
		}
		return "";
	}

	String keyboard(KeyEvent event) {
		return "";
	}

	void toggleImage() { toggleImage(0); }
	void toggleImage(int index) { setCheck(index, (buttonPages[index] == origPages[index])); }
	void setCheck(boolean check) { setCheck(0, check); }
	void setCheck(int index, boolean check) {
		if (check) buttonPages[index] = altPages[index];
		else buttonPages[index] = origPages[index];
	}

	void uncheckAll() {
		for (int i = 0; i < buttonPages.length; i++) {
			setCheck(i, false);
		}
	}

	int indexAtMouse() { return indexAtPosition(mouseX, mouseY); }
	int indexAtPosition(float _x, float _y) {
		//if (!body.isMouseOver()) return -1;
		float relativeX = _x - body.realX();
		float relativeY = _y - body.realY();
		int index = (int)(floor(relativeY / buttonAlbum.h) * columns + (relativeX / buttonAlbum.w));
		return index;
	}

	String getName() {
		return "GridButtons";
	}
}



/**
* Contains basics for a window that floats in the sketch and can be dragged around. 
* Intended to be extended. Requires a little wiring up in the child class like so:
*
*	class MyWindow extends DraggableWindow {
*		MyWindow() {
*			super(myX, myY);
*			body.setSize(myW, myH);
*			dragBar.w = body.w - UI_PADDING * 2;
*			windowTitle = "My Window";
*			...
*		}
*
*		void drawSelf(PGraphics canvas) {
*			if (!isVisible) return;
*			super.drawSelf(canvas);
*			canvas.pushMatrix();
*			canvas.translate(body.x, body.y);
*			...
*			canvas.popMatrix();
*		}
*
*		String mouse() {
*			if (!isVisible) return "";
*			if (super.mouse() != "") return "dragging";
*			...
*		}
*	}
*
*/
class DraggableWindow implements Kid {
	RectBody body;
	NestedRectBody dragBar;
	XY dragOffset;
	String windowTitle;
	boolean isVisible, beingDragged;
	public static final int UI_PADDING = 5;

	DraggableWindow() { this(random(width - 100), random(height - 100)); }
	DraggableWindow(float _x, float _y) {
		int baseHeight = 18, baseWidth = 40;
		body = new RectBody(_x, _y, baseWidth + UI_PADDING * 2, baseHeight + UI_PADDING * 2);
		dragBar = new NestedRectBody(body, UI_PADDING, UI_PADDING, baseWidth, baseHeight);
		dragOffset = new XY();
		isVisible = true;
		beingDragged = false;
		windowTitle = "";
	}

	void toggleVisibility() {
		isVisible = !isVisible;
	}

	void drawSelf(PGraphics canvas) {
		if (!isVisible) return;
		canvas.strokeWeight(1);
		canvas.stroke(EdColors.UI_DARKEST);
		canvas.fill(EdColors.UI_NORMAL);
		canvas.rect(body.x, body.y, body.w, body.h);
		if (!dragBar.isMouseOver()) canvas.noStroke();
		canvas.fill(EdColors.UI_DARK);
		canvas.rect(dragBar.realX(), dragBar.realY(), dragBar.w, dragBar.h);
		canvas.fill(EdColors.UI_LIGHT);
		canvas.text(windowTitle, dragBar.realX() + UI_PADDING, dragBar.realYH() - 5); //text draws from the bottom left going up (rather than images/rects that go top left down)
	}

	String mouse() {
		if (!isVisible) return "";
		if (edwin.mouseBtnBeginHold == LEFT && dragBar.isMouseOver()) {
			beingDragged = true;
			dragOffset.set(mouseX - body.x, mouseY - body.y);
			return "begin drag";
		}
		if (beingDragged) {
			body.set(mouseX - dragOffset.x, mouseY - dragOffset.y);
			if (edwin.mouseBtnReleased == LEFT) {
				beingDragged = false;
				return "end drag";
			}
			return "dragging";
		}
		return "";
	}

	String keyboard(KeyEvent event) {
		return "";
	}

	String getName() {
		return "SomeDraggableWindow";
	}
}



/**
* A floating draggable window you put GridButtons + labels on.
* Use addItem() to insert a menu line and make sure to 
* override the Command object's execute() to handle the menu click
*/
class GadgetPanel extends DraggableWindow {
	ArrayList<PanelItem> panelItems; //each of these has a GridButtons
	Album buttonAlbum;
	final int TX_OFFSET = 9;
	//constants for the Album
	public static final String BUTTON_FILENAME = "basicButtons.alb",
	BLANK = "blank",
	OPEN = "open", 
	SAVE = "save",
	ARROW_N = "arrowN",
	ARROW_S = "arrowS",
	ARROW_E = "arrowE",
	ARROW_W = "arrowW",
	PLUS = "plus",
	MINUS = "minus",
	NO = "no",
	OK = "ok",
	BIGX = "bigx",
	COLOR_WHEEL = "colorWheel",
	START_LIGHT = "start light",
	STOP_LIGHT = "stop light",
	OVER_UNDER = "over under",
	OVER_UNDER_DOWN = "over under down",
	SIDE_SIDE = "side side",
	SIDE_SIDE_DOWN = "side side down";

	GadgetPanel() { this(""); }
	GadgetPanel(String title) { this(50, 50, title); }
	GadgetPanel(XY anchor) { this(anchor.x, anchor.y, ""); }
	GadgetPanel(XY anchor, String title) { this(anchor.x, anchor.y, title); }
	GadgetPanel(float _x, float _y, String title) { this(_x, _y, title, new Album(BUTTON_FILENAME)); }
	GadgetPanel(float _x, float _y, String title, Album album) {
		super(_x, _y);
		buttonAlbum = album;
		windowTitle = title; //displayed in dragBar
		panelItems = new ArrayList<PanelItem>();
		body.h += UI_PADDING;
	}

	void addItem(String label, String page, Command cmd) { addItem(label, new String[] { page }, cmd); }
	void addItem(String label, String page, String alt, Command cmd) { addItem(label, new String[] { page }, new String[] { alt }, cmd); }
	void addItem(String label, String[] pages, Command cmd) { addItem(label, pages, pages, cmd); }
	void addItem(String label, String[] pages, String[] alts, Command cmd) { addItem(label, new GridButtons(body, 0, 0, 5, buttonAlbum, pages, alts), cmd); }
	void addItem(String label, GridButtons buttons, Command cmd) {
		buttons.body.set(UI_PADDING, body.h - UI_PADDING); //reset position of GridButtons
		panelItems.add(new PanelItem(label, buttons, cmd));
		float itemWidth = buttons.body.w + label.length() * 7 + UI_PADDING * 2; //7 here is an estimate of how many pixels wide one character is
		if (itemWidth > body.w) {
			body.w = itemWidth;
			dragBar.w = body.w - UI_PADDING * 2;
		}
		body.h += buttons.body.h;
	}

	/**
	* Mainly for toggling buttons to their alt state
	*/
	GridButtons getButtons(String label) {
		for (PanelItem item : panelItems) {
			if (item.label.equals(label)) {
				return item.buttons;
			}
		}
		println("Uh oh, no GadgetPanel.PanelItem found with the label " + label);
		return null;
	}

	/**
	* Can be called at will from any class that has a GadgetPanel of their own.
	* This lets you execute the code in the Command object with your own argument
	*/
	void itemExecute(String label, String arg) {
		for (PanelItem item : panelItems) {
			if (item.label.equals(label)) {
				item.command.execute(arg);
				return;
			}
		}
		println("Uh oh, no GadgetPanel.PanelItem found with the label " + label);
	}

	void drawSelf(PGraphics canvas) {
		if (!isVisible) return;
		super.drawSelf(canvas);
		canvas.pushMatrix();
		canvas.translate(body.x, body.y);
		canvas.fill(EdColors.UI_DARKEST);
		for (PanelItem item : panelItems) {
			canvas.text(item.label, item.labelPos.x, item.labelPos.y);
			item.buttons.drawSelf(canvas);
		}
		canvas.popMatrix();
	}

	String mouse() {
		if (!isVisible) return "";
		if (super.mouse() != "") return "dragging";
		if (edwin.mouseBtnReleased == LEFT && body.isMouseOver()) {
			for (PanelItem item : panelItems) {
				String buttonPage = item.buttons.mouse();
				if (buttonPage != "") {
					item.command.execute(buttonPage);
					return buttonPage;
				}
			}
		}
		return "";
	}

	String getName() {
		return "GadgetPanel";
	}

	class PanelItem {
		Command command;
		GridButtons buttons;
		XY labelPos;
		String label;

		PanelItem(String text, GridButtons gridButtons, Command cmd) {
			label = text;
			buttons = gridButtons;
			command = cmd;
			labelPos = new XY(buttons.body.xw() + UI_PADDING, buttons.body.yh() - TX_OFFSET);
		}
	}
}



/**
* Restricting to a color palette helps me design stuff
* so I made this color picker. See AlbumEditor for potential usage
*/
public class PalettePicker extends DraggableWindow {
	ArrayList<Integer> colors;
	GridButtons buttons;
	BoundedInt selectedColor;
	XY squareCoord;
	String openFilepath;
	final int SIDE = 24, COLUMN_COUNT = 5;

	PalettePicker() { this(new int[] { #FFFFFF, #000000 }); }
	PalettePicker(int[] paletteColors) { this(paletteColors, "Color Palette", true); }
	PalettePicker(int[] paletteColors, String title) { this(paletteColors, title, true); }
	PalettePicker(int[] paletteColors, String title, boolean visible) {
		super();
		colors = new ArrayList<Integer>();
		selectedColor = new BoundedInt(0);
		body.setSize(SIDE * COLUMN_COUNT + UI_PADDING * 2, SIDE * 2 + dragBar.h + UI_PADDING * 4);
		dragBar.setSize(body.w - UI_PADDING * 2, dragBar.h);
		buttons = new GridButtons(body, UI_PADDING + SIDE, UI_PADDING * 2 + dragBar.h, 5, 
			new Album(GadgetPanel.BUTTON_FILENAME), new String[] { GadgetPanel.COLOR_WHEEL, GadgetPanel.PLUS, GadgetPanel.ARROW_S, GadgetPanel.OPEN });
		squareCoord = new XY();
		isVisible = visible;
		windowTitle = title;
		openFilepath = null;
		resetColors(paletteColors);
	}

	/** You can override these *************/
	void colorSelected(int paletteIndex) { }
	void colorEdited(int paletteIndex) { }
	/***************************************/

	void resetColors(int[] paletteColors) {
		colors.clear();
		selectedColor.reset(0, -1);
		for (int i = 0; i < paletteColors.length; i++) {
			colors.add(paletteColors[i]);
			selectedColor.incrementMax();
			colorEdited(i);
		}
		body.h = UI_PADDING * 4 + dragBar.h + buttons.body.h + SIDE * ceil(colors.size() / (float)COLUMN_COUNT);
	}

	void drawSelf(PGraphics canvas) {
		if (!isVisible) return;
		//if (openFilepath != null) digestFile();
		super.drawSelf(canvas);
		canvas.pushMatrix();
		canvas.translate(body.x, body.y);
		canvas.noStroke();
		//menu
		buttons.drawSelf(canvas);
		//square intended to show contrast when your palette color is transparent
		canvas.fill(0);
		canvas.rect(buttons.body.x - SIDE, buttons.body.y, SIDE, SIDE);
		canvas.fill(255);
		canvas.triangle(buttons.body.x - SIDE, buttons.body.y + SIDE, buttons.body.x, buttons.body.y + SIDE, buttons.body.x, buttons.body.y);
		//currently selected color
		canvas.fill(colors.get(selectedColor.value));
		canvas.rect(buttons.body.x - SIDE, buttons.body.y, SIDE, SIDE);
		//draw palette squares
		for (int i = 0; i < colors.size(); i++) {
			squareCoord.y = floor(i / (float)COLUMN_COUNT);
			squareCoord.x = i - (squareCoord.y * COLUMN_COUNT);
			canvas.fill(colors.get(i));
			canvas.rect(UI_PADDING + squareCoord.x * SIDE, UI_PADDING * 3 + SIDE + dragBar.h + squareCoord.y * SIDE, SIDE, SIDE);
		}
		canvas.popMatrix();
	}

	String mouse() {
		if (super.mouse() != "") return "dragging";
		if (!isVisible || edwin.mouseBtnReleased != LEFT || !body.isMouseOver()) return "";

		String button = buttons.mouse();
		if (button == GadgetPanel.COLOR_WHEEL) {
			Color picked = JColorChooser.showDialog(null, "Edit color", new Color(colors.get(selectedColor.value)));
			if (picked == null) return "";
			colors.set(selectedColor.value, picked.getRGB());
			colorEdited(selectedColor.value);
			return "color edited";
		}
		else if (button == GadgetPanel.PLUS) {
			Color picked = JColorChooser.showDialog(null, "Pick new color", Color.BLACK);
			if (picked == null) return "";
			colors.add(picked.getRGB());
			selectedColor.incrementMax();
			selectedColor.maximize();
			if (colors.size() % COLUMN_COUNT == 1) {
				body.h += SIDE;
			}
			return "new color";
		}
		else if (button == GadgetPanel.OPEN) {
			selectInput("Open color palette from file (.alb, .lzr, .pw)", "openFile", null, this);
			return "open";
		}
		else if (button == GadgetPanel.ARROW_S) {
			String newPalette = JOptionPane.showInputDialog("Enter hex values of new color palette", "");
			if (newPalette == null) return "";
			try {
				String[] hexValues = newPalette.replaceAll("\\r", " ").replaceAll("\\n", " ").replaceAll("\\t", " ").replaceAll(" ", ",").split(",");
				int[] newColors = new int[hexValues.length];
				int index = 0;
				for (int i = 0; i < hexValues.length; i++) {
					if (hexValues[i].replace("#", "").trim().length() != 6) continue;
					String col = hexValues[i].replace("#", "").trim();
					newColors[index++] = Color.decode("#" + col).getRGB();
				}
				if (index > 0) resetColors(Arrays.copyOf(newColors, index));
			}
			catch (Exception e) {
				JOptionPane.showMessageDialog(null, "Palette could not be read", "Hey", JOptionPane.ERROR_MESSAGE);
			}
			return "new palette from hex";
		}

		//translate mouse position into palette index
		int yIndex = (int)((mouseY - (buttons.body.realYH() + UI_PADDING)) / SIDE);
		int xIndex = (int)((mouseX - (body.x + UI_PADDING)) / SIDE);
		int index = yIndex * COLUMN_COUNT + xIndex;
		if (index >= 0 && index < colors.size()) {
			selectedColor.set(index);
			colorSelected(selectedColor.value);
			return "color selected";
		}
		return "";
	}

	void openFile(File file) {
		if (file == null) return; //user hit cancel or closed
		openFilepath = file.getAbsolutePath();
		try {
			JSONObject json = loadJSONObject(openFilepath);
			resetColors(json.getJSONArray(EdFiles.COLOR_PALETTE).getIntArray());
		}
		catch (Exception e) {
			JOptionPane.showMessageDialog(null, "Palette could not be read", "Hey", JOptionPane.ERROR_MESSAGE);
		}
		finally {
			openFilepath = null;
		}
	}

	String keyboard(KeyEvent event) {
		return "";
	}

	String getName() {
		return "PalettePicker";
	}

	String asJsonKV() {
		return jsonKV(EdFiles.COLOR_PALETTE, colors.toString());
	}
}



/** 
* Place and scale a reference image for making stuff with other stuff.
* Use the middle mouse button to drag it around, or arrows keys for 1 pixel movement
*/
public class ReferenceImagePositioner implements Kid {
	PImage refImage;
	File imageFile; //path instead of just String filename
	RectBody body;
	BoundedInt scale;
	GadgetPanel gPanel;
	int origW, origH;
	boolean imageVisible;
	final String SCALE = "scale",
	RELOAD = "reload",
	IS_VISIBLE = "visible";

	ReferenceImagePositioner() { this(""); }
	ReferenceImagePositioner(String imageFilename) {
		body = new RectBody();
		scale = new BoundedInt(10, 500, 100, 10);
		refImage = null;
		imageFile = null;
		imageVisible = false;
		gPanel = new GadgetPanel(50, 50, "(I) Reference Img");

		gPanel.addItem("open image", GadgetPanel.OPEN, new Command() {
			void execute(String arg) {
				selectInput("Open reference image (.jpg or .png)", "openFile", null, ReferenceImagePositioner.this);
			}
		});

		gPanel.addItem(RELOAD, GadgetPanel.OK, new Command() {
			void execute(String arg) {
				openFile(imageFile);
			}
		});

		gPanel.addItem(SCALE, new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS }, new Command() {
			void execute(String arg) {
				if (refImage == null) {
					gPanel.windowTitle = "no image open";
					return;
				}
				else if (arg == GadgetPanel.PLUS) {
					scale.increment();
				}
				else if (arg == GadgetPanel.MINUS) {
					scale.decrement();
				}
				gPanel.windowTitle = SCALE + ":" + scale.value + "%";
				refImage.resize((int)(origW * (scale.value / 100.0)), (int)(origH * (scale.value / 100.0)));
			}
		});

		gPanel.addItem(IS_VISIBLE, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
			void execute(String arg) {
				imageVisible = !imageVisible;
				gPanel.windowTitle = IS_VISIBLE + ":" + imageVisible;
				gPanel.getButtons(IS_VISIBLE).toggleImage();
			}
		});
		
		if (imageFilename != "") {
			openFile(imageFilename);
		}
	}

	void drawSelf(PGraphics canvas) {
		if (imageVisible && refImage != null) canvas.image(refImage, body.x, body.y);
		gPanel.drawSelf(canvas);
	}

	String mouse() {
		if (!gPanel.isVisible) return "";
		if (gPanel.mouse() != "") {
			return getName();
		}
		// else if (edwin.mouseBtnHeld == CENTER) {
		// 	body.set(mouseX, mouseY);
		// 	setGPLabel();
		// }
		return "";
	}

	void setGPLabel() { gPanel.windowTitle = "x:" + (int)body.x +  "|y:" + (int)body.y; }

	String keyboard(KeyEvent event) {
		if (event.getAction() != KeyEvent.PRESS) {
			return "";
		}
		int kc = event.getKeyCode();
		if (kc == Keycodes.VK_I) {
			gPanel.toggleVisibility();
		}
		else if (!gPanel.isVisible) {
			return "";
		}
		// else if (event.isShiftDown()) {
		// 	if (kc == Keycodes.VK_LEFT) {
		// 		body.x--;
		// 		setGPLabel();
		// 	}
		// 	else if (kc == Keycodes.VK_RIGHT) {
		// 		body.x++;
		// 		setGPLabel();
		// 	}
		// 	else if (kc == Keycodes.VK_UP) {
		// 		body.y--;
		// 		setGPLabel();
		// 	}
		// 	else if (kc == Keycodes.VK_DOWN) {
		// 		body.y++;
		// 		setGPLabel();
		// 	}
		// }
		return "";
	}

	void openFile(String imageFilename) { openFile(new File("C:\\code\\Processing\\EdwinGerm\\data\\", imageFilename));  } //TODO relative path
	void openFile(File file) {
		if (file == null) return; //user hit cancel or closed
		imageFile = file;
		refImage = loadImage(imageFile.getAbsolutePath());
		origW = refImage.width;
		origH = refImage.height;
		body.setSize(origW, origH);
		scale.set(100);
		imageVisible = true;
		gPanel.windowTitle = imageFile.getName();
		gPanel.getButtons(IS_VISIBLE).setCheck(true);
	}

	String getName() {
		return "ReferenceImagePositioner";
	}
}



/**
* The tile editor. Define the color palette, create layers of pixels (one color per layer),
* then create "pages" of those layers and save that condensed spritesheet as an "Album" 
* Each page is a subset of the pixel layers in the Album, and each pixel layer can be in many pages. 
* This lets you easily make changes that cascade to all pages that share layers. 
* And restricting colors to a palette allows you change it for all sprites/pages at once. 
* You can use up/down to move between layers or pages depending on which list is shown
* and pressing control + up/down lets you reorder list items. 
* Used to be called EditorWindow (EDitor WINdow, Edwin, get it?)
* "Albums with Pages" used be to "Symbols with Expressions"
*
* Press E to toggle window visibility
*/
public class AlbumEditor extends DraggableWindow {
	ArrayList<PixelLayer> pixelLayers;
	ArrayList<EditablePage> editablePages;
	PixelLayer selectedLayer, utilityLayer;
	EditablePage selectedPage;
	PalettePicker palette;
	GridButtons toolMenu;
	Album layerButtonAlbum;
	NestedRectBody editBounds, previewBounds, layerListBounds;
	BoundedInt brushSize, zoomLevel; 
	BoundedFloat previewZoomLevel;
	String currentBrush, openFilepath;
	boolean showPages, showGrid;
	int spriteW, spriteH;
	final int LIH = 10; //list item height - height of layer list items, and width of its buttons
	//here I'm hardcoding page names from the albums
	//so don't rename the pages if you edit the buttons
	public static final String WINDOW_TITLE = "Album Editor ~ ",
	//main editor menu buttons
	TOOL_MENU_FILENAME = "editorButtons.alb",
	BLANK = "blank",
	BRUSH = "brush", 
	LINE = "line",
	BRUSH_SMALLER = "brushSmaller", 
	BRUSH_BIGGER = "brushBigger", 
	RECTANGLE = "rectangle", 
	PERIMETER = "perimeter",
	ZOOM_IN = "zoomIn", 
	ZOOM_OUT = "zoomOut", 
	OPEN = "open", 
	SAVE = "save",
	ADD_LAYER = "addLayer",
	PALETTE_PICKER = "palettePicker",
	SET_SIZE = "setSize",
	LIST_TOGGLE = "listToggle",
	GRID_TOGGLE = "gridToggle",
	//layer list item buttons
	LAYER_MENU_FILENAME = "layerButtons.alb",
	DELETE = "delete",
	IS_VISIBLE = "isVisible",
	IS_NOT_VISIBLE = "isNotVisible",
	MOVE_DOWN = "moveDown",
	EDIT_COLOR = "editColor",
	EDIT_NAME = "editName";

	AlbumEditor() { this(true); }
	AlbumEditor(boolean initiallyVisible) { 
		super(); //initialize DraggableWindow stuff
		isVisible = initiallyVisible;
		int margin = 30; //optional, can be 0 to take up the whole screen
		body.set(margin, margin, max(width - margin * 2, 600), max(height - margin * 2, 400));
		dragBar.w = body.w - UI_PADDING * 2;
		setWindowTitle("");
		zoomLevel = new BoundedInt(1, 30, 6);
		previewZoomLevel = new BoundedFloat(0.5, 4, 1, 0.5);
		brushSize = new BoundedInt(1, 20, 3);
		layerButtonAlbum = new Album(LAYER_MENU_FILENAME);
		Album brushMenuAlbum = new Album(TOOL_MENU_FILENAME);
		int menuColumns = 4; //can be changed but 4 seems best
		int menuW = menuColumns * (int)brushMenuAlbum.w;
		XY ui = new XY(dragBar.x, dragBar.yh() + UI_PADDING); //anchor for current UI body
		previewBounds = new NestedRectBody(body, ui.x, ui.y, menuW, menuW);
		editBounds = new NestedRectBody(body, ui.x + menuW + UI_PADDING, ui.y, body.w - menuW - UI_PADDING * 3, body.h - dragBar.h - UI_PADDING * 3);
		ui.y += previewBounds.h + UI_PADDING;
		toolMenu = new GridButtons(body, ui.x, ui.y, menuColumns, brushMenuAlbum, new String[] {
			BRUSH, LINE, BRUSH_SMALLER, BRUSH_BIGGER,
			RECTANGLE, PERIMETER, ZOOM_OUT, ZOOM_IN,
			PALETTE_PICKER, SET_SIZE, GRID_TOGGLE, BLANK,
			OPEN, SAVE, LIST_TOGGLE, ADD_LAYER
		});
		ui.y += toolMenu.body.h + UI_PADDING + LIH; //LIH here for the utility layer
		layerListBounds = new NestedRectBody(body, ui.x, ui.y, menuW, body.h - ui.y - UI_PADDING);
		pixelLayers = new ArrayList<PixelLayer>();
		utilityLayer = new PixelLayer(-1, 0, new BitSet(spriteW * spriteH), new String[] { IS_VISIBLE, EDIT_COLOR }); //isVisible used for bgd vis, layer color for bgd color, pixels for the brush preview, and it has a custom GridButtons
		editablePages = new ArrayList<EditablePage>();
		selectedPage = new EditablePage(0, "first page", new int[] { 0 });
		editablePages.add(selectedPage);
		selectedLayer = new PixelLayer(0, 0, null);
		palette = new PalettePicker(new int[] { #FFFFFF, #000000 }, "Album colors", false) {
			void colorSelected(int paletteIndex) {
				selectedLayer.paletteIndex = paletteIndex;
			}
		};
		spriteW = spriteH = 50;
		currentBrush = BRUSH;
		showPages = false;
		showGrid = true;
		openFilepath = null; //stays null until a new file is opened, at which point it will be loaded the next time drawSelf() is called
		addPixelLayer(); 
	}

	void setWindowTitle(String text) {
		windowTitle = WINDOW_TITLE + text;
	}

	void addPixelLayer() { addPixelLayer(new BitSet(spriteW * spriteH), 1); }
	void addPixelLayer(BitSet pxls, int paletteIndex) {
		selectedLayer = new PixelLayer(pixelLayers.size(), paletteIndex, pxls);
		pixelLayers.add(selectedLayer);
		useLayer(pixelLayers.size() - 1);
	}

	/** Input layer index, receive color from palette */
	int colr(int index) { return colr(pixelLayers.get(index)); }
	int colr(PixelLayer layer) {
		return palette.colors.get(layer.paletteIndex);
	}

	// big methods ============================================================================================================================================
	void drawSelf(PGraphics canvas) { // ======================================================================================================================
		//canvas.beginDraw() has already been called in Edwin
		if (!isVisible) return;
		super.drawSelf(canvas); //draw DraggableWindow - the box bgd and the dragBar

		//This is so that we can't use the new Album from openFile() while the old one is still being drawn
		//openFilepath stays null until a new Album file is opened
		if (openFilepath != null) digestFile();
		
		//This must be called before translations, and popMatrix() reverses them
		canvas.pushMatrix();
		//This translate call is the benefit and requirement of using NestedRectBodys
		//It allows us to keep the AlbumEditor's body anchor separate so everything can now draw from 0,0 
		canvas.translate(body.x, body.y);

		//blank bgds
		canvas.noStroke();
		canvas.fill(EdColors.UI_DARKEST);
		canvas.rect(editBounds.x, editBounds.y, editBounds.w, editBounds.h);
		canvas.fill(EdColors.UI_DARK);
		canvas.rect(previewBounds.x, previewBounds.y, previewBounds.w, previewBounds.h);
		canvas.rect(layerListBounds.x, layerListBounds.y, layerListBounds.w, layerListBounds.h);

		canvas.fill(colr(utilityLayer));
		if (utilityLayer.isVisible) { //sprite bgds
			canvas.rect(editBounds.x, editBounds.y, min(editBounds.w, spriteW * zoomLevel.value), min(editBounds.h, spriteH * zoomLevel.value));
			canvas.rect(previewBounds.x, previewBounds.y, min(previewBounds.w, spriteW * previewZoomLevel.value), min(previewBounds.h, spriteH * previewZoomLevel.value));
		}
		canvas.rect(utilityLayer.listBody.x, utilityLayer.listBody.y, utilityLayer.listBody.w, utilityLayer.listBody.h);
		utilityLayer.buttons.drawSelf(canvas); 
		listLabel(canvas, selectedPage.name, -1);

		//draw each layer scaled at zoomLevel
		PixelLayer thisLayer;
		float pixelX, pixelY;
		RectBody scaledPixel = new RectBody();
		for (int i = 0; i <= pixelLayers.size(); i++) {
			if (i == pixelLayers.size()) {
				thisLayer = utilityLayer;
				canvas.fill(EdColors.UI_EMPHASIS); //brush preview color
			}
			else if (!pixelLayers.get(i).isVisible) {
				continue;
			}
			else {
				thisLayer = pixelLayers.get(i);
				canvas.fill(colr(i));
			}

			//loop through BitSet, draw each pixel for this layer factoring in zoomLevel
			for (int j = 0; j < thisLayer.dots.size(); j++) {
				if (!thisLayer.dots.get(j)) continue; //if pixel isn't set, skip loop iteration
				
				//calculate coords based on the dot's index
				pixelY = round(j / spriteW);
				pixelX = j - (pixelY * spriteW);

				//draw pixel in top left preview
				canvas.rect(
					previewBounds.x + pixelX * previewZoomLevel.value, 
					previewBounds.y + pixelY * previewZoomLevel.value, 
					ceil(previewZoomLevel.value), 
					ceil(previewZoomLevel.value));

				//determine rectangle to draw that represents the current pixel with current zoom level
				//and clipped at the edges if necessary
				scaledPixel.set(
					editBounds.x + pixelX * zoomLevel.value,
					editBounds.y + pixelY * zoomLevel.value,
					min(zoomLevel.value, editBounds.w - pixelX * zoomLevel.value), 
					min(zoomLevel.value, editBounds.h - pixelY * zoomLevel.value));
				//finally if we're in the pane, draw the zoomed pixel
				if (editBounds.intersects(scaledPixel)) {
					canvas.rect(scaledPixel.x, scaledPixel.y, scaledPixel.w, scaledPixel.h);
				}
			}
		}

		//pixel grid lines
		if (showGrid && zoomLevel.value >= 6) {
			XY gridPt0 = new XY();
			XY gridPt1 = new XY();
			//vertical lines
			gridPt0.x = editBounds.x;
			gridPt1.x = editBounds.insideX(editBounds.x + spriteW * zoomLevel.value);
			for (int _y = 1; _y < spriteH; _y++) {
				if (_y % 10 == 0) canvas.stroke(EdColors.UI_EMPHASIS, 200);
				else if (zoomLevel.value < 12) continue;
				else canvas.stroke(EdColors.UI_DARK, 100);
				gridPt0.y = gridPt1.y = editBounds.insideY(editBounds.y + _y * zoomLevel.value);
				canvas.line(gridPt0.x, gridPt0.y, gridPt1.x, gridPt1.y);
			}
			//horizontal lines
			gridPt0.y = editBounds.y;
			gridPt1.y = editBounds.insideY(editBounds.y + spriteH * zoomLevel.value);
			for (int _x = 1; _x < spriteW; _x++) {
				if (_x % 10 == 0) canvas.stroke(EdColors.UI_EMPHASIS, 200);
				else if (zoomLevel.value < 12) continue;
				else canvas.stroke(EdColors.UI_DARK, 100);
				gridPt0.x = gridPt1.x = editBounds.insideX(editBounds.x + _x * zoomLevel.value);
				canvas.line(gridPt0.x, gridPt0.y, gridPt1.x, gridPt1.y);
			}
			canvas.noStroke();
		}

		//layer list items/menus
		if (showPages) {
			int selectedPageIndex = editablePages.indexOf(selectedPage);
			for (int i = 0; i < editablePages.size(); i++) {
				canvas.fill((i % 2 == 0) ? EdColors.ROW_EVEN : EdColors.ROW_ODD);
				canvas.rect(
					layerListBounds.x, 
					layerListBounds.y + (LIH * i), 
					layerListBounds.w, 
					LIH);
				//if this is the selected item, display extra wide body
				if (i == selectedPageIndex || editablePages.get(i).listBody.isMouseOver()) {
					canvas.rect(
						layerListBounds.x - UI_PADDING,
						layerListBounds.y + (LIH * i), 
						layerListBounds.w + UI_PADDING * 2, 
						LIH);
				}
				listLabel(canvas, editablePages.get(i).name, i);
				editablePages.get(i).buttons.drawSelf(canvas);
			}
		}
		else {
			int selectedLayerIndex = pixelLayers.indexOf(selectedLayer);
			for (int i = 0; i < pixelLayers.size(); i++) {
				canvas.fill(colr(i));
				canvas.rect(
					layerListBounds.x, 
					layerListBounds.y + (LIH * i), 
					layerListBounds.w, 
					LIH);
				//if this is the selected item, display extra wide body and name
				if (i == selectedLayerIndex || pixelLayers.get(i).listBody.isMouseOver()) {
					canvas.rect(
						layerListBounds.x - UI_PADDING,
						layerListBounds.y + (LIH * i), 
						layerListBounds.w + UI_PADDING * 2, 
						LIH);
					listLabel(canvas, pixelLayers.get(i).name, i);
				}
				pixelLayers.get(i).buttons.drawSelf(canvas);
			}
		}

		//draw menus
		toolMenu.drawSelf(canvas); //brushes, zoom, open/save and other buttons
		canvas.popMatrix(); //undo translate()
		palette.drawSelf(canvas); //standalone draggable window
	} // end drawSelf() =======================================================================================================================================
	// ========================================================================================================================================================

	/** convenience method */
	void listLabel(PGraphics canvas, String label, int index) {
		canvas.fill(EdColors.UI_LIGHT);
		canvas.rect(layerListBounds.x, layerListBounds.y + LIH * index, canvas.textWidth(label) + 1, LIH);
		canvas.fill(EdColors.UI_DARKEST);
		canvas.text(label, layerListBounds.x, layerListBounds.y + (LIH * (index + 1)) - 2);
	}

	String mouse() {
		if (!isVisible) return "";
		if (palette.mouse() != "" || super.mouse() != "") { //if the palette handles the event, or the window is being dragged
			return getName();
		}

		if (edwin.mouseBtnBeginHold != 0 || edwin.mouseBtnReleased != 0) {
			utilityLayer.dots.clear(); //clear brush preview
		}

		if (!body.isMouseOver()) {
			return "";
		}

		if (previewBounds.isMouseOver()) {
			if (edwin.mouseWheelValue == -1) {
				previewZoomLevel.increment();
			}
			else if (edwin.mouseWheelValue == 1) {
				previewZoomLevel.decrement();
			}
		}

		//now for determining which area/menu was clicked and how to handle it
		//I use switches for menus to make it easier to distinguish from other logic
		if (editBounds.isMouseOver()) {
			if (edwin.mouseHovering) { 
				switch (currentBrush) {
					case BRUSH:
						//hovering brush preview
						utilityLayer.dots.clear();
						applyBrush(utilityLayer, true);
						break;
				}
			}
			else if (edwin.mouseBtnHeld == LEFT || edwin.mouseBtnHeld == RIGHT) {
				switch (currentBrush) {
					case BRUSH:
						applyBrush(selectedLayer, (edwin.mouseBtnHeld == LEFT)); //  ? true : false
						break;
					case LINE:
					case RECTANGLE:
					case PERIMETER:
						//brush preview
						utilityLayer.dots.clear();
						applyBrush(utilityLayer, true);
						break;
				}
			}
			else if (edwin.mouseBtnReleased == LEFT || edwin.mouseBtnReleased == RIGHT) {
				switch (currentBrush) {
					case LINE:
					case RECTANGLE:
					case PERIMETER:
						applyBrush(selectedLayer, (edwin.mouseBtnReleased == LEFT));
						break;
				}
			}
			return getName(); //?
		}
		else if (edwin.mouseBtnReleased != LEFT) {
			utilityLayer.dots.clear(); //clear brush preview
			return ""; //otherwise if the mouse event wasn't a left click release then leave because we're not interested anymore
		}

		String buttonPage = toolMenu.mouse(); //primary menu buttons below preview
		switch (buttonPage) {
			case BRUSH:
			case LINE:
			case RECTANGLE:
			case PERIMETER:
				currentBrush = buttonPage;
				break;
			case ZOOM_IN: 
				zoomLevel.increment();
				break;
			case ZOOM_OUT: 
				zoomLevel.decrement();
				break;
			case BRUSH_BIGGER:
				brushSize.increment();
				break;
			case BRUSH_SMALLER:
				brushSize.decrement();
				break;
			case ADD_LAYER:
				if (showPages) {
					String newName = JOptionPane.showInputDialog("Enter new page name\nPress X to toggle layer menu", "newpage");
					if (newName == null) return "";
					//check for duplicate name
					for (EditablePage page : editablePages) {
						if (page.name.equals(newName)) {
							JOptionPane.showMessageDialog(null, "Duplicate name found", "Hey", JOptionPane.ERROR_MESSAGE);
							return "";
						}
					}
					int lastIndex = editablePages.size();
					selectedPage = new EditablePage(lastIndex, newName, new int[] { });
					editablePages.add(selectedPage);
					usePage(lastIndex);
				}
				else {
					addPixelLayer();
					selectedPage.layerIndicies.add(pixelLayers.size() - 1); //add new layer to current page
				}
				break;
			case PALETTE_PICKER: 
				palette.toggleVisibility();
				palette.body.set(mouseX, mouseY);
				break;
			case SAVE:
				selectOutput("Save Album .alb", "saveFile", null, this);
				break;
			case OPEN:
				selectInput("Open Album .alb", "openFile", null, this);
				break;
			case LIST_TOGGLE:
				showPages = !showPages;
				break;
			case SET_SIZE:
				String newSize = JOptionPane.showInputDialog("Enter new sprite size as w,h", spriteW + "," + spriteH);
				if (newSize == null) return ""; //canceled
				String[] sizes = newSize.split(",");
				int newWidth = 0, newHeight = 0;
				try {
					newWidth = Integer.parseInt(sizes[0].trim());
					newHeight = Integer.parseInt(sizes[1].trim());
				}
				catch (Exception e) {
					JOptionPane.showMessageDialog(null, "\"" + newSize + "\" does not fit the format of w,h", "Hey", JOptionPane.ERROR_MESSAGE);
					return "";
				}
				//new bounds parsed, now we change the BitSets of the PixelLayers
				for (PixelLayer layer : pixelLayers) {
					layer.updateBounds(newWidth, newHeight);
				}
				spriteW = newWidth;
				spriteH = newHeight;
				break;
			case GRID_TOGGLE:
				showGrid = !showGrid;
				break;
			case BLANK:
				//stupid hack to shift my layer's pixels to the right
				// for (int i = selectedLayer.dots.size() - 1; i > 0; i--) {
				// 	if (selectedLayer.dots.get(i -1)) {
				// 		selectedLayer.dots.set(i, true);
				// 		selectedLayer.dots.set(i - 1, false);
				// 	}
				// }
				break;
		}
		if (buttonPage != "") {
			return getName();
		}

		buttonPage = utilityLayer.buttons.mouse();
		if (buttonPage == IS_VISIBLE || buttonPage == IS_NOT_VISIBLE) {
			utilityLayer.toggleVisibility();
			return "bgd color toggled";
		}
		else if (buttonPage == EDIT_COLOR) {
			utilityLayer.paletteIndex = palette.selectedColor.value;
			return "bgd color chosen";
		}
		else if (!layerListBounds.isMouseOver() || editBounds.containsPoint(edwin.mouseHoldInitial)) {
			return "";
		}
		else if (showPages) {
			int index = -1;
			//loop through the list of pages and check to see if any were clicked
			for (int i = 0; i < editablePages.size(); i++) {
				buttonPage = editablePages.get(i).buttons.mouse();
				if (buttonPage != "") {
					index = i;
					break;
				}
				else if (editablePages.get(i).listBody.isMouseOver()) {
					usePage(i);
					return "page selected";
				}
			}
			if (index == -1) {
				return "";
			}
			usePage(index);
			switch (buttonPage) {
				case DELETE:
					if (editablePages.size() == 1) {
						JOptionPane.showMessageDialog(null, "Can't delete page when it's the only one", "Hey", JOptionPane.INFORMATION_MESSAGE);
						break;
					}
					int choice = JOptionPane.showConfirmDialog(null, "Really delete page \"" + selectedPage.name + "\"?", "Delete Page?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
					if (choice != JOptionPane.YES_OPTION) return "";
					editablePages.remove(index);
					if (index > 0) {
						for (int i = index; i < editablePages.size(); i++) {
							editablePages.get(i).buttons.body.y -= LIH;
							editablePages.get(i).listBody.y -= LIH;
						}
					}
					usePage(min(index, editablePages.size() - 1));
					break;
				case EDIT_NAME:
					String newName = JOptionPane.showInputDialog("Enter new page name", selectedPage.name);
					if (newName == null || newName.equals(selectedPage.name)) return "";
					//check for duplicate name
					for (EditablePage page : editablePages) {
						if (page.name.equals(newName)) {
							JOptionPane.showMessageDialog(null, "Duplicate name found", "Hey", JOptionPane.ERROR_MESSAGE);
							return "";
						}
					}
					selectedPage.name = newName;
					break;
				case MOVE_DOWN:
					movePageDown(index);
					break;
			}
			return getName();
		}
		//else: layer list items are visible and that area was clicked

		int index = -1;
		//loop through the list of layers and check to see if any were clicked
		for (int i = 0; i < pixelLayers.size(); i++) {
			buttonPage = pixelLayers.get(i).buttons.mouse();
			if (buttonPage != "") {
				index = i;
				break;
			}
			else if (pixelLayers.get(i).listBody.isMouseOver()) {
				useLayer(i);
				return "layer selected";
			}
		}
		if (index == -1) {
			return "";
		}
		useLayer(index);
		switch (buttonPage) {
			case DELETE:
				if (pixelLayers.size() == 1) {
					JOptionPane.showMessageDialog(null, "Can't delete layer when it's the only one", "Hey", JOptionPane.INFORMATION_MESSAGE);
					break;
				}
				int deleteChoice = JOptionPane.showConfirmDialog(null, "Really delete layer \"" + selectedLayer.name + "\"?", "Delete Layer?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
				if (deleteChoice != JOptionPane.YES_OPTION) return "";
				pixelLayers.remove(index);
				if (pixelLayers.indexOf(selectedLayer) == -1) {
					useLayer(0);
				}
				for (int i = index; i < pixelLayers.size(); i++) {
					pixelLayers.get(i).buttons.body.y -= LIH; //gotta shift the GridButtons manually for now...
					pixelLayers.get(i).listBody.y -= LIH; 
				}
				for (EditablePage page : editablePages) {
					page.deleteLayer(index);
				}
				break;
			case EDIT_NAME:
				String newName = JOptionPane.showInputDialog("Enter new layer name", selectedLayer.name);
				if (newName != null) selectedLayer.name = newName;
				break;
			case MOVE_DOWN:
				moveLayerDown(index);
				break;
			case IS_VISIBLE:
			case IS_NOT_VISIBLE:
				selectedLayer.toggleVisibility();
				selectedPage.setLayerVisibility(index, selectedLayer.isVisible);
				break;
		}
		return getName();
	} // end mouse() ==========================================================================================================================================
	// ========================================================================================================================================================

	String keyboard(KeyEvent event) {
		int kc = event.getKeyCode();
		if (!isVisible && kc != Keycodes.VK_E) {
			return "";
		}
		else if (kc == Keycodes.VK_Z) {
			zoomLevel.increment();
		}
		else if (kc == Keycodes.VK_A) {
			zoomLevel.decrement();
		}
		else if (event.getAction() != KeyEvent.RELEASE) { //the keys above react to any event, below only to RELEASE
			return "";
		}
		else if (kc == Keycodes.VK_X) {
			showPages = !showPages;
		}
		else if (kc == Keycodes.VK_E) {
			toggleVisibility();
		}
		else if (kc == Keycodes.VK_C) {
			palette.toggleVisibility();
		}
		else if (kc == Keycodes.VK_V) {
			selectedLayer.toggleVisibility();
			selectedPage.setLayerVisibility(pixelLayers.indexOf(selectedLayer), selectedLayer.isVisible);
		}
		else if (kc == Keycodes.VK_UP) {
			int selLayer = pixelLayers.indexOf(selectedLayer);
			int selPage = editablePages.indexOf(selectedPage);
			if (showPages) {
				if (event.isControlDown()) {
					if (selPage > 0) movePageDown(selPage - 1);
				}
				else {
					if (selPage > 0) usePage(selPage - 1);
				}
			}
			else if (event.isControlDown()) {
				if (selLayer > 0) moveLayerDown(selLayer - 1);
			}
			else {
				if (selLayer > 0) useLayer(selLayer - 1);
			}
		}
		else if (kc == Keycodes.VK_DOWN) {
			int selLayer = pixelLayers.indexOf(selectedLayer);
			int selPage = editablePages.indexOf(selectedPage);
			if (showPages) {
				if (event.isControlDown()) {
					if (selPage < editablePages.size() - 1) movePageDown(selPage);
				}
				else {
					if (selPage < editablePages.size() - 1) usePage(selPage + 1);
				}
			}
			else if (event.isControlDown()) {
				if (selLayer < pixelLayers.size() - 1) moveLayerDown(selLayer);
			}
			else {
				if (selLayer < pixelLayers.size() - 1) useLayer(selLayer + 1);
			}
		}
		else if (kc == Keycodes.VK_O && event.isControlDown()) {
			selectInput("Open Album .alb", "openFile", null, this);
		}
		else if (kc == Keycodes.VK_S && event.isControlDown()) {
			selectOutput("Save Album .alb", "saveFile", null, this);
		}
		else {
			return "";
		}
		return getName();
	}// end keyboard() and big methods ========================================================================================================================
	// ========================================================================================================================================================

	void useLayer(int index) {
		selectedLayer = pixelLayers.get(index);
		palette.selectedColor.set(selectedLayer.paletteIndex);
	}

	void moveLayerDown(int index) {
		//TODO make cleaner...
		if (index >= pixelLayers.size() - 1) return; //can't move the last layer down
		pixelLayers.get(index).buttons.body.y += LIH;
		pixelLayers.get(index).listBody.y += LIH;
		pixelLayers.get(index + 1).buttons.body.y -= LIH;
		pixelLayers.get(index + 1).listBody.y -= LIH;
		Collections.swap(pixelLayers, index, index + 1);
		//now we'll check each page for either PixelLayer being swapped and adjust their index value
		int indexItem, indexBelowItem;
		for (EditablePage page : editablePages) {
			indexItem = page.layerIndicies.indexOf(index);
			indexBelowItem = page.layerIndicies.indexOf(index + 1);
			if (indexItem != -1) page.layerIndicies.set(indexItem, index + 1);
			if (indexBelowItem != -1) page.layerIndicies.set(indexBelowItem, index);
		}
	}

	void usePage(int index) {
		selectedPage = editablePages.get(index);
		//turn all layers off
		for (int i = 0; i < pixelLayers.size(); i++) {
			if (pixelLayers.get(i).isVisible) {
				pixelLayers.get(i).toggleVisibility();
			}
		}
		//turn on layers selectively
		int selLayer = 0;
		for (int l : selectedPage.layerIndicies) {
			pixelLayers.get(l).toggleVisibility();
			selLayer = l;
		}
		useLayer(selLayer);
	}

	void movePageDown(int index) {
		//TODO make cleaner...
		if (index >= editablePages.size() - 1) { //can't move the last layer down
			return;
		}
		editablePages.get(index).buttons.body.y += LIH; 
		editablePages.get(index).listBody.y += LIH;
		editablePages.get(index + 1).buttons.body.y -= LIH;
		editablePages.get(index + 1).listBody.y -= LIH;
		Collections.swap(editablePages, index, index + 1);
	}

	/**
	* brushVal == true means setting pixels
	* brushVal == false means removing pixels
	*/
	void applyBrush(PixelLayer pixelLayer, boolean brushVal) {
		//these figures are aimed at consistency while zoomed
		XY mouseTranslated = new XY(round((mouseX - body.x - editBounds.x - (zoomLevel.value * .4)) / zoomLevel.value), 
			round((mouseY - body.y - editBounds.y - (zoomLevel.value * .4)) / zoomLevel.value));
		XY mouseInitialTranslated = new XY(round(edwin.mouseHoldInitial.x - body.x - editBounds.x) / zoomLevel.value, 
			round(edwin.mouseHoldInitial.y - body.y - editBounds.y) / zoomLevel.value);

		if (!pixelLayer.isVisible && pixelLayer != utilityLayer) return; //can't draw on layers that aren't visible, except 0 is a special case

		if (currentBrush == BRUSH) {
			//square of size brushSize
			pixelLayer.pixelRectangle(brushVal, mouseTranslated.x, mouseTranslated.y, (float)brushSize.value, (float)brushSize.value);
		}
		else if (currentBrush == RECTANGLE) {
			//just a solid block
			pixelLayer.pixelRectangle(brushVal, 
				min(mouseInitialTranslated.x, mouseTranslated.x),
				min(mouseInitialTranslated.y, mouseTranslated.y),
				abs(mouseInitialTranslated.x - mouseTranslated.x),
				abs(mouseInitialTranslated.y - mouseTranslated.y));
		}
		else if (currentBrush == PERIMETER) {
			//perimeter is the outline of a rectangle
			//so we will be adding in a rectangle of points for each side
			RectBody rectArea = new RectBody(
				min(mouseInitialTranslated.x, mouseTranslated.x),
				min(mouseInitialTranslated.y, mouseTranslated.y),
				abs(mouseInitialTranslated.x - mouseTranslated.x),
				abs(mouseInitialTranslated.y - mouseTranslated.y));
			//left
			pixelLayer.pixelRectangle(brushVal, 
				rectArea.x, 
				rectArea.y, 
				min(brushSize.value, rectArea.w), 
				rectArea.h);
			//top
			pixelLayer.pixelRectangle(brushVal, 
				rectArea.x, 
				rectArea.y, 
				rectArea.w, 
				min(brushSize.value, rectArea.h));
			//right
			pixelLayer.pixelRectangle(brushVal, 
				max(rectArea.xw() - brushSize.value, rectArea.x),
				rectArea.y, 
				min(brushSize.value, rectArea.w),
				rectArea.h);
			//bottom
			pixelLayer.pixelRectangle(brushVal, 
				rectArea.x, 
				max(rectArea.yh() - brushSize.value, rectArea.y),
				rectArea.w, 
				min(brushSize.value, rectArea.h));
		}
		else if (currentBrush == LINE) {
			//line of brushSize width
			//math.stackexchange.com/a/2109383
			float segmentIncrement = 1;
			float lineDist = mouseInitialTranslated.distance(mouseTranslated);
			XY newPoint = new XY();
			pixelLayer.pixelRectangle(brushVal, mouseTranslated.x, mouseTranslated.y, brushSize.value, brushSize.value);
			for (float segDist = 0; segDist <= lineDist; segDist += segmentIncrement) {
				newPoint.set(mouseInitialTranslated.x - (segDist * (mouseInitialTranslated.x - mouseTranslated.x)) / lineDist, 
					mouseInitialTranslated.y - (segDist * (mouseInitialTranslated.y - mouseTranslated.y)) / lineDist);
				pixelLayer.pixelRectangle(brushVal, newPoint.x, newPoint.y, brushSize.value - 1, brushSize.value - 1);
			}
		}
	}
	
	void openFile(File file) {
		if (file == null) return; //user hit cancel or closed
		setWindowTitle(file.getName());
		openFilepath = file.getAbsolutePath();
		//Next time drawSelf() is called it'll call digestAlbum() so we don't screw with variables potentially in use 
		//since we might be in the middle of drawing at this time. Then openFilepath becomes null.
	}

	/** Load file into editor variables */
	void digestFile() {
		JSONObject json = loadJSONObject(openFilepath);
		openFilepath = null;
		spriteW = json.getInt(EdFiles.PX_WIDTH);
		spriteH = json.getInt(EdFiles.PX_HEIGHT);
		palette.resetColors(json.getJSONArray(EdFiles.COLOR_PALETTE).getIntArray());
		pixelLayers.clear();
		editablePages.clear();

		//colors
		if (json.isNull(EdFiles.BGD_COLOR)) {
			if (utilityLayer.isVisible) utilityLayer.toggleVisibility();
			utilityLayer.paletteIndex = 0;
		}
		else {
			if (!utilityLayer.isVisible) utilityLayer.toggleVisibility();
			utilityLayer.paletteIndex = json.getInt(EdFiles.BGD_COLOR);
		}

		//pixel layers
		JSONArray jsonLayers = json.getJSONArray(EdFiles.PIXEL_LAYERS);
		for (int i = 0; i < jsonLayers.size(); i++) {
			JSONObject thisLayer = jsonLayers.getJSONObject(i);
			BitSet pxls = new BitSet(spriteW * spriteH);
			for (int v : thisLayer.getJSONArray(EdFiles.DOTS).getIntArray()) {
				pxls.set(v);
			}
			addPixelLayer(pxls, thisLayer.getInt(EdFiles.PALETTE_INDEX)); 
			pixelLayers.get(i).name = thisLayer.getString(EdFiles.PIXEL_LAYER_NAME);
		}
		useLayer(0);

		//pages of the album
		JSONArray jsonPages = json.getJSONArray(EdFiles.ALBUM_PAGES);
		for (int i = 0; i < jsonPages.size(); i++) {
			JSONObject page = jsonPages.getJSONObject(i);
			editablePages.add(new EditablePage(i, page.getString(EdFiles.PAGE_NAME), page.getJSONArray(EdFiles.LAYER_NUMBERS).getIntArray()));
		}
		usePage(0);
	}

	/**
	* So unfortunately for me the default toString() methods for JSONObject and JSONArray that were provided by 
	* the wonderful Processing devs give each value their own line. So the dump I'm trying to take is too big for that, 
	* and this is my attempt at significantly fewer newline characters and having a sorted readable format.
	* Also I don't know how to work with binary files.
	*/
	void saveFile(File file) {
		if (file == null) return; //user closed window or hit cancel
		ArrayList<String> fileLines = new ArrayList<String>();
		fileLines.add("{"); //opening bracket
		fileLines.add(jsonKV(EdFiles.PX_WIDTH, spriteW));
		fileLines.add(jsonKV(EdFiles.PX_HEIGHT, spriteH));
		fileLines.add(palette.asJsonKV());
		fileLines.add(jsonKV(EdFiles.BGD_COLOR, (utilityLayer.isVisible ? String.valueOf(utilityLayer.paletteIndex) : "null")));
		fileLines.add("");
		fileLines.add(jsonKVNoComma(EdFiles.PIXEL_LAYERS, "[{")); //array of objects
		BitSet pxls;
		String line;
		int valueCount;
		for (int i = 0; i < pixelLayers.size(); i++) {
			if (i > 0) fileLines.add("},{"); //separation between layer objects in this array
			fileLines.add(TAB + jsonKVString(EdFiles.PIXEL_LAYER_NAME, pixelLayers.get(i).name));
			fileLines.add(TAB + jsonKV(EdFiles.PALETTE_INDEX, pixelLayers.get(i).paletteIndex));
			fileLines.add(TAB + jsonKVNoComma(EdFiles.DOTS, "[")); 
			pxls = pixelLayers.get(i).dots;
			line = "";
			valueCount = -1;
			for (int j = 0; j < pxls.size(); j++) {
				if (!pxls.get(j)) continue;
				if (++valueCount == 25) {
					valueCount = 0;
					fileLines.add(TAB + TAB + line);
					line = "";
				}
				line += j + ", ";
			}
			fileLines.add(TAB + TAB + line);
			fileLines.add(TAB + "]"); //close DOTS
		}
		fileLines.add("}],"); //close last layer and array
		fileLines.add("");
		fileLines.add(jsonKVNoComma(EdFiles.ALBUM_PAGES, "[{"));
		for (int i = 0; i < editablePages.size(); i++) {
			if (i > 0) fileLines.add("},{"); //separation between layer objects in this array
			EditablePage page = editablePages.get(i);
			Collections.sort(page.layerIndicies);
			fileLines.add(TAB + jsonKVString(EdFiles.PAGE_NAME, page.name));
			fileLines.add(TAB + jsonKV(EdFiles.LAYER_NUMBERS, page.layerIndicies.toString()));
		}
		fileLines.add("}]"); //close last page and array
		fileLines.add("}"); //final closing bracket
		saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
		setWindowTitle(file.getName());
	}

	String getName() {
		return "AlbumEditor";
	}

	private class PixelLayer {
		NestedRectBody listBody;
		GridButtons buttons;
		BitSet dots;
		String name;
		int paletteIndex;
		boolean isVisible;

		PixelLayer(int index, int colorPaletteIndex, BitSet pxls) {
			this(index, colorPaletteIndex, pxls, new String[] { IS_VISIBLE, MOVE_DOWN, EDIT_NAME, DELETE });
		}

		PixelLayer(int index, int colorPaletteIndex, BitSet pxls, String[] buttonNames) {
			paletteIndex = colorPaletteIndex;
			dots = pxls;
			isVisible = true;
			name = "newlayer";
			buttons = new GridButtons(body, 
				layerListBounds.xw() - layerButtonAlbum.w * buttonNames.length, 
				layerListBounds.y + layerButtonAlbum.h * index, 
				buttonNames.length, 
				layerButtonAlbum, 
				buttonNames);
			listBody = new NestedRectBody(body, 
				layerListBounds.x, 
				layerListBounds.y + index * LIH,
				layerListBounds.w,
				LIH);
		}

		/** requires that the is_visible page is the first item in the array */
		void toggleVisibility() {
			isVisible = !isVisible;
			buttons.buttonPages[0] = (isVisible ? IS_VISIBLE : IS_NOT_VISIBLE);
		}

		/**
		* brushVal == true means setting pixels
		* brushVal == false means removing pixels
		*/
		void pixelRectangle(boolean brushVal, float _x, float _y, float _w, float _h) {
			//if rectangle isn't in bounds, leave
			if (_x >= spriteW || _y >= spriteH ||
				_x + _w < 0 || _y + _h < 0) {
				return;
			}
			//clamp boundaries
			_x = max(_x, 0);
			_y = max(_y, 0);
			_w = min(_w, spriteW - _x);
			_h = min(_h, spriteH - _y);
			//finally, loop through each pixel in rect and set it
			for (int y = (int)_y; y < _y + _h; y++) {
				for (int x = (int)_x; x < _x + _w; x++) {
					dots.set(y * spriteW + x, brushVal);
				}
			}
		}

		/** Create new BitSet for the pixels and copy old dots over */
		void updateBounds(int _w, int _h) {
			BitSet newDots = new BitSet(_w * _h);
			XY point = new XY();
			for (int i = 0; i < dots.size(); i++) {
				if (!dots.get(i)) continue; //if pixel isn't set, skip loop
				point.y = floor(i / (float)spriteW);
				point.x = i - (point.y * spriteW);
				if (point.x >= _w || point.y >= _h) continue;
				newDots.set((int)(point.y * _w + point.x)); //find new index with the new width
			}
			dots = newDots;
		}
	}

	private class EditablePage {
		NestedRectBody listBody;
		GridButtons buttons;
		ArrayList<Integer> layerIndicies;
		String name;

		EditablePage(int index, String pageName, int[] layerIds) {
			name = pageName;
			layerIndicies = new ArrayList<Integer>(); //visible PixelLayers
			for (int i = 0; i < layerIds.length; i++) {
				layerIndicies.add(layerIds[i]);
			}
			String[] buttonNames = new String[] { MOVE_DOWN, EDIT_NAME, DELETE };
			buttons = new GridButtons(body, 
				layerListBounds.xw() - layerButtonAlbum.w * buttonNames.length, 
				layerListBounds.y + layerButtonAlbum.h * index, 
				buttonNames.length, 
				layerButtonAlbum, 
				buttonNames);
			listBody = new NestedRectBody(body, 
				layerListBounds.x, 
				layerListBounds.y + index * LIH,
				layerListBounds.w,
				LIH);
		}

		void setLayerVisibility(int index, boolean visible) {
			int existing = -1;
			for (int i = 0; i < layerIndicies.size(); i++) {
				if (layerIndicies.get(i) == index) {
					existing = i;
					break;
				}
			}
			if (visible && existing == -1) { //if we want to set it and it doesn't exist
				layerIndicies.add(index);
			}
			else if (!visible && existing != -1) { //if we want to remove it and it does exist
				layerIndicies.remove(existing);
			}
		}

		void deleteLayer(int index) {
			int existing = -1;
			for (int i = 0; i < layerIndicies.size(); i++) {
				if (layerIndicies.get(i) == index) {
					existing = i;
				}
				else if (layerIndicies.get(i) > index) {
					layerIndicies.set(i, layerIndicies.get(i) - 1); //shift other layers up a value
				}
			} 
			if (existing != -1) {
				layerIndicies.remove(existing);
			}
		}
	}

} //end AlbumEditor

// JOptionPane.showMessageDialog(null, "omg lookout", "Hey", JOptionPane.INFORMATION_MESSAGE);
// int selected = JOptionPane.showConfirmDialog(null, "Really wanna delete this?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
// if (selected == JOptionPane.YES_OPTION) { ... }
