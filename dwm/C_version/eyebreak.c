// eyebreak.c
// gcc eyebreak.c -O2 -o eyebreak -lX11

#include <sys/file.h>
#include <fcntl.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <getopt.h>
#include <signal.h>

volatile sig_atomic_t force_break = 0;
volatile sig_atomic_t skip_break = 0;

void sighandler(int s)
{
    if (s == SIGUSR1)
        force_break = 1;
    else if (s == SIGUSR2)
        skip_break = 1;
}

// Функция вывода справки (Usage / Help)
void usage(const char *progname)
{
    printf("Использование: %s [-w секунды] [-b секунды] [-h]\n\n", progname);
    printf("Программа для периодического блокирования экрана и отдыха глаз (совместима с dwm/dwmblocks).\n\n");
    printf("Параметры:\n");
    printf("  -w, --work      Время работы в секундах до начала перерыва (по умолчанию: 3600)\n");
    printf("  -b, --break     Продолжительность перерыва в секундах (по умолчанию: 5)\n");
    printf("  -h, --help      Показать эту справку и выйти\n\n");
    printf("Управление через сигналы (IPC):\n");
    printf("  kill -USR1 $(pidof eyebreak)   - Принудительно начать перерыв прямо сейчас\n");
    printf("  kill -USR2 $(pidof eyebreak)   - Пропустить/завершить текущий перерыв\n\n");
    printf("Горячие клавиши (внутри окна перерва):\n");
    printf("  Escape                         - Закрыть окно перерыва\n");
    exit(0);
}

void setroot(Display *dpy, const char *txt)
{
    FILE *f = fopen("/tmp/eyebreak_status", "w");
    if (f) {
        fprintf(f, "%s", txt);
        fclose(f);
    }
    system("pkill -RTMIN+12 dwmblocks &");
}

void draw_center(
    Display *dpy,
    Window win,
    GC gc,
    XFontStruct *font,
    int win_width,
    int y,
    const char *text)
{
    int tw = XTextWidth(font, text, strlen(text));
    XDrawString(dpy, win, gc, (win_width - tw) / 2, y, text, strlen(text));
}

int main(int argc, char *argv[])
{
    signal(SIGUSR1, sighandler);
    signal(SIGUSR2, sighandler);

    int work = 3600; 
    int rest = 5;    

    int c;

    // Добавлен параметр 'h' в строку getopt
    while((c = getopt(argc, argv, "w:b:h")) != -1)
    {
        switch(c)
        {
            case 'w':
                work = atoi(optarg); 
                break;

            case 'b':
                rest = atoi(optarg);
                break;

            case 'h':
                usage(argv[0]); // Вызов справки по прапорщику -h
                break;

            default:
                usage(argv[0]); // Вызов справки, если передан неизвестный аргумент
                break;
        }
    } 
   
    int fd = open("/tmp/eyebreak.lock", O_CREAT|O_RDWR, 0666);
    if (fd < 0)
        return 1;

    if (flock(fd, LOCK_EX|LOCK_NB))
    {
        printf("Already running\n");
        return 0;
    }

    Display *dpy = XOpenDisplay(NULL);

    if (!dpy) {
        fprintf(stderr,"Cannot open display\n");
        close(fd); 
        return 1;
    }

    int screen = DefaultScreen(dpy);
    int sw = DisplayWidth(dpy, screen);
    int sh = DisplayHeight(dpy, screen);

    while (1)
    {
        int work_seconds = work; 
        skip_break = 0; 

        while (work_seconds > 0)
        {
            if (force_break)
            {
                force_break = 0;
                break;
            }

            if (work_seconds <= 10)
            {
                char status[64];
                sprintf(status, "Break in %d", work_seconds);
                setroot(dpy, status);
            }
            sleep(1);
            work_seconds--;
        }

        int w = 700;
        int h = 320;

        Window win = XCreateSimpleWindow(
            dpy,
            RootWindow(dpy, screen),
            (sw-w)/2,
            (sh-h)/2,
            w,
            h,
            2,
            WhitePixel(dpy,screen),
            BlackPixel(dpy,screen)
        );

        XStoreName(dpy, win, "Eye Break");
        XSelectInput(dpy, win, ExposureMask | KeyPressMask);
        XMapRaised(dpy, win);

        GC gc = XCreateGC(dpy, win, 0, NULL);
        XSetForeground(dpy, gc, WhitePixel(dpy, screen));

        XFontStruct *font = XLoadQueryFont(dpy, "-misc-fixed-bold-r-normal--24-240-75-75-c-120-iso10646-1");
        if (!font)
            font = XLoadQueryFont(dpy, "fixed");

        XSetFont(dpy, gc, font->fid);
        time_t start = time(NULL);

        while (1)
        {
            if (skip_break)
            {
                skip_break = 0;
                goto finish_break;
            }

            while (XPending(dpy))
            {
                XEvent ev;
                XNextEvent(dpy,&ev);

                if(ev.type==KeyPress)
                {
                    KeySym ks = XLookupKeysym(&ev.xkey, 0);
                    if(ks==XK_Escape)
                        goto finish_break;
                }
            }

            int left = rest - (time(NULL) - start);

            if(left<=0)
                break;

            char status[64];
            sprintf(status, "👁 %02d:%02d", left/60, left%60);
           
            setroot(dpy,status);
            XClearWindow(dpy,win);

            char line[128];
            draw_center(dpy, win, gc, font, w, 70, "EYE BREAK");
            draw_center(dpy, win, gc, font, w, 130, "Look away from the monitor.");
            draw_center(dpy, win, gc, font, w, 170, "Focus on distant objects.");

            sprintf(line, "Remaining: %02d:%02d", left/60, left%60);
            draw_center(dpy, win, gc, font, w, 260, line);

            XFlush(dpy);
            sleep(1);
        }

finish_break:

        setroot(dpy,"");
        XFreeGC(dpy,gc);
        XUnloadFont(dpy, font->fid);
        XDestroyWindow(dpy,win);
        XSync(dpy,False);
    }

    XCloseDisplay(dpy);
    close(fd);

    return 0;
}
