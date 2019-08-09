Edwin edwin;

void setup() {
	size(900, 900);
	edwin = new Edwin();
	edwin.addKid(new StarBackdrop());
	//edwin.addKid(new ReferenceImagePositioner());
	edwin.addKid(new PolycolorWireframe("_lowpoly_mushroom.dots"));
	edwin.addKid(new LaserboltPositioner("_mush.lzr")); 
	//edwin.addKid(new EditorWindow()); //UI is a little tricky atm, opens and saves .alb files
	//edwin.addKid(new MinesweeperGame());
}

void draw() {
	edwin.update();
	image(edwin.canvas, 0, 0);
}

