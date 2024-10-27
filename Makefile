main:
	@$(MAKE) macos

macos:
	@./build.sh --app Heat --bundle-id run.nathan.Heat --platform macOS > /dev/null 2>&1

ios:
	@./build.sh --app Heat --bundle-id run.nathan.Heat --platform 'iOS Simulator' > /dev/null 2>&1
