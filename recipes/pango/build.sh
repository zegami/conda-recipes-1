#! /bin/bash
# Copyright 2014-2015 Peter Williams and collaborators.
# This file is licensed under a 3-clause BSD license; see LICENSE.txt.

[ "$NJOBS" = '<UNDEFINED>' -o -z "$NJOBS" ] && NJOBS=1
set -e

# don't get locally installed pkg-config entries:
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"

if [ -n "$OSX_ARCH" ] ; then
    # rpath setting is often needed to run compiled autoconf test programs:
    export MACOSX_DEPLOYMENT_TARGET=10.6
    sdk=/
    export CFLAGS="$CFLAGS -isysroot $sdk"
    export LDFLAGS="$LDFLAGS -Wl,-syslibroot,$sdk -Wl,-rpath,$PREFIX/lib"

    # Ugh. install_name fixup currently needed; have to copy since
    # install_name_tool patches in place and the files are hardlinked out of
    # the pkgs tree!
    for lib in freetype png16; do
	lpath=$PREFIX/lib/lib${lib}.dylib
	mv $lpath $lpath.tmp
	cp $lpath.tmp $lpath
	rm -f $lpath.tmp
	iname=$(otool -D $lpath |sed -e '2!d')
	install_name_tool -id @rpath/$iname $lpath
    done
fi

./configure --prefix=$PREFIX --with-included-modules=yes || { cat config.log ; exit 1 ; }
make -j$NJOBS
make install

cd $PREFIX
find . '(' -name '*.la' -o -name '*.a' ')' -delete
rm -rf share/gtk-doc
