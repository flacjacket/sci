# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

if [[ ${PV} == "9999" ]] ; then
	inherit subversion
	ESVN_REPO_URI="https://astromatic.net/pubsvn/software/${PN}/trunk"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="http://www.astromatic.net/download/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
fi

#AUTOTOOLS_AUTORECONF=1
AUTOTOOLS_IN_SOURCE_BUILD=1

inherit autotools-utils

DESCRIPTION="Converts astronomical FITS images to the TIFF format"
HOMEPAGE="http://astromatic.iap.fr/software/stiff"

LICENSE="GPL-3"
SLOT="0"
IUSE="doc threads"

RDEPEND="
	media-libs/tiff:0=
	virtual/jpeg:0
	sys-libs/zlib:0="
DEPEND="${RDEPEND}"

src_configure() {
	local myeconfargs=( $(use_enable threads) )
	autotools-utils_src_configure
}

src_install () {
	use doc && DOCS=( doc/. )
	autotools-utils_src_install
}
