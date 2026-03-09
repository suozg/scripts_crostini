import gi
import subprocess
import os
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk

def get_color():
    # Чекаємо фізичного кліку мишкою (використовуємо xdotool)
    subprocess.run(["xdotool", "selectwindow"], stdout=subprocess.DEVNULL)
    
    # Отримуємо координати після кліку
    display = Gdk.Display.get_default()
    seat = display.get_default_seat()
    pointer = seat.get_pointer()
    screen, x, y = pointer.get_position()
    
    # Захоплюємо піксель
    root_window = Gdk.get_default_root_window()
    pixbuf = Gdk.pixbuf_get_from_window(root_window, x, y, 1, 1)
    
    if pixbuf:
        pixels = pixbuf.get_pixels()
        r, g, b = pixels[0], pixels[1], pixels[2]
        color = f"#{r:02x}{g:02x}{b:02x}".upper()
        
        # Копіюємо в буфер обміну (потрібен xclip)
        os.system(f"echo -n {color} | xclip -selection clipboard")
        return color
    return None

if __name__ == "__main__":
    color = get_color()
    if color:
        print(color)
