/** 
* This lets you make a ~wireframe statue.
* File saved as .pw
*/
class Polywire extends DraggableWindow {
	GridButtons modeButtons;
	PolywireMode editMode;

	public static final String BUTTON_MENU_FILENAME = "polywireButtons.alb",
	BLANK = "blank",
	BLANK_CHECKED = "blankChecked",
	BUTTON_FIGURE = "modeFigure",
	BUTTON_FIGURE_CHECKED = "modeFigureChecked",
	BUTTON_SHIMMER = "modeShimmer",
	BUTTON_SHIMMER_CHECKED = "modeShimmerChecked",
	BUTTON_MORPH = "modeMorph",
	BUTTON_MORPH_CHECKED = "modeMorphChecked",
	WAND = "wand",
	WAND_CHECKED = "wandChecked";

	Polywire() {
		super(0, 0);
		modeButtons = new GridButtons(body, UI_PADDING, dragBar.h + UI_PADDING * 2, 1, 
			new Album(BUTTON_MENU_FILENAME), 
			new String[] { BUTTON_FIGURE, BUTTON_SHIMMER, BUTTON_MORPH, WAND, BLANK },
			new String[] { BUTTON_FIGURE_CHECKED, BUTTON_SHIMMER_CHECKED, BUTTON_MORPH_CHECKED, WAND_CHECKED, BLANK_CHECKED }
		);
		modeButtons.setCheck(0, true);
		editMode = PolywireMode.EDIT_FIGURE;

		body.setSize(modeButtons.body.w + UI_PADDING * 2, dragBar.h + modeButtons.body.h + UI_PADDING * 3);
		dragBar.w = modeButtons.body.w;
		isVisible = true;
	}

	void drawSelf(PGraphics canvas) {
		if (!isVisible) return;
		super.drawSelf(canvas);
		canvas.pushMatrix();
		canvas.translate(body.x, body.y);
		modeButtons.drawSelf(canvas);
		canvas.popMatrix();
		switch (editMode) {
			case EDIT_FIGURE:
				break;
			case EDIT_SHIMMER:
				break;
		}
	}

	String mouse() { 
		if (!isVisible) return "";
		if (super.mouse() != "") return "dragging";
		if (edwin.mouseBtnReleased != LEFT) return "";
		String modeClicked = modeButtons.mouse();
		if (modeClicked == "") return "";
		else if (!modeClicked.endsWith("Checked")) {
			modeButtons.uncheckAll();
			switch (modeClicked) {
				case BUTTON_FIGURE:
					editMode = PolywireMode.EDIT_FIGURE;
					modeButtons.toggleImage(0);
					break;
				case BUTTON_SHIMMER:
					editMode = PolywireMode.EDIT_SHIMMER;
					modeButtons.toggleImage(1);
					break;
				case BUTTON_MORPH:
					editMode = PolywireMode.EDIT_MORPH;
					modeButtons.toggleImage(2);
					break;
				case WAND:
					modeButtons.toggleImage(3);
					break;
				case BLANK:
					modeButtons.toggleImage(4);
					break;
			}
			return getName();
		}

		return "";
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() != KeyEvent.RELEASE) {
			return "";
		}
		int kc = event.getKeyCode();
		if (kc == Keycodes.VK_W) {
			toggleVisibility();
			return getName();
		}
		return "";
	}
}


public enum PolywireMode {
	EDIT_FIGURE, EDIT_SHIMMER, EDIT_MORPH
}






public class PolywireOld implements Kid {
	ArrayList<XY> allDots, buildingPolygon;
	ArrayList<AnimationFrames> allAnimations;
	ArrayList<Polygon> allPolygons;
	Polygon selectedPolygon;
	AnimationFrames selectedAnimation;
	PShape selectedPolygonBorder, mouseoverPolygonBorder;
	GadgetPanel gPanel, modePanel;
	PalettePicker palette;
	ReferenceImagePositioner referenceImage;
	BoundedInt selectedColor, animationFramerate;
	XY selectedAnchor, symmetryAnchor, originOffset;
	String openFilepath, currentAnimation;
	boolean useVertSym, setVertSym, useHorzSym, setHorzSym, modeDefineFace, playAnimation, queueNextAnimation;
	int delayCounter;
	final int anchorDiameter = 40, dotDiameter = 6;
	//constants
	final String SELECTED_DOT = "selected",
	NEW_DOT = "new dot",
	DELETE_DOT = "delete dot",
	IS_VISIBLE = "visible",
	VERTICAL_SYM = "vertical sym",
	HORIZONTAL_SYM = "horizontal symmetry",
	FACEMAKING = "facemaking",
	//file json keys (plus EdFiles.DOTS, COLOR_PALETTE)
	OFFSET_X = "offset x",
	OFFSET_Y = "offset y",
	SYMMETRY_X = "symmetry x",
	SYMMETRY_Y = "symmetry y",
	POLYGONS = "polygons",
	ANIMATIONS = "animations",
	ANIMATION_NAME = "name",
	ANIMATION_FRAMES = "frames",
	FRAME_DELAY = "delay",
	FRAME_COLORS = "polygon colors",
	//modes
	MODE_FIGURE = "",
	MODE_SHIMMER = " ";

