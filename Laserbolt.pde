/** 
* This lets you place multiple Laserbolts on the screen and 
* lets you play with their parameters live. Eventually
* it will also be able to save arrangements you've made 
*/
public class LaserboltPositioner implements Kid {
	ArrayList<Laserbolt> lasers;
	Laserbolt selected;
	GadgetPanel gPanel;
	String openFilepath;
	int anchorDiameter;
	//keys for the JSON file
	final String LASERBOLT_LIST = "laserbolt list",
	COLOR_MAIN = "color 0",
	COLOR_HILIGHT = "color 1",
	ORIGIN_X = "origin x",
	ORIGIN_Y = "origin y",
	DESTINATION_X = "destination x",
	DESTINATION_Y = "destination y",
	//labels for the GadgetPanel 
	IS_VISIBLE = "is visible",
	PERFECT_ZZ = "perfect zig zag",
	JOLTS = "jolts",
	TIMER_LIMIT = "timer limit",
	SEG_LENGTH = "segment length",
	PLACE_MIN = "placement min",
	PLACE_MAX = "placement max",
	PLACE_ANG_MIN = "place angle min",
	PLACE_ANG_MAX = "place angle max",
	THICK_MIN = "thickness min",
	THICK_MAX = "thickness max",
	THICK_INC = "thickness inc",
	THICK_MUL = "thickness mul";

	LaserboltPositioner() { this(null, true); }
	LaserboltPositioner(String filename) { this(filename, false); }
	LaserboltPositioner(String filename, boolean gadgetPanelVisible) { 
		if (filename != null) filename = EdFiles.DATA_FOLDER + filename;
		openFilepath = filename;
		anchorDiameter = 70;
		lasers = new ArrayList<Laserbolt>();
		addLaser();

		//now we define the GadgetPanel menu which will have a lot of buttons...
		gPanel = new GadgetPanel(500, 100, "(L) Laserbolts!");
		gPanel.isVisible = gadgetPanelVisible;
		String[] minusPlus = new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS };
		
