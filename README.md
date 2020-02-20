[![CircleCI](https://circleci.com/gh/sul-dlss/technical-metadata-service.svg?style=svg)](https://circleci.com/gh/sul-dlss/technical-metadata-service)
[![Maintainability](https://api.codeclimate.com/v1/badges/7f4010377decf07ba1e4/maintainability)](https://codeclimate.com/github/sul-dlss/technical-metadata-service/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/7f4010377decf07ba1e4/test_coverage)](https://codeclimate.com/github/sul-dlss/technical-metadata-service/test_coverage)

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
brew install richardlehane/digipres/siegfried
```

## Testing

### CI build

Spin up all the database using docker-compose:

```shell
$ docker-compose up db # use -d to run in background
```

Run the linter and test suite:

```shell
$ rubocop && rspec
```

### Integration

Spin up all the docker-compose services for dev/testing:

```shell
$ docker-compose up # use -d to run in background
```

Then create the accession workflow for the test object:

```shell
$ rails c
> client = Dor::Workflow::Client.new(url: 'http://localhost:3001')
> client.create_workflow_by_name('druid:bc123df4567', 'accessionWF', version: '1')
```

Hit the technical-metadata-service's HTTP API:

```shell
$ curl -i -H 'Content-Type: application/json' --data '{"druid":"druid:bc123df4567","files":["file:///app/README.md","file:///app/openapi.yml"]}' http://localhost:3000/v1/technical-metadata
```

Verify that technical metadata was created:

```shell
$ docker-compose exec app rails c
> DroFile.pluck(:druid, :filename, :mimetype, :filetype)
# should look like: [["druid:bc123df4567", "openapi.yml", "text/plain", "x-fmt/111"], ["druid:bc123df4567", "README.md", "text/markdown", "fmt/1149"]]
```

And that the object's workflow was updated:

```shell
$ rails c
> client = Dor::Workflow::Client.new(url: 'http://localhost:3001')
> client.workflow_status({druid: 'druid:bc123df4567', workflow: 'accessionWF', process: 'technical-metadata'})
# should be "completed"
```

## Docker


Note that this project's continuous integration build will automatically create and publish an updated image whenever there is a passing build from the `master` branch. If you do need to manually create and publish an image, do the following:


Build image:

```
docker build -t suldlss/technical-metadata-service:latest -f docker/app/Dockerfile .
```

Publish:

```
docker push suldlss/technical-metadata-service:latest
```
