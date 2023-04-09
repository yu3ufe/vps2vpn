# vps2vpn

vps2vpn is a Bash script for quickly and easily setting up an OpenVPN server on a Linux Ubuntu VPS. With this script, you can turn your VPS into a secure VPN server in a matter of seconds.

## Support

If you find this project useful and would like to support its development, you can buy me a coffee by clicking the button below:

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/yu3ufe)

Your support is greatly appreciated!

## Usage

To use the script, simply download it to your VPS and run it with the following command:

```
bash vps2vpn.sh
```

The script will guide you through the process of installing and configuring OpenVPN and related components. Once the script has completed, your OpenVPN server will be up and running.

The script provides a menu with the following options:
- Install openvpn server and create a basic connection pack
- Create a new connecion pack
- Revoke user certificate
- Assign a static IP for a specific connection pack
- Assign a range of dynamic IPs for the server (Under maintenance)
- Delete Everything and apply a RollBack plan
- Exit

You can select an option from the menu to perform the corresponding task.

## Contributions

Contributions are welcome! If you find any bugs or have suggestions for improving the script, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
