
const { S3Client, ListObjectsV2Command, GetObjectCommand } = require('@aws-sdk/client-s3');
const fs = require('fs');

const s3 = new S3Client({
    region: 'us-east-1',
    endpoint: 'http://127.0.0.1:9000',
    credentials: {
        accessKeyId: 'YOUR-ACCESSKEYID',
        secretAccessKey: 'YOUR-SECRETACCESSKEY'
    },
    forcePathStyle: true
});

async function run() {
    // List all contents stored in the zip archive
    try {
        const listCmd = new ListObjectsV2Command({
            Bucket: 'your-bucket',
            Prefix: 'path/to/file.zip/'
        });
        listCmd.middlewareStack.add(
            (next) => async (args) => {
                args.request.headers['x-minio-extract'] = 'true';
                return next(args);
            },
            { step: 'build', name: 'addMinioExtractHeader' }
        );
        const data = await s3.send(listCmd);
        console.log("Success", data);
    } catch (err) {
        console.log("Error", err);
    }

    // Download a file in the archive and store it in /tmp/data.csv
    try {
        const getCmd = new GetObjectCommand({
            Bucket: 'your-bucket',
            Key: 'path/to/file.zip/data.csv'
        });
        getCmd.middlewareStack.add(
            (next) => async (args) => {
                args.request.headers['x-minio-extract'] = 'true';
                return next(args);
            },
            { step: 'build', name: 'addMinioExtractHeader' }
        );
        const response = await s3.send(getCmd);
        const writeStream = fs.createWriteStream('/tmp/data.csv');
        response.Body.pipe(writeStream);
        await new Promise((resolve, reject) => {
            writeStream.on('finish', resolve);
            writeStream.on('error', reject);
        });
    } catch (err) {
        console.log("Error downloading file", err);
    }
}

run();

