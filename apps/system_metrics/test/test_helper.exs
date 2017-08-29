ExUnit.start()

# start agent process
SystemMetrics.Testmeter.start_link()

# Report warnings as errors
Code.compiler_options(warnings_as_errors: true)
