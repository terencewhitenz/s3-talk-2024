export const handler = async (event, context) => {
    console.log("event: \n" + JSON.stringify(event, null, 2));
    const API_ENDPOINT = process.env.API_ENDPOINT;

    for (let record of event.Records) {
      const APIParams = {
        Event: record.eventName,
        EventTime: record.eventTime,
        Bucket: record.s3.bucket.name,
        Key: record.s3.object.key,
        Size: record.s3.object.size
      }
      try {
        const response = await fetch(
          API_ENDPOINT, {
            method : 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(APIParams)
        })
        console.log(JSON.stringify(await response.json(), null, 2))
      } catch (error) {
        console.error(`Error calling API: ${error}`);
      }
    }
}    

