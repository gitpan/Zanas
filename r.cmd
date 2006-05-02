perl Makefile.PL
nmake
nmake install
nmake realclean
net stop Apache
net start Apache
explorer http://do