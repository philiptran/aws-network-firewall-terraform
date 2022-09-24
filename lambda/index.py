from botocore.awsrequest import AWSRequest
from botocore.endpoint import URLLib3Session

headers = {}
def lambda_handler(event, context):
  url = 'https://www.amazon.com'
  if 'queryStringParameters' in event:
    if 'url' in event["queryStringParameters"]:
      url = event["queryStringParameters"]["url"]
    
  request = AWSRequest(method="GET", url=url, headers=headers)
  session = URLLib3Session()
  res = session.send(request.prepare())
  print (request.headers)
  print("STATUS_CODE:{}".format(res.status_code))
  print("CONTENT:{}".format(res._content))
  print("Headers:{}".format(res.headers))
  print("ALL:{}".format(res.text))
  
  return {
    'statusCode': 200,
    'body': res.text
  }
