/** */
class AlbumAnimator implements Kid {
	Album album;
	BoundedInt frame, delay;
	XY offset;
	final String prefix = "torch";

	AlbumAnimator() { this(2.0); }
	AlbumAnimator(float scale) {
		album = new Album("tiles\\platformer_flame.alb", scale);
		offset = new XY();
		frame = new BoundedInt(0, 5);
		frame.loops = true;
		delay = new BoundedInt(0, 3);
		delay.loops = true;
	}

	void drawSelf(PGraphics canvas) {
		if (delay.increment() == delay.maximum) frame.increment();
		canvas.image(album.page(prefix + frame.value), offset.x, offset.y);
	}

	String mouse() {
		if (edwin.mouseBtnHeld == CENTER) {
			offset.set(mouseX, mouseY);
		}
		return "";
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() != KeyEvent.RELEASE) {
			return "";
		}
		int kc = event.getKeyCode();
		if (kc == Keycodes.VK_S) {
			offset.x += 1;
		}
		else if (kc == Keycodes.VK_X) {
			offset.x += album.scale;
		}
		else if (kc == Keycodes.VK_A) {
			offset.y += 1;
		}
		else if (kc == Keycodes.VK_Z) {
			offset.y += album.scale;
		}
		return "";
	}

	String getName() {
		return "Simple";
	}
}
