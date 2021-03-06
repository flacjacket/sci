# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils fortran-2 multilib toolchain-funcs

DESCRIPTION="Calculates maximally localized Wannier functions (MLWFs)"
HOMEPAGE="http://www.wannier.org/"
SRC_URI="http://wannier.org/code/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-linux"
IUSE="doc examples perl test"

RDEPEND="
	virtual/blas
	virtual/lapack
	perl? ( dev-lang/perl )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( virtual/latex-base
		dev-texlive/texlive-latexextra
	)"

src_configure() {
	cat <<- EOF >> "${S}"/make.sys
		F90 = $(tc-getFC)
		FCOPTS = ${FCFLAGS:- ${FFLAGS:- -O2}}
		LDOPTS = ${LDFLAGS}
		LIBS = $($(tc-getPKG_CONFIG) --libs blas lapack)
	EOF
}

src_compile() {
	emake -j1 wannier
	emake -j1 lib
	if use doc; then
		VARTEXFONTS="${T}/fonts"
		emake -j1 doc
	fi
}

src_test() {
	einfo "Compare the 'Standard' and 'Current' outputs of this test."
	pushd tests
	emake test
	cat wantest.log
}

src_install() {
	dobin wannier90.x
	use perl && dobin utility/kmesh.pl
	dolib.a libwannier.a
	insinto /usr/include
	doins src/obj/*.mod
	if use examples; then
		insinto /usr/share/${PN}
		doins -r examples
	fi
	use doc && dodoc doc/*.pdf
	dodoc README README.install CHANGE.log
}
