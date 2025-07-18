[![CircleCI](https://circleci.com/gh/sul-dlss/technical-metadata-service.svg?style=svg)](https://circleci.com/gh/sul-dlss/technical-metadata-service)
[![codecov](https://codecov.io/github/sul-dlss/technical-metadata-service/graph/badge.svg?token=5AFRQ6NUBT)](https://codecov.io/github/sul-dlss/technical-metadata-service)
[![Docker image](https://images.microbadger.com/badges/image/suldlss/technical-metadata-service.svg)](https://microbadger.com/images/suldlss/technical-metadata-service "Get your own image badge on microbadger.com")
[![OpenAPI Validator](http://validator.swagger.io/validator?url=https://raw.githubusercontent.com/sul-dlss/technical-metadata-service/main/openapi.yml)](http://validator.swagger.io/validator/debug?url=https://raw.githubusercontent.com/sul-dlss/technical-metadata-service/main/openapi.yml)

# Technical Metadata Service

This API provides methods for creating technical metadata for files in the DOR.  It persists the technical metadata and allows it to be queried.

The metadata creation process runs Siegfried to determine which kind of file this is and then runs appropriate tools depending on the file type (e.g. exiftool, poppler, etc.)

Before this service is invoked, the files must be on the `/dor/workspace` NFS mounts.  Then this technical metadata service is invoked by the accessionWF technical-metadata robot by making a REST request.  In the near term, the technical metadata service will directly update the workflow system after it has completed generating the technical metadata. Once this happens, the accessionWF can proceed and remove the files from the workspace.  In the longer term, we would like to do this update via a messaging service so that it does not require the robots or need to be tightly coupled to the workflow service.

This will only store technical metadata for files in the current version; technical metadata for files that were in earlier versions and are not in the current version will be deleted.

## Rake

In addition to the web service, the technical metadata can also be generated by using a pair of rake tasks.  To generate technical metadata for an item, run this:

```shell
$ bundler exec rake techmd:generate['druid:bc123df4567','spec/fixtures/content/0001.html spec/fixtures/content/bar.txt spec/fixtures/content/dir/brief.pdf spec/fixtures/content/foo.jpg spec/fixtures/content/max.webm spec/fixtures/content/noam.ogg','spec/fixtures/content','true']
Success
```

This happens synchronously and will not update the workflow service.

Note that if you do this locally, you need to have postgres running because the results will be stored in the database.

You can check the results on the rails console:

```ruby
druid='druid:bc123df4567'
pp DroFile.where(druid:)
DroFile.where(druid:).each {|file| pp file.dro_file_parts};nil
```

You can also do this directly on the rails console if you want to have immediate feedback:

```ruby
druid='druid:fd222ms9828'
filepath_map = MoabProcessingService.new(druid:).send(:generate_filepath_map)
errors = TechnicalMetadataGenerator.generate(druid:, filepath_map:, force: true)
```

To generate for an item from a Moab (from preservation storage), the rake task below can be used.  Setting the second parameter to "true" will force the generation of new technical-metadata even if it already exists.  Note that this rake task will queue a job, so will happen asynchronously (and possibly not immediately if there are other jobs already queued).

```shell
$ bundler exec rake techmd:generate_for_moab['druid:bc123df4567','true']
Queued
```

If you have many objects to re-generate technical metadata for, create a list of druids, one per row, with no header, in a plain text file called `druid.txt` and place in the root of the tech metadata application folder.  Note that this will also queue jobs and thus will happen asynchronously:

```shell
$ bundler exec rake techmd:generate_for_moab_list
Queued druid:bc123df4567
```

## Background processing

Background processing is performed by [Sidekiq](https://github.com/mperham/sidekiq).

Sidekiq can be monitored from [/queues](http://localhost:3000/queues).
For more information on configuring and deploying Sidekiq, see this [doc](https://github.com/sul-dlss/DevOpsDocs/blob/master/projects/sul-requests/background_jobs.md).

## Monitoring / statistics

Basic monitoring and statistics are available from [/](http://localhost:3000/).

## Reports

The service includes a Rake task that outputs CSV for files belonging to druids (as specified in an argument to the rake task) if and only if the file has a `duration` value in its audiovisual metadata. It outputs the druid, the filename, the MIME type, and the duration (in seconds):

```shell
$ RAILS_ENV=production bin/rake techmd:reports:media_durations[/tmp/druids.txt]
druid:bk586kk6146,cb147tv8205_pm.wav,audio/x-wav,1683.739
druid:bk586kk6146,cb147tv8205_sh.wav,audio/x-wav,1646.118
druid:bk586kk6146,cb147tv8205_sl.m4a,application/mp4,1646.179
druid:cm856pm4228,gt507vy5436_sl.mp4,application/mp4,3816.201
druid:ck227dm7693,bb761mb4522_FV4298_eng_sl.mp4,application/mp4,621.0
druid:ck227dm7693,bb761mb4522_FV4298_ger_sl.mp4,application/mp4,621.0
druid:ck227dm7693,bb761mb4522_FV4298_v1_sl.mp4,application/mp4,620.72
druid:ck227dm7693,bb761mb4522_FV4298_v2_sl.mov,video/quicktime,620.96
druid:ck227dm7693,bb761mb4522_FV4298_v3_sl.mp4,application/mp4,621.014
druid:ck227dm7693,bb761mb4522_FV4298_v4_sl.mp4,application/mp4,620.96
druid:nr582tm3161,Redivis_GMT20220303-205959_Recording_1920x1186.mp4,application/mp4,3322.912
druid:nr582tm3161,Redivis_GMT20220303-205959_Recording.mp4,application/mp4,3322.912
druid:pf759xf5671,qf378nj5000_sh.mpeg,video/mpeg,2261.04
druid:pf759xf5671,qf378nj5000_sl.mp4,application/mp4,2294.956
druid:rz125dy0428,bw689yg2740_sl.mp4,application/mp4,5080.485
```

where `/tmp/druids.txt` looks like:

```
druid:bk586kk6146
druid:cm856pm4228
foobar
druid:ck227dm7693
druid:nr582tm3161
druid:pf759xf5671
druid:rz125dy0428
druid:bf342vg1682
```

## Requirements

### Siegfried

[Siegfried](https://github.com/richardlehane/siegfried) (version 1.8.0+) is used for file identification.

To install on OS X:
```
brew install richardlehane/digipres/siegfried
```

Note that if you are using an earlier version, you may encounter problems as the output format has changed.

### Exiftool

[Exiftool](https://exiftool.org/) is used for image characterization.

To install on OS X:
```
brew install exiftool
```

### Poppler
[Poppler](https://poppler.freedesktop.org/) is used for PDF characterization.

To install on OS X:
```
brew install poppler
```

### MediaInfo
[MediaInfo](https://mediaarea.net/en/MediaInfo) is used for A/V characterization.

To install on OS X:
```
brew install mediainfo
```

### FFMpeg
[FFmpeg](https://github.com/FFmpeg/FFmpeg) is used for audio analysis of A/V files.

To install on OS X:
```
brew install ffmpeg
```

## Testing

### CI build

Spin up the database using docker-compose:

```shell
$ docker compose up db # use -d to run in background
```

```shell
$ rake db:setup # setup the databases (first time only)
$ rake db:migrate # ensure up to date (after first setup)
```

Run the linters and the test suite:

```shell
$ bin/rake
```

### Integration

Spin up all the docker-compose services for dev/testing:

```shell
$ docker compose up # use -d to run in background
```

Then create the accession workflow for the test object:

```shell
$ rails c
> Dor::Services::Client.object('druid:bc123df4567').workflow('accessionWF').create(version: '1')
```

Get a JWT token for authentication

```shell
bundle exec rake generate_token
```

Hit the technical-metadata-service's HTTP API:

Substitute the token above:

```shell
$ curl -i -H "Authorization: Bearer {TOKEN}" -H 'Content-Type: application/json' --data '{"druid":"druid:bc123df4567","files":[{"uri":"file:///app/openapi.yml", "md5": "123"},{"uri":"file:///app/README.MD", "md5":"456"}], "basepath": "//app"}' http://localhost:3000/v1/technical-metadata
```

Verify that technical metadata was created:

```shell
$ docker compose exec app rails c
> DroFile.pluck(:druid, :filename, :mimetype, :filetype)
# should look like: [["druid:bc123df4567", "openapi.yml", "text/plain", "fmt/818"], ["druid:bc123df4567", "README.md", "text/markdown", "fmt/1149"]]
```

And that the object's workflow was updated:

```shell
$ rails c
> Dor::Services::Client.object('druid:bc123df4567').workflow('accessionWF').process('technical-metadata').status
# should be "completed"
```

## Run locally

First install foreman (foreman is not supposed to be in the Gemfile, See this [wiki article](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman) ):

```
gem install foreman
```

Then you can run
```
bin/dev
```
This starts css/js bundling and the development server

### Generating local technical metadata locally

If you have a file on your laptop you want to test quickly to see if generation is as expected, you can do this on the rails console.  You can also use the `bundler exec rake techmd:generate` rake task as described above.

```ruby
rails c

druid = 'druid:ab123bc4567'
basepath = '//some/local/laptop/path'
files = [{"uri":"file:///some/local/laptop/path/nc889qn3957_sl.mp4", "md5": "012"}]
params = {druid:, files:, basepath:}
file_infos = params[:files].map do |file|
    filepath = CGI.unescape(URI(file[:uri]).path)
    filename = FilepathSupport.filename_for(filepath:, basepath: params[:basepath])
    FileInfo.new(filepath:, md5: file[:md5], filename:)
end
errors = TechnicalMetadataGenerator.generate_with_file_info(druid:, file_infos:, force: true)

puts errors

pp DroFile.where(druid:)
DroFile.where(druid:).each {|file| pp file.dro_file_parts};nil
```

## Docker

Note that this project's continuous integration build will automatically create and publish an updated image whenever there is a passing build from the `main` branch. If you do need to manually create and publish an image, do the following:

Build image:

```
docker build -t suldlss/technical-metadata-service:latest -f docker/app/Dockerfile .
```

Publish:

```
docker push suldlss/technical-metadata-service:latest
```

## Generating techmd from preservation storage
For details, see https://github.com/sul-dlss/technical-metadata-service/wiki/Generating-techmd-from-preservation-storage

## Reset Process (for QA/Stage)

### Steps

1. Reset the database: `bin/rails -e p db:reset`
