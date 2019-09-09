Edwin edwin;

void setup() {
	size(1500, 1000);
	edwin = new Edwin();
	//edwin.useSmooth = false;
	//edwin.addKid(new StarBackdrop());
	edwin.addKid(new PixelStarBackdrop(500, 1.0));
	edwin.addKid(new Polywire());
	//edwin.addKid(new LaserboltPositioner("_mush.lzr")); 
	//edwin.addKid(new Polywire("_lowpoly_mushroom.dots"));
	
	//edwin.addKid(new PixelGlitcher(new LaserboltPositioner("_mush.lzr")));
	//edwin.addKid(new PixelGlitcher(new Polywire("_lowpoly_mushroom.dots")));

	//edwin.addKid(new AlbumAnimator(2));
	edwin.addKid(new EditorWindow());

	//edwin.addKid(new MinesweeperGame());
}

void draw() {
	edwin.think();
	image(edwin.canvas, 0, 0);
}
