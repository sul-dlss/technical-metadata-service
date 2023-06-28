# Why was this change made? 🤔



# How was this change tested? 🤨

⚡ ⚠ If this change consumes from or writes to other services (including shared file systems), ***run [integration test create_preassembly_image_spec.rb](https://github.com/sul-dlss/infrastructure-integration-test) on stage as it exercises this service*** and/or test in [stage|qa] environment, in addition to specs.  ***You will need to confirm that technical metadata was correctly created for the test, as it is a background job kicked off by a common-accessioning step.***⚡



# Does your change introduce accessibility violations? 🩺

⚡ ⚠ Please ensure this change does not introduce accessibility violations (at the WCAG A or AA conformance levels); if it does, include a rationale. See the [Infrastructure accessibility guide](https://github.com/sul-dlss/DeveloperPlaybook/blob/main/best-practices/infra-accessibility.md) for more detail. ⚡



