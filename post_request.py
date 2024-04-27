import boto3

client = boto3.client('sagemaker-runtime', region_name='us-east-1')

response = client.invoke_endpoint(
    EndpointName="deploy-hub-ep-igzdvfhi",
    ContentType="application/json",
    Body='{"inputs": "This product is amazing and great and makes me happy: Words said by no-one."}',
)

print(response["Body"].read())
