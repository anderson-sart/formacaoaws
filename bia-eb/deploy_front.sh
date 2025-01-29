API_ENDPOINT="http://bia-alb-1610665679.us-east-1.elb.amazonaws.com"

NODE_OPTIONS=--openssl-legacy-provider REACT_APP_API_URL=$API_ENDPOINT SKIP_PREFLIGHT_CHECK=true npm run build --prefix client

echo '>> Faszendo deploy dos assets'

aws s3 sync client/build s3://bia-formacao-cdn/ --exclude "index.html"

echo '>> Faszendo deploy dos index.html'

aws s3 sync client/build s3://bia-formacao-cdn/ --exclude "*" --include "index.html"