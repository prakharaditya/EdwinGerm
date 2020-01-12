/**
* Decorator class for applying a filter to a Kid
*/
class PixelGlitcher implements Kid {
	PGraphics canvas;
	Kid child;

	PixelGlitcher(Kid kid) {
		child = kid;
		canvas = createGraphics(width, height);
	}

	void drawSelf(PGraphics edCanvas) {
		canvas.beginDraw();
		canvas.clear();
		child.drawSelf(canvas);
		canvas.loadPixels();
		boolean offset = false;
		for (int i = 0; i < canvas.pixels.length; i++) {
			if (canvas.pixels[i] == 0) continue;
			//if (i % width == 0) offset = !offset;
			if (i % 5 == 0) offset = !offset;
			if (offset) canvas.pixels[i] = color(canvas.pixels[i], 50);
		}
		// int i;
		// for (int y = 0; y < height; y++) {
		// 	//if (y % 2 == 0) offset = !offset;
		// 	offset = !offset;
		// 	for (int x = 0; x < width; x++) {
		// 		if (x % 5 == 0) offset = !offset;
		// 		i = y * width + x + (offset ? -1 : 1);
		// 		if (i < 0) i++;
		// 		if (i == width * height) i--;
		// 		if (offset) canvas.pixels[i] = color(canvas.pixels[i], 50);
		// 	}
		// }
		canvas.updatePixels();
		canvas.endDraw();
		edCanvas.image(canvas, 0, 0);
	}

	String mouse() {
		return child.mouse();
	}

	String keyboard(KeyEvent event) {
		return child.keyboard(event);
	}
}
