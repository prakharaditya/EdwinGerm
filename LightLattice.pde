/** 
* This lets you make a wireframe figure 
* and  make a lightshow on its polygons.
* File saved as .ll
*
* Press L to toggle visibility
*/
public class LightLattice extends DraggableWindow implements Kid {
	Figure figure;
	Shimmer shimmer;
	Morph morph;
	ArrayList<XY> allDots, buildingPolygon;
	ArrayList<LatticePolygon> allPolygons;
	ChargeColor[] chargeColors;
	BoundedInt defaultCharge;
	BoundedFloat figureScale;
	GridButtons modeButtons, openSaveButtons;
	PalettePicker palette;
	Album basicButtonAlbum;
	PImage referenceImage, unscaledReference;
	XY offset, figureDragOffset;
	String openFilepath;
	boolean figureBeingDragged, referenceImageVisible;
	int editMode;
	//Album and pages for edit modes
	final String BUTTON_MENU_FILENAME = "polywireButtons.alb",
	BUTTON_FIGURE = "modeFigure",
	BUTTON_FIGURE_CHECKED = "modeFigureChecked",
	BUTTON_SHIMMER = "modeShimmer",
	BUTTON_SHIMMER_CHECKED = "modeShimmerChecked",
	BUTTON_MORPH = "modeMorph",
	BUTTON_MORPH_CHECKED = "modeMorphChecked",
	WAND = "wand",
	WAND_CHECKED = "wandChecked",
	BLANK = "blank",
	BLANK_CHECKED = "blankChecked",
	//file json keys
	OFFSET_X = "offset x",
	OFFSET_Y = "offset y",
	POLYGONS = "polygons",
	ANIMATIONS = "animations",
	ANIMATION_NAME = "name",
	ANIMATION_FRAMES = "frames",
	FRAME_DELAY = "delay",
	FRAME_COLORS = "polygon colors";
	//Constants for tracking editMode
	final int EDIT_FIGURE_ANCHORS = 0,
	EDIT_FIGURE_POLYGONS = 1,
	EDIT_SHIMMER_PATH = 2,
	EDIT_SHIMMER_PULSE = 3,
	EDIT_MORPH = 4;

