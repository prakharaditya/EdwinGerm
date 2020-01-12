Edwin edwin;

void setup() {
	//fullScreen();
	size(800, 1100);
	edwin = new Edwin(#FFFFFF);
	//edwin.useSmooth = false;
	//edwin.addKid(new MinesweeperGame());
	
	//edwin.addKid(new PortalPiece());
	edwin.addKid(new ReferenceImagePositioner("starwebs\\statue2.png"));
	edwin.addKid(new StarWebPositioner());

	//edwin.addKid(new StarBackdrop());
	//edwin.addKid(new PixelStarBackdrop(500, 2.0));

	//edwin.addKid(new LightLattice());
	//edwin.addKid(new LaserboltPositioner("_mush.lzr")); 
	edwin.addKid(new LaserboltPositioner()); 
	//edwin.addKid(new PolywireOld("_lowpoly_mushroom.dots"));

	//edwin.addKid(new PixelGlitcher(new LaserboltPositioner("_mush.lzr")));
	//edwin.addKid(new PixelGlitcher(new PolywireOld("_lowpoly_mushroom.dots")));

	//edwin.addKid(new AlbumAnimator(2));

	edwin.addKid(new AlbumEditor(false));
}

void draw() {
	edwin.think();
	image(edwin.canvas, 0, 0);
}
