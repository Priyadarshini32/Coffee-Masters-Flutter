// SQLite Web Worker
let worker;

self.onmessage = function(e) {
  const { type, data } = e.data;
  
  switch (type) {
    case 'init':
      try {
        worker = new Worker('sqlite3.js');
        worker.onmessage = handleWorkerMessage;
        self.postMessage({ type: 'init', success: true });
      } catch (error) {
        self.postMessage({ type: 'init', success: false, error: error.message });
      }
      break;
      
    case 'open':
      worker.postMessage({ type: 'open', data });
      break;
      
    case 'exec':
      worker.postMessage({ type: 'exec', data });
      break;
      
    case 'close':
      worker.postMessage({ type: 'close' });
      break;
  }
};

function handleWorkerMessage(e) {
  self.postMessage(e.data);
} 