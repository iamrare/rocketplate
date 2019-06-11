FROM node:11

RUN mkdir /home/node/app
WORKDIR /home/node/app

COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# USER node

CMD ["npm", "start"]
