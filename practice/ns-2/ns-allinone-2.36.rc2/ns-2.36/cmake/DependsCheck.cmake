find_package(TCL REQUIRED)
find_package(TclStub REQUIRED)
find_package(Perl REQUIRED)
pkg_check_modules(OTCL REQUIRED otcl)
pkg_check_modules(TCLCL REQUIRED tclcl)

pkg_check_modules(X11 REQUIRED x11)

#FIXME: to check STL: if enable, namespace and etc.



set(TCLSH, ${TCL_TCLSH})

find_path(TCL2CPP_PATH tcl2c++)
set(TCL2C, ${TCL2CPP_PATH})
set(TCLSH, ${TCL_TCLSH})
set(AR, ar rc)
set(RANLIB, ranlib)
set(INSTALL, install)
set(LN, ln)
set(TEST, test)
set(RM, rm -f)
set(MV, mv)
set(PERL, ${PERL_EXECUTABLE})
