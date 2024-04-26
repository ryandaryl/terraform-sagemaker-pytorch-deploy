import boto3

client = boto3.client('sagemaker-runtime')

response = client.invoke_endpoint(
    EndpointName="distilbert-ep-dcyqvzoe",
    ContentType="application/json",
    Body='{"inputs": "This product is amazing and great and makes me happy: Words said by no-one."}',
)

print(response["Body"].read())
                                    