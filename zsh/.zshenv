ensure_dir() {
  for dir in "$@"; do
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
  done
}
