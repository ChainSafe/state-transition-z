#/bin/sh
find src test -type f -exec sed -i '' -e "s/@import(\"..\/types\/primitives.zig\")/ssz.primitive/g" {} +
