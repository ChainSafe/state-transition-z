#/bin/sh
find src -type f -exec sed -i '' -e "s/$1/$2/g" {} +
