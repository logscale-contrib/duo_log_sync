Duo Log Sync (v2.1.0)
===================

[![Issues](https://img.shields.io/github/issues/duosecurity/duo_log_sync)](https://github.com/duosecurity/duo_log_sync/issues)
[![Forks](https://img.shields.io/github/forks/duosecurity/duo_log_sync)](https://github.com/duosecurity/duo_log_sync/network/members)
[![Stars](https://img.shields.io/github/stars/duosecurity/duo_log_sync)](https://github.com/duosecurity/duo_log_sync/stargazers)
[![License](https://img.shields.io/badge/License-View%20License-orange)](./LICENSE)

## About
`duologsync` (DLS) is a utility written by Duo Security that supports fetching logs from Duo endpoints and ingesting them to different SIEMs.

---

## Installation - Generic

- Make sure you are running Python 3+ with `python --version`.
- Clone this GitHub repository and navigate to the `duo_log_sync` folder.
- Ensure you have "setuptools" by running `pip3 install setuptools`.
- Install `duologsync` by running `python/python3 setup.py install`. 
- Refer to the `Configuration` section below. You will need to create a `config.yml` file and fill out credentials for the adminapi in the duoclient section as well as other parameters if necessary.
- Run the application using `duologsync <complete/path/to/config.yml>`.
- If a new version of DLS is downloaded from GitHub, run the setup command again to reinstall `duologsync` for changes to take effect.

## Installation - Podman

- Create a new file `/lib/systemd/system/duologsync.service`

```ini
[Unit]
Description=duologsync Container
Wants=NetworkManager.service network-online.target
After=NetworkManager.service network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Environment="IMAGE=ghcr.io/logscale-contrib/duo_log_sync/container:1"

# Required mount point for syslog-ng persist data (including disk buffer)
Environment="PERSIST_MOUNT=duologsync-var:/var/lib/duologsync"

# Optional mount point for local overrides and configurations; see notes in docs
Environment="LOCAL_MOUNT=/opt/duologsync:/etc/duologsync:z"

TimeoutStartSec=0

ExecStartPre=/usr/bin/podman pull $IMAGE

ExecStart=/usr/bin/podman run \
        -v "$PERSIST_MOUNT" \
        -v "$LOCAL_MOUNT" \
        --network host \
        --name duologsync \
        --rm $IMAGE

Restart=on-abnormal
```

- Create a configuration file `/opt/duologsync/config.yaml` The configuration below is a subset of the full template provided in the repo 
additional configuration options may be added ensure the minimum below is used.

```yaml
# IMPORTANT!: Use single quotes (''), NOT double quotes ("")!
# All fields marked 'REQUIRED' must have a value otherwise the config will be
# considered invalid. If something is not marked required, you may remove that
# field from the config if you are fine with the default value.

# Version of the config file. Do not change! Automatically updated for each
# config file change
version: '1.0.0'

# Fields for changing the functionality of DuoLogSync (DLS)
# The fields for dls_settings, including dls_setting itself are not required.
# Default values may be given for all the fields if you choose not to include
# them.
dls_settings:
    
  # Settings related to saving API call offset information into files for use
  # when DLS crashes so that DLS can pickup where it left off.
  # By default, entire section is commented out. DLS will still create checkpoint files in the
  # default directory which is /tmp/. Uncomment sections to give custom path
  checkpointing:

    # Whether checkpoint files should be created to save offset information
    # about API calls. If true, the value set for directory (or the default of
    # '/tmp') is where DLS will look for checkpoint files to recover offset
    # information from.
    # Valid options are False, True
    enabled: True

    # Directory where checkpoint files should be stored.
    directory: '/var/lib/duologsync'


# List of servers and how DLS will communicate with them
servers:
  
    # Descriptive name for your server
    # REQUIRED
  - id: 'logscale'

    # Address of server to which Duo logs will be sent. If there is nothing that consumes these
    # logs, they will be lost, since writing to local storage is not supported
    # REQUIRED
    hostname: ''

    # Port of server to which logs will be sent
    # MINIMUM: 0
    # MAXIMUM: 65535
    # REQUIRED
    port:

    # Transport protocol used to communicate with the server
    # OPTIONS: TCP, TCPSSL, UDP
    # REQUIRED
    protocol: ''

account:
  
  # Integration key
  # REQUIRED
  ikey: ''

  # Private key, keep this safe
  # REQUIRED
  skey: ''

  # api-hostname of the server hosting this account's logs shown on duo admin panel
  # REQUIRED
  hostname: ''
    
  # Here you define to what servers the logs of certain endpoints should go.
  # This is done by creating a mapping (start with dash -) and then defining
  # what endpoints the mapping is for as a list and the what server apply to
  # those endpoints.
  # ENDPOINTS OPTIONS: adminaction, auth, telephony, trustmonitor, activity
  # SERVERS OPTIONS: any server id defined above in the list of servers
  # REQUIRED
  endpoint_server_mappings:
    - endpoints: ['adminaction', 'auth', 'activity']
     server: 'logscale'
```

- Create the podman volume used to store the checkpoint `sudo podman volume create duologsync-var`

- Enable the service and start

```bash
sudo systemctl daemon-reload
sudo systemctl enable duologsync
sudo systemctl start duologsync
```

- Review the output of the service `journalctl -xe`

### Compatibility

- Duologsync is compatible with Python versions `3.6`, `3.7`, and `3.8`.
- Duologsync is officially supported on Linux, MacOS, and Windows systems.

### Windows
- On Windows operating systems, `duologsync` is installed in the `\scripts\` folder under the Python installation in most cases.
---

## Logging
- A logging filepath can be specified in `config.yml`. By default, logs will be stored under the `/tmp` folder with name `duologsync.log`.
- These logs are only application/system logs, and not the actual logs retrieved from Duo endpoints.

---

## Features

- Current version supports fetching logs from auth, telephony, admin, and trust monitor endpoints and sending over TCP, TCP Encrypted over SSL, and UDP to consuming systems.
- Ability to recover data by reading from last known offset through checkpointing files.
- Enabling only certain endpoints through config file.
- Choosing how logs are formatted (JSON, CEF).
- Support for Linux, MacOS, Windows.
- Support for pulling logs using Accounts API (only for MSP accounts).

### Work in progress

- Adding more log endpoints.
- Adding better skey security.
- Adding CEF and MSP support for the Trust Monitor endpoint.

---

## Configuration

- See [`template_config.yml`](./template_config.yml) for an example and for extensive, in-depth config explanation.

### Upgrading Your Config File
- From time to time new features and fields will be added to the config file. Updating of the config file is mandatory when config changes are made. To make this easier, Duo has created a script called [`upgrade_config.py`](./upgrade_config.py) which will automatically update your old config for you.
- To use the `upgrade_config.py` script, simply run the following command: `python3 upgrade_config.py <old_config> <new_config>` where `<old_config>` is the filepath or your old configuration file, and `<new_config>` is where you would like the new configuration file to be saved.
- The `upgrade_config.py` script will not delete your old config file, it will be preserved.
- This script is a new feature and has to extrapolate some information, some unexpected issues may occur. For most old configs the script will work just fine. You can check if the new config file works by running it with DLS.
- The `is_msp` field under accounts section is required only when using DLS with the Accounts API. For this reason, the upgrade script won't create that field in new config by default.

---

## Additional Considerations

### MSP customers

- Calling Admin API handlers with Accounts API is mutually exclusive with cross-deployment sub-accounts. Many customers with sub-accounts (especially MSPs) must use cross-deployment sub-accounts and therefore can't use the Accounts API. 

### Trust Monitor Support
- Currently, the Trust Monitor endpoint only supports logging in JSON format, and does not support MSPs. Calling this endpoint (in combination with any other endpoints) using CEF format or MSPs will not allow the program to execute.
