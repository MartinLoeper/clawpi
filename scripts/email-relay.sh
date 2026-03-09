#!/usr/bin/env bash
# Start a restricted email relay on your laptop for the OpenClaw agent.
#
# Usage: ./scripts/email-relay.sh <your-email> [port]
#
# Runs a tiny HTTP→SMTP relay in Docker that:
#   - Only accepts POST /send with { "subject": "...", "body": "..." }
#   - Only sends to YOUR email address (hardcoded at startup)
#   - Relays via Gmail SMTP using an App Password
#
# The agent on the Pi can then: curl -X POST http://<laptop-ip>:<port>/send \
#   -d '{"subject":"Dashboard screenshot","body":"See attached"}'
#
# Requires: Docker, a Gmail App Password (https://myaccount.google.com/apppasswords)
set -euo pipefail

RECIPIENT="${1:?Usage: $0 <your-email> [port]}"
PORT="${2:-8025}"
CONTAINER_NAME="openclaw-email-relay"
LOCAL_IP="$(ip -4 route get 1 | grep -oP 'src \K\S+')"

echo "Enter your Gmail address (sender):"
read -r GMAIL_USER
echo "Enter Gmail App Password (16 chars, no spaces):"
read -rs GMAIL_PASS
echo ""

docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Create a minimal relay server using Python inside the container
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${PORT}:8025" \
  -e GMAIL_USER="${GMAIL_USER}" \
  -e GMAIL_PASS="${GMAIL_PASS}" \
  -e RECIPIENT="${RECIPIENT}" \
  python:3.12-slim \
  python3 -c "
import http.server, json, smtplib, os
from email.mime.text import MIMEText

GMAIL_USER = os.environ['GMAIL_USER']
GMAIL_PASS = os.environ['GMAIL_PASS']
RECIPIENT = os.environ['RECIPIENT']

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != '/send':
            self.send_response(404)
            self.end_headers()
            return
        length = int(self.headers.get('Content-Length', 0))
        data = json.loads(self.rfile.read(length))
        subject = data.get('subject', 'OpenClaw notification')
        body = data.get('body', '')
        msg = MIMEText(body)
        msg['From'] = GMAIL_USER
        msg['To'] = RECIPIENT
        msg['Subject'] = subject
        try:
            with smtplib.SMTP('smtp.gmail.com', 587) as s:
                s.starttls()
                s.login(GMAIL_USER, GMAIL_PASS)
                s.send_message(msg)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'{\"status\":\"sent\"}')
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'{\"service\":\"openclaw-email-relay\",\"recipient\":\"' + RECIPIENT.encode() + b'\"}')

http.server.HTTPServer(('0.0.0.0', 8025), Handler).serve_forever()
"

echo ""
echo "  OpenClaw Email Relay"
echo "  ===================="
echo ""
echo "  Recipient:  ${RECIPIENT} (only address allowed)"
echo "  Container:  ${CONTAINER_NAME}"
echo ""
echo "  --- Hand these to the agent ---"
echo ""
echo "  Relay URL:  http://${LOCAL_IP}:${PORT}/send"
echo "  Method:     POST"
echo "  Body:       {\"subject\": \"...\", \"body\": \"...\"}"
echo ""
echo "  Agent command:"
echo "    curl -X POST http://${LOCAL_IP}:${PORT}/send \\"
echo "      -H 'Content-Type: application/json' \\"
echo "      -d '{\"subject\":\"Hello\",\"body\":\"Test from OpenClaw\"}'"
echo ""
echo "  Stop with: docker rm -f ${CONTAINER_NAME}"
echo ""