	PolywireOld() { this(null, true); }
	PolywireOld(String filename) { this(filename, false); }
	PolywireOld(String filename, boolean gadgetPanelVisible) { 
		if (filename != null) filename = EdFiles.DATA_FOLDER + filename;
		openFilepath = filename;
		palette = new PalettePicker(new int[] { #05162B, #134372, #3176BC, #9AC5EA, #DCE6ED }, "Polywire Colors", false);
		allAnimations = new ArrayList<AnimationFrames>();
		allAnimations.add(new AnimationFrames("first"));
		allDots = new ArrayList<XY>();
		allDots.add(new XY(50, 50));
		allPolygons = new ArrayList<Polygon>();
		buildingPolygon = new ArrayList<XY>();
		selectedAnchor = allDots.get(0);
		selectedAnimation = allAnimations.get(0);
		selectedPolygon = null;
		selectedPolygonBorder = mouseoverPolygonBorder = null;
		selectedColor = new BoundedInt(0, palette.colors.size() - 1);
		animationFramerate = new BoundedInt(0, 0);
		animationFramerate.loops = true;
		symmetryAnchor = new XY(width / 2, height / 2);
		originOffset = new XY(0, 0);
		delayCounter = 0;
		useVertSym = setVertSym = useHorzSym = setHorzSym = modeDefineFace = playAnimation = queueNextAnimation = false;
		gPanel = new GadgetPanel(100, 100, "(P) Polywire!");
		gPanel.isVisible = gadgetPanelVisible;
		//String[] minusPlus = new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS };

		gPanel.addItem("open|save", new String[] { GadgetPanel.OPEN, GadgetPanel.SAVE }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.OPEN) {
					selectInput("Open Lasers...", "openFile", null, PolywireOld.this);
				}
				else { // GadgetPanel.SAVE
					selectOutput("Save Lasers...", "saveFile", null, PolywireOld.this);
				}
			}
		});

		gPanel.addItem("colors", GadgetPanel.START_LIGHT, new Command() {
			void execute(String arg) {
				palette.toggleVisibility();
				palette.body.set(mouseX, mouseY);
			}
		});

