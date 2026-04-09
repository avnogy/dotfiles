#!/usr/bin/env bash
set -euo pipefail

max_width="${MAX_WIDTH:-2560}"
max_height="${MAX_HEIGHT:-1440}"
jpg_quality="${JPG_QUALITY:-88}"
preview_size="${PREVIEW_SIZE:-512x512>}"
wal_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
preview_cache_dir="${wal_cache_dir}/preview"
palette_cache_dir="${wal_cache_dir}/awesome-palettes"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
originals_dir="${script_dir}/originals"
output_dir="${script_dir}/optimized"

mkdir -p "${originals_dir}"
mkdir -p "${output_dir}"
mkdir -p "${preview_cache_dir}"
mkdir -p "${palette_cache_dir}"

rm -f "${output_dir}"/*.jpg "${output_dir}"/*.jpeg "${output_dir}"/*.png "${output_dir}"/*.webp
rm -f "${preview_cache_dir}"/*.jpg
rm -f "${palette_cache_dir}"/full-*.sh "${palette_cache_dir}"/preview-*.sh

shopt -s nullglob

cache_wal_palette() {
	local source="$1"
	local prefix="$2"
	local name
	name="$(basename -- "${source}")"

	wal -q -n -i "${source}"
	cp "${wal_cache_dir}/colors.sh" "${palette_cache_dir}/${prefix}-${name}.sh"
}

optimized_name() {
	local source="$1"
	local base="$2"
	local size

	size="$(magick "${source}" -resize "${max_width}x${max_height}>" -format '%wx%h' info:)"
	printf '%s_%s.jpg\n' "$(printf '%s\n' "${base}" | sed -E 's/_[0-9]+x[0-9]+$//')" "${size}"
}

for source in "${script_dir}"/*; do
	[[ -f "${source}" ]] || continue

	name="$(basename -- "${source}")"
	ext="${name##*.}"
	base="${name%.*}"

	case "${ext,,}" in
		png|jpg|jpeg|webp)
			;;
		*)
			continue
			;;
	esac

	mv -n "${source}" "${originals_dir}/${name}" || true
done

for source in "${originals_dir}"/*; do
	[[ -f "${source}" ]] || continue

	name="$(basename -- "${source}")"
	base="${name%.*}"

	target="${output_dir}/$(optimized_name "${source}" "${base}")"
	magick "${source}" \
		-strip \
		-resize "${max_width}x${max_height}>" \
		-sampling-factor 4:2:0 \
		-interlace Plane \
		-quality "${jpg_quality}" \
		"${target}"

	cache_wal_palette "${target}" "full"

	preview_target="${preview_cache_dir}/$(basename -- "${target}")"
	magick "${target}" -resize "${preview_size}" "${preview_target}"
	cache_wal_palette "${preview_target}" "preview"

	printf 'optimized %s -> %s\n' "${name}" "$(basename -- "${target}")"
done
