import boto3
import random
import string

# Function that generate random string
def generate_password(length):
    chars = string.ascii_letters + string.digits + string.punctuation
    return ''.join(random.choice(chars) for _ in range(length))

# Function that rotate the secret stored in secret manager 
def lambda_handler(event, context):
    secret_name = "Splunk_Password"
    secret_client = boto3.client('secretsmanager')

    # Retrieve the current secret value
    response = secret_client.get_secret_value(SecretId=secret_name)
    current_password = response['SecretString']

    # Generate a new password
    new_password = generate_password(10)

    # Update the secret with the new password
    secret_client.update_secret(SecretId=secret_name, SecretString=new_password)
    
    print("Secret rotation completed successfully")

    return {
        'statusCode': 200,
        'body': 'Secret rotation completed successfully.'
    }
