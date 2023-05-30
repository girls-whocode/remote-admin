# Remote Admin

This script allows you to perform various administrative tasks on remote hosts using SSH. It provides an interactive interface to select a host, choose an action, and execute the action on the selected host(s). The script also supports loading a configuration file to customize the behavior.

## Prerequisites

- Bash (Bourne Again SHell)
- SSH client

## Usage

```bash
./remote_admin.sh [options]
```

If no options are provided, the script will prompt you to select a host and choose an action interactively. Alternatively, you can specify the options directly in the command.

## Options

- `-a, --action=<action>`: Specifies the action to perform on the host(s).
- `-c, --color=<true|false>`: Sets the color output. Default is `true`.
- `-h, --help`: Displays the help information.
- `-H, --host=<hostname>`: Sets the hostname to perform the action on.
- `-F, --hostfile=<file>`: Loads hosts from a file.
- `-u, --user=<username>`: Sets the username to connect with SSH.
- `-i, --identity=<keyfile>`: Sets the SSH key identity file.
- `--configure`: Rebuilds the configuration file with answered questions.

## Configuration

The script uses a configuration file (`remote-admin.conf`) to store user preferences. If the configuration file doesn't exist, the script will create it with default values. You can modify the configuration file manually or use the `--configure` option to rebuild it with answered questions.

## Actions

The following actions are available:

1. **Shell**: Opens a shell session on the remote host.
2. **Copy SSH Key**: Copies your SSH public key to the remote host for passwordless authentication.
3. **Check Security Updates**: Checks for available security updates on the remote host.
4. **Refresh Subscription Manager**: Refreshes the subscription manager on the remote host.
5. **Copy File**: Copies a file to the remote host.
6. **Get File**: Retrieves a file from the remote host.
7. **Check Memory**: Checks the memory usage on the remote host.
8. **Check Disk Space**: Checks the disk space usage on the remote host.
9. **Check Load**: Checks the system load on the remote host.
10. **Reboot Host**: Reboots the remote host.
11. **Shutdown Host**: Shuts down the remote host.

Note: If multiple hosts are selected, the script will perform the chosen action on each host sequentially.

## Examples

1. Select host interactively and open a shell session:
   ```bash
   ./remote_admin.sh
   ```

2. Specify the hostname and copy a file to the host:
   ```bash
   ./remote_admin.sh --host=myhost.example.com --action="Copy File"
   ```

3. Load hosts from a file and check disk space on each host:
   ```bash
   ./remote_admin.sh --hostfile=hosts.txt --action="Check Disk Space"
   ```

4. Rebuild the configuration file with answered questions:
   ```bash
   ./remote_admin.sh --configure
   ```

## License

This script is licensed under the MIT License. See [LICENSE](LICENSE) for more information.