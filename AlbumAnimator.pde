/** */
class AlbumAnimator implements Kid {
    Album album;
    BoundedInt frame, delay;
    XY offset;
    final String prefix = "torch";

    AlbumAnimator() { this(2.0); }
    AlbumAnimator(float scale) {
        album = new Album("tiles/torch.alb", scale);
        offset = new XY();
        frame = new BoundedInt(0, 5);
        frame.loops = true;
        delay = new BoundedInt(0, 3);
        delay.loops = true;
    }

    void draw(PGraphics canvas) {
        if (delay.increment() == delay.maximum) frame.increment();
        canvas.image(album.page(prefix + frame.value), offset.x, offset.y);
    }

    String mouse() {
        return "";
    }

    String keyboard(KeyEvent event) {
        int kc = event.getKeyCode();
        if (kc == Keycodes.SPACE) {
            offset.set(mouseX, mouseY);
        }
        else if (event.getAction() != KeyEvent.RELEASE) {
            return "";
        }
        else if (kc == Keycodes.S) {
            offset.x += 1;
        }
        else if (kc == Keycodes.X) {
            offset.x += album.w;
        }
        else if (kc == Keycodes.A) {
            offset.y += 1;
        }
        else if (kc == Keycodes.Z) {
            offset.y += album.h;
        }
        else if (kc == Keycodes.R) {
            album.reload();
        }
        return "";
    }
}