		gPanel.addItem("open|save", new String[] { GadgetPanel.OPEN, GadgetPanel.SAVE }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.OPEN) {
					selectInput("Open Lasers...", "openFile", null, LaserboltPositioner.this);
				}
				else { // GadgetPanel.SAVE
					selectOutput("Save Lasers...", "saveFile", null, LaserboltPositioner.this);
				}
			}
		});

		gPanel.addItem("colors", new String[] { GadgetPanel.START_LIGHT, GadgetPanel.STOP_LIGHT }, new Command() {
			void execute(String arg) {
				Color picked = JColorChooser.showDialog(null, "Change color", Color.BLACK);
				if (picked == null) return;
				if (arg == GadgetPanel.START_LIGHT) {
					selected.color0 = picked.getRGB();
				}
				else { // if (arg == GadgetPanel.STOP_LIGHT) {
					selected.color1 = picked.getRGB();
				}
				selected.jolt();
				gPanel.panelLabel = "color changed";
			}
		});

		gPanel.addItem("selected", new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E }, new Command() {
			void execute(String arg) {
				int selIndex = lasers.indexOf(selected);
				if (arg == GadgetPanel.ARROW_W) {
					if (selIndex > 0) {
						selIndex--;
						selected = lasers.get(selIndex);
					}
				}
				else { //GadgetPanel.ARROW_E
					if (selIndex < lasers.size() - 1) {
						selIndex++;
						selected = lasers.get(selIndex);
					}
				}
				gPanel.panelLabel = "selected index:" + selIndex;
				gPanel.getButtons(PERFECT_ZZ).setCheck(selected.perfectZigZag); //set checkboxes of newly selected laser
				gPanel.getButtons(JOLTS).setCheck(selected.jolts); //it's a little awkward right now
				gPanel.getButtons(IS_VISIBLE).setCheck(selected.isVisible); 
			}
		});

		gPanel.addItem("new laser", GadgetPanel.OK, new Command() {
			void execute(String arg) {
				addLaser();
				gPanel.panelLabel = "new laser created"; 
				gPanel.getButtons(PERFECT_ZZ).setCheck(true); //set checkboxes to true for the new laser
				gPanel.getButtons(JOLTS).setCheck(true); 
				gPanel.getButtons(IS_VISIBLE).setCheck(true); 
			}
		});

		gPanel.addItem("clone laser", GadgetPanel.OK, new Command() {
			void execute(String arg) {
				cloneLaser();
				gPanel.panelLabel = "laser cloned"; 
			}
		});

		gPanel.addItem("delete laser", GadgetPanel.NO, new Command() {
			void execute(String arg) {
				gPanel.panelLabel = "not implemented yet";
			}
		});

		gPanel.addItem(PLACE_MIN, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.placeRadius.decrementMin();
				}
				else { //GadgetPanel.PLUS
					selected.placeRadius.incrementMin();
				}
				gPanel.panelLabel = PLACE_MIN + ":" + selected.placeRadius.minimum;
				selected.jolt();
			}
		});

		gPanel.addItem(PLACE_MAX, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.placeRadius.decrementMax();
				}
				else { //GadgetPanel.PLUS
					selected.placeRadius.incrementMax();
				}
				gPanel.panelLabel = PLACE_MAX + ":" + selected.placeRadius.maximum;
				selected.jolt();
			}
		});

		gPanel.addItem(PLACE_ANG_MIN, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.placeAngle.decrementMin();
				}
				else { //GadgetPanel.PLUS
					selected.placeAngle.incrementMin();
				}
				gPanel.panelLabel = PLACE_ANG_MIN + ":" + String.format("%.4f", selected.placeAngle.minimum);
				selected.jolt();
			}
		});

		gPanel.addItem(PLACE_ANG_MAX, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.placeAngle.decrementMax();
				}
				else { //GadgetPanel.PLUS
					selected.placeAngle.incrementMax();
				}
				gPanel.panelLabel = PLACE_ANG_MAX + ":" + String.format("%.4f", selected.placeAngle.maximum);
				selected.jolt();
			}
		});

		gPanel.addItem(PERFECT_ZZ, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
			void execute(String arg) {
				selected.perfectZigZag = !selected.perfectZigZag; //toggle
				gPanel.panelLabel = PERFECT_ZZ + ":" + selected.perfectZigZag;
				gPanel.getButtons(PERFECT_ZZ).toggleImage();
				selected.jolt();
			}
		});
		gPanel.getButtons(PERFECT_ZZ).setCheck(true); //all checkboxes start as false...

		gPanel.addItem(JOLTS, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
			void execute(String arg) {
				selected.jolts = !selected.jolts; //toggle
				gPanel.panelLabel = JOLTS + ":" + selected.jolts;
				gPanel.getButtons(JOLTS).toggleImage();
				selected.jolt();
			}
		});
		gPanel.getButtons(JOLTS).setCheck(true);

		gPanel.addItem(TIMER_LIMIT, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.timer.decrementMax(5);
				}
				else { //GadgetPanel.PLUS
					selected.timer.incrementMax(5);
				}
				gPanel.panelLabel = TIMER_LIMIT + ":" + selected.timer.maximum;
				selected.jolt();
			}
		});

		gPanel.addItem(SEG_LENGTH, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.segmentLength.decrement();
				}
				else { //GadgetPanel.PLUS
					selected.segmentLength.increment();
				}
				gPanel.panelLabel = SEG_LENGTH + ":" + selected.segmentLength.value;
				selected.jolt();
			}
		});

		gPanel.addItem(THICK_MIN, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.thickness.decrementMin();
				}
				else { //GadgetPanel.PLUS
					selected.thickness.incrementMin();
				}
				gPanel.panelLabel = THICK_MIN + ":" + selected.thickness.minimum;
				selected.jolt();
			}
		});

		gPanel.addItem(THICK_MAX, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.thickness.decrementMax();
				}
				else { //GadgetPanel.PLUS
					selected.thickness.incrementMax();
				}
				gPanel.panelLabel = THICK_MAX + ":" + selected.thickness.maximum;
				selected.jolt();
			}
		});

		gPanel.addItem(THICK_INC, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.powInc.decrement();
				}
				else { //GadgetPanel.PLUS
					selected.powInc.increment();
				}
				gPanel.panelLabel = THICK_INC + ":" + selected.powInc.value;
				selected.jolt();
			}
		});

		gPanel.addItem(THICK_MUL, minusPlus, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.MINUS) {
					selected.powIncInc.decrement();
				}
				else { //GadgetPanel.PLUS
					selected.powIncInc.increment();
				}
				gPanel.panelLabel = THICK_MUL + ":" + String.format("%.2f", selected.powIncInc.value);
				selected.jolt();
			}
		});

		gPanel.addItem(IS_VISIBLE, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
			void execute(String arg) {
				selected.isVisible = !selected.isVisible; //toggle
				gPanel.panelLabel = IS_VISIBLE + ":" + selected.isVisible;
				gPanel.getButtons(IS_VISIBLE).toggleImage();
				selected.jolt();
			}
		});
		gPanel.getButtons(IS_VISIBLE).setCheck(true);
	}

	void addLaser() {
		int margin = 80;
		selected = new Laserbolt(margin, margin, margin, height - margin);
		lasers.add(selected);
	}

	void cloneLaser() {
		selected = selected.clone();
		lasers.add(selected);
	}

	void drawSelf(PGraphics canvas) {
		if (openFilepath != null) digestFile();
		//edit anchors
		if (gPanel.isVisible) {
			canvas.noStroke();
			canvas.fill(255, 100);
			canvas.ellipse(selected.anchor0.x, selected.anchor0.y, anchorDiameter, anchorDiameter);
			canvas.ellipse(selected.anchor1.x, selected.anchor1.y, anchorDiameter, anchorDiameter);
		}
		for (Laserbolt laser : lasers) {
			laser.drawSelf(canvas);
		}
		gPanel.drawSelf(canvas);
	}

	String mouse() {
		if (!gPanel.isVisible) return "";
		if (gPanel.mouse() != "") {
			//selected.jolt();
			return getName();
		}
		else if (edwin.mouseBtnHeld == LEFT) {
			if (selected.anchor0.distance(mouseX, mouseY) < anchorDiameter) {
				selected.newAnchor(mouseX, mouseY);
			}
			else if (selected.anchor1.distance(mouseX, mouseY) < anchorDiameter) {
				selected.newTarget(mouseX, mouseY);
			}
		}
		return "";
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() != KeyEvent.RELEASE) {
			return "";
		}
		int kc = event.getKeyCode();
		if (kc == Keycodes.VK_L) {
			gPanel.toggleVisibility();
			return getName();
		}
		else if (!gPanel.isVisible) {
			return "";
		}
		else if (kc == Keycodes.VK_LEFT) {
			gPanel.itemExecute("selected", GadgetPanel.ARROW_W);
			return getName();
		}
		else if (kc == Keycodes.VK_RIGHT) {
			gPanel.itemExecute("selected", GadgetPanel.ARROW_E);
			return getName();
		}
		return "";
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
		lasers.clear();
		JSONArray jsonLasers = json.getJSONArray(LASERBOLT_LIST);
		for (int i = 0; i < jsonLasers.size(); i++) {
			JSONObject jsonLaser = jsonLasers.getJSONObject(i);
			Laserbolt laser = new Laserbolt(
				new XY(jsonLaser.getFloat(ORIGIN_X), jsonLaser.getFloat(ORIGIN_Y)),
				new XY(jsonLaser.getFloat(DESTINATION_X), jsonLaser.getFloat(DESTINATION_Y)), 
				jsonLaser.getInt(COLOR_MAIN), 
				jsonLaser.getInt(COLOR_HILIGHT));
			laser.isVisible = jsonLaser.getBoolean(IS_VISIBLE);
			laser.perfectZigZag = jsonLaser.getBoolean(PERFECT_ZZ);
			laser.jolts = jsonLaser.getBoolean(JOLTS);
			laser.timer.reset(0, jsonLaser.getInt(TIMER_LIMIT));
			laser.segmentLength.set(jsonLaser.getInt(SEG_LENGTH));
			laser.placeRadius.reset(jsonLaser.getInt(PLACE_MIN), jsonLaser.getInt(PLACE_MAX));
			laser.placeAngle.reset(jsonLaser.getFloat(PLACE_ANG_MIN), jsonLaser.getFloat(PLACE_ANG_MAX));
			laser.thickness.reset(jsonLaser.getInt(THICK_MIN), jsonLaser.getInt(THICK_MAX));
			laser.powInc.set(jsonLaser.getInt(THICK_INC));
			laser.powIncInc.set(jsonLaser.getInt(THICK_MUL));
			laser.jolt();
			lasers.add(laser);
		}
		selected = lasers.get(0);
	}

	void saveFile(File file) {
		if (file == null) return; //user closed window or hit cancel
		ArrayList<String> fileLines = new ArrayList<String>();
		fileLines.add("{"); //opening bracket
		fileLines.add(jsonKVNoComma(LASERBOLT_LIST, "[{"));
		for (int i = 0; i < lasers.size(); i++) {
			if (i > 0) fileLines.add("},{"); //separation between layer objects in this array
			Laserbolt laser = lasers.get(i);
			fileLines.add(TAB + jsonKV(ORIGIN_X, laser.anchor0.x));
			fileLines.add(TAB + jsonKV(ORIGIN_Y, laser.anchor0.y));
			fileLines.add(TAB + jsonKV(DESTINATION_X, laser.anchor1.x));
			fileLines.add(TAB + jsonKV(DESTINATION_Y, laser.anchor1.y));
			fileLines.add(TAB + jsonKV(COLOR_MAIN, laser.color0));
			fileLines.add(TAB + jsonKV(COLOR_HILIGHT, laser.color1));
			fileLines.add(TAB + jsonKV(IS_VISIBLE, laser.isVisible));
			fileLines.add(TAB + jsonKV(PERFECT_ZZ, laser.perfectZigZag));
			fileLines.add(TAB + jsonKV(JOLTS, laser.jolts));
			fileLines.add(TAB + jsonKV(TIMER_LIMIT, laser.timer.maximum));
			fileLines.add(TAB + jsonKV(SEG_LENGTH, laser.segmentLength.value));
			fileLines.add(TAB + jsonKV(PLACE_MIN, laser.placeRadius.minimum));
			fileLines.add(TAB + jsonKV(PLACE_MAX, laser.placeRadius.maximum));
			fileLines.add(TAB + jsonKV(PLACE_ANG_MIN, laser.placeAngle.minimum));
			fileLines.add(TAB + jsonKV(PLACE_ANG_MAX, laser.placeAngle.maximum));
			fileLines.add(TAB + jsonKV(THICK_MIN, laser.thickness.minimum));
			fileLines.add(TAB + jsonKV(THICK_MAX, laser.thickness.maximum));
			fileLines.add(TAB + jsonKV(THICK_INC, laser.powInc.value));
			fileLines.add(TAB + jsonKV(THICK_MUL, laser.powIncInc.value));
		}
		fileLines.add("}]"); //close list
		fileLines.add("}"); //final closing bracket
		saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
	}

	String getName() {
		return "LaserboltPositioner";
	}
}



