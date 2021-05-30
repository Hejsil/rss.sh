#!/bin/sh

program=${0##*/}
usage() {
    echo "Usage: $program [-h]"
    echo "A program for downloading all the rss feeds you follow."
    echo "$program reads \$XDG_CONFIG_HOME/rss/urls to find all the feeds you follow."
    echo "These feeds will be downloaded to \$XDG_CACHE_HOME/rss/unread. $program will"
    echo 'not download feed entries that already exists in $XDG_CACHE_HOME/rss/{unread,read}.'
    echo ""
    echo 'Users can move entries between $XDG_CACHE_HOME/rss/{unread,read} to mark whether'
    ecoh "an entry has been read or not. The name of the file should not be changed though."
    echo ""
    echo "Requires: curl, sfeed"
    echo ""
    echo "    -h    Print help information and exists"
}

while [ -n "$1" ]; do
    case $1 in
        --)
            shift
            break
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        -*)
            usage
            exit 1
            ;;
        *) break ;;
    esac
    shift
done

dir_with_fallback() {
    dir=$1
    fallback=$2
    if [ -e "$dir" ]; then
        echo "$dir"
    else
        echo "$fallback"
    fi
}

global_cache_dir=$(dir_with_fallback "$XDG_DATA_HOME" "$HOME/.local/share")
global_config_dir=$(dir_with_fallback "$XDG_CONFIG_HOME" "$HOME/.config")

# cache dirs
cache_dir="$global_cache_dir/rss"
unread_dir="$cache_dir/unread"
mkdir -p "$unread_dir"
read_dir="$cache_dir/read"
mkdir -p "$read_dir"

# configs
config_dir="$global_config_dir/rss"
mkdir -p "$config_dir"
url_config="$config_dir/urls"
touch -a "$url_config"

cut -f1 "$url_config" | xargs curl -s | sfeed | tr '\t' '\a' |
    while IFS=$(printf '\a') read -r timestamp title link content content_type id author enclosure; do
        id=$(echo "$id" | sed 's#/#|#g')
        [ -z "$id" ] && id=$(echo "$link" | sed 's#/#|#g')
        [ -z "$id" ] && {
            echo 'No id' >&2
            continue
        }
        [ -e "$unread_dir/$id" ] && continue
        [ -e "$read_dir/$id" ] && continue

        printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n' "$timestamp" "$title" "$link" \
            "$content" "$content_type" "$author" "$enclosure" \
            >"$unread_dir/$id"
    done
