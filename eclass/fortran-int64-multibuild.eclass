# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# @ECLASS: fortran-int64-multibuild-multibuild.eclass
# @MAINTAINER:
# sci team <sci@gentoo.org>
# @AUTHOR:
# Author: Mark Wright <gienah@gentoo.org>
# Author: Justin Lecher <jlec@gentoo.org>
# @BLURB: flags and utility functions for building Fortran multilib int64
# multibuild packages
# @DESCRIPTION:
# The fortran-int64-multibuild-multibuild.eclass exports utility functions necessary to build 
# packages for multilib int64 multibuild in a clean and uniform manner.

if [[ ! ${_FORTRAN_INT64_MULTIBUILD_ECLASS} ]]; then

# EAPI=4 is required for meaningful MULTILIB_USEDEP.
case ${EAPI:-0} in
	4|5) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

FORTRAN_INT64="IUSE"

inherit fortran-2 multilib-build toolchain-funcs

# @ECLASS-VARIABLE: ESTATIC_MULTIBUILD
# @DEFAULT_UNSET
# @DESCRIPTION:
# If this is set, then do separate static multibuilds.
# @CODE
# ESTATIC_MULTIBUILD=1
# inherit fortran-int64-multibuild-multibuild
# @CODE

# @ECLASS-VARIABLE: INT64_SUFFIX
# @INTERNAL
# @DESCRIPTION:
# Suffix for Multibuild variant
INT64_SUFFIX="int64"

# @ECLASS-VARIABLE: STATIC_SUFFIX
# @INTERNAL
# @DESCRIPTION:
# Suffix for Multibuild variant
STATIC_SUFFIX="static"

# @FUNCTION: fortran-int64-multibuild_is_int64_build
# @DESCRIPTION:
# Returns shell true if the current multibuild is a int64 build,
# else returns shell false.
# @CODE
#	$(fortran-int64-multibuild_is_int64_build) && \
#		openblas_abi_cflags+=" -DOPENBLAS_USE64BITINT"
# @CODE
# RENAME to match eclass name
fortran-int64-multibuild_is_int64_build() {
	debug-print-function ${FUNCNAME} "${@}"
	if [[ "${MULTIBUILD_ID}" =~ "_${INT64_SUFFIX}" ]]; then
		return 0
	else
		return 1
	fi
}

# @FUNCTION: fortran-int64-multibuild_is_static_build
# @DESCRIPTION:
# Returns shell true if ESTATIC_MULTIBUILD is true and the current multibuild
# is a static build, else returns shell false.
# @CODE
#	if $(fortran-int64-multibuild_is_static_build); then
#		...
# @CODE
fortran-int64-multibuild_is_static_build() {
	debug-print-function ${FUNCNAME} "${@}"
	if [[ "${MULTIBUILD_ID}" =~ "_${STATIC_SUFFIX}" ]]; then
		return 0
	else
		return 1
	fi
}

# @FUNCTION: fortran-int64-multibuild_get_fortran_int64_abi_fflags
# @DESCRIPTION: Return the Fortran compiler flag to enable 64 bit integers for
# array indices if we are performing an int64 build, or the empty string
# otherwise.
# @CODE
# src_configure() {
#	local MULTIBUILD_VARIANTS=( $(fortran-int64-multibuild_multilib_get_enabled_abis) )
#	my_configure() {
#		export FCFLAGS="${FCFLAGS} $(get_abi_CFLAGS) $(fortran-int64-multibuild_get_fortran_int64_abi_fflags)"
#		econf $(use_enable fortran)
#	}
#	multibuild_foreach_variant run_in_build_dir fortran-int64-multibuild_multilib_multibuild_wrapper my_configure
# }
# @CODE
fortran-int64-multibuild_get_fortran_int64_abi_fflags() {
	debug-print-function ${FUNCNAME} "${@}"
	local abi_fflags=""
	if $(fortran-int64-multibuild_is_int64_build); then
		abi_fflags+="$(fortran_get_int64_flag)"
	fi
	echo "${abi_fflags}"
}

# @FUNCTION: fortran-int64-multibuild_multilib_get_enabled_abis
# @DESCRIPTION: Returns the array of multilib int64 and optionally static
# build combinations.  Each ebuild function that requires multibuild
# functionalits needs to set the MULTIBUILD_VARIANTS variable to the
# array returned by this function.
# @CODE
# src_prepare() {
#	local MULTIBUILD_VARIANTS=( $(fortran-int64-multibuild_multilib_get_enabled_abis) )
#	multibuild_copy_sources
# }
# @CODE
fortran-int64-multibuild_multilib_get_enabled_abis() {
	debug-print-function ${FUNCNAME} "${@}"
	local MULTILIB_VARIANTS=( $(multilib_get_enabled_abis) )
	local MULTILIB_INT64_VARIANTS=()
	local i
	for i in "${MULTILIB_VARIANTS[@]}"; do
		if use int64 && [[ "${i}" =~ 64$ ]]; then
			MULTILIB_INT64_VARIANTS+=( "${i}_${INT64_SUFFIX}" )
		fi
		MULTILIB_INT64_VARIANTS+=( "${i}" )
	done
	local MULTIBUILD_VARIANTS=()
	if [[ -n ${ESTATIC_MULTIBUILD} ]]; then
		local j
		for j in "${MULTILIB_INT64_VARIANTS[@]}"; do
			use static-libs && MULTIBUILD_VARIANTS+=( "${j}_${STATIC_SUFFIX}" )
			MULTIBUILD_VARIANTS+=( "${j}" )
		done
	else
		MULTIBUILD_VARIANTS="${MULTILIB_INT64_VARIANTS[@]}"
	fi
	echo "${MULTIBUILD_VARIANTS[@]}"
}

# @FUNCTION: fortran-int64-multibuild_ensure_blas
# @DESCRIPTION: Check the blas pkg-config files are available for the currently
# selected blas module, and for the currently select blas-int64 module if the
# int64 USE flag is enabled.
# @CODE
# src_prepare() {
#	fortran-int64-multibuild_ensure_blas
#	...
# @CODE
fortran-int64-multibuild_ensure_blas() {
	local MULTILIB_INT64_VARIANTS=( $(fortran-int64-multibuild_multilib_get_enabled_abis) )
	local MULTIBUILD_ID
	for MULTIBUILD_ID in "${MULTILIB_INT64_VARIANTS[@]}"; do
		local blas_profname=$(fortran-int64-multibuild_get_blas_profname)
		$(tc-getPKG_CONFIG) --exists "${blas_profname}" \
			|| die "${PN} requires the pkgbuild module ${blas_profname}"
	done
}

# @FUNCTION: fortran-int64-multibuild_multilib_multibuild_wrapper
# @USAGE: <argv>...
# @DESCRIPTION:
# Initialize the environment for ABI selected for multibuild.
# @CODE
#	multibuild_foreach_variant run_in_build_dir fortran-int64-multibuild_multilib_multibuild_wrapper my_src_install
# @CODE
fortran-int64-multibuild_multilib_multibuild_wrapper() {
	debug-print-function ${FUNCNAME} "${@}"
	local v="${MULTIBUILD_VARIANT/_${INT64_SUFFIX}/}"
	local ABI="${v/_${STATIC_SUFFIX}/}"
	multilib_toolchain_setup "${ABI}"
	"${@}"
}

_FORTRAN_INT64_MULTIBUILD_ECLASS=1
fi
