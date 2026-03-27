npm install prom-client


docker build -f multistageDockerFile -t chatapp .
 docker run -d -p 3000:3000 --name frontend chatapp:latest
