# ChatGPT Diagnostic Suite

A comprehensive diagnostic tool for analyzing ChatGPT system status, connectivity, and performance issues.

## Overview

The ChatGPT Diagnostic Suite is a bash-based tool that provides detailed insights into ChatGPT's infrastructure status, including CDN performance, API health, network quality, and system dependencies. It performs extensive checks across multiple service endpoints and generates detailed reports for troubleshooting.

## Features

- **DNS and CDN Analysis**
  - DNS resolution checks
  - CDN header inspection
  - TLS certificate validation
  - IPv4 and IPv6 support

- **API Health Monitoring**
  - Response time measurements
  - Status code analysis
  - HTTP/2 support verification
  - Backend service status checks

- **Network Quality Assessment**
  - Latency measurements
  - TCP connection testing
  - Basic connectivity verification
  - Response pattern analysis

## Prerequisites

### Required Tools
- curl
- dig (dnsutils)
- host
- openssl
- nc (netcat)

### Optional Tools
- whois
- traceroute
- mtr

## Installation

1. Clone or download the script:
```bash
curl -O https://raw.githubusercontent.com/yourusername/chatgpt-diagnostic/main/chatgpt_diagnose.sh
```

2. Make the script executable:
```bash
chmod +x chatgpt_diagnose.sh
```

3. Install required dependencies:
```bash
apt-get update && apt-get install -y dnsutils curl openssl netcat-openbsd
```

## Usage

Run the diagnostic suite:
```bash
./chatgpt_diagnose.sh
```

### Output Files
- Diagnostic log: `/tmp/chatgpt_diagnostics.log`
- Summary report: `/tmp/chatgpt_summary.txt`

## Understanding the Results

### DNS and CDN Analysis
- Checks DNS resolution for all ChatGPT domains
- Verifies Cloudflare CDN operation
- Validates SSL certificates

### API Health Check
- HTTP Response Codes:
  - 200: Fully operational
  - 308: Redirect
  - 401: Authentication required
  - 403: Rate limited
  - 503: Service disruption

### Network Quality
- TCP connectivity status
- Average latency measurements
- Response pattern analysis

## Common Issues and Solutions

1. **DNS Resolution Failures**
   - Check local DNS configuration
   - Try alternative DNS servers (8.8.8.8, 1.1.1.1)

2. **API Service Disruption (503)**
   - Backend service issue
   - Check status.openai.com for updates
   - Retry after a few minutes

3. **High Latency**
   - Check local network connection
   - Consider using a different network
   - Test from different geographic locations

4. **SSL/TLS Issues**
   - Verify system time is correct
   - Update OpenSSL
   - Check for certificate expiration

## Example Output Analysis

```
=== API Health Check ===
Testing https://api.openai.com/v1/models
HTTP Response Code: 503
Time to First Byte: 0.239956s
⚠️ Service Unavailable - Backend issue detected
```
This indicates a backend service disruption. The API is responding but unavailable for requests.

## Troubleshooting Tips

1. **CDN Issues**
   - Clear browser cache
   - Try different DNS servers
   - Use a different network connection

2. **API Access Problems**
   - Verify API key status
   - Check rate limits
   - Monitor usage quotas

3. **Network Connectivity**
   - Test basic internet connectivity
   - Check for DNS resolution
   - Verify proxy settings if applicable

## Support

For issues with the diagnostic tool:
- Open an issue on GitHub
- Check the latest release notes
- Contact system administrator

## License

MIT License - Feel free to modify and distribute as needed.

## Contributing

Contributions are welcome! Please submit pull requests with improvements or additional features.

## Acknowledgments

- OpenAI API Documentation
- Cloudflare Network Diagnostics
- Community Contributors