		gPanel.addItem(VERTICAL_SYM, new String[] { GadgetPanel.SIDE_SIDE, GadgetPanel.BLANK }, new String[] { GadgetPanel.SIDE_SIDE_DOWN, GadgetPanel.BIGX }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.SIDE_SIDE || arg == GadgetPanel.SIDE_SIDE_DOWN) {
					setVertSym = !setVertSym;
					gPanel.panelLabel = "setting v symmetry: " + setVertSym;
					gPanel.getButtons(VERTICAL_SYM).toggleImage(0);
				}
				else { //if (arg == GadgetPanel.BLANK || arg == GadgetPanel.BIGX) {
					useVertSym = !useVertSym;
					gPanel.panelLabel = "using v symmetry: " +  useVertSym;
					gPanel.getButtons(VERTICAL_SYM).toggleImage(1);
				}
			}
		});

		gPanel.addItem(HORIZONTAL_SYM, new String[] { GadgetPanel.OVER_UNDER, GadgetPanel.BLANK }, new String[] { GadgetPanel.OVER_UNDER_DOWN, GadgetPanel.BIGX }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.OVER_UNDER || arg == GadgetPanel.OVER_UNDER_DOWN) {
					setHorzSym = !setHorzSym;
					gPanel.panelLabel = "setting h symmetry: " + setHorzSym;
					gPanel.getButtons(HORIZONTAL_SYM).toggleImage(0);
				}
				else { //if (arg == GadgetPanel.BLANK || arg == GadgetPanel.BIGX) {
					useHorzSym = !useHorzSym;
					gPanel.panelLabel = "using h symmetry: " +  useHorzSym;
					gPanel.getButtons(HORIZONTAL_SYM).toggleImage(1);
				}
			}
		});

		gPanel.addItem(FACEMAKING, GadgetPanel.START_LIGHT, GadgetPanel.STOP_LIGHT, new Command() {
			void execute(String arg) {
				defineFace();
			}
		});

		gPanel.addItem("dot new|disconnect|delete", new String[] { GadgetPanel.PLUS, GadgetPanel.BLANK, GadgetPanel.BIGX }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.PLUS) {
					addDot();
				}
				else if (arg == GadgetPanel.BLANK) {
					ArrayList<Polygon> toDelete = new ArrayList<Polygon>();
					for (Polygon polygon : allPolygons) {
						if (Arrays.asList(polygon.dots).contains(selectedAnchor)) {
							toDelete.add(polygon);
						}
					}
					int confirm = JOptionPane.showConfirmDialog(null, "Really delete " + toDelete.size() + " polygons connected to dot?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
					if (confirm == JOptionPane.YES_OPTION) { 
						for (Polygon del : toDelete) {
							allPolygons.remove(del);
						}
					}
				}
				else { //if (arg == GadgetPanel.BIGX) {
					if (allDots.size() == 1) {
						gPanel.panelLabel = "can't delete only dot";
						return;
					}
					int confirm = JOptionPane.showConfirmDialog(null, "Really delete dot?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
					if (confirm == JOptionPane.YES_OPTION) { 
						allDots.remove(selectedAnchor);
						selectedAnchor = allDots.get(0);
						gPanel.panelLabel = "dot deleted";
					}
				}
			}
		});

		gPanel.addItem("animation play|stop|new", new String[] { GadgetPanel.ARROW_E, GadgetPanel.STOP_LIGHT, GadgetPanel.PLUS }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.ARROW_E) {
					restartAnimation();
				}
				else if (arg == GadgetPanel.STOP_LIGHT) {
					playAnimation = false;
				}
				else { //if (arg == GadgetPanel.PLUS) {
					String newName = JOptionPane.showInputDialog("Enter new animation name", "new");
					if (newName != null) { 
						AnimationFrames newAnimation = new AnimationFrames(newName);
						newAnimation.addBlankFrame();
						newAnimation.drawFrame();
						allAnimations.add(newAnimation);
						selectedAnimation = newAnimation;
						gPanel.panelLabel = newName + " animation created";
					}
				}
			}
		});

		gPanel.addItem("animation prev|next|rename", new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E, GadgetPanel.NO }, new Command() {
			void execute(String arg) {
				int selIndex = allAnimations.indexOf(selectedAnimation);
				if (arg == GadgetPanel.ARROW_W) {
					if (selIndex > 0) {
						selIndex--;
						selectedAnimation = allAnimations.get(selIndex);
					}
				}
				else if (arg == GadgetPanel.ARROW_E) {
					if (selIndex < allAnimations.size() - 1) {
						selIndex++;
						selectedAnimation = allAnimations.get(selIndex);
					}
				}
				else { //if (arg == GadgetPanel.NO) {
					String newName = JOptionPane.showInputDialog("Edit animation name", selectedAnimation.name);
					if (newName != null) { 
						selectedAnimation.name = newName;
					}
				}
				selectedAnimation.currentFrame.minimize();
				selectedAnimation.drawFrame();
				gPanel.panelLabel = "animation: \"" + selectedAnimation.name + "\"";
			}
		});

		gPanel.addItem("frame prev|next|new", new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E, GadgetPanel.PLUS }, new Command() {
			void execute(String arg) {
				playAnimation = false;
				if (arg == GadgetPanel.ARROW_W) {
					selectedAnimation.currentFrame.decrement();
					selectedAnimation.drawFrame();
					gPanel.panelLabel = "frame " + selectedAnimation.currentFrame.value + "/" + selectedAnimation.currentFrame.maximum;
				}
				else if (arg == GadgetPanel.ARROW_E) {
					selectedAnimation.currentFrame.increment();
					selectedAnimation.drawFrame();
					gPanel.panelLabel = "frame " + selectedAnimation.currentFrame.value + "/" + selectedAnimation.currentFrame.maximum;
				}
				else { //if (arg == GadgetPanel.PLUS) {
					selectedAnimation.addDuplicateFrame();
					gPanel.panelLabel = "frame " + selectedAnimation.currentFrame.value + " added";
				}
			}
		});

		modePanel = new GadgetPanel(100, 100, "Mode", null) {
			void disableAll() {
				for (PanelItem item : panelItems) {
					item.buttons.setCheck(false);
				}
			}
		};

		modePanel.addItem(MODE_FIGURE, "modeFigure", "modeFigureChecked", new Command() {
			void execute(String arg) {
				modePanel.getButtons(MODE_FIGURE).toggleImage();
			}
		});

		modePanel.getButtons(MODE_FIGURE).toggleImage();
		modePanel.addItem(MODE_SHIMMER, "modeShimmer", "modeShimmerChecked", new Command() {
			void execute(String arg) {
				modePanel.getButtons(MODE_SHIMMER).toggleImage();
			}
		});

		edwin.useSmooth = false;
	} //end constructor

	void addDot() {
		selectedAnchor = new XY(selectedAnchor.x + 20, selectedAnchor.y + 20);
		allDots.add(selectedAnchor);
		gPanel.panelLabel = "dot created:" + (allDots.size() - 1); 
	}

	void drawSelf(PGraphics canvas) {
		if (openFilepath != null) digestFile();
		canvas.noStroke();
		canvas.pushMatrix();
		canvas.translate(originOffset.x, originOffset.y);

		// animationFramerate.increment();
		// if (playAnimation && animationFramerate.atMax()) {
		// 	animationFramerate.minimize();

		animationFramerate.increment();
		if (playAnimation && animationFramerate.atMax()) {
			// animationFramerate.minimize(); don't need this anymore since we set loops = true
			if (delayCounter++ >= selectedAnimation.delays[selectedAnimation.currentFrame.value]) {
				delayCounter = 0;
				selectedAnimation.currentFrame.increment();
				int animIndex = allAnimations.indexOf(selectedAnimation);
				if (selectedAnimation.currentFrame.atMin() && queueNextAnimation && animIndex != allAnimations.size() - 1) {
					queueNextAnimation = false;
					selectedAnimation = allAnimations.get(animIndex + 1);
					selectedAnimation.currentFrame.minimize();
				}
				selectedAnimation.drawFrame();
			}
		}

		//wireframe
		for (Polygon polygon : allPolygons) {
			canvas.shape(polygon.face);
		}
		for (Polygon polygon : allPolygons) {
			canvas.shape(polygon.wire);
		}
		
		if (!gPanel.isVisible) {
			canvas.popMatrix();
			return;
		}

		if (mouseoverPolygonBorder != null) canvas.shape(mouseoverPolygonBorder);
		if (selectedPolygonBorder != null) canvas.shape(selectedPolygonBorder);

		//verticies
		for (XY dot : allDots) {
			if (buildingPolygon.contains(dot) || dot == selectedAnchor) {
				canvas.fill(EdColors.UI_NORMAL);
				canvas.ellipse(selectedAnchor.x, selectedAnchor.y, dotDiameter * 2, dotDiameter * 2);
			}
			canvas.fill(EdColors.UI_EMPHASIS);
			canvas.ellipse(dot.x, dot.y, dotDiameter, dotDiameter);
			//symmetry dots
			canvas.fill(EdColors.UI_DARK);
			if (useVertSym) canvas.ellipse(symmetryAnchor.x + (symmetryAnchor.x - dot.x), dot.y, dotDiameter, dotDiameter);
			if (useHorzSym) canvas.ellipse(dot.x, symmetryAnchor.y + (symmetryAnchor.y - dot.y), dotDiameter, dotDiameter);
			canvas.fill(EdColors.UI_NORMAL);
			if (useHorzSym && useVertSym) canvas.ellipse(symmetryAnchor.x + (symmetryAnchor.x - dot.x), symmetryAnchor.y + (symmetryAnchor.y - dot.y), dotDiameter, dotDiameter);
		}

		//current polygon/face being drawn
		if (buildingPolygon.size() > 2) {
			canvas.beginShape();
			canvas.fill(color(EdColors.UI_DARK, 120));
			for (XY dot : buildingPolygon) {
				canvas.vertex(dot.x, dot.y);
			}
			canvas.endShape(CLOSE);
		}

		//indicator for origin
		// if (edwin.mouseBtnHeld == CENTER) {
		// 	canvas.fill(EdColors.UI_EMPHASIS);
		// 	canvas.ellipse(0, 0, anchorDiameter, anchorDiameter);
		// }

		//symmetry lines
		if (setVertSym || setHorzSym) {
			canvas.strokeWeight(3);
			canvas.stroke(255);
			if (setVertSym) canvas.line(symmetryAnchor.x, 0, symmetryAnchor.x, height);
			if (setHorzSym) canvas.line(0, symmetryAnchor.y, width, symmetryAnchor.y);
			canvas.strokeWeight(1);
			canvas.noStroke();
		}

		canvas.popMatrix();
		gPanel.drawSelf(canvas);
		modePanel.drawSelf(canvas);
		palette.drawSelf(canvas);
	}

	String mouse() {
		if (gPanel.mouse() != "" || palette.mouse() != "" || modePanel.mouse() != "") {
			return getName(); //if mouse() returns something that means the panel reacting and we'll ignore the event here
		}

		XY mouseWOffset = new XY(mouseX - originOffset.x, mouseY - originOffset.y);
		if (edwin.mouseBtnReleased == LEFT) {
			if (modeDefineFace) {
				if (buildingPolygon.indexOf(selectedAnchor) == -1) buildingPolygon.add(selectedAnchor);
				else buildingPolygon.remove(selectedAnchor);
			}
			else {
				selectedPolygonBorder = null;
				selectedPolygon = null;
				for (Polygon polygon : allPolygons) {
					if (polygon != selectedPolygon && polygon.containsPoint(mouseX - originOffset.x, mouseY - originOffset.y)) {
						selectedPolygonBorder = redrawHilight(polygon, EdColors.UI_EMPHASIS);
						selectedPolygon = polygon;
						break;
					}
				}
			}
		}
		else if (edwin.mouseBtnHeld == LEFT) {
			if ((setVertSym || setHorzSym) && !gPanel.body.isMouseOver()) {
				if (setVertSym) symmetryAnchor.x = mouseWOffset.x;
				if (setHorzSym) symmetryAnchor.y = mouseWOffset.y;
				gPanel.panelLabel = "x:" + (int)symmetryAnchor.x +  "|y:" + (int)symmetryAnchor.y;
			}
			else if (!modeDefineFace && selectedAnchor.distance(mouseWOffset) < anchorDiameter && gPanel.isVisible) { //move anchor
				selectedAnchor.set(mouseWOffset);
				for (Polygon polygon : allPolygons) {
					if (Arrays.asList(polygon.dots).contains(selectedAnchor)) {
						polygon.redrawFace();
					}
				}
				//setGPLabel();
				gPanel.panelLabel = "x:" + (int)selectedAnchor.x +  "|y:" + (int)selectedAnchor.y;
			}
		}
		else if (edwin.mouseBtnHeld == RIGHT) {
			float mouseDist, closestDist;
			closestDist = selectedAnchor.distance(mouseWOffset);
			for (XY dot : allDots) {
				mouseDist = dot.distance(mouseWOffset);
				if (mouseDist < closestDist) {
					selectedAnchor = dot;
					closestDist = mouseDist;
				}
			}
		}
		else if (edwin.mouseBtnHeld == CENTER && gPanel.isVisible) {
			originOffset.set(mouseX, mouseY);
			gPanel.panelLabel = "offset x:" + (int)originOffset.x +  "|y:" + (int)originOffset.y;
		}	
		else if (edwin.mouseHovering) {
			mouseoverPolygonBorder = null;
			for (Polygon polygon : allPolygons) {
				if (polygon != selectedPolygon && polygon.containsPoint(mouseX - originOffset.x, mouseY - originOffset.y)) {
					mouseoverPolygonBorder = redrawHilight(polygon, EdColors.UI_NORMAL);
					break;
				}
			}
			if (modeDefineFace) {
				float mouseDist, closestDist;
				closestDist = selectedAnchor.distance(mouseWOffset);
				for (XY dot : allDots) {
					mouseDist = dot.distance(mouseWOffset);
					if (mouseDist < closestDist) {
						selectedAnchor = dot;
						closestDist = mouseDist;
					}
				}
			}
		}

		return "";
	}

	//void setGPLabel() { gPanel.panelLabel = "x:" + (int)selectedAnchor.x +  "|y:" + (int)selectedAnchor.y; }

	String keyboard(KeyEvent event) {
		if (event.getAction() != KeyEvent.RELEASE) {
			return "";
		}
		int kc = event.getKeyCode();
		if (kc == Keycodes.VK_P) {
			gPanel.toggleVisibility();
			return getName();
		}
		else if (kc == Keycodes.VK_SPACE) {
			playAnimation = !playAnimation;
			return getName();
		}
		else if (kc == Keycodes.VK_LEFT && !selectedAnimation.currentFrame.atMin()) {
			selectedAnimation.currentFrame.decrement();
			selectedAnimation.drawFrame();
		}
		else if (kc == Keycodes.VK_RIGHT && !selectedAnimation.currentFrame.atMax()) {
			selectedAnimation.currentFrame.increment();
			selectedAnimation.drawFrame();
		}
		else if (kc == Keycodes.VK_N) {
			queueNextAnimation = true;
			return getName();
		}
		else if (!gPanel.isVisible) {
			return "";
		}
		else if (kc == Keycodes.VK_F) {
			gPanel.itemExecute("frame prev|next|new", GadgetPanel.PLUS);
			return getName();
		}
		else if (kc == Keycodes.VK_Z) {
			defineFace();
			return getName();
		}
		else if (kc == Keycodes.VK_D && event.isControlDown()) {
			addDot();
			return getName();
		}
		else if (selectedPolygon != null) {
			int num = kc - 48; //VK_0, VK_1, ...
			if (num >= 0 && num < palette.colors.size()) {
				selectedPolygon.redrawFace(num);
				selectedAnimation.setColor(num);
			}
		}
		// 	else if (event.isShiftDown()) {
		// 	}
		// 	else {
		// 		gPanel.itemExecute(SELECTED_DOT, GadgetPanel.ARROW_E);
		// 	}
		// }
		// else if (kc == Keycodes.VK_UP) {
		// 	if (event.isControlDown()) {
		// 		selectedAnchor.y--;
		// 		setGPLabel();
		// 	}
		// }
		// else if (kc == Keycodes.VK_DOWN) {
		// 	if (event.isControlDown()) {
		// 		selectedAnchor.y++;
		// 		setGPLabel();
		// 	}
		// }
		return "";
	}

	void restartAnimation() {
		animationFramerate.minimize();
		selectedAnimation.currentFrame.minimize();
		selectedAnimation.drawFrame();
		playAnimation = true;
	}

	/** Called whenever we start or stop a face */
	void defineFace() {
		modeDefineFace = !modeDefineFace; //toggle
		gPanel.getButtons(FACEMAKING).toggleImage();
		if (modeDefineFace) gPanel.panelLabel = "face started";
		else {
			if (buildingPolygon.size() < 3) {
				gPanel.panelLabel = "need dots > 2";
			}
			else {
				allPolygons.add(new Polygon(buildingPolygon.toArray(new XY[0])));
				gPanel.panelLabel = "new face added";
			}
			buildingPolygon.clear();
		}
	}

	PShape redrawHilight(Polygon polygon, int borderColor) {
		PShape polygonBorder = createShape();
		polygonBorder.beginShape();
		polygonBorder.strokeWeight(2);
		polygonBorder.stroke(borderColor);
		polygonBorder.noFill();
		for (XY dot : polygon.dots) {
			polygonBorder.vertex(dot.x, dot.y);
		}
		polygonBorder.endShape(CLOSE);
		return polygonBorder;
	}

	void openFile(File file) {
		if (file == null) return; //user hit cancel or closed
		openFilepath = file.getAbsolutePath();
	}

	void digestFile() {
		JSONObject json = loadJSONObject(openFilepath);
		openFilepath = null;
		useHorzSym = useVertSym = false;
		if (!json.isNull(SYMMETRY_X)) {
			symmetryAnchor.x = json.getInt(SYMMETRY_X);
			useVertSym = true;
		}
		if (!json.isNull(SYMMETRY_Y)) {
			symmetryAnchor.y = json.getInt(SYMMETRY_Y);
			useHorzSym = true;
		}
		gPanel.getButtons(VERTICAL_SYM).setCheck(1, useVertSym);
		gPanel.getButtons(HORIZONTAL_SYM).setCheck(1, useHorzSym);
		originOffset.set(json.getFloat(OFFSET_X), json.getFloat(OFFSET_Y));
		palette.resetColors(json.getJSONArray(EdFiles.COLOR_PALETTE).getIntArray());

		//create verticies
		allDots.clear();
		for (String coords : json.getJSONArray(EdFiles.DOTS).getStringArray()) {
			String[] values = coords.split("\\.");
			allDots.add(new XY(Float.valueOf(values[0]), Float.valueOf(values[1])));
		}
		selectedAnchor = allDots.get(0);

		//get and draw polygons
		allPolygons.clear();
		XY[] anchors;
		JSONObject jsonPolygon;
		for (int i = 0; i < json.getJSONArray(POLYGONS).size(); i++) {
			jsonPolygon = json.getJSONArray(POLYGONS).getJSONObject(i);
			anchors = new XY[jsonPolygon.getJSONArray(EdFiles.DOTS).size()];
			int a = 0;
			for (int anchorIndex : jsonPolygon.getJSONArray(EdFiles.DOTS).getIntArray()) {
				anchors[a++] = allDots.get(anchorIndex);
			}
			allPolygons.add(new Polygon(anchors));
		}

		//store animations
		allAnimations.clear();
		JSONObject jsonAnimation;
		for (int i = 0; i < json.getJSONArray(ANIMATIONS).size(); i++) {
			jsonAnimation = json.getJSONArray(ANIMATIONS).getJSONObject(i);
			allAnimations.add(new AnimationFrames(jsonAnimation.getString(ANIMATION_NAME), jsonAnimation.getJSONArray(ANIMATION_FRAMES)));
		}
		selectedAnimation = allAnimations.get(0);
		selectedAnimation.drawFrame();
	}

	void saveFile(File file) {
		if (file == null) return; //user hit cancel or closed
		ArrayList<String> fileLines = new ArrayList<String>();
		fileLines.add("{"); //opening bracket
		fileLines.add(jsonKV(OFFSET_X, originOffset.x));
		fileLines.add(jsonKV(OFFSET_Y, originOffset.y));
		fileLines.add(jsonKV(SYMMETRY_X, (useVertSym ? String.valueOf(symmetryAnchor.x) : "null")));
		fileLines.add(jsonKV(SYMMETRY_Y, (useHorzSym ? String.valueOf(symmetryAnchor.y) : "null")));
		fileLines.add(palette.asJsonKV());
		fileLines.add(jsonKVNoComma(EdFiles.DOTS, "["));
		int valueCount = -1;
		String line = "";
		//here we save each set of coordinates separated by a period ("xxx.yyy")
		//to make it easier to read and smaller to store
		for (int i = 0; i < allDots.size(); i++) {
			if (++valueCount == 10) {
				valueCount = 0;
				fileLines.add(TAB + line);
				line = "";
			}
			line += "\"" + (int)allDots.get(i).x + "." + (int)allDots.get(i).y + "\", ";
		}
		fileLines.add(TAB + line);
		fileLines.add("],"); //close dots list

		//list polygons as json objects {"dots":[vertex indicies...]}
		fileLines.add(jsonKVNoComma(POLYGONS, "["));
		for (Polygon polygon : allPolygons) {
			String[] dotIndicies = new String[polygon.dots.length];
			for (int i = 0; i < polygon.dots.length; i++) {
				dotIndicies[i] = String.valueOf(allDots.indexOf(polygon.dots[i]));
			}
			fileLines.add(TAB + "{" + jsonKV(EdFiles.DOTS, Arrays.toString(dotIndicies) + "}")); 
		}
		fileLines.add("],"); //close polygon list

		//animations
		fileLines.add(jsonKVNoComma(ANIMATIONS, "[{"));
		int a = 0;
		for (AnimationFrames animation : allAnimations) {
			if (a++ > 0) fileLines.add("},{"); //separation between animation objects in this array
			fileLines.add(TAB + jsonKVString(ANIMATION_NAME, animation.name));
			fileLines.add(TAB + jsonKVNoComma(ANIMATION_FRAMES, "["));
			for (int i = 0; i < animation.polygonColors.length; i++) {
				fileLines.add(TAB + TAB + "{" + jsonKV(FRAME_DELAY, animation.delays[i]) + jsonKV(FRAME_COLORS, "\"" + animation.polygonColors[i] + "\"}"));
			}
			fileLines.add(TAB + "]"); //close frames for this animation
		}
		fileLines.add("}]"); //close animation list
		fileLines.add("}"); //final closing bracket
		saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
	}

	String getName() {
		return "PolywireOld";
	}

	/** Face on the wireframe */
	class Polygon {
		XY[] dots;
		PShape face, wire;
		int paletteIndex;

		Polygon(XY[] anchors) { this(anchors, 1); }
		Polygon(XY[] anchors, int paletteColor) {
			dots = anchors;
			paletteIndex = paletteColor;
			redrawFace();
		}

		void redrawFace() { redrawFace(paletteIndex); }
		void redrawFace(int paletteColor) {
			PShape paintedFace = createShape();
			paintedFace.beginShape();
			if (paletteColor == 1) paintedFace.noFill();
			else paintedFace.fill(palette.colors.get(paletteColor));
			paintedFace.stroke(#201708);
			paintedFace.strokeWeight(3);
			PShape paintedWire = createShape();
			paintedWire.beginShape();
			paintedWire.noFill();
			if (random(100) > 90) paintedWire.stroke(#17a1a9);
			else paintedWire.stroke(#173b47);
			paintedWire.strokeWeight(1);
			for (XY dot : dots) {
				paintedFace.vertex(dot.x, dot.y);
				paintedWire.vertex(dot.x, dot.y);
			}
			paintedFace.endShape(CLOSE);
			paintedWire.endShape(CLOSE);
			face = paintedFace;
			wire = paintedWire;
			paletteIndex = paletteColor;
		}

		boolean containsPoint(float x, float y) {
			// https://stackoverflow.com/a/16391873
			boolean inside = false;
			for (int i = 0, j = dots.length - 1; i < dots.length; j = i++) {
				if ((dots[i].y > y) != (dots[j].y > y) &&
					x < (dots[j].x - dots[i].x) * (y - dots[i].y) / (dots[j].y - dots[i].y) + dots[i].x) {
					inside = !inside;
				}
			}
			return inside;
		}
	}

	/** Series of color changes for the polygons on the wireframe */
	class AnimationFrames {
		String name;
		String[] polygonColors;
		int[] delays;
		BoundedInt currentFrame;
		
		AnimationFrames(String animationName) { this(animationName, new JSONArray()); }
		AnimationFrames(String animationName, JSONArray json) {
			name = animationName;
			polygonColors = new String[json.size()];
			delays = new int[json.size()];
			currentFrame = new BoundedInt(0, -1);
			currentFrame.loops = true;
			JSONObject frame;
			for (int i = 0; i < json.size(); i++) {
				frame = json.getJSONObject(i);
				polygonColors[i] = frame.getString(FRAME_COLORS);
				delays[i] = frame.getInt(FRAME_DELAY);
				currentFrame.incrementMax();
			}
		}

		void addBlankFrame() { 
			char[] nums = new char[allPolygons.size()];
			Arrays.fill(nums, '1');
			addFrame(0, new String(nums));
		}

		void addDuplicateFrame() { 
			addFrame(delays[currentFrame.value], polygonColors[currentFrame.value]);
		}

		void addFrame(int delay, String colors) {
			int maxIndex = polygonColors.length;
			polygonColors = Arrays.copyOf(polygonColors, maxIndex + 1);
			polygonColors[maxIndex] = colors;
			delays = Arrays.copyOf(delays, maxIndex + 1);
			delays[maxIndex] = delay;
			currentFrame.incrementMax();
			currentFrame.maximize();
		}

		void drawFrame() {
			if (polygonColors.length == 0) return;
			String[] colors = polygonColors[currentFrame.value].split("");
			for (int i = 0; i < allPolygons.size(); i++) {
				allPolygons.get(i).redrawFace(Integer.valueOf(colors[i]));
			}
		}

		void setColor(int paletteIndex) {
			int polyIndex = allPolygons.indexOf(selectedPolygon);
			String updated = polygonColors[currentFrame.value].substring(0, polyIndex);
			updated += paletteIndex + polygonColors[currentFrame.value].substring(polyIndex + 1, allPolygons.size());
			polygonColors[currentFrame.value] = updated;
		}
	}
} //end PolywireOld