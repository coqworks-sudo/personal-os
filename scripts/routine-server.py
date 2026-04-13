#!/usr/bin/env python3
"""
routine-server.py
n8nからのHTTPリクエストを受けてroutine.shを実行するローカルサーバー
ポート: 5679
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import json
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)

ROUTINE_SH = '/Users/subaru/Claude-Workspace/personal-os/scripts/routine.sh'
PORT = 5680


class Handler(BaseHTTPRequestHandler):

    def do_POST(self):
        try:
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length)
            data = json.loads(body) if body else {}

            messages_file = data.get('messagesFile', '/tmp/personal-os-messages.txt')
            date = data.get('date', '')

            logging.info(f'routine.sh 開始: date={date}, file={messages_file}')

            result = subprocess.run(
                ['/bin/bash', ROUTINE_SH, messages_file, date],
                capture_output=True,
                text=True,
                timeout=600
            )

            logging.info(f'routine.sh 終了: returncode={result.returncode}')

            response = json.dumps({
                'ok': result.returncode == 0,
                'returncode': result.returncode,
                'stdout': result.stdout,
                'stderr': result.stderr,
            }).encode()

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(response)

        except Exception as e:
            logging.error(f'エラー: {e}')
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'ok': False, 'error': str(e)}).encode())

    def log_message(self, format, *args):
        pass  # HTTPサーバーのデフォルトログを抑制


if __name__ == '__main__':
    server = HTTPServer(('localhost', PORT), Handler)
    logging.info(f'routine-server 起動: http://localhost:{PORT}')
    server.serve_forever()
