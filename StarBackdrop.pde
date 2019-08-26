/** 
* Random stars that fill the screen
* While running hit S to generate new stars
*/
class StarBackdrop implements Kid {
	PGraphics backdrop;
	int[] palette = new int[] { #D1CAA1, #66717E, #383B53, #32213A, #110514 }; 
	int starCount;
	//XY[] stars;
	//BoundedInt timer, fadingStar;

	StarBackdrop() { this(250); }
	StarBackdrop(int numStars) {
		backdrop = createGraphics(width, height);
		newStarCount(numStars);
		//random star blinking (only works when we draw every frame rather than drawing to a PGraphics)
		// timer = new BoundedInt(50);
		// fadingStar = new BoundedInt(stars.length - 1);
		// fadingStar.loops = true;
	}

	void newStarCount(int numStars) {
		starCount = numStars;
		XY[] stars = new XY[starCount];
		for (int i = 0; i < stars.length; i++) {
			stars[i] = new XY(random(width), random(height));
		}
		//draw each star
		float tip = 6;
		float mid = tip / 3;
		backdrop.beginDraw();
		backdrop.clear();
		for (int i = 0; i < stars.length; i++) {
			backdrop.stroke(palette[i % palette.length]);
			if (i % 3 == 0) { //cross
				backdrop.line(stars[i].x - mid, stars[i].y, stars[i].x + mid, stars[i].y);
				backdrop.line(stars[i].x, stars[i].y - mid, stars[i].x, stars[i].y + mid);
			}
			else if (i % 8 == 0) { //diamond
				backdrop.fill(palette[i % palette.length]);
				backdrop.noStroke();
				backdrop.beginShape();
				backdrop.vertex(stars[i].x, stars[i].y - tip); 
				backdrop.vertex(stars[i].x + mid, stars[i].y - mid);
				backdrop.vertex(stars[i].x + tip, stars[i].y);
				backdrop.vertex(stars[i].x + mid, stars[i].y + mid);
				backdrop.vertex(stars[i].x, stars[i].y + tip);
				backdrop.vertex(stars[i].x - mid, stars[i].y + mid);
				backdrop.vertex(stars[i].x - tip, stars[i].y);
				backdrop.vertex(stars[i].x - mid, stars[i].y - mid);
				backdrop.endShape(CLOSE);
			}
			else { //single dot
				backdrop.point(stars[i].x, stars[i].y);
			}
		}
		backdrop.endDraw();
	}

	void drawSelf(PGraphics canvas) {
		canvas.image(backdrop, 0, 0);

		/*
		//random star blinking (only works when we draw every frame rather than drawing to a PGraphics)
		timer.increment();
		if (timer.atMax()) {
			timer.randomize();
			stars[fadingStar.increment()].set(random(width), random(height));
		}

		//draw each star
		float tip = 6;
		float mid = tip / 3;
		for (int i = 0; i < stars.length; i++) {
			stroke(palette[i % palette.length]);
			if (i % 3 == 0) { //cross
				line(stars[i].x - mid, stars[i].y, stars[i].x + mid, stars[i].y);
				line(stars[i].x, stars[i].y - mid, stars[i].x, stars[i].y + mid);
			}
			else if (i % 8 == 0) { //diamond
				fill(palette[i % palette.length]);
				noStroke();
				beginShape();
				vertex(stars[i].x, stars[i].y - tip); 
				vertex(stars[i].x + mid, stars[i].y - mid);
				vertex(stars[i].x + tip, stars[i].y);
				vertex(stars[i].x + mid, stars[i].y + mid);
				vertex(stars[i].x, stars[i].y + tip);
				vertex(stars[i].x - mid, stars[i].y + mid);
				vertex(stars[i].x - tip, stars[i].y);
				vertex(stars[i].x - mid, stars[i].y - mid);
				endShape(CLOSE);
			}
			else { //single dot
				point(stars[i].x, stars[i].y);
			}
		}
		*/
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() == KeyEvent.RELEASE && event.getKeyCode() == Keycodes.VK_S) { 
			newStarCount(starCount); //redraw
			return getName();
		}
		return "";
	}

	String mouse() {
		return "";
	}

	String getName() {
		return "StarBackdrop";
	}
}
