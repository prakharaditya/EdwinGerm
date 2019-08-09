
import java.util.Arrays;
import java.util.BitSet;
import java.util.Collections;
import java.util.Map;
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
* So far Components haven't been useful for me so they're commented out
* and I've renamed Entities to Kids, and Systems to Schemes.
* The rules aren't very fixed - from this base you can go in many directions
* and I haven't even needed a Scheme yet...
*/
interface Kid {
	void drawSelf(PGraphics canvas);
	String getName(); //might not be useful, may remove
	//void think();
	//boolean hasComponent(Component comp); 
}
//interface Component { } //not really useful atm
interface MouseReactive { String mouse(); } //returns a String so it can communicate backwards to whoever called it
interface KeyReactive { String keyboard(KeyEvent event); }
interface Scheme { void play(ArrayList<Kid> kids); }

/**
* Edwin the art/game "engine" that's currently in alpha and totally free 
* to edit and use as you want. It essentially allows you to have layers 
* in Processing that can be turned on or off. Then each Kid class gets
* its own draw function, plus a mouse and/or keyboard function if you want.
* To use the editor make sure to include edwin.addKid(new EditorWindow()); to your setup()
* See a small example project below this class. Made by moonbaseone@hush.com
*/
class Edwin {
	PGraphics canvas;
	PFont defaultFont;
	ArrayList<Scheme> schemes;
	ArrayList<Kid> kids, leaving; 
	ArrayList<MouseReactive> mouseKids;
	ArrayList<KeyReactive> keyKids;
	//now for some values you might check in your Kid classes
	XY mouseHoldInitial, mouseLast;
	int mouseHoldStartMillis, mouseHeldMillis, tickLength, mouseTicking;
	int mouseBtnBeginHold, mouseBtnHeld, mouseBtnReleased, mouseWheelValue;
	boolean useSmooth, mouseHoldTicked, mouseHovering;

	Edwin() { 
		canvas = createGraphics(width, height);
		defaultFont = createFont(EdFiles.DATA_FOLDER + "consolas.ttf", 12); //not necessary to have
		schemes = new ArrayList<Scheme>();
		kids = new ArrayList<Kid>();
		leaving = new ArrayList<Kid>(); //in Schemes if a Kid needs to be euthanized use edwin.leave(kid)
		mouseKids = new ArrayList<MouseReactive>();
		keyKids = new ArrayList<KeyReactive>();
		mouseHoldInitial = new XY();
		mouseLast = new XY();
		mouseHeldMillis = mouseHoldStartMillis = mouseTicking = 0;
		mouseBtnHeld = mouseBtnBeginHold = mouseBtnReleased = mouseWheelValue = 0;
		useSmooth = true; //use Processing's built-in smooth() or noSmooth()
		mouseHoldTicked = false; //true for one draw tick every couple ms when you've been holding down a mouse button
		mouseHovering = false;
		tickLength = 17;
	}

	void addScheme(Scheme scheme) {
		schemes.add(scheme);
	}

	void addKid(Kid kid) {
		kids.add(kid);
		if (kid instanceof MouseReactive) {
			mouseKids.add((MouseReactive)kid);
		}
		if (kid instanceof KeyReactive) {
			keyKids.add((KeyReactive)kid);
		}
	}

	/** Use this in Schemes to safely remove Kids */
	void leave(Kid kid) {
		leaving.add(kid);
	}

