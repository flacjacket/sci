# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v3
# $Id$

EAPI=5

MY_PV=${PV/_beta/-beta}

DESCRIPTION="Navigation scripting & testing utility for PhantomJS and SlimerJS"
HOMEPAGE="http://casperjs.org/"
SRC_URI="https://github.com/n1k0/${PN}/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${MY_PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="<www-client/phantomjs-2.0.0"
RDEPEND="${DEPEND}"

src_compile() {
	return
}

src_install() {
	dodir /usr/share/${P}/
    insinto /usr/share/${P}/
    doins -r modules/
	doins -r tests/
    doins package.json

	exeinto /usr/share/${P}/bin
	insinto /usr/share/${P}/bin
	doexe bin/bootstrap.js
	doexe bin/casperjs
	doins bin/usage.txt

    dodir /usr/bin/
	ln -s /usr/share/${P}/bin/casperjs "${D}"/usr/bin/casperjs || die

    dodoc CHANGELOG.md
    dodoc CONTRIBUTORS.md
    dodoc README.md
}
