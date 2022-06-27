#!/bin/sh

failed_steps=`(
	# eslint outputs warnings to stdout, which get eaten later by the grep if
	# we don't redirect to stderr
	npm run lint -- --max-warnings=0 --color 1>&2 || echo __fail__ lint &
	npm run test -- --color || echo __fail__ test &
	npm run check-format -- --color || echo __fail__ format &
	npm run typecheck -- --pretty 1>&2 || echo __fail__ typecheck &

	wait
) | grep __fail__ | cut -f2 -d' ' | paste -sd' '`

if [ ! -z "$failed_steps" ]; then
	echo "Checks failed: $failed_steps"
	exit 1
fi
