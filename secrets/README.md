# SOPS Secrets Management

This directory contains encrypted secrets for the Heartwood Craft NixOS configuration.

## Structure

```
secrets/
├── keys/                 # Age encryption keys (private keys, mode 600)
│   ├── laptop.txt       # Laptop host age key
│   └── server.txt       # Server host age key
├── database.yaml        # Database credentials (encrypted)
├── surveillance.yaml    # RTSP and camera passwords (encrypted)
├── admin.yaml          # Admin interface passwords (encrypted)
├── users.yaml          # User account passwords (encrypted)
└── README.md           # This documentation
```

## Key Information

**Laptop Public Key:** age1dyegtj68gpyhwvus4wlt8azyas2sslwwt8fwyqwz3vu2jffl8chsk2afne
**Server Public Key:** age14rghg6wtzujzmhd0hxhf8rp3vkj8d7uu6f3ppm2grcj5c0gfn4wqz3l0zh

## Usage

### Editing Secrets
```bash
# Install SOPS
nix-shell -p sops

# Edit encrypted file (will decrypt, open editor, re-encrypt)
sops secrets/database.yaml
```

### Creating New Secrets
```bash
# Create new encrypted file
sops secrets/new-service.yaml
```

### Viewing Decrypted Content (for debugging)
```bash
# View decrypted content (don't save this output!)
sops -d secrets/database.yaml
```

## Security Notes

- Private keys in `keys/` directory are mode 600 (read-write for owner only)
- All `.yaml` files are encrypted and safe to commit to git
- Never commit unencrypted secrets or private keys
- Age keys are specific to each host and cannot decrypt secrets for other hosts

## Backup Strategy

- Private keys should be backed up securely offline
- Encrypted secrets files can be stored in git (they're safe when encrypted)
- Consider storing a copy of keys in a secure password manager