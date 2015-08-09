# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# @ECLASS: numeric-int64.eclass
# @MAINTAINER:
# sci team <sci@gentoo.org>
# @AUTHOR:
# Author: Mark Wright <gienah@gentoo.org>
# Author: Justin Lecher <jlec@gentoo.org>
# @BLURB: flags and utility functions for building numeric packages with int64 support
# @DESCRIPTION:
# The numeric-int64.eclass exports utility functions necessary to build 
# numeric packages with int64 support in a clean and uniform manner.

if [[ ! ${_NUMERIC_INT64_ECLASS} ]]; then

# EAPI=4 is required for meaningful MULTILIB_USEDEP.
case ${EAPI:-0} in
	4|5) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

inherit fortran-int64-multibuild

# @ECLASS-VARIABLE: NUMERIC_ALTERNATIVE
# @DESCRIPTION: The base pkg-config module name of the package being built.
# NUMERIC_ALTERNATIVE is used by the numeric-int64_get_alternative_provider_name function to
# determine the pkg-config module name based on whether the package
# has dynamic, threads or openmp USE flags and if so, if the user has
# turned them or, and if the current multibuild is a int64 build or not.
# @CODE
# NUMERIC_ALTERNATIVE="openblas"
# inherit ... numeric-int64
# @CODE
# NEEDS REVIEW - Needed? NoDefault? Move into numeric-int64_get_alternative_provider_name()?
: ${NUMERIC_ALTERNATIVE:=blas}

# @FUNCTION: numeric-int64_get_alternative_provider_name
# @USAGE: [<alternative>]
# @DESCRIPTION: Return the full alternative name, without the .pc extension,
# for the current numeric build.  If the current build is not an int64
# build, and the ebuild does not have dynamic, threads or openmp USE flags or
# they are disabled, then the alternative is ${NUMERIC_ALTERNATIVE} or <alternative> if
# <alternative> is specified.
#
# Takes an optional <alternative> parameter.  If no <alternative> is specified, uses
# ${NUMERIC_ALTERNATIVE} as the base to calculate the full alternative for the current
# build.
numeric-int64_get_alternative_provider_name() {
	debug-print-function ${FUNCNAME} "${@}"
	local alternative="${1:-${NUMERIC_ALTERNATIVE}}"
	if has dynamic ${IUSE} && use dynamic; then
		alternative+="-dynamic"
	fi
	if $(fortran-int64-multibuild_is_int64_build); then
		alternative+="-${INT64_SUFFIX}"
	fi
	# choose posix threads over openmp when the two are set
	# yet to see the need of having the two profiles simultaneously
	if has threads ${IUSE} && use threads; then
		alternative+="-threads"
	elif has openmp ${IUSE} && use openmp; then
		alternative+="-openmp"
	fi
	echo "${alternative}"
}

# @FUNCTION: numeric-int64_get_alternative_name
# @DESCRIPTION: Returns the eselect blas alternative for the current build.
# Which is e.g. blas-int64 if called from an int64 build, or blas otherwise.
# @CODE
#	local provider=$(numeric-int64_get_alternative_provider_name)
#	local alternative=$(numeric-int64_get_alternative_name)
#	alternatives_for ${alternative} $(numeric-int64_get_alternative_provider_name "reference") 0 \
#		/usr/$(get_libdir)/pkgconfig/${alternative}.pc ${provider}.pc
# @CODE
numeric-int64_get_alternative_name() {
	debug-print-function ${FUNCNAME} "${@}"
	[[ -z ${1} ]] && die "${FUNCNAME} needs one argument"
	local alternative_name="${1}"
	if $(numeric-int64_is_int64_build); then
		alternative_name+="-${INT64_SUFFIX}"
	fi
	echo "${alternative_name}"
}

# @FUNCTION: numeric-int64_ensure_blas
# @DESCRIPTION: Check the blas pkg-config files are available for the currently
# selected blas module, and for the currently select blas-int64 module if the
# int64 USE flag is enabled.
# @CODE
# src_prepare() {
#	numeric-int64_ensure_blas
#	...
# @CODE
numeric-int64_ensure_blas() {
	local MULTILIB_INT64_VARIANTS=( $(numeric-int64_multilib_get_enabled_abis) )
	local MULTIBUILD_ID
	for MULTIBUILD_ID in "${MULTILIB_INT64_VARIANTS[@]}"; do
		local alternative_provider=$(numeric-int64_get_alternative_provider_name blas)
		$(tc-getPKG_CONFIG) --exists "${alternative_provider}" \
			|| die "${PN} requires the pkgbuild module ${alternative_provider}"
	done
}

_NUMERIC_INT64_ECLASS=1
fi
