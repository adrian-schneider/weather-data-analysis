var g_http = require('http');
var g_fs = require('fs');
var g_url = require('url');

var g_sockets = {}, g_nextSocketId = 0;

var g_port = 8081;
var g_host = '127.0.0.1';
var g_httpServer = null;

const VOFF = 0, VERROR = 1, VWARN = 2, VINFO = 3, VDEBUG1 = 4, VDEBUG2 = 5;
var g_verbosityThsld = VWARN;
var g_logWithDate = true;

var g_fileWatcher = null;
var g_timerId = null;

var g_watchedFileChanged = false;
var g_watchedFilename = '';
var g_rootPath = './';

const INDEXFILENAME = '.svggraph/index.html';
const GRAPHFILENAME = '.svggraph/graph.html';

function log(verbosity, text) {
  if (verbosity <= g_verbosityThsld) {
    var date = '';
    if (g_logWithDate) {
      date = new Date().toISOString();
      // Strip the date portion from the time stamp.
      date = date.substr(1 + date.indexOf('T'));
    }
    var level = verbosity == VERROR ? 'ERR'
      : verbosity == VWARN ? 'WRN'
      : verbosity == VINFO ? 'INF'
      : verbosity == VDEBUG1 ? 'DB1'
      : verbosity == VDEBUG2 ? 'DB2'
      : '...';
    console.log(`${date} ${level} ${text}`);
  }
}

function statSync(filename) {
  try {
    return g_fs.statSync(filename);
  }
  catch(err) {
    return null;
  }
}

function processFileChangeHandler(filename) {
  log(VDEBUG1, `File change detected on: ${filename}`);
  if (statSync(filename)) {
    g_watchedFileChanged = true;
  }
  else {
    log(VWARN, `File change handler could not stat: ${filename}`);
  }
}

function hasWatchedFileChanged() {
  var dirty = g_watchedFileChanged;
  g_watchedFileChanged = false;
  log(VDEBUG2, `File changed: ${dirty ? 'T' : 'F'}`);
  return dirty;
}

function rerunDelayedHandler(handler, filename, millis) {
  if (g_timerId) {
    clearTimeout(g_timerId);
  }
  g_g_timerId = setTimeout(() => { handler(filename); }, millis);
}

function establishFileWatch(handler, filename) {
  if (g_watchedFilename == '') {
    if (g_fileWatcher) {
      g_fileWatcher.close();
    }
    g_watchedFileChanged = false;
    g_watchedFilename = filename;
    g_fileWatcher = g_fs.watch(filename, (event, eventFilename) => {
      if (eventFilename) {
        // Debounce and dealy:
        // Any file change event occuring within the timeout period
        // prolongs that timeout period by the same amount.
        // Only if no further event occurs during that time, the last
        // event is finally getting handled.
        rerunDelayedHandler(handler, filename, 200);
      }
    });
    log(VINFO, `File watch established on: ${filename}`);
  }
}

// https://stackoverflow.com/questions/14626636/how-do-i-shutdown-a-node-js-https-server-immediately
// Before closing the server and exiting the node.js program,
// the sockets need to be destroyed.
function maintainSocketHash(server) {
  // Maintain a hash of all connected sockets.
  server.on('connection', function (socket) {
    // Add a newly connected socket.
    var socketId = g_nextSocketId++;
    g_sockets[socketId] = socket;
    log(VDEBUG2, `Socket ${socketId} opened.`);

    // Remove the socket when it closes.
    socket.on('close', function () {
      log(VDEBUG2, `Socket ${socketId} closed.`);
      delete g_sockets[socketId];
    });
  });
}

function destroyOpenSockets() {
  for (var socketId in g_sockets) {
    log(VDEBUG2, `Socket ${socketId} destroyed.`);
    g_sockets[socketId].destroy();
  }
}

function deleteFiles() {
  log(VINFO, `Deleting index and graph files.`);
  g_fs.unlinkSync(g_rootPath + INDEXFILENAME);
  g_fs.unlinkSync(g_rootPath + GRAPHFILENAME);
}

