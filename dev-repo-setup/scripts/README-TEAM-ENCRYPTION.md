# 🔐 Multi-Developer Environment Variables Encryption

A secure solution for distributing environment variable encryption across development teams. Uses **hybrid encryption** (RSA + AES) to allow multiple developers to encrypt their `.env` files, while only the team lead can decrypt them.

## 🎯 Use Case

**Perfect for scenarios where:**
- Multiple developers need to encrypt their environment variables
- Only team lead/DevOps should be able to decrypt them
- Encrypted files need to be stored in Git repositories
- Private keys should be stored in GitHub secrets or secure locations

## 🔄 How It Works

### Security Model
```
Developer A ──┐
Developer B ──┼─► [Team Public Key] ──► Encrypt ──► GitHub Repository
Developer C ──┘                                          │
                                                          │
Team Lead ◄── [Team Private Key] ◄── Decrypt ◄───────────┘
```

### Encryption Process
1. **RSA-4096 + AES-256 Hybrid Encryption**
2. **Random AES key** generated for each file
3. **AES key encrypted** with team's RSA public key
4. **File data encrypted** with AES (fast, handles large files)
5. **Two files created**: `encrypted-env-vars.enc` + `encrypted-aes-key.enc`

## 🚀 Setup Instructions

### 1. Team Lead: Generate Key Pair

```bash
# Generate RSA-4096 key pair
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out team-private-key.pem
openssl rsa -in team-private-key.pem -pubout -out team-public-key.pem

# Secure the private key
chmod 600 team-private-key.pem
```

### 2. Embed Public Key in Script

Copy the public key content and embed it in `encrypt-env-vars-team.sh`:

```bash
TEAM_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxR9Cqvsw1ai1f9gCcOSL
LP7fwwwBMMKHRvwTLaGEMnSymGEPLuo/MU4RkCjTNsT7v7tSOJuTBx4q/Lno5BF4
... (your actual public key) ...
-----END PUBLIC KEY-----"
```

### 3. Store Private Key Securely

**Option A: GitHub Secrets**
1. Go to your repository → Settings → Secrets and variables → Actions
2. Add new secret: `TEAM_PRIVATE_KEY`
3. Paste the entire private key content

**Option B: Local Secure Storage**
- Store `team-private-key.pem` in a secure location
- Never commit it to version control
- Share securely with authorized team members only

### 4. Distribute Encryption Script

Share `encrypt-env-vars-team.sh` with all developers:
- ✅ **Safe to distribute** (contains only public key)
- ✅ **Safe to commit to Git**
- ✅ **Works cross-platform** (Linux, macOS, Windows)

## 👨‍💻 Developer Usage

### Encrypting Environment Variables

```bash
# Make script executable
chmod +x encrypt-env-vars-team.sh

# Run encryption (will prompt for .env file path)
./encrypt-env-vars-team.sh

# Enter path to your .env file
# Script creates: encrypted-env-vars.enc, encrypted-aes-key.enc, encrypted-env-vars.meta
```

### Committing to Git

```bash
# Add encrypted files (safe to commit)
git add encrypted-env-vars.enc encrypted-aes-key.enc encrypted-env-vars.meta

# Commit and push
git commit -m "Add encrypted environment variables"
git push
```

## 🔑 Team Lead Usage

### Manual Decryption

```bash
# Run decryption script
./decrypt-env-vars-team.sh

# Prompts for:
# 1. Path to private key file
# 2. Encrypted files (uses defaults if in same directory)
# 3. Output file name

# Creates: decrypted-env-vars (contains original .env content)
```

### Automated Decryption (GitHub Actions)

The provided GitHub Action workflow automatically:
1. **Detects encrypted files** in repository
2. **Uses private key from secrets**
3. **Decrypts environment variables**
4. **Shows metadata and content preview**
5. **Cleans up sensitive files**

```yaml
# Trigger manually or on push to encrypted files
name: Decrypt Environment Variables
on:
  workflow_dispatch:
  push:
    paths:
      - '**/encrypted-env-vars.enc'
```

## 📁 File Structure

```
scripts/
├── encrypt-env-vars-team.sh     # Developer encryption script (public key embedded)
├── decrypt-env-vars-team.sh     # Team lead decryption script
├── team-private-key.pem         # Private key (KEEP SECURE)
├── team-public-key.pem          # Public key (safe to share)
└── sample.env                   # Example environment file

encrypted-files/
├── encrypted-env-vars.enc       # Encrypted data (safe to commit)
├── encrypted-aes-key.enc        # Encrypted AES key (safe to commit)
└── encrypted-env-vars.meta      # Metadata (safe to commit)
```

## 🔒 Security Features

### ✅ Secure
- **RSA-4096 encryption** (unbreakable with current technology)
- **AES-256 encryption** for data (industry standard)
- **Hybrid approach** (best of both worlds)
- **Random salt/IV** for each encryption
- **File integrity verification** (SHA-256 hashes)
- **Cross-platform compatibility**

### ✅ Safe to Distribute
- **Public key embedded** in encryption script
- **No secrets in distributed files**
- **Metadata tracking** (developer, timestamp, hashes)
- **Safe to commit** encrypted files to Git

### ✅ Developer Friendly
- **Single command** encryption
- **Auto-installs dependencies** (OpenSSL)
- **Clear error messages** and progress indicators
- **Git integration** instructions

## 🚨 Security Best Practices

### For Team Lead
- ✅ **Keep private key secure** (never commit to Git)
- ✅ **Use GitHub secrets** for automation
- ✅ **Regularly rotate keys** (regenerate key pair)
- ✅ **Audit access** to private key

### For Developers
- ✅ **Never commit original .env files**
- ✅ **Only use provided encryption script**
- ✅ **Verify script authenticity** before use
- ✅ **Delete unencrypted files** after encryption

### For Repository
- ✅ **Add .env to .gitignore**
- ✅ **Only commit encrypted files**
- ✅ **Include .meta files** for tracking
- ✅ **Use GitHub Actions** for automated decryption

## 🛠️ Troubleshooting

### Common Issues

**"OpenSSL not found"**
- Script auto-installs on Linux/macOS
- On Windows: Use Git Bash or install OpenSSL manually

**"Failed to encrypt AES key"**
- Check if public key is correctly embedded
- Verify OpenSSL version supports RSA

**"Decryption failed"**
- Verify you're using the correct private key
- Check if encrypted files are corrupted
- Ensure files were encrypted with matching public key

**"File too large for RSA"**
- This shouldn't happen with hybrid encryption
- Check if script is using AES for file data

## 📊 Performance

| File Size | Encryption Time | Method |
|-----------|----------------|---------|
| < 1KB | ~0.1s | RSA + AES |
| 1-100KB | ~0.2s | RSA + AES |
| 100KB-1MB | ~0.5s | RSA + AES |
| > 1MB | ~1s+ | RSA + AES |

*Hybrid encryption handles files of any size efficiently*

## 🎉 Benefits

1. **🔐 Secure**: Military-grade encryption standards
2. **👥 Scalable**: Support unlimited developers
3. **🚀 Fast**: Hybrid encryption for any file size  
4. **🔧 Simple**: Single command for developers
5. **📱 Cross-platform**: Works everywhere
6. **🔄 Automated**: GitHub Actions integration
7. **📋 Auditable**: Metadata tracking and verification

---

**This solution provides enterprise-grade security for environment variable management while maintaining developer productivity and ease of use.** 🚀
