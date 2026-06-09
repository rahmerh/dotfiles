for file in "$HOME/.bashrc.d/"*; do
  [ -e "$file" ] || continue
  . "$file"
done
