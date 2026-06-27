/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
/* static const char *fonts[]          = { "monospace:size=12" }; */
static const char *fonts[] = {
    "Hack Nerd Font Mono:pixelsize=12:antialias=true:autohint=true",
    "monospace:size=12"
};
static const char dmenufont[]       = "monospace:size=12";
static const char col_gray1[]       = "#222222";
static const char col_gray2[]       = "#444444";
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#eeeeee";
static const char col_cyan[]        = "#005577";
static const char *colorsdark[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};
static const char *colorslight[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray1, col_gray3, col_gray2 },
	[SchemeSel]  = { col_cyan,  col_gray4, col_cyan  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class, instance, title, tags, mask, switchtotag, isfloating, monitor */
	{ "Xmessage",  NULL,    NULL,                        0,    0,     1,   -1 },
	{ "Gimp",      NULL,    NULL,                   1 << 4,    1,     0,   -1 },
	{ "Awardswx",  NULL,    NULL,                   1 << 2,    1,     0,   -1 },
	{ "Drs_wx",    NULL,    NULL,                   1 << 1,    1,     0,   -1 },
    { NULL,        NULL,    "Прив'язка до запису",  1 << 2,    1,     1,   -1 },
    { NULL,        NULL,    "Пошук отримувача",     1 << 2,    1,     1,   -1 },
    { "st-256color", "btop",  NULL,                 1 << 8,    1,     0,   -1 },
    { "st-256color", "nethogs",  NULL,              1 << 7,    1,     0,   -1 },
};

/* layout(s) */
static const float mfact     = 0.65; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
static const int refreshrate = 120;  /* refresh rate (per second) for client move/resize */

static const Layout layouts[] = {
	/* symbol     arrange function */
    { "[]=",     tile },    /* Мозаичный режим (Tiling) */
    { "><>",     NULL },    /* Плавающий режим (Floating) */
    { "[M]",     monocle },     /* Полноекранний режим (Monocle) */
};

/* key definitions */
#define MODKEY Mod1Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenudark[] =  { 
    "dmenu_run", 
    "-m", 
    dmenumon, 
    "-i", 
    "-fn", 
    dmenufont, 
    "-nb", 
    col_gray1, 
    "-nf", 
    col_gray3, 
    "-sb", 
    col_cyan, 
    "-sf", 
    col_gray4, 
    NULL
};
static const char *dmenulight[] = { 
    "dmenu_run", 
    "-m", 
    dmenumon, 
    "-i",
    "-fn", 
    dmenufont, 
    "-nb", 
    col_gray3, 
    "-nf", 
    col_gray1, 
    "-sb", 
    col_cyan, 
    "-sf", 
    col_gray4, 
    NULL 
};
static const char *termcmd[]  = { "/home/alex320388/.local/bin/st", NULL };
/*static const char *open_ranger[] = {
    "/home/alex320388/.local/bin/st",
    "-t=RANGER",  
    "-e",              
    "ranger",
    NULL
};*/
static const char *themecmd[]  = { "/home/alex320388/.local/bin/set-theme-based-on-time.sh", NULL };
static const char *open_radio[]  = { "/home/alex320388/.local/bin/dwm/radio.sh", NULL };
static const char *open_calc[]  = { "/home/alex320388/.local/bin/dwm/calculator.sh", NULL };
static const char *open_help[]  = { "/home/alex320388/.local/bin/dwm/help.sh", NULL };
static const char *nakaz[]  = { "/home/alex320388/.local/bin/nn_start", NULL };
static const char *awards[]  = { "/home/alex320388/.local/bin/awardstart", NULL };
static const char *getclpb[]  = { "/home/alex320388/.local/bin/dwm/get_clipb.sh", NULL };
static const char *sendclpb[]  = { "/home/alex320388/.local/bin/dwm/send_clipb.sh", NULL };
static const char *switchkeyb[]  = { "/home/alex320388/.local/bin/dwm/toggle_layout.sh", NULL };
static const char *clipboardmenu[]  = { "/home/alex320388/.local/bin/clipmenu-themed.sh", NULL };
static const char *clipdelcmd[] = { "clipdel", "-d", ".", NULL };
static const char *open_events[]  = { "/home/alex320388/.local/bin/dwm/my_tasks_edit.sh", NULL };
static const char *select_color[]  = { "/home/alex320388/.local/bin/dwm/selcolor_with_dmenuklik.sh", NULL }; 

