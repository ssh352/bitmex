\d .utils

loadlib:{[path;lib]
 pwd:system"pwd";
 system "cd ",path;
 system "l ",lib;
 system"cd ",first pwd;
 }

\d .
