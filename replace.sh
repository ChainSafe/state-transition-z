#/bin/sh
find src test -type f -exec sed -i '' -e "s/$1/$2/g" {} +
