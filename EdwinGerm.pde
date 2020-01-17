Edwin edwin;

void setup() {
	//fullScreen();
	size(1200, 1000);
	edwin = new Edwin();
	//edwin.useSmooth = false;
	//edwin.addKid(new StarBackdrop());
	edwin.addKid(new PixelStarBackdrop(500));
	//edwin.addKid(new MinesweeperGame());
	
	//edwin.addKid(new PortalPiece());
	//edwin.addKid(new ReferenceImagePositioner("starwebs\\statue2.png"));
	//edwin.addKid(new StarWebPositioner());


	edwin.addKid(new PixelGlitcher(new LightLattice()));
	//edwin.addKid(new LaserboltPositioner("_mush.lzr")); 
	//edwin.addKid(new LaserboltPositioner()); 

	//edwin.addKid(new PixelGlitcher(new LaserboltPositioner("_mush.lzr", true)));
	edwin.addKid(new PixelGlitcher(new StarWebPositioner()));

	//edwin.addKid(new AlbumAnimator(2));

	edwin.addKid(new AlbumEditor(false));
}

void draw() {
	edwin.think();
	image(edwin.canvas, 0, 0);
}
