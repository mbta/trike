# Trike

Trike is a simple application in the spirit of [socket_proxy](https://github.com/mbta/socket_proxy) consisting of a [Ranch protocol](https://ninenines.eu/docs/en/ranch/2.1/guide/protocols/) that listens on a TCP socket for packets in the OCS (Operations Control System) message format, parses them into a structured [CloudEvent](https://cloudevents.io/), and forwards them to an [AWS Kinesis Data Stream](https://aws.amazon.com/kinesis/data-streams/).

# Getting started
- Clone this repo.
- Install [asdf](https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies).
- Run `asdf install` from the repository root.
- Install dependencies: `mix deps.get`
- Run tests: `mix test`
- Run typechecking: `mix dialyzer`
- Run style checking: `mix credo --strict`

# Deployment
Trike runs as a Windows service on the opstech3 server in the MBTA's data center. You will need [remote desktop access to opstech3](https://github.com/mbta/wiki/blob/master/devops/accessing-windows-servers.md) to deploy it. If you are not connected to the MBTA's network, you will need to join it using [the VPN](https://www.mbta.com/org/workfromhome).

## If it's your first time using opstech3:
1. Make sure you're connected to the MBTA's network or using the VPN.
1. Connect to opstech3 using the remote desktop client and login.
1. Open `C:\Users\RTRUser` using Windows Explorer, and change the permissions to give yourself access when prompted.

## To deploy a new version:
1. Launch Git Bash.
1. Navigate to `/c/Users/RTRUser/GitHub/trike_release_prod`.
1. Ensure you are on the `main` branch.
1. `git pull` the latest version of the code.
1. Run `./build_release.sh trike_prod` to compile a new release.
1. Open the Windows `Services` application and restart `Trike Prod`
1. Tag the release in git: `git tag -a yyyy-mm-dd -m "Deployed on [date] at [time]"`
1. Push the tag to GitHub: `git push origin yyyy-mm-dd`

## To quickly roll back to a previous version:
1. Move the broken release: `mv _build _build-broken`.
1. Restore the previous release: `mv _build-prev _build`.
1. Restart the service as described above.

## Service configuration
Trike uses [WinSW](https://github.com/winsw/winsw) to manage its service configuration. Its WinSW file is stored in `C:\Users\RTRUser\apps`. When making changes to Trike's service configuration, please be sure to update the version stored in 1Password as well.