#!/usr/bin/env python3

import cgi
import http.server
import logging

log = logging.getLogger()

FORM = b'''
<html>
    <body>
        <h1>Luna Setup</h1>
        <form action="" method="post">
            <input type="datetime-local" name="datetime" />
            <input type="submit" />
        </form>
        <script type="text/javascript">
            (function() {
                var datetime_field = document.querySelector('[name=datetime]');
                var now = new Date();
                var formatter = new Intl.DateTimeFormat('en-us', {year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit",
                    second: "2-digit",
                    hour12: false,
                });
                var formatted = Object.fromEntries(formatter.formatToParts(now).map(o => [o['type'], o['value']]));
                var now_str = `${formatted['year']}-${formatted['month']}-${formatted['day']}T${formatted['hour']}:${formatted['minute']}`;
                datetime_field.value = now_str;

                window.addEventListener('message', function handle_message(evt) {
                    alert('got ' + JSON.stringify(evt.data));
                });

            })();
        </script>
    </body>
</html>
'''
PORT = 8000

class Handler(http.server.BaseHTTPRequestHandler):

    def do_GET(self):
        '''Serve the form.'''
        self.send_response(200)
        self.end_headers()
        self.wfile.write(FORM)

    def do_POST(self):
        '''Save posted data from the form.'''
        self.send_response(200)
        self.end_headers()
        form = cgi.FieldStorage(
                fp=self.rfile,
                headers=self.headers,
                environ={'REQUEST_METHOD': 'POST',
                    'CONTENT_TYPE': self.headers['Content-Type'],
                    }
                )
        self.wfile.write(repr(form).encode('utf-8'))


if __name__ == '__main__':
    with http.server.ThreadingHTTPServer(('', PORT), Handler) as httpd:
        log.info('serving')
        httpd.serve_forever()
