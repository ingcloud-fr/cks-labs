FROM node:latest

WORKDIR /app

COPY package*.json ./
RUN apt-get update
RUN apt-get install -y curl
RUN npm install
RUN apt-get clean

COPY . .

EXPOSE 3000
CMD ["npm", "start"]
