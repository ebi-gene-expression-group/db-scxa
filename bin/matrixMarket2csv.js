#!/usr/bin/env node

const fs = require('fs');
const zlib = require('zlib');
const readline = require('readline');

// Helper function that parses CLI options (it doesn’t support flags, only value arguments)
const optParse = (shortArg, longArg) => {
  const argIndex = Math.max(process.argv.indexOf('-' + shortArg), process.argv.indexOf('--' + longArg));
  if (argIndex > 0) {
    return process.argv[argIndex + 1];
  }
};

const mtxFilePath = optParse('m', 'matrix-file');
const mtxRowsFilePath = optParse('r', 'rows-genes-file');
const mtxColsFilePath = optParse('c', 'cols-runs-file');
const experimentId = optParse('e', 'experiment-id');
const batchSize = optParse('s', 'step-size');
const outputPath = optParse('o', 'output');

const outputStream = outputPath ?
  fs.createWriteStream(optParse('o', 'output')) :
  process.stdout;

// Reads a file with lines of the form '<some_id>', and returns an array arr such that arr[<index>] == <some_id>
// The index is assigned based on the line number (starting at 1) where the ID was found
const readIndexedLinesToArray = (fileContents) =>
  fileContents.split('\n')
    .filter(line => line.trim() !== '')
    .map(line => line.trim().match(/\s*(\S+)\.*/))
    .map((match, index) => [index + 1, match[1]])
    .reduce((accumulator, currentValue) => {
      accumulator[currentValue[0]] = currentValue[1];
      return accumulator;
    }, []);

const genes = readIndexedLinesToArray(zlib.gunzipSync(fs.readFileSync(mtxRowsFilePath)).toString('utf8'));
const runs = readIndexedLinesToArray(zlib.gunzipSync(fs.readFileSync(mtxColsFilePath)).toString('utf8'));

// Readline ensures that the Matrix Market file will be streamed and consumed one line at a time
const rl = readline.createInterface({
  input: fs.createReadStream(mtxFilePath).pipe(zlib.createGunzip())
});

// If a stepSize was given, all writes will be buffered until uncork or end are called
batchSize && outputStream.cork();

let readLines = 0;
// We insert the experiment accession and the row/col indexes are replaced by the labels in the rows/cols files
rl.on('line', line => {
  while (line.startsWith("%")) {
    return;
  }
  readLines++;
  // The first non-comment line in MatrixMarket contains the matrix dimensions and should be skipped.
  if (readLines==1) return;

  const match = line.trim().match(/(.+)\s+(.+)\s+(.+)/);
  const parsedFields = [Number.parseInt(match[1]), Number.parseInt(match[2]), Number.parseFloat(match[3])];

  outputStream.write(
    [experimentId, genes[parsedFields[0]], runs[parsedFields[1]], parsedFields[2]].join(',') + '\n',
     'utf8');

  if (batchSize && readLines % batchSize === 0) {
    outputStream.uncork();
    outputStream.cork();
  }
});

rl.on('close', () => {
  outputStream.end();
});
