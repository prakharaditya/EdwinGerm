Edwin edwin;

void setup() {
	//fullScreen();
	size(1500, 1000);
	edwin = new Edwin();
	//edwin.useSmooth = false;
	//edwin.addKid(new MinesweeperGame());

	//edwin.addKid(new StarBackdrop());
	//edwin.addKid(new PixelStarBackdrop(500, 2.0));

	edwin.addKid(new LightLattice());
	//edwin.addKid(new LaserboltPositioner("_mush.lzr")); 
	//edwin.addKid(new PolywireOld("_lowpoly_mushroom.dots"));

	//edwin.addKid(new PixelGlitcher(new LaserboltPositioner("_mush.lzr")));
	//edwin.addKid(new PixelGlitcher(new Polywire("_lowpoly_mushroom.dots")));

	//edwin.addKid(new AlbumAnimator(2));
	edwin.addKid(new AlbumEditor(false));
}

void draw() {
	edwin.think();
	image(edwin.canvas, 0, 0);
}
