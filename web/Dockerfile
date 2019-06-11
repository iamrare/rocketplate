FROM node:11

WORKDIR /home/node/app

COPY package.json package-lock.json ./

RUN npm i

COPY . .

# `next build` doesn't like non-root permissions
# USER node

CMD npm run build && npm start
