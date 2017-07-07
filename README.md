There are known issues but this is a proof of concept and an experiment with Kitura and Watson capabilities

## Scaffolded Swift Kitura server application

[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://bluemix.net)
[![Platform](https://img.shields.io/badge/platform-swift-lightgrey.svg?style=flat)](https://developer.ibm.com/swift/)

### Table of Contents
* [Summary](#summary)
* [Requirements](#requirements)
* [Project contents](#project-contents)
* [Configuration](#configuration)
* [Run](#run)
* [Deploy to Bluemix](#deploy-to-bluemix)
* [License](#license)
* [Generator](#generator)

### Summary
This scaffolded application provides a starting point for creating Swift applications running on [Kitura](https://developer.ibm.com/swift/kitura/).

### Requirements
* [Swift 3](https://swift.org/download/)

### Project contents
This application has been generated with the following capabilities and services:

* [CloudConfiguration](#configuration)
* [Static web file serving](#static-web-file-serving)
* [Embedded metrics dashboard](#embedded-metrics-dashboard)
* [Docker files](#docker-files)
* [Bluemix cloud deployment](#bluemix-cloud-deployment)
* [Cloudant](#cloudant)
* [Watson Conversation](#watsonconversation)

#### Static web file serving
This application includes a `public` directory in the root of the project. The contents of this directory will be served as static content using the built-in Kitura [StaticFileServer module](https://github.com/IBM-Swift/Kitura/wiki/Serving-Static-Content).

This content is hosted on `/`. For example, if you want to view `public/myfile.html` and the application is hosted at https://localhost:8080, go to https://localhost:8080/myfile.html.
#### Embedded metrics dashboard
This application uses the [SwiftMetrics package](https://github.com/RuntimeTools/SwiftMetrics) to gather application and system metrics.

These metrics can be viewed in an embedded dashboard on `/swiftmetrics-dash`. The dashboard displays various system and application metrics, including CPU, memory usage, HTTP response metrics and more.
#### Docker files
The application includes the following files for Docker support:
* `.dockerignore`
* `Dockerfile`
* `Dockerfile-tools`

The `.dockerignore` file contains the files/directories that should not be included in the built docker image. By default this file contains the `Dockerfile` and `Dockerfile-tools`. It can be modified as required.

The `Dockerfile` defines the specification of the default docker image for running the application. This image can be used to run the application.

The `Dockerfile-tools` is a docker specification file similar to the `Dockerfile`, except it includes the tools required for compiling the application. This image can be used to compile the application.

Details on how to build the docker images, compile and run the application within the docker image can be found in the [Run section](#run) below.
#### Bluemix cloud deployment
Your application has a set of Bluemix cloud deployment configuration files defined to support deploying your application to Bluemix:
* `manifest.yml`
* `.bluemix/toolchain.yml`
* `.bluemix/pipeline.yml`

The [`manifest.yml`](https://console.ng.bluemix.net/docs/manageapps/depapps.html#appmanifest) defines options which are passed to the Cloud Foundry `cf push` command during application deployment.

[IBM Bluemix DevOps](https://console.ng.bluemix.net/docs/services/ContinuousDelivery/index.html) service provides toolchains as a set of tool integrations that support development, deployment, and operations tasks inside Bluemix. The ["Create Toolchain"](#deploy-to-bluemix) button creates a DevOps toolchain and acts as a single-click deploy to Bluemix including provisioning all required services.

#### Cloudant
This application uses the [Kitura-CouchDB package](https://github.com/IBM-Swift/Kitura-CouchDB), which allows Kitura applications to interact with a Cloudant or CouchDB database.

CouchDB speaks JSON natively and supports binary for all your data storage needs.

Boilerplate code for creating a client object for the Kitura-CouchDB API is included inside `Sources/Application/Application.swift` as an `internal` variable available for use anywhere in the `Application` module.

The connection details for this client are loaded by the [configuration](#configuration) code and are passed to the Kitura-CouchDB client in the boilerplate code.
#### Watson Conversation
This application uses the [Watson Swift SDK package](https://github.com/watson-developer-cloud/swift-sdk), which allows Kitura applications to build Watson-powered applications, specifically in this case the IBM Watson Conversation service.

With the IBM Watson Conversation service you can create cognitive agents--virtual agents that combine machine learning, natural language understanding, and integrated dialog scripting tools to build outstanding projects, such as a chat room with an integrated Watson chat bot.

Boilerplate code for creating a client object for the Watson Conversation API is included inside `Sources/Application/Application.swift` as an `internal` variable available for use anywhere in the `Application` module.

The connection details for this client are loaded by the [configuration](#configuration) code and are passed to the Watson Conversation client in the boilerplate code.

More information about the Watson Conversation can be found in the [README](https://github.com/watson-developer-cloud/swift-sdk#conversation)

### Configuration
Your application configuration information is stored in the `config.json` in the project root directory. This file is in the `.gitignore` to prevent sensitive information from being stored in git.

The connection information for any configured services, such as username, password and hostname, is stored in this file.

The application uses the [CloudConfiguration package](https://github.com/IBM-Swift/CloudConfiguration) to read the connection and configuration information from the environment and this file.

If the application is running locally, it can connect to Bluemix services using unbound credentials read from this file. If you need to create unbound credentials you can do so from the Bluemix web console ([example](https://console.ng.bluemix.net/docs/services/Cloudant/tutorials/create_service.html#creating-a-service-instance)), or using the CloudFoundry CLI [`cf create-service-key` command](http://cli.cloudfoundry.org/en-US/cf/create-service-key.html).

When you push your application to Bluemix, these values are no longer used, instead Bluemix automatically connects to bound services using environment variables.

### Run
To build and run the application:
1. `swift build`
1. `.build/debug/text-bot`

**NOTE**: On macOS you will need to add options to the `swift build` command: `swift build -Xlinker -lc++`

#### Docker
To build the two docker images, run the following commands from the root directory of the project:
* `docker build -t myapp-run .`
* `docker build -t myapp-build -f Dockerfile-tools .`
You may customize the names of these images by specifying a different value after the `-t` option.

To compile the application using the tools docker image, run:
* `docker run -v $PWD:/root/project -w /root/project myapp-build /root/utils/tools-utils.sh build release`

To run the application:
* `docker run -it -p 8080:8080 -v $PWD:/root/project -w /root/project myapp-run sh -c .build-ubuntu/release/text-bot`

### Deploy to Bluemix
You can deploy your application to Bluemix using:
* the [CloudFoundry CLI](#cloudfoundry-cli)
* a [Bluemix toolchain](#bluemix-toolchain)

#### CloudFoundry CLI
You can deploy the application to Bluemix using the CloudFoundry command-line:
1. Install the Cloud Foundry command-line (https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
1. Ensure all configured services have been provisioned
1. Run `cf push` from the project root directory

The Cloud Foundry CLI will not provision the configured services for you, so you will need to do this manually using the Bluemix web console ([example](https://console.ng.bluemix.net/docs/services/Cloudant/tutorials/create_service.html#creating-a-service-instance)) or the CloudFoundry CLI (`cf create-service` command)[http://cli.cloudfoundry.org/en-US/cf/create-service.html]. The service names and types will need to match your [configuration](#configuration).

#### Bluemix toolchain
You can also set up a default Bluemix Toolchain to handle deploying your application to Bluemix. This is achieved by publishing your application to a publicly accessible github repository and using the "Create Toolchain" button below. In this case configured services will be automatically provisioned, once, during toolchain creation.

[![Create Toolchain](https://console.ng.bluemix.net/devops/graphics/create_toolchain_button.png)](https://console.ng.bluemix.net/devops/setup/deploy/)

### License
All generated content is available for use and modification under the permissive MIT License (see `LICENSE` file), with the exception of SwaggerUI which is licensed under an Apache-2.0 license (see `NOTICES.txt` file).

### Generator
This project was generated with [generator-swiftserver](https://github.com/IBM-Swift/generator-swiftserver) v2.1.0.
