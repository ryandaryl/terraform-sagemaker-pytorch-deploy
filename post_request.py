import boto3

client = boto3.client('sagemaker-runtime', region_name='us-east-2')

response = client.invoke_endpoint(
    EndpointName="deploy-s3-ep-wurxfiib",
    ContentType="application/json",
    Body='[0, 1, 2, 3]',
)

print(response["Body"].read())
