import { PassThrough, Readable } from 'stream';
import readline from 'readline';
import { ReadableStream } from 'stream/web'; 
import { S3Client, WriteGetObjectResponseCommand } from '@aws-sdk/client-s3';

const s3 = new S3Client();

const CENSORED_WORDS = ["Terence White"]; 
const CENSOR_PLACEHOLDER = "[REDACTED]"; 

export const handler = async (event) => {
    console.log("Event: ", JSON.stringify(event, null, 2));
    try {
        const inputS3Url = event.getObjectContext.inputS3Url;
        const originalFile = await fetchFromS3Url(inputS3Url);
        const censoredContent = await censorCSV(originalFile);
        await writeGetObjectResponse(event, censoredContent);
        console.log("Successfully processed and returned the censored file.");
    } catch (err) {
        console.error("Error:", err);
        return {
            statusCode: 500,
            body: "Internal Server Error",
        };
    }
};

async function fetchFromS3Url(url) {
    const response = await fetch(url); 
    if (!response.ok) {
        throw new Error(`Failed to fetch file: ${response.statusText}`);
    }

    const reader = response.body.getReader(); 
    let content = '';
    const decoder = new TextDecoder('utf-8');

    while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        content += decoder.decode(value);
    }

    return content;
}

async function censorCSV(content) {
    const output = new PassThrough();
    const rl = readline.createInterface({
        input: Readable.from(content),
        output: output,
    });

    let result = "";
    for await (const line of rl) {
        const censoredLine = censorLine(line);
        result += censoredLine + "\n";
    }
    return result;
}

function censorLine(line) {
    let censoredLine = line;
    CENSORED_WORDS.forEach((word) => {
        const regex = new RegExp(`\\b${word}\\b`, 'gi'); // Match whole words, case-insensitive
        censoredLine = censoredLine.replace(regex, CENSOR_PLACEHOLDER);
    });
    return censoredLine;
}

async function writeGetObjectResponse(event, content) {
    console.log("Writing censored content back to S3...");
    const outputRoute = event.getObjectContext.outputRoute;
    const outputToken = event.getObjectContext.outputToken;

    const params = {
        Body: content,
        RequestRoute: outputRoute,
        RequestToken: outputToken,
        ContentType: "text/csv",
    };

    const command = new WriteGetObjectResponseCommand(params);
    await s3.send(command);
    console.log("WriteGetObjectResponse successful.");
}
