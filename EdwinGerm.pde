Edwin edwin;

void setup() {
    //fullScreen();
    // size(1900, 1100);
    size(800, 800);
    edwin = new Edwin();
    
    // edwin.addKid(new StarBackdrop());
    edwin.addKid(new PixelStarBackdrop(200));
    edwin.addKid(new Ricochet());
    
    // edwin.addKid(new PalettePicker(EdColors.dxPalette(), "Set window color") {
    //     public void colorSelected(int paletteIndex) { 
    //         edwin.bgdColor = this.colors.get(paletteIndex);
    //     }
    // });
    
    // edwin.addKid(new MinesweeperGame());
    // edwin.addKid(new ReferenceImagePositioner());
    // edwin.addKid(new StarWebPositioner());
    // edwin.addKid(new LaserboltPositioner()); 
    // edwin.addKid(new LightLattice());
    // edwin.addKid(new AlbumAnimator());

    // edwin.addKid(new PixelGlitcher(new LightLattice()));
    // edwin.addKid(new PixelGlitcher(new StarWebPositioner()));

    edwin.addKid(new AlbumEditor(false)); //hit E to toggle visibility (after clicking into the window)
}

void draw() {
    edwin.think();
    image(edwin.canvas, 0, 0);
}
