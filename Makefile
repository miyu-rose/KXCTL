SHELL=fish.x
AS=has060
LK=hlk

OBJ=KXCTL.O KXLIB.O miyulib.O
OBJ_DEBUG=KXCTL_dbg.O KXLIB_dbg.O miyulib.O

all : KXCTL.X
debug : KXCTL_dbg.X

KXCTL.X : $(OBJ)
	$(LK) -x -o$@ $(OBJ)
KXCTL_dbg.X : $(OBJ_DEBUG)
	$(LK) -x -o$@ $(OBJ_DEBUG)

KXCTL_dbg.O : KXCTL.S
	$(AS) -u -s__DEBUG__ -o$@ $<
KXLIB_dbg.O : KXLIB.S
	$(AS) -u -w3 -s__DEBUG__ -o$@ $<


%.O : %.S
	$(AS) -u -w3 $<
%.O : %.HAS
	$(AS) -u -w3 $<


clean :
	-rm *.O *.x *.*~ *.bak *_dbg.* > NUL

KXCTL.O     : KeplerX.H
KXCTL_dbg.O : KeplerX.H
KXLIB.O     : KeplerX.H
KXLIB_dbg.O : KeplerX.H
