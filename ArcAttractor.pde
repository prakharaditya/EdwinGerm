/**
* Lines that flow to a center point jumping distances and arcs
* Segments and Arcs
* incomplete!
*/
class ArcAttractor implements Kid {
	XY origin;
	ArrayList<BeamSegment> beams;
	BoundedInt arcPossible;
	BoundedFloat arcLenPossible, segLenPossible;
	int[] colors, strokeWeights;

	ArcAttractor() { this(width / 2.0, height / 2.0); }
	ArcAttractor(XY center) { this(center.x, center.y); }
	ArcAttractor(float x, float y) {
		origin = new XY(x, y);
		arcPossible = new BoundedInt(40, 200);
		// colors = new int[] { EdColors.DX_DARK_BLUE, EdColors.DX_BROWN, EdColors.DX_SKY_BLUE };
		// strokeWeights = new int[] { 12, 9, 3 };
		colors = new int[] { EdColors.DX_SKY_BLUE };
		strokeWeights = new int[] { 3 };
		beams = new ArrayList<BeamSegment>();
		for (int i = 0; i < 200; i++) {
			beams.add(new BeamSegment());
		}
	}

	void draw(PGraphics canvas) {
		canvas.noFill();
		canvas.strokeCap(PROJECT);
		for (BeamSegment beam : beams) {
			beam.draw(canvas);
		}
		canvas.fill(255);
		canvas.ellipse(origin.x, origin.y, 20, 20);
	}

	String mouse() {
		if (edwin.mouseBtnHeld == CENTER) {
			origin.set(mouseX, mouseY);
		}
		return "";
	}

	String keyboard(KeyEvent event) {
		return "";
	}

	private class Beam {
		ArrayList<BeamSegment> segments;
		float totalBeamLength, speed;

		Beam() {
			segments = new ArrayList<BeamSegment>();

		}
	}

	private class BeamSegment {
		XY back, attractor;
		XY start, end, arcStart, arcEnd;
		float radiusFromOrigin, lastAlleyAngle;
		BoundedFloat alleyAngle;
		boolean onArc, left;

		float angleFromAttractor, radiusFromAttractor;
		float lineLength, arcLength;

		BeamSegment() {
			//arcLength = arcPossible.randomize();
			//lineLength = random(50, 250);
			back = new XY(random(width), random(height));
			//attractor = origin.clone();
			onArc = false;
			alleyAngle = new BoundedFloat(0);
			alleyAngle.step = PI / 100.0;
			reset(false);
		}

		void update() {
			if (onArc) {
				//lastAlleyAngle = alleyAngle.value;
				alleyAngle.increment();
				if (alleyAngle.atMax()) {
					onArc = false;
					float last = back.angle(origin) + (alleyAngle.value + PI) * (left ? -1 : 1);
					back.set(
						origin.x + cos(last) * radiusFromOrigin,
						origin.y + sin(last) * radiusFromOrigin);
					reset(false);
				}
			}
			else {
				//back.moveTowards(origin, random(8, 24));
				back.moveTowards(origin, 3);
				if (back.distance(origin) <= 5) {
					reset(true);
				}
				if (back.distance(origin) <= radiusFromOrigin) {
					onArc = true;
					left = (random(1) > 0.5);
					//left = !left;
					alleyAngle.reset(0, random(PI / 12.0, PI / 4.0));
					lastAlleyAngle = 0;
				}
			}
		}

		void reset(boolean newPos) {
			if (newPos) {
				float r = random(1);
				if (r > 0.75) back.set(random(width), -10);
				else if (r > 0.5) back.set(random(width), height + 10);
				else if (r > 0.25) back.set(-10, random(height));
				else back.set(width + 10, random(height));
			}
			radiusFromOrigin = back.distance(origin) - random(30, 120);
		}

		void draw(PGraphics canvas) {
			update();
			for (int i = 0; i < colors.length; i++) {
				canvas.strokeWeight(strokeWeights[i]);
				canvas.stroke(colors[i]);
				canvas.point(back.x, back.y);
				if (onArc) {
					if (left) {
						canvas.arc(
							origin.x, 
							origin.y, 
							radiusFromOrigin * 2, 
							radiusFromOrigin * 2, 
							back.angle(origin) - alleyAngle.value - PI,
							back.angle(origin) - PI);
					}
					else {
						canvas.arc(
							origin.x, 
							origin.y, 
							radiusFromOrigin * 2, 
							radiusFromOrigin * 2, 
							back.angle(origin) + PI, 
							back.angle(origin) + alleyAngle.value + PI);
					}
				}
			} //for i
		}

	}


}
