#!/bin/sh

cd ..

if [ ! -d cog ]; then
  echo "Setting up cog..."

  git clone git@github.com:operable/cog.git &> /dev/null
  cd cog
  mix do deps.get, ecto.create, ecto.migrate &> /dev/null
else
  echo "Making sure cog is up-to-date..."

  cd cog
  git pull origin master &> /dev/null
  mix ecto.migrate &> /dev/null
fi

echo "Starting cog..."

elixir --detached -S mix phoenix.server &> /dev/null

while ! nc -z localhost 4000 &> /dev/null; do   
  sleep 0.1
done

cd ../cogctl

set -e
test_status=0
mix test || test_status=$?
set +e

ps x | grep elixir | grep -v grep | cut -d ' ' -f 1 | xargs kill

exit $test_status
