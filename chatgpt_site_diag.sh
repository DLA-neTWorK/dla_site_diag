#!/bin/bash

# Ultimate ChatGPT System Diagnostic Suite
set -e

# Log file setup
LOG_FILE="/tmp/chatgpt_diagnostics.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

# Colors and styles
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Utility functions
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}"
    echo "[$(timestamp)] Running: $1" >> "$LOG_FILE"
}

check_command() {
    local cmd=$1
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: $cmd is not installed. Some checks will be skipped.${NC}"
        return 1
    fi
    return 0
}

# Check required commands
check_required_tools() {
    print_header "Checking Required Tools"
    
    local required_tools=(curl dig host openssl nc)
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! check_command "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Missing tools: ${missing_tools[*]}${NC}"
        echo "Install missing tools with:"
        echo "apt-get update && apt-get install -y dnsutils curl openssl netcat-openbsd"
    fi
    
    # Optional tools
    echo -e "\nOptional tools:"
    for tool in whois traceroute mtr; do
        if check_command "$tool"; then
            echo "✓ $tool installed"
        else
            echo "○ $tool not installed (optional)"
        fi
    done
}

check_dns_and_cdn() {
    print_header "DNS and CDN Analysis"
    
    local domains=(
        "chat.openai.com"
        "api.openai.com"
        "auth0.openai.com"
        "cdn.oaistatic.com"
    )
    
    for domain in "${domains[@]}"; do
        echo -e "\n${BOLD}Analyzing $domain:${NC}"
        
        # Basic DNS resolution
        echo "DNS Records:"
        if check_command dig; then
            dig +short "$domain" | while read -r ip; do
                echo "IP: $ip"
                # Reverse DNS (if host is available)
                if check_command host; then
                    host "$ip" 2>/dev/null || echo "No reverse DNS"
                fi
            done
        else
            getent hosts "$domain" || echo "Unable to resolve domain"
        fi
        
        # CDN headers check
        echo -e "\nCDN Headers:"
        curl -sI "https://$domain" | grep -i "server\|cf-ray\|x-served-by\|fastly"
        
        # Certificate info
        echo -e "\nTLS Certificate Info:"
        if check_command openssl; then
            echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | 
            openssl x509 -noout -dates -issuer
        fi
    done
}

check_api_health() {
    print_header "API Health Check"
    
    local endpoints=(
        "chat.openai.com/api/auth/session"
        "api.openai.com/v1/models"
        "api.openai.com/v1/chat/completions"
    )
    
    for endpoint in "${endpoints[@]}"; do
        echo -e "\n${BOLD}Testing https://$endpoint${NC}"
        
        # Advanced curl metrics
        curl -sI -w "\
        HTTP Response Code: %{http_code}\n\
        DNS Lookup Time: %{time_namelookup}s\n\
        TCP Connect Time: %{time_connect}s\n\
        TLS Handshake: %{time_appconnect}s\n\
        Time to First Byte: %{time_starttransfer}s\n\
        Total Time: %{time_total}s\n\
        \n" -o /dev/null "https://$endpoint"
        
        # Check for specific error patterns
        response=$(curl -sI "https://$endpoint")
        if [[ $response =~ "503" ]]; then
            echo -e "${RED}⚠️ Service Unavailable - Backend issue detected${NC}"
        elif [[ $response =~ "403" ]]; then
            echo -e "${YELLOW}⚠️ Forbidden - Possible rate limiting or authentication issue${NC}"
        fi
    done
}

check_network_quality() {
    print_header "Network Quality Analysis"
    
    local target="chat.openai.com"
    
    # Basic connectivity test
    echo "Basic Connectivity:"
    if ping -c 3 "$target" &>/dev/null; then
        echo "✓ Host is reachable"
    else
        echo "✗ Host is unreachable"
    fi
    
    # TCP connection test
    echo -e "\nTCP Connection Test:"
    if check_command nc; then
        timeout 5 nc -zv "$target" 443 2>&1
    fi
    
    # Latency check
    echo -e "\nLatency Check:"
    ping -c 5 "$target" 2>/dev/null | tail -1 | awk -F '/' '{print $5}' | \
        xargs -I {} echo "Average latency: {}ms"
}

analyze_response_pattern() {
    print_header "Response Pattern Analysis"
    
    local url="https://chat.openai.com"
    local samples=5
    local pattern_data=()
    
    echo "Collecting response patterns across $samples requests..."
    
    for ((i=1; i<=samples; i++)); do
        local start_time=$(date +%s.%N)
        local response=$(curl -sI "$url")
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        local status=$(echo "$response" | grep "HTTP" | awk '{print $2}')
        
        pattern_data+=("$status:$duration")
        echo "Request $i: Status $status, Time ${duration}s"
        sleep 1
    done
    
    # Analyze patterns
    echo -e "\nPattern Analysis:"
    echo "Status Codes Distribution:"
    for pattern in "${pattern_data[@]}"; do
        status="${pattern%%:*}"
        case $status in
            200) echo "✓ Success" ;;
            403) echo "! Access Denied" ;;
            503) echo "! Service Unavailable" ;;
            *) echo "? Unknown Status: $status" ;;
        esac
    done
}

generate_summary() {
    print_header "Diagnostic Summary"
    
    local summary_file="/tmp/chatgpt_summary.txt"
    {
        echo "ChatGPT System Status Summary"
        echo "=============================="
        echo "Timestamp: $(timestamp)"
        echo
        
        # DNS Status
        echo "DNS Status:"
        if dig chat.openai.com +short &>/dev/null; then
            echo "✓ DNS resolution working"
        else
            echo "✗ DNS issues detected"
        fi
        
        # CDN Status
        echo -e "\nCDN Status:"
        if curl -sI https://chat.openai.com | grep -q "cf-ray"; then
            echo "✓ Cloudflare CDN operational"
        else
            echo "? CDN status unclear"
        fi
        
        # API Status
        echo -e "\nAPI Status:"
        local api_status=$(curl -s -o /dev/null -w "%{http_code}" https://api.openai.com/v1/models)
        case $api_status in
            200) echo "✓ API fully operational" ;;
            401) echo "✓ API responding (auth required)" ;;
            403) echo "! API rate limited" ;;
            503) echo "✗ API service disruption" ;;
            *) echo "? Unknown API status: $api_status" ;;
        esac
        
    } > "$summary_file"
    
    cat "$summary_file"
}

main() {
    print_header "Starting ChatGPT Diagnostic Suite"
    
    check_required_tools
    check_dns_and_cdn
    check_api_health
    check_network_quality
    analyze_response_pattern
    generate_summary
    
    echo -e "\n${BOLD}Diagnostic logs saved to: $LOG_FILE${NC}"
    echo -e "${BOLD}Summary saved to: /tmp/chatgpt_summary.txt${NC}"
}

# Execute main function
main
