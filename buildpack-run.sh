if [ -f  ".bundle/plugin/index" ]; then
  sed -i "s|$(pwd)|/app|" .bundle/plugin/index
fi