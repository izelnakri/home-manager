# `nvim` shim for tuicr's `e` (open in editor) while tuicr runs in nvim's floating terminal ($NVIM set):
# instead of nesting a second nvim, hide the float and open the file at that line in the parent nvim, where
# gitsigns/neogit can stage the hunk. `cr` puts this first on PATH only inside nvim; anywhere else it's real nvim.
# tuicr passes `+LINE PATH` because the program is named nvim (see tuicr src/editor.rs editor_family).

real=$(PATH=${PATH#*:} command -v nvim)

line=1
file=""
for arg in "$@"; do
  case "$arg" in
    +[0-9]*) line=${arg#+} ;;
    *) file=$arg ;;
  esac
done

if [ -n "${NVIM:-}" ] && [ -n "$file" ]; then
  escaped=${file//\'/\'\'}
  exec "$real" --server "$NVIM" --remote-expr \
    "luaeval('require(\"izelnakri.tuicr\").jump(_A[1], _A[2])', ['$escaped', $line])" >/dev/null
fi

exec "$real" "$@"
