[![CircleCI](https://circleci.com/gh/sul-dlss/technical-metadata-service.svg?style=svg)](https://circleci.com/gh/sul-dlss/technical-metadata-service)
[![Maintainability](https://api.codeclimate.com/v1/badges/96da90f8c036d8e9fbaf/maintainability)](https://codeclimate.com/github/sul-dlss/technical-metadata-service/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/96da90f8c036d8e9fbaf/test_coverage)](https://codeclimate.com/github/sul-dlss/technical-metadata-service/test_coverage)

# Technical Metadata Service

This API provides methods for creating technical metadata for files in the DOR.  It persists the technical metadata and allows it to be queried.

The metadata creation process runs Sigfried to determine which kind of file this is and then runs appropriate tools depending on the file type (e.g. Tika, exiftool, etc.)

Before this service is invoked, the files must be on the `/dor/workspace` NFS mounts.  Then this technical metadata service is invoked by the accessionWF technical-metadata robot by making a REST request.  In the near term, the technical metadata service will directly update the workflow system after it has completed generating the technical metadata. Once this happens, the accessiongWF can proceed and remove the files from the workspace.  In the longer term, we would like to do this update via a messaging service so that it does not require the robots or need to be tightly coupled to the workflow service.

This will only store technical metadata for files in the current version; technical metadata for files that were in earlier versions and are not in the current version will be deleted.

## Background processing
Background processing is performed by [Sidekiq](https://github.com/mperham/sidekiq).

Sidekiq can be monitored from [/queues](http://localhost:3000/queues).
For more information on configuring and deploying Sidekiq, see this [doc](https://github.com/sul-dlss/DevOpsDocs/blob/master/projects/sul-requests/background_jobs.md).

## Requirements
### Siegfried
[Siegfried](https://github.com/richardlehane/siegfried) is used for file identification.

To install on OS X:
```
brew install mistydemeo/digipres/siegfried
```
