/** 
* This lets you make a grid of polygons (usually quads) that are ordered 
* and know their relationship to others around it so that it can be animated.
*/
public class LightLattice implements Kid {
	ArrayList<LatticeLine> lattice, activeLines;
	LatticeLine root, tip; //linked list
	PalettePicker palette;
	PGraphics wireframe;
	XY[] basePoints;
	XY offset;
	BoundedInt frameWidth;
	int quadsPerLine, standardLength;
	boolean useWireframe;

	LightLattice() { this(8); }
	LightLattice(int cellsPerLine) { this(cellsPerLine, new int[] { #05162B, #134372, #3176BC, #9AC5EA, #DCE6ED }); }
	LightLattice(int cellsPerLine, int[] paletteColors) {
		quadsPerLine = cellsPerLine;
		palette = new PalettePicker(paletteColors);
		//lattice = new ArrayList<LatticeLine>();
		basePoints = new XY[quadsPerLine + 1];
		XY[] linePoints = new XY[basePoints.length];
		XY anchor = new XY(50, 50);
		offset = new XY(0, 0);
		frameWidth = new BoundedInt(1, 10);
		standardLength = 40;
		for (int i = 0; i < basePoints.length; i++) {
			basePoints[i] = new XY(anchor.x, anchor.y);
			linePoints[i] = new XY(anchor.x, anchor.y + standardLength);
			anchor.x += standardLength;
		}
		LatticeLine currentLine, prevLine;
		root = new LatticeLine(linePoints, null);
		prevLine = root;
		for (int a = 0; a < 10; a++) {
			linePoints = new XY[basePoints.length];
			anchor = prevLine.points[0].clone();
			for (int i = 0; i < basePoints.length; i++) {
				linePoints[i] = new XY(anchor.x, anchor.y + standardLength);
				anchor.x += standardLength;
			}
			currentLine = new LatticeLine(linePoints, prevLine);
			//prevLine.next = currentLine;
			//lattice.add(currentLine);
			prevLine = currentLine;
			tip = currentLine;
		}
		wireframe = createGraphics(width, height);
		useWireframe = true;
		redrawSkeleton();
	}

	void redrawSkeleton() {
		LatticeLine currentLine = root;
		wireframe.beginDraw();
		wireframe.clear();
		while (currentLine != null) {
			drawLine(wireframe, currentLine, true);
			currentLine = currentLine.next;
		}
		wireframe.endDraw();
	}

	void drawLine(PGraphics canvas, LatticeLine line, boolean stroked) {
		XY[] prevPoints;
		if (line.prev == null) prevPoints = basePoints;
		else prevPoints = line.prev.points;
		for (int i = 0; i < quadsPerLine; i++) {
			canvas.beginShape();
			if (stroked) {
				canvas.stroke(palette.colors.get(0));
				canvas.strokeWeight(frameWidth.value);
				canvas.noFill();
			}
			else {
				canvas.noStroke();
				canvas.fill(palette.colors.get(line.paletteColors[i]));
				// if (random(450) > 420) canvas.fill(0,0);
				// else canvas.fill(palette.colors.get(line.paletteColors[i]));
			}
			canvas.vertex(prevPoints[i].x, prevPoints[i].y);
			canvas.vertex(prevPoints[i + 1].x, prevPoints[i + 1].y);
			canvas.vertex(line.points[i + 1].x, line.points[i + 1].y);
			canvas.vertex(line.points[i].x, line.points[i].y);
			canvas.endShape(CLOSE);
		}
	}

	void drawSelf(PGraphics canvas) {
		LatticeLine currentLine = root;
		while (currentLine != null) {
			drawLine(canvas, currentLine, false);
			currentLine = currentLine.next;
		} 
		// if (edwin.mouseBtnHeld == LEFT) {
		// 	canvas.fill(255);
		// 	canvas.noStroke();
		// 	canvas.ellipse(mouseX, mouseY, 40, 40);
		// }
		if (useWireframe) canvas.image(wireframe, offset.x, offset.y);
	}

	String mouse() {
		// if (edwin.mouseBtnReleased == LEFT) {
		// 	println(new XY(mouseX, mouseY).toString());
		// }
		return "";
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() != KeyEvent.RELEASE) {
			return "";
		}
		int kc = event.getKeyCode();
		if (kc == Keycodes.VK_Q) {
			frameWidth.decrement();
			redrawSkeleton();
		}
		else if (kc == Keycodes.VK_W) {
			frameWidth.increment();
			redrawSkeleton();
		}
		return "";
	}

	String getName() {
		return "LightLattice";
	}

	class LatticeLine {
		int[] defaultColors, paletteColors;
		XY[] points; //length is one more than int[]s above
		LatticeLine prev, next;
		LatticeLine(XY[] anchors, LatticeLine previous) { this(anchors, previous, null); }
		LatticeLine(XY[] anchors, LatticeLine previous, int[] latticeColors) {
			points = anchors;
			prev = previous;
			if (prev != null) prev.next = this;
			next = null;
			if (latticeColors == null || latticeColors.length != quadsPerLine) {
				defaultColors = new int[quadsPerLine];
				for (int i = 0; i < quadsPerLine; i++) defaultColors[i] = 2;
			}
			else {
				defaultColors = latticeColors;
			}
			paletteColors = new int[quadsPerLine];
			toDefaults();
		}

		void toDefaults() {
			for (int i = 0; i < defaultColors.length; i++) {
				paletteColors[i] = defaultColors[i];
			}
		}

		boolean containsPoint(XY[] dots, float x, float y) {
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

} //end LightLattice

public static enum FadeIn {
	ASSIGN, LIST, RISE;
}

public static enum FadeOut {
	ASSIGN, LIST, DECAY;
}