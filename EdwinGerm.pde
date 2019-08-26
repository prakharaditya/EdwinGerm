Edwin edwin;

void setup() {
	size(1500, 1000);
	//size(1000, 500);
	edwin = new Edwin();
	edwin.addKid(new StarBackdrop());
	edwin.addKid(new ReferenceImagePositioner());
	//edwin.addKid(new ReferenceImagePositioner("serpent.png"));
	//edwin.addKid(new LightLattice());

	edwin.addKid(new LaserboltPositioner("_mush.lzr")); 
	edwin.addKid(new PolycolorWireframe());
	//edwin.addKid(new PolycolorWireframe("_lowpoly_mushroom.dots"));
	//edwin.addKid(new PixelGlitcher(new LaserboltPositioner("_mush.lzr")));
	//edwin.addKid(new PixelGlitcher(new PolycolorWireframe("_lowpoly_mushroom.dots")));

	edwin.addKid(new EditorWindow()); //UI is a little tricky atm, opens and saves .alb files
	//edwin.addKid(new MinesweeperGame());
}

void draw() {
	edwin.think();
	image(edwin.canvas, 0, 0);
}