static const Key keys[] = {
	/* modifier             key     function        argument */
    { MODKEY,             167,       spawn,         SHCMD("bash -c 'sleep 0.2; win=$(/usr/bin/xdotool getwindowfocus getwindowname); if echo \"$win\" | grep -iq libreoffice; then /usr/bin/xdotool key --clearmodifiers ctrl+S; fi'") }, /* стрелка вправо вверху */
    { MODKEY,             166,       spawn,         SHCMD("bash -c 'sleep 0.2; win=$(/usr/bin/xdotool getwindowfocus getwindowname); if echo \"$win\" | grep -iq libreoffice; then /usr/bin/xdotool key --clearmodifiers ctrl+o; fi'") }, /* стрелка влева вверху */
	{ MODKEY|ControlMask,   28,     spawn,          {.v = themecmd } },      // t
	{ MODKEY,               33,     spawndmenu,     {0} },                   // p
	{ MODKEY,               36,     zoom,           {0} },                   // Return
	{ MODKEY,               39,     spawn,          {.v = select_color } },  // s
	{ MODKEY|ControlMask,   36,     spawn,          {.v = termcmd } },       // Return
	{ MODKEY,               181,    spawn,          {.v = open_calc } },     // Refresh
	{ MODKEY,               51,     spawn,          {.v = open_events } },   // / "\"
	{ MODKEY,               52,     spawn,          {.v = getclpb } },       // z
	{ MODKEY|ShiftMask,     52,     spawn,          {.v = sendclpb } },      // z
	{ MODKEY,               53,     spawn,          {.v = clipboardmenu } }, // x
	{ MODKEY|ShiftMask,     53,     spawn,          {.v = clipdelcmd } },    // x
	{ MODKEY,               57,     spawn,          {.v = awards } },        // n
	{ MODKEY|ShiftMask,     57,     spawn,          {.v = nakaz } },         // n
	{ MODKEY,               27,     spawn,          {.v = open_radio } },    // r
	{ MODKEY,               61,     spawn,          {.v = open_help } },     // /
	{ ControlMask,          65,     spawn,          {.v = switchkeyb } },    // space
	{ MODKEY,               56,     togglebar,      {0} },                   // b
	{ MODKEY,               44,     focusstack,     {.i = +1 } },            // j
	{ MODKEY,               45,     focusstack,     {.i = -1 } },            // k
	{ MODKEY,               31,     incnmaster,     {.i = +1 } },            // i
	{ MODKEY,               40,     incnmaster,     {.i = -1 } },            // d
	{ MODKEY,               43,     setmfact,       {.f = -0.05} },          // h
	{ MODKEY,               46,     setmfact,       {.f = +0.05} },          // l
    { MODKEY|ShiftMask,     28,     view,           {0} },                   // t
	{ MODKEY|ShiftMask,     54,     killclient,     {0} },                   // c
	{ MODKEY,               28,     setlayout,      {.v = &layouts[0]} },    // t
	{ MODKEY,               41,     setlayout,      {.v = &layouts[1]} },    // f
	{ MODKEY,               58,     setlayout,      {.v = &layouts[2]} },    // m
	{ MODKEY,               65,     setlayout,      {0} },                   // space
	{ MODKEY|ControlMask,   65,     togglefloating, {0} },                   // space
	{ MODKEY,               19,     view,           {.ui = ~0 } },           // 0
	{ MODKEY|ShiftMask,     19,     tag,            {.ui = ~0 } },           // 0
	{ MODKEY,               59,     focusmon,       {.i = -1 } },            // comma
	{ MODKEY,               60,     focusmon,       {.i = +1 } },            // period
	{ MODKEY|ShiftMask,     59,     tagmon,         {.i = -1 } },            // comma
	{ MODKEY|ShiftMask,     60,     tagmon,         {.i = +1 } },            // period
	TAGKEYS(                10,                     0)                       // 1
	TAGKEYS(                11,                     1)                       // 2
	TAGKEYS(                12,                     2)                       // 3
	TAGKEYS(                13,                     3)                       // 4
	TAGKEYS(                14,                     4)                       // 5
	TAGKEYS(                15,                     5)                       // 6
	TAGKEYS(                16,                     6)                       // 7
	TAGKEYS(                17,                     7)                       // 8
	TAGKEYS(                18,                     8)                       // 9
	{ MODKEY|ShiftMask,     24,     quit,           {0} },                   // q
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
