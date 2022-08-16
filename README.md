# Trike

Trike is a simple application in the spirit of [socket_proxy](https://github.com/mbta/socket_proxy) consisting of a [Ranch protocol](https://ninenines.eu/docs/en/ranch/2.1/guide/protocols/) that listens on a TCP socket for packets in the OCS (Operations Control System) message format, parses them into a structured [CloudEvent](https://cloudevents.io/), and forwards them to an [AWS Kinesis Data Stream](https://aws.amazon.com/kinesis/data-streams/).

# Development
- Clone this repo.
- Install [asdf](https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies).
- Run `asdf install` from the repository root.
- Install dependencies: `mix deps.get`
- Run tests: `mix test`
- Run typechecking: `mix dialyzer`
- Run style checking: `mix credo --strict`
- Run all static checks: `mix check`
- Run the application:
  - When developing (`MIX_ENV=dev`), Trike will listen on port 8001 and proxy received messages into a fake Kinesis client that logs events to the console instead of sending them to AWS. The port can be changed with the environment variable `LISTEN_PORT`.
  - Run `mix run --no-halt` or `LISTEN_PORT=<some other port> mix run --no-halt`
## Fake data
Trike comes with a small tool, `fake_source`, for feeding it data over TCP for testing purposes. To use the tool:
- Ensure the application is running: `mix run --no-halt`
- Open a new terminal in the repository root
- Run the tool: `mix fake_source [--trike-port port_number] [--good] [--bad]`
  - By default, the tool assumes Trike is running on port 8001
  - The `--good` option will send Trike canned OCS messages from `priv/ocs_data.csv`
  - The `--bad` option will send Trike random bytes of data
  - `--good` and `--bad` used together will alternate good messages with bad data sent every five seconds

# Architecture and Specification
The design of Trike is specified in two RFCs. Trike's message format is documented in [socket-proxy-ocs-cloudevents](https://github.com/mbta/technology-docs/blob/main/rfcs/accepted/0004-socket-proxy-ocs-cloudevents.md), while general architectural concerns and guidance on Kinesis usage are in [kinesis-proxy-json](https://github.com/mbta/technology-docs/blob/main/rfcs/accepted/0005-kinesis-proxy-json.md).

# Deployment
Trike runs as a Docker Swarm service in the MBTA's data center. Deployments happen from GitHub Actions (the Deploy to Dev and Deploy to Prod actions).

It requires repository secrets to be set in GitHub:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DOCKER_REPO` (the ECR repository to push images into)
