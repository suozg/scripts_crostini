//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
    /* Иконка  Команда                                              Период Сигнал */
    { "", "/home/alex320388/.local/bin/dwm/pipette_status.sh",        0,    14 }, 
    { "", "/home/alex320388/.local/bin/dwm/netstatus",                5,    0  }, 
    { "", "/home/alex320388/.local/bin/dwm/battery",                  60,   0  },
    { "", "/home/alex320388/.local/bin/dwm/disk",                     5,    2  },
    { "", "/home/alex320388/.local/bin/dwm/toggle_layout.sh status",  0,    1  },
    { "", "/home/alex320388/.local/bin/dwm/sbtsks.sh",                300,  10 }, 
    { "", "cat /tmp/dwm-radio-status",                                0,    15 },
    { "", "date '+%b %d %a (%j) %H:%M %p'",			                  5,	0  },
};

//sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char delim[] = " | ";
static unsigned int delimLen = 5;