	LightLattice() { this(true); }
	LightLattice(boolean initiallyVisible) {
		super(0, 0);
		isVisible = initiallyVisible; //only applies to editing windows, not the figure
		modeButtons = new GridButtons(body, UI_PADDING, dragBar.h + UI_PADDING * 2, 1, 
			new Album(BUTTON_MENU_FILENAME), 
			new String[] { BUTTON_FIGURE, BUTTON_SHIMMER, BUTTON_MORPH, WAND, BLANK },
			new String[] { BUTTON_FIGURE_CHECKED, BUTTON_SHIMMER_CHECKED, BUTTON_MORPH_CHECKED, WAND_CHECKED, BLANK_CHECKED }
		);
		modeButtons.setCheck(0, true);
		openSaveButtons = new GridButtons(body, UI_PADDING, modeButtons.body.yh(), 1, 
			new Album(AlbumEditor.TOOL_MENU_FILENAME), 
			new String[] { AlbumEditor.SAVE, AlbumEditor.OPEN }
		);
		body.setSize(modeButtons.body.w + UI_PADDING * 2, openSaveButtons.body.yh() + UI_PADDING);
		dragBar.w = modeButtons.body.w;
		basicButtonAlbum = new Album(GadgetPanel.BUTTON_FILENAME);
		allPolygons = new ArrayList<LatticePolygon>();
		allDots = new ArrayList<XY>();
		allDots.add(new XY(200, 200));
		figureScale = new BoundedFloat(0.5, 5.0, 1.0, 0.5);
		offset = new XY(0, 0);
		figureDragOffset = new XY(0, 0);
		figureBeingDragged = referenceImageVisible = false;
		referenceImage = unscaledReference = null;
		openFilepath = null;
		editMode = EDIT_FIGURE_ANCHORS;
		figure = new Figure();
		shimmer = new Shimmer();
		morph = new Morph();
		//default figure colors
		int BORDER_W = 1, HILIGHT_W = 2; 
		palette = new PalettePicker(new int[] { #173b47, #046894, #17a1a9, #81dbcd, #fdf9f1, #201708, #463731, #87715b }, "Lattice colors", false);
		chargeColors = new ChargeColor[9];
		chargeColors[0] = new ChargeColor(BORDER_W, HILIGHT_W, 5, 0, 0);
		chargeColors[1] = new ChargeColor(BORDER_W, HILIGHT_W, 5, 1, 0);
		chargeColors[2] = new ChargeColor(BORDER_W, HILIGHT_W, 5, 1, 1);
		chargeColors[3] = new ChargeColor(BORDER_W, HILIGHT_W, 6, 2, 1);
		chargeColors[4] = new ChargeColor(BORDER_W, HILIGHT_W, 6, 2, 2);
		chargeColors[5] = new ChargeColor(BORDER_W, HILIGHT_W, 6, 3, 2);
		chargeColors[6] = new ChargeColor(BORDER_W, HILIGHT_W, 6, 3, 3);
		chargeColors[7] = new ChargeColor(BORDER_W, HILIGHT_W, 7, 4, 3);
		chargeColors[8] = new ChargeColor(BORDER_W, HILIGHT_W, 7, 4, 4);
		defaultCharge = new BoundedInt(0, chargeColors.length, 5);
		//edwin.useSmooth = false;
	}

	void drawSelf(PGraphics canvas) {
		if (openFilepath != null) digestFile();
		//figure
		canvas.pushMatrix();
		canvas.translate(offset.x, offset.y);
		if (isVisible && referenceImageVisible && editMode <= EDIT_FIGURE_POLYGONS) {
			canvas.image(referenceImage, 0, 0);
		}
		ChargeColor colr;
		canvas.noStroke();
		for (LatticePolygon polygon : allPolygons) {
			//polygon.update();
			colr = chargeColors[polygon.chargeLevel];

			if (colr.borderWidth.value > 0) {
				canvas.beginShape();
				canvas.fill(palette.colors.get(colr.borderPaletteIndex));
				for (XY dot : polygon.dots) {
					canvas.vertex(dot.x * figureScale.value, dot.y * figureScale.value);
				}
				canvas.endShape(CLOSE);
			}

			if (colr.hilightWidth.value > 0) {
				canvas.beginShape();
				canvas.fill(palette.colors.get(colr.hilightPaletteIndex));
				for (XY dot : polygon.getOffsetPoly(colr.borderWidth.value)) {
					canvas.vertex(dot.x * figureScale.value, dot.y * figureScale.value);
				}
				canvas.endShape(CLOSE);
			}

			canvas.beginShape();
			canvas.fill(palette.colors.get(colr.facePaletteIndex));
			for (XY dot : polygon.getOffsetPoly(colr.borderWidth.value + colr.hilightWidth.value)) {
				canvas.vertex(dot.x * figureScale.value, dot.y * figureScale.value);
			}
			canvas.endShape(CLOSE);

			// if (polygon.chargeLevel == chargeColors.length - 1) polygon.chargeLevel = 0;
			// else polygon.chargeLevel++;
		}
		canvas.popMatrix();

		//edit mode
		if (!isVisible) return;
		switch (editMode) {
			case EDIT_FIGURE_ANCHORS:
			case EDIT_FIGURE_POLYGONS:
				figure.drawSelf(canvas);
				break;
			case EDIT_SHIMMER_PATH:
			case EDIT_SHIMMER_PULSE:
				shimmer.drawSelf(canvas);
				break;
			case EDIT_MORPH:
				morph.drawSelf(canvas);
				break;
		}

		//DraggableWindow stuff
		super.drawSelf(canvas);
		canvas.pushMatrix();
		canvas.translate(body.x, body.y);
		modeButtons.drawSelf(canvas);
		openSaveButtons.drawSelf(canvas);
		canvas.popMatrix();

		palette.drawSelf(canvas);
	}

	String mouse() { 
		if (!isVisible) return "";
		if (super.mouse() != "") return "dragging";
		if (palette.mouse() != "") return "palette changes";

		//offset dragging
		if (edwin.mouseBtnBeginHold == CENTER) {
			figureBeingDragged = true;
			figureDragOffset.set(mouseX - offset.x, mouseY - offset.y);
			return "begin drag";
		}
		if (figureBeingDragged) {
			offset.set(mouseX - figureDragOffset.x, mouseY - figureDragOffset.y);
			if (edwin.mouseBtnReleased == CENTER) {
				figureBeingDragged = false;
				return "end drag";
			}
			return "dragging";
		}

		//route mouse event
		switch (editMode) {
			case EDIT_FIGURE_ANCHORS:
			case EDIT_FIGURE_POLYGONS:
				if (figure.mouse() != "") return "figure editing";
				break;
			case EDIT_SHIMMER_PATH:
			case EDIT_SHIMMER_PULSE:
				if (shimmer.mouse() != "") return "shimmer editing";
				break;
			case EDIT_MORPH:
				if (morph.mouse() != "") return "morph editing";
				break;
		}

		//at this point we're checking to see if a mode button was pressed
		if (edwin.mouseBtnReleased != LEFT) return "";
		String clicked = modeButtons.mouse();
		if (clicked != "" && !clicked.endsWith("Checked")) {
			//to treat the modes like a radio button group we uncheck all buttons then flip back on the relevant one
			modeButtons.uncheckAll();
			switch (clicked) {
				case BUTTON_FIGURE:
					editMode = EDIT_FIGURE_ANCHORS;
					modeButtons.toggleImage(0);
					break;
				case BUTTON_SHIMMER:
					editMode = EDIT_SHIMMER_PATH;
					modeButtons.toggleImage(1);
					break;
				case BUTTON_MORPH:
					editMode = EDIT_MORPH;
					modeButtons.toggleImage(2);
					break;
				case WAND:
					modeButtons.toggleImage(3);
					break;
				case BLANK:
					modeButtons.toggleImage(4);
					break;
			}
			return clicked;
		}
		clicked = openSaveButtons.mouse();
		if (clicked != "") {
			switch (clicked) {
				case AlbumEditor.OPEN:
					selectInput("Open Lasers...", "openFile", null, LightLattice.this);
					break;
				case AlbumEditor.SAVE:
					selectOutput("Save Lasers...", "saveFile", null, LightLattice.this);
					break;
			}
			return clicked;
		}
		return "";
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() == KeyEvent.RELEASE && event.getKeyCode() == Keycodes.VK_L) {
			toggleVisibility();
			return getName();
		}
		if (!isVisible) return "";
		//route keyboard event
		switch (editMode) {
			case EDIT_FIGURE_ANCHORS:
			case EDIT_FIGURE_POLYGONS:
				if (figure.keyboard(event) != "") return "figure editing";
				break;
			case EDIT_SHIMMER_PATH:
			case EDIT_SHIMMER_PULSE:
				if (shimmer.keyboard(event) != "") return "shimmer editing";
				break;
			case EDIT_MORPH:
				if (morph.keyboard(event) != "") return "morph editing";
				break;
		}
		return "";
	}

	void openFile(File file) {
		if (file == null) return; //user hit cancel or closed
		openFilepath = file.getAbsolutePath();
	}

	void digestFile() {
		JSONObject json = loadJSONObject(openFilepath);
		openFilepath = null;
		offset.set(json.getFloat(OFFSET_X), json.getFloat(OFFSET_Y));
		palette.resetColors(json.getJSONArray(EdFiles.COLOR_PALETTE).getIntArray());

		//create verticies
		allDots.clear();
		for (String coords : json.getJSONArray(EdFiles.DOTS).getStringArray()) {
			String[] values = coords.split("\\.");
			allDots.add(new XY(Float.valueOf(values[0]), Float.valueOf(values[1])));
		}
		figure.closestAnchor = allDots.get(0);

		//get and draw polygons
		allPolygons.clear();
		JSONObject jsonPolygon;
		for (int i = 0; i < json.getJSONArray(POLYGONS).size(); i++) {
			jsonPolygon = json.getJSONArray(POLYGONS).getJSONObject(i);
			XY[] anchors = new XY[jsonPolygon.getJSONArray(EdFiles.DOTS).size()];
			int a = 0;
			for (int anchorIndex : jsonPolygon.getJSONArray(EdFiles.DOTS).getIntArray()) {
				anchors[a++] = allDots.get(anchorIndex);
			}
			allPolygons.add(new LatticePolygon(anchors));
		}

		//store animations
		// allAnimations.clear();
		// JSONObject jsonAnimation;
		// for (int i = 0; i < json.getJSONArray(ANIMATIONS).size(); i++) {
		// 	jsonAnimation = json.getJSONArray(ANIMATIONS).getJSONObject(i);
		// 	allAnimations.add(new AnimationFrames(jsonAnimation.getString(ANIMATION_NAME), jsonAnimation.getJSONArray(ANIMATION_FRAMES)));
		// }
		// selectedAnimation = allAnimations.get(0);
		// selectedAnimation.drawFrame();
	}

	void saveFile(File file) {
		if (file == null) return; //user hit cancel or closed
		ArrayList<String> fileLines = new ArrayList<String>();
		fileLines.add("{"); //opening bracket
		fileLines.add(jsonKV(OFFSET_X, offset.x));
		fileLines.add(jsonKV(OFFSET_Y, offset.y));
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
		for (LatticePolygon polygon : allPolygons) {
			String[] dotIndicies = new String[polygon.dots.length];
			for (int i = 0; i < polygon.dots.length; i++) {
				dotIndicies[i] = String.valueOf(allDots.indexOf(polygon.dots[i]));
			}
			fileLines.add(TAB + "{" + jsonKV(EdFiles.DOTS, Arrays.toString(dotIndicies) + "}")); 
		}
		fileLines.add("],"); //close polygon list

		//animations
		// fileLines.add(jsonKVNoComma(ANIMATIONS, "[{"));
		// int a = 0;
		// for (AnimationFrames animation : allAnimations) {
		// 	if (a++ > 0) fileLines.add("},{"); //separation between animation objects in this array
		// 	fileLines.add(TAB + jsonKVString(ANIMATION_NAME, animation.name));
		// 	fileLines.add(TAB + jsonKVNoComma(ANIMATION_FRAMES, "["));
		// 	for (int i = 0; i < animation.polygonColors.length; i++) {
		// 		fileLines.add(TAB + TAB + "{" + jsonKV(FRAME_DELAY, animation.delays[i]) + jsonKV(FRAME_COLORS, "\"" + animation.polygonColors[i] + "\"}"));
		// 	}
		// 	fileLines.add(TAB + "]"); //close frames for this animation
		// }
		//fileLines.add("}]"); //close animation list

		fileLines.add("}"); //final closing bracket
		saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
	}

	void openImage(File file) {
		if (file == null) return; //user hit cancel or closed
		unscaledReference = loadImage(file.getAbsolutePath());
		figureScale.set(1.0);
		figure.getButtons("visible").setCheck(true);
		rescaleImage();
		referenceImageVisible = true;
	}

	void rescaleImage() {
		figure.windowTitle = "scale:" + figureScale.value;
		if (unscaledReference != null) {
			referenceImage = unscaledReference.copy();
			referenceImage.resize((int)(unscaledReference.width * figureScale.value), (int)(unscaledReference.height * figureScale.value));
		}
		// for (LatticePolygon polygon : allPolygons) {
		// 	polygon.redrawFace();
		// }
	}

	/** Get mouse position adjusted for offset and scale */
	XY translateMouse() {
		return new XY((mouseX - offset.x) / figureScale.value, (mouseY - offset.y) / figureScale.value);
	}

	String getName() {
		return "LightLattice";
	}

	/** 
	* Face on the lattice 
	*/
	private class LatticePolygon {
		XY[] dots, newDots;
		int chargeLevel;

		LatticePolygon(ArrayList<XY> anchors) { this(anchors.toArray(new XY[0])); }
		LatticePolygon(XY[] anchors) {
			dots = anchors;
			chargeLevel = defaultCharge.value;
			newDots = null;
		}

		//need to do it this way so that we don't interrupt the draw loop
		void update() {
			if (newDots != null) {
				dots = newDots;
				newDots = null;
			}
		}

		//http://pyright.blogspot.com/2011/02/simple-polygon-offset.html
		//https://stackoverflow.com/questions/1109536/an-algorithm-for-inflating-deflating-offsetting-buffering-polygons

		XY[] getOffsetPoly(float offset) {
			XY[] newPoly = new XY[dots.length];
			for (int i = 0; i < dots.length - 3; i++) {
				newPoly[i] = getPt(dots[i], dots[i + 1], dots[i + 2], offset);
			}
			int n = dots.length - 1;
			newPoly[n - 2] = getPt(dots[n - 2], dots[n - 1], dots[n], offset);
			newPoly[n - 1] = getPt(dots[n - 1], dots[n], dots[0], offset);
			newPoly[n] = getPt(dots[n], dots[0], dots[1], offset);
			return newPoly;
		}

		XY getPt(XY pt1, XY pt2, XY pt3, float offset) {
			// first offset intercept
			float divisor = (pt1.x == pt2.x) ? 1 : pt2.x - pt1.x;
			float m = (pt2.y - pt1.y)/divisor;
			//if (m == Float.POSITIVE_INFINITY || m == Float.NEGATIVE_INFINITY) m = (pt2.y - pt1.y);
			float boffset = getOffsetIntercept(pt1, pt2, m, offset);

			// get second offset intercept
			float divisorprime = (pt2.x == pt3.x) ? 1 : pt3.x - pt2.x;
			float mprime = (pt3.y - pt2.y)/divisorprime;
			//if (mprime == Float.POSITIVE_INFINITY || mprime == Float.NEGATIVE_INFINITY) mprime = (pt3.y - pt2.y);
			float boffsetprime = getOffsetIntercept(pt2, pt3, mprime, offset);

			// get intersection of two offset lines
			float newx = (boffsetprime - boffset)/(m - mprime);
			float newy = m * newx + boffset;
			//println(m + "|" + boffset + "|" + mprime + "|" + boffsetprime + "|" + newx + "|" + newy);
			return new XY(newx, newy);
		}

		float getOffsetIntercept(XY pt1, XY pt2, float m, float offset) {
			float theta = atan2(pt2.y - pt1.y, pt2.x - pt1.x) + HALF_PI;
			return (pt1.y - sin(theta) * offset) - m * (pt1.x - cos(theta) * offset);
		}

		boolean containsPoint(XY point) { return containsPoint(point.x, point.y); }
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

		// void redrawFace() { redrawFace(paletteIndex); }
		// void redrawFace(int paletteColor) {
		// 	PShape paintedFace = createShape();
		// 	paintedFace.beginShape();
		// 	//paintedFace.fill(palette.colors.get(paletteColor));
		// 	paintedFace.fill(#55535A);
		// 	paintedFace.stroke(#201708);
		// 	paintedFace.strokeWeight(4);
		// 	PShape paintedWire = createShape();
		// 	paintedWire.beginShape();
		// 	paintedWire.noFill();
		// 	paintedWire.stroke(palette.colors.get(paletteColor));
		// 	//paintedWire.stroke(#55535A);
		// 	paintedWire.strokeWeight(1);
		// 	for (XY dot : dots) {
		// 		paintedFace.vertex(dot.x * figureScale.value, dot.y * figureScale.value);
		// 		paintedWire.vertex(dot.x * figureScale.value, dot.y * figureScale.value);
		// 	}
		// 	paintedFace.endShape(CLOSE);
		// 	paintedWire.endShape(CLOSE);
		// 	face = paintedFace;
		// 	wire = paintedWire;
		// 	paletteIndex = paletteColor;
		// }

	} //end LatticePolygon

	/** 
	* Colors for polygon charge
	*/
	private class ChargeColor {
		BoundedInt borderWidth, hilightWidth;
		int borderPaletteIndex, hilightPaletteIndex, facePaletteIndex;
		ChargeColor(int stroke1W, int stroke2W, int stroke1C, int stroke2C, int faceC) {
			borderWidth = new BoundedInt(0, 10, stroke1W);
			hilightWidth = new BoundedInt(0, 10, stroke2W);
			borderPaletteIndex = stroke1C;
			hilightPaletteIndex = stroke2C;
			facePaletteIndex = faceC;
		}
	}

	/** 
	* Edit anchors and polygons 
	*/
	private class Figure extends GadgetPanel {
		LatticePolygon selectedPolygon;
		ArrayList<XY> selectedAnchors;
		XY closestAnchor;
		boolean showDots;
		final int DOT_RADIUS = 7;

		Figure() {
			super(40 + UI_PADDING * 2, 0, "Figure", basicButtonAlbum);
			selectedAnchors = new ArrayList<XY>();
			closestAnchor = allDots.get(0);
			selectedPolygon = null;
			showDots = true;

			//GadgetPanel items
			addItem("image", GadgetPanel.OPEN, new Command() {
				void execute(String arg) {
					selectInput("Select image (.jpg, .png)", "openImage", null, LightLattice.this);
				}
			});

			addItem("visible", GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
				void execute(String arg) {
					if (referenceImage == null) {
						windowTitle = "no image loaded";
						return;
					}
					getButtons("visible").toggleImage();
					referenceImageVisible = !referenceImageVisible;
				}
			});

			addItem("scale", new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS }, new Command() {
				void execute(String arg) {
					if (arg == GadgetPanel.MINUS) figureScale.decrement();
					else figureScale.increment();
					rescaleImage();
				}
			});

			addItem("define polygon", GadgetPanel.START_LIGHT, GadgetPanel.STOP_LIGHT, new Command() {
				void execute(String arg) {
					definePolygon();
				}
			});

			addItem("dot add|split", new String[] { GadgetPanel.PLUS, GadgetPanel.OVER_UNDER }, new Command() {
				void execute(String arg) {
					if (arg == GadgetPanel.PLUS) {
						addDot(closestAnchor.x + 20, closestAnchor.y + 20);
					}
					else { //if (arg == GadgetPanel.OVER_UNDER) {
						splitLine();
					}
				}
			});

			addItem("disconnect|delete", new String[] { GadgetPanel.BLANK, GadgetPanel.BIGX }, new Command() {
				void execute(String arg) {
					if (arg == GadgetPanel.BLANK) {
						println("nada");
						// ArrayList<LatticePolygon> toDelete = new ArrayList<LatticePolygon>();
						// for (LatticePolygon polygon : allPolygons) {
						// 	if (Arrays.asList(polygon.dots).contains(selectedAnchor)) {
						// 		toDelete.add(polygon);
						// 	}
						// }
						// int confirm = JOptionPane.showConfirmDialog(null, "Remove " + toDelete.size() + " polygons connected to dot?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
						// if (confirm == JOptionPane.YES_OPTION) { 
						// 	for (LatticePolygon del : toDelete) {
						// 		allPolygons.remove(del);
						// 	}
						// }
					}
					else { //if (arg == GadgetPanel.BIGX) {
						deleteDot();
					}
				}
			});

		} //end constructor

