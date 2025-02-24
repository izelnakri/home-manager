# Cool
fmt:
	echo "===> Formatting"
	stylua lua/ --config-path=.stylua.toml

lint:
	echo "===> Linting"
	luacheck lua/ --globals vim

test:
	echo "===> Testing"
	nvim -l ./scripts/busted.lua tests/izelnakri/utils/fs/
	# nvim --headless -c "PlenaryBustedDirectory tests/"

clean:
	echo "===> Cleaning"
	rm /tmp/lua_*

pr-ready: fmt lint test
