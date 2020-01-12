/**
*
*/
class PortalPiece implements Kid {
	Ball[] balls;
	XY[] borderPoints0, borderPoints1, portals0, portals1;
	XY center0, center1;
	float angleOffset, angleIncrement, angleSegment;
	int colr0, colr1;
	final float HEX_RADIUS = 200,
	HEX_RADIUS_SHORT = 180, //for portal placement
	PORTAL_SIZE = 25,
	BALL_SIZE = 10,
	MAX_SPEED = 5.0, 
	ACCEL = 0.15;

	PortalPiece() {
		colr0 = #6E3232;
		colr1 = #046894;
		center0 = new XY(HEX_RADIUS + 20, HEX_RADIUS + 20);
		center1 = new XY(HEX_RADIUS * 3, HEX_RADIUS + 20);
		borderPoints0 = new XY[6];
		borderPoints1 = new XY[6];
		portals0 = new XY[6];
		portals1 = new XY[6];
		angleOffset = 0;
		angleSegment = TWO_PI / 6.0;
		angleIncrement = TWO_PI / 5000.0;
		//angleIncrement = 0;
		//border
		float angle0 = 0, angle1 = -HALF_PI;
		for (int i = 0; i < 6; i++) {
			borderPoints0[i] = new XY(center0.x + cos(angle0) * HEX_RADIUS, center0.y + sin(angle0) * HEX_RADIUS);
			borderPoints1[i] = new XY(center1.x + cos(angle1) * HEX_RADIUS, center1.y + sin(angle1) * HEX_RADIUS);
			portals0[i] = new XY(center0.x + cos(angle0) * HEX_RADIUS_SHORT, center0.y + sin(angle0) * HEX_RADIUS_SHORT);
			portals1[i] = new XY(center1.x + cos(angle1) * HEX_RADIUS_SHORT, center1.y + sin(angle1) * HEX_RADIUS_SHORT);
			angle0 += angleSegment;
			angle1 += angleSegment;
		}
		//ball placement
		balls = new Ball[6];
		angle0 = HALF_PI;
		angle1 = -HALF_PI;
		float triSegment = TWO_PI / 3.0;
		for (int i = 0; i < 3; i++) {
			balls[i] = new Ball(center0.x + cos(angle0) * 50, center0.y + sin(angle0) * 50, 0);
			balls[i + 3] = new Ball(center1.x + cos(angle1) * 50, center1.y + sin(angle1) * 50, 1);
			angle0 += triSegment;
			angle1 += triSegment;
		}
	}

	void drawSelf(PGraphics canvas) {
		update();
		canvas.stroke(#87715B);
		canvas.stroke(#201708);
		canvas.strokeWeight(3);
		int previous = 5;
		//borders
		for (int i = 0; i < 6; i++) {
			canvas.line(borderPoints0[i].x, borderPoints0[i].y, borderPoints0[previous].x, borderPoints0[previous].y);
			canvas.line(borderPoints1[i].x, borderPoints1[i].y, borderPoints1[previous].x, borderPoints1[previous].y);
			previous = i;
		}
		canvas.noStroke();
		//portals
		for (int i = 0; i < 6; i++) {
			if (i % 2 == 0) canvas.fill(colr0);
			else canvas.fill(colr1);
			canvas.ellipse(portals0[i].x, portals0[i].y, PORTAL_SIZE, PORTAL_SIZE);
			canvas.ellipse(portals1[i].x, portals1[i].y, PORTAL_SIZE, PORTAL_SIZE);
		}
		//balls
		for (Ball ball : balls) {
			if (ball.portal == 0) canvas.fill(colr0);
			else canvas.fill(colr1);
			canvas.ellipse(ball.x, ball.y, BALL_SIZE, BALL_SIZE);
		}
		//center points
		canvas.fill(colr0);
		canvas.ellipse(center0.x, center0.y, PORTAL_SIZE, PORTAL_SIZE);
		canvas.fill(colr1);
		canvas.ellipse(center1.x, center1.y, PORTAL_SIZE, PORTAL_SIZE);
	}

	void update() {
		//rotate border
		float angle0 = angleOffset, angle1 = -angleOffset - HALF_PI;
		for (int i = 0; i < 6; i++) {
			borderPoints0[i].set(center0.x + cos(angle0) * HEX_RADIUS, center0.y + sin(angle0) * HEX_RADIUS);
			borderPoints1[i].set(center1.x + cos(angle1) * HEX_RADIUS, center1.y + sin(angle1) * HEX_RADIUS);
			portals0[i].set(center0.x + cos(angle0) * HEX_RADIUS_SHORT, center0.y + sin(angle0) * HEX_RADIUS_SHORT);
			portals1[i].set(center1.x + cos(angle1) * HEX_RADIUS_SHORT, center1.y + sin(angle1) * HEX_RADIUS_SHORT);
			angle0 += angleSegment;
			angle1 += angleSegment;
		}
		angleOffset += angleIncrement;
		if (angleOffset > TWO_PI) angleOffset -= TWO_PI;

		//move balls
		for (Ball ball : balls) {
			if (ball.speed < MAX_SPEED) ball.speed += ACCEL;
			ball.move();
			//check for collisions with border
			int previous = 5;
			boolean collides = false;
			for (int i = 0; i < 6; i++) {
				if (ball.portal == 0 && hitsBorder(borderPoints0[i], borderPoints0[previous], ball)) {
					collides = true;
					break;
				}
				else if (ball.portal == 1 && hitsBorder(borderPoints1[i], borderPoints1[previous], ball)) {
					collides = true;
					break;
				}
				previous = i;
			}
			if (collides) {
				ball.direction += PI + random(QUARTER_PI);
				if (ball.direction > TWO_PI) ball.direction -= TWO_PI;
				ball.move(5);
			}
		}

		//collide and bounce
	}

	boolean hitsBorder(XY pt0, XY pt1, Ball ball) {
		// https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
		float numerator = (pt1.y - pt0.y) * ball.x - (pt1.x - pt0.x) * ball.y + (pt1.x * pt0.y) - (pt1.y * pt0.x);
		return abs(numerator) / pt0.distance(pt1) <= BALL_SIZE / 2;
	}

	String mouse() {
		return "";
	}

	String keyboard(KeyEvent event) {
		return "";
	}

	private class Ball extends XY {
		float speed, direction;
		int portal;

		Ball(float _x, float _y, int port) {
			set(_x, _y);
			portal = port;
			speed = 0.2;
			direction = HALF_PI;
			if (portal == 1) direction *= -1; //gravity in the right portal goes up rather than down
		}

		void move() { move(speed); }
		void move(float s) {
			set(x + cos(direction) * s, y + sin(direction) * s); //move ball towards "direction" at "speed"
		}
	}

}
