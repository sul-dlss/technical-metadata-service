## Why was this change made? 🤔



## How was this change tested? 🤨

⚡ ⚠ If this change consumes from or writes to other services (including shared file systems), ***run [integration test create_preassembly_image_spec.rb](https://github.com/sul-dlss/infrastructure-integration-test) on stage as it exercises this service*** and/or test in [stage|qa] environment, in addition to specs.  ***You will need to confirm that technical metadata was correctly created for the test, as it is a background job kicked off by a common-accessioning step.***⚡


