import {createServer} from 'node:http';
import {reportHtml, reportScript} from '../src/report_ui.ts';
// Isolated fixture host only; never included in the deployed Worker.
createServer((req,res) => {
  if (req.url === '/private/report/') { res.setHeader('content-type','text/html'); res.end(reportHtml); }
  else if (req.url === '/private/report/app.js') { res.setHeader('content-type','text/javascript'); res.end(reportScript); }
  else { res.statusCode = 404; res.end(); }
}).listen(8799,'127.0.0.1');