function exitServer() {
  if (g_fileWatcher) {
    g_fileWatcher.close();
  }
  g_httpServer.close(() => { log(VWARN, 'Server closed.'); });
  destroyOpenSockets();
  deleteFiles();
  process.exitCode = 1;
}

function serveFile(filename, response) {
  g_fs.readFile(filename, function (err, data) {
    if (err) {
      log(VERROR, err);
      response.writeHead(404, {'Content-Type': 'text/html'});
    }
    else {
      response.writeHead(200, {'Content-Type': 'text/html'});
      response.write(data.toString());
    }
    response.end();
  });
}

function asStyledHtml(text, refresh) {
  return '<!DOCTYPE html>'
  + (refresh ? '<meta http-equiv="refresh" content="2"/>' : '')
  + '<style>html,body{margin:0 0 0 0;overflow:hidden;background-color:black;color:white;font-family:consolas,monospace}</style>'
  + '<html><body>'
  + text
  + '</body></html>'
}

function handleRequest(request, response) {
  var pathname = g_url.parse(request.url).pathname;

  log(VDEBUG1, `Request for ${pathname} received.`);

  if (pathname == "/bye") {
    response.writeHead(200, {'Content-Type': 'text/html'});
    response.write(asStyledHtml('Closing Terminal. Bye...', false));
    response.end();
    setTimeout(exitServer, 1000);
  }
  else if (pathname == "/ask_graph_changed") {
    response.writeHead(200, {'Content-Type': 'text/plain'});
    response.write(hasWatchedFileChanged() ? 'T' : 'F');
    response.end();
  }
  else if (pathname == '/') {
    var indexFile = g_rootPath + INDEXFILENAME;
    if (statSync(indexFile)) {
      serveFile(indexFile, response);
    }
    else {
      log(VINFO, `Could not stat ${indexFile}. Sending default index page.`);
      response.writeHead(200, {'Content-Type': 'text/html'});
      response.write(asStyledHtml('Waiting for data...', true));
      response.end();
    }
  }
  else if (pathname == '/graph.html') {
    var filename = g_rootPath + GRAPHFILENAME;
    establishFileWatch(processFileChangeHandler, filename);
    serveFile(filename, response);
  }
  else {
    log(VINFO, `Ignoring ${pathname}.`);
    response.writeHead(404, {'Content-Type': 'text/html'});
    response.end();
  }
}

function optValue(opt) {
   var val = '';
   try {
     val = opt.substr(opt.indexOf('=') + 1);
   }
   catch (err) {}
   return val;
}

function processArguments() {
  var good = true;
  process.argv.forEach((opt, index, array) => {
    if (index > 1) {
      // port=0..65535
      if (opt.indexOf('port=') == 0) {
        g_port = (0 + optValue(opt)) % 65536;
      }
      // port=0..65535
      if (opt.indexOf('host=') == 0) {
        g_host = optValue(opt);
      }
      // log=0..5
      else if (opt.indexOf('log=') == 0) {
        g_verbosityThsld = (0 + optValue(opt)) % 6;
      }
      // root=<path-name>
      else if (opt.indexOf('root=') == 0) {
        g_rootPath = optValue(opt);
      }
      else if (opt.indexOf('help') == 0) {
        good = false;
        console.log('Terminal options:');
        console.log('  port=0..65535     Listen on port number.');
        console.log('                    Defaults to 8081.');
        console.log('  host=IP|hostname  Host address to listen.');
        console.log('                    Defauts to 127.0.0.1.');
        console.log('  log=0..5          Set log level.');
        console.log('                    Defaults to level 2.');
        console.log('                    0: Remain silent.');
        console.log('                    1: Show errors only.');
        console.log('                    2: Include warnings.');
        console.log('                    3: Include informational.');
        console.log('                    4: Show debug standard.');
        console.log('                    5: Show debug detail.');
        console.log('  root=<path>       Root path to serve files from.');
      }
      else {
        good = false;
        log(VERROR, `Invalid argument ${opt}`)
      }
    }
  });
  return good;
}

if (processArguments()) {
  g_httpServer = g_http.createServer(handleRequest);
  g_httpServer.listen(g_port, g_host);
  maintainSocketHash(g_httpServer);

  log(VWARN, `Server running at http://${g_host}:${g_port}/`);
}