/** 
* A polygon zigzag line that jolts between two points 
*/
class Laserbolt implements Kid {
	BoundedInt timer, segmentLength, thickness, placeRadius, powInc;
	BoundedFloat placeAngle, powIncInc;
	PShape laserBeam;
	PShape[] hilights;
	//LaserPoint[] lPoints;
	XY anchor0, anchor1;
	int color0, color1;
	boolean perfectZigZag, jolts, isVisible;

	Laserbolt(XY anchor, XY dest) { this(anchor.x, anchor.y, dest.x, dest.y); }
	Laserbolt(XY anchor, XY dest, int colorMain, int colorHilight) { this(anchor.x, anchor.y, dest.x, dest.y, colorMain, colorHilight); }
	Laserbolt(float anchorX, float anchorY, float destX, float destY) { this(anchorX, anchorY, destX, destY, #69D1C5, #3B898C); }
	Laserbolt(float anchorX, float anchorY, float destX, float destY, int colorMain, int colorHilight) {
		anchor0 = new XY(anchorX, anchorY);
		anchor1 = new XY(destX, destY);
		color0 = colorMain;
		color1 = colorHilight;
		perfectZigZag = jolts = isVisible = true;
		timer = new BoundedInt(80);
		segmentLength = new BoundedInt(10, 300, 80, 5);
		thickness = new BoundedInt(8, 24, 8, 2);
		placeRadius = new BoundedInt(10, 30, 10, 2);
		powInc = new BoundedInt(20);
		powIncInc = new BoundedFloat(0, 20, 0, 0.5);
		placeAngle = new BoundedFloat(-QUARTER_PI / 3, QUARTER_PI / 3, 0, QUARTER_PI / 30);
		jolt();
	}

	void drawSelf(PGraphics canvas) {
		if (!isVisible) return;
		timer.increment();
		if (jolts && timer.atMax()) {
			timer.randomize();
			jolt(); 
		}
		canvas.shape(laserBeam);
		for (PShape hilight : hilights) {
			canvas.shape(hilight);
		}
	}

	void newAnchor(XY anchor) { newAnchor(anchor.x, anchor.y); }
	void newAnchor(float x, float y) {
		anchor0.set(x, y);
		jolt();
	}

	void jolt() { newTarget(anchor1); } //generate new form without picking different points
	void newTarget(XY dest) { newTarget(dest.x, dest.y); }
	void newTarget(float x, float y) {
		anchor1.set(x, y);
		XY inline = anchor0; //used for finding each point along the line
		int numPoints = (int)max(anchor0.distance(anchor1) / segmentLength.value, 1); //at least 1 point along line
		LaserPoint[] lPoints = new LaserPoint[numPoints];
		float segDist = anchor0.distance(anchor1) / (numPoints + 1); //makes the stretching transition a little smoother than using segmentLength.value directly
		XY pointAt = anchor0; 
		float pow = 0, powPlus = powInc.value;
		boolean isOdd;
		for (int i = 0; i < numPoints; i++) {
			inline = new XY(inline.x - segDist * anchor0.angCos(anchor1), inline.y - segDist * anchor0.angSin(anchor1));
			//inline = new XY(inline.x - segmentLength.value * anchor0.angCos(anchor1), inline.y - segmentLength.value * anchor0.angSin(anchor1));
			if (i > 0) pointAt = lPoints[i - 1].anchor; ///////////
			isOdd = perfectZigZag ? (i % 2 == 1) : (random(1) > 0.5);
			lPoints[i] = new LaserPoint(inline, pointAt, isOdd, thickness.randomize() + pow, placeRadius.randomize(), placeAngle.randomize()); //random(-QUARTER_PI, QUARTER_PI) placeAngle.randomize()
			pow += powPlus;
			powPlus += powIncInc.value;
		}

		//define beam polygon
		//go up along the left side then down the right
		laserBeam = createShape();
		laserBeam.beginShape();
		laserBeam.noStroke();
		laserBeam.fill(color0);
		laserBeam.vertex(anchor0.x, anchor0.y);
		for (int i = 0; i < lPoints.length; i++) {
			laserBeam.vertex(lPoints[i].left.x, lPoints[i].left.y);
		}
		laserBeam.vertex(anchor1.x, anchor1.y);
		for (int i = lPoints.length - 1; i >= 0; i--) {
			laserBeam.vertex(lPoints[i].right.x, lPoints[i].right.y);
		}
		laserBeam.endShape(CLOSE);
		
		//define quads that break up the solid beam
		hilights = new PShape[(int)(numPoints / 3)];
		int indx = 0;
		for (int i = 2; i < lPoints.length; i += 3) {
			PShape diamond = createShape();
			diamond.beginShape();
			diamond.noStroke();
			diamond.fill(color1);
			if (indx % 2 == 1) {
				diamond.vertex(lPoints[i].left.x, lPoints[i].left.y);
				diamond.vertex(lPoints[i - 1].left.x, lPoints[i - 1].left.y);
				diamond.vertex(lPoints[i - 2].left.x, lPoints[i - 2].left.y);
				diamond.vertex(lPoints[i - 1].right.x, lPoints[i - 1].right.y);
			}
			else {
				diamond.vertex(lPoints[i].right.x, lPoints[i].right.y);
				diamond.vertex(lPoints[i - 1].right.x, lPoints[i - 1].right.y);
				diamond.vertex(lPoints[i - 2].right.x, lPoints[i - 2].right.y);
				diamond.vertex(lPoints[i - 1].left.x, lPoints[i - 1].left.y);
			}
			diamond.endShape(CLOSE);
			hilights[indx++] = diamond;
		}
	}

	Laserbolt clone() {
		Laserbolt schwarzenegger = new Laserbolt(anchor0.clone(), anchor1.clone(), color0, color1);
		schwarzenegger.timer = timer.clone();
		schwarzenegger.segmentLength = segmentLength.clone();
		schwarzenegger.thickness = thickness.clone();
		schwarzenegger.placeRadius = placeRadius.clone();
		schwarzenegger.powInc = powInc.clone();
		schwarzenegger.powIncInc = powIncInc.clone();
		schwarzenegger.placeAngle = placeAngle.clone();
		schwarzenegger.perfectZigZag = perfectZigZag;
		schwarzenegger.jolts = jolts;
		schwarzenegger.jolt();
		return schwarzenegger;
	}

	String mouse() {
		return "";
	}

	String keyboard(KeyEvent event) {
		return "";
	}

	String getName() {
		return "Laserbolt";
	}

	private class LaserPoint {
		XY absoluteAnchor, anchor, left, right;
		boolean odd;

		LaserPoint(XY anc, XY aim, boolean isOdd, float thickness, float placeRadius, float placeAngVar) {
			absoluteAnchor = anc;
			odd = isOdd; 
			float placeAngle = anchor0.angle(anchor1) + (odd ? HALF_PI : -HALF_PI) + placeAngVar;
			anchor = new XY(absoluteAnchor.x - placeRadius * cos(placeAngle), absoluteAnchor.y - placeRadius * sin(placeAngle));
			//define edge points on laser
			float aimAngle = anchor0.angle(anchor1) + HALF_PI;
			//float aimAngle = anchor.angle(aim);
			left = new XY(anchor.x - thickness * cos(aimAngle), anchor.y - thickness * sin(aimAngle));
			aimAngle -= PI;
			right = new XY(anchor.x - thickness * cos(aimAngle), anchor.y - thickness * sin(aimAngle));
		}
	}

} //end Laserbolt