	void update() {
		if (mouseBtnHeld != 0) {
			mouseHeldMillis = millis() - mouseHoldStartMillis; //gives a more reliable figure than using mouse events to update
			if (++mouseTicking > tickLength) {
				mouseTicking = 0;
				mouseHoldTicked = true;
			}
		}

		for (Scheme scheme : schemes) {
			scheme.play(kids);
		}
		for (Kid kid : leaving) {
			kids.remove(kid);
		}
		leaving.clear();

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
			mouseBtnBeginHold = mouseBtnHeld = mouseButton;
			mouseHoldStartMillis = millis();
			mouseBtnReleased = 0;
		}
		else if (action == MouseEvent.RELEASE) {
			mouseBtnReleased = mouseBtnHeld;
			mouseBtnBeginHold = mouseBtnHeld = 0;
			resetMouse = true; //other resets need to happen after calling each MouseReactive so they can use the values first
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

		for (MouseReactive kid : mouseKids) {
			//if (kid.mouse() != "") break; //notify the kids. if any respond we assume it handled the event and we don't need to check others
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
		for (KeyReactive kid : keyKids) {
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
	edwin.addKid(new Simple());

	String[] buttons = new String[] { EditorWindow.BRUSH, EditorWindow.LINE, EditorWindow.PERIMETER, EditorWindow.ADD_LAYER, EditorWindow.ZOOM_OUT }; 
	Kid someMenu = new GridButtons(20, 80, 3, new Album(EditorWindow.TOOL_MENU_FILENAME, 2.0), buttons) {
		@Override
		public void buttonClick(String clicked) { 
			aNum += 1;
			println(clicked + " " + aNum);
		}
	};
	edwin.addKid(someMenu);
}

void draw() {
	edwin.update();
	image(edwin.canvas, 0, 0);
}



class Simple implements Kid, MouseReactive {
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
	boolean equals(float _x, float _y) { return (x == _x && y == _y); }
	boolean equals(XY other) { return equals(other.x, other.y); }
	void set(float _x, float _y) { x = _x; y = _y; }
	void set(XY other) { set(other.x, other.y); }
	float distance(float _x, float _y) { return sqrt(pow(x - _x, 2) + pow(y - _y, 2)); }
	float distance(XY other) { return distance(other.x, other.y); }
	float angle(float _x, float _y) { return atan2(y - _y, x - _x); } //radians
	float angle(XY other) { return angle(other.x, other.y); }
	float angCos(XY other) { return cos(angle(other)); }
	float angSin(XY other) { return sin(angle(other)); }
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
	boolean equals(float _x, float _y, float _w, float _h) { return (x == _x && y == _y && w == _w && h == _h); }
	boolean equals(RectBody other) { return equals(other.x, other.y, other.w, other.h); }
	void set(float _x, float _y, float _w, float _h) { x = _x; y = _y; w = _w; h = _h; }
	void set(RectBody other) { set(other.x, other.y, other.w, other.h); }
	void setSize(float _w, float _h) { w = _w; h = _h; }
	void setSize(RectBody other) { setSize(other.w, other.h); }

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
* see EditorWindow example usage
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
	String toString() { return "[min:" + minimum + "|max:" + maximum + "|val:" + value + "]"; }
	BoundedInt clone() { BoundedInt schwarzenegger = new BoundedInt(minimum, maximum, value, step); schwarzenegger.loops = loops; schwarzenegger.isEnabled = isEnabled; return schwarzenegger; }
	boolean contains(int num) { return (num >= minimum && num <= maximum); }
	void set(int num) { value = min(max(minimum, num), maximum); } //assign value to num, or to minimum/maximum if it's out of bounds
	void reset(int newMin, int newMax) { reset(newMin, newMax, newMin); }
	void reset(int newMin, int newMax, int num) { minimum = newMin; maximum = newMax; value = num; }
	int randomize() { value = (int)random(minimum, maximum + 1); return value; } //+1 here because the max of random() is exclusive
	int minimize() { value = minimum; return value; }
	int maximize() { value = maximum; return value; }
	boolean atMin() { return (value == minimum); }
	boolean atMax() { return (value == maximum); }

	int increment() { return increment(step); }
	int increment(int num) {
		if (value + num > maximum) {
			if (loops) value = minimum;
			return value;
		}
		value += num;
		return value;
	}

	int decrement() { return decrement(step); }
	int decrement(int num) {
		if (value - num < minimum) {
			if (loops) value = maximum;
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
	String toString() { return "[min:" + minimum + "|max:" + maximum + "|val:" + value + "]"; }
	BoundedFloat clone() { BoundedFloat schwarzenegger = new BoundedFloat(minimum, maximum, value, step); schwarzenegger.loops = loops; schwarzenegger.isEnabled = isEnabled; return schwarzenegger; }
	boolean contains(float num) { return (num >= minimum && num <= maximum); }
	void set(float num) { value = min(max(minimum, num), maximum); } //assign value to num, or to minimum/maximum if it's out of bounds
	void reset(float newMin, float newMax) { reset(newMin, newMax, newMin); }
	void reset(float newMin, float newMax, float num) { minimum = newMin; maximum = newMax; value = num; }
	float randomize() { value = random(minimum, maximum); return value; }
	float minimize() { value = minimum; return value; }
	float maximize() { value = maximum; return value; }
	boolean atMin() { return value == minimum; }
	boolean atMax() { return value == maximum; }

	//it could be argued that these should return the value instead of a boolean, then you'd check atMin() or atMax() if you're looking for that...
	float increment() { return increment(step); }
	float increment(float num) {
		if (value + num > maximum) {
			if (loops) value = minimum;
			return value;
		}
		value += num;
		return value;
	}

	float decrement() { return decrement(step); }
	float decrement(float num) {
		if (value - num < minimum) {
			if (loops) value = maximum;
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



class Command {
	void execute(String arg) {
		println("uh oh, empty Command object [arg=" + arg + "]");
		//void execute() {
		//println("uh oh, empty Command object");
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
	//println("len:" + values.length +"  0:" + values[0] + "  max:" + values[values.length - 1]);
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
String TAB = "\t";


/** Constants */
class EdColors {
	//Edwin VanCleef https://media-hearth.cursecdn.com/avatars/331/109/3.png
	//https://lospec.com/palette-list/dirtyboy
	public static final int DEFAULT_BACKGROUND = #000000,
	UI_LIGHT = #C4CFA1, 
	UI_NORMAL = #8B956D, 
	UI_DARK = #4D533C,
	UI_DARKEST = #1F1F1F,
	UI_EMPHASIS = #73342E,
	INFO = #5881C1,
	ROW_EVEN = #050505,
	ROW_ODD = #101010;
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
* A kind of sprite sheet that is made by my tile editor EditorWindow.
* Albums have one set of pixel layers, and another set of "pages" that use 
* any number of those pixel layers to create an image. Also requires a 
* small color palette where each pixel layer uses one color. This allows you to
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
				sheet.background(json.getInt(EdFiles.BGD_COLOR));
			}
			//loop through each pixel layer used by the page
			for (int visibleLayerIndex : jsonPage.getJSONArray(EdFiles.LAYER_NUMBERS).getIntArray()) {
				JSONObject thisLayer = jsonLayers.getJSONObject(visibleLayerIndex);
				sheet.fill(colorPalette.getInt(thisLayer.getInt(EdFiles.PALETTE_INDEX)));
				//draw layer to current page
				for (int pixelIndex : thisLayer.getJSONArray(EdFiles.DOTS).getIntArray()) {
					//translate pixel index (from BitSet) to its xy coord
					y = (int)(pixelIndex / pixelW);
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
}



/**
* A set of menu buttons that line up in a grid next to each other according to the number of columns specified. 
* The page names supplied (albumPages) become the buttons. To handle a button press you can either
* check its mouse() function to get the page name clicked, or you can override buttonClick()
* Checkboxes start as false (so togglePages should contain the true/enabled album pages, if any)
*/
class GridButtons implements Kid, MouseReactive {
	NestedRectBody body;
	Album buttonAlbum;
	String[] buttonPages, altPages, origPages;
	int columns;

	GridButtons(RectBody parent, float anchorX, float anchorY, int numCols, Album album, String[] albumPages) {
		this(parent, anchorX, anchorY, numCols, album, albumPages, albumPages);
	}

	GridButtons(RectBody parent, float anchorX, float anchorY, int numCols, Album album, String[] albumPages, String[] togglePages) {
		columns = min(max(1, numCols), albumPages.length); //quick error checking
		body = new NestedRectBody(parent, anchorX, anchorY, columns * album.w, ceil(albumPages.length / (float)columns) * album.h);
		buttonAlbum = album;
		buttonPages = albumPages;
		altPages = togglePages; //should have the same number of elements as albumPages when using toggleImage()
		origPages = albumPages.clone();
	}

	/** Override this when adding directly to Edwin **/
	void buttonClick(String clicked) { }
	/*************************************************/

	void drawSelf(PGraphics canvas) {
		for (int i = 0; i < buttonPages.length; i++) {
			canvas.image(buttonAlbum.page(buttonPages[i]), 
				body.x + (i % columns) * buttonAlbum.w, 
				body.y + (i / columns) * buttonAlbum.h);
		}
	}

	String mouse() { 
		if (!body.isMouseOver() ||
			(edwin.mouseBtnHeld == 0 && edwin.mouseBtnReleased != LEFT) ||
			(edwin.mouseBtnReleased == 0 && edwin.mouseBtnHeld != LEFT)) {
			return "";
		}
		int index = indexAtMouse();
		if (index < buttonPages.length) {
			buttonClick(buttonPages[index]);
			return buttonPages[index]; //respond with the page name of the button that was clicked
		}
		return "";
	}

	void toggleImage() { toggleImage(0); }
	void toggleImage(int index) { setCheck(index, (buttonPages[index] == origPages[index])); }
	void setCheck(boolean check) { setCheck(0, check); }
	void setCheck(int index, boolean check) {
		if (check) buttonPages[index] = altPages[index];
		else buttonPages[index] = origPages[index];
	}

	int indexAtMouse() { return indexAtPosition(mouseX, mouseY); }
	int indexAtPosition(XY point) { return indexAtPosition(point.x, point.y); }
	int indexAtPosition(float _x, float _y) {
		float relativeX = _x - body.realX();
		float relativeY = _y - body.realY();
		int index = (int)(floor(relativeY / buttonAlbum.h) * columns + (relativeX / buttonAlbum.w)); 
		// println("mouseX:" + mouseX + " relativeX:" + relativeX);
		// println("mouseY:" + mouseY + " relativeY:" + relativeY + "  i:" + i);
		return index;
	}

	String getName() {
		return "GridButtons";
	}
}



/**
* A floating draggable window you put GridButtons + labels on.
* Make sure to override buttonClick(PanelItem, String) 
* to handle the menu click when you create one of these 
*/
class GadgetPanel implements Kid, MouseReactive {
	ArrayList<PanelItem> panelItems; //each of these has a GridButtons
	Album buttonAlbum;
	RectBody body;
	NestedRectBody dragBar;
	XY dragOffset;
	String title, panelLabel;
	boolean isVisible, beingDragged;
	int UI_PADDING = 4, TX_OFFSET = 9;
	//constants for the Album's pages
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
	START_LIGHT = "start light",
	STOP_LIGHT = "stop light",
	OVER_UNDER = "over under",
	OVER_UNDER_DOWN = "over under down",
	SIDE_SIDE = "side side",
	SIDE_SIDE_DOWN = "side side down";

	GadgetPanel() { this(""); }
	GadgetPanel(String label) { this(50, 50, label); }
	GadgetPanel(XY anchor) { this(anchor.x, anchor.y, ""); }
	GadgetPanel(XY anchor, String label) { this(anchor.x, anchor.y, label); }
	GadgetPanel(float _x, float _y, String label) { this(_x, _y, label, new Album(BUTTON_FILENAME)); }
	GadgetPanel(float _x, float _y, String label, Album album) {
		buttonAlbum = album;
		TX_OFFSET *= album.scale; //rough placement for text
		panelLabel = title = label; //displayed in dragBar
		panelItems = new ArrayList<PanelItem>();
		body = new RectBody(_x, _y, panelLabel.length() * 7, buttonAlbum.h + UI_PADDING * 3); //7 here is an estimate of how many pixels wide one character is
		dragBar = new NestedRectBody(body, UI_PADDING, UI_PADDING, body.w - UI_PADDING * 2, buttonAlbum.h);
		dragOffset = new XY();
		isVisible = true;
		beingDragged = false;
	}

	/** Override this when creating a new GadgetPanel */
	//void buttonClick(PanelItem item, String clicked) { }
	//void buttonTick(PanelItem item, String ticked) { }
	/**************************************************/

	void addItem(String label, String page, Command cmd) { addItem(label, new String[] { page }, cmd); }
	void addItem(String label, String page, String alt, Command cmd) { addItem(label, new String[] { page }, new String[] { alt }, cmd); }
	void addItem(String label, String[] pages, Command cmd) { addItem(label, pages, pages, cmd); }
	void addItem(String label, String[] pages, String[] alts, Command cmd) { addItem(label, new GridButtons(body, 0, 0, 5, buttonAlbum, pages, alts), cmd); }
	void addItem(String label, GridButtons buttons, Command cmd) {
		buttons.body.set(UI_PADDING, body.h - UI_PADDING); //reset position of GridButtons
		panelItems.add(new PanelItem(label, buttons, cmd));
		float itemWidth = buttons.body.w + label.length() * 7 + UI_PADDING * 2; 
		if (itemWidth > body.w) {
			body.w = itemWidth;
			dragBar.w = body.w - UI_PADDING * 2;
		}
		body.h += buttons.body.h;
	}

	GridButtons getButtons(String label) {
		for (PanelItem item : panelItems) {
			if (item.label.equals(label)) {
				return item.buttons;
			}
		}
		println("Uh oh, no GadgetPanel.PanelItem found with the label " + label);
		return null;
	}

	void itemExecute(String label, String arg) {
		for (PanelItem item : panelItems) {
			if (item.label.equals(label)) {
				item.command.execute(arg);
				return;
			}
		}
		println("Uh oh, no GadgetPanel.PanelItem found with the label " + label);
	}

	void toggleVisibility() {
		isVisible = !isVisible;
	}

	void drawSelf(PGraphics canvas) {
		if (!isVisible) return;
		// if (edwin.mouseHoldTicked && body.isMouseOver()) {
		// 	for (PanelItem item : panelItems) {
		// 		String menuHeld = item.buttons.mouse();
		// 		if (menuHeld != "") {
		// 			buttonTick(item, menuHeld);
		// 			break;
		// 		}
		// 	}
		// }
		canvas.pushMatrix();
		canvas.translate(body.x, body.y);
		canvas.stroke(EdColors.UI_DARKEST);
		canvas.fill(EdColors.UI_NORMAL);
		canvas.rect(0, 0, body.w, body.h);
		canvas.noStroke();
		canvas.fill(EdColors.UI_DARK);
		canvas.rect(dragBar.x, dragBar.y, dragBar.w, dragBar.h);
		canvas.fill(EdColors.UI_LIGHT);
		canvas.text(panelLabel, dragBar.x + UI_PADDING, dragBar.yh() - TX_OFFSET);
		canvas.fill(EdColors.UI_DARKEST);
		for (PanelItem item : panelItems) {
			canvas.text(item.label, item.labelPos.x, item.labelPos.y);
			item.buttons.drawSelf(canvas);
		}
		canvas.popMatrix();
	}

	String mouse() {
		if (!isVisible) return "";

		if (beingDragged) {
			body.set(mouseX - dragOffset.x, mouseY - dragOffset.y);
			if (edwin.mouseBtnReleased == LEFT) {
				beingDragged = false;
			}
			return "dragging";
		}
		
		if (edwin.mouseBtnBeginHold == LEFT && dragBar.isMouseOver()) {
			beingDragged = true;
			dragOffset.set(mouseX - body.x, mouseY - body.y);
			panelLabel = title;
			return "begin drag";
		}

		if (edwin.mouseBtnReleased == LEFT && body.isMouseOver()) {
			for (PanelItem item : panelItems) {
				String buttonPage = item.buttons.mouse();
				if (buttonPage != "") {
					//buttonClick(item, buttonPage);
					item.command.execute(buttonPage);
					//beware - if you use the same button (page) multiple times in the same panel then just checking mouse() won't be able to tell you which one was clicked.
					//I think it's best to handle clicks by overriding buttonClick() rather than using the GadgetPanel's mouse() function
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
* Place and scale a reference image for making stuff with other stuff.
* Use the middle mouse button to drag it around, or arrows keys for 1 pixel movement
*/
public class ReferenceImagePositioner implements Kid, MouseReactive, KeyReactive {
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

	ReferenceImagePositioner() {
		body = new RectBody();
		scale = new BoundedInt(10, 200, 100, 10);
		refImage = null;
		imageFile = null;
		imageVisible = false;
		gPanel = new GadgetPanel(50, 50, "(I) Reference Img");

		gPanel.addItem("open image", GadgetPanel.OPEN, new Command() {
			void execute(String arg) {
				selectInput("Open reference image", "openFile", null, ReferenceImagePositioner.this);
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
					gPanel.panelLabel = "no image open";
					return;
				}
				else if (arg == GadgetPanel.PLUS) {
					scale.increment();
				}
				else if (arg == GadgetPanel.MINUS) {
					scale.decrement();
				}
				gPanel.panelLabel = SCALE + ":" + scale.value + "%";
				refImage.resize((int)(origW * (scale.value / 100.0)), (int)(origH * (scale.value / 100.0)));
			}
		});

		gPanel.addItem(IS_VISIBLE, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
			void execute(String arg) {
				imageVisible = !imageVisible;
				gPanel.panelLabel = IS_VISIBLE + ":" + imageVisible;
				gPanel.getButtons(IS_VISIBLE).toggleImage();
			}
		});
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
		else if (edwin.mouseBtnHeld == CENTER) {
			body.set(mouseX, mouseY);
			setGPLabel();
		}
		return ""; 
	}

	void setGPLabel() { gPanel.panelLabel = "x:" + (int)body.x +  "|y:" + (int)body.y; }

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
		else if (kc == Keycodes.VK_LEFT) {
			body.x--;
			setGPLabel();
		}
		else if (kc == Keycodes.VK_RIGHT) {
			body.x++;
			setGPLabel();
		}
		else if (kc == Keycodes.VK_UP) {
			body.y--;
			setGPLabel();
		}
		else if (kc == Keycodes.VK_DOWN) {
			body.y++;
			setGPLabel();
		}
		return "";
	}

	void openFile(File file) {
		if (file == null) return; //user hit cancel or closed
		imageFile = file;
		refImage = loadImage(imageFile.getAbsolutePath());
		origW = refImage.width;
		origH = refImage.height;
		body.setSize(origW, origH);
		scale.set(100);
		imageVisible = true;
		gPanel.panelLabel = imageFile.getName();
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
* This lets you easily make changes that cascade to all pages that use (some of) the same layers. 
* And restricting colors to a palette allows you change it for all sprites/pages at once. 
* The UI is kinda tricky right now though...The only way to see the pages menu is to hit X on your keyboard to toggle.
* You can use up/down to move between layers or pages, depending on which list is shown.
* When choosing a color from the palette a quick click will use the color, 
* while a long click lets you choose a new color in that slot.
*/
public class EditorWindow implements Kid, MouseReactive, KeyReactive {
	ArrayList<PixelLayer> pixelLayers;
	ArrayList<EditablePage> editablePages;
	ArrayList<Integer> colorPalette;
	GridButtons toolMenu;
	Album layerButtons;
	XY dragOffset;
	RectBody body;
	NestedRectBody editBounds, previewBounds, layerListBounds, dragBar;
	BoundedInt brushSize, zoomLevel, selectedLayer, selectedPage;
	BoundedFloat previewZoomLevel;
	String currentBrush, openFilepath;
	boolean isVisible, beingDragged, showPalette, showPages;
	int spriteW, spriteH, maxColors;

	final int MS_THRESHOLD = 500, //number of milliseconds you need to hold for certain clicks
	UI_PADDING = 6, //distance between UI elements
	LIH = 10; //list item height - height of layer list items, and width of its buttons

	//here I'm hardcoding page names from the albums
	//so if you edit the buttons don't rename the pages
	public static final String TOOL_MENU_FILENAME = "editorButtons.alb",
	//main editor menu buttons
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
	NEW_PAGE = "newPage",
	//layer list item buttons
	LAYER_MENU_FILENAME = "layerButtons.alb",
	DELETE = "delete",
	IS_VISIBLE = "isVisible",
	IS_NOT_VISIBLE = "isNotVisible",
	MOVE_DOWN = "moveDown",
	EDIT_COLOR = "editColor",
	EDIT_NAME = "editName",
	EDIT_EXPRESSIONS = "editExpressions"; //"Albums with Pages" used be to called "Symbols with Expressions"

	EditorWindow() { 
		spriteW = 24;
		spriteH = 24;
		currentBrush = BRUSH;
		showPalette = showPages = beingDragged = false;
		isVisible = true; //whether the EditorWindow itself is visible on screen
		openFilepath = null; //stays null until a new file is opened, at which point it will be loaded the next time drawSelf() is called
		int margin = 50; //optional, can be 0 to take up the whole screen
		body = new RectBody(margin, margin, max(width - margin * 2, 600), max(height - margin * 2, 400));
		selectedLayer = new BoundedInt(0); //min gets updated later to 1 because layer 0 is the bgd layer which is hijacked to hold the brush preview
		selectedPage = new BoundedInt(0);
		zoomLevel = new BoundedInt(1, 30, 6);
		previewZoomLevel = new BoundedFloat(0.5, 4, 1, 0.5);
		brushSize = new BoundedInt(1, 20, 3);
		dragOffset = new XY(); //for when the window is being dragged
		layerButtons = new Album(LAYER_MENU_FILENAME);
		Album brushMenuAlbum = new Album(TOOL_MENU_FILENAME);
		int menuColumns = 4; //can be changed but this seems best
		int menuW = menuColumns * (int)brushMenuAlbum.w;
		maxColors = (menuW / LIH); //not great design... this limits the number of colors in the palette to the width of toolMenu
		XY ui = new XY(UI_PADDING, UI_PADDING); //anchor for current UI body
		dragBar = new NestedRectBody(body, ui.x, ui.y, body.w - UI_PADDING * 2, LIH);
		ui.y += dragBar.h + UI_PADDING;
		editBounds = new NestedRectBody(body, ui.x + menuW + UI_PADDING, ui.y, body.w - menuW - UI_PADDING * 3, body.h - dragBar.h - UI_PADDING * 3); 
		previewBounds = new NestedRectBody(body, ui.x, ui.y, menuW, menuW);
		ui.y += previewBounds.h + UI_PADDING;
		toolMenu = new GridButtons(body, ui.x, ui.y, menuColumns, brushMenuAlbum, new String[] { 
			BRUSH, LINE, BRUSH_SMALLER, BRUSH_BIGGER, 
			RECTANGLE, PERIMETER, ZOOM_OUT, ZOOM_IN, 
			OPEN, SAVE, NEW_PAGE, ADD_LAYER
		});
		ui.y += toolMenu.body.h + UI_PADDING;
		layerListBounds = new NestedRectBody(body, ui.x, ui.y, menuW, body.h - ui.y - UI_PADDING);
		pixelLayers = new ArrayList<PixelLayer>();
		editablePages = new ArrayList<EditablePage>();
		colorPalette = new ArrayList<Integer>();
		colorPalette.add(#FFFFFF); //bgd
		colorPalette.add(#000000); //first layer
		resetLayers(); 
		addPixelLayer();
		editablePages.add(new EditablePage(0, "first page", new int[] { 0 }));
	}

	String getName() { 
		return "EditorWindow";
	}

	/**
	* Layer 0 is hijacked to use the color as sprite bgd, 
	* use a different GridButtons, and to use its pixels as the brush preview
	*/
	void resetLayers() {
		pixelLayers.clear();
		pixelLayers.add(new PixelLayer(0, 0, new BitSet(spriteW * spriteH), new String[] { IS_VISIBLE }));
		//pixelLayers.get(0).name = "background";
		selectedLayer.reset(1, 0); //setting a min of 1 here (with a max of 0) is kind of a stupid hack because addPixelLayer should be the next call
		selectedPage.reset(0, 0);
		editablePages.clear();
	}

	void addPixelLayer() {
		addPixelLayer(new BitSet(spriteW * spriteH), 1);
	}

	void addPixelLayer(BitSet pxls, int paletteIndex) {
		selectedLayer.incrementMax();
		selectedLayer.maximize();
		pixelLayers.add(new PixelLayer(selectedLayer.value, paletteIndex, pxls));
	}

	/** Input layer index, receive color from palette */
	int colr(int index) {
		return colorPalette.get(pixelLayers.get(index).paletteIndex);
	}

	// big methods ============================================================================================================================================
	void drawSelf(PGraphics canvas) { // ======================================================================================================================
		//canvas.beginDraw() has already been called in Edwin
		if (!isVisible) return;

		//This is so that we can't use the new Album from digestFile() while the old one is still being drawn
		//openFilepath stays null until a new Album file is opened
		if (openFilepath != null) digestFile();
		
		//This must be called before translations, and popMatrix() reverses them
		canvas.pushMatrix(); 
		//This translate call is the benefit and requirement of using NestedRectBodys
		//It allows us to keep the EditorWindow's body anchor separate so everything can now draw from 0,0 
		canvas.translate(body.x, body.y);

		//editor window bgd
		canvas.stroke(EdColors.UI_DARKEST);
		canvas.fill(EdColors.UI_NORMAL);
		canvas.rect(0, 0, body.w, body.h);

		//blank bgds
		canvas.noStroke();
		canvas.fill(EdColors.UI_DARKEST);
		canvas.rect(editBounds.x, editBounds.y, editBounds.w, editBounds.h);
		//canvas.fill(EdColors.UI_LIGHT);
		canvas.fill(EdColors.UI_DARK);
		canvas.rect(dragBar.x, dragBar.y, dragBar.w, dragBar.h);
		canvas.rect(previewBounds.x, previewBounds.y, previewBounds.w, previewBounds.h);
		canvas.rect(layerListBounds.x, layerListBounds.y, layerListBounds.w, layerListBounds.h);

		//sprite bgds
		if (pixelLayers.get(0).isVisible) { //layer 0 hijacked
			canvas.fill(colr(0));
			canvas.rect(editBounds.x, editBounds.y, min(spriteW * zoomLevel.value, editBounds.w), min(spriteH * zoomLevel.value, editBounds.h));
			canvas.rect(previewBounds.x, previewBounds.y, min(spriteW * previewZoomLevel.value, previewBounds.w), min(spriteH * previewZoomLevel.value, previewBounds.h));
		}

		//draw each layer scaled at zoomLevel
		PixelLayer thisLayer;
		float pixelX, pixelY;
		RectBody scaledPixel = new RectBody(); 
		for (int i = 1; i <= pixelLayers.size(); i++) {
			if (i == pixelLayers.size()) i = 0; //hack to draw layer 0 last
			thisLayer = pixelLayers.get(i);

			//set color
			if (i == 0) {
				canvas.fill(EdColors.UI_EMPHASIS); //brush preview color
			} 
			else if (!thisLayer.isVisible) {
				continue; 
			}
			else {
				canvas.fill(colr(i));
			}

			//loop through BitSet, draw each pixel for this layer factoring in zoomLevel
			for (int j = 0; j < thisLayer.dots.size(); j++) {
				if (!thisLayer.dots.get(j)) continue; //if pixel isn't set, skip loop iteration
				
				//calculate coords based on the dot's index
				pixelY = round(j / spriteW);
				pixelX = j - (pixelY * spriteW);

				//draw pixel in top left preview
				canvas.rect(previewBounds.x + pixelX * previewZoomLevel.value, 
					previewBounds.y + pixelY * previewZoomLevel.value, 
					ceil(previewZoomLevel.value), 
					ceil(previewZoomLevel.value));

				//determine rectangle to draw that represents the current pixel with current zoom level
				//and clipped at the edges if necessary
				scaledPixel.set(
					editBounds.x + pixelX * zoomLevel.value,
					editBounds.y + pixelY * zoomLevel.value,
					min(zoomLevel.value, editBounds.xw() - editBounds.x - pixelX * zoomLevel.value), 
					min(zoomLevel.value, editBounds.yh() - editBounds.y - pixelY * zoomLevel.value));
				//finally if we're in the pane, draw the zoomed pixel
				if (editBounds.intersects(scaledPixel)) {
					canvas.rect(scaledPixel.x, scaledPixel.y, scaledPixel.w, scaledPixel.h);
				}
			}

			if (i == 0) break; //undo hack
		}

		//pixel grid lines
		if (zoomLevel.value >= 6) {
			XY gridPt0 = new XY();
			XY gridPt1 = new XY();
			//vertical lines
			gridPt0.x = editBounds.x;
			gridPt1.x = editBounds.insideX(editBounds.x + spriteW * zoomLevel.value);
			for (int _y = 1; _y < spriteH; _y++) { 
				if (_y % 10 == 0) canvas.stroke(50, 200);
				else if (zoomLevel.value < 12) continue;
				else canvas.stroke(120, 100);
				gridPt0.y = gridPt1.y = editBounds.insideY(editBounds.y + _y * zoomLevel.value);
				canvas.line(gridPt0.x, gridPt0.y, gridPt1.x, gridPt1.y);
			}
			//horizontal lines
			gridPt0.y = editBounds.y;
			gridPt1.y = editBounds.insideY(editBounds.y + spriteH * zoomLevel.value);
			for (int _x = 1; _x < spriteW; _x++) { 
				if (_x % 10 == 0) canvas.stroke(50, 200);
				else if (zoomLevel.value < 12) continue;
				else canvas.stroke(120, 100);
				gridPt0.x = gridPt1.x = editBounds.insideX(editBounds.x + _x * zoomLevel.value);
				canvas.line(gridPt0.x, gridPt0.y, gridPt1.x, gridPt1.y);
			}
			canvas.noStroke();
		}

		//draw menus
		toolMenu.drawSelf(canvas); //brushes, zoom, open/save and other buttons
		//layer list items/menus
		if (showPages) {
			for (int i = 0; i < editablePages.size(); i++) {
				canvas.fill((i % 2 == 0) ? EdColors.ROW_EVEN : EdColors.ROW_ODD);
				//canvas.rect(layerListBounds.x, layerListBounds.y + LIH * i, layerListBounds.w, LIH);
				canvas.rect(
					((selectedPage.value == i) ? layerListBounds.x - UI_PADDING : layerListBounds.x), 
					layerListBounds.y + (LIH * i), 
					((selectedPage.value == i) ? layerListBounds.w + UI_PADDING * 2 : layerListBounds.w), 
					LIH);
				listLabel(canvas, editablePages.get(i).name, i);
				editablePages.get(i).buttons.drawSelf(canvas);
			}
		}
		else {
			//draw bgd list layer bar
			canvas.fill(colr(0));
			canvas.rect(layerListBounds.x, layerListBounds.y, layerListBounds.w, LIH);
			//show palette or regular buttons
			if (showPalette) {
				listLabel(canvas, "palette", 0);
				//draw palette squares
				//starting at 1 because we use index 0 for the background (and brush preview)
				for (int i = 1; i < colorPalette.size(); i++) {
					canvas.fill(colorPalette.get(i));
					canvas.rect(layerListBounds.xw() - (LIH * i), layerListBounds.y, LIH, LIH);
				}
			}
			else {
				listLabel(canvas, editablePages.get(selectedPage.value).name, 0);
				pixelLayers.get(0).buttons.drawSelf(canvas); //another reason to hijack layer 0
			}

			//layer list items
			for (int i = 1; i < pixelLayers.size(); i++) {
				canvas.fill(colr(i));
				//if this is the selected layer, display its name
				if (i == selectedLayer.value) {
					canvas.rect(
						layerListBounds.x - UI_PADDING,
						layerListBounds.y + (LIH * i), 
						layerListBounds.w + UI_PADDING * 2, 
						LIH);
					listLabel(canvas, pixelLayers.get(i).name, i);
				}
				else {
					canvas.rect(
						layerListBounds.x, 
						layerListBounds.y + (LIH * i), 
						layerListBounds.w, 
						LIH);
				}
				pixelLayers.get(i).buttons.drawSelf(canvas);
			}
		}

		//indicator that you've been holding down the mouse
		if (edwin.mouseHeldMillis > MS_THRESHOLD && layerListBounds.isMouseOver()) {
			canvas.fill(255, 0, 255, 150);
			canvas.ellipse(mouseX - body.x, mouseY - body.y, 10, 10);
		}

		canvas.popMatrix(); //undo translate()
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
		if (!isVisible) {
			return "";
		}
		
		if (beingDragged) {
			body.set(mouseX - dragOffset.x, mouseY - dragOffset.y);
			if (edwin.mouseBtnReleased != 0) {
				beingDragged = false;
			}
			return getName();
		}
		
		if (edwin.mouseBtnBeginHold != 0) {
			pixelLayers.get(0).dots.clear(); //clear brush preview
			if (dragBar.isMouseOver()) {
				beingDragged = true;
				dragOffset.set(mouseX - body.x, mouseY - body.y);
				return getName();
			}
		}
		else if (edwin.mouseBtnReleased != 0) {
			pixelLayers.get(0).dots.clear(); //clear brush preview
		}

		if (previewBounds.isMouseOver()) {
			if (edwin.mouseWheelValue == -1) {
				previewZoomLevel.increment();
			}
			else if (edwin.mouseWheelValue == 1) {
				previewZoomLevel.decrement();
			}
		}

		if (!body.isMouseOver()) {
			return "";
		}

		//now for determining which menu was clicked and how to handle it
		//I use switches for menus to make it easier to distinguish from other logic
		if (editBounds.isMouseOver()) {
			if (edwin.mouseBtnHeld == 0 && edwin.mouseBtnReleased == 0) { //mouse hovering
				switch (currentBrush) {
					case BRUSH:
						//hovering brush preview
						pixelLayers.get(0).dots.clear(); 
						applyBrush(0, true);
						break;
				}
			}
			else if (edwin.mouseBtnHeld == LEFT || edwin.mouseBtnHeld == RIGHT) {
				switch (currentBrush) {
					case BRUSH:
						applyBrush(selectedLayer.value, (edwin.mouseBtnHeld == LEFT)); //  ? true : false
						break;
					case LINE:
					case RECTANGLE:
					case PERIMETER:
						//brush preview
						pixelLayers.get(0).dots.clear();
						applyBrush(0, true);
						break;
				}
			}
			else if (edwin.mouseBtnReleased == LEFT || edwin.mouseBtnReleased == RIGHT) {
				switch (currentBrush) {
					case LINE:
					case RECTANGLE:
					case PERIMETER:
						applyBrush(selectedLayer.value, (edwin.mouseBtnReleased == LEFT)); // ? true : false
						break;
				}
			}
			return getName(); //?
		}
		else if (edwin.mouseBtnReleased != LEFT) {
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
				addPixelLayer();
				editablePages.get(selectedPage.value).layerIndicies.add(pixelLayers.size() - 1); //add new layer to current page
				break;
			case NEW_PAGE: 
				String newName = JOptionPane.showInputDialog("Enter new page name\nPress X to toggle layer menu", "newpage");
				if (newName == null) return "";
				//I really need to check for a duplicate name here...
				editablePages.add(new EditablePage(editablePages.size(), newName, new int[] { 0 }));
				int lastSelected = selectedPage.value;
				selectedPage.incrementMax();
				selectedPage.maximize();
				//clone visible pixelLayers to new page
				for (int i : editablePages.get(lastSelected).layerIndicies) {
					editablePages.get(selectedPage.value).setLayerVisibility(i, true);
				}
				usePage(selectedPage.value);
				break;
			case SAVE:
				selectOutput("Save Album .alb", "saveFile", null, this);
				break;
			case OPEN:
				selectInput("Open Album .alb", "openFile", null, this);
				break;
		}

		if (buttonPage != "") {
			return getName();
		}
		else if (!layerListBounds.isMouseOver() || editBounds.containsPoint(edwin.mouseHoldInitial)) {
			return ""; 
		}
		else if (showPages) {
			int index = -1;
			//loop through the menus of the pages and check to see if any were clicked
			for (int i = 0; i < editablePages.size(); i++) {
				buttonPage = editablePages.get(i).buttons.mouse();
				if (buttonPage != "") {
					index = i;
					break;
				}
			}
			if (index == -1) {
				return "";
			}
			EditablePage page = editablePages.get(index);
			switch (buttonPage) {
				case DELETE:
					if (editablePages.size() == 1) {
						JOptionPane.showMessageDialog(null, "Can't delete page when it's the only one", "Hey", JOptionPane.INFORMATION_MESSAGE);
						break;
					}
					int selected = JOptionPane.showConfirmDialog(null, "Really delete page \"" + page.name + "\"?", "Delete Page?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
					if (selected == JOptionPane.YES_OPTION) {
						editablePages.remove(index);
						selectedPage.decrementMax();
						if (index == 1 && editablePages.size() == 1) {
							selectedPage.set(0);
						}
						else {
							for (int i = index; i < editablePages.size(); i++) {
								editablePages.get(i).buttons.body.y -= LIH;
							}
							usePage(selectedPage.maximize());
						}
					}
					break;
				case EDIT_NAME:
					String newName = JOptionPane.showInputDialog("Enter new page name", page.name);
					if (newName != null) {
						page.name = newName;
					}
					break;
				case MOVE_DOWN: //currently what I'm using for selection
					usePage(index);
					//showPages = false;
					break;
			}
			return getName();
		}
		//else: layer list items are visible and that area was clicked

		//Here we translate the mouse coordinate into an index location
		//using LIH (List Item Height) as the side length of 1 grid cell
		//yIndex 0 is the background layer and topmost item, xIndex 1 is the rightmost item (0 is skipped)
		//this is a remnant from before I had GridMenus when I was using square regions as buttons
		int yIndex = (int)((mouseY - layerListBounds.realY()) / LIH);
		int xIndex = (int)((layerListBounds.realXW() - mouseX) / LIH) + 1;

		//edit color palette
		//sooo I tried to pack too many controls in with too few buttons
		//and this is a side effect. When selecting a new color for a layer
		//if it's a quick click you use the existing color, a long click
		//will let you choose a new color in the palette slot
		if (yIndex == 0) {
			if (showPalette) {
				if (xIndex < colorPalette.size()) {
					if (edwin.mouseHeldMillis < MS_THRESHOLD) {
						pixelLayers.get(selectedLayer.value).paletteIndex = xIndex;
					}
					else if (pickNewColor(xIndex)) {
						pixelLayers.get(selectedLayer.value).paletteIndex = xIndex;
					}
				}
				else if (edwin.mouseHeldMillis > MS_THRESHOLD) {
					//otherwise we're further left than the color palette so change the bgd color
					pickNewColor(0);
				}
				else {
					showPalette = false;
				}
			}
			return getName();
		}
		else if (yIndex >= pixelLayers.size()) {
			return "";
		}

		PixelLayer thisLayer = pixelLayers.get(yIndex);
		buttonPage = thisLayer.buttons.mouse();
		selectedLayer.set(yIndex);
		switch (buttonPage) {
			case DELETE:
				if (pixelLayers.size() == 2) {
					JOptionPane.showMessageDialog(null, "Can't delete layer when it's the only one", "Hey", JOptionPane.INFORMATION_MESSAGE);
					break;
				}
				int deleteChoice = JOptionPane.showConfirmDialog(null, "Really delete layer \"" + thisLayer.name + "\"?", "Delete Layer?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
				if (deleteChoice == JOptionPane.YES_OPTION) {
					pixelLayers.remove(yIndex);
					selectedLayer.decrementMax();
					for (int i = yIndex; i < pixelLayers.size(); i++) { 
						pixelLayers.get(i).buttons.body.y -= LIH; //gotta shift the GridButtons manually for now...
					}
					for (EditablePage page : editablePages) {
						page.deleteLayer(yIndex);
					}
				}
				break;
			case EDIT_NAME:
				String newName = JOptionPane.showInputDialog("Enter new layer name", thisLayer.name);
				if (newName != null) thisLayer.name = newName;
				break;
			case MOVE_DOWN:
				movePixelLayerDown(yIndex);
				break;
			case IS_VISIBLE:
			case IS_NOT_VISIBLE:
				thisLayer.toggleVisibility();
				editablePages.get(selectedPage.value).setLayerVisibility(yIndex, thisLayer.isVisible);
				break;
			case EDIT_COLOR:
				if (edwin.mouseHeldMillis > MS_THRESHOLD) {
					if (yIndex == 0) {
						pickNewColor(0);
					}
					else if (colorPalette.size() <= maxColors) {
						if (pickNewColor(colorPalette.size())) {
							thisLayer.paletteIndex = colorPalette.size() - 1;
						}
					}
					else {
						JOptionPane.showMessageDialog(null, "Too many colors in the palette", "Coding is complicated...", JOptionPane.INFORMATION_MESSAGE);
					}
				}
				else {
					showPalette = !showPalette;
				}
				break;
			case EDIT_EXPRESSIONS: //only available in layer 0...
				showPages = true;
				break;
		}
		//println(buttonPage);
		return getName();
	} // end mouse() and big methods ==========================================================================================================================
	// ========================================================================================================================================================

	String keyboard(KeyEvent event) {
		int kc = event.getKeyCode();
		if (kc == Keycodes.VK_Z) {
			zoomLevel.increment();
		}
		else if (kc == Keycodes.VK_A) {
			zoomLevel.decrement();
		}
		else if (event.getAction() != KeyEvent.RELEASE) { //the keys above react to any event, below only to RELEASE
			return "";
		}
		else if (kc == Keycodes.VK_UP) {
			if (showPages) { 
				usePage(selectedPage.decrement());
			}
			else if (event.isControlDown()) {
				selectedLayer.decrement();
				if (!selectedLayer.atMin()) {
					movePixelLayerDown(selectedLayer.value);
					selectedLayer.decrement();
				}
			}
			else {
				selectedLayer.decrement();
			}
		}
		else if (kc == Keycodes.VK_DOWN) {
			if (showPages) {
				usePage(selectedPage.increment());
			}
			else if (event.isControlDown()) {
				movePixelLayerDown(selectedLayer.value);
				//selectedLayer.increment();
			}
			else {
				selectedLayer.increment();
			}
		}
		else if (kc == Keycodes.VK_X) {
			showPages = !showPages;
		}
		else if (kc == Keycodes.VK_E) {
			isVisible = !isVisible;
		}
		else if (kc == Keycodes.VK_V) {
			PixelLayer layer = pixelLayers.get(selectedLayer.value);
			layer.toggleVisibility();
			editablePages.get(selectedPage.value).setLayerVisibility(selectedLayer.value, layer.isVisible); 
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
	}

	boolean pickNewColor(int paletteIndex) {
		Color init = (paletteIndex == colorPalette.size()) ? Color.BLACK : new Color(colorPalette.get(paletteIndex));
		Color picked = JColorChooser.showDialog(null, "Pick new color", init);
		if (picked == null) {
			return false; //they cancelled/closed the window
		}
		if (paletteIndex == colorPalette.size()) {
			colorPalette.add(picked.getRGB());
		}
		else {
			colorPalette.set(paletteIndex, picked.getRGB());
		}
		return true;
	}

	void usePage(int index) {
		selectedPage.set(index);
		//turn all layers off
		for (int i = 1; i < pixelLayers.size(); i++) {
			if (pixelLayers.get(i).isVisible) {
				pixelLayers.get(i).toggleVisibility();
			}
		}
		//turn on layers selectively
		for (int l : editablePages.get(selectedPage.value).layerIndicies) {
			pixelLayers.get(l).toggleVisibility();
			selectedLayer.set(l);
		}
	}

	void movePixelLayerDown(int index) {
		//TODO make cleaner...
		if (index >= pixelLayers.size() - 1) { //can't move the last layer down
			return;
		}
		pixelLayers.get(index).buttons.body.y += LIH;
		pixelLayers.get(index + 1).buttons.body.y -= LIH;
		Collections.swap(pixelLayers, index, index + 1);
		//now we'll check each page for either PixelLayer being swapped and adjust their index value
		int layerI;
		for (EditablePage page : editablePages) {
			layerI = page.layerIndicies.indexOf(index);
			if (layerI != -1) page.layerIndicies.set(layerI, index + 1);
			layerI = page.layerIndicies.indexOf(index + 1);
			if (layerI != -1) page.layerIndicies.set(layerI, index);
		}
		selectedLayer.set(index + 1);
	}

	/**
	* brushVal == true means setting pixels
	* brushVal == false means removing pixels
	*/
	void applyBrush(int layerIndex, boolean brushVal) {
		//these figures are aimed at consistency while zoomed
		XY mouseTranslated = new XY(round((mouseX - body.x - editBounds.x - (zoomLevel.value * .4)) / zoomLevel.value), 
			round((mouseY - body.y - editBounds.y - (zoomLevel.value * .4)) / zoomLevel.value));
		XY mouseInitialTranslated = new XY(round(edwin.mouseHoldInitial.x - body.x - editBounds.x) / zoomLevel.value, 
			round(edwin.mouseHoldInitial.y - body.y - editBounds.y) / zoomLevel.value);

		PixelLayer thisLayer = pixelLayers.get(layerIndex);
		if (!thisLayer.isVisible && layerIndex != 0) return; //can't draw on layers that aren't visible, except 0 is a special case

		if (currentBrush == BRUSH) {
			//square of size brushSize
			thisLayer.pixelRectangle(brushVal, mouseTranslated.x, mouseTranslated.y, (float)brushSize.value, (float)brushSize.value);
		}
		else if (currentBrush == RECTANGLE) {
			//just a solid block
			thisLayer.pixelRectangle(brushVal, 
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
			thisLayer.pixelRectangle(brushVal, 
				rectArea.x, 
				rectArea.y, 
				min(brushSize.value, rectArea.w), 
				rectArea.h);
			//top
			thisLayer.pixelRectangle(brushVal, 
				rectArea.x, 
				rectArea.y, 
				rectArea.w, 
				min(brushSize.value, rectArea.h));
			//right
			thisLayer.pixelRectangle(brushVal, 
				max(rectArea.xw() - brushSize.value, rectArea.x),
				rectArea.y, 
				min(brushSize.value, rectArea.w),
				rectArea.h);
			//bottom
			thisLayer.pixelRectangle(brushVal, 
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
			thisLayer.pixelRectangle(brushVal, mouseTranslated.x, mouseTranslated.y, brushSize.value, brushSize.value);
			for (float segDist = 0; segDist <= lineDist; segDist += segmentIncrement) {
				newPoint.set(mouseInitialTranslated.x - (segDist * (mouseInitialTranslated.x - mouseTranslated.x)) / lineDist, 
					mouseInitialTranslated.y - (segDist * (mouseInitialTranslated.y - mouseTranslated.y)) / lineDist);
				thisLayer.pixelRectangle(brushVal, newPoint.x, newPoint.y, brushSize.value - 1, brushSize.value - 1);
			}
		}
	}
	
	void openFile(File file) {
		if (file == null) return; //user hit cancel or closed
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
		colorPalette.clear();
		resetLayers();

		//colors
		if (json.isNull(EdFiles.BGD_COLOR)) {
			colorPalette.add(#FFFFFF);
			pixelLayers.get(0).isVisible = false; 
		}
		else {
			colorPalette.add(json.getInt(EdFiles.BGD_COLOR));
		}

		for (int paletteColor : json.getJSONArray(EdFiles.COLOR_PALETTE).getIntArray()) {
			colorPalette.add(paletteColor);
		}

		//pages of the album
		JSONArray jsonPages = json.getJSONArray(EdFiles.ALBUM_PAGES);
		for (int i = 0; i < jsonPages.size(); i++) {
			JSONObject page = jsonPages.getJSONObject(i);
			editablePages.add(new EditablePage(i, page.getString(EdFiles.PAGE_NAME), page.getJSONArray(EdFiles.LAYER_NUMBERS).getIntArray()));
		}

		selectedPage.setMax(editablePages.size() - 1); 

		//layer pixels
		JSONArray jsonLayers = json.getJSONArray(EdFiles.PIXEL_LAYERS);
		for (int i = 0; i < jsonLayers.size(); i++) {
			JSONObject thisLayer = jsonLayers.getJSONObject(i);
			BitSet pxls = new BitSet(spriteW * spriteH);
			for (int v : thisLayer.getJSONArray(EdFiles.DOTS).getIntArray()) {
				pxls.set(v);
			}
			addPixelLayer(pxls, thisLayer.getInt(EdFiles.PALETTE_INDEX) + 1); // + 1 because the file has bgdColor on its own but EditorWindow has it in layer 0
			pixelLayers.get(i + 1).name = thisLayer.getString(EdFiles.PIXEL_LAYER_NAME);
		}

		//choose some page rather than have all layers on
		for (int i = 1; i < pixelLayers.size(); i++) {
			if (editablePages.get(0).layerIndicies.indexOf(i) == -1) {
				pixelLayers.get(i).toggleVisibility();
			}
		}
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
		fileLines.add(jsonKV(EdFiles.BGD_COLOR, (pixelLayers.get(0).isVisible ? String.valueOf(colr(0)) : "null")));
		fileLines.add(jsonKV(EdFiles.COLOR_PALETTE, colorPalette.subList(1, colorPalette.size()).toString()));
		fileLines.add("");

		fileLines.add(jsonKVNoComma(EdFiles.ALBUM_PAGES, "[{"));
		for (int i = 0; i < editablePages.size(); i++) {
			if (i > 0) fileLines.add("},{"); //separation between layer objects in this array
			EditablePage page = editablePages.get(i);
			ArrayList<Integer> pageNums = new ArrayList<Integer>();
			for (int layerIndex : page.layerIndicies) {
				//here we subtract one from each index value so that 
				//the file can start at index 0 and its logic is consistent
				//but in this editor we hijack index 0 for display purposes
				pageNums.add(layerIndex - 1); 
			}
			Collections.sort(pageNums);
			fileLines.add(TAB + jsonKVString(EdFiles.PAGE_NAME, page.name));
			fileLines.add(TAB + jsonKV(EdFiles.LAYER_NUMBERS, pageNums.toString()));
		}
		fileLines.add("}],"); //close last page and whole page list

		fileLines.add("");
		fileLines.add(jsonKVNoComma(EdFiles.PIXEL_LAYERS, "[{")); //array of objects
		// remember - index 0 in pixelLayers is actually hijacked for the brush preview pixels 
		// (which aren't saved) and whether the sprite background has a color or is transparent (not visible)
		for (int i = 1; i < pixelLayers.size(); i++) {
			if (i > 1) fileLines.add("},{"); //separation between layer objects in this array
			BitSet pxls = pixelLayers.get(i).dots;
			ArrayList<Integer> layerDots = new ArrayList<Integer>();
			for (int j = 0; j < pxls.size(); j++) {
				if (pxls.get(j)) {
					layerDots.add(j);
				}
			}
			fileLines.add(TAB + jsonKV(EdFiles.PALETTE_INDEX, pixelLayers.get(i).paletteIndex - 1));
			fileLines.add(TAB + jsonKVString(EdFiles.PIXEL_LAYER_NAME, pixelLayers.get(i).name));
			fileLines.add(TAB + jsonKV(EdFiles.TRANSPARENCY, "255")); //not implemented yet...
			fileLines.add(TAB + jsonKV(EdFiles.DOTS, layerDots.toString())); // "dots":[1, 5, 9 ... ]
		}
		fileLines.add("}]"); //close PIXEL_LAYERS
		fileLines.add("}"); //final closing bracket
		saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
	}

	/** EditorWindow internal class */
	private class PixelLayer {
		GridButtons buttons;
		BitSet dots;
		String name;
		int paletteIndex;
		boolean isVisible;

		PixelLayer(int index, int colorPaletteIndex, BitSet pxls) {
			this(index, colorPaletteIndex, pxls, new String[] { DELETE, EDIT_NAME, EDIT_COLOR, MOVE_DOWN, IS_VISIBLE });
		}

		PixelLayer(int index, int colorPaletteIndex, BitSet pxls, String[] buttonNames) {
			paletteIndex = colorPaletteIndex;
			dots = pxls;
			isVisible = true;
			name = "newlayer";
			buttons = new GridButtons(body, 
				layerListBounds.xw() - layerButtons.w * buttonNames.length, 
				layerListBounds.y + layerButtons.h * index, 
				buttonNames.length, 
				layerButtons, 
				buttonNames);
		}

		void toggleVisibility() {
			isVisible = !isVisible;
			buttons.buttonPages[buttons.buttonPages.length - 1] = isVisible ? IS_VISIBLE : IS_NOT_VISIBLE;
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

		// void updateBounds(BitSet pxl, int _w, int _h) {
		// 	BitSet newPixels = new BitSet(_w * _h);
		// 	XY point = new XY();
		// 	//try to maintain pixels from old bounds
		// 	for (int i = 0; i < pxl.size(); i++) {
		// 		if (pxl.get(i)) {
		// 			point.y = (int) ((float) i / (float) spriteW);
		// 			point.x = i - (point.y * spriteW);
		// 			if (point.x >= _w || point.y >= _h) {
		// 				continue;
		// 			}
		// 			newPixels.set((int) (point.y * _w + point.x));
		// 		}		
		// 	}
		// 	pxl = newPixels;
		// }
	}

	/** EditorWindow internal class */
	private class EditablePage {
		ArrayList<Integer> layerIndicies;
		String name;
		GridButtons buttons;

		EditablePage(int index, String pageName, int[] layerIds) {
			name = pageName;
			layerIndicies = new ArrayList<Integer>(); //visible PixelLayers
			for (int i = 0; i < layerIds.length; i++) {
				layerIndicies.add(layerIds[i] + 1);
			}
			String[] buttonNames = new String[] { DELETE, EDIT_NAME, MOVE_DOWN };
			buttons = new GridButtons(body, 
				layerListBounds.xw() - layerButtons.w * buttonNames.length, 
				layerListBounds.y + layerButtons.h * index, 
				buttonNames.length, 
				layerButtons, 
				buttonNames);
		}

		/** for when layers are being shuffled around */
		// void swapPixelLayerDown(int index) {
		// 	for (int i = 0; i < layerIndicies.size(); i++) {
		// 		if (layerIndicies.get(i) == index) {
		// 			layerIndicies.set(i, index + 1);
		// 		}
		// 		else if (layerIndicies.get(i) == index + 1) {
		// 			layerIndicies.set(i, index);
		// 		}
		// 	}
		// }

		void setLayerVisibility(int index, boolean vis) {
			int existing = -1;
			for (int i = 0; i < layerIndicies.size(); i++) {
				if (layerIndicies.get(i) == index) {
					existing = i;
					break;
				}
			}
			if (vis && existing == -1) { //if we want to set it and it doesn't exist
				layerIndicies.add(index);
			}
			else if (!vis && existing != -1) { //if we want to remove it and it does exist
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

} //end EditorWindow

// JOptionPane.showMessageDialog(null, "omg lookout", "Hey", JOptionPane.INFORMATION_MESSAGE);
// int selected = JOptionPane.showConfirmDialog(null, "Really wanna delete this?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
// if (selected == JOptionPane.YES_OPTION) { ... }