		void drawSelf(PGraphics canvas) {
			float s = figureScale.value;
			canvas.pushMatrix();
			canvas.translate(offset.x, offset.y);
			//all anchors
			canvas.strokeWeight(1);
			if (showDots) {
				canvas.fill(EdColors.UI_DARKEST);
				canvas.stroke(EdColors.UI_DARK);
				for (XY dot : allDots) {
					canvas.ellipse(dot.x * s, dot.y * s, DOT_RADIUS, DOT_RADIUS);
				}
			}
			canvas.fill(EdColors.UI_EMPHASIS);
			canvas.ellipse(closestAnchor.x * s, closestAnchor.y * s, DOT_RADIUS, DOT_RADIUS);
			
			//selected anchors
			if (selectedAnchors.size() > 0) {
				canvas.fill(color(#FFFFFF, 100));
				XY lastSelected = selectedAnchors.get(selectedAnchors.size() - 1);
				canvas.ellipse(lastSelected.x * s, lastSelected.y * s, DOT_RADIUS * 3, DOT_RADIUS * 3);
				canvas.stroke(EdColors.UI_EMPHASIS);
				canvas.strokeWeight(3);
				for (int i = 0; i < selectedAnchors.size() - 1; i++) {
					XY p1 = selectedAnchors.get(i);
					XY p2 = selectedAnchors.get(i + 1);
					canvas.line(p1.x * s, p1.y * s, p2.x * s, p2.y * s);
				}
				//implied line that closes the polygon
				if (selectedAnchors.size() > 2) {
					canvas.stroke(color(#FFFFFF, 100));
					canvas.line(lastSelected.x * s, lastSelected.y * s, selectedAnchors.get(0).x * s, selectedAnchors.get(0).y * s);
				}
				canvas.strokeWeight(1);
			}

			//mouseover hilighted polygon
			if (selectedPolygon == null) {
				XY mouseTranslated = translateMouse();
				for (LatticePolygon polygon : allPolygons) {
					if (polygon.containsPoint(mouseTranslated.x, mouseTranslated.y)) {
						canvas.stroke(color(#FFFFFF, 100));
						canvas.strokeWeight(3);
						int n = polygon.dots.length - 1;
						for (int i = 0; i < n; i++) {
							canvas.line(polygon.dots[i].x * s, polygon.dots[i].y * s, polygon.dots[i + 1].x * s, polygon.dots[i + 1].y * s);
						}
						canvas.line(polygon.dots[n].x * s, polygon.dots[n].y * s, polygon.dots[0].x * s, polygon.dots[0].y * s);
						break;
					}
				}
			}

			// if (mouseoverPolygonBorder != null) canvas.shape(mouseoverPolygonBorder);
			// if (selectedPolygonBorder != null) canvas.shape(selectedPolygonBorder);
			canvas.popMatrix();
			super.drawSelf(canvas); //GadgetPanel
		}

		String mouse() {
			if (super.mouse() != "") {
				//windowTitle = "Figure";
				return "dragging";
			}
			XY mouseTranslated = translateMouse();
			float mouseDist, closestDist;
			closestDist = closestAnchor.distance(mouseTranslated);
			for (XY dot : allDots) {
				mouseDist = dot.distance(mouseTranslated);
				if (mouseDist <= closestDist) {
					closestAnchor = dot;
					closestDist = mouseDist;
				}
			}
			
			if (edwin.mouseBtnHeld == LEFT ) {
				if (mouseTranslated.distance(closestAnchor) < DOT_RADIUS) {
					if (edwin.isShiftDown) {
						closestAnchor.set(mouseTranslated);
						windowTitle = closestAnchor.toStringInt();
					}
					else {
						if (selectedAnchors.indexOf(closestAnchor) == -1) selectedAnchors.add(closestAnchor);
					}
				}
			}
			else if (edwin.mouseBtnReleased == LEFT) {
				if (closestAnchor.distance(mouseTranslated) < DOT_RADIUS) {
					if (selectedAnchors.indexOf(closestAnchor) == -1) {
						if (selectedAnchors.size() == 1 && selectedAnchors.get(0) != closestAnchor) { //if there's only 1 dot selected and it's not this closest one
							selectedAnchors.clear();
						}
						selectedAnchors.add(closestAnchor);
					}
					return "anchor de/selected";
				}
				else {
					for (LatticePolygon polygon : allPolygons) {
						if (polygon.containsPoint(mouseTranslated.x, mouseTranslated.y)) {
							selectedPolygon = polygon;
							selectedAnchors.clear();
							selectedAnchors.addAll(Arrays.asList(polygon.dots));
							return "polygon selected";
						}
					}
					//if we get here then the mouse click wasn't near an anchor or on a polygon so we deselect everything
					if (closestAnchor.distance(mouseTranslated) > 30) {
						selectedPolygon = null;
						selectedAnchors.clear();
					}
				}
			}
			else if (edwin.mouseBtnReleased == RIGHT) {
				//deselect dot
				if (closestAnchor.distance(mouseTranslated) < DOT_RADIUS) {
					if (selectedAnchors.indexOf(closestAnchor) != -1) selectedAnchors.remove(closestAnchor);
					if (selectedAnchors.size() == 0) selectedPolygon = null;
				}
			}
			
			return "";
		}

		String keyboard(KeyEvent event) {
			int kc = event.getKeyCode();
			if (event.getAction() == KeyEvent.PRESS && event.isShiftDown()) {
				if (kc == Keycodes.VK_UP) {
					for (XY anchor : selectedAnchors) anchor.y--;
				}
				else if (kc == Keycodes.VK_DOWN) {
					for (XY anchor : selectedAnchors) anchor.y++;
				}
				else if (kc == Keycodes.VK_LEFT) {
					for (XY anchor : selectedAnchors) anchor.x--;
				}
				else if (kc == Keycodes.VK_RIGHT) {
					for (XY anchor : selectedAnchors) anchor.x++;
				}
				else {
					return "";
				}
				//redrawSelected();
				return "dots shifted";
			}
			else if (event.getAction() == KeyEvent.RELEASE) {
				return "";
			}
			if (kc == Keycodes.VK_INSERT) {
				addDot(mouseX, mouseY);
			}
			else if (kc == Keycodes.VK_DELETE) {
				if (selectedPolygon == null) deleteDot();
				else {
					allPolygons.remove(selectedPolygon);
					selectedPolygon = null;
					selectedAnchors.clear();
				}
			}
			else if (kc == Keycodes.VK_P) {
				definePolygon();
			}
			else if (kc == Keycodes.VK_SEMICOLON) {
				splitLine();
			}
			else if (kc == Keycodes.VK_BACK_SPACE) {
				selectedAnchors.clear();
				selectedPolygon = null;
			}
			else {
				return "";
			}
			return getName();
		}

		// void redrawSelected() {
		// 	for (Polygon polygon : allPolygons) {
		// 		if (Arrays.asList(polygon.dots).contains(closestAnchor)) {
		// 			polygon.redrawFace();
		// 		}
		// 	}
		// }

		void addDot(float x, float y) {
			allDots.add(new XY((x - offset.x) / figureScale.value, (y - offset.y) / figureScale.value));
			windowTitle = "dot created:" + (allDots.size() - 1); 
		}

		void deleteDot() {
			if (allDots.size() == 1) {
				windowTitle = "can't delete only dot";
				return;
			}
			else if (selectedAnchors.size() != 1) {
				windowTitle = "select 1 dot";
				return;
			}
			int confirm = JOptionPane.showConfirmDialog(null, "Really delete dot?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
			if (confirm == JOptionPane.YES_OPTION) { 
				allDots.remove(selectedAnchors.get(0));
				selectedAnchors.clear();
				closestAnchor = allDots.get(0);
				windowTitle = "dot deleted";
				//TODO also check for connected polygons
			}
		}

		void definePolygon() {
			if (selectedAnchors.size() > 2) {
				allPolygons.add(new LatticePolygon(selectedAnchors));
				//allPolygons.add(new LatticePolygon(selectedAnchors.toArray(new XY[0])));
				selectedAnchors.clear();
				windowTitle = "polygon added";
			}
			else {
				windowTitle = "need dots > 2";
			}
			selectedPolygon = null;
		}

		void splitLine() {
			if (selectedAnchors.size() != 2) {
				windowTitle = "select 2 dots";
				return;
			}
			XY dot0 = selectedAnchors.get(0);
			XY dot1 = selectedAnchors.get(1);
			XY newDot = dot0.midpoint(dot1);
			allDots.add(newDot);
			selectedAnchors.clear();
			selectedAnchors.add(newDot);
			closestAnchor = newDot;
			//insert new dot into existing polygons that use these two dots adjacently
			for (LatticePolygon polygon : allPolygons) {
				int last = polygon.dots.length - 1;
				int insertPosition = -1;
				for (int i = 0; i < polygon.dots.length; i++) {
					if (polygon.dots[i] == dot0) {
						if (i == 0 && polygon.dots[last] == dot1) {
							insertPosition = last + 1;
							break;
						}
						else if (i == last && polygon.dots[0] == dot1) {
							insertPosition = 0;
							break;
						}
						else if (i != last && polygon.dots[i + 1] == dot1) {
							insertPosition = i + 1;
							break;
						}
						else if (i > 0 && i <= last && polygon.dots[i - 1] == dot1) {
							insertPosition = i - 1;
							break;
						}
					}
					else if (polygon.dots[i] == dot1) {
						if (i == 0 && polygon.dots[last] == dot0) {
							insertPosition = last + 1;
							break;
						}
						else if (i == last && polygon.dots[0] == dot0) {
							insertPosition = 0;
							break;
						}
						else if (i != last && polygon.dots[i + 1] == dot0) {
							insertPosition = i + 1;
							break;
						}
						else if (i > 0 && i <= last && polygon.dots[i - 1] == dot0) {
							insertPosition = i - 1;
							break;
						}
					}
				}
				//polygon dot loop finished. now we see if we need to insert newDot into the polygon
				if (insertPosition == -1) continue;
				XY[] newList = new XY[polygon.dots.length + 1];
				for (int i = 0; i < insertPosition; i++) {
					newList[i] = polygon.dots[i];
				}
				newList[insertPosition] = newDot;
				for (int i = insertPosition; i < polygon.dots.length; i++) {
					newList[i + 1] = polygon.dots[i];
				}
				polygon.dots = newList; //assign new points to polygon
			}
		}
	} //end Figure

	/**
	* Edit paths and pulses
	*/
	private class Shimmer extends DraggableWindow {
		GridButtons editButtons, borderButtons, hilightButtons;
		NestedRectBody faceSquare, borderSquare, hilightSquare;
		ArrayList<TextLabel> labels;
		XY tri0, tri1, tri2;
		int faceColor, borderColor, hilightColor;

		Shimmer() {
			super(40 + UI_PADDING * 2, 0);
			int triWidth = 90;
			tri0 = new XY(UI_PADDING + 5 + triWidth / 2, dragBar.yh() + UI_PADDING + 5); //top
			tri1 = new XY(UI_PADDING * 2 + 5 , dragBar.yh() + UI_PADDING * 3 + 78); //left
			tri2 = new XY(UI_PADDING * 2 + 5 + triWidth, dragBar.yh() + UI_PADDING * 3 + 78); //right
			triWidth = 100;

			borderSquare = new NestedRectBody(body, UI_PADDING, dragBar.yh() + triWidth + UI_PADDING, basicButtonAlbum.w, basicButtonAlbum.h);
			borderButtons = new GridButtons(body, UI_PADDING, borderSquare.yh(), 2, basicButtonAlbum, (new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS })) {
				void buttonClick(String clicked) { 
					// if (clicked == GadgetPanel.MINUS) borderThickness.decrement();
					// else borderThickness.increment();
					// windowTitle = "Border: " + borderThickness.value;
				}
			};

			hilightSquare = new NestedRectBody(body, UI_PADDING, borderButtons.body.yh(), basicButtonAlbum.w, basicButtonAlbum.h);
			hilightButtons = new GridButtons(body, UI_PADDING, hilightSquare.yh(), 2, basicButtonAlbum, new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS }) {
				void buttonClick(String clicked) { 
					// if (clicked == GadgetPanel.MINUS) hilightThickness.decrement();
					// else hilightThickness.increment();
					// windowTitle = "Hilight: " + hilightThickness.value;
				}
			};

			faceSquare = new NestedRectBody(body, UI_PADDING, hilightButtons.body.yh(), basicButtonAlbum.w, basicButtonAlbum.h);
			editButtons = new GridButtons(body, UI_PADDING, faceSquare.yh(), 1, basicButtonAlbum, (new String[] { GadgetPanel.COLOR_WHEEL, GadgetPanel.PLUS, GadgetPanel.MINUS, GadgetPanel.START_LIGHT }), (new String[] { GadgetPanel.COLOR_WHEEL, GadgetPanel.PLUS, GadgetPanel.MINUS, GadgetPanel.STOP_LIGHT })) {
				void buttonClick(String clicked) { 
					// if (clicked == GadgetPanel.COLOR_WHEEL) {
					// 	palette.toggleVisibility();
					// 	palette.body.set(mouseX, mouseY);
					// }
					// else if (clicked == GadgetPanel.PLUS) {
					// }
					// else if (clicked == GadgetPanel.MINUS) {
					// 	//delete
					// }
					// else { //if (clicked == GadgetPanel.START_LIGHT) {
					// 	//definePolygon();
					// }
				}
			};
			labels = new ArrayList<TextLabel>();
			labels.add(new TextLabel("border", borderSquare.xw(), borderSquare.y, body));
			labels.add(new TextLabel("hilight", hilightSquare.xw(), hilightSquare.y, body));
			labels.add(new TextLabel("face", faceSquare.xw(), faceSquare.y, body));
			labels.add(new TextLabel("palette", editButtons.body.xw(), editButtons.body.y, body));
			labels.add(new TextLabel("new dot", editButtons.body.xw(), editButtons.body.y + basicButtonAlbum.h * 1, body));
			labels.add(new TextLabel("delete dot", editButtons.body.xw(), editButtons.body.y + basicButtonAlbum.h * 2, body));
			labels.add(new TextLabel("polygon", editButtons.body.xw(), editButtons.body.y + basicButtonAlbum.h * 3, body));
			body.setSize(triWidth + UI_PADDING * 4, editButtons.body.yh() + UI_PADDING);
			dragBar.w = body.w - UI_PADDING * 2;
			windowTitle = "Figure";
			faceColor = 0;
			borderColor = 5;
			hilightColor = 0;
		}

		void drawSelf(PGraphics canvas) {
			if (!isVisible) return;

			//DraggableWindow stuff...
			super.drawSelf(canvas);
			canvas.pushMatrix();
			canvas.translate(body.x, body.y);
			//triangle with default colors
			// if (borderThickness.value > 0) {
			// 	canvas.strokeWeight(borderThickness.value);
			// 	canvas.stroke(palette.colors.get(borderColor));
			// }
			// else {
			// 	canvas.noStroke();
			// }
			// canvas.fill(palette.colors.get(faceColor));
			// canvas.triangle(tri0.x, tri0.y, tri1.x, tri1.y, tri2.x, tri2.y);
			// //hilight
			// if (hilightThickness.value > 0) {
			// 	canvas.strokeWeight(hilightThickness.value);
			// 	canvas.stroke(palette.colors.get(hilightColor));
			// }
			// else {
			// 	canvas.noStroke();
			// }
			canvas.noFill();
			canvas.triangle(tri0.x, tri0.y, tri1.x, tri1.y, tri2.x, tri2.y);
			//palette color squares
			canvas.noStroke();
			canvas.fill(palette.colors.get(borderColor));
			canvas.rect(borderSquare.x, borderSquare.y, borderSquare.w, borderSquare.h);
			canvas.fill(palette.colors.get(hilightColor));
			canvas.rect(hilightSquare.x, hilightSquare.y, hilightSquare.w, hilightSquare.h);
			canvas.fill(palette.colors.get(faceColor));
			canvas.rect(faceSquare.x, faceSquare.y, faceSquare.w, faceSquare.h);
			//buttons and labels
			borderButtons.drawSelf(canvas);
			hilightButtons.drawSelf(canvas);
			editButtons.drawSelf(canvas);
			for (TextLabel label : labels) {
				label.drawSelf(canvas);
			}
			canvas.popMatrix();
		}

		String mouse() {
			if (!isVisible) return "";
			if (super.mouse() != "") {
				windowTitle = "Figure";
				return "dragging";
			}
			if (edwin.mouseBtnReleased != LEFT) return "";
			if (borderButtons.mouse() != "" || hilightButtons.mouse() != "" || editButtons.mouse() != "") return "button click";
			if (palette.isVisible) {
				if (faceSquare.isMouseOver()) faceColor = palette.selectedColor.value;
				if (borderSquare.isMouseOver()) borderColor = palette.selectedColor.value;
				if (hilightSquare.isMouseOver()) hilightColor = palette.selectedColor.value;
			}
			return "";
		}

		String keyboard(KeyEvent event) {
			if (event.getAction() != KeyEvent.RELEASE) {
				return "";
			}
			int kc = event.getKeyCode();
			if (kc == Keycodes.VK_INSERT) {
			}
			else if (kc == Keycodes.VK_DELETE) {
				
			}
			else if (kc == Keycodes.VK_P) {
				//definePolygon();
			}
			else {
				return "";
			}
			return getName();
		}
	} //end Shimmer

	/**
	* Transformations
	*/
	private class Morph extends DraggableWindow {
		Morph() {
			super(40 + UI_PADDING * 2, 0);
			body.setSize(100, 100);
			dragBar.w = body.w - UI_PADDING * 2;
			windowTitle = "Morph";
			//...
		}

		void drawSelf(PGraphics canvas) {
			if (!isVisible) return;
			super.drawSelf(canvas);
			canvas.pushMatrix();
			canvas.translate(body.x, body.y);
			//...
			canvas.popMatrix();
		}

		String mouse() {
			if (!isVisible) return "";
			if (super.mouse() != "") return "dragging";
			//...
			return "";
		}
	} //end Morph

} //end LightLattice





















































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
					gPanel.windowTitle = "setting v symmetry: " + setVertSym;
					gPanel.getButtons(VERTICAL_SYM).toggleImage(0);
				}
				else { //if (arg == GadgetPanel.BLANK || arg == GadgetPanel.BIGX) {
					useVertSym = !useVertSym;
					gPanel.windowTitle = "using v symmetry: " +  useVertSym;
					gPanel.getButtons(VERTICAL_SYM).toggleImage(1);
				}
			}
		});

		gPanel.addItem(HORIZONTAL_SYM, new String[] { GadgetPanel.OVER_UNDER, GadgetPanel.BLANK }, new String[] { GadgetPanel.OVER_UNDER_DOWN, GadgetPanel.BIGX }, new Command() {
			void execute(String arg) {
				if (arg == GadgetPanel.OVER_UNDER || arg == GadgetPanel.OVER_UNDER_DOWN) {
					setHorzSym = !setHorzSym;
					gPanel.windowTitle = "setting h symmetry: " + setHorzSym;
					gPanel.getButtons(HORIZONTAL_SYM).toggleImage(0);
				}
				else { //if (arg == GadgetPanel.BLANK || arg == GadgetPanel.BIGX) {
					useHorzSym = !useHorzSym;
					gPanel.windowTitle = "using h symmetry: " +  useHorzSym;
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
						gPanel.windowTitle = "can't delete only dot";
						return;
					}
					int confirm = JOptionPane.showConfirmDialog(null, "Really delete dot?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
					if (confirm == JOptionPane.YES_OPTION) { 
						allDots.remove(selectedAnchor);
						selectedAnchor = allDots.get(0);
						gPanel.windowTitle = "dot deleted";
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
						gPanel.windowTitle = newName + " animation created";
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
				gPanel.windowTitle = "animation: \"" + selectedAnimation.name + "\"";
			}
		});

		gPanel.addItem("frame prev|next|new", new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E, GadgetPanel.PLUS }, new Command() {
			void execute(String arg) {
				playAnimation = false;
				if (arg == GadgetPanel.ARROW_W) {
					selectedAnimation.currentFrame.decrement();
					selectedAnimation.drawFrame();
					gPanel.windowTitle = "frame " + selectedAnimation.currentFrame.value + "/" + selectedAnimation.currentFrame.maximum;
				}
				else if (arg == GadgetPanel.ARROW_E) {
					selectedAnimation.currentFrame.increment();
					selectedAnimation.drawFrame();
					gPanel.windowTitle = "frame " + selectedAnimation.currentFrame.value + "/" + selectedAnimation.currentFrame.maximum;
				}
				else { //if (arg == GadgetPanel.PLUS) {
					selectedAnimation.addDuplicateFrame();
					gPanel.windowTitle = "frame " + selectedAnimation.currentFrame.value + " added";
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
		gPanel.windowTitle = "dot created:" + (allDots.size() - 1); 
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
				gPanel.windowTitle = "x:" + (int)symmetryAnchor.x +  "|y:" + (int)symmetryAnchor.y;
			}
			else if (!modeDefineFace && selectedAnchor.distance(mouseWOffset) < anchorDiameter && gPanel.isVisible) { //move anchor
				selectedAnchor.set(mouseWOffset);
				for (Polygon polygon : allPolygons) {
					if (Arrays.asList(polygon.dots).contains(selectedAnchor)) {
						polygon.redrawFace();
					}
				}
				//setGPLabel();
				gPanel.windowTitle = "x:" + (int)selectedAnchor.x +  "|y:" + (int)selectedAnchor.y;
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
			gPanel.windowTitle = "offset x:" + (int)originOffset.x +  "|y:" + (int)originOffset.y;
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

	//void setGPLabel() { gPanel.windowTitle = "x:" + (int)selectedAnchor.x +  "|y:" + (int)selectedAnchor.y; }

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
		if (modeDefineFace) gPanel.windowTitle = "face started";
		else {
			if (buildingPolygon.size() < 3) {
				gPanel.windowTitle = "need dots > 2";
			}
			else {
				allPolygons.add(new Polygon(buildingPolygon.toArray(new XY[0])));
				gPanel.windowTitle = "new face added";
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

	

	/** Series of color changes for the polygons on the wireframe */
	private class AnimationFrames {
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

	/** Face on the wireframe */
	private class Polygon {
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
} //end PolywireOld

